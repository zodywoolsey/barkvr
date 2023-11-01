@tool
@icon("res://addons/Panel3D/icon.svg")
class_name Panel3D
extends StaticBody3D
var viewport : SubViewport
var viewport_container : SubViewportContainer
var mesh : MeshInstance3D
var colshape : CollisionShape3D
var material : StandardMaterial3D

var ui : Node
var tex:ViewportTexture

# Plugin stuff
var prev_vals : Dictionary

## PackedScene of the scene you want to load into the panel (you can also use the "set_viewport_scene(Node)")
@export var _auto_load_ui : PackedScene
## Sets the panel to transparent (Panel3Ds are automatically opaque on Android and Web)
@export var transparent : bool = true
## Sets the viewport size (panel size is automatically .0005 meters * number of pixels)
@export var viewport_size:Vector2i=Vector2i(1024,1024)

@export_group('Graphics Settings')
## The shading mode for the canvas
@export_enum("Unshaded:0", "Per Pixel:1", "Per Vertex:2") var shading_mode: int = 0
##
@export var heightmap_enabled:bool=false
@export var heightmap_deep_parallax:bool=false
@export_range(1,10000) var heightmap_min_layers:int=8
@export_range(1,10000) var heightmap_max_layers:int=32
@export var heightmap_scale:float=5.0

func _init():
	viewport_container = SubViewportContainer.new()
	viewport_container.visibility_layer = 0
	viewport_container.light_mask = 0
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	mesh = MeshInstance3D.new()
	mesh.mesh = PlaneMesh.new()
	colshape = CollisionShape3D.new()
	colshape.shape = BoxShape3D.new()
	material = StandardMaterial3D.new()
	mesh.mesh.surface_set_material(0,material)

func _ready():
	if Engine.is_editor_hint():
		# sets watch values for keeping track of changes
		prev_vals = {}
		prev_vals['_auto_load_ui'] = _auto_load_ui
		prev_vals['transparent'] = transparent
		prev_vals['viewport_size'] = viewport_size
		prev_vals['shading_mode'] = shading_mode
		prev_vals['heightmap_enabled'] = heightmap_enabled
		prev_vals['heightmap_deep_parallax'] = heightmap_deep_parallax
		prev_vals['heightmap_max_layers'] = heightmap_max_layers
		prev_vals['heightmap_scale'] = heightmap_scale
		prev_vals['heightmap_min_layers'] = heightmap_min_layers
	add_child(viewport_container)
	viewport_container.add_child(viewport,false,Node.INTERNAL_MODE_FRONT)
	add_child(mesh,false,Node.INTERNAL_MODE_FRONT)
	add_child(colshape,false,Node.INTERNAL_MODE_FRONT)
	material.texture_repeat = false
	material.albedo_texture = viewport.get_texture()
	material.metallic_specular = 0.0
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = shading_mode
	material.heightmap_enabled = heightmap_enabled
	material.heightmap_deep_parallax = heightmap_deep_parallax
	material.heightmap_min_layers = heightmap_min_layers
	material.heightmap_max_layers = heightmap_max_layers
	material.heightmap_texture = material.albedo_texture
	material.heightmap_scale = heightmap_scale
	if transparent:
		viewport.transparent_bg = transparent
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		viewport.transparent_bg = transparent
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	if viewport_size:
		set_viewport_size(viewport_size)
	if transparent and OS.get_name() != "Android" and OS.get_name() != 'Web':
		viewport.transparent_bg = true
	else:
		viewport.transparent_bg = false
#	viewport.gui_focus_changed.connect(func(node):
#		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_TYPING
#		)
#	LocalGlobals.playerreleaseuifocus.connect(func():
#		viewport.gui_release_focus()
#		)
#	colShape.position.y = -colShape.shape.size.y/2.0
	if _auto_load_ui:
		set_viewport_scene(_auto_load_ui.instantiate())

func _process(delta):
	plugin_stuff()
	mesh.mesh.size.x = .0005*viewport.size.x
	mesh.mesh.size.y = .0005*viewport.size.y
	colshape.shape.size = Vector3(mesh.mesh.size.x,.001,mesh.mesh.size.y)

func laser_input(data:Dictionary):
	var event
	# Setup event
	match data.action:
		"hover":
			event = InputEventMouseMotion.new()
		"scrollup":
			event = InputEventMouseButton.new()
			event.button_index = 4
		"scrolldown":
			event = InputEventMouseButton.new()
			event.button_index = 5
		"click":
			event = InputEventMouseButton.new()
			event.button_index = 1
		"custom":
			# Use this to pass a different event type or add event strings below
			event = data.event
	# Set event pressed value (should be false if not explicitly changed)
	if data.pressed and 'pressed' in event:
		event.pressed = data.pressed
	# Get the size of the quad mesh we're rendering to
	var quad_size = mesh.mesh.size
	# Convert GLOBAL collision point from to be in local space of the panel
	var mouse_pos3D = to_local(data.position) # data.position must be global
	var mouse_pos2D = Vector2(mouse_pos3D.x, mouse_pos3D.z)
	# Translate the 2D mouse position to the center of the quad
	#	by adding half of the quad size to both x and y coordinates.
	mouse_pos2D.x += quad_size.x / 2
	mouse_pos2D.y += quad_size.y / 2
	# Normalize the mouse position to be within the quad size
	mouse_pos2D.x = mouse_pos2D.x / quad_size.x
	mouse_pos2D.y = mouse_pos2D.y / quad_size.y
	# Convert the 2D mouse position to viewport coordinates
	mouse_pos2D.x = mouse_pos2D.x * viewport.size.x
	mouse_pos2D.y = mouse_pos2D.y * viewport.size.y
	# Sets the position of the event to the calculated mouse position in 2D space.
	event.position = mouse_pos2D
	# Set the event to be handled locally (workaround for Godot 4.x bug)
	#	The bug causes the viewport to not consistently receive input events
	viewport.handle_input_locally = true
	# Push the event to the viewport
	viewport.call_thread_safe("push_input",event,true)
	viewport.handle_input_locally = false

func set_viewport_scene(node):
	# Clears the current nodes from within the viewport first
	for child in viewport.get_children():
		child.queue_free()
	# Adds a child node to the viewport and sets it as the UI
	#	Then, gets the texture of the viewport.
	viewport.add_child(node)
	ui = node
	tex = viewport.get_texture()
	mesh.mesh.surface_get_material(0).albedo_texture = tex

func set_viewport_size(size:Vector2i):
	viewport.size = size

# this just tracks updated parameters so the engine view updates in realtime
func plugin_stuff():
	if Engine.is_editor_hint():
		if _auto_load_ui != prev_vals._auto_load_ui:
			prev_vals._auto_load_ui = _auto_load_ui
			if _auto_load_ui:
				set_viewport_scene(_auto_load_ui.instantiate())
			else:
				for child in viewport.get_children():
					child.queue_free()
		if transparent != prev_vals.transparent:
			prev_vals.transparent = transparent
			if transparent:
				viewport.transparent_bg = transparent
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			else:
				viewport.transparent_bg = transparent
				material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		if viewport_size != prev_vals.viewport_size:
			prev_vals.viewport_size = viewport_size
			viewport.size = viewport_size
		if shading_mode != prev_vals.shading_mode:
			prev_vals.shading_mode = shading_mode
			material.shading_mode = shading_mode
		if heightmap_enabled != prev_vals.heightmap_enabled:
			prev_vals.heightmap_enabled = heightmap_enabled
			material.heightmap_enabled = heightmap_enabled
		if heightmap_deep_parallax != prev_vals.heightmap_deep_parallax:
			prev_vals.heightmap_deep_parallax = heightmap_deep_parallax
			material.heightmap_deep_parallax = heightmap_deep_parallax
		if heightmap_min_layers != prev_vals.heightmap_min_layers:
			prev_vals.heightmap_min_layers = heightmap_min_layers
			material.heightmap_min_layers = heightmap_min_layers
		if heightmap_max_layers != prev_vals.heightmap_max_layers:
			prev_vals.heightmap_max_layers = heightmap_max_layers
			material.heightmap_max_layers = heightmap_max_layers
		if heightmap_scale != prev_vals.heightmap_scale:
			prev_vals.heightmap_scale = heightmap_scale
			material.heightmap_scale = heightmap_scale
