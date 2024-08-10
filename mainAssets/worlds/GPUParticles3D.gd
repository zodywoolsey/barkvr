extends GPUParticles3D

@onready var audio_stream_player_3d : AudioStreamPlayer = $"../AudioStreamPlayer"
var process_mat : ParticleProcessMaterial = process_material

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !audio_stream_player_3d:
		audio_stream_player_3d = $"../AudioStreamPlayer"
	if !process_mat:
		process_mat = process_material
	var spec:AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(0,0)
#	print(spec.get_magnitude_for_frequency_range(0, 150))
#	if spec.get_magnitude_for_frequency_range(0, 150).length() > .05:
#		print('go')
#		lifetime = .01
#	else:
#		lifetime = 5
	var a = spec.get_magnitude_for_frequency_range(0,200).length()
	var b = spec.get_magnitude_for_frequency_range(200,400).length()
	var c = spec.get_magnitude_for_frequency_range(400,400).length()
	var d = spec.get_magnitude_for_frequency_range(600,800).length()
	var e = spec.get_magnitude_for_frequency_range(800,1000).length()
	var f = spec.get_magnitude_for_frequency_range(1000,1200).length()
	var g = spec.get_magnitude_for_frequency_range(1200,1400).length()
	var h = spec.get_magnitude_for_frequency_range(1400,1600).length()
	var i = spec.get_magnitude_for_frequency_range(1600,1800).length()
	var tmp = PackedFloat64Array([a,b,c,d,e,f,g,h,i])
	var norm = BarkHelpers.normalize_float64_array(tmp)
	
#	process_mat.color.r = lerpf(
#		process_mat.color.r,
#		norm[0],
#		.2
#	)
#	process_mat.color.g = lerpf(
#		process_mat.color.g,
#		norm[0],
#		.2
#	)
#	process_mat.color.b = lerpf(
#		process_mat.color.b,
#		norm[1],
#		.2
#	)
#	process_mat.damping_min = 0.0
	var bass = BarkHelpers.float64_array_size(PackedFloat64Array([norm[0],norm[1]]))
	var tmpspeed = lerpf(
		speed_scale,
		a*20,
		.6
		)


	if is_nan(tmpspeed):
		tmpspeed = .1
	
	speed_scale = tmpspeed
















