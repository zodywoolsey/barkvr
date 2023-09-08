class_name vboxScrollChild
extends VBoxContainer

func _process(delta):
	custom_minimum_size = Vector2(0,get_child_count()*200.0)
