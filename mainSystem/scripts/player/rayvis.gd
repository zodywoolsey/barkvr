extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics

var target := Vector3()

func _process(delta):
	if get_tree().get_first_node_in_group("player"):
		var dist = target.distance_to(get_tree().get_first_node_in_group("playerCamera").global_position)
		pointer.scale = Vector3(1,1,1)*dist/200.0
		physics.scale = Vector3(1,1,1)*dist/200.0
		pointer.global_position = target
		physics.global_position = target

func setType(type:String):
	pass
	if type == "rigidbody":
		physics.show()
		pointer.hide()
	if type == "pointer":
		physics.hide()
		pointer.show()
