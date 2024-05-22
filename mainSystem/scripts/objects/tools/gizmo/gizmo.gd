extends Node3D
@onready var x = $x
@onready var y = $y
@onready var z = $z
@export var target:Node

var size_factor = 7.5

func _ready():
	LocalGlobals.clear_gizmos.connect(func():
		queue_free()
		)

func _physics_process(delta):
	if is_instance_valid(target):
		var dist = target.global_position.distance_to(get_tree().get_first_node_in_group("playerCamera").global_position)
		scale = Vector3(1,1,1)*dist/size_factor
		global_position = target.global_position
	else:
		queue_free()
