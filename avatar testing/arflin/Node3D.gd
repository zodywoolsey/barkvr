@tool
extends Node3D

var timer = 0

func _process(delta):
	timer += delta
	position = Vector3(sin(timer), 5.2, cos(timer))
