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

## PackedScene of the scene you want to load into the panel (you can also use the "set_viewport_scene(Node)")
@export var _auto_load_ui : PackedScene:
	set(val):
		_auto_load_ui = val
		if _auto_load_ui:
			set_viewport_scene(_auto_load_ui.instantiate())
		else:
			for child in viewport.get_children():
				child.queue_free()

## Sets the panel to transparent (Panel3Ds are automatically opaque on Android and Web)
@export var transparent : bool = true:
	set(val):
		transparent = val
		if transparent:
			viewport.transparent_bg = transparent
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		else:
			viewport.transparent_bg = transparent
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

## Sets the viewport size (panel size is automatically .0005 meters * number of pixels)
@export var viewport_size:Vector2i=Vector2i(1024,1024):
	set(val):
		viewport_size = val
		viewport.size = viewport_size
		mesh.mesh.size.x = .0005*viewport.size.x
		mesh.mesh.size.y = .0005*viewport.size.y
		colshape.shape.size = Vector3(.0005*viewport.size.x,.0005*viewport.size.y,.001)

@export_group('Graphics Settings')
## The shading mode for the canvas
@export_enum("Unshaded:0", "Per Pixel:1", "Per Vertex:2") var shading_mode: int = 0:
	set(val):
		shading_mode = val
		material.shading_mode = shading_mode
		
##
@export var heightmap_enabled:bool=false:
	set(val):
		heightmap_enabled = val
		material.heightmap_enabled = heightmap_enabled
@export var heightmap_deep_parallax:bool=false:
	set(val):
		heightmap_deep_parallax = val
		material.heightmap_deep_parallax = heightmap_deep_parallax
@export_range(1,10000) var heightmap_min_layers:int=8:
	set(val):
		heightmap_min_layers = val
		material.heightmap_min_layers = heightmap_min_layers
@export_range(1,10000) var heightmap_max_layers:int=32:
	set(val):
		heightmap_max_layers = val
		material.heightmap_max_layers = heightmap_max_layers
@export var heightmap_scale:float=5.0:
	set(val):
		heightmap_scale = val
		material.heightmap_scale = heightmap_scale

func _init():
	#viewport_container = SubViewportContainer.new()
	#viewport_container.visibility_layer = 0
	#viewport_container.light_mask = 0
	#viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.gui_embed_subwindows = true
	viewport.own_world_3d = true
	#viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	mesh = MeshInstance3D.new()
	mesh.mesh = QuadMesh.new()
	colshape = CollisionShape3D.new()
	colshape.shape = BoxShape3D.new()
	material = StandardMaterial3D.new()
	mesh.mesh.surface_set_material(0,material)
	#add_child(viewport_container)
	#viewport_container.add_child(viewport,false,Node.INTERNAL_MODE_FRONT)
	add_child(viewport)
	add_child(mesh,false,Node.INTERNAL_MODE_FRONT)
	add_child(colshape,false,Node.INTERNAL_MODE_FRONT)
	material.texture_repeat = false
	material.albedo_texture = viewport.get_texture()
	material.metallic_specular = 0.0
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.heightmap_texture = material.albedo_texture
	if transparent and OS.get_name() != "Android" and OS.get_name() != 'Web':
		viewport.transparent_bg = true
	else:
		viewport.transparent_bg = false
	_auto_load_ui = _auto_load_ui
	transparent = transparent
	viewport_size = viewport_size
	shading_mode = shading_mode
	heightmap_enabled = heightmap_enabled
	heightmap_deep_parallax = heightmap_deep_parallax
	heightmap_min_layers = heightmap_min_layers
	heightmap_max_layers = heightmap_max_layers
	heightmap_scale = heightmap_scale

func _ready():
#grab any non-mouse input from the window and pass it through directly to the
# viewport this is necessary because removing the SubViewportContainer makes
# it so inptus are not automatically passed to the SubViewport
	get_tree().root.window_input.connect(func(event):
		if !(event is InputEventMouse or event is InputEventPanGesture):
			viewport.push_input(event)
		)
	viewport.gui_focus_changed.connect(func(node):
		print('focus')
		LocalGlobals.player_state = LocalGlobals.PLAYER_STATE_TYPING
		)
	LocalGlobals.playerreleaseuifocus.connect(func():
		viewport.gui_release_focus()
		)

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
		_:
			pass
	# Set event pressed value (should be false if not explicitly changed)
	if data.has('pressed') and "pressed" in event:
		event.pressed = data.pressed
	# Get the size of the quad mesh we're rendering to
	var quad_size = mesh.mesh.size
	# Convert GLOBAL collision point from to be in local space of the panel
	var mouse_pos3D = to_local(data.position) # data.position must be global
	var mouse_pos2D = Vector2(mouse_pos3D.x, -mouse_pos3D.y)
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
	#viewport.handle_input_locally = true
	# Push the event to the viewport
	viewport.push_input(event,true)
	#viewport.handle_input_locally = false

func set_viewport_scene(node):
	# Clears the current nodes from within the viewport first
	for child in viewport.get_children():
		child.queue_free()
	# Adds a child node to the viewport and sets it as the UI
	#	Then, gets the texture of the viewport.
	viewport.add_child(node)
	ui = node
	tex = viewport.get_texture()
	# Connects the 'action' signal of the given node to the 'action' signal of this node.
	if node.has_signal('action'):
		node.action.connect(func(data):
			emit_signal('action',data)
		)
	mesh.mesh.surface_get_material(0).albedo_texture = tex

