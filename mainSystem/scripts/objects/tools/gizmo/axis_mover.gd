extends StaticBody3D

@onready var gizmo:Node3D = $".."
var prev_click_pos:Vector3

@onready var xcol:CollisionShape3D = %xcol
@onready var ycol:CollisionShape3D = %ycol
@onready var zcol:CollisionShape3D = %zcol

var interaction_index:int=-1

var _offset:=Vector3()

@export_enum("x","y","z") var _axis:String = "x"

func laser_input(data:Dictionary):
	if data.pressed:
		interaction_index = data.index
	if gizmo.target and prev_click_pos != data.position and data.index == interaction_index:
		if prev_click_pos and data.pressed:
			_set_colliders(true)
			var tmppos:Vector3=gizmo.target.global_position
			tmppos[_axis] = data.position[_axis]-_offset[_axis]
			gizmo.target.global_position = tmppos
			prev_click_pos = data.position
		else:
			interaction_index = -1
			_set_colliders(false)
			prev_click_pos = data.position
			_offset = data.position-gizmo.target.global_position
			Journaling.set_property(
				get_tree().get_first_node_in_group('localworldroot').get_path_to(gizmo.target),
				"global_position",
				gizmo.target.global_position
				)
	elif data.has('hovering'):
		if !data.hovering:
			interaction_index = -1
			_set_colliders(false)
			prev_click_pos = Vector3()
			_offset = Vector3()

func _set_colliders(is_drag:bool=false):
	match _axis:
		"x":
			if is_drag:
				zcol.disabled = true
				ycol.disabled = true
				xcol.shape.size.x = 10000000000.0
				xcol.shape.size.y = 10000000000.0
			else:
				zcol.disabled = false
				ycol.disabled = false
				xcol.shape.size.x = 1.1
				xcol.shape.size.y = 0.1
		"y":
			if is_drag:
				zcol.disabled = true
				xcol.disabled = true
				ycol.shape.size.x = 10000000000.0
				ycol.shape.size.y = 10000000000.0
			else:
				zcol.disabled = false
				xcol.disabled = false
				ycol.shape.size.x = 1.1
				ycol.shape.size.y = 0.1
		"z":
			if is_drag:
				xcol.disabled = true
				ycol.disabled = true
				zcol.shape.size.x = 10000000000.0
				zcol.shape.size.y = 10000000000.0
			else:
				xcol.disabled = false
				ycol.disabled = false
				zcol.shape.size.x = 1.1
				zcol.shape.size.y = 0.1
