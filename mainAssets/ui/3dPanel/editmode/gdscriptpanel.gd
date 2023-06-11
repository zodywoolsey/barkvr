extends Control

@onready var code_edit = $CodeEdit

func set_target(item):
	if item is Node:
		var script = item.get_script()
		if script:
			code_edit.text = script.source_code
		else:
			code_edit.text = ""
