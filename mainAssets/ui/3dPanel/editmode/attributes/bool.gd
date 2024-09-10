class_name Bool_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :Button= $VBoxContainer/position/v/val

var target:Object
var _is_editing:bool = false:
	get:
		return _check_focus()
var property_name:String = ''

func _ready():
	val.toggled.connect(func(on):
		if is_instance_valid(target):
			if on:
				val.text = "true"
			else:
				val.text = "false"
			target[property_name] = on
		)

func _process(_delta):
	var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
	if scrollparentrect is ScrollContainer:
		var rect = get_global_rect()
		if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
				update_fields()
	else:
		update_fields()

func update_fields():
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		val.button_pressed = (target[property_name])
	elif !is_instance_valid(target):
		target = null
		val.button_pressed = false
		val.text = ''

func _check_focus():
	if val.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
	val.button_pressed = bool(target[property_name])
	if val.button_pressed:
		val.text = "true"
	else:
		val.text = "false"
