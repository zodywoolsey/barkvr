extends Button

@onready var homeserver = $"../homeserver"
@onready var uname = $"../uname"
@onready var pword = $"../pword"
@onready var button = $"."

func _ready():
	button.pressed.connect(func():
		Vector.login_username_password(
			homeserver.text,
			uname.text,
			pword.text
		)
		)
