@tool
#class_name GridMenuButton
extends StaticBody3D

@onready var mesh_instance_3d : MeshInstance3D = $MeshInstance3D
@onready var label_3d = $Label3D
@onready var collision_shape_3d = $CollisionShape3D

@export_file var itemToSpawn
@export var text :String

var alpha = 0.1

var hover = false

func _ready():
	label_3d.text = text

func _physics_process(delta):
	var tmp = mesh_instance_3d.mesh.surface_get_material(0)
	tmp.albedo_color.a = lerpf(tmp.albedo_color.a, alpha, .1)

func laser_input(data:Dictionary):
	match data.action:
		"click":
			if itemToSpawn:
				for i in range(1):
					var tmp = load(itemToSpawn).instantiate()
					get_tree().get_first_node_in_group("localworldroot").add_child(tmp)
					tmp.global_position = global_position
			if label_3d.text == "set root":
				if LocalGlobals.editor_refs.has('inspector'):
					LocalGlobals.editor_refs.inspector.setRoot(get_tree().get_first_node_in_group('localworldroot'))
		"hover":
			if data.has('hovering') and data['hovering'] == true:
				alpha = 0.25
				hover = true
			else:
				alpha = 0.1
				hover = false
