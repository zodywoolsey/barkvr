extends MeshInstance3D

var targetpos:Vector3 = Vector3()
var speed:float = .4

func _process(delta):
	global_position.x = lerpf(
		global_position.x,
		targetpos.x,
		speed
	)
	global_position.y = lerpf(
		global_position.y,
		targetpos.y,
		speed
	)
	global_position.z = lerpf(
		global_position.z,
		targetpos.z,
		speed
	)
