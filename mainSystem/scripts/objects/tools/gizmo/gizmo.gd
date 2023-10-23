extends Node3D
@onready var x = $x
@onready var y = $y
@onready var z = $z
@export var target:Node

func _ready():
	LocalGlobals.clear_gizmos.connect(func():
		queue_free()
		)

func _process(delta):
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		queue_free()
