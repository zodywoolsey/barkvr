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
	if !LocalGlobals.vr_supported:
		var player_size_mult:float=1.0
		if is_instance_valid(get_tree().get_first_node_in_group("player")):
			var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
			player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
		global_position = (get_viewport().get_camera_3d().project_position(get_viewport().size/2.0, player_size_mult))
	scale = Vector3(1,1,1)
	dismissTimer = 0
	look_at(look)
	show()
