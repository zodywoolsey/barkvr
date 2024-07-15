class_name BarkHand
extends XRController3D

@onready var grabArea : Area3D = $handproxy/grabArea
@onready var world_ray : RayCast3D = $handproxy/worldRay
@onready var ui_ray : RayCast3D = $handproxy/uiRay
@onready var handmenu :Node3D = %"handmenu"
@onready var hand_menu_point :Node3D = $handproxy/handMenuPoint
@onready var grab_parent :Node3D= $handproxy/grabParent
#@onready var grabjoint = $handproxy/grabjoint
@onready var local_player = %CharacterBody3D
@onready var righthand = %righthand
@onready var lefthand = %lefthand
@onready var lefthandtracking :SimpleOpenXRHand= %lefthandtracking
@onready var righthandtracking :SimpleOpenXRHand= %righthandtracking
var thishandtracking :SimpleOpenXRHand
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
var rays_disabled : bool = false:
	set(value):
		rays_disabled = value
		if is_instance_valid(world_ray) and is_instance_valid(ui_ray):
			world_ray.enabled = !value
			world_ray.visible = !value
			ui_ray.enabled = !value
			ui_ray.visible = !value

func _ready():
	world_ray.enabled = !rays_disabled
	world_ray.visible = !rays_disabled
	ui_ray.enabled = !rays_disabled
	ui_ray.visible = !rays_disabled
	if name == "righthand":
		otherhand = lefthand
		thishandtracking = righthandtracking
	else:
		otherhand = righthand
		thishandtracking = lefthandtracking
	grabArea.connect("body_entered", grabBodyEntered)
	grabArea.connect("body_exited", grabBodyExited)
	connect("button_pressed",buttonPressed)
	connect("button_released",buttonReleased)
	input_float_changed.connect(func(name:String,value:float):
		if (XRServer.get_tracker(tracker).profile).ends_with("index_controller"):
			match name:
				"grip_force":
					if value > .1 and !grabbing:
						trigger_haptic_pulse("haptic",400.0,.5,.1,0.0)
						grip()
				"grip":
					if value < 1.0:
						if grabbing:
							grabbing = false
							trigger_haptic_pulse("haptic",100.0,.5,.1,0.0)
							ungrip()
		else:
			match name:
				"grip":
					if value > .75 and !grabbing:
						trigger_haptic_pulse("haptic",100.0,.5,.1,0.0)
						grip()
					elif value < .5:
						grabbing = false
#		if name == "trigger":
#			if value > .3:
#				world_ray.enabled = true
#			else:
#				world_ray.enabled = false
		)

func _physics_process(delta):
	if local_player.vr_mode_enabled:
		if thishandtracking.tracking and !rays_disabled:
			rays_disabled = true
		elif rays_disabled:
			rays_disabled = false
	if !rays_disabled:
		if buttons.has('by_button') and LocalGlobals.world_state:
			if buttons['by_button']:
				contexttimer += delta
			else:
				contexttimer = 0
	for item in grabbed.values():
		if Input.is_action_just_pressed("scrollup"):
			if Input.is_physical_key_pressed(KEY_SHIFT):
				print(item.offset.basis)
				item.offset.basis.x *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.y *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.z *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
			else:
				item.offset.origin *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
		if Input.is_action_just_pressed("scrolldown"):
			if Input.is_physical_key_pressed(KEY_SHIFT):
				print(item.offset.basis)
				item.offset.basis.x *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.y *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.z *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
			else:
				item.offset.origin *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
		if self == righthand:
			item.node.global_transform = righthand.global_transform * item.offset
		else:
			item.node.global_transform = lefthand.global_transform * item.offset

func _process(delta):
	if !rays_disabled:
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

func update_raycasts():
	ui_ray.force_raycast_update()
	ui_ray.force_update_transform()
	world_ray.force_raycast_update()
	world_ray.force_update_transform()

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
	if name == "grip_click":
		pass
	if name == "trigger_click":
		if ui_ray.is_colliding():
			ui_ray.click()
		else:
			world_ray.click()
		for item in grabbed.values():
			if 'primary' in item.node:
				item.node.primary()
			if "trigger_pressed" in item.node:
				item.node.trigger_pressed = true

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
				if is_instance_valid(item.node):
					if 'primary_released' in item.node:
						item.node.primary_released()
					if 'trigger_pressed' in item.node:
						item.node.trigger_pressed = false
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
	if isscalinggrabbedobject:
		scalinggrabbedobject = null
		scalinggrabbedstartdist = 0
		isscalinggrabbedobject = false

func grab(node:Node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
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

func releasegrab(node:Node):
	if grabbed.has(node.name):
		if node is RigidBody3D:
			node.freeze = false
		grabbed.erase(node.name)
		
