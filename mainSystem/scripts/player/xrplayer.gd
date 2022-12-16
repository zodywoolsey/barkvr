extends XROrigin3D

var interface : XRInterface

# Called when the node enters the scene tree for the first time.
func _ready():
	print(XRServer.get_interfaces())
	interface = XRServer.find_interface("OpenXR")
	interface.initialize()
	if interface and interface.is_initialized():
		print("openxr started")
		get_viewport().use_xr = true
	else:
		print('openxr not work')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
