extends Control

@onready var button = $Button
@onready var window_properties = $TabContainer/window_properties
@onready var resize = $resize

var big_height := 800
var big_width := 800
var small_height := 40
var expanded := true

var resizing := false
var resize_start_position := Vector2()

func _ready():
	window_properties.set_target(get_window())
	if get_viewport().get_parent() is Panel3D:
		get_viewport().get_parent().minimum_viewport_size = Vector2i(small_height,small_height)
	button.pressed.connect(func():
		expanded = !expanded
		resize.visible = expanded
		create_tween().tween_property(get_viewport().get_parent(),"viewport_size:y",big_height if expanded else small_height,.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		create_tween().tween_property(get_viewport().get_parent(),"viewport_size:x",big_width if expanded else small_height,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		)

func _input(event:InputEvent):
	if resize.button_pressed and event is InputEventMouseMotion:
		get_viewport().get_parent().viewport_size = event.position
		big_height = event.position.y
		big_width = event.position.x
