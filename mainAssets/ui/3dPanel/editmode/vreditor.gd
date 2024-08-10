extends Node

@onready var inspector:Panel3D = $".."
var scene_inspector
@onready var attributes:Panel3D = $"../attributes"
var attributes_ui
@onready var gdscript:Panel3D = $"../script"
var gdscript_ui
@onready var addnode = $"../addnode"
var addnode_ui

func _ready():
	scene_inspector = inspector.ui
	attributes_ui = attributes.ui
	gdscript_ui = gdscript.ui
	addnode_ui = addnode.ui
	scene_inspector.selected.connect(func(item):
		if is_instance_valid(item):
			if attributes_ui and item:
				attributes_ui.set_target(item)
			if gdscript_ui and item:
				gdscript_ui.set_target(item)
			if addnode_ui and item:
				addnode_ui.set_target(item)
			)
	
	LocalGlobals.editor_refs['inspector'] = scene_inspector
	LocalGlobals.editor_refs['attributespanel'] = attributes
	LocalGlobals.editor_refs['attributesui'] = attributes_ui
	LocalGlobals.editor_refs['vreditor'] = self
	LocalGlobals.editor_refs['mainpanel'] = inspector

func set_items(items):
	scene_inspector.setItems(items)
