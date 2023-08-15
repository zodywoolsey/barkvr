extends Control

@onready var button = $VBoxContainer/HBoxContainer/HBoxContainer/Button
@onready var posx:LineEdit = $VBoxContainer/position/x/LineEdit
@onready var posy:LineEdit = $VBoxContainer/position/y/LineEdit
@onready var posz:LineEdit = $VBoxContainer/position/z/LineEdit
@onready var scax:LineEdit = $VBoxContainer/scale/x/LineEdit
@onready var scay:LineEdit = $VBoxContainer/scale/y/LineEdit
@onready var scaz:LineEdit = $VBoxContainer/scale/z/LineEdit
@onready var rotx:LineEdit = $VBoxContainer/rotation/x/LineEdit
@onready var roty:LineEdit = $VBoxContainer/rotation/y/LineEdit
@onready var rotz:LineEdit = $VBoxContainer/rotation/z/LineEdit
@onready var grabbable:CheckBox = $VBoxContainer/meta/ColorRect/x/CheckBox
@onready var objectname = $VBoxContainer/HBoxContainer/Panel/LineEdit

var is_field_focused = false
var target : Node = null

func _input(event):
	pass

func _process(delta):
	if !is_field_focused:
		update_fields()

func set_target(node):
	if node:
		target = node
		update_fields()

func update_fields():
	if target and is_instance_valid(target):
		objectname.text = target.name
		posx.text = str(target.position.x)
		posy.text = str(target.position.y)
		posz.text = str(target.position.z)
		scax.text = str(target.scale.x)
		scay.text = str(target.scale.y)
		scaz.text = str(target.scale.z)
		rotx.text = str(target.rotation.x)
		roty.text = str(target.rotation.y)
		rotz.text = str(target.rotation.z)
		if target.has_meta('grabbable') and is_instance_valid(target):
			grabbable.button_pressed = target.get_meta('grabbable')
		elif is_instance_valid(target):
			grabbable.button_pressed = false

func clear_fields():
	if target:
		objectname.text = target.name
		posx.text = ''
		posy.text = ''
		posz.text = ''
		scax.text = ''
		scay.text = ''
		scaz.text = ''
		rotx.text = ''
		roty.text = ''
		rotz.text = ''
		grabbable.button_pressed = false

func _ready():
	button.pressed.connect(func():
		if target:
			target.queue_free()
			target = null
			clear_fields()
		)
	posx.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.position.x = float(new_text)
		)
	posx.focus_entered.connect(func():
		is_field_focused = true
		)
	posx.focus_exited.connect(func():
		is_field_focused = false
		)
	posy.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.position.y = float(new_text)
		)
	posy.focus_entered.connect(func():
		is_field_focused = true
		)
	posy.focus_exited.connect(func():
		is_field_focused = false
		)
	posz.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.position.z = float(new_text)
		)
	posz.focus_entered.connect(func():
		is_field_focused = true
		)
	posz.focus_exited.connect(func():
		is_field_focused = false
		)
	scax.text_changed.connect(func(new_text):
		if target:
			if float(new_text):
				target.scale.x = float(new_text)
		)
	scax.focus_entered.connect(func():
		is_field_focused = true
		)
	scax.focus_exited.connect(func():
		is_field_focused = false
		)
	scay.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.scale.y = float(new_text)
		)
	scay.focus_entered.connect(func():
		is_field_focused = true
		)
	scay.focus_exited.connect(func():
		is_field_focused = false
		)
	scaz.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.scale.z = float(new_text)
		)
	scaz.focus_entered.connect(func():
		is_field_focused = true
		)
	scaz.focus_exited.connect(func():
		is_field_focused = false
		)
	rotx.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.rotation.x = float(new_text)
		)
	rotx.focus_entered.connect(func():
		is_field_focused = true
		)
	rotx.focus_exited.connect(func():
		is_field_focused = false
		)
	roty.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.rotation.y = float(new_text)
		)
	roty.focus_entered.connect(func():
		is_field_focused = true
		)
	roty.focus_exited.connect(func():
		is_field_focused = false
		)
	rotz.text_changed.connect(func(new_text:String):
		if target:
			if float(new_text):
				target.rotation.z = float(new_text)
		)
	rotz.focus_entered.connect(func():
		is_field_focused = true
		)
	rotz.focus_exited.connect(func():
		is_field_focused = false
		)
	grabbable.toggled.connect(func(pressed):
		if target:
			target.set_meta('grabbable',pressed)
		)
	grabbable.focus_entered.connect(func():
		is_field_focused = true
		)
	grabbable.focus_exited.connect(func():
		is_field_focused = false
		)
	objectname.text_changed.connect(func(new_text:String):
		if target:
			target.name = new_text
		)
	objectname.focus_entered.connect(func():
		is_field_focused = true
		)
	objectname.focus_exited.connect(func():
		is_field_focused = false
		)
