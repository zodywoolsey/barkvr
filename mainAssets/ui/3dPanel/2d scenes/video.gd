extends VBoxContainer

@onready var play = $HBoxContainer/play
@onready var pause = $HBoxContainer/pause
@onready var restart = $HBoxContainer/restart
@onready var video = $AspectRatioContainer/video

func _ready():
	play.pressed.connect(func():
		if !video.is_playing():
			video.play()
		elif video.paused:
			video.paused = false
		)
	pause.pressed.connect(func():
		video.paused = true
		)
	restart.pressed.connect(func():
		video.stop()
		)
