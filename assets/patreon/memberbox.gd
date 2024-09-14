extends PanelContainer
@onready var label: Label = %Label
var effects := "[rainbow freq=.1 sat=.6][wave amp=50 freq=1][center][font_size=42]"
var text :String:
	set(val):
		label.text = val
		text = val
