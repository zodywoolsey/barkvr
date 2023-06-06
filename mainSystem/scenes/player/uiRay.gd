extends rayvisscript

@onready var grab_parent = $"../grabParent"
var prevHover

func _process(delta):
	procrayvis(delta)
	if is_colliding():
		vis.show()
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserHover"):
			if prevHover and prevHover != tmpcol:
				prevHover.laserHover({
					'hovering': false,
					'clicked': false,
					'position': get_collision_point()
				})
			else:
				tmpcol.laserHover({
					'hovering': true,
					'clicked': false,
					"position": get_collision_point()
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laserHover"):
				prevHover.laserHover({
					'hovering': false,
					'position': get_collision_point()
				})
	else:
		vis.hide()
		if prevHover and prevHover.has_method("laserHover"):
			prevHover.laserHover({
				'hovering': false,
				'position': get_collision_point()
			})
			prevHover = null

func click():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserClick"):
			tmpcol.laserClick({
				"position": get_collision_point(),
				"pressed": true
				})

func release():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserClick"):
			tmpcol.laserClick({
				"position": get_collision_point(),
				"pressed": false
				})
