extends XROrigin3D

var interface : XRInterface

# Called when the node enters the scene tree for the first time.
func _ready():
	interface = XRServer.find_interface("OpenXR")
	interface.initialize()
	if interface and interface.is_initialized():
		get_viewport().use_xr = true
	else:
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
