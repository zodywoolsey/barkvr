extends Control

@onready var object_name: LineEdit = \
	$HBoxContainer/VBoxContainer/name

@onready var load: Button = \
	$HBoxContainer/VBoxContainer/load

@onready var item_list: ItemList = \
	$HBoxContainer/ItemList

func _ready() -> void:
	init_object_list()
	item_list.item_clicked.connect(_item_selected)
	load.pressed.connect(_load_requested)

func _unhandled_input(event: InputEvent) -> void:
	# If escape key pressed, remove focus from text input.
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		object_name.release_focus()

func _item_selected(i: int, _pos: Vector2, _button_mask: int) -> void:
	var text := item_list.get_item_text(i)
	print(text)
	object_name.text = text

func _load_requested() -> void:
	var object_path := "user://objects/" + object_name.text
	var object_file := FileAccess.open(object_path, FileAccess.READ_WRITE)
	if object_file:
		# Get file extension.
		var extension := ""
		if object_path.contains("."):
			extension = object_path.rsplit(".", true, 1)[1]
		match extension:
			"res", "tres", "scn", "tscn":
				print("Loading scene.")
				Journaling.import_asset("res", object_path)
			"glb", "gltf":
				Journaling.import_asset("glb", object_path)
			"jpg", "jpeg", "png", "bmp", "tga", "webp":
				Journaling.import_asset("image", object_path)
			"bark":
				print("Loading var.")
				var tmp = object_file.get_var(true)
				print('got var:\n' + tmp)
				get_tree().get_first_node_in_group('localworldroot').add_child(BarkHelpers.var_to_node(tmp))

## Repeatedly refresh object list with objects in user folder.
func init_object_list() -> void:
	var dir := DirAccess.open("user://")
	dir.make_dir("./objects")
	dir.change_dir("./objects")
	var files := dir.get_files()
	for i in item_list.item_count:
		files.remove_at(files.find(item_list.get_item_text(i)))
	for world in files:
		item_list.add_item(world)
	get_tree().create_timer(1).timeout.connect(init_object_list)
