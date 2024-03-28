extends Node3D

@onready var parent :JoltSliderJoint3D= get_parent()
@onready var low = $low
@onready var high = $high

func _ready():
	if parent is JoltSliderJoint3D:
		if parent.limit_enabled:
			low.show()
			high.show()
			low.position.x = parent.limit_lower
			high.position.x = parent.limit_upper
