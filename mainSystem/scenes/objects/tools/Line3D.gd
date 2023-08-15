class_name Line3D
extends MeshInstance3D

var mat : BaseMaterial3D

var amesh := ArrayMesh.new()
var vertices := PackedVector3Array()

var timer := 0.0
var target := Vector3()

func _init():
	vertices.append(Vector3())
	vertices.append(Vector3())
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,arrays)
	mesh = amesh

func _ready():
	amesh

func _process(delta):
	timer+=delta
	vertices[1] = to_local(target)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	amesh.clear_surfaces()
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,arrays)
