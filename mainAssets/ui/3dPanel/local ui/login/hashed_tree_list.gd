class_name hashed_tree_list
extends Tree
var tree:Dictionary = {}

func add_item(text:String,metadata:Variant,replace:String=''):
	if replace and tree.has(replace):
		tree[replace]['name'] = text
		tree[replace]['tree_item'].call_deferred("set_text",0,text)
		tree[replace]['tree_item'].call_deferred("set_metadata",0, metadata)
		tree[replace]['tree_item'].visible = true
	elif tree.has(text):
		tree[replace]['name'] = text
		tree[replace]['tree_item'].call_deferred("set_text",0,text)
		tree[replace]['tree_item'].call_deferred("set_metadata",0, metadata)
		tree[replace]['tree_item'].visible = true
	elif metadata and metadata.has('state'):
		var roomdict = {
			"name": text,
			"tree_item": create_item()
		}
		for event in metadata["state"]:
			match event.type:
				"m.space.child":
					if tree.has(event['state_key']):
						await get_tree().process_frame
						var parent = tree[event['state_key']]['tree_item'].get_parent()
						if is_instance_valid(parent):
							parent.remove_child(tree[event['state_key']]['tree_item'])
						roomdict['tree_item'].add_child(tree[event['state_key']]['tree_item'])
					else:
						tree[event["state_key"]] = {
							"name": event["state_key"],
							"tree_item": create_item(roomdict["tree_item"]),
							"parent": metadata['room_id']
						}
						tree[event['state_key']]['tree_item'].set_text(0,event['state_key'])
		var room_id = metadata["room_id"]
		tree[room_id] = roomdict
		roomdict['tree_item'].set_text(0,text)
		roomdict['tree_item'].set_metadata(0,metadata)
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
				tree[item_id] = {
					'node': metadata.node
				}
				if metadata.has('parent'):
					tree[item_id].tree_item = create_item(tree[metadata.parent.get_instance_id()].tree_item)
				else:
					tree[item_id].tree_item = create_item()
				tree[item_id].tree_item.collapsed = true
				tree[item_id].tree_item.set_text(0,text)
				tree[item_id].tree_item.set_metadata(0,metadata)

func check_children():
	for key in tree:
		if tree[key].has('node') and !is_instance_valid(tree[key].node):
			if is_instance_valid(tree[key].tree_item):
				tree[key].tree_item.free()
			tree.erase(key)


