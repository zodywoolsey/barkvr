class_name Object_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var expand: Button = $VBoxContainer/Panel2/expand
var ATTRIBUTES_SCENE = load("res://mainAssets/ui/3dPanel/editmode/attributes.tscn")
@onready var field_parent: HBoxContainer = $VBoxContainer/MarginContainer/object
@onready var color_rect: ColorRect = $VBoxContainer/MarginContainer/ColorRect
@onready var margin_container: MarginContainer = $VBoxContainer/MarginContainer

var target:Object
var _is_editing:bool = false
var property_name:String = '':
	set(val):
		property_name = val
		var col := Color.from_hsv(
			fmod(hash(property_name)/1000.0,1.0),
			clamp(fmod(hash(property_name)/1000.0,1.0), .6, .9),
			clamp(fmod(hash(property_name)/1000.0,1.0), .6, .9),
			1.0
			)
		#color_rect.color = col
		col.v = .8
		margin_container.modulate = col
		print(property_name + " " + str( fmod(hash(property_name)/1000.0,1.0) ) + "\n" + str(hash(property_name)))

func _ready() -> void:
	expand.toggled.connect(func(on:bool):
		if on:
			custom_minimum_size.y = 1000
		else:
			custom_minimum_size.y = 100
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
	var attributes_target = target[property_name]
	var attributes:Control = ATTRIBUTES_SCENE.instantiate()
	attributes.hide_titlebar = true
	attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_parent.add_child(attributes)
	attributes.call_deferred("set_target",target[property_name])
