@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("grid menu button","StaticBody3D",preload("res://addons/contextmenu/gridmenu/gridMenuButton.gd"),Texture2D.new())


func _exit_tree():
	remove_custom_type("grid menu button")
