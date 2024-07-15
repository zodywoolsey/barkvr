class_name Network_Handler
extends Node

var peers : Array[Dictionary] = []

var packs : Array[PackedByteArray] = [PackedByteArray()]

var pack : PackedByteArray = PackedByteArray()
var packsize : int = 0
var packet_size : int = 100000

var bytes_to_send

var chat_timer :float = 0.0
var event_sync_timer :float = 0.0

var uname :String = ""

var current_room :String = ''

signal created_offer(data:Dictionary)
signal created_answer(data:Dictionary)
signal finished_candidates(data:Dictionary)

var close_requested := false

@onready var prev_time:float = Time.get_unix_time_from_system()

var thread = Thread.new()
var packetdict = {
	'p_id': OS.get_unique_id(),
	'uname': '',
	'user_pos': {
		'pos': Vector3(),
		'rhpos': Vector3(),
		'lhpos': Vector3()
	}
}

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F2:
			get_clipboard_connection_string()
		elif event.keycode == KEY_F3:
			apply_connection_string('offer')
		elif event.keycode == KEY_F4:
			create_new_peer_connection()
		elif event.keycode == KEY_F5:
			apply_connection_string('answer')
		elif event.keycode == KEY_F6:
			for peer in peers:
				Notifyvr.send_notification("connection state: "+str(peer.peer.get_connection_state()))
				Notifyvr.send_notification("gathering state: "+str(peer.peer.get_gathering_state()))
				Notifyvr.send_notification("signaling state: "+str(peer.peer.get_signaling_state()))

func get_clipboard_connection_string():
	var tmp
	if !peers.is_empty() and peers[0].has('offer'):
		tmp = str({
			"description": peers[0].offer,
			"candidates": peers[0].candidates
		})
	else:
		tmp = str({
			"description": peers[0].answer,
			"candidates": peers[0].candidates
		})
	DisplayServer.clipboard_set(tmp)
#	discord_sdk.join_secret = tmp
#	discord_sdk.state = "testing a session"
#	discord_sdk.refresh()

func apply_connection_string(type:String):
	var data = JSON.parse_string(DisplayServer.clipboard_get())
	if data and data.has('description') and data.has('candidates'):
		for peer in peers:
			if peer.peer.get_connection_state() == 1:
				pass
				#print('found peer1')
				#print(peer.peer.set_remote_description(type, data.description))
				#print('set remote desc1')

func _ready():
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_turn_server.connect(got_turn_server)
		Engine.get_singleton("user_manager").user_logged_in.connect(user_logged_in)
	thread.start(poll)
	BarkHelpers.rejoin_thread_when_finished(thread)
	get_window().close_requested.connect(func():
		close_requested = true
		thread.wait_to_finish()
		)

func user_logged_in():
	if is_instance_valid(Engine.get_singleton("user_manager")):
		uname = Engine.get_singleton("user_manager").userData.login.user_id.split(':')[0].right(-1)

func got_turn_server(data):
		if data.has('username'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_username',data.username)
		if data.has('password'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_password',data.password)
		if data.has('uris'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_servers',data.uris)

func reset():
	peers = []

func _physics_process(_delta):
	var player = get_tree().get_first_node_in_group('player')
	if player:
		packetdict.user_pos.pos = player.global_position
		if is_instance_valid(player.righthand):
			packetdict.user_pos.rhpos = player.righthand.global_position
		if is_instance_valid(player.lefthand):
			packetdict.user_pos.lhpos = player.lefthand.global_position
	#if !thread.is_alive() and thread.is_started():
		#print('thread died')
		#thread.wait_to_finish()
		#thread.start(poll)
	for peer in peers:
		if !is_instance_valid(peer):
			break
		var tmp = true
		for chan in peer.channels:
			if !is_instance_valid(peer):
				break
			if chan.channel.get_ready_state() != WebRTCDataChannel.STATE_OPEN:
				tmp = false
		peer.channels_ready = tmp

func poll():
	while !close_requested:
		var delta = Time.get_ticks_msec()-prev_time
		prev_time = Time.get_ticks_msec()
		chat_timer += delta
		event_sync_timer += delta
		if chat_timer < 0:
			chat_timer = 0
		if event_sync_timer < 0:
			event_sync_timer = 0
		for peer in peers:
			if is_instance_valid(peer.peer):
				peer.peer.poll()
				if peer.has('channels_ready') and peer.channels_ready:
					for chan in peer.channels:
						if !is_instance_valid(peer.peer):
							break
						#chan.channel.poll()
						if chan.label == 'social_sync_channel' and chat_timer > 8.3:
							if !is_instance_valid(peer.peer):
								break
							while chan.channel.get_available_packet_count() > 0:
								if !is_instance_valid(peer.peer):
									break
								var data = bytes_to_var(chan.channel.get_packet().decompress_dynamic(999999999999, 3))
								var remplayer = get_tree().get_first_node_in_group(data.p_id)
								if remplayer:
									remplayer.call_deferred('set_target_pos',data.user_pos.pos)
								else:
									var root = get_tree().get_first_node_in_group('localworldroot')
									var tmp:Node = load("res://mainSystem/scenes/player/remote player/remote player.tscn").instantiate()
									tmp.add_to_group(data.p_id)
									await root.call_deferred('add_child',tmp)
							if !is_instance_valid(peer.peer):
								break
							chat_timer = 0.0
							var packet = var_to_bytes(packetdict).compress(3)
							chan.channel.put_packet(packet)
						if chan.label == 'event_sync_channel' and event_sync_timer > 8.3:
							if is_instance_valid(Engine.get_singleton("event_manager")) and "receive" in Engine.get_singleton("event_manager") and "get_actions" in Engine.get_singleton("event_manager"):
								if !is_instance_valid(peer.peer):
									break
								var current_actions :Array[Dictionary] = Engine.get_singleton("event_manager").get_actions()
								# Sync from incoming data
								while chan.channel.get_available_packet_count() > 0:
									if !is_instance_valid(peer.peer):
										break
									print('getting available network events')
									var data = chan.channel.get_var(true)
									if data.has('pos') and data.pos != -1 and data.has('bytes'):
										pack.append_array(data.bytes)
										packsize += 1
									elif data.has('pos') and data.pos == -1:
										pack.append_array(data.bytes)
										packsize += 1
										data = bytes_to_var_with_objects(pack.decompress_dynamic(999999999999, 3))
										pack = PackedByteArray()
									if data and data is Array:
										for action in data:
											print("got action: "+str(action))
											Engine.get_singleton("event_manager").call_deferred("receive",action)
								# Send all new network events to the other users
								event_sync_timer = 0.0
								if !current_actions.is_empty():
									if !is_instance_valid(peer.peer):
										break
									print('putting actions: '+str(current_actions))
									bytes_to_send = var_to_bytes_with_objects(current_actions).compress(3)
									if bytes_to_send.size() < packet_size:
										chan.channel.put_var({
											'pos': -1,
											'bytes': bytes_to_send
										})
									else:
										if !is_instance_valid(peer.peer):
											break
										var parts:int = float(bytes_to_send.size())/packet_size
										for i:int in range(float(bytes_to_send.size())/packet_size):
											if !is_instance_valid(peer.peer):
												break
											var pack_dict = {}
											if i < parts-1: 
												pack_dict['pos'] = i
												pack_dict['bytes'] = bytes_to_send.slice(i*packet_size, (i*packet_size)+packet_size)
											else:
												pack_dict['bytes'] = bytes_to_send.slice(i*packet_size)
												pack_dict['pos'] = -1
					#							print('err: ',chan.put_var(pack_dict))
											var err = chan.channel.put_var(pack_dict)
											if err != OK:
												#print("Network handler, channel.put_var"+str(err))
												pass
					if !is_instance_valid(peer.peer):
						break
			else:
				peers.erase(peer)

## Takes an optional offer_string, and an optional for_user string
## offer_string will automatically set a remote offer description for the created peer
## for_user attached data to the peer data stored in the list of peers that tell which user it's meant for
func create_new_peer_connection(offer_string:String='', for_user:String=''):
	var peer = WebRTCPeerConnection.new()
#	print('created peer')
	# init the webrtc peer with the public google ice server
	var ice = [
			{
				"urls": Array(ProjectSettings.get_setting(
					'bark/webrtc_config/stun_servers',
				[
					"stun:stun.l.google.com:19302",
					"stun:stun1.l.google.com:19302",
					"stun:stun2.l.google.com:19302",
					"stun:stun3.l.google.com:19302",
					"stun:stun4.l.google.com:19302"
					]
				))
			}
		]
	if ProjectSettings.get_setting('bark/webrtc_config/turn_servers') and ProjectSettings.get_setting('bark/webrtc_config/turn_password') and ProjectSettings.get_setting('bark/webrtc_config/turn_username'):
		ice.append({
			'urls':Array(ProjectSettings.get_setting('bark/webrtc_config/turn_servers')),
			'username':ProjectSettings.get_setting('bark/webrtc_config/turn_username'),
			'credentials':ProjectSettings.get_setting('bark/webrtc_config/turn_password')
		})
	var tmp = peer.initialize({
		"iceServers": ice
	})
	assert(tmp == OK)
#	print('initialized new peer')
	var peer_dict = {
		'peer': peer,
		'channels': [{
			'channel':peer.create_data_channel("social_sync_channel", {
				'id':1,
				'negotiated': true,
				'maxPacketLifeTime': 500
				}),
			'label':'social_sync_channel'
		},
		{
			'channel':peer.create_data_channel("event_sync_channel", {
				'id':2,
				'negotiated': true,
				'ordered': true
				}),
			'label':'event_sync_channel'
		}
		],
		'for_user': for_user,
		'candidates': [],
		'set_remote': false
		}
	
	# connect functions
	peer.ice_candidate_created.connect(_on_ice_candidate.bind(peer_dict))
	peer.session_description_created.connect(description_created.bind(peer_dict))
	# add peer to list of peers
	peers.append(peer_dict)
	# if there is an offer to use, use it
	if offer_string:
		peer.set_remote_description("offer",offer_string)
		peer_dict.set_remote = true
	else: # otherwise, create an offer
		tmp = peer.create_offer()
		assert(tmp == OK)

func _on_ice_candidate(media, index, ice_name, data:Dictionary):
	#print("ice:")
	#print("media: ",str(media),"\nindex: ",str(index),"\nname: ",str(ice_name))
	data.candidates.append({
		'name':ice_name,
		'media':media,
		'index':index
		})
#	if data.candidates.size() >= 4:
	call_deferred('emit_signal','finished_candidates', data)
	

func description_created(type:String, sdp:String, data:Dictionary):
#	print("type: ",type,"\nsdp: ",sdp)
	#print('set local description'+"\ntype: "+type)
	if sdp.contains('actpass'):
		sdp = sdp.replace('actpass', 'passive')
	data.peer.set_local_description(type,sdp)
	if type == 'offer':
		data.offer = sdp
		call_deferred('emit_signal','created_offer',data)
	if type == 'answer':
		data.answer = sdp
		call_deferred('emit_signal','created_answer',data)
