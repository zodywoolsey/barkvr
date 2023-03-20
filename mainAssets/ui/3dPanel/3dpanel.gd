extends Node3D
@export var viewport : SubViewport
@export var mesh : MeshInstance3D
@export var colShape : CollisionShape3D

func _ready():
	mesh.mesh.material.albedo_texture = viewport.get_texture()

func _process(delta):
	colShape.shape.size = Vector3(mesh.mesh.size.x,.01,mesh.mesh.size.y)
