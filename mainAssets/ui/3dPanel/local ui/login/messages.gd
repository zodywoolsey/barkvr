extends Control

var prevmessages:Dictionary
var requesting_user:String = ''
var target_room:String = ''
var already_processed_requests := []
var already_processed_offers := []
var already_processed_answers := []
@onready var item_list := $"../../../../../ItemList"
@onready var scroll_container := $".."
@onready var text_edit = $"../../../Control/TextEdit"

func _ready():
	if is_instance_valid(Engine.get_singleton("network_manager")):
		Engine.get_singleton("network_manager").created_offer.connect(offer_created)
		Engine.get_singleton("network_manager").created_answer.connect(answer_created)
		Engine.get_singleton("network_manager").finished_candidates.connect(candidates_finished)
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_room_messages.connect(func(data):
			if var_to_bytes(data).size() != var_to_bytes(prevmessages).size():
	#			for child in get_children():
	#				child.queue_free()
				if data and data.has('body') and data.body.has('chunk'):
					data.body.chunk.reverse()
				for event in data['body']['chunk']:
					match event['type']:
						'm.room.message':
							_display_message(event)
						'bark.session.request':
							if is_instance_valid(Engine.get_singleton("network_manager")):
								_display_message(event)
								if event.event_id not in already_processed_requests:
									already_processed_requests.append(event.event_id)
									if event.sender != Engine.get_singleton("user_manager").userData.login.user_id:
										if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
											Engine.get_singleton("network_manager").create_new_peer_connection('',event.sender)
											requesting_user = event.sender
											Notifyvr.send_notification('got request')
						'bark.session.offer':
							if is_instance_valid(Engine.get_singleton("network_manager")):
								_display_message(event)
								if event.event_id not in already_processed_offers:
									already_processed_offers.append(event.event_id)
									if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
										if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
											Engine.get_singleton("network_manager").create_new_peer_connection(event.content.sdp,event.sender)
											Notifyvr.send_notification('got offer')
						'bark.session.answer':
							if is_instance_valid(Engine.get_singleton("network_manager")):
								_display_message(event)
								if event.event_id not in already_processed_answers:
									already_processed_answers.append(event.event_id)
									if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts:
										if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
											for peer in Engine.get_singleton("network_manager").peers:
												if peer.for_user == event.sender:
													peer.peer.set_remote_description('answer',event.content.sdp)
													peer.set_remote = true
													Notifyvr.send_notification('got answer')
						'bark.session.ice':
							if is_instance_valid(Engine.get_singleton("network_manager")):
								_display_message(event)
								if Time.get_unix_time_from_system()*1000.0-10000 < event.origin_server_ts and event.event_id not in already_processed_answers:
									if event.content.for_user == Engine.get_singleton("user_manager").userData.login.user_id:
										for peer in Engine.get_singleton("network_manager").peers:
											if peer.for_user == event.sender:
												if peer.set_remote:
													already_processed_answers.append(event.event_id)
													for candidate in event.content.candidates:
														peer.peer.add_ice_candidate(
															candidate.media,
															candidate.index,
															candidate.name
														)
														Notifyvr.send_notification('set_ice')
				prevmessages = data
			)

func _display_message(event):
	if event.has('content'):
		if event.room_id == target_room:
			var exists = false
			for i in get_children():
				if i.name == event.event_id:
					exists = true
	#									break
			if !exists:
				var tmp = preload("res://mainAssets/ui/3dPanel/local ui/login/message.tscn").instantiate()
				tmp.name = event.event_id
				if event['content'].has('body'):
					tmp.text = (
						"[b][u]"+event.sender.split(':')[0].right(-1)+'[/u][/b]:\n'+event.content.body
						)
				else:
					tmp.text = str(event)
				if is_instance_valid(Engine.get_singleton("user_manager")) and event.sender == Engine.get_singleton("user_manager").userData.login.user_id:
					tmp.leftside = false
				if scroll_container.scroll_vertical == size.y:
					add_child(tmp)
					move_child(tmp,0)
					scroll_container.scroll_vertical = size.y
				else:
					add_child(tmp)
					move_child(tmp,0)

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		text_edit.release_focus()

func offer_created(data:Dictionary):
	if data.for_user == requesting_user and target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.offer',
			{
				'sdp':data.offer,
				'for_user':data.for_user
			}
		)
		Notifyvr.send_notification('sent offer')

func answer_created(data:Dictionary):
	if target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.answer',
			{
				'sdp':data.answer,
				'for_user':data.for_user
			}
		)
		Notifyvr.send_notification('sent answer')

func candidates_finished(data:Dictionary):
	if target_room and is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").send_room_event(
			target_room,
			'bark.session.ice',
			{
				'candidates':data.candidates,
				'for_user': data.for_user
			}
		)

func set_room(new_room):
	target_room = new_room
	for child in get_children():
		child.queue_free()
