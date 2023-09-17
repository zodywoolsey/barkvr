extends Control

var prevmessages:Dictionary
var requesting_user:String = ''
@onready var item_list = $"../../../../ItemList"

func _ready():
	NetworkHandler.created_offer.connect(offer_created)
	Vector.got_room_messages.connect(func(data):
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
				if event.type == 'bark.session.request':
					if item_list.target_room == NetworkHandler.current_room and event.sender != Vector.userData.login.user_id:
						NetworkHandler.create_new_peer_connection('',event.sender)
						requesting_user = event.sender
						await NetworkHandler.created_offer
			prevmessages = data
		)
	if get_parent() is ScrollContainer:
		get_parent().scroll_vertical = 999999999

func offer_created(data:Dictionary):
#	print("type: ",type,"\nsdp: ",sdp)
	if data.for_user == requesting_user:
		print('created offer')
