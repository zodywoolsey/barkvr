extends Node3D

var dismissTimer = 0.0

func _process(delta):
	dismissTimer += delta
	var tmp = false
	for i in get_children():
		if i.hover == true:
			tmp = true
			dismissTimer = 0.0
			break;
	if tmp == false and dismissTimer > .2:
		hide()
		scale = Vector3()

func summon(pos:Vector3, look:Vector3):
	global_position = pos
	scale = Vector3(1,1,1)
	dismissTimer = 0
	look_at(look)
	show()
