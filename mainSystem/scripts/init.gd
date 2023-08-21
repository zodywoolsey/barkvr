extends Node3D

@onready var start_xr = $StartXR

func _ready():
	start_xr.xr_started.connect(func():
		LocalGlobals.vr_supported = true
		)
	get_window().files_dropped.connect(func(files):
		print("files: \n\n",files)
		var object_file = FileAccess.open(files[0], FileAccess.READ_WRITE)
		if object_file:
			var tmp = object_file.get_as_text()
			var loaded_object = BarkHelpers.var_to_node(tmp)
			var localworld = get_tree().get_first_node_in_group("localworldroot")
			if localworld:
				print("loaded object: ",str(loaded_object))
				var parent = get_tree().get_first_node_in_group('localworldroot')
				if parent:
					parent.add_child(loaded_object)
		)
#	Vector.user_logged_in.connect(func():
#		discord_sdk.details = "local home, logged in"
#		discord_sdk.refresh()
#		)

	# Application ID
	discord_sdk.app_id = 1137953671842377778
	# this is boolean if everything worked
	print("Discord working: " + str(discord_sdk.get_is_discord_working()))
	print(discord_sdk.get_current_user())
	discord_sdk.details = "local home, not logged in"
	discord_sdk.large_image = "game"
	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system())

func _process(delta):
	discord_sdk.refresh() 
