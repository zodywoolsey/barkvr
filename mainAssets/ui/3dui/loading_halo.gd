@tool
extends Node3D
@onready var animation_player = $MeshInstance3D/AnimationPlayer
@onready var animation_player2 = $MeshInstance3D2/AnimationPlayer
@onready var animation_player3 = $MeshInstance3D3/AnimationPlayer
@onready var animation_player4 = $MeshInstance3D4/AnimationPlayer

func _ready():
	animation_player.play("rotate")
	animation_player2.play("rotate")
	animation_player3.play("rotate")
	animation_player4.play("rotate")
