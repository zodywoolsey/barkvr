extends rayvisscript

var prevHover
@onready var local_player = %CharacterBody3D
var isclick := false

func _process(delta):
	procrayvis()
	if is_colliding():
		var tmpcol = get_collider()
		if is_instance_valid(tmpcol) and tmpcol.has_method("get_collision_layer_value") and tmpcol.get_collision_layer_value(3) and tmpcol.has_method("laserHover"):
			if prevHover and prevHover != tmpcol:
				prevHover.laserHover({
					'hovering': false,
					'clicked': false
				})
			else:
				tmpcol.laserHover({
					'hovering': true,
					'clicked': false,
					"collision_point": get_collision_point()
				})
			prevHover = tmpcol
		else:
			if prevHover and prevHover.has_method("laserHover"):
				prevHover.laserHover({
					'hovering': false
				})
	else:
		if prevHover and prevHover.has_method("laserHover"):
			prevHover.laserHover({
				'hovering': false
			})
			prevHover = null

func click():
	isclick = false
	if is_colliding():
		var tmpcol : Node3D = get_collider()
		if !local_player.selected.has(tmpcol):
			local_player.selected.append(tmpcol)
		else:
			local_player.selected.erase(tmpcol)
