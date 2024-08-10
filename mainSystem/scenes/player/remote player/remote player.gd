extends Node3D

var targetpos :Vector3 = Vector3()
var speed :float = 1.5
var time_since :float = 0.0

var audio_frames := PackedVector2Array()
var audio_mutex := Mutex.new()
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
var audio_playback : AudioStreamGeneratorPlayback
var player_audio_thread := Thread.new()

var close_requested :bool = false

func set_target_pos(new_pos:Vector3) -> void:
	targetpos=new_pos
	create_tween().tween_property(self,'global_position',targetpos,time_since)
	time_since = 0.0

func _process(delta) -> void:
	time_since += delta

func _ready() -> void:
	audio_playback = audio_stream_player_3d.get_stream_playback()
	get_window().close_requested.connect(func():
		close_requested = true
		)
	player_audio_thread.start(push_audio_thread)

func push_audio_thread():
	while !close_requested:
		if is_instance_valid(audio_playback) and audio_playback.can_push_buffer(audio_frames.size()):
			audio_mutex.lock()
			var tmpframes = audio_frames.duplicate()
			audio_mutex.unlock()
			audio_playback.push_buffer(audio_frames)
