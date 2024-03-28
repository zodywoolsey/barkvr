extends Button
@onready var text_edit = $"../TextEdit"
@onready var item_list = $"../../../../ItemList"

func _ready():
	pressed.connect(func():
		Vector.send_room_event(item_list.get_selected().get_metadata(0)['room_id'], 'm.room.message', {
		  "body": text_edit.text,
		  "msgtype": "m.text"
		})
		text_edit.clear()
		text_edit.release_focus()
		)
