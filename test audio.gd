extends Node3D

@onready var audio_stream_player = $AudioStreamPlayer
var stream : AudioStreamGeneratorPlayback
var timer = 0

var pitch = .05

var mousepos = Vector2()

var thread:Thread = Thread.new()

func _ready():
	stream = audio_stream_player.get_stream_playback()
#	thread.start(dostuff())

func _process(delta):
	dostuff()

func dostuff():
	timer += stream.get_frames_available()
	var tofill = stream.get_frames_available()
	while tofill > 0:
		stream.push_frame(Vector2.ONE * sin( (timer-tofill)*pitch ))
		tofill -= 1

func _input(event):
	if event is InputEventMouseMotion:
		mousepos = event.relative
