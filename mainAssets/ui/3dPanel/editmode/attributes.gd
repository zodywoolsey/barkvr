@tool
extends Control

# todo 	for optimization create a system where fields appended (ex: Vector3_Attribute)
#			register the values they need updated with the parent manager so
#			that they can be updated in batches by the parent attr panel
#			with optional self update for user simplicity reasons.

@onready var export = $titlebar/HBoxContainer/HBoxContainer/export
@onready var dupbtn = $titlebar/HBoxContainer/HBoxContainer3/dupbtn
@onready var delete = $titlebar/HBoxContainer/HBoxContainer2/delete

@onready var objectname = $titlebar/HBoxContainer/Panel/objectname

@onready var v_box_container = $ScrollContainer/VBoxContainer

var vector_3_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/vector3.tscn")
var vector_2_field = preload("res://mainAssets/ui/3dPanel/editmode/attributes/vector2.tscn")
var is_field_focused = false
var target : Node = null

func _input(event):
	pass

#func _process(delta):
#	if !is_field_focused:
#		update_fields()

func set_target(node):
	if node:
		for child in v_box_container.get_children():
			child.queue_free()
		target = node
		for prop in target.get_property_list():
			match prop.type:
				9:
					var tmp :Vector3_Attribute = vector_3_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
				5:
					var tmp :Vector2_Attribute = vector_2_field.instantiate()
					v_box_container.add_child(tmp)
					tmp.set_data(prop.name, target, prop.name)
#		update_fields()

func update_fields():
	if target and is_instance_valid(target):
		objectname.text = target.name

func clear_fields():
	if target:
		objectname.text = target.name

func _ready():
	dupbtn.pressed.connect(func():
		if target:
			target.get_parent().add_child(target.duplicate())
		)
	delete.pressed.connect(func():
		if target and is_instance_valid(target):
			target.queue_free()
			target = null
			clear_fields()
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
	objectname.text_changed.connect(func(new_text:String):
		if target:
			print(target)
			target.name = new_text
			print(target)
		)
	objectname.focus_entered.connect(func():
		is_field_focused = true
		)
	objectname.focus_exited.connect(func():
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
