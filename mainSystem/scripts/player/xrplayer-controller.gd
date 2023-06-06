extends CharacterBody3D


#controllers:
@onready var righthand = $xrplayer/righthand
@onready var lefthand = $xrplayer/lefthand
@onready var xr_camera_3d = $xrplayer/XrCamera3d
@onready var xrplayer = $xrplayer
@onready var playercamoffset = $playercamoffset

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
@onready var collision_shape_3d = $CollisionShape3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var selected : Array = []
var grabbed : Dictionary = {}
var vreditor : Node3D = null
var vrinspector : Control = null

func _ready():
	var spawnLoc = get_tree().get_nodes_in_group("PlayerSpawnLocation").pick_random()
	global_position = spawnLoc.global_position
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

	# Handle Jump.
	if rightaxbtn and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	xrplayer.position.x = -xr_camera_3d.position.x
	xrplayer.position.z = -xr_camera_3d.position.z
	position.x += (transform.basis*(xr_camera_3d.position-camPrevPos)).x
	position.z += (transform.basis*(xr_camera_3d.position-camPrevPos)).z
	playercamoffset.global_position.x -= (transform.basis*(xr_camera_3d.position-camPrevPos)).x
	playercamoffset.global_position.z -= (transform.basis*(xr_camera_3d.position-camPrevPos)).z
	camPrevPos = xr_camera_3d.position
	transform = transform.rotated_local(Vector3.UP,-rightStick.x*delta)
	xrplayer.position = xrplayer.position.rotated(Vector3.UP,rightStick.x*delta)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = leftStick
	var direction = ((xr_camera_3d.transform.basis*transform.basis) * Vector3(input_dir.x, 0, -input_dir.y))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
