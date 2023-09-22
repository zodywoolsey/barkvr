extends Node

var registered_actions:PackedStringArray = [
	'set_parent'
]

const vrm_import_extension = preload("res://addons/vrm/vrm_extension.gd")

var actions:Array = []

var root:Node

func _ready():
	root = get_tree().get_first_node_in_group('localworldroot')

func get_actions():
	var tmp = actions
	actions = []
	return tmp

func check_root():
	if !is_instance_valid(root):
		root = get_tree().get_first_node_in_group('localworldroot')

func set_parent(target:NodePath, new_parent:NodePath):
	var t_node = root.get_node(target)
	var np_node = root.get_node(new_parent)
	t_node.reparent(np_node)
	actions.append({
		'action_name':'set_parent',
		'target': target,
		'new_parent': new_parent
		})

func set_property(target:NodePath, prop_name:String, value:Variant, recieved=false):
	var t_node:Node = root.get_node(target)
	if is_instance_valid(t_node) and prop_name.split(':')[0] in t_node:
#		print(prop_name)
		t_node.get_indexed(prop_name)
		t_node.set_indexed(prop_name,value)
		if !recieved:
			actions.append({
				'action_name':'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value
			})

func net_propogate_node(node_string:String, parent:NodePath='', recieved:=false):
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

func net_propogate_resource(res, recieved:=false):
	print(res)

func import_asset(type:String, asset_to_import:PackedByteArray, asset_name:='', recieved:=false):
	if !asset_name:
		asset_name = str(asset_to_import)
		print(asset_name)
	if type == 'vrm' and asset_to_import and asset_to_import is PackedByteArray:
		var doc:GLTFDocument = GLTFDocument.new()
		var state:GLTFState = GLTFState.new()
		var vrm_extension: GLTFDocumentExtension = vrm_import_extension.new()
		doc.register_gltf_document_extension(vrm_extension, true)
		doc.append_from_buffer(asset_to_import,'',state)
		var scene = doc.generate_scene(state)
		scene.name = asset_name
		get_tree().get_first_node_in_group('localworldroot').add_child(scene)
		if !recieved:
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': asset_to_import
			})
	elif type == 'glb' and asset_to_import and asset_to_import is PackedByteArray:
		var doc:GLTFDocument = GLTFDocument.new()
		var state:GLTFState = GLTFState.new()
		doc.append_from_buffer(asset_to_import,'',state)
		var scene = doc.generate_scene(state)
		scene.name = asset_name
		get_tree().get_first_node_in_group('localworldroot').add_child(scene)
		if !recieved:
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': asset_to_import
			})
