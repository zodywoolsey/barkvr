class_name Bark_Journal
extends Node

var registered_actions: PackedStringArray = [
	'set_parent'
]

const vrm_import_extension = preload("res://addons/vrm/vrm_extension.gd")

var actions := []

var root: Node

signal rejoin_thread(thread: Thread)

func _ready():
	root = get_tree().get_first_node_in_group('localworldroot')
	rejoin_thread.connect(func(thread: Thread) -> void:
		print('finished thread')
		thread.wait_to_finish())

func get_actions():
	var tmp := actions.duplicate()
	actions.clear()
	return tmp

func check_root():
	if !is_instance_valid(root):
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
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var base_path := ''
	if 'base_path' in data:
		base_path = data.base_path
	var err := doc.append_from_buffer(content, base_path, state)
	if err == OK:
		var scene := doc.generate_scene(state)
		if root:
			asset_name += str(Time.get_unix_time_from_system())
		scene.name = asset_name
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

	if err != OK:
		return

	var rect := TextureRect.new()
	var tex := ImageTexture.create_from_image(img)
	rect.texture = tex
	var panel := preload('res://addons/Panel3D/Panel3D.tscn').instantiate()
	root.add_child(panel)
	panel.name = asset_name
	panel.set_viewport_scene(rect)
	panel.position.y = 2.0

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
