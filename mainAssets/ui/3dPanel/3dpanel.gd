extends Node3D
@onready var sub_viewport = $SubViewport
@onready var panel = $panel
@onready var collision_shape_3d = $panel/StaticBody3D/CollisionShape3D

func _ready():
	panel.mesh.material.albedo_texture = sub_viewport.get_texture()

func _process(delta):
	collision_shape_3d.shape.size = Vector3(panel.mesh.size.x,.01,panel.mesh.size.y)
