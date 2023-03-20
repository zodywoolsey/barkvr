extends RayCast3D

var rayvis = preload("res://mainSystem/scenes/player/rayvis.tscn")
var vis
func _ready():
	vis = rayvis.instantiate()
	get_tree().root.add_child.call_deferred(vis)
	

func _process(delta):
	if !is_colliding():
		vis.hide()
	elif !vis.visible:
		vis.show()
	var tmp = get_collision_point()
	vis.global_position.x = lerpf(vis.global_position.x, tmp.x, .1)
	vis.global_position.z = lerpf(vis.global_position.z, tmp.z, .1)
	vis.global_position.y = lerpf(vis.global_position.y, tmp.y, .1)
