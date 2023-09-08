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

func get_clipboard_connection_string():
	var tmp = str({
		"description": local_description,
		"candidates": candidates
	})
	DisplayServer.clipboard_set(tmp)
	discord_sdk.join_secret = tmp
	discord_sdk.state = "testing a session"
	discord_sdk.refresh()

func apply_connection_string(constring:String):
	var data = JSON.parse_string(DisplayServer.clipboard_get())
	if data and data.has('description') and data.has('candidates'):
		peer.set_remote_description("offer",data.description)
		print('connecting')

func _ready():
	# init the peer
	initwebrtc()
	# connect functions
	peer.ice_candidate_created.connect(_on_ice_candidate)
	peer.session_description_created.connect(description_created)

func _process(delta):
	timer += delta
	peer.poll()
	for chan in channels:
		chan.poll()
		if chan.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while chan.get_available_packet_count() > 0:
				print(" received: ", str(chan.get_var()))
	if timer > .1:
		if !peers.size() > 0:
			pass
#			print("attempting to create data channel")
#			peers.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
#			peers.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
#			peers.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
#			peers.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
#			print('channels created')
#			peer.create_offer()
		else:
			for chan in channels:
				if chan.get_ready_state() == 1:
					channels[0].put_var({
						'p_id': OS.get_unique_id(),
						'uname': uname,
#							'p_pos': tmpplayer.global_position,
					})
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
	print("ice:")
	print("mid: ",str(mid),"\nindex: ",str(index),"\nsdp: ",str(sdp))
	candidates.append(sdp)

func description_created(type:String, sdp:String):
	print("type: ",type,"\nsdp: ",sdp)
	print('set local description')
	peer.set_local_description(type,sdp)
	local_description = sdp
