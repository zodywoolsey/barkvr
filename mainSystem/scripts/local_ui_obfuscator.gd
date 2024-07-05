extends Node3D

func _ready():
	for child in get_children():
		child.name = str(hash(child))
