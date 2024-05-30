extends rayvisscript

@onready var grab_parent = $"../grabParent"
@onready var line_3d = $Line3D
var prevHover:Node
var clickedObject:Node
var pressed := false
var otherray : rayvisscript

var last_pos := Vector3()

func _process(_delta):
	procrayvis()
	if is_colliding():
		line_3d.target = to_local(get_collision_point())
	else:
		line_3d.target = target_position

func _input(event):
	if event is InputEventPanGesture:
		if is_colliding() and prevHover is Panel3D:
			prevHover.laser_input({
				'action':'custom',
				'position':get_collision_point(),
				'event':event,
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
			})
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==4:
			scrollup()
		elif event.pressed and event.button_index==5:
			scrolldown()

func _physics_process(_delta):
	if is_colliding():
		vis.show()
		line_3d.show()
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			if prevHover and prevHover != tmpcol:
				prevHover.laser_input({
					'hovering': false,
					'pressed': pressed,
					'position': get_collision_point(),
					"action": "hover",
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
				})
			else:
				tmpcol.laser_input({
					'hovering': true,
					'pressed': pressed,
					"position": get_collision_point(),
					"action": "hover",
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laser_input"):
				prevHover.laser_input({
					'hovering': false,
					'pressed': pressed,
					'position': get_collision_point(),
					"action": "hover",
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
				})
	else:
		vis.hide()
		if prevHover and prevHover.has_method("laser_input") and prevHover.has_method('laser_input'):
			prevHover.laser_input({
				'hovering': false,
				'pressed': pressed,
				'position': get_collision_point(),
				'action': 'hover',
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
			})
			if pressed and prevHover.has_method('laser_input'):
				prevHover.laser_input({
					"position": get_collision_point(),
					"pressed": pressed,
					'action': 'click',
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
					})
			prevHover = null
#	print(currentAction)

func scrollup():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrollup",
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup",
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
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
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown",
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
				})

func click():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			pressed = true
			clickedObject = tmpcol
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": pressed,
				'action': 'click',
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': int(leftside)
				})
	pressed = true

func release():
	if is_instance_valid(clickedObject) and 'laser_input' in clickedObject:
		pressed = false
		clickedObject.laser_input({
			"position": get_collision_point(),
			"pressed": pressed,
			'action': 'click',
			'ray_origin': global_position,
			'ray_direction': to_global(target_position),
			'index': int(leftside)
			})
	else:
		if is_colliding():
			var tmpcol = get_collider()
			if tmpcol.has_method("laser_input"):
				pressed = false
				tmpcol.laser_input({
					"position": get_collision_point(),
					"pressed": pressed,
					'action': 'click',
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
					})
		elif prevHover:
			if prevHover.has_method("laser_input"):
				pressed = false
				prevHover.laser_input({
					"position": get_collision_point(),
					"pressed": pressed,
					'action': 'click',
					'ray_origin': global_position,
					'ray_direction': to_global(target_position),
					'index': int(leftside)
					})
	pressed = false
	clickedObject = null
