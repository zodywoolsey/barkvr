extends Node3D

@onready var start_xr = $StartXR
const gltf_document_extension_class = preload("res://addons/vrm/vrm_extension.gd")

func _ready():
	get_viewport().canvas_cull_mask
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec",100000000)
	var dir = DirAccess.open('user://')
	if !dir.dir_exists('./tmp'):
		dir.make_dir('./tmp')
	if !dir.dir_exists('./objects'):
		dir.make_dir('./objects')
	if !dir.dir_exists('./worlds'):
		dir.make_dir('./worlds')
	start_xr.xr_started.connect(func():
		LocalGlobals.vr_supported = true
		)
	get_window().files_dropped.connect(func(files):
		var filename:String
		if OS.get_name() == "Windows" or OS.get_name() == "UWP":
			filename = files[0].split('\\')[-1]
		else:
			filename = files[0].split('/')[-1]
		if files[0].contains('.gltf') or files[0].contains('.glb'):
			Journaling.import_asset('glb', FileAccess.get_file_as_bytes(files[0]), filename)
		elif files[0].contains('.vrm'):
			Journaling.import_asset('vrm',FileAccess.get_file_as_bytes(files[0]), filename)
		elif files[0].ends_with('.res') or files[0].ends_with('.tres') or files[0].ends_with('.scn') or files[0].ends_with('.tscn'):
			Journaling.import_asset('res',files[0], filename)
		elif files[0].ends_with('.zip') or files[0].ends_with('.pck'):
			Journaling.import_asset('pck', files[0], filename)
		elif files[0].ends_with('png') or files[0].ends_with('jpg') or files[0].ends_with('jpeg'):
			Journaling.import_asset('image', FileAccess.get_file_as_bytes(files[0]), filename)
		)


