extends Button

@onready var homeserver = $"../homeserver"
@onready var uname = $"../uname"
@onready var pword = $"../pword"
@onready var button = $"."

func _ready():
	button.pressed.connect(func():
		if is_instance_valid(Engine.get_singleton("user_manager")):
			Engine.get_singleton("user_manager").login_username_password(
				homeserver.text,
				uname.text,
				pword.text
			)
		)
