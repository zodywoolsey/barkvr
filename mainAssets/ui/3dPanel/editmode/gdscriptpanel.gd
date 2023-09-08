extends Control

@onready var code_edit = $CodeEdit
@onready var button = $Button

var target : Node

func _ready():
	button.pressed.connect(func():
		print("valid? ",is_instance_valid(target))
		if target and is_instance_valid(target):
			var tmp = target.get_script()
			if tmp:
				tmp.source_code = code_edit.text
				print("script: ",tmp)
			else:
				tmp = GDScript.new()
				print("script: ",tmp)
				tmp.source_code = code_edit.text
			target.set_script(tmp)
			target.get_script()
		)

func set_target(item):
	if item:
		var script = item.get_script()
		print(typeof(script))
		target = item
		if script:
			code_edit.text = script.source_code
		else:
			code_edit.text = ""
