extends Node3D

@onready var ren_ik = $RenIK
@onready var ren_ik_foot_placement = $RenIKFootPlacement

@export var armature_skeleton: Node3D:
	set(value):
		armature_skeleton = value
		ren_ik.armature_skeleton_path = ren_ik.get_path_to(armature_skeleton)
		print(ren_ik.armature_skeleton_path)
		ren_ik_foot_placement.armature_skeleton_path = ren_ik_foot_placement.get_path_to(armature_skeleton)
		print(ren_ik_foot_placement.armature_skeleton_path)

func _ready():
	ren_ik.armature_skeleton_path = ren_ik.get_path_to(armature_skeleton)
	ren_ik_foot_placement.armature_skeleton_path = ren_ik_foot_placement.get_path_to(armature_skeleton)
	var tmp = _find_skeleton(get_parent_node_3d())
	print(tmp)
	print(armature_skeleton)
	armature_skeleton = tmp
	print(armature_skeleton)

func _find_skeleton(node:Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	elif node.get_child_count()>0:
		for child in node.get_children():
			return _find_skeleton(child)
	return null
