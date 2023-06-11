extends Node

func _ready():
	get_tree().create_timer(5).timeout.connect(func():
		queue_free()
		)
	
