class_name InteractionRay
extends rayvisscript

@export var interaction_index :int = 0

@onready var line_3d = $Line3D
var prevHover:Node
var clickedObject:Node
var pressed := false
var clicked := false
var otherray : rayvisscript

var last_point := Vector3()
var last_dist := float()

func _process(_delta):
	if !get_viewport().use_xr:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			var cam = get_viewport().get_camera_3d()
			target_position = (cam.project_local_ray_normal(get_viewport().get_mouse_position()))*10.0
		else:
			target_position = Vector3(0,0,-1000)
	procrayvis()
	if is_colliding():
		line_3d.target = to_local(get_collision_point())
	else:
		line_3d.target = target_position

func _input(event):
	if event is InputEventGesture:
		if is_colliding() and prevHover is Panel3D:
			prevHover.laser_input({
				'action':'custom',
				'position':get_collision_point(),
				'event':event,
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': interaction_index
			})
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				4:
					scrollup()
				5:
					scrolldown()

func _physics_process(_delta):
	var tmpcol
	var point : Vector3
	if last_point.is_zero_approx():
		point = to_global(target_position)
	else:
		point = to_global( target_position.normalized()*( global_position.distance_to(last_point) ) )
	if is_instance_valid(prevHover):
		tmpcol = prevHover
		if is_colliding():
			if get_collider() == prevHover:
				point = get_collision_point()
				last_point = point
			elif !pressed:
				tmpcol = get_collider()
				if "laser_input" in prevHover:
					prevHover.laser_input({
						'hovering': prevHover == tmpcol,
						'pressed': false,
						'position': point,
						'action': 'hover',
						'index': interaction_index
					})
				prevHover = tmpcol
		else:
			if !pressed:
				if "laser_input" in prevHover:
					prevHover.laser_input({
						'hovering': prevHover == tmpcol,
						'pressed': false,
						'position': point,
						'action': 'hover',
						'index': interaction_index
					})
				last_point = Vector3()
				prevHover = null
	elif is_colliding():
		tmpcol = get_collider()
		point = get_collision_point()
		last_point = point
		prevHover = tmpcol
	if is_instance_valid(tmpcol) and "laser_input" in tmpcol:
		if clicked:
			if !pressed:
				_click(tmpcol,point)
			else:
				tmpcol.laser_input({
					'hovering': prevHover == tmpcol,
					'pressed': pressed,
					'position': point,
					'action': 'hover',
					'index': interaction_index
				})
		elif !clicked:
			if pressed:
				_release(tmpcol,point)
			else:
				tmpcol.laser_input({
					'hovering': prevHover == tmpcol,
					'pressed': pressed,
					'position': point,
					'action': 'hover',
					'index': interaction_index
				})

func scrollup():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrollup",
				'index': interaction_index
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrollup",
				'index': interaction_index
				})

func scrolldown():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": true,
				"action": "scrolldown",
				'index': interaction_index
				})
			tmpcol.laser_input({
				"position": get_collision_point(),
				"pressed": false,
				"action": "scrolldown",
				'index': interaction_index
				})

func click():
	clicked = true
func release():
	clicked = false

func _click(target:PhysicsBody3D,point:Vector3):
	if target.has_method("laser_input"):
		target.laser_input({
			"position": point,
			"pressed": true,
			'action': 'click',
			'index': interaction_index
			})
		pressed = true

func _release(target:PhysicsBody3D,point:Vector3):
	if target.has_method("laser_input"):
		target.laser_input({
			"position": point,
			"pressed": false,
			'action': 'click',
			'index': interaction_index
			})
		pressed = false
