extends Control

@onready var grid_container = $GridContainer
signal action(data:Dictionary)
var btn = preload("res://mainAssets/ui/3dPanel/2d scenes/local ui selector/button.tscn")
func _ready():
	_check_for_local_ui()

func _check_for_local_ui():
	if LocalGlobals.local_uis.size() != grid_container.get_child_count():
#		for child in grid_container.get_children():
#			child.queue_free()
		for ui in LocalGlobals.local_uis:
			var tmp = btn.instantiate()
			tmp.set_meta('viewport_texture', ui.viewport_texture)
			tmp.text = ui.name
			tmp.pressed.connect(func():
				emit_signal("action",{
					'button':tmp
				})
				)
			grid_container.add_child(tmp)
	get_tree().create_timer(1).timeout.connect(func():
		_check_for_local_ui()
		)
