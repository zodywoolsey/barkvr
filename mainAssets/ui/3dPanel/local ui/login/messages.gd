extends Control

var prevmessages:Dictionary

func _ready():
	Vector.got_room_messages.connect(func(data):
		print('got messages')
		if var_to_bytes(data).size() != var_to_bytes(prevmessages).size():
			for child in get_children():
				child.queue_free()
			for event in data['body']['chunk']:
				if event['type'] == 'm.room.message':
					if event.has('content') and event['content'].has('body') :
						var tmp = preload("res://mainAssets/ui/3dPanel/local ui/login/message.tscn").instantiate()
						tmp.text = (
							"[b][u]"+event.sender.split(':')[0].right(-1)+'[/u][/b]:\n'+event.content.body
							)
						if event.sender == Vector.userData.login.user_id:
							tmp.leftside = false
						add_child(tmp)
			prevmessages = data
		)
	if get_parent() is ScrollContainer:
		get_parent().scroll_vertical = 999999999
