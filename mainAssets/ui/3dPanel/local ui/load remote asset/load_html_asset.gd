extends Control

@onready var url = $VBoxContainer/url
@onready var submit = $VBoxContainer/submit
@onready var http_request = $HTTPRequest

func _ready():
	submit.pressed.connect(func():
		http_request.request(url.text)
		)
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		print(headers)
		
		)
