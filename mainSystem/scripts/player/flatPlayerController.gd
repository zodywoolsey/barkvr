extends CharacterBody3D

@onready var camera_3d = $Camera3D
@onready var world_ray = $Camera3D/worldRay
@onready var ui_ray = $Camera3D/uiRay

@export var touchsticklook = false

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var MOUSE_SPEED = .1

var selected : Array = []

var lookdrag : Dictionary = {}
#{'index': -1,'relative': Vector2(),'velocity': Vector2()}
	
func _physics_process(delta):
	if ui_ray.is_colliding():
		world_ray.enabled = false
	else:
		world_ray.enabled = true
	if Input.is_action_just_pressed("click"):
		world_ray.click()
		ui_ray.click()
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if lookdrag and touchsticklook:
		rotate_y( -(lookdrag.position.x-lookdrag.startposition.x)*(MOUSE_SPEED/800) )
		camera_3d.rotate_x( -(lookdrag.position.y-lookdrag.startposition.y)*(MOUSE_SPEED/800) )
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*(MOUSE_SPEED/100))
		camera_3d.rotate_x(-event.relative.y*(MOUSE_SPEED/100))
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed == true:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
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
		if event.double_tap:
			Notifyvr.send_notification("double tapped")
			ui_ray.click()
			await get_tree().process_frame
			ui_ray.release()
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
				camera_3d.rotate_x( -(event.relative.y)*(MOUSE_SPEED/100) )
		
