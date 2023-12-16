class_name Bark_Journal
extends Node

var registered_actions: PackedStringArray = [
	'set_parent'
]

var actions: Array[Dictionary] = []

var root: Node

func _ready() -> void:
	_get_root()

func get_actions() -> Array[Dictionary]:
	var tmp := actions.duplicate()
	actions.clear()
	return tmp

func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')

func set_parent(target: NodePath, new_parent: NodePath) -> void:
	check_root()
	var t_node := root.get_node(target)
	var np_node := root.get_node(new_parent)
	t_node.reparent(np_node)
	actions.append({
		'action_name': 'set_parent',
		'target': target,
		'new_parent': new_parent
	})

func delete_node(target: NodePath, recieved := false) -> void:
	check_root()
	var t_node := root.get_node(target)
	t_node.queue_free()
	if !recieved:
		actions.append({
			'action_name': 'delete_node',
			'target': target
		})

func set_property(target: NodePath, prop_name: String, value: Variant, recieved := false) -> void:
	check_root()
	var t_node := root.get_node(target)
	if is_instance_valid(t_node) and prop_name.split(':')[0] in t_node:
		t_node.get_indexed(prop_name)
		t_node.set_indexed(prop_name,value)
		if !recieved:
			actions.append({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value
			})

func net_propagate_node(node_string: String, parent := ^'', node_name := '', recieved := false) -> void:
	check_root()
	if node_name.is_empty():
		node_name = node_string.sha256_text()
	var node = BarkHelpers.var_to_node(node_string)
	if parent:
		root.get_node(parent).add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string,
				'parent': parent
			})
	else:
		root.add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string
			})

## Imports an asset and adds that to the action log unless it was a recieved action.
func import_asset(
	type: String,
	asset_to_import: Variant,
	asset_name := '',
	recieved := false,
	data := {}
) -> void:
	# Make sure root is valid.
	check_root()
	# Generate an asset name if not given.
	if asset_name.is_empty():
		# If we have a string path for the asset import, use that instead.
		if asset_to_import is String:
			asset_name = asset_to_import.split('/')[-1]
		else:
			asset_name = str(Time.get_unix_time_from_system())
	# Get asset content if needed.
	var content := PackedByteArray()
	if type != "res":
		if asset_to_import is PackedByteArray:
			content = asset_to_import
		elif asset_to_import is String:
			content = FileAccess.get_file_as_bytes(asset_to_import)
	# Decide how to import asset based on type.
	# TODO pck support
	match type:
		"glb", "vrm":
			var thread := Thread.new()
			thread.start(_import_glb.bind(content, asset_name, data))
			rejoin_thread_when_finished(thread)
		"res":
			# TODO scenes and resources can't easily be sent to peers because of
			# possible dependencies in other files.
			_import_res(asset_name, asset_to_import)
		"image":
			_import_image(asset_name, content)
	# Send message to peers.
	if !recieved:
		if type == "res":
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': content,
				'asset_name': asset_name
			})
		else:
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': asset_to_import,
				'asset_name': asset_name
			})

func _check_loaded(path: String) -> void:
	match ResourceLoader.load_threaded_get_status(path):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_check_loaded.call_deferred(path)
		ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path)
			if res != null:
				var node = res.instantiate()
				node.position.y = 2.0
				root.add_child(node)

func _import_glb(content: PackedByteArray, asset_name := '', data := {}) -> void:
	Thread.set_thread_safety_checks_enabled(false)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var base_path := ''
	if 'base_path' in data:
		base_path = data.base_path
	var err := doc.append_from_buffer(content, base_path, state)
	if err == OK:
#		for mesh in state.get_meshes():
##			print('mesh: '+str(mesh.mesh))
##			print('surfaces: '+str(mesh.mesh.get_surface_count()))
#			if mesh.mesh.get_surface_lod_count(0) == 0:
##				print('generating lod')
#				mesh.mesh.generate_lods(25,60,[])
			
		var scene := doc.generate_scene(state)
		if root:
			asset_name += str(Time.get_unix_time_from_system())
		scene.name = asset_name
#		if scene is Node3D:
#			scene.scale = Vector3(.1,.1,.1)
		root.call_deferred('add_child', scene)
	else:
		Notifyvr.send_notification("error importing gltf document")

## Imports a Godot resource.
func _import_res(asset_name: String, asset_to_import: Variant) -> void:
	# If asset to import is not a path, create a path.
	# Note that this may mean assets might not load for peers.
	if asset_to_import is PackedByteArray:
		# Write the content to a temporary file.
		# TODO cleanup of the file?
		var path := "user://tmp/" + str(str(asset_to_import).hash())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(asset_to_import)
		file.flush()
		file.close()
		asset_to_import = path
	ResourceLoader.load_threaded_request(asset_to_import, '', true)
	_check_loaded.call_deferred(asset_to_import)

## Imports an image.
func _import_image(asset_name: String, content: PackedByteArray) -> void:
	var img := Image.new()
	var err: Error

	if asset_name.ends_with('.jpg') or asset_name.ends_with('.jpeg'):
		err = img.load_jpg_from_buffer(content)
	elif asset_name.ends_with('.png'):
		err = img.load_png_from_buffer(content)
	elif asset_name.ends_with('.bmp'):
		err = img.load_bmp_from_buffer(content)
	elif asset_name.ends_with('.tga'):
		err = img.load_tga_from_buffer(content)
	elif asset_name.ends_with('.webp'):
		err = img.load_webp_from_buffer(content)
	else:
		return

	if err != OK:
		return

	var tex := ImageTexture.create_from_image(img)
	var plane := MeshInstance3D.new()
	var tmpmesh = PlaneMesh.new()
	tmpmesh.orientation = PlaneMesh.FACE_Z
	root.add_child(plane)
	plane.name = asset_name
	plane.position.y = 1.0

func rejoin_thread_when_finished(thread: Thread) -> void:
	if thread and thread.is_started() and thread.is_alive():
		get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
		return
	thread.wait_to_finish()

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	match action.action_name:
		"net_propagate_node":
			var parent: String = action.get('parent', '')
			net_propagate_node(action.node_string, parent, '', true)
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			import_asset(action.type, action.asset_to_import, '', true)
		"delete_node":
			delete_node(action.target, true)
