extends Button

@onready var homeserver: LineEdit = $"../homeserver"
@onready var uname: LineEdit = $"../uname"
@onready var pword: LineEdit = $"../pword"
@onready var button: Button = $"."
@onready var base_url_lbl: Label = $"../Label/base_url"

func _ready():
	if is_instance_valid(Engine.get_singleton("user_manager")):
		Engine.get_singleton("user_manager").got_well_known.connect(func(homeserver:String, base_url:String):
			base_url_lbl.text = "base_url: "+base_url
			button.disabled = false
			)
	homeserver.text_changed.connect(func(new_text:String):
		if is_instance_valid(Engine.get_singleton("user_manager")):
			Engine.get_singleton("user_manager").get_well_known(new_text)
			base_url_lbl.text = ""
			button.disabled = true
		)
	homeserver.text_changed.emit(homeserver.text)
	button.pressed.connect(func():
		if is_instance_valid(Engine.get_singleton("user_manager")):
			Engine.get_singleton("user_manager").login_username_password(
				Engine.get_singleton("user_manager").base_url,
				uname.text,
				pword.text
			)
		)
