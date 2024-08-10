class_name Run_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :Button= $VBoxContainer/position/v/val

var target:Node
var _is_editing:bool = false
var action:Callable
var call_on_target:bool = false

func _ready():
	val.pressed.connect(func():
		if is_instance_valid(target) and action:
			action.call()
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Node, new_property_name:String):
	label.text = new_name
	target = new_target
	if val.button_pressed:
		val.text = "true"
	else:
		val.text = "false"
