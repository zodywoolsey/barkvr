extends rayvisscript

@onready var grab_parent = $"../grabParent"
var prevHover
var pressed := false

func _process(delta):
	procrayvis()
	if Input.is_action_just_released("scrollup"):
		scrollup()
	if Input.is_action_just_released("scrolldown"):
		scrolldown()

func _physics_process(delta):
	if is_colliding():
		vis.show()
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			if prevHover and prevHover != tmpcol:
				prevHover.laser_input({
					'hovering': false,
					'pressed': pressed,
					'position': get_collision_point(),
					"action": "hover"
				})
			else:
				tmpcol.laser_input({
					'hovering': true,
					'pressed': pressed,
					"position": get_collision_point(),
					"action": "hover"
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laser_input"):
				prevHover.laser_input({
					'hovering': false,
					'pressed': pressed,
					'position': get_collision_point(),
					"action": "hover"
				})
	else:
		vis.hide()
		if prevHover and prevHover.has_method("laser_input") and prevHover.has_method('laser_input'):
			prevHover.laser_input({
				'hovering': false,
				'pressed': pressed,
				'position': get_collision_point(),
				'action': 'hover'
			})
			if pressed and prevHover.has_method('laser_input'):
				prevHover.laser_input({
					"position": get_collision_point(),
					"pressed": pressed,
					'action': 'click'
					})
			prevHover = null
#	print(currentAction)

func scrollup():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrollup"
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup"
				})

func scrolldown():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrolldown"
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown"
				})

func click():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			pressed = true
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": pressed,
				'action': 'click'
				})
	pressed = true

func release():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			pressed = false
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": pressed,
				'action': 'click'
				})
	elif prevHover:
		if prevHover.has_method("laser_input"):
			pressed = false
			prevHover.laser_input({
				"position": get_collision_point(),
				"pressed": pressed,
				'action': 'click'
				})
	pressed = false
