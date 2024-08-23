extends Node3D

var targetpos :Vector3 = Vector3()
var speed :float = 1.5
var time_since :float = 0.0

var audio_frames :Array[PackedVector2Array] = []
var audio_mutex := Mutex.new()
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
var audio_decoder : AudioStreamOpusDecoder
var audio_playback : AudioStreamGeneratorPlayback
var player_audio_thread := Thread.new()
var audio_timer := (1.0/48000)*960

var pushed_frames :int= 0

var close_requested :bool = false

func set_target_pos(new_pos:Vector3) -> void:
	targetpos=new_pos
	create_tween().tween_property(self,'global_position',targetpos,time_since)
	time_since = 0.0

func _process(delta) -> void:
	time_since += delta

func _ready() -> void:
	audio_decoder = audio_stream_player_3d.stream
	audio_playback = audio_stream_player_3d.get_stream_playback()
	get_window().close_requested.connect(func():
		close_requested = true
		)

func push_audio_buffer(buffer:PackedVector2Array) -> void:
	audio_mutex.lock()
	audio_frames.append(buffer)
	audio_mutex.unlock()

func push_audio_buffer_bytes(buffer:PackedByteArray) -> void:
	audio_mutex.lock()
	var frames :PackedVector2Array = audio_decoder.gdopus_decode(buffer,buffer.size())
	if audio_frames == null:
		audio_frames = PackedVector2Array()
	audio_frames.append(frames)
	audio_mutex.unlock()
	if !player_audio_thread.is_started():
		player_audio_thread.start(push_audio_thread)

func push_audio_thread():
	while !close_requested:
		if is_instance_valid(audio_playback):
			if audio_playback.can_push_buffer(960):
				if !audio_frames.is_empty():
					audio_mutex.lock()
					var tmpframes :PackedVector2Array= audio_frames.pop_front()
					if audio_frames.size() > 1:
						audio_frames.clear()
					audio_mutex.unlock()
					audio_playback.push_buffer(tmpframes)
					pushed_frames += 1
				elif pushed_frames > 1:
					audio_playback.push_buffer(audio_decoder.gdopus_decode_loss())
					pushed_frames = 0
