class_name Bark_Journal
extends Node

var registered_actions:PackedStringArray = [
	'set_parent'
]

const vrm_import_extension = preload("res://addons/vrm/vrm_extension.gd")

var actions:Array = []

var root:Node

signal rejoin_thread(thread:Thread)

func _ready():
	root = get_tree().get_first_node_in_group('localworldroot')
	rejoin_thread.connect(func(thread:Thread):
		print('finished thread')
		thread.wait_to_finish()
		)

func get_actions():
	var tmp = actions
	actions = []
	return tmp

func check_root():
	if !is_instance_valid(root):
		root = get_tree().get_first_node_in_group('localworldroot')

func set_parent(target:NodePath, new_parent:NodePath):
	check_root()
	var t_node = root.get_node(target)
	var np_node = root.get_node(new_parent)
	t_node.reparent(np_node)
	actions.append({
		'action_name':'set_parent',
		'target': target,
		'new_parent': new_parent
		})

func delete_node(target:NodePath, recieved=false):
	check_root()
	var t_node = root.get_node(target)
	t_node.queue_free()
	if !recieved:
		actions.append({
			'action_name':'delete_node',
			'target': target
		})

func set_property(target:NodePath, prop_name:String, value:Variant, recieved=false):
	check_root()
	var t_node:Node = root.get_node(target)
	if is_instance_valid(t_node) and prop_name.split(':')[0] in t_node:
		t_node.get_indexed(prop_name)
		t_node.set_indexed(prop_name,value)
		if !recieved:
			actions.append({
				'action_name':'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value
			})

func net_propogate_node(node_string:String, parent:NodePath='', node_name:String='', recieved:=false):
	check_root()
	if node_name.is_empty():
		node_name = node_string.sha256_text()
	var node = BarkHelpers.var_to_node(node_string)
	if parent:
		root.get_node(parent).add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propogate_node',
				'node_string': node_string,
				'parent': parent
			})
	else:
		root.add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propogate_node',
				'node_string':node_string
			})

## Imports an asset and adds that to the action log unless it was a recieved action.
func import_asset(type:String, asset_to_import, asset_name:='', recieved:=false, data:Dictionary={}):
	check_root()
	if asset_name.is_empty():
		asset_name = str(Time.get_unix_time_from_system())

	if (type == 'glb' or type == 'vrm') and asset_to_import and asset_to_import is PackedByteArray:
		var thread = Thread.new()
		thread.start(_import_glb.bind(asset_to_import,asset_name,recieved,data))
#		_import_glb(asset_to_import, asset_name, recieved, data)
		rejoin_thread_when_finished(thread)
	elif type == 'res' and asset_to_import:
		if asset_to_import is String:
			var object_file = FileAccess.open(asset_to_import, FileAccess.READ_WRITE)
			if object_file:
				var tmp = object_file.get_as_text()
				print('started loading')
	#			Journaling.net_propogate_node(tmp)
				ResourceLoader.load_threaded_request(asset_to_import,'',true)
				get_tree().create_timer(1).timeout.connect(_check_loaded.bind(asset_to_import, asset_name, type))
		elif asset_to_import is PackedByteArray:
			var tmpname = str(str(asset_to_import).hash())
			var file = FileAccess.open("user://tmp/"+tmpname,FileAccess.WRITE_READ)
			file.store_buffer(asset_to_import)
			ResourceLoader.load_threaded_request(file.get_path(),'',true)
			get_tree().create_timer(1).timeout.connect(_check_loaded.bind(file.get_path(), asset_name, type))
	elif type == 'pck' and asset_to_import:
		if asset_to_import is String:
			print(ResourceLoader.get_dependencies(asset_to_import))
	elif type == 'image' and asset_to_import:
		if asset_to_import is String and asset_to_import.is_absolute_path():
			pass
		elif asset_to_import is PackedByteArray:
			var tmp = Image.new()
			var err
			if asset_name.ends_with('.jpg') or asset_name.ends_with('.jpeg'):
				err = tmp.load_jpg_from_buffer(asset_to_import)
			elif asset_name.ends_with('.png'):
				err = tmp.load_png_from_buffer(asset_to_import)
			elif asset_name.ends_with('.bmp'):
				err = tmp.load_bmp_from_buffer(asset_to_import)
			elif asset_name.ends_with('.tga'):
				err = tmp.load_tga_from_buffer(asset_to_import)
			elif asset_name.ends_with('.webp'):
				err = tmp.load_webp_from_buffer(asset_to_import)
			var image = TextureRect.new()
			var tex = ImageTexture.create_from_image(tmp)
			image.texture = tex
			var panel = load('res://addons/Panel3D/Panel3D.tscn').instantiate()
			print(panel)
			print(image)
			root.add_child(panel)
			panel.name = asset_name
			panel.set_viewport_scene(image)
			panel.position.y = 2.0
			if !recieved:
				actions.append({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'asset_name': asset_name
				})

func _check_loaded(path:String, asset_name:String, type:String):
	match ResourceLoader.load_threaded_get_status(path):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			print('not loaded yet')
			get_tree().create_timer(.1).timeout.connect(_check_loaded.bind(path, asset_name, type))
		ResourceLoader.THREAD_LOAD_LOADED:
			var err = ResourceLoader.load_threaded_get(path)
			var tmp = err.instantiate()
			root.add_child(tmp)
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': FileAccess.get_file_as_bytes(path)
			})

func _import_glb(asset_to_import, asset_name:='', recieved:=false, data:Dictionary={}) -> void:
	var doc:GLTFDocument = GLTFDocument.new()
	var state:GLTFState = GLTFState.new()
	var base_path = ''
	if 'base_path' in data:
		base_path = data.base_path
	var err = doc.append_from_buffer(asset_to_import,base_path,state)
	if err == OK:
#		for mesh in state.get_meshes():
#			print('mesh: '+str(mesh.mesh))
#			print('surfaces: '+str(mesh.mesh.get_surface_count()))
#			if mesh.mesh.get_surface_lod_count(0) == 0:
#				mesh.mesh.generate_lods(25,60,[])
			
		var scene = doc.generate_scene(state)
		if root:
			asset_name += str(Time.get_unix_time_from_system())
		scene.name = asset_name
		root.call_deferred('add_child',scene)
		print('importing')
		if !recieved:
			actions.append({
				'action_name': 'import_asset',
				'type': 'glb',
				'asset_to_import': doc.generate_buffer(state),
				'asset_name': asset_name
			})
	else:
		Notifyvr.send_notification("error importing gltf document")
		print(err)
	print(' done importing glb ')

func rejoin_thread_when_finished(thread:Thread) -> void:
	if thread:
		if thread.is_started():
			if thread.is_alive():
				get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
				return
		thread.wait_to_finish()

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	match action.action_name:
		"net_propogate_node":
			var parent: String = action.get('parent', '')
			net_propogate_node(action.node_string, parent, '', true)
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			import_asset(action.type, action.asset_to_import, '', true)
		"delete_node":
			delete_node(action.target, true)
