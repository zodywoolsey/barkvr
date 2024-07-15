extends Button

@export var node_to_toggle : Node

func _toggled(toggled_on):
	if is_instance_valid(node_to_toggle):
		node_to_toggle.visible = toggled_on
