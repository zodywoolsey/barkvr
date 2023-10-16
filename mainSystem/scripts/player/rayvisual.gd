class_name rayvisscript
extends RayCast3D

var rayvis = preload("res://mainSystem/scenes/player/rayvis.tscn")
var vis
var vispos := Vector3()
@export var leftside:=false

func _init():
	vis = rayvis.instantiate()
	add_child.call_deferred(vis)

func procrayvis():
	vispos = get_collision_point()
	var tmpnorm = get_collision_normal()
	if is_colliding():
		if is_instance_valid(get_collider()):
			if get_collider().is_class("RigidBody3D"):
				vis.setType('rigidbody')
			else:
				vis.setType('pointer')
	else:
		vispos = to_global(Vector3(0,0,-10))
	vis.target.x = lerpf(vis.target.x, vispos.x, .9)
	vis.target.z = lerpf(vis.target.z, vispos.z, .9)
	vis.target.y = lerpf(vis.target.y, vispos.y, .9)
	
