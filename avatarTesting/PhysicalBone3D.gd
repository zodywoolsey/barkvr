extends PhysicalBone3D

@export_enum("none", "physical", "kinematic") var grabbable = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if grabbable:
		set_meta("grabbable", grabbable)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
