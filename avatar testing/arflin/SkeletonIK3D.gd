@tool
extends SkeletonIK3D
@onready var arflin = $".."
@export var offset := Vector3()

func _ready():
#	if !Engine.is_editor_hint():
	start()

func _process(delta):
	magnet = arflin.get_bone_global_pose(arflin.find_bone('Left_wrist')).origin+offset
