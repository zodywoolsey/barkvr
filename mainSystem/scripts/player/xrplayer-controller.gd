extends CharacterBody3D

#controllers:
@onready var righthand :BarkHand= %righthand
@onready var lefthand :BarkHand= %lefthand
@onready var xr_camera_3d :XRCamera3D = $xrplayer/XrCamera3d
@onready var camera_3d :Camera3D = $xrplayer/Camera3D
@onready var xrplayer :XROrigin3D = $xrplayer
@onready var playercamoffset = $playercamoffset
@onready var camray = $xrplayer/Camera3D/camray
@onready var collision_shape_3d = %CollisionShape3D
@onready var world_ray :InteractionRay = %worldRay
@onready var ui_ray :InteractionRay = %uiRay
@onready var handmenu = %handmenu
@onready var menuoffset = %menuoffset

#controller input vars:
var rightStick :Vector2 = Vector2()
var rightGrip :float
var rightaxbtn :bool = false
var leftStick :Vector2 = Vector2()
var leftGrip :float
var leftaxbtn :bool = false

var camPrevPos : Vector3 = Vector3()

@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5

@export var flymode := true:
	set(value):
		flymode = value
		if value:
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
@export var noclip := false:
	set(value):
		noclip = value
		collision_shape_3d.disabled = value

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var selected : Array = []
var grabbed : Dictionary = {}
var grabbing : bool = false
var vreditor : Node3D = null
var vrinspector : Control = null

# flat vars
var MOUSE_SPEED := .1
var lookdrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}
@export var touchsticklook := false
var grab_point := Vector3()

var vr_mode_enabled := true:
	set(value):
		vr_mode_enabled = value
		_toggle_xr(value)

func _toggle_xr(value):
	if LocalGlobals:
		LocalGlobals.vr_supported = value
	if is_instance_valid(lefthand) and is_instance_valid(righthand):
		lefthand.rays_disabled = !value
		righthand.rays_disabled = !value
		world_ray.enabled = false
		world_ray.hide()
		ui_ray.enabled = false
		ui_ray.hide()
	if !value:
		print("DISABLING XR")
		collision_shape_3d.shape.height = 1.0
		collision_shape_3d.shape.radius = .1
		if OS.get_name() != "Web":
			get_viewport().use_xr = false
		camera_3d.current = true
		if get_viewport().get_camera_3d() is XRCamera3D:
			get_viewport().get_camera_3d()
		camera_3d.position.y = .9
		righthand.position = Vector3(.2,.6,-.2)
		lefthand.position = Vector3(-.2,.6,0.0)
		lefthand.rotation_degrees = Vector3(-90.0,0,0)
		world_ray.enabled = true
		world_ray.show()
		ui_ray.enabled = true
		ui_ray.show()
	else:
		if OS.get_name() != "Web":
			get_viewport().use_xr = true
		xr_camera_3d.current = true

func respawn_player():
	velocity = Vector3()
	var spawnLoc = get_tree().get_nodes_in_group("PlayerSpawnLocation").pick_random()
	if spawnLoc:
		global_position = spawnLoc.global_position
	else:
		global_position = Vector3(0,4,0)

func _ready():
	world_ray.add_exception(self)
	ui_ray.add_exception(self)
	lefthand.rays_disabled = !vr_mode_enabled
	righthand.rays_disabled = !vr_mode_enabled
	respawn_player()
	if !ProjectSettings.get_setting("xr/openxr/enabled"):
		vr_mode_enabled = false
	
	if OS.get_name() == "Web":
		vr_mode_enabled = false
	
	righthand.connect("button_pressed",func(input_name):
		#Notifyvr.send_notification(name)
		if input_name == "ax_button":
			rightaxbtn = true
		)
	righthand.connect("button_released",func(input_name):
#		print("released: "+name)
		pass
		if input_name == "ax_button":
			rightaxbtn = false
		)
	#righthand.input_float_changed.connect(func(input_name:String,value:float):
##		print('value {0}, {1}'.format([name,value]))
		#pass
		#)
	righthand.input_vector2_changed.connect(func(input_name:String,value):
#		print('axis {0}, {1}'.format([name,value]))
		pass
		if input_name == "primary":
			rightStick = value
		)
	lefthand.connect("button_pressed",func(input_name):
		#print("pressed: "+name)
		pass
		if input_name == "ax_button":
			leftaxbtn = true
		)
	lefthand.connect("button_released",func(input_name):
		#print("released: "+name)
		pass
		if input_name == "ax_button":
			leftaxbtn = false
		)
	#lefthand.input_float_changed.connect(func(name:String,value:float):
		##print('value {0}, {1}'.format([name,value]))
		#pass
		#)
	lefthand.input_vector2_changed.connect(func(input_name:String,value):
#		print('axis {0}, {1}'.format([name,value]))
		pass
		if input_name == "primary":
			leftStick = value
		)

func _process(delta):
	if !vr_mode_enabled:
		menuoffset.global_rotation = Vector3()

func _physics_process(delta):
	if global_position.length() > 100000:
		respawn_player()
		flymode = true
	# Add the gravity.
	if not is_on_floor() and not flymode:
		velocity.y -= (gravity*( (scale.x+scale.y+scale.z)/3.0 )) * delta
	
	# Flat mode toggle
	if Input.is_action_just_pressed("desktoptoggle"):
		vr_mode_enabled = !vr_mode_enabled

	if vr_mode_enabled || OS.get_name() == "Android":
		#LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
		#if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		xrplayer.position.x = -xr_camera_3d.position.x
		xrplayer.position.z = -xr_camera_3d.position.z
		position.x += (transform.basis*(xr_camera_3d.position-camPrevPos)).x
		position.z += (transform.basis*(xr_camera_3d.position-camPrevPos)).z
		playercamoffset.global_position.x -= (transform.basis*(xr_camera_3d.position-camPrevPos)).x
		playercamoffset.global_position.z -= (transform.basis*(xr_camera_3d.position-camPrevPos)).z
		camPrevPos = xr_camera_3d.position
		transform = transform.rotated_local(Vector3.UP,-rightStick.x*delta)
		xrplayer.position = xrplayer.position.rotated(Vector3.UP,rightStick.x*delta)
		
		var input_dir = leftStick
		var direction = ((xr_camera_3d.transform.basis*transform.basis) * Vector3(input_dir.x, 0, -input_dir.y))
		if direction:
			velocity.x = direction.x * (SPEED*( (scale.x+scale.y+scale.z)/3.0 ))
			velocity.z = direction.z * (SPEED*( (scale.x+scale.y+scale.z)/3.0 ))
		else:
			velocity.x = move_toward(velocity.x, 0, (SPEED*( (scale.x+scale.y+scale.z)/3.0 )))
			velocity.z = move_toward(velocity.z, 0, (SPEED*( (scale.x+scale.y+scale.z)/3.0 )))
		if xr_camera_3d.position.y > 0.1:
			collision_shape_3d.shape.height = xr_camera_3d.position.y
		else:
			collision_shape_3d.shape.height = 0.1
#		collision_shape_3d.position = xr_camera_3d.position.y/2.0
	
	# Handle Jump.
	if vr_mode_enabled:
		if rightaxbtn and (is_on_floor() or flymode):
			velocity.y = (JUMP_VELOCITY*( (scale.x+scale.y+scale.z)/3.0 ))
	else:
		flat_movement()
		if (Input.is_action_just_pressed("jump") or (flymode and Input.is_action_pressed("jump"))) and (is_on_floor() or flymode) and LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
			velocity.y = (JUMP_VELOCITY*( (scale.x+scale.y+scale.z)/3.0 ))
		
	
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_key_pressed(KEY_E):
			if vr_mode_enabled:
				for node in righthand.grabbed.values():
					var rotation_basis = (basis*Vector3.UP*node.node.basis).normalized()
					node.offset = node.offset.rotated_local(
						rotation_basis,
						-event.relative.x*(MOUSE_SPEED/100)
						)
					if !Input.is_key_pressed(KEY_SHIFT):
						rotation_basis = (basis*Vector3.RIGHT*node.node.basis)
						node.offset = node.offset.rotated_local(
							rotation_basis.normalized(),
							event.relative.y*(MOUSE_SPEED/100)
							)
			else:
				for node in grabbed.values():
					var rotation_basis = (basis*Vector3.UP*node.node.basis).normalized()
					node.offset = node.offset.rotated_local(
						rotation_basis,
						-event.relative.x*(MOUSE_SPEED/100)
						)
					if !Input.is_key_pressed(KEY_SHIFT):
						rotation_basis = (basis*Vector3.RIGHT*node.node.basis)
						node.offset = node.offset.rotated_local(
							rotation_basis.normalized(),
							event.relative.y*(MOUSE_SPEED/100)
							)
		else:
			rotate_y(-event.relative.x*(MOUSE_SPEED/100))
			xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
			camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:
				match LocalGlobals.player_state:
					LocalGlobals.PLAYER_STATE_TYPING:
						LocalGlobals.set_player_state(LocalGlobals.PLAYER_STATE_PLAYING)
						LocalGlobals.emit_signal("playerreleaseuifocus")
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
					LocalGlobals.PLAYER_STATE_PLAYING:
						LocalGlobals.set_player_state(LocalGlobals.PLAYER_STATE_PAUSED)
						LocalGlobals.emit_signal("playerreleaseuifocus")
						Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					LocalGlobals.PLAYER_STATE_PAUSED:
						LocalGlobals.set_player_state(LocalGlobals.PLAYER_STATE_PLAYING)
						LocalGlobals.emit_signal("playerreleaseuifocus")
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.ctrl_pressed:
				scale *= 1.1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.ctrl_pressed:
				scale *= .9
	if event is InputEventScreenTouch:
		if event.position.x > get_viewport().size.x/2.0 and lookdrag.is_empty():
			lookdrag = {
				'index': event.index,
				'relative': Vector2(),
				'velocity': Vector2(),
				'startposition': event.position,
				'position': event.position
			}
		if event.pressed:
			if ui_ray.is_colliding():
				LocalGlobals.playerreleaseuifocus.emit()
				ui_ray.click()
				ui_ray.release()
			elif world_ray.is_colliding():
				world_ray.click()
				world_ray.release()
		if !lookdrag.is_empty() and event.index == lookdrag.index and event.pressed == false:
			lookdrag = {}
	if event is InputEventScreenDrag:
		if lookdrag and event.index == lookdrag.index:
			lookdrag = {
				'index': event.index,
				'relative': event.relative,
				'velocity': event.velocity,
				'startposition': lookdrag.startposition,
				'position': event.position
			}
			if !touchsticklook:
				rotate_y( -(event.relative.x)*(MOUSE_SPEED/100) )
				xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
				camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))

func flat_movement():
	place_grabbed_nodes()
	var joy_look_vector = Input.get_vector('lookleft','lookright','lookdown','lookup')
	if joy_look_vector.length()>.1:
		rotate_y(-joy_look_vector.x*MOUSE_SPEED)
		xr_camera_3d.rotate_x(joy_look_vector.y*MOUSE_SPEED)
		camera_3d.rotate_x(joy_look_vector.y*MOUSE_SPEED)
	if Input.is_action_just_pressed("click"):
		if grabbed.size() > 0:
			for item in grabbed.values():
				if "node" in item and "primary" in item.node:
					item.node.primary()
		else:
			if ui_ray.is_colliding():
				ui_ray.click()
			elif world_ray.is_colliding():
				world_ray.click()
	if Input.is_action_just_released("click"):
		if grabbed.size() > 0:
			for item in grabbed.values():
				if "node" in item and "primary_released" in item.node:
					item.node.primary_released()
		ui_ray.release()
		world_ray.release()
	if Input.is_action_just_pressed("rightclick"):
		if vr_mode_enabled:
			righthand.grip()
		else:
			grip()
	if Input.is_action_just_released("rightclick"):
		if vr_mode_enabled:
			righthand.ungrip()
		else:
			ungrip()
	if Input.is_action_just_pressed("middleclick"):
		if vr_mode_enabled:
			righthand.contextMenuSummon()
		else:
			contextMenuSummon()
	if !Input.is_action_pressed("rightclick"):
		if camray.is_colliding():
			grab_point = camera_3d.to_local(camray.get_collision_point())
		else:
			grab_point = camera_3d.to_local(camera_3d.project_position(get_viewport().size/2.0, 10.0))
	if Input.is_action_just_pressed("desktop_secondary") and LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		if LocalGlobals.editor_refs.has('vreditor'):
			LocalGlobals.editor_refs.mainpanel.global_position = camera_3d.to_global(Vector3(0,0,-.5))
			LocalGlobals.editor_refs.mainpanel.look_at(camera_3d.global_position, Vector3.UP, true)
			#LocalGlobals.editor_refs.mainpanel.global_rotation.x += deg_to_rad(90.0)
		else:
			var vreditor = load("res://mainAssets/ui/3dPanel/editmode/vreditor.tscn").instantiate()
			get_tree().get_first_node_in_group("localroot").add_child(vreditor)
			vreditor.global_position = righthand.hand_menu_point.global_position
	righthand.look_at(camera_3d.to_global(grab_point))
	
	if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
		if flymode:
			direction.y = (camera_3d.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized().y
		if direction:
			velocity.x = direction.x * (SPEED*( (scale.x+scale.y+scale.z)/3.0 ))
			velocity.z = direction.z * (SPEED*( (scale.x+scale.y+scale.z)/3.0 ))
			if flymode:
				velocity.y = direction.y * (SPEED*( (scale.x+scale.y+scale.z)/3.0 ))
		else:
			velocity.x = move_toward(velocity.x, 0, (SPEED*( (scale.x+scale.y+scale.z)/3.0 )))
			velocity.z = move_toward(velocity.z, 0, (SPEED*( (scale.x+scale.y+scale.z)/3.0 )))
			if flymode:
				velocity.y = move_toward(velocity.y, 0, (SPEED*( (scale.x+scale.y+scale.z)/3.0 )))
	if lookdrag:
		if touchsticklook:
			rotate_y( -(lookdrag.position.x-lookdrag.startposition.x)*(MOUSE_SPEED/800) )
			xr_camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )
			camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )

func contextMenuSummon():
	handmenu.summon(camera_3d.to_global(Vector3(0,0,-.5)), camera_3d.global_position)

func place_grabbed_nodes():
	for item in grabbed.values():
		if Input.is_action_just_pressed("scrollup"):
			if Input.is_physical_key_pressed(KEY_SHIFT):
				item.offset.basis.x *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.y *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.z *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
			else:
				item.offset.origin *= Engine.get_singleton("settings_manager").grabbed_object_scale_factor
		if Input.is_action_just_pressed("scrolldown"):
			if Input.is_physical_key_pressed(KEY_SHIFT):
				item.offset.basis.x *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.y *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
				item.offset.basis.z *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
			else:
				item.offset.origin *= 1.0/Engine.get_singleton("settings_manager").grabbed_object_scale_factor
		item.node.global_transform = camera_3d.global_transform * item.offset

func grip():
	print('grip')
	if ui_ray.is_colliding():
		var rayCollided = ui_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)
	elif world_ray.is_colliding():
		var rayCollided = world_ray.get_collider()
		if rayCollided.has_meta("grabbable"):
			grab(rayCollided,true)
	grabbing = true

func ungrip():
	for item in grabbed.values():
		releasegrab(item.node)

func grab(node:Node, laser:bool=false):
	var tmpgrab = node.get_meta("grabbable")
	if tmpgrab:
		if node.is_class("RigidBody3D"):
			node.freeze = true
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': camera_3d.global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'frozen': node.freeze,
					'node': node
				}
		else:
			if laser:
				pass
			if !grabbed.has(node.name):
				grabbed[node.name] = {
					"parent": node.get_parent(),
					'offset': camera_3d.global_transform.affine_inverse() * node.global_transform,
					'rotoffset': node.global_rotation,
					'node': node
				}

func releasegrab(node:Node):
	if grabbed.has(node.name):
		if node is RigidBody3D:
			node.freeze = false
		grabbed.erase(node.name)
		
