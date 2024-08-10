extends ScrollListContainer

var message_scene = preload("res://mainAssets/ui/3dPanel/local ui/login/message.tscn")

func _ready():
	Vector.got_room_messages.connect(func(data):
		print('got messages')
		for child in get_children():
			child.queue_free()
		for event in data['body']['chunk']:
			if event['type'] == 'm.room.message':
				if event.has('content') and event['content'].has('body'):
					var message = message_scene.instantiate()
					message.text = event['content']['body']
					add_child(message)
		)
