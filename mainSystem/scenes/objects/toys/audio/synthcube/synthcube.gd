extends RigidBody3D

@onready var audio_stream_player = $AudioStreamPlayer3D
var stream : AudioStreamGeneratorPlayback
var timer = 0
@onready var label = $Label3D
@onready var label_2 = $Label3D2

var pitch = .05

func _ready():
	stream = audio_stream_player.get_stream_playback()

func _process(delta):
#	audio_stream_player.play()
	var newval = lerp(audio_stream_player.pitch_scale,linear_velocity.length(),.1)
	audio_stream_player.pitch_scale = clampf(sin(timer/32.0),.2,1.0)
	label.text = str(audio_stream_player.pitch_scale)
	timer += stream.get_frames_available()
	var tofill = stream.get_frames_available()
	while tofill > 0:
		stream.push_frame(Vector2.ONE * sin( (timer-tofill)*pitch ))
		tofill -= 1
