extends Node

func node_to_var(node:Node, type:String=''):
	var dict:Dictionary = {}
	if type:
		dict['asset_type'] = type
	dict['node'] = var_to_bytes_with_objects(node)
	dict['groups'] = PackedStringArray()
	for group in node.get_groups():
		if !group.begins_with("_"):
			dict.groups.append(group)
	if node.get_child_count() > 0:
		var children : Array = []
		for i in node.get_children():
			children.append(node_to_var(i))
		dict['children']=children
	return dict

func var_to_node(item:String='', dict:Dictionary={}):
	if dict.is_empty() and !item.is_empty():
		dict = JSON.parse_string(item)
	if !dict.is_empty():
		var node :Node = bytes_to_var_with_objects(dict.node)
		if dict.has('groups') and dict['groups'].size()>0:
			for group in dict.groups:
				node.add_to_group(group)
		if dict.has('children'):
			for child in dict.children:
				node.add_child(var_to_node('',child))
		print(node)
		return node
