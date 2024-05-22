class_name LoadingHalo
extends Node3D
@onready var animation_player = $MeshInstance3D/AnimationPlayer
@onready var animation_player3 = $MeshInstance3D3/AnimationPlayer
@onready var halo1 = $MeshInstance3D
@onready var halo2 = $MeshInstance3D3

@onready var label_3d = $textparent/Label3D
@onready var mesh_instance_3d = $textparent/Label3D/MeshInstance3D

var text : String = "":
	set(value):
		text = value
		label_3d.text = "loading:\n"+str(value)
		mesh_instance_3d.detect_size()

func _ready():
	animation_player.play("rotate")
	animation_player3.play("rotate")

func set_wait_for_thread(thread:Thread=null):
	if is_instance_valid(thread):
		_wait_for_thread_and_remove_loader(thread)

func set_wait_for_timer(seconds:float=1.0):
	get_tree().create_timer(seconds,true,false,true).timeout.connect(func():
		self.queue_free()
		)

func _wait_for_thread_and_remove_loader(thread:Thread):
	LocalGlobals
	if thread and thread.is_started() and thread.is_alive():
		get_tree().create_timer(1).timeout.connect(_wait_for_thread_and_remove_loader.bind(thread))
		return
	thread.wait_to_finish()
	_exit()

func _exit():
	var tween := create_tween()
	animation_player.pause()
	animation_player3.pause()
	tween.tween_property(halo1,"rotation_degrees",Vector3(),.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tween.parallel().tween_property(halo2,"rotation_degrees",Vector3(),.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self,"scale",Vector3(),.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
