extends hashed_tree_list
@onready var messages = $"../RoomSplitContainer/MessageSplitContainer/ScrollContainer/Control"

var target_room:String = ''
@onready var join_button:Button = $"../RoomSplitContainer/Panel/join button"

func _ready():
	Vector.got_room_messages.connect(_check_room_messages)
	item_selected.connect(func():
		if get_selected().get_metadata(0) && get_selected().get_metadata(0).has('room_id'):
			Vector.get_room_messages(get_selected().get_metadata(0)['room_id'])
			target_room = get_selected().get_metadata(0)['room_id']
			messages.set_room(target_room)
			_check_room_messages()
		else:
			get_selected().visible = false
		)
	join_button.pressed.connect(func():
		NetworkHandler.reset()
		Vector.send_room_event(
			target_room,
			'bark.session.request',
			{}
		)
		)


func _check_room_messages():
	if target_room:
		Vector.get_room_messages(target_room)
	else:
		get_tree().create_timer(.1).timeout.connect(_check_room_messages)
