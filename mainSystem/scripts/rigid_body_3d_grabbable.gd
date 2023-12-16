extends RigidBody3D

@export var grabbable : bool = true
@export var dampening : float = 0
var parent:Node

# Called when the node enters the scene tree for the first time.
func _ready():
	if grabbable:
		set_meta("grabbable", grabbable)


func resetPhysicsProps():
	linear_damp = dampening

func setPhysicsProps(dampening: float):
	linear_damp = dampening

func assignParent():
	parent = get_parent()

func resetParent():
	reparent(parent)
