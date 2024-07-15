extends Node

signal grabbed_object_scale_factor_changed(value:float)
var grabbed_object_scale_factor := 1.1:
	set(value):
		grabbed_object_scale_factor = value
		grabbed_object_scale_factor_changed.emit(grabbed_object_scale_factor)

signal hand_tracking_enabled_changed(value:bool)
var hand_tracking_enabled := true:
	set(value):
		hand_tracking_enabled = value
		hand_tracking_enabled_changed.emit(hand_tracking_enabled)
