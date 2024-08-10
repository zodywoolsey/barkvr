extends Control

@onready var world_name = $HBoxContainer/VBoxContainer/name
@onready var save = $HBoxContainer/VBoxContainer/save
@onready var load = $HBoxContainer/VBoxContainer/load
@onready var item_list = $HBoxContainer/ItemList

func _ready():
	init_world_list()
	item_list.item_clicked.connect(func(i, pos, button_mask):
		print(item_list.get_item_text(i))
		world_name.text = item_list.get_item_text(i)
		)
	save.pressed.connect(func():
		var world = get_tree().get_first_node_in_group("localworldroot")
		
		if world and !world_name.text.is_empty():
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
#				discord_sdk.details = "in world "+world_name.text
		)


func init_world_list():
	item_list.clear()
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("./worlds"):
		dir.make_dir("./worlds")
	dir.change_dir("./worlds")
	for world in dir.get_files():
		item_list.add_item(world)
