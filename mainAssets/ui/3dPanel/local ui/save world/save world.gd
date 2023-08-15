extends Control

@onready var world_name = $VBoxContainer/name
@onready var save = $VBoxContainer/save
@onready var load = $VBoxContainer/load

func _ready():
	save.pressed.connect(func():
		var world = get_tree().get_first_node_in_group("localworldroot")
		if world:
			var dir = DirAccess.open("user://")
			if !dir.dir_exists("./worlds"):
				dir.make_dir("./worlds")
			var world_file = FileAccess.open("user://worlds/"+world_name.text, FileAccess.WRITE)
			world_file.store_string(str(BarkHelpers.node_to_var(world)))
#			OS.shell_open(OS.get_user_data_dir())
		)
	load.pressed.connect(func():
		var world_file = FileAccess.open("user://worlds/"+world_name.text, FileAccess.READ_WRITE)
		if world_file:
			var tmp = world_file.get_as_text()
			var loaded_world = BarkHelpers.var_to_node(tmp)
			var localworld = get_tree().get_first_node_in_group("localworldroot")
			if localworld:
				print(str(localworld),"replaced by",str(loaded_world))
				var parent = get_tree().get_first_node_in_group('localroot')
				localworld.queue_free()
				parent.add_child(loaded_world)
		)
