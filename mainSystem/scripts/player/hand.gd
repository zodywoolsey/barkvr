extends XRController3D

@onready var grabArea : Area3D = $grabArea
@onready var handRay : RayCast3D = $RayCast3D
@onready var label_3d = $Label3D
@onready var handmenu = $"../../handmenu"
@onready var hand_menu_point = $handMenuPoint
@onready var grab_parent = $grabParent

var prevHover : Node
var grabAreaBodies : Array = []
var grabbed
var grabbedVel := Vector3()
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
			if grabArea.get_overlapping_bodies().size() > 0:
				for item in grabArea.get_overlapping_bodies():
					grab(item,true)
			elif handRay.is_colliding():
				var rayCollided = handRay.get_collider()
				if rayCollided.has_meta("grabbable"):
					grab(rayCollided,true)
#		if name == "trigger":
#			if value > .3:
#				handRay.enabled = true
#			else:
#				handRay.enabled = false
		)

func _process(delta):
	for item in grab_parent.get_children():
		item.global_position = grab_parent.global_position
	if handRay.is_colliding():
		var tmpcol = handRay.get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserHover"):
			if prevHover and prevHover != tmpcol:
				prevHover.laserHover({
					'hovering': false,
					'clicked': false
				})
			else:
				tmpcol.laserHover({
					'hovering': true,
					'clicked': false,
					"collision_point": handRay.get_collision_point()
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laserHover"):
				prevHover.laserHover({
					'hovering': false
				})
	else:
		if prevHover and prevHover.has_method("laserHover"):
			prevHover.laserHover({
				'hovering': false
			})
			prevHover = null

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
	label_3d.text = name
	if name == "by_button":
		handmenu.summon(hand_menu_point.global_position, global_position)
	if name == "grip_click":
#		if grabAreaBodies.size() > 0:
#			grab(grabAreaBodies[0])
#		elif handRay.is_colliding():
#			var rayCollided = handRay.get_collider()
#			if rayCollided.has_meta("grabbable"):
#				grab(rayCollided,true)
		pass
	if name == "trigger_click":
		if handRay.is_colliding():
			var tmpcol = handRay.get_collider()
			if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserClick"):
				tmpcol.laserClick({
					"position": handRay.get_collision_point()
					})
				pass
		
#	print("button: {0}".format([name]))
	
func buttonReleased(name):
	if name == "grip_click":
		for item in grab_parent.get_children():
			if item.has_method('resetParent'):
				item.resetParent()
				item.freeze = false
			else:
				pass
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
		if node.has_method('assignParent'):
			var alreadyGrabbed = false
			for i in grab_parent.get_children():
				if i == node:
					alreadyGrabbed = true
					break
			if !alreadyGrabbed:
				node.assignParent()
				node.reparent(grab_parent)
		node.freeze = true
