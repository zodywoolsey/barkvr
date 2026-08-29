extends Control

## holds a ref to the vbox container that will hold all the fields
@onready var v_box_container: VBoxContainer = %properties_vbox

## hold ref to the searchbar linedit in the scene
@onready var search_bar: LineEdit = %SearchBar

## here, we load each of the field scenes we will be using.
## we use load instead of preload so that the user can live-mod the game if they so desire

## vector3 barkvr field editor
var vector_3_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/vector3.tscn")
## vector_2_field barkvr field editor
var vector_2_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/vector2.tscn")
## number_field barkvr field editor
var number_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/number.tscn")
## bool_field barkvr field editor
var bool_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/bool.tscn")
## enum_field barkvr field editor
var enum_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/enum.tscn")
## string_field barkvr field editor
var string_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/string.tscn")
## object_field barkvr field editor
var object_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/object.tscn")
## color_field barkvr field editor
var color_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/color.tscn")
## array_field barkvr field editor
var array_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/array.tscn")
## this executes a method on the target
var run_field = load("res://barkvr-system/ui/3dPanel/editmode/attributes/run.tscn")
## tracks the current target object we are viewing/editing
var target : Object = null

# the titlebar is the part that shows and edits the name of the target
# we need refs to this because it is hidden while editing a sub-resource
# since the target name doesn't need to be duplicated on every nested menu

## the container of the titlebar, used when the 
@onready var titlebar_top_row: HBoxContainer = $VBoxContainer/titlebar/HBoxContainer
## holds a ref to the root of the active toggle button so we can hide this part when
## it's not relevant to whatever is selected rn
@onready var titlebar_active: ColorRect = $"VBoxContainer/titlebar/properties header/active"
## holds ref to the toggle button that sets whether the target is enabled
@onready var activetoggle: CheckButton = $"VBoxContainer/titlebar/properties header/active/HBoxContainer/activetoggle"
## holds ref to the linedit that displays and edits the target name
@onready var targetname: LineEdit = $VBoxContainer/titlebar/HBoxContainer/Panel/targetname
## holds a ref to the header label at the top of the attributes panel
@onready var properties_header_label: Label = $"VBoxContainer/titlebar/properties header/Panel9/properties header label"
## toggles whether properties should be loaded in this editor
@export var load_properties : bool = true
## toggles whether methods should be loaded in this editor
@export var load_methods : bool = false
## toggles whether signals should be loaded in this editor
@export var load_signals : bool = false


## sets whether the titlebar should be hidden or not and shows/hides the necessary
## nodes using the setter
var hide_titlebar := false:
	set(val):
		hide_titlebar = val
		# hide the top row since it only views/edits the target Object.name and isn't relevant
		# when viewing a subresource
		if is_instance_valid(titlebar_top_row):
			titlebar_top_row.visible = !hide_titlebar
		# same but for the active toggle
		if is_instance_valid(titlebar_active):
			titlebar_active.visible = !hide_titlebar

## holder to keep track of the event_manager instance so we don't have to keep asking the 
## engine for it
var event_manager : BarkJournal

## updates the current target of this attributes panel
func set_target(new_target:Object):
	if is_instance_valid(target):
		target.property_list_changed.disconnect(target_property_list_changed)
	
	print_debug("setting target in: ",self, "to look at: ",new_target)
	# check that the new_target is valid
	if is_instance_valid(new_target) and new_target is Object:
		new_target.property_list_changed.connect(target_property_list_changed)
		# update the holder variable so the target is available across the script
		target = new_target
		# if the target has a name, then set the ui to reflect it
		if "name" in new_target and new_target.name:
			targetname.text = new_target.name
		# if the target has our custom display_name metadata, display that instead
		if new_target.has_meta("display_name"):
			targetname.text = new_target.get_meta("display_name")
		# if the target supports visibility, update the field accordingly
		if "visible" in new_target and new_target.visible != null:
			activetoggle.disabled = false
			activetoggle.button_pressed = new_target.visible
		# if it doesn't, just hide the field
		else:
			activetoggle.button_pressed = true
			activetoggle.disabled = true
		# set the header to reflect the class of the target
		properties_header_label.text = new_target.get_class()
		if load_methods:
			properties_header_label.text += " Methods," if load_properties or load_signals else " Methods"
		if load_signals:
			properties_header_label.text += " Signals," if load_properties else " Signals"
		if load_properties:
			properties_header_label.text += " Properties"
		#MeshInstance3D.new().create_tween().tween_property(self, "transparency", 1.0, 4.0)
		
		# this is a dubious hack to forcibly limit how much time we will take
		# to process and add fields each frame. this allows us to set a fixed
		# performance cost limit on the attributes while loading a new target 
		# (shown below in the _add_fields method) or while freeing children of
		# the current attributes panel so we can populate the data of the new
		# target
		# start by getting the current milliseconds the app has been open
		var start_time : float = Time.get_ticks_msec()
		# for each child...
		for child in v_box_container.get_children():
			# we check if it's been longer than 2 milliseconds since
			# last iteration
			if start_time + 2 < Time.get_ticks_msec():
				# if it has been, then we wait for the next frame
				await get_tree().process_frame
				start_time = Time.get_ticks_msec()
			# finished by freeing the child
			child.queue_free()
		# grab the property list of the new target
		var prop_list :Array[Dictionary]
		if load_properties:
			prop_list.append_array(new_target.get_property_list())
		if load_methods:
			# append the method list to the property list but map it through our
			# helper method to add a type entry to each relevant dictionary so we
			# don't have to change the code below just yet
			prop_list.append_array(new_target.get_method_list().map(_add_types_to_all_entries.bind(TYPE_CALLABLE)))
		if load_signals:
			# same but for signals
			prop_list.append_array(new_target.get_signal_list().map(_add_types_to_all_entries.bind(TYPE_SIGNAL)))
		# call the method to add these fields. we call deferred beacuse it prevents the frontend from
		# stuttering
		call_deferred("_add_fields", prop_list, new_target)

var tmp_prop_list : Array[Dictionary]
func target_property_list_changed():
	#if tmp_prop_list:
		#print_debug(tmp_prop_list == target.get_property_list())
	#tmp_prop_list = target.get_property_list()
	print_debug("props_changed ", target)

## helper method to simply add the type of TYPE_CALLABLE to every entry in the passed array
## so we can include the method/signal list without needing to change how we handle the property list
## below in _add_fields
func _add_types_to_all_entries(input:Dictionary, type: Variant.Type):
	input["type"] = type
	return input

## the method that actually adds the fields to the attributes panel
## [br]we accept a property list that we will use to know what fields to add to the attributes panel
## and a target Object that we want to be editing with the fields
func _add_fields(prop_list, new_target) -> void:
	# global bool to track whether another inspector is already loading something so we can wait
	# for the next frame. this prevents some weird performance issues with having tons of
	# inspectors open
	while LocalGlobals.is_inspector_loading:
		await get_tree().process_frame
	# now we claim this state for this inspector
	LocalGlobals.is_inspector_loading = true
	# a duplicate of the performance hack mentioned above in the end of the set_target method
	var start_time : float = Time.get_ticks_msec()
	# we start adding fields by iterating over every entry in the property list
	for i in prop_list.size():
		# continue hack mentioned above
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()
		# now we retrieve the current property to process
		var prop = prop_list[i]
		# grab the name of the property
		var fieldname :String= prop.name
		# special exception for fields that are bones in a skeleton so we can show the user
		# a less weird name (since these are normally named as full paths to each bone)
		if prop.name.contains("bones/") and new_target is Skeleton3D:
			# set the fieldname to bone: [name of bone] [bone property we are editing]
			# ex: bone: Head position 
			# TODO: make this line less ugly
			fieldname = "bone: "+new_target.get_bone_name(int(prop.name.split("/")[1]))+" "+prop.name.split("/")[-1]
		# if the target has somehow become invalid, exit so we don't crash or error out
		# (yes this was a real issue in the past -_-)
		if !is_instance_valid(new_target):
			return
		# we don't want to allow editing of this field because it's a lil dubious in some behaviors
		if prop.name == "owner":
			continue
		# now we do the type specific stuff
		# basically, we check what type the property is and then add and setup the appropriate
		# field editor
		# i know this part is a big block with no comments, but these should be self-explanatory
		# from reading the code, and if you want more details, you should look in the respective 
		# files for the field you are curious about. if you're curious about other stuff
		# it's probably vaguely described by looking into the get_property_list or get_method_list
		# documentation pages
		match prop.type:
			TYPE_OBJECT:
				var tmp :Object_Attribute = object_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, target, prop.name, prop.class_name)
			TYPE_ARRAY:
				var tmp :Array_Attribute = array_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_STRING_NAME:
				# string names can sometimes be enums
				match prop.hint:
					0:
						var tmp :String_Attribute = string_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
					2:
						var tmp :Enum_Attribute = enum_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop, true)
			TYPE_STRING:
				var tmp :String_Attribute = string_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_COLOR:
				var tmp :Color_Attribute = color_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_BOOL:
				var tmp :Bool_Attribute = bool_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_FLOAT:
				var tmp :Number_Attribute = number_field.instantiate()
				tmp.type = 0
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_INT:
				# ints can sometimes be enums
				match prop.hint:
					2:
						var tmp :Enum_Attribute = enum_field.instantiate()
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop)
					_:
						var tmp :Number_Attribute = number_field.instantiate()
						tmp.type = 1
						v_box_container.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR3:
				var tmp :Vector3_Attribute = vector_3_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR3I:
				var tmp :Vector3_Attribute = vector_3_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR2:
				var tmp :Vector2_Attribute = vector_2_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR2I:
				var tmp :Vector2_Attribute = vector_2_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_CALLABLE, TYPE_SIGNAL:
				var tmp : Run_Attribute = run_field.instantiate()
				v_box_container.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			_:
				# if we don't yet handle this field type, then we wanna add some text
				# declaring such, for now. this is incentive to add support for these fields
				var tmp : Label = Label.new()
				v_box_container.add_child(tmp)
				tmp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				tmp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				tmp.name = fieldname
				tmp.text = "NOT YET SUPPORTED: " + fieldname + "\nTYPE: " + str(prop.type)
	# since this attributes panel is finished loading, we can release the claim
	LocalGlobals.is_inspector_loading = false

func _ready():
	search_bar.text_changed.connect(_on_search_bar_edited)
	# reset vars with setters so they apply on first set
	titlebar_top_row.visible = !hide_titlebar
	titlebar_active.visible = !hide_titlebar
	# get a ref to the event manager (the BarkJournal)
	event_manager = Engine.get_singleton("event_manager")
	# connect to the toggled signal so we can set the value on the target when
	# the button is toggled
	activetoggle.toggled.connect(func(on:bool):
		if target and is_instance_valid(target) and target is Node:
			event_manager.set_property(event_manager.root.get_path_to(target),"visible",on)
			#target.visible = active.button_pressed
		)
	# same but for the target name
	targetname.text_changed.connect(func(new_text:String):
		if target:
			target.set_meta("display_name",new_text)
			target.name = target.name
		)

## Search through the item list.
func _on_search_bar_edited(search_text : String) -> void:
	search_text = search_text.to_lower()

	var filtered_list := Array()
	for child : Node in v_box_container.get_children():
		var contains_all_chars := true
		var class_string_lower := child.name.to_lower()
		for character in search_text:
			if !class_string_lower.contains(character):
				contains_all_chars = false
				break
		if (
				contains_all_chars
				or class_string_lower.contains(search_text)
				or class_string_lower.similarity(search_text) > 0.8
		):
			child.visible = true
		else:
			child.visible = false

	# Sort the list to make the "most accurate" result the top item.
	#filtered_list.sort_custom(func(a : String, b : String) -> bool:
		#return true if search_text.similarity(a.to_lower()) > search_text.similarity(b.to_lower()) else false
	#)
