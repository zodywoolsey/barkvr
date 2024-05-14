extends Node3D

@onready var ren_ik = $RenIK
@onready var ren_ik_foot_placement = $RenIKFootPlacement

@export_node_path("Skeleton3D") var armature_skeleton_path: NodePath:
	set(value):
		armature_skeleton_path = value

func _ready():
	ren_ik.armature_skeleton_path = armature_skeleton_path
	ren_ik_foot_placement.armature_skeleton_path = armature_skeleton_path
