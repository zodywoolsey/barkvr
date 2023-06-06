extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics

func _process(delta):
	if get_tree().get_first_node_in_group("player"):
		var dist = global_position.distance_to(get_tree().get_first_node_in_group("playerCamera").global_position)
		scale = Vector3(1,1,1)*dist/1.0
		

func setType(type:String):
	pass
	if type == "rigidbody":
		physics.show()
		pointer.hide()
	if type == "pointer":
		physics.hide()
		pointer.show()
