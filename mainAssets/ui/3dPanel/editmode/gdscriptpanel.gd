extends Control

@onready var code_edit = $CodeEdit
@onready var button = $Button

var citem : Node

func _ready():
	button.pressed.connect(func():
		if citem:
			var tmp = citem.get_script()
			tmp.source_code = code_edit.text
			citem.set_script(tmp)
		)

func set_target(item):
	if item is Node:
		var script = item.get_script()
		if script:
			code_edit.text = script.source_code
			citem = item
		else:
			code_edit.text = ""
			citem = null
