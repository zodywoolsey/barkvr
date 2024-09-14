extends hashed_tree_list
@onready var messages = %messages

var target_room:String = ''
@onready var join_button:Button = %"join button"

func _ready():
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_room_messages.connect(func(_data:Dictionary):
			_check_room_messages()
			)
	item_selected.connect(func():
		if get_selected().get_metadata(0) && get_selected().get_metadata(0).has('room_id') and is_instance_valid(Engine.get_singleton("user_manager")):
			Engine.get_singleton("user_manager").get_room_messages(get_selected().get_metadata(0)['room_id'])
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
	else:
		get_tree().create_timer(.1).timeout.connect(_check_room_messages)
