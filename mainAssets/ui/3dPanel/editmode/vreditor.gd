extends Node3D

@onready var inspector:Panel3D = $inspector
var scene_inspector_scene = load("res://mainAssets/ui/3dPanel/editmode/sceneinspector.tscn")
var scene_inspector
@onready var attributes:Panel3D = $attributes
var attributes_scene = load("res://mainAssets/ui/3dPanel/editmode/attributes.tscn")
var attributes_ui
@onready var gdscript:Panel3D = $script
var gdscript_scene = load("res://mainAssets/ui/3dPanel/editmode/gdscriptpanel.tscn")
var gdscript_ui

func _ready():
	scene_inspector = scene_inspector_scene.instantiate()
	inspector.set_viewport_scene(scene_inspector)
	attributes_ui = attributes_scene.instantiate()
	attributes.set_viewport_scene(attributes_ui)
	gdscript_ui = gdscript_scene.instantiate()
	gdscript.set_viewport_scene(gdscript_ui)
	scene_inspector.selected.connect(func(item):
		if is_instance_valid(item):
			if attributes_ui and item:
				attributes_ui.set_target(item)
			if gdscript_ui and item:
				gdscript_ui.set_target(item)
			)
	
	LocalGlobals.editor_refs['inspector'] = scene_inspector
	LocalGlobals.editor_refs['attributespanel'] = attributes
	LocalGlobals.editor_refs['attributesui'] = attributes_ui
	LocalGlobals.editor_refs['vreditor'] = self
	LocalGlobals.editor_refs['mainpanel'] = inspector

func set_items(items):
	scene_inspector.setItems(items)
