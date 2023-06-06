class_name rayvisscript
extends RayCast3D

var rayvis = preload("res://mainSystem/scenes/player/rayvis.tscn")
var vis
func _ready():
	vis = rayvis.instantiate()
	get_tree().root.add_child.call_deferred(vis)

func procrayvis(delta):
	var tmp = get_collision_point()
	var tmpnorm = get_collision_normal()
	if is_colliding():
		if get_collider().is_class("RigidBody3D"):
			vis.setType('rigidbody')
		else:
			vis.setType('pointer')
	else:
		tmp = to_global(Vector3(0,0,-10))
	vis.global_position.x = lerpf(vis.global_position.x, tmp.x, .9)
	vis.global_position.z = lerpf(vis.global_position.z, tmp.z, .9)
	vis.global_position.y = lerpf(vis.global_position.y, tmp.y, .9)
	
