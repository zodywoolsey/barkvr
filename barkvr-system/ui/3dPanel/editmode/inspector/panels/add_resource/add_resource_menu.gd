extends Control

var target : Object:
	set(val):
		target = val
var property_name : String
var event_manager : BarkJournal
## Store original parent of this menu to reparent upon panel close.
var original_parent : Node

## Used to track the time since the last item selection.
## item_activated signal in 3DUI issue workaround.
var double_click_timer : SceneTreeTimer
## Used to track the last selected class.
## item_activated signal in 3DUI issue workaround.
var last_selected_class : String

var root_class : StringName

@onready var window_icon: TextureRect = %WindowIcon
@onready var button_close: Button = %ButtonClose

@onready var search_bar: LineEdit = %SearchBar
@onready var button_favorite: Button = %ButtonFavorite

@onready var item_list: ItemList = %ItemList

@onready var list_favorites: ItemList = %ListFavorites
@onready var list_recent: ItemList = %ListRecent

@onready var button_confirm: Button = %ButtonConfirm
@onready var button_cancel: Button = %ButtonCancel

func _ready() -> void:
	event_manager = BarkJournal.current_bark_journal
	print("event supplier: " + str(event_manager))

	original_parent = get_parent()

	_setup_icons()
	_load_class_list()

	# Set up signals.
	button_close.pressed.connect(close)
	button_cancel.pressed.connect(close)
	button_confirm.pressed.connect(add_selected_resource)

	search_bar.text_changed.connect(_on_search_bar_edited)
	search_bar.text_submitted.connect(_on_search_bar_submitted)
	button_favorite.pressed.connect(_on_favorite_button_pressed)

	item_list.item_selected.connect(_on_item_list_item_selected)

	list_favorites.item_selected.connect(_on_sidebar_item_list_item_selected.bind(list_favorites))
	list_recent.item_selected.connect(_on_sidebar_item_list_item_selected.bind(list_recent))

	# item_activated just does not work with 3DUI apparently, real fun.
	# Currently using a custom double click checker using item_selected.
	#item_list.item_activated.connect(_on_item_list_item_activated)

## Set up dynamic icons loaded from project settings.
func _setup_icons() -> void:
	window_icon.set_texture(load(ProjectSettings.get_setting("application/config/icon")))

## Load the initial, unfiltered, class list.
func _load_class_list() -> void:
	for cls : String in ClassDB.get_class_list():
		if not ClassDB.is_parent_class(cls, root_class): continue

		add_class_to_item_list(item_list, cls)

	item_list.select(0)

## Confirm selection and assign it to the correct property
func add_selected_resource() -> void:
	if not is_instance_valid(target): return
	if not is_instance_valid(event_manager): return

	var selected_item_list : PackedInt32Array = item_list.get_selected_items()
	if selected_item_list.is_empty(): return

	var selected_index : int = selected_item_list[0]
	var selected_class : String = item_list.get_item_text(selected_index)

	# TODO: switch to this after the networking refactor is ready
	#event_manager.set_property(event_manager.root.get_path_to(target), property_name, ClassDB.instantiate(root_class))
	var tmp_resource = ClassDB.instantiate(selected_class)
	target[property_name] = tmp_resource

	# Check if class already exists in recent list.
	var is_in_list := false
	for idx : int in list_recent.item_count:
		if list_recent.get_item_text(idx) == selected_class:
			is_in_list = true
			# Move item to top.
			list_recent.move_item(idx, 0)
			break

	# Add to recent list if not present already, then move to top.
	if not is_in_list:
		list_recent.move_item(add_class_to_item_list(list_recent, selected_class), 0)

	close()

## Hide the menu and reset selection to the first list item.
func close() -> void:
	item_list.deselect_all()
	if item_list.item_count > 0: item_list.select(0)

	# Reparent menu if it has been moved upon showing.
	if get_parent() != original_parent:
		reparent(original_parent)

	hide()

## Add an item to the item list with class_string as the type.
func add_class_to_item_list(list : ItemList, class_string : String) -> int:
		return list.add_item(class_string, get_editor_icon(class_string))

## Used to detect double clicks.
func detect_double_click(selected_class : String) -> void:
	if double_click_timer and last_selected_class == selected_class:
		add_selected_resource()
		double_click_timer = null
		return

	# Enable double click timer.
	last_selected_class = selected_class
	double_click_timer = get_tree().create_timer(0.5)
	double_click_timer.timeout.connect(func() -> void: double_click_timer = null)

## Search through the item list.
func _on_search_bar_edited(search_text : String) -> void:
	search_text = search_text.to_lower()

	# Deselect items and clear list.
	item_list.deselect_all()
	item_list.clear()

	var filtered_list := Array()
	var class_list : PackedStringArray = ClassDB.get_class_list()
	class_list.append_array(BarkJournal.extra_classes)

	for class_string : String in class_list:
		if ( # Discard unfit classes.
				not ClassDB.is_parent_class(class_string, root_class)
				and not class_string in BarkJournal.extra_classes
		): continue

		var contains_all_chars := true
		var class_string_lower := class_string.to_lower()
		for character in search_text:
			if !class_string_lower.contains(character):
				contains_all_chars = false
				break
		if (
				contains_all_chars
				or class_string_lower.contains(search_text)
				or class_string_lower.similarity(search_text) > 0.6
		):
			filtered_list.append(class_string)

	# Sort the list to make the "most accurate" result the top item.
	filtered_list.sort_custom(func(a : String, b : String) -> bool:
		return true if search_text.similarity(a.to_lower()) > search_text.similarity(b.to_lower()) else false
	)
	# Populate list with search matches.
	for item : String in filtered_list:
		add_class_to_item_list(item_list, item)

	# Select the first item to prevent no items being selected.
	if item_list.item_count > 0: item_list.select(0)

## Called when enter is pressed while the search bar is focused.
## Function exists due to add_selected_resource not having any args.
func _on_search_bar_submitted(_text : String) -> void:
	add_selected_resource()

## Called when the favorite button is pressed.
func _on_favorite_button_pressed() -> void:
	if not item_list.is_anything_selected(): return

	var selected_index : int = item_list.get_selected_items()[0]
	var selected_class : String = item_list.get_item_text(selected_index)

	# Remove if already a favorite.
	var is_in_list := false
	for idx : int in list_favorites.item_count:
		if list_favorites.get_item_text(idx) == selected_class:
			is_in_list = true
			list_favorites.remove_item(idx)
			break

	# Add if not a favorite yet.
	if not is_in_list:
		add_class_to_item_list(list_favorites, selected_class)

## Called when an item is selected.
func _on_item_list_item_selected(index : int) -> void:
	var selected_class : String = item_list.get_item_text(index)
	detect_double_click(selected_class)

## Called when one of the lists on the sidebar has one of its items selected.
func _on_sidebar_item_list_item_selected(index : int, list : ItemList) -> void:
	match list: # Deselect other list.
		list_recent: list_favorites.deselect_all()
		list_favorites: list_recent.deselect_all()

	var selected_class : String = list.get_item_text(index)

	# Select it in the search bar.
	search_bar.set_text(selected_class)
	_on_search_bar_edited(selected_class)

	# Check for double clicks in the sidebar.
	detect_double_click(selected_class)

## Returns the basic editor icon under the given icon_name.
## Returns the default Node icon instead if no icon exists under that name.
## Duplicate from the InspectorPanel class, maybe this should just be a global function.
func get_editor_icon(icon_name: StringName) -> Texture2D:
	var icon_path: String = "res://barkvr-system/assets/icons/editor-icons/"+icon_name+".svg"
	if ResourceLoader.exists(icon_path, "Texture2D"):
		return ResourceLoader.load(icon_path, "Texture2D")

	return ResourceLoader.load("res://barkvr-system/assets/icons/editor-icons/Node.svg", "Texture2D")
