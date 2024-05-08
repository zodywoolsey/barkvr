extends Node3D

@onready var start_xr = $StartXR
const gltf_document_extension_class = preload("res://addons/vrm/vrm_extension.gd")

func _ready():
	GLTFDocument.register_gltf_document_extension(preload("res://addons/vrm/vrm_extension.gd").new(), true)
#	print(ProjectSettings.get_global_class_list())
	get_viewport().canvas_cull_mask
	var dir = DirAccess.open('user://')
	if !dir.dir_exists('./tmp'):
		dir.make_dir('./tmp')
	if !dir.dir_exists('./objects'):
		dir.make_dir('./objects')
	if !dir.dir_exists('./worlds'):
		dir.make_dir('./worlds')
	get_window().files_dropped.connect(func(files):
		var filename:String
		var file := FileAccess.open(files[0],FileAccess.READ)
		if !file:
			print('failed to open import file')
		if OS.get_name() == "Windows" or OS.get_name() == "UWP":
			filename = files[0].split('\\')[-1]
		else:
			filename = files[0].split('/')[-1]
		if files[0].contains('.gltf') or files[0].contains('.glb'):
			Journaling.import_asset('glb', files[0], filename, false, {"base_path":files[0]})
		elif files[0].contains('.vrm'):
			Journaling.import_asset('vrm',files[0], filename)
		elif files[0].ends_with('.res') or files[0].ends_with('.tres') or files[0].ends_with('.scn') or files[0].ends_with('.tscn'):
			Journaling.import_asset('res',files[0], filename)
		elif files[0].ends_with('.zip') or files[0].ends_with('.pck'):
			Journaling.import_asset('pck', files[0], filename)
		elif files[0].ends_with('png') or files[0].ends_with('jpg') or files[0].ends_with('jpeg'):
			Journaling.import_asset('image', FileAccess.get_file_as_bytes(files[0]), filename)
		)

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
