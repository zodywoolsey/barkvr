class_name MicPlayback
extends AudioStreamPlayer

var buffer_to_push:Array
var playback_stream:AudioStreamGeneratorPlayback
@onready var sample_hz = stream.mix_rate
func _ready():
	playback_stream = get_stream_playback()

func _process(delta):
	var phase = 0.0
	var increment = 150.0 / sample_hz
	print(playback_stream.get_frames_available())
	for i in range(10000):
		if buffer_to_push.size()>0:
			playback_stream.push_frame(buffer_to_push.pop_back())
		else:
			playback_stream.push_frame(Vector2.ONE * sin(phase * TAU))
			phase = fmod(phase + increment, 1.0)

func set_buffer(data:PackedVector2Array):
	if !buffer_to_push.size()>0:
		buffer_to_push = data
