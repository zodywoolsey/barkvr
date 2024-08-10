extends Node

## emitted when the grabbed object scale factor setting is chaned
signal grabbed_object_scale_factor_changed(value:float)
## the multiplier that is used for the speed held items should be scaled at
var grabbed_object_scale_factor := 1.1:
	set(value):
		grabbed_object_scale_factor = value
		grabbed_object_scale_factor_changed.emit(grabbed_object_scale_factor)

## emitted when the hand tracking enabled setting is chaned
signal hand_tracking_enabled_changed(value:bool)
## toggles whether hand tracking data is used if it's available
var hand_tracking_enabled := true:
	set(value):
		hand_tracking_enabled = value
		hand_tracking_enabled_changed.emit(hand_tracking_enabled)

## emitted when the inspector update interval setting is changed
signal inspector_update_interval_changed(value:float)
## inspector fields update at a specific interval starting from their instantiation.
## this changes the interval length in seconds. 
var inspector_update_interval := .1:
	set(value):
		inspector_update_interval = value
		inspector_update_interval_changed.emit(inspector_update_interval)
