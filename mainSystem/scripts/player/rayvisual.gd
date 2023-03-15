extends RayCast3D

var vis := MeshInstance3D.new()
var vismat := StandardMaterial3D.new()

func _ready():
	vismat.no_depth_test = true
	vis.mesh = BoxMesh.new()
	vis.mesh.size = Vector3(.01,.01,.01)
	vis.mesh.surface_set_material(0,vismat)
	get_tree().root.add_child.call_deferred(vis)

func _process(delta):
	var tmp = get_collision_point()
	vis.global_position.x = lerpf(vis.global_position.x, tmp.x, .1)
	vis.global_position.z = lerpf(vis.global_position.z, tmp.z, .1)
	vis.global_position.y = lerpf(vis.global_position.y, tmp.y, .1)
