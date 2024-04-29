@tool
class_name Line3D
extends MeshInstance3D

# this tool was made by zodiepupper under the MIT license

var amesh := ArrayMesh.new()
var vertices := PackedVector3Array()
var arrays := Array()
var spline := Curve3D.new()

@export var target := Vector3(0.0,.1,0.0)

var current_pos := Vector3():
	set(value):
		current_pos = value
		spline.clear_points()
		spline.add_point(Vector3())
		spline.add_point(current_pos, (target-current_pos) )
		spline.bake_interval = .1
		vertices = spline.get_baked_points()
		arrays.clear()
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		amesh.clear_surfaces()
		amesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP,arrays)
		mesh = amesh

func _process(delta):
	current_pos = Vector3(
		lerpf(current_pos.x,target.x,.1),
		lerpf(current_pos.y,target.y,.1),
		lerpf(current_pos.z,target.z,.1)
	)
