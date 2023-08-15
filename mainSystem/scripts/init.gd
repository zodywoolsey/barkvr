extends Node3D

@onready var start_xr = $StartXR

func _ready():
	start_xr.xr_started.connect(func():
		LocalGlobals.vr_supported = true
		)
#	Vector.user_logged_in.connect(func():
#		discord_sdk.details = "local home, logged in"
#		discord_sdk.refresh()
#		)
#
#	# Application ID
#	discord_sdk.app_id = 1137953671842377778
#	# this is boolean if everything worked
#	print("Discord working: " + str(discord_sdk.get_is_discord_working()))
#	print(discord_sdk.get_current_user())
#	discord_sdk.details = "local home, not logged in"
#	discord_sdk.large_image = "game"
#	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system())
#
#	# Always refresh after changing the values!
#	discord_sdk.refresh() 
