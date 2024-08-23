class_name String_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var val = $VBoxContainer/position/v/val
@onready var type_label = $VBoxContainer/position/v/Panel2/Label

var target:Node
var _is_editing:bool = false
var property_name:String = ''

func _ready():
	val.text_changed.connect(func(new_text:String):
		target[property_name] = new_text
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
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target):
		val.text = str(target[property_name])
	elif !is_instance_valid(target):
		target = null
		val.text = ''

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Node, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
