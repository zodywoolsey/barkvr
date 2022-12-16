extends Node3D

var camera

func _ready():
	camera = $Window/Camera3d


func _process(delta):
	camera.global_position = global_position
	camera.global_rotation = global_rotation
