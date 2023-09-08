extends rayvisscript

@onready var grab_parent = $"../grabParent"
@onready var label = $"../../../../Label"
var prevHover
var isclick := false
var isrelease := false
var currentAction := ""
var hovertimer := 0.0

func _process(delta):
	procrayvis(delta)
	if Input.is_action_just_released("scrollup"):
		scrollup()
func _physics_process(delta):
	currentAction = ""
	var actioncount = 0
	hovertimer += delta
	if isclick:
		click()
		currentAction += " click"
	elif isrelease:
		release()
		currentAction += " release"
	else:
		currentAction += " notclick"
		if is_colliding():
			currentAction += " hover"
			vis.show()
			var tmpcol = get_collider()
			if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserHover"):
				hovertimer = 0.0
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
	label.text = currentAction
#	print(currentAction)

func scrollup():
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserInput"):
			tmpcol.laserInput({
				"position": get_collision_point(),
				"pressed": true
				})
			print('ui click')

func click():
	isclick = false
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserClick"):
			tmpcol.laserClick({
				"position": get_collision_point(),
				"pressed": true
				})
			print('ui click')

func release():
	isrelease = false
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserClick"):
			tmpcol.laserClick({
				"position": get_collision_point(),
				"pressed": false
				})
