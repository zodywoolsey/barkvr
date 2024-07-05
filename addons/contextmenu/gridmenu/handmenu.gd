extends Node3D

var dismissTimer = 0.0

func _physics_process(delta):
	dismissTimer += delta
	var tmp = false
	for i in get_children():
		if i.hover == true:
			tmp = true
			dismissTimer = 0.0
			break
	if visible and tmp == false and dismissTimer > .2:
		hide()
		scale = Vector3(.0001,.0001,.0001)

func summon(pos:Vector3, look:Vector3):
	global_position = pos
	scale = Vector3(1,1,1)
	dismissTimer = 0
	look_at(look)
	show()
