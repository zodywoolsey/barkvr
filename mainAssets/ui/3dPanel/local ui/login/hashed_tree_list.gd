class_name hashed_tree_list
extends Tree
var tree:Dictionary = {}

func add_item(text:String,metadata:Variant,replace:String=''):
	if metadata and 'state' in metadata and 'room_id' in metadata:
		var room_id = metadata["room_id"]
		var roomdict = {}
		if room_id in tree:
			roomdict = tree[room_id]
		else:
			roomdict = {
				"name": text,
				"tree_item": create_item()
			}
		for event in metadata["state"]:
			match event.type:
				"m.space.child":
					if event['state_key'] in Engine.get_singleton('user_manager').joinedRooms:
						if tree.has(event['state_key']):
							var parent = tree[event['state_key']]['tree_item'].get_parent()
							if is_instance_valid(parent):
								parent.remove_child(tree[event['state_key']]['tree_item'])
							roomdict['tree_item'].add_child(tree[event['state_key']]['tree_item'])
						else:
							tree[event["state_key"]] = {
								"name": event["state_key"],
								"tree_item": create_item(roomdict["tree_item"])
							}
							tree[event['state_key']]['tree_item'].set_text(0,event['state_key'])
				"m.space.parent":
					if tree.has(event['state_key']):
						if is_instance_valid(roomdict.tree_item.get_parent()):
							roomdict.tree_item.get_parent().remove_child(roomdict.tree_item)
						tree[event.state_key].tree_item.add_child(roomdict.tree_item)
					else:
						tree[event["state_key"]] = {
							"name": event["state_key"],
							"tree_item": create_item()
						}
						tree[event['state_key']]['tree_item'].set_text(0,event['state_key'])
						if is_instance_valid(roomdict.tree_item.get_parent()):
							roomdict.tree_item.get_parent().remove_child(roomdict.tree_item)
						tree[event.state_key].tree_item.add_child(roomdict.tree_item)
				"m.room.name":
					if "content" in event and "name" in event.content:
						roomdict.name = event.content.name
				"m.room.power_levels":
					if "content" in event and "users" in event.content:
						if event.content.users is Dictionary:
							if event.content.users.size() == 2:
								roomdict.name = event.content.users.keys()[1] if \
								event.content.users.keys()[0] == Engine.get_singleton("user_manager").uid else\
								 event.content.users.keys()[0]
		roomdict['tree_item'].set_text(0,roomdict.name)
		roomdict['tree_item'].set_metadata(0,metadata)
		tree[room_id] = roomdict
	elif metadata and metadata.has('node'):
		if is_instance_valid(metadata.node):
			var item_id = metadata.node.get_instance_id()
			if tree.has(item_id):
				if metadata.has('parent'):
					var parent = tree[item_id].tree_item.get_parent()
					if is_instance_valid(parent):
						parent.remove_child(tree[item_id].tree_item)
					tree[metadata.parent.get_instance_id()].tree_item.add_child(tree[item_id].tree_item)
				tree[item_id].tree_item.set_text(0,text)
				tree[item_id].tree_item.set_metadata(0,metadata)
			else:
				var tmp_tree_item:TreeItem
				tree[item_id] = {
					'node': metadata.node
				}
				if metadata.has('parent'):
					if !tree.has(metadata.parent.get_instance_id()):
						add_item(metadata.parent.name, {
							'node':metadata.parent,
							'parent':metadata.parent.get_parent()
						})
					var parent_item :TreeItem = tree[metadata.parent.get_instance_id()].tree_item
					tmp_tree_item = create_item(parent_item)
					#tmp_tree_item.add_button(0,load("res://assets/icons/teenyicons/solid/bin.svg"))
					tree[item_id].tree_item = tmp_tree_item
				else:
					tree[item_id].tree_item = create_item()
					#tree[item_id].tree_item.add_button(0,load("res://assets/icons/teenyicons/solid/bin.svg"))
				tree[item_id].tree_item.collapsed = true
				tree[item_id].tree_item.set_text(0,text)
				tree[item_id].tree_item.set_metadata(0,metadata)

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
