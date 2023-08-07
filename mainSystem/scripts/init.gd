extends Node3D

@onready var start_xr = $StartXR

func _ready():
	start_xr.xr_started.connect(func():
		LocalGlobals.vr_supported = true
		)
	# Application ID
	discord_sdk.app_id = 1137953671842377778
	# this is boolean if everything worked
	print("Discord working: " + str(discord_sdk.get_is_discord_working()))
	print(discord_sdk.get_current_user())
	
	# Set the first custom text row of the activity here
	discord_sdk.details = "testing barkvr"
	# Set the second custom text row of the activity here
	discord_sdk.state = "test"
	# Image key for small image from "Art Assets" from the Discord Developer website
	discord_sdk.large_image = "game"
	# Tooltip text for the large image
	discord_sdk.large_image_text = "big text"
	# Image key for large image from "Art Assets" from the Discord Developer website
	discord_sdk.small_image = "smol text"
	# Tooltip text for the small image
	discord_sdk.small_image_text = "testing some shit"
	# "02:41 elapsed" timestamp for the activity
	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system())
	# "59:59 remaining" timestamp for the activity
	discord_sdk.end_timestamp = int(Time.get_unix_time_from_system()) + 3600
	# Always refresh after changing the values!
	discord_sdk.refresh() 
