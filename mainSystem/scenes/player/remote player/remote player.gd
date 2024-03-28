extends Node3D

var targetpos:Vector3 = Vector3()
var speed:float = 1.5
var time_since = 0.0

func set_target_pos(new_pos:Vector3):
	targetpos=new_pos
	create_tween().tween_property(self,'global_position',targetpos,time_since)
	time_since = 0.0

func _process(delta):
	time_since += delta
