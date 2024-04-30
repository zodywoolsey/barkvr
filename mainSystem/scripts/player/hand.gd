extends XRController3D

@onready var grabArea : Area3D = $handproxy/grabArea
@onready var world_ray : RayCast3D = $handproxy/worldRay
@onready var ui_ray = $handproxy/uiRay
@onready var label_3d = $handproxy/Label3D
@onready var handmenu = %"handmenu"
@onready var hand_menu_point = $handproxy/handMenuPoint
@onready var grab_parent = $handproxy/grabParent
@onready var grabjoint = $handproxy/grabjoint
@onready var local_player = %CharacterBody3D
@onready var righthand = %righthand
@onready var lefthand = %lefthand
var otherhand : XRController3D


var prevHover : Node
var grabAreaBodies : Array = []
var grabbed :Dictionary
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
		if (XRServer.get_tracker(tracker).profile).ends_with("index_controller"):
			match name:
				"grip_force":
					if value > .1 and !grabbing:
						trigger_haptic_pulse("haptic",100.0,.5,.1,0.0)
						trigger_haptic_pulse("haptic",200.0,.5,.1,0.1)
						trigger_haptic_pulse("haptic",300.0,.5,.1,0.2)
						trigger_haptic_pulse("haptic",400.0,.5,.1,0.3)
						trigger_haptic_pulse("haptic",500.0,.5,.1,0.4)
						trigger_haptic_pulse("haptic",400.0,.5,.1,0.5)
						trigger_haptic_pulse("haptic",300.0,.5,.1,0.6)
						trigger_haptic_pulse("haptic",200.0,.5,.1,0.7)
						trigger_haptic_pulse("haptic",100.0,.5,.1,0.8)
						grip()
				"grip":
					if value < 1.0:
						grabbing = false
		else:
			if name == "grip":
				if value > .5 and !grabbing:
					grip()
			elif name == "grip" and value < .5:
				grabbing = false
#		if name == "trigger":
#			if value > .3:
#				world_ray.enabled = true
#			else:
#				world_ray.enabled = false
		)


func _physics_process(delta):
	if visible:
		if buttons.has('by_button') and LocalGlobals.world_state:
			if buttons['by_button']:
				contexttimer += delta
			else:
				contexttimer = 0
	for item in grabbed.values():
		if self == righthand:
			item.node.global_transform = righthand.global_transform * item.offset
		else:
			item.node.global_transform = lefthand.global_transform * item.offset

func _notification(what):
	if what == NOTIFICATION_PROCESS:
		if visible:
			if isscalinggrabbedobject:
				var ts = global_position.distance_to(otherhand.global_position)-scalinggrabbedstartdist
				ts *= 4.0
				scalinggrabbedobject.scale = scalinggrabbedstartscale+Vector3(ts,ts,ts)
			if ui_ray.is_colliding():
				world_ray.enabled = false
				world_ray.hide()
			else:
				world_ray.enabled = true
				world_ray.show()
		else:
			world_ray.enabled = false
			ui_ray.enabled = false

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
			world_ray.click()
		for item in grabbed.values():
			if item.has_method('primary'):
				item.primary(true)
			if item.has('trigger_pressed'):
				item.trigger_pressed = true
		if grabjoint.node_b and get_node(grabjoint.node_b).has_method('primary'):
			get_node(grabjoint.node_b).primary(true)

func buttonReleased(name):
	buttons[name] = false
	if name == "by_button":
		contextMenuSummon()
	if name == "grip_click":
		ungrip()
	if name == "trigger_click":
		ui_ray.release()
		if grab_parent.get_child_count()>0:
			for item in grab_parent.get_children():
				if is_instance_valid(item):
					if item.has_method('primary'):
						item.primary(false)
					if item.has('trigger_pressed'):
						item.trigger_pressed = false
		if grabjoint.node_b and get_node(grabjoint.node_b).has_method('primary'):
			get_node(grabjoint.node_b).primary(false)
		rayBody = null

func contextMenuSummon():
	if contexttimer < contexteditortimeout:
		handmenu.summon(hand_menu_point.global_position, global_position)
	else:
		if LocalGlobals.editor_refs.has('vreditor'):
			LocalGlobals.editor_refs.mainpanel.global_position = hand_menu_point.global_position
			LocalGlobals.editor_refs.mainpanel.global_rotation = hand_menu_point.global_rotation
			LocalGlobals.editor_refs.mainpanel.global_rotation.x += deg_to_rad(90.0)
		else:
			var vreditor = load("res://mainAssets/ui/3dPanel/editmode/vreditor.tscn").instantiate()
			get_tree().get_first_node_in_group("localroot").add_child(vreditor)
			vreditor.set_items(local_player.selected)
			vreditor.global_position = hand_menu_point.global_position

func grip():
	if ui_ray.is_colliding():
		var rayCollided = ui_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)
	elif grabArea.get_overlapping_bodies().size() > 0:
		for item in grabArea.get_overlapping_bodies():
			grab(item,true)
	elif world_ray.is_colliding():
		var rayCollided = world_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)
	grabbing = true

func ungrip():
	for item in grabbed.values():
		releasegrab(item.node)
	if grabjoint.node_b:
		grabjoint.node_b = ""
	if isscalinggrabbedobject:
		scalinggrabbedobject = null
		scalinggrabbedstartdist = 0
		isscalinggrabbedobject = false

func grab(node:Node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
#			grabjoint.node_b = node.get_path()
			node.freeze = true
			if grabbed.has(node.name):
				scalinggrabbedobject = node
				scalinggrabbedstartdist = global_position.distance_to(otherhand.global_position)
				scalinggrabbedstartscale = node.scale
				isscalinggrabbedobject = true
			else:
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'frozen': node.freeze,
					'node': node
				}
#				node.reparent(grab_parent, true)
		else:
			if laser:
				pass
			if grabbed.has(node.name):
				scalinggrabbedobject = node
				scalinggrabbedstartdist = global_position.distance_to(otherhand.global_position)
				scalinggrabbedstartscale = node.scale
				isscalinggrabbedobject = true
			else:
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'node': node
				}
#				node.reparent(grab_parent, true)

func releasegrab(node:Node):
	if grabbed.has(node.name):
#		if lefthand == grabbed[node.name].parent or righthand == grabbed[node.name].parent:
#			node.reparent(get_tree().get_first_node_in_group('worldroot'))
#		else:
#			node.reparent(grabbed[node.name].parent)
		if node is RigidBody3D:
			node.freeze = false
		grabbed.erase(node.name)
		

func isgrabbed(node):
	for i in grab_parent.get_children():
		if i == node:
			return true
	
