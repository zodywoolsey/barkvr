extends Node

var registered_actions:PackedStringArray = [
	'set_parent'
]

var actions:Array = []

var root:Node

func _ready():
	root = get_tree().get_first_node_in_group('localworldroot')

func get_actions():
	var tmp = actions
	actions = []
	return tmp

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
	if recieved:
		print('recd')
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

func net_propogate_node(node_string:String, parent:NodePath='', recieved=false):
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
