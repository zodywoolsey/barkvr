extends Control

@onready var url = $VBoxContainer/url
@onready var submit = $VBoxContainer/submit
@onready var submitastext: Button = $VBoxContainer/submitastext
@onready var http_request_file = $HTTPRequestFile
@onready var http_request: HTTPRequest = $HTTPRequest

func _ready():
	submit.pressed.connect(func():
		var loader :LoadingHalo = load("res://mainAssets/ui/3dui/loading_halo.tscn").instantiate()
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
		)
	submitastext.pressed.connect(func():
		http_request.request_completed.connect(func(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
			print("request completed")
			var xml := XMLParser.new()
			xml.open_buffer(body)
			var loader :LoadingHalo = load("res://mainAssets/ui/3dui/loading_halo.tscn").instantiate()
			loader.text = url.text
			var player_size_mult:float=1.0
			var import_position :Vector3= get_window().get_camera_3d().to_global(Vector3(0,0,-2.0)*player_size_mult)
			if is_instance_valid(get_tree().get_first_node_in_group("player")):
				var tmpscale = get_tree().get_first_node_in_group("player").global_basis.get_scale()
				player_size_mult = (tmpscale.x+tmpscale.y+tmpscale.z)/3.0
			Engine.get_singleton("event_manager").import_asset('text',body.get_string_from_utf8(),'', false, {"loader":loader ,"position":import_position, "scale":player_size_mult})
			get_tree().get_first_node_in_group("localworldroot").add_child(loader)
			if loader.text.is_empty():
				loader.text = "nothing?"
			loader.global_position = import_position
			,4)
		http_request.request(url.text)
		)
