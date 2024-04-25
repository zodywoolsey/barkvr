@tool
class_name Line3D
extends MeshInstance3D

# this tool was made by zodiepupper under the MIT license

var amesh := ArrayMesh.new()
var vertices := PackedVector3Array()
var arrays := Array()

@export var target := Vector3():
	set(value):
		target = value
		vertices = [Vector3(),target]
		arrays.clear()
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		amesh.clear_surfaces()
		amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,arrays)
		mesh = amesh

