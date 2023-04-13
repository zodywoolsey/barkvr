extends XRController3D

@onready var grabArea : Area3D = $grabArea
@onready var handRay : RayCast3D = $RayCast3D
var grabAreaBodies : Array = []
var rayBody : RigidBody3D
var rightStickVec

func _ready():
	grabArea.connect("body_entered", grabBodyEntered)
	grabArea.connect("body_exited", grabBodyExited)
	connect("button_pressed",buttonPressed)
	connect("button_released",buttonReleased)
	input_float_changed.connect(func(name:String,value:float):
#		print('input {0}, {1}'.format([name,value]))
		if name == "grip" and value > .5:
			if grabAreaBodies.size() > 0:
				grab(grabAreaBodies[0])
			elif handRay.is_colliding():
				var rayCollided = handRay.get_collider()
				if rayCollided.has_meta("grabbable"):
					grab(rayCollided,true)
		if name == "trigger":
			if value > .3:
				handRay.enabled = true
			else:
				handRay.enabled = false
		)
	input_vector2_changed.connect(func(name:String,value):
#		print('input {0}, {1}'.format([name,value]))
		pass
		)

func _process(delta):
	pass

func _input(event):
	pass

func grabBodyEntered(body):
	if body.has_meta("grabbable"):
		var bodyMeta = body.get_meta("grabbable")
		if bodyMeta != 0:
			grabAreaBodies.push_back(body)

func grabBodyExited(body):
	var tmp = grabAreaBodies.find(body)
	if tmp != -1:
		grabAreaBodies.pop_at(tmp)

func buttonPressed(name):
	if name == "grip_click":
#		if grabAreaBodies.size() > 0:
#			grab(grabAreaBodies[0])
#		elif handRay.is_colliding():
#			var rayCollided = handRay.get_collider()
#			if rayCollided.has_meta("grabbable"):
#				grab(rayCollided,true)
		pass
	if name == "trigger_click":
		var tmpcol = handRay.get_collider()
		if tmpcol.get_collision_layer_value(3):
			tmpcol.laserClick(handRay.get_collision_point())
		
#	print("button: {0}".format([name]))
	
func buttonReleased(name):
#	if name == "grip_click" and !grabConstraint.node_b.is_empty():
#		if get_node(grabConstraint.node_b).get_class() == "RigidBody3D":
#			get_node(grabConstraint.node_b).freeze = false
#		grabConstraint.position = Vector3(0,0,0)
#		grabConstraint.node_b = ""
	if name == "trigger_click":
		rayBody = null

func grab(node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
#	print(tmpgrab)
	if tmpgrab == 1:
		if laser:
			pass
	
	#node.freeze = true
