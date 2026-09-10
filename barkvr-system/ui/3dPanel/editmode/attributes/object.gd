class_name Object_Attribute
extends Control

@onready var label: Label = %Label
@onready var expand: Button = %expand
var ATTRIBUTES_SCENE = load("res://barkvr-system/ui/3dPanel/editmode/attributes.tscn")
var ATTRIBUTES_POPUP_SCENE = load("res://barkvr-system/ui/3dPanel/editmode/popup/attributes_popup.tscn")
var CREATE_RESOURCE_POPUP_SCENE = load("res://barkvr-system/ui/3dPanel/editmode/inspector/panels/add_resource/add_resource_menu.tscn")
var attributes: Control
@onready var create: Button = %create
@onready var copy: Button = %copy
@onready var paste: Button = %paste

var target_type : StringName

@export var full_height := false

var popup : Control

var target:Object:
	set(val):
		target = val
var property_name:String = '':
	set(val):
		property_name = val

func _ready() -> void:
	create.pressed.connect(create_pressed)
	copy.pressed.connect(copy_pressed)
	paste.pressed.connect(paste_pressed)
	get_child(0).resized.connect(on_first_child_resized)
	expand.toggled.connect(func(on:bool):
		if on:
			if full_height:
				custom_minimum_size.y = get_child(0).size.y
				return
			custom_minimum_size.y = 1000
		else:
			custom_minimum_size.y = 100
		)
	expand.pressed.connect(func():
		var tmp : Control = ATTRIBUTES_POPUP_SCENE.instantiate()
		tmp.hide_titlebar = true
		#tmp.full_height = full_height
		tmp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		get_parent().get_parent().get_parent().get_parent().add_child(tmp)
		tmp.set_deferred("target", target[property_name])
		print('opened single object inspector: ',target, " -> ", property_name)
		)

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String, target_class_name:StringName, above_targets=[]):
	if new_property_name in new_target:
		above_targets.append(new_target)
		target_type = target_class_name
		label.text = new_name+" : "+target_type
		target = new_target
		property_name = new_property_name

func show_attributes_modal() -> void:
		attributes = ATTRIBUTES_SCENE.instantiate()
		attributes.hide_titlebar = true
		attributes.full_height = full_height
		attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attributes.call_deferred("set_target",target[property_name])

func create_pressed() -> void:
		if !popup:
			popup = CREATE_RESOURCE_POPUP_SCENE.instantiate()
		popup.target = target
		popup.property_name = property_name
		popup.root_class = target_type
		popup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		popup.top_level = true
		if !popup.is_inside_tree():
			add_child(popup)
		#popup.set_deferred("target", target[property_name])
		popup.show()
		

func copy_pressed() -> void:
		if target[property_name]:
			DisplayServer.clipboard_set(str(target[property_name].get_instance_id()))
		
func paste_pressed() -> void:
		var pasted := DisplayServer.clipboard_get()
		if !pasted.is_empty() and pasted.is_valid_int():
			var derived = instance_from_id(pasted.to_int())
			if is_instance_valid(derived) and typeof(derived) == typeof(target[property_name]):
				target[property_name] = derived
				print('pasted')
		

func on_first_child_resized() -> void:
		if full_height and expand.button_pressed:
			custom_minimum_size.y = get_child(0).size.y
		
