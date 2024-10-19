@tool
class_name GridMenuButton
extends StaticBody3D

@onready var mesh_instance_3d : MeshInstance3D = $MeshInstance3D
@onready var label_3d :Label3D = $Label3D
@onready var collision_shape_3d :CollisionShape3D = $CollisionShape3D

## if this button is meant to spawn a scene,
## you can set that scene file with this variable
@export_file var itemToSpawn

## sets how many of the set item should be created
## each time the button is pressed
@export var item_spawn_multiplier:float = 1

## label for the text on the button
@export var text :String:
	set(value):
		text = value
		name = text
		if label_3d:
			label_3d.text = text

## Optionally add a script to be called when the button is pressed or hovered
## [br][br]The script is instantiated and the "onhover" or
## "onclick" methods will be called when the button is hovered or clicked
@export var callscript : Script:
	set(value):
		callscript = value
		if callscript and callscript.can_instantiate():
			callscriptinstance = callscript.new()

var callscriptinstance:
	set(value):
		callscriptinstance = value
		if callscriptinstance is Node:
			add_child(callscriptinstance)

var mesh_target_size := Vector2()
var label_target_position := 0.0

var alpha := 0.5

var hover := false
var isclicked := false

signal clicked

func _ready():
	label_3d.text = text

func _physics_process(delta):
	var tmp = mesh_instance_3d.mesh.surface_get_material(0)
	tmp.albedo_color.a = lerpf(tmp.albedo_color.a, alpha, .1)
	tmp.albedo_color.r = lerpf(tmp.albedo_color.r, alpha, .1)
	tmp.albedo_color.g = lerpf(tmp.albedo_color.g, alpha, .1)
	tmp.albedo_color.b = lerpf(tmp.albedo_color.b, alpha, .1)
	if isclicked:
		mesh_target_size = Vector2(.02,.02)
		label_target_position = -.01
	elif hover:
		mesh_target_size = Vector2(.11,.11)
		label_target_position = .01
	else:
		mesh_target_size = Vector2(.09,.09)
		label_target_position = .0
	label_3d.position.y = lerpf(label_3d.position.y, label_target_position, .1)
	mesh_instance_3d.mesh.size.y = lerpf(mesh_instance_3d.mesh.size.y,mesh_target_size.y,.2)
	mesh_instance_3d.mesh.size.x = lerpf(mesh_instance_3d.mesh.size.x,mesh_target_size.y,.2)

func _check_callscriptinstance():
	if !is_instance_valid(callscriptinstance) and callscript != null and callscript.can_instantiate():
		callscriptinstance = callscript.new()

func laser_input(data:Dictionary):
	_check_callscriptinstance()
	match data.action:
		"click":
			if "pressed" in data:
				if data.pressed:
					isclicked = true
					clicked.emit()
					if itemToSpawn != null:
						for i in range(item_spawn_multiplier):
							var tmp = load(itemToSpawn).instantiate()
							get_tree().get_first_node_in_group("localworldroot").add_child(tmp)
							tmp.global_position = global_position
					if callscriptinstance != null and 'onclick' in callscriptinstance:
						callscriptinstance.onclick()
					if label_3d.text == "set root":
						if LocalGlobals.editor_refs.has('inspector'):
							LocalGlobals.editor_refs.inspector.setRoot(get_tree().get_first_node_in_group('localworldroot'))
				else:
					isclicked = false
		"hover":
			if callscriptinstance != null and 'onhover' in callscriptinstance:
				callscriptinstance.onhover()
			if data.has('hovering') and data['hovering'] == true:
				alpha = 1.0
				hover = true
			else:
				alpha = 0.5
				hover = false
