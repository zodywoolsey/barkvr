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

var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()

var channels : Array[WebRTCDataChannel]

var peers : Array[WebRTCPeerConnection]

var local_description : String

var candidates : Array

var timer :float = 0

var uname :String = ""

#var audioshit:Dictionary = {}
var capture:AudioEffectCapture
var mic_playback:MicPlayback

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F2:
			get_clipboard_connection_string()
		elif event.keycode == KEY_F3:
			apply_connection_string('')

func get_clipboard_connection_string():
	var tmp = str({
		"description": local_description,
		"candidates": candidates
	})
	DisplayServer.clipboard_set(tmp)
#	discord_sdk.join_secret = tmp
#	discord_sdk.state = "testing a session"
#	discord_sdk.refresh()

func apply_connection_string(constring:String):
	var data = JSON.parse_string(DisplayServer.clipboard_get())
	if data and data.has('description') and data.has('candidates'):
		peer.set_remote_description("offer",data.description)
		print('connecting')
		return
	data = JSON.parse_string(constring)
	if data and data.has('description') and data.has('candidates'):
		peer.set_remote_description("offer",data.description)
		print('connecting')
		return

func _ready():
#	mic_playback = get_tree().get_first_node_in_group('mic_playback')
	capture = AudioServer.get_bus_effect(2,0)
	# init the peer
	initwebrtc()
	# connect functions
	peer.ice_candidate_created.connect(_on_ice_candidate)
	peer.session_description_created.connect(description_created)

func _process(delta):
	timer += delta
	peer.poll()
	
#	mic_playback.play()
	for chan in channels:
		chan.poll()
		if chan.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			match chan.get_label():
				'bark-chat':
					while chan.get_available_packet_count() > 0:
						var data = chan.get_var()
#						if data.has('audio'):
#							mic_playback.buffer_to_push.append_array(data.audio)
				'bark-journal':
					while chan.get_available_packet_count() > 0:
						var data = chan.get_var()
						print(data)
						for action in data:
							print(action)
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
	if timer > .5:
		if !channels.size() > 0:
			pass
			print("attempting to create data channel")
			channels.append(peer.create_data_channel("bark-chat", {
				'id':1,
				'negotiated': true,
				'ordered': false,
				'maxPacketLifeTime': 500
				}))
			channels.append(peer.create_data_channel("bark-journal", {
				'id':2,
				'negotiated': true,
				}))
#			print('channels created')
			peer.create_offer()
		else:
			for chan in channels:
				if chan.get_label() == 'bark-chat':
					var audiobuf = capture.get_buffer(capture.get_frames_available())
					if chan.get_ready_state() == 1:
						channels[0].put_var({
							'p_id': OS.get_unique_id(),
							'uname': uname,
							'audio': audiobuf
	#							'p_pos': tmpplayer.global_position,
						})
				if chan.get_label() == 'bark-journal' and chan.get_ready_state() == 1:
					var tmp = Journaling.get_actions()
					if tmp.size() >0:
#						print(tmp)
						print('err: ',chan.put_var(tmp, true))
		timer = 0.0

func initwebrtc():
	# init the webrtc peer with the public google ice server
	var tmp = peer.initialize({
		"iceServers": [
			{
				"urls": [
					"stun:stun.l.google.com:19302",
					"stun:stun1.l.google.com:19302",
					"stun:stun2.l.google.com:19302",
					"stun:stun3.l.google.com:19302",
					"stun:stun4.l.google.com:19302"
					],
			}
		]
	})
	assert(tmp == OK)

func _on_ice_candidate(mid, index, sdp):
#	print("ice:")
#	print("mid: ",str(mid),"\nindex: ",str(index),"\nsdp: ",str(sdp))
	candidates.append(sdp)

func description_created(type:String, sdp:String):
#	print("type: ",type,"\nsdp: ",sdp)
#	print('set local description')
	peer.set_local_description(type,sdp)
	local_description = sdp
