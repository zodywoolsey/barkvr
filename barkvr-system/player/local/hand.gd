class_name BarkHand
extends XRController3D

@onready var grabArea : Area3D = $handproxy/grabArea
@onready var ui_ray : Node3D = $handproxy/uiRay
@onready var handmenu :Node3D = %"handmenu"
@onready var hand_menu_point :Node3D = $handproxy/handMenuPoint
@onready var grab_parent :Node3D= $handproxy/grabParent
#@onready var grabjoint = $handproxy/grabjoint
@onready var local_player :Node = $"../.."
@onready var handproxy: Node3D = $handproxy
@onready var handiktarget: Node3D = $handiktarget
@onready var righthand :Node = %righthand
@onready var lefthand :Node = %lefthand
#TODO read handtracking stuffs
var otherhand : XRController3D

var grabbed :Dictionary
var grabbedVel := Vector3()

var rayBody : RigidBody3D
var grabbing = false
## for holding time passed while holding the context menu button
var contexttimer = 0
## holder for currently pressed buttons this allows us to do more than just
## respond to a button press immediately
var buttons :Dictionary = {}
## the amount of time the context menu buston needs to be held to summon the inspector 
## instead of just opening the context menu
var contexteditortimeout := 1.0
## var for tracking whether this hand is currently scaling an object
var isscalinggrabbedobject := false
## for tracking the distance between the hands when beginning to scale 
## an object
var scalinggrabbedstartdist : float
## for tracking wh9ich object is being scaled currently [this should
## be upgraded eventually to allow scaling of multiple held objects]
var scalinggrabbedobject : Node
var scalinggrabbedstartscale : Vector3
var rays_disabled : bool = false:
	set(value):
		rays_disabled = value
		if is_instance_valid(ui_ray):
			ui_ray.enabled = !value
			ui_ray.visible = !value

func _ready():
	ui_ray.enabled = !rays_disabled
	ui_ray.visible = !rays_disabled
	if name == "righthand":
		otherhand = lefthand
		#thishandtracking = righthandtracking
	else:
		otherhand = righthand
		#thishandtracking = lefthandtracking
	connect("button_pressed",buttonPressed)
	connect("button_released",buttonReleased)
	input_vector2_changed.connect(vector2_changed)
	input_float_changed.connect(func(input_name:String,value:float):
		float_changed(input_name, value)
		if (XRServer.get_tracker(tracker).profile).ends_with("index_controller"):
			match input_name:
				"grip_force":
					if value > .1 and !grabbing: #TODO change these to be a setting
						trigger_haptic_pulse("haptic",400.0,.5,.05,0.0)
						grip()
				"grip":
					if value < 1.0: #TODO change these to be a setting
						if grabbing:
							grabbing = false
							trigger_haptic_pulse("haptic",100.0,.5,.05,0.0)
							ungrip()
		else:
			match input_name:
				"grip":
					if value > .75 and !grabbing: #TODO change these to be a setting
						trigger_haptic_pulse("haptic",400.0,.5,.05,0.0)
						grip()
					elif value < .5: #TODO change these to be a setting
						grabbing = false
						trigger_haptic_pulse("haptic",100.0,.5,.05,0.0)
						ungrip()
#		if name == "trigger":
#			if value > .3:
#				world_ray.enabled = true
#			else:
#				world_ray.enabled = false
		)

func float_changed(input_name:String, value:float):
	for item in grabbed.values():
		if is_instance_valid(item.node):
			if 'float_changed' in item.node:
				item.node.float_changed(input_name, value)
				return

func vector2_changed(input_name:String, value:Vector2):
	for item in grabbed.values():
		if is_instance_valid(item.node):
			if 'vector2_changed' in item.node:
				item.node.vector2_changed(input_name, value)
				return

func _physics_process(delta: float) -> void:
	if !rays_disabled:
		if isscalinggrabbedobject:
			var ts = global_position.distance_to(otherhand.global_position)-scalinggrabbedstartdist
			ts *= 4.0
			scalinggrabbedobject.scale = scalinggrabbedstartscale+Vector3(ts,ts,ts)
	#if local_player.vr_mode_enabled:
		#if thishandtracking.tracking and !rays_disabled:
			#rays_disabled = true
		#elif rays_disabled:
			#rays_disabled = false
	if !rays_disabled:
		if buttons.has('by_button') and LocalGlobals.world_state:
			if buttons['by_button']:
				contexttimer += delta
			else:
				contexttimer = 0
	var setsing_precast = Engine.get_singleton("settings_manager")
	var settings_singleton := (setsing_precast as SettingsSingleton) if setsing_precast is SettingsSingleton else null
	for item in grabbed.values():
		if settings_singleton:
			if Input.is_action_just_pressed("scrollup"):
				if Input.is_physical_key_pressed(KEY_SHIFT):
					print(item.offset.basis)
					item.offset.basis.x *= settings_singleton.grabbed_object_scale_factor
					item.offset.basis.y *= settings_singleton.grabbed_object_scale_factor
					item.offset.basis.z *= settings_singleton.grabbed_object_scale_factor
				else:
					item.offset.origin *= settings_singleton.grabbed_object_scale_factor
			if Input.is_action_just_pressed("scrolldown"):
				if Input.is_physical_key_pressed(KEY_SHIFT):
					print(item.offset.basis)
					item.offset.basis.x *= 1.0/settings_singleton.grabbed_object_scale_factor
					item.offset.basis.y *= 1.0/settings_singleton.grabbed_object_scale_factor
					item.offset.basis.z *= 1.0/settings_singleton.grabbed_object_scale_factor
				else:
					item.offset.origin *= 1.0/settings_singleton.grabbed_object_scale_factor
		if self == righthand:
			item.node.global_transform = righthand.global_transform * item.offset
		else:
			item.node.global_transform = lefthand.global_transform * item.offset
		if is_instance_valid(Engine.get_singleton("event_manager")):
				print("apply")
				Engine.get_singleton("event_manager").set_property(
					get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
					"position",
					item.node.position
				)
				Engine.get_singleton("event_manager").set_property(
					get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
					"rotation",
					item.node.rotation
				)
				Engine.get_singleton("event_manager").set_property(
					get_tree().get_first_node_in_group('localworldroot').get_path_to(item.node),
					"scale",
					item.node.scale
				)

func update_raycasts():
	ui_ray.force_raycast_update()
	ui_ray.force_update_transform()

func buttonPressed(btn_name):
	# if anything is grabbed, send inputs to those objects and return
	if !grabbed.is_empty():
		for item in grabbed.values():
			if 'button_pressed' in item.node:
				item.node.button_pressed(btn_name)
				continue
			# DEPRECATED the following are only for backward compatibility!
			if btn_name == "trigger_click":
				if 'primary' in item.node:
					item.node.primary()
					continue
				if 'primary_pressed' in item.node:
					item.node.primary_pressed()
					continue
				if "trigger_pressed" in item.node:
					item.node.trigger_pressed = true
					continue
		return
	# add the button to the dictionary of pressed buttons
	buttons[btn_name] = true
	# click the interaction ray
	if btn_name == "trigger_click":
		if ui_ray.is_colliding():
			ui_ray.click()

func buttonReleased(btn_name):
	# if anything is grabbed send the input to those nodes and return
	if !grabbed.is_empty():
		for item in grabbed.values():
			if is_instance_valid(item.node):
				if 'button_released' in item.node:
					item.node.button_released(btn_name)
					continue
				# DEPRECATED the following are only for backward compatibility!
				if 'released' in item.node:
					item.node.released()
					continue
				if 'primary_released' in item.node:
					item.node.primary_released()
					continue
				if 'trigger_released' in item.node:
					item.node.trigger_released()
					continue
		return
	# remove the button from the pressed buttons dictionary
	buttons[btn_name] = false
	if btn_name == "by_button":
		contextMenuSummon()
	# unclick the interaction ray
	if btn_name == "trigger_click":
		ui_ray.release()
		rayBody = null

func contextMenuSummon():
	if handmenu:
		handmenu.summon(hand_menu_point.global_position, global_position)

func grip():
	if grabArea.get_overlapping_bodies().size() > 0:
		for item in grabArea.get_overlapping_bodies():
			if item.has_meta("grabbable"):
				grab(item,true)
				return
	if ui_ray.is_colliding():
		var rayCollided = ui_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)

func ungrip():
	for item in grabbed.values():
		releasegrab(item.node)
	if isscalinggrabbedobject:
		scalinggrabbedobject = null
		scalinggrabbedstartdist = 0
		isscalinggrabbedobject = false

func grab(node:Node, laser:bool=false):
	grabbing = true
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'isfrozen': node.freeze,
					'node': node
				}
			node.freeze = true
		else:
			if laser:
				pass
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'node': node
				}

func releasegrab(node:Node):
	if grabbed.has(node.name):
		if node is RigidBody3D:
			node.freeze = grabbed[node.name].isfrozen
		grabbed.erase(node.name)
		
