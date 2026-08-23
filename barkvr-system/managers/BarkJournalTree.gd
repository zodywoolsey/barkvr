class_name BarkJournalTree
extends Node

## the dictionary that holds all the objects, 
## their data, and corresponding TreeItem
var tree:Dictionary = {}

var root:Node

func _ready() -> void:
	root = get_tree().get_first_node_in_group("localworldroot")
	while !root:
		await get_tree().process_frame
		root = get_tree().get_first_node_in_group("localworldroot")
	add_item(root.name,{
		'node':root
	})
	get_tree().node_added.connect(func(node:Node):
		if is_inside_tree():
			await get_tree().process_frame
			if root:
				if is_instance_valid(node) and root.is_ancestor_of(node):
					var nodename :String = node.name
					if node.has_meta('display_name'):
						nodename = node.get_meta('display_name')
					add_item(nodename, {
						'node':node,
						'parent':node.get_parent()
					})
		)
	get_tree().node_renamed.connect(func(node:Node):
		#print('node renamed')
		#await get_tree().process_frame
		if root:
			if is_instance_valid(node):
				update_item(node)
		)
	get_tree().node_removed.connect(func(node:Node):
		remove_item(node)
		)
	check_children()

func hashed_tree_clear():
	tree.clear()

func add_item(_text:String,metadata:Variant,_replace:String=''):
	if metadata and metadata.has('node'):
		if is_instance_valid(metadata.node):
			pass
			#var item_id = metadata.node.get_instance_id()
			#if tree.has(item_id):
				#if metadata.has('parent'):
					#var parent = tree[item_id].tree_item.get_parent()
					#tree[metadata.parent.get_instance_id()].tree_item.add_child(tree[item_id].tree_item)
				#tree[item_id].tree_item.text = text
				#tree[item_id].tree_item.metadata = metadata
			#else:
				#tree[item_id] = {
					#'node': metadata.node,
					#'tree_item': {}
				#}
				#if metadata.has('parent'):
					#if !tree.has(metadata.parent.get_instance_id()):
						#add_item(metadata.parent.name, {
							#'node':metadata.parent,
							#'parent':metadata.parent.get_parent()
						#})
				#
				#tree[item_id].tree_item.collapsed = true
				#tree[item_id].tree_item.text = text
				#tree[item_id].tree_item.metadata = metadata

func check_children() -> void:
	for key in tree:
		if tree[key].has('node') and !is_instance_valid(tree[key].node):
			if is_instance_valid(tree[key].tree_item):
				tree[key].tree_item.free()
			tree.erase(key)

func remove_item(target:Variant) -> void:
	if target is Node:
		var node:Node=target
		var item_id := node.get_instance_id()
		if tree.has(item_id):
			if is_instance_valid(tree[item_id].tree_item):
				tree[item_id].tree_item.free()
			tree.erase(item_id)
	elif target is String:
		if tree.has(target):
			if is_instance_valid(tree[target].tree_item):
				tree[target].tree_item.free()
			tree.erase(target)

func update_item(node:Node) -> void:
	var item_id := node.get_instance_id()
	if tree.has(item_id):
		if is_instance_valid(tree[item_id].tree_item):
			if node.has_meta("display_name"):
				tree[item_id].tree_item.set_text(0,node.get_meta("display_name"))
			else:
				tree[item_id].tree_item.set_text(0,node.name)
