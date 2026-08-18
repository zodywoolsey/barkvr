extends Node3D

# here we are just loading all the vrm extensions manually so they are bound for every import.
# we probably shouldn't do this but i found an interesting benefit in that if a user
# exports as a GLTF/GLB but the file data still includes the vrm metadata and nodes then
# having these available for every import means it will still import the avatar properly
## loading vrm extensions
var vrm_ext_vrm_extension_0 = load("res://addons/vrm/vrm_extension.gd")
## loading vrm extensions
var vrm_ext_emmissive_multiplier = load("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
## loading vrm extensions
var vrm_ext_materials_mtoon = load("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
## loading vrm extensions
var vrm_ext_node_constraint = load("res://addons/vrm/1.0/VRMC_node_constraint.gd")
## loading vrm extensions
var vrm_ext_springbone = load("res://addons/vrm/1.0/VRMC_springBone.gd")
## loading vrm extensions
var vrm_ext_vrm = load("res://addons/vrm/1.0/VRMC_vrm.gd")
## loading vrm extensions
var vrm_ext_vrm_animation = load("res://addons/vrm/1.0/VRMC_vrm_animation.gd")

## pre-ref the path to the loading halo to reduce duplicate lines and make it easier to instantiate
var LOADING_HALO_SCENE := load("res://barkvr-system/ui/3dui/loading_halo.tscn")

## holder variable to keep track of the command line arguments that were used at launch
## [br]we don't really need these after startup but they could be useful in the future
## for feature ideas.
var command_line_arguments :PackedStringArray

## this is the scene we want to instantiate upon startup. 
## TODO: replace this with a fixed startup scene that proceeds to either the user's set homeworld or to a default world or to the new world dialogue
## TODO: create a new world dialogue to accompany the above
@export var game_startup_scene :PackedScene

## ready runs when the tree is setup and is ready to start running. look at the godot docs for
## _ready for more info
func _ready():
	# if the game_startup_scene is set to something then we instantiate it and add it to the tree
	if game_startup_scene:
		call_deferred("add_child",game_startup_scene.instantiate())
	
	# here we check to see if the user has passed any command line arguments
	command_line_arguments = OS.get_cmdline_args()
	if command_line_arguments:
		# indexed for loop is here because it reduces complexity when validating
		# whether the user provided valid options following a custom command line
		# argument
		for arg : int in command_line_arguments.size():
			match command_line_arguments[arg]:
				# here we allow the user to pass a file to auto-import at startup
				# this makes it easier and more practical to use barkvr as a 3d file viewer/quick editor
				# UNFORTUNATELY, these have to be absolute paths rn. godot doesn't seem to provide
				# a builtin way to convert paths like "~" to be "/home/[user]" which sucks. we should
				# add it manually later.
				# TODO: autoconvert shorthand paths to absolute (~/woof.zip -> /home/username/woof.zip)
				"--view-file":
					if command_line_arguments.size() > arg and\
					(command_line_arguments[arg+1].is_absolute_path() or command_line_arguments[arg+1].is_relative_path()):
						
						call_deferred( "import", [ command_line_arguments[ arg+1 ].remove_chars("\\\"") ] )
	# here we load the vrm extensions we reference at the top of the file
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_extension_0.new(),true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_emmissive_multiplier.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_materials_mtoon.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_node_constraint.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_springbone.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm.new(), true)
	GLTFDocument.register_gltf_document_extension(vrm_ext_vrm_animation.new(), true)
	
	# some old attempts at permission requests. i believe this is no longer needed and that goodt
	# asked upon attempting access
	# TODO: look into how we should be handling the permission requests on each platform
	#OS.set_use_file_access_save_and_swap(true)
	#OS.request_permissions()
	
	# here we open the user directory for whatever platform we are on, thankfully godot makes this easy
	# look in godot docs for where this leads for each platform
	var dir = DirAccess.open('user://')
	# now we create the directories we need if they don't already exist
	if !dir.dir_exists('./tmp'):
		dir.make_dir('./tmp')
	if !dir.dir_exists('./objects'):
		dir.make_dir('./objects')
	if !dir.dir_exists('./worlds'):
		dir.make_dir('./worlds')
	if !dir.dir_exists('./logins'):
		dir.make_dir('./logins')
	
	# here we setup a connection to the files_dropped signal from the window
	# this is for capturing when a user drags files from another window
	# and drops them on our window. listening to this signal allows us to run an import
	# when that happens.
	get_window().files_dropped.connect(window_files_dropped)# end files dropped (i put this here because i'm dyslexic and it's easier to read with this here)

## class to simplify the export and provide a fixed schema for what is return
## from the calc_import_position_and_size method. we should start using this 
## design pattern as much as possible to remove all the vague dictionaries that
## have to be manually documented. we can replace them with self-documenting
## classes
class ImportPosAndSize:
	var position : Vector3
	var size : float

## helper method to find the current camera and player and return a calculated size based on the local 
## player that can be used to position imported assets
func calc_import_position_and_size() -> ImportPosAndSize:
	# create the instance we will return
	var out := ImportPosAndSize.new()
	# TODO: move this to the player code, we might also use the globals autoload singleton to hold this data so it is globally available (or even a static var on the player controller class, then we should be able to just ask the class itself for the data)
	# start by initializing the estimated size at 1.0
	# here we do the player size calculation for some reason
	var player_size_mult:float=1.0
	# we then query the tree for the "player" group to find the player node and store it in a var for brevity
	var tmp_player_reference : Node = get_tree().get_first_node_in_group("player")
	# if the tree returns a valid instance...
	if is_instance_valid(tmp_player_reference):
		# get the global scale of the player
		var tmpscale = tmp_player_reference.global_basis.get_scale()
		# do some magic number bullshit we shouldn't be doing (initially tuned for UX reasons but should not be done this way)
		player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
	# lazily find a good position relative to the player to place the imported and assign it to the out
	out.position = get_viewport().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
	# grab the final size calculation and give it to out
	out.size = player_size_mult
	# we return is as a custom class to make it easier to debug lol (yes this actually does make it
	# easier to debug lol)
	return out

func window_files_dropped(files:PackedStringArray):
		# create a loading indicator
		var loader : LoadingHalo = LOADING_HALO_SCENE.instantiate()
		var import_pos_and_size := calc_import_position_and_size()
		# if we are on the web then we need to handle the import differently.
		# TODO: oh my dog why did i do this like this please refactor
		if !OS.get_name() == "Web":
			# spin the task off to a thread to finish importing so we can continue doing other things
			WorkerThreadPool.add_task(func():
				# don't know why we are doing this here, but okay -_-
				Thread.set_thread_safety_checks_enabled(false)
				# run the import function which handles file type detection and passing the
				# import on to the next part of the process
				import(files,loader,import_pos_and_size.position,import_pos_and_size.size)
				, true, "importing: "+str(files))
			# look for the "localworldroot" which is named poorly but is the root of the shared scene
			# (like all the stuff under the localworldroot is what gets synced over the network to 
			# everyone else)
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			# if we couldn't populate the loader text with something then we put a silly text in there
			# since this probably means the import won't work :grimace:
			if loader.text.is_empty():
				loader.text = "something or nothing??? i can't tell yet"
			# set the loader position to the import position we lazily found earlier
			loader.global_position = import_pos_and_size.position
		# not on web, do it a different way
		else:
			# for some reason we aren't passing it to another thread here
			# TODO: make this use threads
			import(files,loader,import_pos_and_size.position,import_pos_and_size.size)
			# find the shared root like mentioned above and add the loader as a child
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			# see above
			if loader.text.is_empty():
				loader.text = "something or nothing??? i can't tell yet"
			# see above
			loader.global_position = import_pos_and_size.position
	

# this was intended to ensure the player is always in the world, that way if the local player object
# is somehow destroyed, we can just immediately reinstantiate it
#func _process(_delta:float) -> void:
	#if !is_instance_valid(get_tree().get_first_node_in_group("player")):
		#var tmp_target_parent = get_tree().get_first_node_in_group("localworldroot")
		#if is_instance_valid(tmp_target_parent):
			#tmp_target_parent.add_child(load("res://barkvr-system/player/local/xrplayer.tscn").instantiate())
		#else:
			#get_tree().root.add_child(load("res://barkvr-system/player/local/xrplayer.tscn").instantiate())

#### the actual import function

## files is an array of paths to the files to be imported. loader is the loading indicator which we
## should have already instantiated before calling this. import position is the initial position 
## where we should place the imported stuff. player_size_mult is used to scale the imported stuff to
## a good size relative to the player
func import(files:PackedStringArray, loader:LoadingHalo=null, import_position:Vector3=Vector3(), player_size_mult:float=1.0):
	# the offset is used while handling multiple simultaneous file imports. we increment this for 
	# each thing that is batch imported to offset them in the world so it's easier to tell what's happening
	var offset := -1.0
	# this one is also just incremented each time but is used for the loader text to indicate the 
	# progress of the batch import
	var iteration :int= 0
	# if there isn't a loading indicator already, create one
	if !is_instance_valid(loader):
		loader = LOADING_HALO_SCENE.instantiate()
		# add it to the tree so it *actually* exists lol
		get_tree().get_first_node_in_group("localworldroot").add_child(loader)
	# for every file in the array
	for dropped in files:
		# increment
		iteration += 1
		offset += 1.0
		
		# here we are just getting the filenames of the stuff we are importing
		var filename:String
		# if we are on windows then we need to handle the filenames differently
		if OS.get_name() == "Windows" or OS.get_name() == "UWP":
			filename = dropped.split('\\')[-1]
		# everywhere else we can handle it *normally* lmao
		else:
			filename = dropped.split('/')[-1]
		# set the loader text to a good indicator 
		loader.text = filename + " (" + str(iteration) + "of" + str(files.size()) + ")"
		# open the file with only read permissions
		var file := FileAccess.open(dropped,FileAccess.READ)
		# if we can't open the file thne it's not real and it can't hurt us
		if !file:
			print_debug('failed to open import file: ',dropped, "\nfailed because: ", FileAccess.get_open_error())
			continue # skip the rest of the process since the file isn't obtainable
		file.close()
		# try to detect the file type:
		# TODO: HOLY SHIT THIS IS SO STUPID. I LITERALLY LOAD THE WHOLE FILE INTO MEMORY ON A WHIM TO JUST CHECK HEADERS *SOBS*
		# TODO: we gotta fix this but i'm commenting right now. i will be back for you :evil stare:
		# TODO: ALSO WHAT THE FUCK I DIDN'T EVEN PROPERLY SWITCH TO USING HEADER DETECTION WTF, WE GOTTA DO THAT TOO FML
		var type = BarkHelpers.detect_file_type_from_header(FileAccess.get_file_as_bytes(dropped))
		# use the offset to move the import position for the aforementioned UX decision
		var new_import_position :Vector3=import_position+Vector3(0,0,offset)
		# TODO: use the type we calculated above using the BarkHelpers class
		# this part is a little cumbersome to read. but the "event_manager" is the BarkJournal, which handles imports right now
		# we should move the import code to it's own class for tons of reasons lol
		# i'm not gonna comment the following lines any further until they are changed because they are all duplicates
		#
		# if the type didn't resolve something we can import, then we check the file extension just incase
		# and pass the import process to the import handling code (currently in BarkJournal)
		if dropped.to_lower().ends_with('.gltf') or \
			dropped.to_lower().ends_with('.glb'):
			BarkJournal.current_bark_journal.import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.fbx'):
			BarkJournal.current_bark_journal.import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult,"type":'fbx'})
		#elif dropped.to_lower().ends_with('.obj'):
			#BarkJournal.current_bark_journal.import_asset('glb', dropped, filename, false, {"base_path":dropped, "position":new_import_position,"scale":player_size_mult,"type":'fbx'})
		elif dropped.to_lower().ends_with('.vrm'):
			BarkJournal.current_bark_journal.import_asset('vrm',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.obj'):
			BarkJournal.current_bark_journal.import_asset('obj',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.res') or \
			dropped.to_lower().ends_with('.tres') or \
			dropped.to_lower().ends_with('.scn')  or \
			dropped.to_lower().ends_with('.tscn') or \
			dropped.to_lower().ends_with('.blend') or \
			dropped.to_lower().ends_with('.mtl'):
			BarkJournal.current_bark_journal.import_asset('res',dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
		#elif dropped.to_lower().ends_with('.pck'):
			#BarkJournal.current_bark_journal.import_asset('pck', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.to_lower().ends_with('.png') or \
			dropped.to_lower().ends_with('.jpg')  or \
			dropped.to_lower().ends_with('.jpeg') or \
			dropped.to_lower().ends_with('.bmp')  or \
			dropped.to_lower().ends_with('.svg')  or \
			dropped.to_lower().ends_with('.tga')  or \
			dropped.to_lower().ends_with('.ktx')  or \
			dropped.to_lower().ends_with('.webp') or \
			type == "img":
			BarkJournal.current_bark_journal.import_asset('image', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.ends_with(".zip") or dropped.to_lower().ends_with('.pck') or dropped.to_lower().ends_with(".resonitepackage") or type == "rpkg":
			BarkJournal.current_bark_journal.import_asset('zip', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		elif dropped.ends_with(".mp3") or dropped.ends_with(".ogg") or dropped.ends_with(".wav"):
			BarkJournal.current_bark_journal.import_asset('audio', dropped, filename, false, {"position":new_import_position,"scale":player_size_mult})
		else:
			BarkJournal.current_bark_journal.import_asset('file', FileAccess.get_file_as_bytes(dropped), filename, false, {"position":new_import_position,"scale":player_size_mult})
	# since this process is blocking for the thread it exists in, we can assume the files are fully imported once this 
	# code is finished executing.
	# tell the loader to play the done animation and close itself
	loader.done()

## here we handle importing from the clipboard
## expects an existing loadinghalo just like the previous function
## import position just like the above
## player_size_mult just like the above
func import_clip(loader:LoadingHalo=null, import_position:Vector3=Vector3(), player_size_mult:float=1.0):
	# we grab a string from the clipboard if possible because sometimes the DisplayServer will tell
	# us it has an image even though the clipboard only contains text. 
	var clipstr : String = DisplayServer.clipboard_get()
	# if the clipboard contains an image and didn't return a string...
	if DisplayServer.clipboard_has_image() and clipstr.is_empty():
		# ask the displayserver for the image in the clipboard
		var clip : Image = DisplayServer.clipboard_get_image()
		# set the loader text to indicate what it's importing is an image
		loader.set_deferred("text", "clipboard image")
		# pass onto the next part of the import process
		BarkJournal.current_bark_journal.import_asset('image', clip, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
	else:
		# create a holder for attempting to load the plain text as an svg
		var trysvg = Image.new()
		# attempt to load the plain text as an svg
		# including a quick calculation to try to normalize the size of the svg
		var did_svg_load = trysvg.load_svg_from_string(clipstr, 1000.0/trysvg.get_size().length())
		# if the svg loaded successfully
		if did_svg_load == OK:
			# if we did load an svg we wanna update the text to say it's an image
			# since godot will rasterize the svg to an image resource
			loader.set_deferred("text", "clipboard image")
			BarkJournal.current_bark_journal.import_asset('image', trysvg, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		# if the text is a URL, then we wanna import it as a remote uri
		elif clipstr.begins_with("http://") or clipstr.begins_with("https://"):
			loader.set_deferred("text", "clipboard url")
			BarkJournal.current_bark_journal.import_asset('uri',clipstr,'', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		# otehrwise we just import it as a 3d text object
		else:
			loader.set_deferred("text", "clipboard text")
			BarkJournal.current_bark_journal.import_asset('text', clipstr, '', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
		
# here we capture inputs so we can capture when the player is pasting something
# TODO: make this so it's not hard-coded to ctrl+v
func _input(event):
	# we only wanna do stuff if it's a key event
	if event is InputEventKey:
		# check if it aligns with our conditions for paste importing (right buttons and player state)
		if event.physical_keycode == KEY_V and event.ctrl_pressed and event.pressed and LocalGlobals.player_state != LocalGlobals.PLAYER_STATE_TYPING:
			# this is essentially a duplicate of the code that exists in the files_dropped code, so look
			# above for more info
			var player_size_mult:float=1.0
			if is_instance_valid(get_tree().get_first_node_in_group("player")):
				var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
				player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
			var import_position :Vector3= get_viewport().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
			var loader :LoadingHalo= LOADING_HALO_SCENE.instantiate()
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			var clipthread := Thread.new()
			clipthread.start(import_clip.bind(loader, import_position, player_size_mult))
			BarkHelpers.rejoin_thread_when_finished(clipthread)
			loader.global_position = import_position
		# if the player is pressing the keys to undo, then we wanna send an undo to the BarkJournal
		if event.physical_keycode == KEY_Z and event.ctrl_pressed and event.pressed:
			BarkJournal.current_bark_journal.undo_action()
