extends Node

signal grabbed_object_scale_factor_changed(value:float)
var grabbed_object_scale_factor := 1.1:
	set(value):
		grabbed_object_scale_factor_changed.emit(value)
