@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type(
		"Panel3D",
		"StaticBody3D",
		preload("res://addons/Panel3D/3dpanel.gd"),
		load("res://addons/Panel3D/icon.svg")
		)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("Panel3D")
