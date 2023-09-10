extends ItemList


func _ready():
	Vector.got_room_messages.connect(func(data):
		print('got messages')
		clear()
		for event in data['body']['chunk']:
			if event['type'] == 'm.room.message':
				if event.has('content') and event['content'].has('body') : add_item(event['content']['body'])
		)
