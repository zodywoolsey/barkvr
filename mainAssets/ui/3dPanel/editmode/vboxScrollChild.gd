class_name vboxScrollChild
extends VBoxContainer

@export var min_item_height:float = 200.0

var current_height = 0
func _process(delta):
	var height = 0
	for child in get_children():
		height += child.size.y
	size.y = height
