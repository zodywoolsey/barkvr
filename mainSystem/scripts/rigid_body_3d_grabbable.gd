extends RigidBody3D

@export_enum("none", "physical", "kinematic") var grabbable = 0
@export var dampening : float = 0
var parent:Node

# Called when the node enters the scene tree for the first time.
func _ready():
	if grabbable:
		set_meta("grabbable", grabbable)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func resetPhysicsProps():
	linear_damp = dampening

func setPhysicsProps(dampening: float):
	linear_damp = dampening

func assignParent():
	parent = get_parent()

func resetParent():
	parent.add_child(self)
