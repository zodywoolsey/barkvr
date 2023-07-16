extends Node

var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()

var channels : Array[WebRTCDataChannel]

var candidates : Array

var timer :float = 0

func _ready():
	# init the peer
	initwebrtc()
	# connect functions
	peer.ice_candidate_created.connect(_on_ice_candidate)
	peer.session_description_created.connect(description_created)
	peer.create_offer()

func _process(delta):
	timer += delta
	peer.poll()
	if channels.size() > 0:
		channels[0].poll()
		if channels[0].get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			while channels[0].get_available_packet_count() > 0:
				print(get_path(), " received: ", str(channels[0].get_var()))
	if timer > .1:
		if !channels.size() > 0:
			print("attempting to create data channel")
			channels.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
			channels.append(peer.create_data_channel("bark-chat", {'id':1,'negotiated': true}))
		else:
			var tmpplayer = get_tree().get_first_node_in_group("player")
#			if tmpplayer:
#				channels[0].put_var({
#					'p_id': OS.get_unique_id(),
#					'p_pos': tmpplayer.global_position,
#				})
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

func description_created(type:String, sdp:String):
	print("type: ",type,"\nsdp: ",sdp)
	print('set local description')
	peer.set_local_description(type,sdp)
