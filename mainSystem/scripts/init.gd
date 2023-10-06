extends Node3D

@onready var start_xr = $StartXR
const gltf_document_extension_class = preload("res://addons/vrm/vrm_extension.gd")

func _ready():
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
		)


