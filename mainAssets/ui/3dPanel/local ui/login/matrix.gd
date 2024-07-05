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
		if is_instance_valid(Engine.get_singleton("user_manager")):
			if login_existing.get_item_text(index) != "existing logins":
				Engine.get_singleton("user_manager").readUserDict(login_existing.get_item_text(index))
		)
	login_existing.toggled.connect(func(toggled_on):
		if toggled_on and is_instance_valid(Engine.get_singleton("user_manager")):
			login_existing.clear()
			login_existing.add_item("existing logins",0)
			for session : String in Engine.get_singleton("user_manager").getExistingSessions():
				login_existing.add_item(session)
			)
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_joined_rooms.connect(func():
			add_items(Engine.get_singleton("user_manager").joinedRooms)
			)
		Engine.get_singleton("user_manager").user_logged_in.connect(func():
			if Engine.get_singleton("user_manager").joinedRooms:
				add_items(Engine.get_singleton("user_manager").joinedRooms)
			else:
				Engine.get_singleton("user_manager").get_joined_rooms()
			Engine.get_singleton("user_manager").sync()
			chat.show()
			login.hide()
			)
		Engine.get_singleton("user_manager").got_room_state.connect(func(data):
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
	if items is Array and is_instance_valid(Engine.get_singleton("user_manager")):
		for i in items:
			Engine.get_singleton("user_manager").get_room_state(i)

func loggedIn():
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").sync()

