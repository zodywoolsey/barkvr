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
			print('started loading')
#			Journaling.net_propogate_node(tmp)
			ResourceLoader.load_threaded_request('user://objects/'+object_name.text,'',true)
			get_tree().create_timer(1).timeout.connect(_check_loaded.bind('user://objects/'+object_name.text))
#			var loaded_object = BarkHelpers.var_to_node(tmp)
#			var localworld = get_tree().get_first_node_in_group("localworldroot")
#			if localworld:
#				print("loaded object: ",str(loaded_object))
#				var parent = get_tree().get_first_node_in_group('localworldroot')
#				if parent:
#					parent.add_child(loaded_object)
		)

func _check_loaded(path:String):
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		print('not loaded yet')
		get_tree().create_timer(1).timeout.connect(_check_loaded.bind(path))
	else:
		var err = ResourceLoader.load_threaded_get(path)
		get_tree().get_first_node_in_group('localworldroot').add_child(err.instantiate())

func init_object_list():
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("./objects"):
		dir.make_dir("./objects")
	dir.change_dir("./objects")
	var files = dir.get_files()
	for i in item_list.item_count:
		files.remove_at(files.find(item_list.get_item_text(i)))
	for world in files:
		item_list.add_item(world)
	get_tree().create_timer(1).timeout.connect(func():
		init_object_list()
		)
