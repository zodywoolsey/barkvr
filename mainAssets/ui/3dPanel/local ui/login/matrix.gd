extends Control
@onready var item_list = $chat/HBoxContainer/ItemList
@onready var chat = $chat
@onready var login_existing :OptionButton= $login/Button
@onready var login = $login


func _ready():
	login_existing.item_selected.connect(func(index):
		print(login_existing.get_popup().get_child_count(true))
		#Vector.readUserDict()
		)
	Vector.got_joined_rooms.connect(func():
		print(Vector.joinedRooms)
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
		print(data)
		if data.response_code and data.response_code == 200:
			var tmp_name
			#var avatar
			var roomId
			for event in data.body:
				roomId = event['room_id']
				if event['type'] == "m.room.name":
					tmp_name = event['content']['name']
				await get_tree().process_frame
			var _tmp
			if tmp_name:
				_tmp = await item_list.add_item(tmp_name,{
					'state': data.body,
					'room_id': roomId
				}, roomId )
			else:
				_tmp = await item_list.add_item(roomId.split(':')[0].right(-1),{
					'state': data.body,
					'room_id': roomId
				}, roomId )
			
		)

func add_items(items):
	if items is Array:
		for i in items:
			Vector.api.get_room_state(i)

func loggedIn():
	Vector.sync()

