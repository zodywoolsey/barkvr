@tool
extends StaticBody3D

@onready var mesh_instance_3d : MeshInstance3D = $MeshInstance3D
@onready var label_3d = $Label3D
@onready var collision_shape_3d = $CollisionShape3D

var roughness = 0.0
var prevRough = 0.0

var hover = false

func _ready():
	pass

func _process(delta):
	prevRough = lerpf(prevRough,roughness,.1)
	var tmp = mesh_instance_3d.mesh.surface_get_material(0)
	tmp.albedo_color.a = lerpf(tmp.albedo_color.a, roughness, .1)

## called when the player laser hovers over the button
## accepts a "data" Dictionary that should at least have a collision_point
func laserHover(data:Dictionary):
	if data.has('hovering') and data['hovering'] == true:
		roughness = 0.25
		hover = true
	else:
		roughness = 0.01
		hover = false

func laserClick(data:Dictionary):
	var tmp = load('res://mainSystem/scenes/objects/toys/rigid_body_3d_grabbable.tscn').instantiate()
	get_tree().root.add_child(tmp)
	tmp.global_position = global_position
