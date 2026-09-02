extends MarginContainer

@onready var attributes: Control = %attributes
@onready var close: Button = %close
@onready var color_rect: ColorRect = %ColorRect

var target:Object:
	set(val):
		target = val
		if attributes:
			attributes.call_deferred("set_target",target)
			hide_titlebar = hide_titlebar
			full_height = full_height
			if target:
				rand_color.call_deferred()

var hide_titlebar := false:
	set(val):
		hide_titlebar = val
		if attributes:
			attributes.set_deferred("hide_titlebar", val)

var full_height := false:
	set(val):
		full_height = val
		if attributes:
			attributes.set_deferred("full_height", val)

func _ready() -> void:
	close.pressed.connect(queue_free)

@onready var border_right: ColorRect = %border_right
@onready var border_left: ColorRect = %border_left
@onready var border_top: ColorRect = %border_top
@onready var border_bottom: ColorRect = %border_bottom

func rand_color():
	border_right.color = Color.from_hsv(hash(target.to_string()),1.0,.8,.8)
	border_left.color = border_right.color
	border_top.color = border_right.color
	border_bottom.color = border_right.color
	color_rect.color = Color(border_right.color.r*.2, border_right.color.g*.2, border_right.color.b*.2, .8)
