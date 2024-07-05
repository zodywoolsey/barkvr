extends Control

@onready var label = $ScrollContainer/Label
@onready var clearpeers = $clearpeers

func _ready():
	_get_webrtc_data()
	clearpeers.pressed.connect(func():
		if clearpeers.button_pressed and is_instance_valid(Engine.get_singleton("network_manager")):
			Engine.get_singleton("network_manager").peers.clear()
		)

func _get_webrtc_data():
	label.text = ""
	if is_instance_valid(Engine.get_singleton("network_manager")):
		for peer in Engine.get_singleton("network_manager").peers.size():
			label.text += str(peer) + "\n"
			for a in Engine.get_singleton("network_manager").peers[peer].size():
				label.text += "    "
				label.text += str(Engine.get_singleton("network_manager").peers[peer].keys()[a]) + ": " + str(Engine.get_singleton("network_manager").peers[peer].values()[a])
				label.text += "\n"
			if "peer" in Engine.get_singleton("network_manager").peers[peer]:
				var tmppeer:WebRTCPeerConnection = Engine.get_singleton("network_manager").peers[peer].peer
				label.text += "PEERCONNECTION INFO:\n"
				label.text += "connection state: "+str(tmppeer.get_connection_state())
		get_tree().create_timer(.1).timeout.connect(_get_webrtc_data)
