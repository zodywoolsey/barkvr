extends Control

#TODO 	find a more optimized way to update field values
#		currently, we're culling field updates to only those visible
# the want is for the fields to behave like they're sharing the reference to a 
# pointer and then are just all the same pointer value. then they would update 
# implicitly because theyre value exists in the same spot. the issue is that
# we still need to tell the elements to update the visuals at some rate. but
# i think if we could get the engine to behave in a way like described, it could
# be cheaper to just deref the pointer for the value it should be instead of
# letting the engine pass those variables around and potentially be duping them

@onready var export = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer/export
@onready var dupbtn = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer3/dupbtn
@onready var delete = $VBoxContainer/titlebar/HBoxContainer/HBoxContainer2/delete
@onready var properties_header_label = $"VBoxContainer/titlebar/properties header/Panel9/properties header label"
@onready var active = $"VBoxContainer/titlebar/properties header/active/HBoxContainer/CheckButton"
@onready var targetname = $VBoxContainer/titlebar/HBoxContainer/Panel/targetname

@onready var v_box_container = $VBoxContainer/ScrollContainer/VBoxContainer

var vector_3_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/vector2.tscn")
var number_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/number.tscn")
var bool_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/bool.tscn")
var enum_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/enum.tscn")
var string_field = load("res://mainAssets/ui/3dPanel/editmode/attributes/string.tscn")
var object_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/object.tscn")
var is_field_focused = false
var target : Node = null

var event_manager

#func _process(delta):
#	if !is_field_focused:
#		update_fields()

func set_target(target):
	if target and target is Object:
		if "name" in target:
			targetname.text = target.name
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		if "visible" in target:
			active.disabled = false
			active.button_pressed = target.visible
		else:
			active.button_pressed = true
			active.disabled = true
		properties_header_label.text = target.get_class()+" Properties:"
		for child in v_box_container.get_children():
			child.queue_free()
		var prop_list :Array[Dictionary]= target.get_property_list()
		for prop in prop_list:
			var fieldname :String= prop.name
			if prop.name.contains("bones/") and target is Skeleton3D:
				fieldname = "bone: "+target.get_bone_name(int(prop.name.split("/")[1]))+" "+prop.name.split("/")[-1]
			match prop.type:
				#TYPE_OBJECT:
					#var tmp :Object_Attribute = object_field.instantiate()
					#v_box_container.add_child(tmp)
					#tmp.call_deferred("set_data",fieldname, target, prop.name)
				TYPE_STRING_NAME:
					var tmp :String_Attribute = string_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
				TYPE_STRING:
					var tmp :String_Attribute = string_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
				TYPE_BOOL:
					var tmp :Bool_Attribute = bool_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
				TYPE_FLOAT:
					var tmp :Number_Attribute = number_field.instantiate()
					tmp.type = 0
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
				TYPE_INT:
					#print(prop)
					match prop.hint:
						0:
							var tmp :Number_Attribute = number_field.instantiate()
							tmp.type = 1
							v_box_container.add_child(tmp)
							tmp.set_data(fieldname, target, prop.name)
						2:
							var tmp :Enum_Attribute = enum_field.instantiate()
							v_box_container.add_child(tmp)
							tmp.set_data(fieldname, target, prop.name, prop)
				TYPE_VECTOR3:
					var tmp :Vector3_Attribute = vector_3_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
				TYPE_VECTOR2:
					var tmp :Vector2_Attribute = vector_2_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(fieldname, target, prop.name)
#		update_fields()

func update_fields():
	if target and is_instance_valid(target):
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		else:
			targetname.text = target.name

func clear_fields():
	if target:
		if target.has_meta("display_name"):
			targetname.text = target.get_meta("display_name")
		else:
			targetname.text = target.name

func _ready():
	event_manager = Engine.get_singleton("event_manager")
	print("event supplierattrib: "+str(event_manager))
	print(event_manager)
	dupbtn.pressed.connect(func():
		if target:
			var tmp :Node=target.duplicate()
			target.get_parent().add_child(tmp)
			tmp.name = target.name
		)
	delete.pressed.connect(func():
		if target and is_instance_valid(target):
			event_manager.delete_node(event_manager.root.get_path_to(target))
			clear_fields()
		)
	active.pressed.connect(func():
		if target and is_instance_valid(target):
			event_manager.set_property(event_manager.root.get_path_to(target),"visible",active.button_pressed)
			#target.visible = active.button_pressed
		)
	export.pressed.connect(func():
		var world_root = get_tree().get_first_node_in_group("localworldroot")
		if world_root and target:
			var thread = Thread.new()
			thread.start(_export_node.bind(target))
			BarkHelpers.rejoin_thread_when_finished(thread)
#			_export_node(target)
#			var tmp:PackedScene = PackedScene.new()
#			assert(tmp.pack(target)==OK)
#			var err = ResourceSaver.save(tmp,'user://objects/'+target.name+'.res')
#			print(err)
#			OS.shell_open(OS.get_user_data_dir())
		)
	targetname.text_changed.connect(func(new_text:String):
		if target:
			target.set_meta("display_name",new_text)
			target.name = target.name
		)
	targetname.focus_entered.connect(func():
		is_field_focused = true
		)
	targetname.focus_exited.connect(func():
		is_field_focused = false
		)


func _export_node(tmp_target:Node):
	Thread.set_thread_safety_checks_enabled(false)
	print(var_to_str(tmp_target))
	#print('start export')
	#var downpath :String=OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	#downpath += "/"
	#if OS.get_name() == "Web":
		#var packed := PackedScene.new()
		#event_manager.take_owner_of_node_and_all_children(tmp_target,tmp_target)
		#packed.pack(tmp_target)
		#print("save path: "+downpath+tmp_target.name+".res")
		#JavaScriptBridge.download_buffer(var_to_bytes_with_objects(packed),tmp_target.name+".res")
		##print("export error: "+str(err))
	#elif DirAccess.dir_exists_absolute(downpath):
		#var packed := PackedScene.new()
		#event_manager.take_owner_of_node_and_all_children(tmp_target,tmp_target)
		#packed.pack(tmp_target)
		#var err = ResourceSaver.save(packed, downpath+tmp_target.name+".res",ResourceSaver.FLAG_BUNDLE_RESOURCES)
		#print("export error: "+str(err))
		
		
	#if !dir.dir_exists("./objects"):
		#dir.make_dir("./objects")
	##var object_file = FileAccess.open("user://objects/"+tmp_target.name+".gltf", FileAccess.WRITE)
	#var gltf = GLTFDocument.new()
	#var gltf_state = GLTFState.new()
	#gltf.append_from_scene(tmp_target,gltf_state)
	#gltf.write_to_filesystem(gltf_state,"user://objects/"+tmp_target.name+".glb")
	##object_file.store_buffer(gltf.generate_buffer(gltf_state))
	##var tmpjson = BarkHelpers.node_to_var(tmp_target,'',tmp_target.name)
	##tmpjson = JSON.stringify(tmpjson)
	##object_file.store_var(tmpjson)
	#print('exported node')
	#return true
