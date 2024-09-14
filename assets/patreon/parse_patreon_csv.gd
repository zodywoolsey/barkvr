extends FlowContainer

var members :String = "paste names
with newlines
in between"

var MEMBERBOX = load("res://assets/patreon/memberbox.tscn")

func _ready() -> void:
	visibility_changed.connect(func():
		for child in get_children():
			child.queue_free()
		var shuffled_members = Array(members.split("\n"))
		shuffled_members.shuffle()
		for member in shuffled_members:
			var lbl = MEMBERBOX.instantiate()
			add_child(lbl)
			lbl.text = member
		)
