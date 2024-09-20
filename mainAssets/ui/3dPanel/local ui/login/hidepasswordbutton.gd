extends Button

func _pressed() -> void:
	var cparent :Node = get_parent()
	if (cparent is LineEdit or cparent is TextEdit) and ("secret" in cparent and cparent.secret is bool):
		cparent.secret = !cparent.secret
