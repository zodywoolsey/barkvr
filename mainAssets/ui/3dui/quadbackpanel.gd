extends MeshInstance3D

func _init():
	mesh = QuadMesh.new()
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = Color.BLACK
	mesh.material.shading_mode = 0
	mesh.material.cull_mode = 2

func detect_size(target:VisualInstance3D):
	if target is VisualInstance3D:
		mesh.size.x = target.get_aabb().size.x
		mesh.size.y = target.get_aabb().size.y
