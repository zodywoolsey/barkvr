@tool
extends Control

#TODO 	for optimization create a system where fields appended (ex: Vector3_Attribute)
#			register the values they need updated with the parent manager so
#			that they can be updated in batches by the parent attr panel
#			with optional self update for user simplicity reasons.

@onready var export = $titlebar/HBoxContainer/HBoxContainer/export
@onready var dupbtn = $titlebar/HBoxContainer/HBoxContainer3/dupbtn
@onready var delete = $titlebar/HBoxContainer/HBoxContainer2/delete
@onready var active = $titlebar/HBoxContainer2/active/HBoxContainer/CheckButton
@onready var targetname = $titlebar/HBoxContainer/Panel/targetname

@onready var v_box_container = $ScrollContainer/VBoxContainer

var vector_3_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/vector2.tscn")
var number_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/number.tscn")
var bool_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/bool.tscn")
var enum_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/enum.tscn")
var is_field_focused = false
var target : Node = null

func _input(event):
	pass

#func _process(delta):
#	if !is_field_focused:
#		update_fields()

func set_target(node):
	if node and node is Node:
		targetname.text = node.name
		if "visible" in node:
			active.disabled = false
			active.button_pressed = node.visible
		else:
			active.button_pressed = true
			active.disabled = true
		for child in v_box_container.get_children():
			child.queue_free()
		target = node
		for prop in target.get_property_list():
			match prop.type:
				TYPE_BOOL:
					var tmp :Bool_Attribute = bool_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
				TYPE_FLOAT:
					var tmp :Number_Attribute = number_field.instantiate()
					tmp.type = 0
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
				TYPE_INT:
					print(prop)
					match prop.hint:
						0:
							var tmp :Number_Attribute = number_field.instantiate()
							tmp.type = 1
							v_box_container.add_child(tmp)
							tmp.set_data(prop.name, target, prop.name)
						2:
							var tmp :Enum_Attribute = enum_field.instantiate()
							v_box_container.add_child(tmp)
							tmp.set_data(prop.name, target, prop.name, prop)
				TYPE_VECTOR3:
					var tmp :Vector3_Attribute = vector_3_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
				TYPE_VECTOR2:
					var tmp :Vector2_Attribute = vector_2_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
#		update_fields()

func update_fields():
	if target and is_instance_valid(target):
		targetname.text = target.name

func clear_fields():
	if target:
		targetname.text = target.name

func _ready():
	dupbtn.pressed.connect(func():
		if target:
			var tmp :Node=target.duplicate()
			target.get_parent().add_child(tmp)
			tmp.name = target.name
		)
	delete.pressed.connect(func():
		if target and is_instance_valid(target):
			target.queue_free()
			target = null
			clear_fields()
		)
	active.pressed.connect(func():
		if target and is_instance_valid(target):
			target.visible = active.button_pressed
		)
	export.pressed.connect(func():
		var world_root = get_tree().get_first_node_in_group("localworldroot")
		if world_root and target:
			var thread = Thread.new()
			thread.start(_export_node.bind(target))
			Journaling.rejoin_thread_when_finished(thread)
#			_export_node(target)
#			var tmp:PackedScene = PackedScene.new()
#			assert(tmp.pack(target)==OK)
#			var err = ResourceSaver.save(tmp,'user://objects/'+target.name+'.res')
#			print(err)
#			OS.shell_open(OS.get_user_data_dir())
		)
	targetname.text_changed.connect(func(new_text:String):
		if target:
			target.name = new_text
		)
	targetname.focus_entered.connect(func():
		is_field_focused = true
		)
	targetname.focus_exited.connect(func():
		is_field_focused = false
		)


func _export_node(target:Node) -> bool:
	Thread.set_thread_safety_checks_enabled(false)
	print('start export')
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("./objects"):
		dir.make_dir("./objects")
	#var object_file = FileAccess.open("user://objects/"+target.name+".gltf", FileAccess.WRITE)
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	gltf.append_from_scene(target,gltf_state)
	gltf.write_to_filesystem(gltf_state,"user://objects/"+target.name+".glb")
	#object_file.store_buffer(gltf.generate_buffer(gltf_state))
	#var tmpjson = BarkHelpers.node_to_var(target,'',target.name)
	#tmpjson = JSON.stringify(tmpjson)
	#object_file.store_var(tmpjson)
	print('exported node')
	return true
