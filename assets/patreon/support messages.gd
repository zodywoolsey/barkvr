extends RichTextLabel

var effects := "[rainbow freq=.1 sat=.6][wave amp=50 freq=1][center][font_size=42]"
var messages :Array = [
	"we couldn't do this without you!",
	"thank you for supporting barkvr!!",
	"woof",
	"thank you!!1!!!",
	"supporters!",
	"the people who help make this possible!!",
	"y'all are the best",
	"please consider helping us out like these wonderful critters!"
]

func _ready() -> void:
	get_tree().create_timer(5).timeout.connect(new_text)

func new_text() -> void:
	create_tween().tween_property(self, "text", effects+messages.pick_random(), 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	get_tree().create_timer(5).timeout.connect(new_text)
