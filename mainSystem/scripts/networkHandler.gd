class_name Network_Handler
extends Node

# todo: USER FLOW STUFF:
# 			user clicks on room to open room
# 			displays button for joining the session
# 			when attempting session join, look for nearest barksession room event
# 			if room event is alive, find all following and attempt to create data channels for each
# 			if room event is dead, send new offer event and startup the world

# todo: for initial start of world:
# 			create a starter journal that will generate the base, which should cause each object to have an id
# 			for ids, just increment unsigned int. Use int in object metadata and in global journal lookup dict
# 			use dictionary with unsigned int keys for each tick as journal entries for now
# 			120hz tickrate for journal, send events that happened since last tick, enforce ordered (default)

# idea for networking:
# 			- voip is secondary task
# 			- 1: sync player positions
# 			- 2: login
# 			- 3: session handshake
# 			- 4: make sure still syncing pos
# 			- 5: setup basic journal and oid generation
# 			- 6: sync basic journal

var peers : Array = []

var packs : Array[PackedByteArray] = [PackedByteArray()]

var pack : PackedByteArray = PackedByteArray()
var packsize : int = 0
var packet_size : int = 100000

var bytes_to_send

var local_description : String

var candidates : Array = []

var chat_timer :float = 0.0
var journal_timer :float = 0.0

var uname :String = ""

var current_room :String = ''

#var audioshit:Dictionary = {}
var capture:AudioEffectCapture
var mic_playback:MicPlayback

signal created_offer(data:Dictionary)
signal created_answer(data:Dictionary)
signal finished_candidates(data:Dictionary)

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

func get_clipboard_connection_string():
	var tmp = str({
		"description": local_description,
		"candidates": candidates
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
				print('found peer1')
				print(peer.peer.set_remote_description(type, data.description))
				print('set remote desc1')

func _ready():
#	mic_playback = get_tree().get_first_node_in_group('mic_playback')
	capture = AudioServer.get_bus_effect(2,0)
	Vector.got_turn_server.connect(func(data):
		if data.has('username'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_username',data.username)
		if data.has('password'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_password',data.password)
		if data.has('uris'):
			ProjectSettings.set_setting('bark/webrtc_config/turn_servers',data.uris)
		)
	Vector.user_logged_in.connect(func():
		uname = Vector.userData.login.user_id.split(':')[0].right(-1)
		print(uname)
		)

func _process(delta):
	chat_timer += delta
	journal_timer += delta
	for peer in peers:
		peer.peer.poll()
		
	#	mic_playback.play()
		for chan in peer.channels:
#			if chan.get_ready_state() != 1:
#				print(chan.get_ready_state())
			chan.poll()
			if chan.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
				match chan.get_label():
					'bark-chat':
						while chan.get_available_packet_count() > 0:
							var data = bytes_to_var(chan.get_packet().decompress_dynamic(999999999999, 3))
							var remplayer = get_tree().get_first_node_in_group(data.p_id)
							if remplayer:
								remplayer.set_target_pos(data.user_pos.pos)
							else:
								var root = get_tree().get_first_node_in_group('localworldroot')
								var tmp:Node = load("res://mainSystem/scenes/player/remote player/remote player.tscn").instantiate()
								tmp.add_to_group(data.p_id)
								root.add_child(tmp)
								
	#						if data.has('audio'):
	#							mic_playback.buffer_to_push.append_array(data.audio)
					'bark-journal':
						while chan.get_available_packet_count() > 0:
							var data = chan.get_var(true)
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
									match action.action_name:
										"net_propogate_node":
											if action.has('parent'):
												Journaling.net_propogate_node(action.node_string,action.parent)
											else:
												Journaling.net_propogate_node(
													action.node_string,
													'',
													true
													)
										"set_property":
											Journaling.set_property(action.target,action.prop_name,action.value,true)
										"import_asset":
											Journaling.import_asset(action.type, action.asset_to_import, true)

		for chan in peer.channels:
			if chan.get_label() == 'bark-chat' and chat_timer > 0.01 and chan.get_ready_state() == 1:
				chat_timer = 0.0
				var player = get_tree().get_first_node_in_group('player')
				var audiobuf = capture.get_buffer(capture.get_frames_available())
				var username:String
				chan.put_packet(var_to_bytes({
					'p_id': OS.get_unique_id(),
					'uname': username,
					'audio': audiobuf,
					'user_pos': {
						'pos':player.global_position,
						'rhpos':player.righthand.global_position,
						'lhpos':player.lefthand.global_position
						}
					}).compress(3))
			if chan.get_label() == 'bark-journal' and journal_timer > 0.08 and chan.get_ready_state() == 1:
				journal_timer = 0.0
				var tmp = Journaling.get_actions()
				if tmp.size() >0:
	#						print(tmp)
					var bytes_to_send = var_to_bytes_with_objects(tmp).compress(3)
					if bytes_to_send.size() < packet_size:
						chan.put_var({
							'pos': -1,
							'bytes': bytes_to_send
						})
					else:
						var parts:int = bytes_to_send.size()/packet_size
						for i in range(bytes_to_send.size()/packet_size):
							var pack_dict = {}
							if i < parts-1: 
								pack_dict['pos'] = i
								pack_dict['bytes'] = bytes_to_send.slice(i*packet_size, (i*packet_size)+packet_size)
	#								print(pack_dict['bytes'].size())
							else:
								pack_dict['bytes'] = bytes_to_send.slice(i*packet_size)
								pack_dict['pos'] = -1
	#							print('err: ',chan.put_var(pack_dict))
							var err = chan.put_var(pack_dict)
							if err!= 0:
								print('err: ', err)

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
		'channels': [
			peer.create_data_channel("bark-chat", {
				'id':1,
				'negotiated': true,
				'maxPacketLifeTime': 500
				}),
			peer.create_data_channel("bark-journal", {
				'id':2,
				'negotiated': true,
				'ordered': true
				})
		],
		'for_user': for_user,
		'candidates': []
		}
	
	# connect functions
	peer.ice_candidate_created.connect(_on_ice_candidate.bind(peer_dict))
	peer.session_description_created.connect(description_created.bind(peer_dict))
	# add peer to list of peers
	peers.append(peer_dict)
	# if there is an offer to use, use it
	if offer_string:
		peer.set_remote_description("offer",offer_string)
	else: # otherwise, create an offer
		tmp = peer.create_offer()
		assert(tmp == OK)
	
	
		
	

func _on_ice_candidate(mid, index, sdp, data:Dictionary):
	print("ice:")
#	print("mid: ",str(mid),"\nindex: ",str(index),"\nsdp: ",str(sdp))
	print(data.candidates)
	data.candidates.append(sdp)
	if data.candidates.size() >= 4:
		emit_signal('finished_candidates', data)
	

func description_created(type:String, sdp:String, data:Dictionary):
#	print("type: ",type,"\nsdp: ",sdp)
	print('set local description')
	print(type)
	if sdp.contains('actpass'):
		sdp = sdp.replace('actpass', 'passive')
	data.peer.set_local_description(type,sdp)
	local_description = sdp
	if type == 'offer':
		data.offer = sdp
		emit_signal('created_offer',data)
	if type == 'answer':
		data.answer = sdp
		emit_signal('created_answer',data)
