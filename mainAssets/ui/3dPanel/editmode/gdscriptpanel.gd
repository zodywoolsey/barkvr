extends Control

@onready var code_edit = $CodeEdit
@onready var button = $Button

var target : Node

func _ready():
	code_edit.text_changed.connect(func():
		print("valid? ",is_instance_valid(target))
		if target and is_instance_valid(target):
			var tmp :GDScript = GDScript.new()
			print("script: ",tmp)
			tmp.source_code = code_edit.text
			var result = tmp.reload()
			#var clas = tmp.get_class()
			if result == OK:
				target.set_script(tmp)
				target.set_process(true)
				target.set_physics_process(true)
		)

func set_target(item):
	if item:
		var script = item.get_script()
		print(typeof(script))
		target = item
		if script and !script.source_code.is_empty():
			code_edit.text = script.source_code
		else:
			code_edit.text = "extends "+str(target.get_class())+"\n\nfunc _init():\n	pass\n\nfunc _process(delta:float):\n	pass"
