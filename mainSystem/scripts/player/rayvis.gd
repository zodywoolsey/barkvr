extends Node3D
@onready var pointer = $pointer
@onready var physics = $physics
@onready var cursor = $cursor

@export var leftside := false

var cursor_size_factor = 50.0

var target := Vector3()

func _process(delta):
	if get_tree().get_first_node_in_group("player"):
		var dist = target.distance_to(get_tree().get_first_node_in_group("playerCamera").global_position)
		pointer.scale = Vector3(1,1,1)*dist/cursor_size_factor
		physics.scale = Vector3(1,1,1)*dist/cursor_size_factor
		cursor.scale = Vector3(1,1,1)*dist/cursor_size_factor
		pointer.global_position = target
		physics.global_position = target
		cursor.global_position = target

func setType(type:String):
	pass
	if type == "rigidbody":
		physics.show()
		pointer.hide()
#		cursor.show()
	if type == "pointer":
		physics.hide()
		pointer.show()
#		cursor.show()
