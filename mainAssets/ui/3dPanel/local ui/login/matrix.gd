extends Control
@onready var item_list = $chat/HBoxContainer/ItemList
@onready var chat = $chat
@onready var login_existing :OptionButton= $login/Button
@onready var login = $login


func _ready():
	login_existing.get_popup().hide_on_checkable_item_selection = false
	login_existing.get_popup().hide_on_item_selection = false
	login_existing.get_popup().hide_on_state_item_selection = false
	login_existing.item_selected.connect(func(index):
		if login_existing.get_item_text(index) != "existing logins":
			Vector.readUserDict(login_existing.get_item_text(index))
		)
	login_existing.toggled.connect(func(toggled_on):
		if toggled_on:
			login_existing.clear()
			login_existing.add_item("existing logins",0)
			for session : String in Vector.getExistingSessions():
				login_existing.add_item(session)
			)
	Vector.got_joined_rooms.connect(func():
		add_items(Vector.joinedRooms)
		)
	Vector.user_logged_in.connect(func():
		if Vector.joinedRooms:
			add_items(Vector.joinedRooms)
		else:
			Vector.get_joined_rooms()
		Vector.sync()
		chat.show()
		login.hide()
		)
	Vector.got_room_state.connect(func(data):
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

