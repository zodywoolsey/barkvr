extends XRController3D

@onready var grabArea : Area3D = $grabArea
@onready var worldRay : RayCast3D = $worldRay
@onready var ui_ray = $uiRay
@onready var label_3d = $Label3D
@onready var handmenu = %"handmenu"
@onready var hand_menu_point = $handMenuPoint
@onready var grab_parent = $grabParent
@onready var grabjoint = $grabjoint
@onready var wristmenu = $wristmenu
@onready var local_player = %CharacterBody3D
@onready var righthand = %righthand
@onready var lefthand = %lefthand
var otherhand : XRController3D

var prevHover : Node
var grabAreaBodies : Array = []
var grabbed
var grabbedVel := Vector3()
var rayBody : RigidBody3D
var rightStickVec
var grabbing = false
var contexttimer = 0
var buttons :Dictionary = {}
var contexteditortimeout := 1.0
var isscalinggrabbedobject := false
var scalinggrabbedstartdist : float
var scalinggrabbedobject : Node
var scalinggrabbedstartscale : Vector3

func _ready():
	if name == "righthand":
		otherhand = lefthand
	else:
		otherhand = righthand
	grabArea.connect("body_entered", grabBodyEntered)
	grabArea.connect("body_exited", grabBodyExited)
	connect("button_pressed",buttonPressed)
	connect("button_released",buttonReleased)
	input_float_changed.connect(func(name:String,value:float):
		if name == "grip" and value > .5 and !grabbing:
			if ui_ray.is_colliding():
				var rayCollided = ui_ray.get_collider()
				if rayCollided.has_meta("grabbable"):
					grab(rayCollided,true)
			elif grabArea.get_overlapping_bodies().size() > 0:
				for item in grabArea.get_overlapping_bodies():
					grab(item,true)
			elif worldRay.is_colliding():
				var rayCollided = worldRay.get_collider()
				if rayCollided.has_meta("grabbable"):
					grab(rayCollided,true)
			grabbing = true
		elif name == "grip" and value < .5:
			grabbing = false
#		if name == "trigger":
#			if value > .3:
#				worldRay.enabled = true
#			else:
#				worldRay.enabled = false
		)

func _process(delta):
	if buttons.has('by_button'):
		if buttons['by_button']:
			contexttimer += delta
		else:
			contexttimer = 0
	if isscalinggrabbedobject:
		var ts = global_position.distance_to(otherhand.global_position)-scalinggrabbedstartdist
		ts *= 4.0
		scalinggrabbedobject.scale = scalinggrabbedstartscale+Vector3(ts,ts,ts)
	if ui_ray.is_colliding():
		worldRay.enabled = false
	else:
		worldRay.enabled = true

func _input(event):
	pass

func grabBodyEntered(body):
	if body.has_meta("grabbable"):
		var bodyMeta = body.get_meta("grabbable")
		if bodyMeta:
			grabAreaBodies.push_back(body)

func grabBodyExited(body):
	var tmp = grabAreaBodies.find(body)
	if tmp != -1:
		grabAreaBodies.pop_at(tmp)

func buttonPressed(name):
	buttons[name] = true
	label_3d.text = name
	if name == "grip_click":
		pass
	if name == "trigger_click":
		if ui_ray.is_colliding():
			ui_ray.click()
		else:
			worldRay.click()
		if grab_parent.get_child_count()>0:
			for item in grab_parent.get_children():
				if item.has_method('primary'):
					item.primary(true)

func buttonReleased(name):
	buttons[name] = false
	if name == "by_button":
		if contexttimer < contexteditortimeout:
			handmenu.summon(hand_menu_point.global_position, global_position)
		else:
			if LocalGlobals.editor_refs.has('vreditor'):
				LocalGlobals.editor_refs.mainpanel.global_position = hand_menu_point.global_position
				LocalGlobals.editor_refs.mainpanel.global_rotation = hand_menu_point.global_rotation
				LocalGlobals.editor_refs.mainpanel.global_rotation.x += deg_to_rad(90.0)
			else:
				var vreditor = load("res://mainAssets/ui/3dPanel/editmode/vreditor.tscn").instantiate()
				get_tree().get_first_node_in_group("worldroot").add_child(vreditor)
				vreditor.set_items(local_player.selected)
				vreditor.global_position = hand_menu_point.global_position
	if name == "grip_click":
		for item in grab_parent.get_children():
			if item.has_method('resetParent'):
				item.resetParent()
				item.freeze = false
			else:
				releasegrab(item)
		if grabjoint.node_b:
			grabjoint.node_b = ""
		if isscalinggrabbedobject:
			scalinggrabbedobject = null
			scalinggrabbedstartdist = 0
			isscalinggrabbedobject = false
	if name == "trigger_click":
		ui_ray.release()
		if grab_parent.get_child_count()>0:
			for item in grab_parent.get_children():
				if item.has_method('primary'):
					item.primary(false)
		rayBody = null

func grab(node:Node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
			grabjoint.node_b = node.get_path()
		else:
			if laser:
				pass
			if node.has_method('assignParent'):
				var alreadyGrabbed = isgrabbed(node)
				if !alreadyGrabbed:
					node.assignParent()
					node.reparent(grab_parent)
			else:
				if local_player.grabbed.has(node.name):
					scalinggrabbedobject = node
					scalinggrabbedstartdist = global_position.distance_to(otherhand.global_position)
					scalinggrabbedstartscale = node.scale
					isscalinggrabbedobject = true
				else:
					local_player.grabbed[node.name] = {
						"parent": node.get_parent(),
						"offset": grab_parent.global_position.direction_to(node.global_position)*grab_parent.global_position.distance_to(node.global_position)
					}
					node.reparent(grab_parent, true)

func releasegrab(node:Node):
	if local_player.grabbed.has(node.name) and isgrabbed(node):
		node.reparent(local_player.grabbed[node.name].parent)
		local_player.grabbed.erase(node.name)

func isgrabbed(node):
	for i in grab_parent.get_children():
		if i == node:
			return true
			break
	
