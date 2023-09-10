@tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("ScrollListContainer", "Container", preload("ScrollListContainer.gd"), preload("icon.png"))

func _exit_tree():
    remove_custom_type("ScrollListContainer")
