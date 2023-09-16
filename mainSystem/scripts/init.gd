extends Node3D

@onready var start_xr = $StartXR
const gltf_document_extension_class = preload("res://addons/vrm/vrm_extension.gd")

func _ready():
	start_xr.xr_started.connect(func():
		LocalGlobals.vr_supported = true
		)
	get_window().files_dropped.connect(func(files):
		print("files: \n\n",files)
		var file:FileAccess = FileAccess.open(files[0], FileAccess.READ)
		if files[0].contains('.gltf') or files[0].contains('.glb'):
			var doc:GLTFDocument = GLTFDocument.new()
			var state:GLTFState = GLTFState.new()
			doc.append_from_file(files[0],state)
			get_tree().get_first_node_in_group('localworldroot').add_child(doc.generate_scene(state))
		elif files[0].contains('.vrm'):
			Journaling.import_asset('vrm',FileAccess.get_file_as_bytes(files[0]))
#		var world_file = FileAccess.open(files[0], FileAccess.READ_WRITE)
#		if world_file:
#			var tmp = world_file.get_as_text()
#			var loaded_world = BarkHelpers.var_to_node(tmp)
#			var localworld = get_tree().get_first_node_in_group("localworldroot")
#			if localworld:
#				print(str(localworld),"replaced by",str(loaded_world))
#				var parent = get_tree().get_first_node_in_group('localroot')
#				localworld.queue_free()
#				parent.add_child(loaded_world)
		)
#	Vector.user_logged_in.connect(func():
#		discord_sdk.details = "local home, logged in"
#		discord_sdk.refresh()
#		)


