extends Node3D
@onready var label_3d = $Label3D

var offset = 0

func _process(delta):
	offset = 0
	for i in get_children():
		i.position.y = offset
		offset += i.get_aabb().size.y
