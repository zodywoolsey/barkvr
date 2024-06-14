extends Control

@onready var label = $ScrollContainer/Label
@onready var clearpeers = $clearpeers

func _ready():
	_get_webrtc_data()
	clearpeers.pressed.connect(func():
		if clearpeers.button_pressed:
			NetworkHandler.peers.clear()
		)

func _get_webrtc_data():
	label.text = ""
	for peer in NetworkHandler.peers.size():
		label.text += str(peer) + "\n"
		for a in NetworkHandler.peers[peer].size():
			label.text += "    "
			label.text += str(NetworkHandler.peers[peer].keys()[a]) + ": " + str(NetworkHandler.peers[peer].values()[a])
			label.text += "\n"
		if "peer" in NetworkHandler.peers[peer]:
			var tmppeer:WebRTCPeerConnection = NetworkHandler.peers[peer].peer
			label.text += "PEERCONNECTION INFO:\n"
			label.text += "connection state: "+str(tmppeer.get_connection_state())
	get_tree().create_timer(.1).timeout.connect(_get_webrtc_data)
