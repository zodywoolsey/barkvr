class_name Run_Attribute
extends Control

@onready var val :Button= $VBoxContainer/position/v/val

var target:Object
var _is_editing:bool = false
var calling:Callable
var emission:Signal
var call_on_target:bool = false

func _ready():
	val.pressed.connect(func():
		if is_instance_valid(target):
			if calling:
				calling.call()
			if emission:
				emission.emit()
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	if new_property_name.begins_with("_"):
		queue_free()
		return
	target = new_target
	if target[new_property_name] is Callable:
		if target[new_property_name].get_argument_count() != 0 and target[new_property_name].get_argument_count() != 0:
			queue_free()
			return
		val.text = "run method: " + new_name
		calling = target[new_property_name]
		return
	if target[new_property_name] is Signal:
		val.text = "emit signal: " + new_name
		emission = target[new_property_name]
