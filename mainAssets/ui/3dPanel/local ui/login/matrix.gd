extends Control
@onready var item_list = $chat/HBoxContainer/ItemList
@onready var chat = $chat
@onready var login_existing = $login/Button
@onready var login = $login

func _ready():
	login_existing.pressed.connect(func():
		Vector.readUserDict()
		)
	Vector.got_joined_rooms.connect(func():
		# print(Vector.joinedRooms)
		add_items(Vector.joinedRooms)
		)
	Vector.user_logged_in.connect(func():
		if Vector.joinedRooms:
			add_items(Vector.joinedRooms)
		else:
			Vector.get_joined_rooms()
		chat.show()
		login.hide()
		)
	Vector.got_room_state.connect(func(data):
		if data.response_code and data.response_code == 200:
			var name
			var avatar
			var roomId
			for event in data.body:
				roomId = event['room_id']
				if event['type'] == "m.room.name":
					name = event['content']['name']
#				if event['type'] == 'm.room.avatar':
#					var tmp = HTTPRequest.new()
#					get_tree().get_first_node_in_group("requestParent").add_child(tmp)
#					var avatarUrl = event['content']['url']
#					var avatarServer = avatarUrl.split('/')[2]
#					var mediaId = avatarUrl.split('/')[3]
#					tmp.download_file = "user://cache/avatars/"+roomId
#					tmp.request(
#						"{0}_matrix/media/v3/download/{1}/{2}".format([Vector.base_url,avatarServer,mediaId]),
#						Vector.headers,
#						HTTPClient.METHOD_GET
#						)
#					await tmp.request_completed
#					print(FileAccess.file_exists("user://cache/avatars/"+roomId))
				await get_tree().process_frame
			var tmp
			if name:
				tmp = await item_list.add_item(name,{
					'state': data.body,
					'room_id': roomId
				})
			else:
				tmp = await item_list.add_item(roomId.split(':')[0].right(-1),{
					'state': data.body,
					'room_id': roomId
				})
			
		)

func add_items(items):
	if items is Array:
		for i in items:
			var state = Vector.api.get_room_state(i)

func loggedIn():
#	Vector.get_joined_rooms()
	Vector.sync()
