class_name Number_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var val = $VBoxContainer/position/v/val
@onready var type_label = $VBoxContainer/position/v/Panel2/Label

var target:Node
var _is_editing:bool = false
var property_name:String = ''
var last_val := ""
@export_enum("float","int") var type = 0:
	set(val):
		type = val
		if type_label:
			if val == 0:
				type_label.text = "float"
			else:
				type_label.text = "int"

func _ready():
	if type == 0:
		type_label.text = "float"
	else:
		type_label.text = "int"
	val.text_changed.connect(func(new_text:String):
		if (type == 0 and new_text.is_valid_float()) or (type == 1 and new_text.is_valid_int()):
			last_val = new_text
			if type == 0:
				target[property_name] = float(new_text)
			else:
				target[property_name] = int(new_text)
		else:
			var last_caret_pos :int = val.caret_column-(val.text.length()-last_val.length())
			val.text = last_val
			val.caret_column = last_caret_pos
		)

func _process(_delta):
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		val.text = str(target[property_name])
	elif !is_instance_valid(target):
		target = null
		val.text = ''

func _check_focus():
	if val.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Node, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
