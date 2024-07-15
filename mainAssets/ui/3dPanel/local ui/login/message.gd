class_name message_bubble
extends Control

var panel:Panel
var label:RichTextLabel

@export var text = ''

@export var leftside:bool = true:
	set(value):
		leftside = value
		var par := get_parent_control()
		if is_instance_valid(par):
			print('sizing')
			if leftside:
				add_theme_constant_override("margin_right",par.size.x*.3)
				return
			add_theme_constant_override("margin_left",par.size.x*.3)

func _enter_tree():
	leftside = leftside
	label = $Panel/MarginContainer/Label
	if text:
		label.text = text

