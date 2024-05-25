class_name Vector2_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var xval = $VBoxContainer/position/x/xval
@onready var yval = $VBoxContainer/position/y/yval

var target:Node
var _is_editing:bool = false
var property_name:String = ''


func _ready():
	xval.text_changed.connect(func(new_text):
		target[property_name].x = float(new_text)
		)
	yval.text_changed.connect(func(new_text):
		target[property_name].y = float(new_text)
		)

func _process(_delta):
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		xval.text = str(target[property_name].x)
		yval.text = str(target[property_name].y)
	elif !is_instance_valid(target):
		target = null
		xval.text = ''
		yval.text = ''

func _check_focus():
	if xval.has_focus() or yval.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Node, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
