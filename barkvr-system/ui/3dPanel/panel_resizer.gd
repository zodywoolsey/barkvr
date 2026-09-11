class_name PanelResizer
extends BaseButton

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

func _input(event: InputEvent) -> void:
	if button_pressed and event is InputEventMouseMotion and get_viewport().get_parent() is Panel3D:
		#get_viewport().size.y = event.position.y as int
		#get_viewport().size.x = event.position.x as int
		if get_viewport().get_parent() is Panel3D:
			get_viewport().get_parent().viewport_size = Vector2i(event.position.x as int, event.position.y as int)
