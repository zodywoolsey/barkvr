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
		var exp := Expression.new()
		print(exp.get_error_text())
		if exp.parse(new_text) == 0:
			new_text = str(exp.execute())
		target[property_name].x = float(new_text)
		)
	yval.text_changed.connect(func(new_text):
		var exp := Expression.new()
		print(exp.get_error_text())
		if exp.parse(new_text) == 0:
			new_text = str(exp.execute())
		target[property_name].y = float(new_text) # change these fields to use the journal instead of directly setting values so they work correctly
		)

func _process(_delta):
	var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
	var rect = get_global_rect()
	if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
			update_fields()

func update_fields():
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		xval.text = str(target.get(property_name).x)
		yval.text = str(target.get(property_name).y)
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
