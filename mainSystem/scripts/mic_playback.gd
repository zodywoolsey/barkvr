class_name MicPlayback
extends AudioStreamPlayer

var buffer_to_push:Array
var playback_stream:AudioStreamGeneratorPlayback
@onready var sample_hz = stream.mix_rate

var timer := 0
var pitch = .05

var thread:Thread = Thread.new()

#func _ready():
#	playback_stream = get_stream_playback()
#	thread.start(poll)
#
#func _process(delta):
#	if !playing:
#		play()
#	if !thread.is_alive() and thread.is_started():
#		thread.wait_to_finish()
#		thread.start(poll)
#
#func poll():
#	while true:
#		var phase = 0.0
#		var increment = 150.0 / sample_hz
#	#	print(playback_stream.get_frames_available())
#		timer += stream.get_frames_available()
#		var tofill = stream.get_frames_available()
#		for i in range(playback_stream.get_frames_available()):
#			if buffer_to_push.size()>0:
#				playback_stream.push_frame(buffer_to_push.pop_back())
#			else:
#				stream.push_frame(Vector2.ONE * sin( (timer-tofill)*pitch ))
#				phase = fmod(phase + increment, 1.0)
#
func set_buffer(data:PackedVector2Array):
	buffer_to_push.append_array(data)
