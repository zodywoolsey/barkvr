@tool
class_name BarkMessageContainer
extends Control
var message_scene = preload("res://mainAssets/ui/3dPanel/local ui/login/message.tscn")

func _ready():
	Vector.got_room_messages.connect(func(data):
		for child in get_children():
			child.queue_free()
		for event in data['body']['chunk']:
			if event['type'] == 'm.room.message':
				if event.has('content') and event['content'].has('body'):
					var msg:message_bubble = message_scene.instantiate()
					if event.has('sender') and event.sender == Vector.userData.login.user_id:
						msg.leftside = false
					msg.text = event['content']['body']
					add_child(msg)
		)

func _notification(what):
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		custom_minimum_size.y = 0.0
		size.y = 0.0
		var height = 0
		for child in get_children():
			print(height)
			child.position.y = height
			height += child.size.y
		custom_minimum_size.y = height
		size.y = height
