extends Control

var target :Node

@onready var item_list = $ItemList

func _ready():
	for cls in ClassDB.get_class_list():
		item_list.add_item(cls)
