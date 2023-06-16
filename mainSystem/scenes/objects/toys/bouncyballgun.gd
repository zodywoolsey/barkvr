extends RigidBody3D

@onready var mesh_instance_3d = $MeshInstance3D/MeshInstance3D

var timer : float = 0.0
var pressed : bool

func primary(press:bool):
	pressed = press

func _process(delta):
	timer += delta
	if timer > .1 and pressed:
		timer = 0.0
		var tmp = get_tree().get_first_node_in_group("worldroot")
		if tmp:
			var obj = load("res://mainSystem/scenes/objects/toys/rigid_body_3d_grabbable.tscn").instantiate()
			tmp.add_child(obj)
			obj.global_position = mesh_instance_3d.global_position
			obj.linear_velocity = (mesh_instance_3d.global_position-global_position).normalized()*20.0
