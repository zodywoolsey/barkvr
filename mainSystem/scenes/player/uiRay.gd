extends rayvisscript

@onready var grab_parent = $"../grabParent"
var prevHover
var pressed := false

func _process(delta):
	procrayvis(delta)
	if Input.is_action_just_released("scrollup"):
		scrollup()
	if Input.is_action_just_released("scrolldown"):
		scrolldown()

func _physics_process(delta):
	if is_colliding():
		vis.show()
		var tmpcol = get_collider()
		if tmpcol.has_method("laserHover"):
			if prevHover and prevHover != tmpcol:
				prevHover.laserInput({
					'hovering': false,
					'pressed': false,
					'position': get_collision_point(),
					"action": "hover"
				})
			else:
				tmpcol.laserInput({
					'hovering': true,
					'pressed': false,
					"position": get_collision_point(),
					"action": "hover"
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laserInput"):
				prevHover.laserInput({
					'hovering': false,
					'position': get_collision_point(),
					"action": "hover"
				})
	else:
		vis.hide()
		if prevHover and prevHover.has_method("laserInput") and prevHover.has_method('laserInput'):
			prevHover.laserInput({
				'hovering': false,
				'position': get_collision_point(),
				'action': 'hover'
			})
			if pressed and prevHover.has_method('laserInput'):
				prevHover.laserInput({
					"position": get_collision_point(),
					"pressed": false,
					'action': 'click'
					})
			prevHover = null
#	print(currentAction)

func scrollup():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserInput"):
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrollup"
				})
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup"
				})

func scrolldown():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserInput"):
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrolldown"
				})
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown"
				})

func click():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserInput"):
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": true,
				'action': 'click'
				})
			pressed = true

func release():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserInput"):
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": false,
				'action': 'click'
				})
			pressed = false
	elif prevHover:
		if prevHover.has_method("laserInput"):
			prevHover.laserInput({
				"position": get_collision_point(),
				"pressed": false,
				'action': 'click'
				})
