class_name Object_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var expand: Button = $VBoxContainer/Panel2/expand
var ATTRIBUTES_SCENE = load("res://mainAssets/ui/3dPanel/editmode/attributes.tscn")
@onready var field_parent: HBoxContainer = $VBoxContainer/object

var target:Object
var _is_editing:bool = false
var property_name:String = ''

func _ready() -> void:
	expand.toggled.connect(func(on:bool):
		if on:
			custom_minimum_size.y = 1000
		else:
			custom_minimum_size.y = 200
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
	var attributes_target = target[property_name]
	var attributes:Control = ATTRIBUTES_SCENE.instantiate()
	attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_parent.add_child(attributes)
	attributes.call_deferred("set_target",target[property_name])
