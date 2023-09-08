extends vboxScrollChild

var timer = 0.0

var thread : Thread = Thread.new()

#func _process(delta):
#	timer += delta
#	for child in get_children():
#		if is_instance_valid(child) and child.has_method('update_fields'):
#			child.update_fields()
#			await get_tree().process_frame

