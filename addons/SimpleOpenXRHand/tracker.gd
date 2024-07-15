extends Node3D

var target:Vector3=Vector3()
var speed:float=.3
var collon:bool = true:
	set(value):
		collon = value
		collision_shape_3d.disabled = !collon
		area_collision_shape_3d.disabled = !collon

var collision_layers:int=6
@onready var rigid_body_3d = $RigidBody3D
@onready var collision_shape_3d = $RigidBody3D/CollisionShape3D
@onready var area_3d = $Area3D
@onready var area_collision_shape_3d = $Area3D/CollisionShape3D

#setup the collision layer and mask bitflag and disable collision if that is set
func _ready():
	rigid_body_3d.collision_layer = collision_layers
	rigid_body_3d.collision_mask = collision_layers
	collision_shape_3d.disabled = !collon
	area_collision_shape_3d.disabled = !collon

func _process(delta):
	for body in area_3d.get_overlapping_bodies():
		if "laser_input" in body:
			body.laser_input({
						'hovering': true,
						'pressed': false,
						'position': area_3d.global_position,
						'action': 'hover',
						'index': 0
					})

#dampening for the hand tracker indicator to smooth out tracking jitter
func _physics_process(delta):
	#position = target
	position.x = lerpf(position.x,target.x,speed)
	position.y = lerpf(position.y,target.y,speed)
	position.z = lerpf(position.z,target.z,speed)
