class_name matrix_hashed_tree
extends Tree
@onready var messages = %messages

## the current room for displaying messages
var target_room : String = ""
## the room that the user is in a VR session in
var current_session_room : String = ""
@onready var join_button:Button = %"join button"

## the dictionary that holds all the objects, 
## their data, and corresponding TreeItem
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
				"tree_item": create_item(),
				"users": {}
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
								"tree_item": create_item(roomdict["tree_item"]),
								"users": {}
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
							"tree_item": create_item(),
							"users": {}
						}
						tree[event['state_key']]['tree_item'].set_text(0,event['state_key'])
						if is_instance_valid(roomdict.tree_item.get_parent()):
							roomdict.tree_item.get_parent().remove_child(roomdict.tree_item)
						tree[event.state_key].tree_item.add_child(roomdict.tree_item)
				"m.room.name":
					if "content" in event and "name" in event.content:
						roomdict.name = event.content.name
				"m.room.power_levels":
					pass
				"m.room.member":
					if "content" in event and "membership" in event.content and "displayname" in event.content:
						match event.content.membership:
							"join":
								if "users" not in roomdict:
									roomdict.users = {}
								if event.state_key not in roomdict.users:
									roomdict.users[event.state_key] = {}
								roomdict.users[event.state_key]["displayname"] = event.content.displayname
		if roomdict.users.size() == 2:
			for user in roomdict.users:
				var tmp = Engine.get_singleton("user_manager").userData.login.user_id
				if user != Engine.get_singleton("user_manager").uid:
					roomdict.name = roomdict.users[user].displayname
		roomdict['tree_item'].set_text(0,roomdict.name)
		roomdict['tree_item'].set_metadata(0,metadata)
		tree[room_id] = roomdict

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


func _ready():
	item_selected.connect(func():
		if get_selected().get_metadata(0) && get_selected().get_metadata(0).has('room_id') and is_instance_valid(Engine.get_singleton("user_manager")):
			target_room = get_selected().get_metadata(0)['room_id']
			messages.set_room(target_room)
			_check_room_messages()
		)
	join_button.pressed.connect(func():
		if is_instance_valid(Engine.get_singleton("user_manager")) and Engine.get_singleton("network_manager"):
			Engine.get_singleton("network_manager").reset()
			Engine.get_singleton("user_manager").send_room_event(
				target_room,
				'bark.session.request',
				{}
			)
		)


func _check_room_messages():
	if target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").get_room_messages(target_room)
