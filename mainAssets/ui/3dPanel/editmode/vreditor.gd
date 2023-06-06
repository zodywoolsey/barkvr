extends Node3D

@onready var inspector = $inspector
var scene_inspector_scene = load("res://mainAssets/ui/3dPanel/editmode/sceneinspector.tscn")
var scene_inspector
@onready var attributes = $inspector/attributes
var attributes_scene = load("res://mainAssets/ui/3dPanel/editmode/attributes.tscn")
var attributes_ui
func _ready():
	scene_inspector = scene_inspector_scene.instantiate()
	scene_inspector.selected.connect(func(item):
		print("selected: ",item)
		if attributes_ui and item is Node3D:
			attributes_ui.set_target(item)
		)
	inspector.set_ui(scene_inspector)
	attributes_ui = attributes_scene.instantiate()
	attributes.set_ui(attributes_ui)
	LocalGlobals.editor_refs['inspector'] = scene_inspector
	LocalGlobals.editor_refs['attributespanel'] = attributes
	LocalGlobals.editor_refs['attributesui'] = attributes_ui
	LocalGlobals.editor_refs['vreditor'] = self
	LocalGlobals.editor_refs['mainpanel'] = inspector

func set_items(items):
	scene_inspector.setItems(items)
