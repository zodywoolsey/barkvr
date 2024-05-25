class_name Enum_Attribute
extends Control

@onready var label :Label= $VBoxContainer/Panel2/Label
@onready var val :OptionButton= $VBoxContainer/position/v/val

var target:Node
var _is_editing:bool = false
var property_name:String = ''

func _ready():
	val.get_popup().hide_on_item_selection=false
	val.get_popup().hide_on_checkable_item_selection=false
	val.get_popup().hide_on_state_item_selection=false
	val.item_selected.connect(func(index):
		if is_instance_valid(target):
			target[property_name] = index
		)

func _process(_delta):
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
func set_data(new_name:String, new_target:Node, new_property_name:String, prop_data:Dictionary):
	label.text = new_name
	property_name = new_property_name
	val.selected = bool(new_target[property_name])
	var options :Array = prop_data.hint_string.split(',')
	for i in options.size():
		val.add_item(options[i], i)
	target = new_target
	name = new_name
