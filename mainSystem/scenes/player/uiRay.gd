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
	if is_instance_valid(prevHover) and pressed and prevHover.has_method("laser_input"):
		if is_colliding():
			prevHover.laser_input({
				'hovering': true,
				'pressed': pressed,
				"position": get_collision_point(),
				"action": "hover",
				'index': int(leftside)
			})
		else:
			prevHover.laser_input({
				'hovering': true,
				'pressed': pressed,
				"position": vispos,
				"action": "hover",
				'index': int(leftside)
			})
	elif is_colliding():
		vis.show()
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			if is_instance_valid(prevHover) and prevHover != tmpcol:
				prevHover.laser_input({
					'hovering': false,
					'pressed': false,
					'position': get_collision_point(),
					"action": "hover",
					'index': int(leftside)
				})
			else:
				tmpcol.laser_input({
					'hovering': true,
					'pressed': pressed,
					"position": get_collision_point(),
					"action": "hover",
					'index': int(leftside)
				})
			prevHover = tmpcol
		else:
			if is_instance_valid(prevHover) and prevHover.has_method("laser_input"):
				prevHover.laser_input({
					'hovering': false,
					'pressed': false,
					'position': get_collision_point(),
					"action": "hover",
					'index': int(leftside)
				})
	else:
		vis.hide()
		if is_instance_valid(prevHover) and prevHover.has_method("laser_input"):
			prevHover.laser_input({
				'hovering': false,
				'pressed': false,
				'position': get_collision_point(),
				'action': 'hover',
				'index': int(leftside)
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
				"action": "scrollup",
				'index': int(leftside)
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup",
				'index': int(leftside)
				})

func scrolldown():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrolldown",
				'index': int(leftside)
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown",
				'index': int(leftside)
				})

func click():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			pressed = true
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": pressed,
				'action': 'click',
				'index': int(leftside)
				})
	pressed = true

func release():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			pressed = false
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				'action': 'click',
				'index': int(leftside)
				})
	elif is_instance_valid(prevHover):
		if prevHover.has_method("laser_input"):
			pressed = false
			prevHover.laser_input({
				"position": vispos,
				"pressed": false,
				'action': 'click',
				'index': int(leftside)
				})
	pressed = false
