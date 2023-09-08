class_name Vector3_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var xval = $VBoxContainer/position/x/xval
@onready var yval = $VBoxContainer/position/y/yval
@onready var zval = $VBoxContainer/position/z/zval

var target:Node
var _is_editing:bool = false
var property_name:String = ''

var timer := 0.0

func _ready():
	xval.text_changed.connect(func(new_text):
		target[property_name].x = float(new_text)
		)
	yval.text_changed.connect(func(new_text):
		target[property_name].y = float(new_text)
		)
	zval.text_changed.connect(func(new_text):
		target[property_name].z = float(new_text)
		)

func _process(delta):
	timer += delta
	update_fields()

func update_fields():
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		xval.text = str(target.get(property_name).x)
		yval.text = str(target.get(property_name).y)
		zval.text = str(target.get(property_name).z)
	elif !is_instance_valid(target):
		target = null
		xval.text = ''
		yval.text = ''
		zval.text = ''

func _check_focus():
	if xval.has_focus() or yval.has_focus() or zval.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(name:String, new_target:Node, new_property_name:String):
	label.text = name
	target = new_target
	property_name = new_property_name
