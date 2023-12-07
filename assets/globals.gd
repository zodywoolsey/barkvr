extends Node

enum {MENU, SETTLE, PLAYING, PAUSED, BUILDER}
var game_state = 0

func node_to_dict(node:Node) -> Dictionary:
	var out: Dictionary = {}
	if node.get_child_count() > 0:
		var children := Array()
		for child in node.get_children():
			children.append(node_to_dict(child))
		out.children = children
	out.node = var_to_str(node)
	return out

func dict_to_node(dict:Dictionary) -> Node:
	var node:Node
	if dict.has('node'):
		node = str_to_var(dict.node)
		if dict.has('children'):
			for child in dict.children:
				node.add_child(dict_to_node(child))
	return node
