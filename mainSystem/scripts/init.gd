extends Node3D

@onready var start_xr = $StartXR

func _ready():
	#GLTFDocument.register_gltf_document_extension(VRMC_vrm_animation_inst)
#	print(ProjectSettings.get_global_class_list())
	get_viewport().canvas_cull_mask
	var dir = DirAccess.open('user://')
	if !dir.dir_exists('./tmp'):
		dir.make_dir('./tmp')
	if !dir.dir_exists('./objects'):
		dir.make_dir('./objects')
	if !dir.dir_exists('./worlds'):
		dir.make_dir('./worlds')
	get_window().files_dropped.connect(func(files:PackedStringArray):
		var loader :LoadingHalo= load("res://mainAssets/ui/3dui/loading_halo.tscn").instantiate()
		var import_position :Vector3= get_viewport().get_camera_3d().to_global(Vector3(0,0,-2.0))
		var thread := Thread.new()
		thread.start(func():
			Thread.set_thread_safety_checks_enabled(false)
			var offset := -1.0
			var iteration :int= 0
			for dropped in files:
				iteration += 1
				offset += 1.0
				var filename:String
				if OS.get_name() == "Windows" or OS.get_name() == "UWP":
					filename = dropped.split('\\')[-1]
				else:
					filename = dropped.split('/')[-1]
				loader.text = filename + " (" + str(iteration) + "of" + str(files.size()) + ")"
				var file := FileAccess.open(dropped,FileAccess.READ)
				if !file:
					print('failed to open import file')
					continue
				if dropped.contains('.gltf') or dropped.contains('.glb'):
					Journaling.import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":import_position+Vector3(0,0,offset)})
				elif dropped.contains('.vrm'):
					Journaling.import_asset('vrm',dropped, filename, false, {"position":import_position+Vector3(0,0,offset)})
				elif dropped.ends_with('.res') or dropped.ends_with('.tres') or dropped.ends_with('.scn') or dropped.ends_with('.tscn'):
					Journaling.import_asset('res',dropped, filename, false, {"position":import_position+Vector3(0,0,offset)})
				#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
				elif dropped.ends_with('.pck'):
					Journaling.import_asset('pck', dropped, filename, false, {"position":import_position+Vector3(0,0,offset)})
				elif dropped.ends_with('.png') or dropped.ends_with('.jpg') or dropped.ends_with('.jpeg'):
					Journaling.import_asset('image', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":import_position+Vector3(0,0,offset)})
				else:
					Journaling.import_asset('file', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":import_position+Vector3(0,0,offset)})
		)# end of thread func
		Journaling.rejoin_thread_when_finished(thread)
		get_tree().get_first_node_in_group("localworldroot").add_child(loader)
		if loader.text.is_empty():
			loader.text = "nothing?"
		loader.set_wait_for_thread(thread)
		loader.global_position = import_position
	)# end of files dropped

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_F8:
			var tmp = MeshInstance3D.new()
			tmp.mesh = BoxMesh.new()
			

@export var threshold = 0
# Reference to global player controller
@onready var player: Node3D = get_node("/root/main/playercontainer/CharacterBody3D")
# Reference to global origin
@export var global_origin: Node3D

# Function to contain origin shift logic
#func shift_origin() -> void:
	# Shift everything by the offset of the global player controller
	#global_origin.global_transform.origin -= player.global_transform.origin
	#print("World shifted to " + str(global_origin.global_transform.origin))

# switching this process to a _physics_process makes physics work but the player controller vibrates
# setting the process to _process makes the player controller not vibrate when in useing moving origin 
# but when updating the origin the physics pauses untill the origin is finished updating
# we currently use threshold to shift the world and at 0 its set to be a moving origin 
# setting it higher will make the orgin move less and dosent vibrate player controller

#func _physics_process(delta: float) -> void:
	#Check distance of world from global player controller and shift if greater than threshold
	#if player.global_transform.origin.length() > threshold && player != null:
		#print(name)
		#shift_origin()
