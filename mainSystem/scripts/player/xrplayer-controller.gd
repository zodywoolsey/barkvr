extends CharacterBody3D


#controllers:
@onready var righthand = %righthand
@onready var lefthand = %lefthand
@onready var xr_camera_3d = $xrplayer/XrCamera3d
@onready var xrplayer = $xrplayer
@onready var playercamoffset = $playercamoffset
@onready var camray = $xrplayer/XrCamera3d/camray
@onready var collision_shape_3d = %CollisionShape3D

#controller input vars:
var rightStick :Vector2 = Vector2()
var rightGrip :float
var rightaxbtn :bool = false
var leftStick :Vector2 = Vector2()
var leftGrip :float
var leftaxbtn :bool = false

var camPrevPos : Vector3 = Vector3()

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var selected : Array = []
var grabbed : Dictionary = {}
var vreditor : Node3D = null
var vrinspector : Control = null

# flat vars
var MOUSE_SPEED := .1
var lookdrag : Dictionary = {} #{'index': -1,'relative': Vector2(),'velocity': Vector2()}
@export var touchsticklook := false
var grab_point := Vector3()


func _ready():
	if !LocalGlobals.vr_supported:
		xr_camera_3d.position.y = .9
		righthand.position = Vector3(.2,.6,-.2)
#		lefthand.hide()
	var spawnLoc = get_tree().get_nodes_in_group("PlayerSpawnLocation").pick_random()
	if spawnLoc:
		global_position = spawnLoc.global_position
	else:
		global_position = Vector3(0,4,0)
	righthand.connect("button_pressed",func(name):
		pass
		if name == "ax_button":
			rightaxbtn = true
		)
	righthand.connect("button_released",func(name):
#		print("released: "+name)
		pass
		if name == "ax_button":
			rightaxbtn = false
		)
	righthand.input_float_changed.connect(func(name:String,value:float):
#		print('value {0}, {1}'.format([name,value]))
		pass
		)
	righthand.input_vector2_changed.connect(func(name:String,value):
#		print('axis {0}, {1}'.format([name,value]))
		pass
		if name == "primary":
			rightStick = value
		)
	lefthand.connect("button_pressed",func(name):
#		print("pressed: "+name)
		pass
		if name == "ax_button":
			leftaxbtn = true
		)
	lefthand.connect("button_released",func(name):
#		print("released: "+name)
		pass
		if name == "ax_button":
			leftaxbtn = false
		)
	lefthand.input_float_changed.connect(func(name:String,value:float):
#		print('value {0}, {1}'.format([name,value]))
		pass
		)
	lefthand.input_vector2_changed.connect(func(name:String,value):
#		print('axis {0}, {1}'.format([name,value]))
		pass
		if name == "primary":
			leftStick = value
		)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Flat mode toggle
	if Input.is_action_just_pressed("desktoptoggle"):
		if LocalGlobals.vr_supported:
			LocalGlobals.vr_supported = false
			xr_camera_3d.position.y = .9
			righthand.position = Vector3(.2,.6,-.2)
#			lefthand.hide()

	# Handle Jump.
	if (rightaxbtn or Input.is_action_just_pressed("jump")) and is_on_floor() and LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		velocity.y = JUMP_VELOCITY
	
	if LocalGlobals.vr_supported || OS.get_name() == "Android":
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
		if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
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
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
			if xr_camera_3d.position.y > 0.01:
				collision_shape_3d.shape.height = xr_camera_3d.position.y
			else:
				collision_shape_3d.shape.height = 0.1
	#		collision_shape_3d.position = xr_camera_3d.position.y/2.0
	else:
		flat_movement()
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*(MOUSE_SPEED/100))
		xr_camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed == true:
			if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_TYPING:
				LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
				LocalGlobals.emit_signal("playerreleaseuifocus")
			elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PAUSED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
#		if event.is_action("ui_accept"):
#			if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_TYPING:
#				LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_PLAYING
#				LocalGlobals.emit_signal("playerreleaseuifocus")
	if event is InputEventScreenTouch:
#		Notifyvr.send_notification(str(event))
		if event.position.x > get_viewport().size.x/2.0 and lookdrag.is_empty():
			lookdrag = {
				'index': event.index,
				'relative': Vector2(),
				'velocity': Vector2(),
				'startposition': event.position,
				'position': event.position
			}
		if event.pressed:
#			Notifyvr.send_notification("double tapped")
			righthand.ui_ray.isclick = true
			await get_tree().process_frame
			righthand.ui_ray.isrelease = true
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
				xr_camera_3d.rotate_x( -(event.relative.y)*(MOUSE_SPEED/100) )
		

func flat_movement():
	if Input.is_action_just_pressed("click"):
		righthand.ui_ray.isclick = true
	if Input.is_action_just_released("click"):
		righthand.ui_ray.isrelease = true
	if Input.is_action_just_pressed("rightclick"):
		righthand.grip()
	if Input.is_action_just_released("rightclick"):
		righthand.ungrip()
	if Input.is_action_just_pressed("middleclick"):
		righthand.contextMenuSummon()
	if !Input.is_action_pressed("rightclick"):
		if camray.is_colliding():
			grab_point = xr_camera_3d.to_local(camray.get_collision_point())
		else:
			grab_point = xr_camera_3d.to_local(xr_camera_3d.project_position(get_viewport().size/2.0, 10.0))
	righthand.look_at(xr_camera_3d.to_global(grab_point))
	
	if LocalGlobals.player_state == LocalGlobals.PLAYER_STATE_PLAYING:
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if lookdrag:
		if touchsticklook:
			rotate_y( -(lookdrag.position.x-lookdrag.startposition.x)*(MOUSE_SPEED/800) )
			xr_camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )
