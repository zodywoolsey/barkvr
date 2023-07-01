class_name panel3d
extends StaticBody3D
@onready var viewport : SubViewport = %SubViewport
@onready var mesh : MeshInstance3D = $panel
@onready var colShape : CollisionShape3D = $CollisionShape3D
@onready var label_3d = $Label3D

func _ready():
#	mesh.mesh.material.albedo_texture = viewport.get_texture()
#	print(mesh.mesh.material.albedo_texture)
	pass

func _process(delta):
	mesh.mesh.material.albedo_texture = viewport.get_texture()
	colShape.shape.size = Vector3(mesh.mesh.size.x,.01,mesh.mesh.size.y)

func laserClick(data):
	# We need to fabricate a fake mouse input even for translating a raycast click to a simulated mouse click on the viewport.
	var event = InputEventMouseMotion.new()
	
	event = InputEventMouseButton.new()
	event.pressed = data.pressed
	event.button_index = 1
	event.button_mask = 1
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = mesh.mesh.size
	var mouse_pos3D = to_local(data.position)
	# convert the relative event position from 3D to 2D
	var mouse_pos2D = Vector2(mouse_pos3D.x, mouse_pos3D.z)
	# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
	# We need to convert it into the following range: 0 -> quad_size
	mouse_pos2D.x += quad_mesh_size.x / 2
	mouse_pos2D.y += quad_mesh_size.y / 2
	# Then we need to convert it into the following range: 0 -> 1
	mouse_pos2D.x = mouse_pos2D.x / quad_mesh_size.x
	mouse_pos2D.y = mouse_pos2D.y / quad_mesh_size.y
	# Finally, we convert the position to the following range: 0 -> viewport.size
	mouse_pos2D.x = mouse_pos2D.x * viewport.size.x
	mouse_pos2D.y = mouse_pos2D.y * viewport.size.y
	# We need to do these conversions so the event's position is in the viewport's coordinate system.
	# Set the event's position and global position.
	event.position = mouse_pos2D
	event.global_position = mouse_pos2D
#	# If the event is a mouse motion event...
#	if event is InputEventMouseMotion:
#		# If there is not a stored previous position, then we'll assume there is no relative motion.
#		if last_mouse_pos2D == null:
#			event.relative = Vector2(0, 0)
#		# If there is a stored previous position, then we'll calculate the relative position by subtracting
#		# the previous position from the new position. This will give us the distance the event traveled from prev_pos
#		else:
#			event.relative = mouse_pos2D - last_mouse_pos2D
#	# Update last_mouse_pos2D with the position we just calculated.
#	last_mouse_pos2D = mouse_pos2D

	# Finally, send the processed input event to the viewport.
	viewport.push_input(event,true)
	var release = InputEventMouseButton.new()
	release.pressed = false
	release.button_index = 1
	release.button_mask = 1
	Input.parse_input_event(release)

func laserHover(data):
	# We need to fabricate a fake mouse input even for translating a raycast click to a simulated mouse click on the viewport.
	var event = InputEventMouseMotion.new()
#	event.pressed = data.pressed
#	event.button_index = 1
#	event.button_mask = 1
	var quad_mesh_size = mesh.mesh.size
	var mouse_pos3D = to_local(data.position)
	var mouse_pos2D = Vector2(mouse_pos3D.x, mouse_pos3D.z)
	mouse_pos2D.x += quad_mesh_size.x / 2
	mouse_pos2D.y += quad_mesh_size.y / 2
	mouse_pos2D.x = mouse_pos2D.x / quad_mesh_size.x
	mouse_pos2D.y = mouse_pos2D.y / quad_mesh_size.y
	mouse_pos2D.x = mouse_pos2D.x * viewport.size.x
	mouse_pos2D.y = mouse_pos2D.y * viewport.size.y
	event.position = mouse_pos2D
	event.global_position = mouse_pos2D
	viewport.push_input(event,true)
	var release = InputEventMouseButton.new()
	release.pressed = false
	release.button_index = 1
	release.button_mask = 1
	Input.parse_input_event(release)

#func _input(event):
#	print(event)
#	viewport.push_input(event)

func set_ui(node:Control):
	viewport.add_child(node)
#	node.gui_input.connect(func(event):
#		label_3d.text = str(event)
#		)
