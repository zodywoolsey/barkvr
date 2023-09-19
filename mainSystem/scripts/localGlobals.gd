extends Node

var editor_refs : Dictionary = {}
var interface : XRInterface
var webxr_interface
var vr_supported = false

var local_uis:Array = [
	]

var discord_world = 'loading'
var discord_login_status = 'not logged in'

@export_enum("PAUSED", "PLAYING", "TYPING") var player_state : int = 0
var PLAYER_STATE_PAUSED := 0
var PLAYER_STATE_PLAYING:= 1
var PLAYER_STATE_TYPING := 2

signal playerinit(isvr:bool)
signal playerreleaseuifocus

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().gui_focus_changed.connect(func(node):
		print(node)
		)
	Vector.user_logged_in.connect(func():
		discord_login_status = 'logged in'
		)
	get_tree().get_first_node_in_group("localroot").add_child(load('res://mainSystem/scenes/player/xrplayer.tscn').instantiate())
	if OS.get_name() == "Android":
		OS.request_permissions()

	# Application ID
# 	discord_sdk.app_id = 1137953671842377778
# 	# this is boolean if everything worked
# 	print("Discord working: " + str(discord_sdk.get_is_discord_working()))
# 	print(discord_sdk.get_current_user())
# 	discord_sdk.details = discord_world
# 	discord_sdk.state = discord_login_status
# 	discord_sdk.large_image = "game"
# 	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system())
# 	get_tree().create_timer(1).timeout.connect(_update_discord)

# func _update_discord():
# 	discord_sdk.details = discord_world
# 	discord_sdk.state = discord_login_status
# 	discord_sdk.refresh() 
# 	get_tree().create_timer(1).timeout.connect(_update_discord)
