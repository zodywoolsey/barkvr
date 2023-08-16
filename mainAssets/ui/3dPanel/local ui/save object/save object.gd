extends Control

@onready var object_name = $HBoxContainer/VBoxContainer/name
@onready var load = $HBoxContainer/VBoxContainer/load
@onready var item_list = $HBoxContainer/ItemList

func _ready():
	init_object_list()
	item_list.item_clicked.connect(func(i, pos, button_mask):
		print(item_list.get_item_text(i))
		object_name.text = item_list.get_item_text(i)
		)
	load.pressed.connect(func():
		var object_file = FileAccess.open("user://objects/"+object_name.text, FileAccess.READ_WRITE)
		if object_file:
			var tmp = object_file.get_as_text()
			var loaded_object = BarkHelpers.var_to_node(tmp)
			var localworld = get_tree().get_first_node_in_group("localworldroot")
			if localworld:
				print("loaded object: ",str(loaded_object))
				var parent = get_tree().get_first_node_in_group('localworldroot')
				if parent:
					parent.add_child(loaded_object)
		)


func init_object_list():
	item_list.clear()
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("./objects"):
		dir.make_dir("./objects")
	dir.change_dir("./objects")
	for world in dir.get_files():
		item_list.add_item(world)
