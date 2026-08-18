extends Control

# import url vars
@onready var url: LineEdit = %url
@onready var submit: Button = %submit
@onready var submitastext: Button = %submitastext
@onready var http_request_file = $HTTPRequestFile
@onready var http_request: HTTPRequest = $HTTPRequest

# import file vars
@onready var import_file_btn: Button = %import_file_btn
var import_file_dialog := FileDialog.new()

func _ready():
	submit.pressed.connect(submit_pressed)
	submitastext.pressed.connect(submit_as_text_pressed)
	import_file_btn.pressed.connect(import_file_btn_pressed)

func import_file_btn_pressed() -> void:
	setup_file_dialog()
	import_file_dialog.show()

var is_file_dialog_setup := false
func setup_file_dialog() -> void:
	if !is_file_dialog_setup:
		is_file_dialog_setup = true
		import_file_dialog.use_native_dialog = true
		import_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		#import_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		import_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_ANY
		import_file_dialog.file_selected.connect(file_dialog_open)
		import_file_dialog.files_selected.connect(files_dialog_open)
		import_file_dialog.dir_selected.connect(file_dialog_open_dir)
		import_file_dialog.current_dir = "/storage/emulated/0"
		import_file_dialog.root_subfolder = "/storage/emulated/0"

func file_dialog_open_dir(path:String) -> void:
	pass

func files_dialog_open(paths:PackedStringArray) -> void:
	pass

func file_dialog_open(path:String) -> void:
	var import_file_bytes := FileAccess.get_file_as_bytes(path)
	var tmp_import_type := BarkHelpers.detect_file_type_from_header(import_file_bytes)
	if tmp_import_type.is_empty():
		tmp_import_type = path.get_extension()
	BarkJournal.current_bark_journal.call_deferred("import_asset", tmp_import_type, import_file_bytes)

func submit_pressed() -> void:
	var loader :LoadingHalo = load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
	loader.text = url.text
	var player_size_mult:float=1.0
	var import_position :Vector3= get_window().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
	if is_instance_valid(get_tree().get_first_node_in_group("player")):
		var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
		player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
	Engine.get_singleton("event_manager").import_asset('uri',url.text,'', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
	get_tree().get_first_node_in_group("localworldroot").add_child(loader)
	if loader.text.is_empty():
		loader.text = "nothing?"
	loader.global_position = import_position
	

func submit_as_text_pressed() -> void:
	http_request.request_completed.connect(func(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		print("request completed")
		var xml := XMLParser.new()
		xml.open_buffer(body)
		var loader :LoadingHalo = load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
		loader.text = url.text
		var player_size_mult:float=1.0
		var import_position :Vector3= get_window().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
		if is_instance_valid(get_tree().get_first_node_in_group("player")):
			var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
			player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
		WorkerThreadPool.add_task(func():
			Engine.get_singleton("event_manager").import_asset('text',body.get_string_from_utf8(),'', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
			)
		get_tree().get_first_node_in_group("localworldroot").add_child(loader)
		if loader.text.is_empty():
			loader.text = "nothing?"
		loader.global_position = import_position
		,4)
	http_request.request(url.text)
	
