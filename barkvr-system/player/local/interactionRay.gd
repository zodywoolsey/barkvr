## custom raycasting tool made in gdscript so we can force the interaction
## layers to work correctly
##
## this class is the laser that lets you touch things in barkvr.[br]
## with this class, we can set and check multiple physics layers so that if a user
## is pointing at an inspector, they don't accidentally click an object behind it[br]
## it functions as a drop-in-replacement for the Raycast3D node but is more relaible
## since this avoids some weird engine quirks with the Raycast3D node.
class_name InteractionRay
extends Node3D

## holder for the rayvis node used for drawing the 3d cursor
@onready var vis: Node3D = $rayvis

## global position we want to put the rayvis cursor at
var vispos := Vector3():
	set(val):
		vispos = val
		vis.target = vispos

## tracks the previous Node that was hovered
var prevHover:Node
## tracks the Node we clicked on in the last iteration
var prevPressed:Node
## tracks whether the current laser input is pressed down or not
var pressed := false

## holder variables for when we automatically switch to touch input mode
var using_touch := false
## timer to wait after releasing a tap to return to the normal input style
var touch_timer := Timer.new()

## tracks the global collision point from the previous iteration
var last_point := Vector3()

# here we make holders to keep the collision point and normal since godot's planes are annoying
# and we can very easily calculate this using only the collision origin and normal and some math.
## track the point last pressed if the user hasn't released yet (look above in code for why)
var last_plane_origin := Vector3()
## track the normal last pressed if the user hasn't released yet (look above in code for why)
var last_plane_normal := Vector3()

@export_category("interaction ray options") ## INTERACTION OPTIONS

## allows us to change the input event device index. this helps differntiate
## between left (0), right (1), and more
@export var interaction_index :int = 0

## this options forces the raycast from position to always be at the origin
## of this raycasts parent node
@export var stay_at_parent_origin: bool = true:
	set(val):
		stay_at_parent_origin = val
		if val:
			position = Vector3()

@export_category("raycast options") ## RAYCAST OPTIONS

## set whether the node should cast a ray every frame or not
@export var enabled := true

## sets whether the ray should follow the mouse cursor position
## intended to easily keep the target aligned with controllers
@export var follow_mouse := true:
	set(val):
		follow_mouse = val
		if vis and "mouse_cursor" in vis:
			vis.mouse_cursor = val

## enables smoothing which applys a lerp to the
## target position to smooth out jittery controller
## movements when aiming at things
@export var smoothing_enabled := false:
	get:
		var settings_instance : SettingsSingleton = SettingsSingleton.instance
		if "laser_smoothing" in settings_instance and smoothing_enabled != settings_instance.laser_smoothing:
			smoothing_enabled = settings_instance.laser_smoothing
		return smoothing_enabled

## this controls the speed at which the lerp function
## interpolates toward the new target point
@export var smoothing_speed := .3:
	get:
		var settings_instance : SettingsSingleton = SettingsSingleton.instance
		if "laser_smoothing_speed" in settings_instance and smoothing_speed != settings_instance.laser_smoothing_speed:
			smoothing_speed = settings_instance.laser_smoothing_speed
		return smoothing_speed

## used to track previous position the raycast casted to
## so we can use it as the `from` in the lerpf for smoothing
var smooth_raycast_position := Vector3()

## only works if `enabled = true`
## sets whether the raycast being run every frame should run on
## the process loop (true) or the physics_process loop (false)
@export var query_on_process := false:
	set(val):
		query_on_process = val
		set_process(val)
		set_physics_process(!val)

## the global position the raycast will query to 
## for collisions the start position is always
## the current global position of the node itself
## (this can be made into a local position if
## `target_position_is_local = true`
@export var target_position := Vector3(0,0,-1):
	get:
		if target_position_is_local and is_inside_tree():
			return to_global(target_position)
		return target_position

## self explanatory, but if this is true, then when the target_position is set
## we will assume we need to convert it from local space to global space
@export var target_position_is_local := true

## a list of RIDs that the raycast query will
## exclude when checking for collisions
var query_exceptions : Array[RID]

## a list of CollisionObject3D nodes to be excluded
## when the raycast queries for collisions 
## (this is mostly an editor helper so you can set
## excluded nodes in the editor)
@export var query_exception_nodes : Array[CollisionObject3D]:
	set(val):
		query_exception_nodes = val
		for i : CollisionObject3D in val:
			if i and i.get_rid() not in query_exceptions:
				query_exceptions.append(i.get_rid())

## the collision layers the ui raycast should collide with
@export_flags_3d_physics var private_ui_collision_layers : int

## the collision layers the ui raycast should collide with
@export_flags_3d_physics var edit_ui_collision_layers : int

## the collision layers the world raycast should collide with
@export_flags_3d_physics var world_collision_layers : int

## Dictionary to keep the data from the raycast query results
## and assign them to the helper values to make it close to 
## a drop-in for raycast3d nodes
var query_collision_data := Dictionary():
	set(val):
		query_collision_data = val
		if query_collision_data.is_empty() or !query_collision_data:
			query_collider = null
			query_collider_id = -1
			query_normal = Vector3()
			query_position = Vector3()
			query_face_index = -1
			query_rid = RID()
			query_shape = -1
			query_is_colliding = false
		else:
			query_collider = query_collision_data["collider"]
			query_collider_id = query_collision_data["collider_id"]
			query_normal = query_collision_data["normal"]
			query_position = query_collision_data["position"]
			query_face_index = query_collision_data["face_index"]
			query_rid = query_collision_data["rid"]
			query_shape = query_collision_data["shape"]
			query_is_colliding = true
## the collider that is currently hit
var query_collider : Node
## the collider id that is currently hit
var query_collider_id : int
## the normal of the current collision (global)
var query_normal : Vector3
## the position of the current collision point (global)
var query_position : Vector3
## the index of the face in the collision shape currently hit
var query_face_index : int
## the rid of the collision shape currently hit
var query_rid : RID
## uhh, idk actually
var query_shape : int
## true if the ray is intersecting something
var query_is_colliding : bool

## returns the query position from the last raycast (gloabl coordiantes) (query_position)
func get_collision_point() -> Vector3:
	return query_position

## returns whether the ray is colliding as of last proc (query_is_colliding)
func is_colliding() -> bool:
	return query_is_colliding

## returns the currently collided collider (query_collider)
func get_collider() -> CollisionObject3D:
	return query_collider

## returns the current collision normal (query_normal)
func get_collision_normal() -> Vector3:
	return query_normal

## allows us to add a new collider to the exceptions
func add_exception(node : CollisionObject3D) -> void:
	if node not in query_exception_nodes:
		query_exception_nodes.append(node)

## allows us to remove a collider from the exception list
func remove_exception(node : CollisionObject3D) -> void:
	if node in query_exception_nodes:
		query_exception_nodes.erase(node)
	var node_rid : RID = node.get_rid()
	remove_exception_rid(node_rid)

## allows us to add an excepted collider by rid to the exceptions list
func add_exception_rid(rid : RID) -> void:
	if !query_exceptions.has(rid):
		query_exceptions.append(rid)
		
## allows us to remove an excepted collider by rid from the exceptions list
func remove_exception_rid(rid : RID) -> void:
	if query_exceptions.has(rid):
		query_exceptions.erase(rid)

func _ready() -> void:
	# reset some vars to fire the setter functions
	stay_at_parent_origin = stay_at_parent_origin
	follow_mouse = follow_mouse
	query_on_process = query_on_process
	# since timers are nodes, we gotta add it as a child here
	add_child(touch_timer)
	# this makes it automatically reset the touch value when it runs out 
	# so we don't have to do this elsewhere in code
	touch_timer.timeout.connect(func():
		using_touch = false
		)

## THIS DOESN'T WORK RN BTW
#func _process(_delta):
	#if enabled:
		#query_raycast()
		## run the interaction function
		#interact()

func _physics_process(_delta: float) -> void:
	if enabled:
		query_raycast()
		# run the interaction function
		interact()

## create holder variables for `query_raycast` to save on performance
var physspace_holder : PhysicsDirectSpaceState3D:
	get:
		if is_instance_valid(physspace_holder): return physspace_holder
		if is_inside_tree():
			physspace_holder = get_world_3d().direct_space_state
		return physspace_holder

var rayquery_holder : PhysicsRayQueryParameters3D
var was_previously_planar : bool = false
## runs the physics query for the raycast
## this now uses 3 raycasts to enforce a selection bias
## on what object is being interacted with (system/private ui, world ui, world objects)
func query_raycast() -> Dictionary:
	if stay_at_parent_origin:
		position = Vector3()
	vispos = query_position
	# if the user is holding a button we switch to planar projection mode
	if pressed:
			# create a plane to check for the intersection much cheaper than calculating ourself
			var ray_intersects_plane_at = Plane(last_plane_normal,last_plane_origin).intersects_ray(global_position, target_position)
			# since we are just reusing the same smooth position variable as the other smoothing code
			# we need to track whether this is the first iteration where we are using the plane 
			# projection instead of the physics raycast so we can snap it to the collided position
			# instead of letting it lerp all the way from the target_position which is often
			# very very far away. if we didn't do this, the cursor jolts to the target_position
			# and *then* lerps to where it's supposed to be which causes all kinds of interaction 
			# issues
			if !was_previously_planar:
				smooth_raycast_position = query_position
			# if smoothing is enabled then we lerp from the last smoothed position to the new target
			if smoothing_enabled:
				smooth_raycast_position = smooth_raycast_position.lerp(
					ray_intersects_plane_at,
					smoothing_speed*get_process_delta_time()
				)
			# update the relevant data so we can pretend that the laser is actually colliding with
			# the object that we started clicking when we entered planar projection mode
			query_collision_data.position = ray_intersects_plane_at if !smoothing_enabled else smooth_raycast_position
			query_position = ray_intersects_plane_at if !smoothing_enabled else smooth_raycast_position
			was_previously_planar = true
			# we then want to return so we don't have to even run any of the code below
			return query_collision_data
	# otherwise we perform the raycast as normal
	else:
		# we update the plane data here to ensure that it's fully valid, even
		# though it will be one iteration late, this eliminates some weird 
		# ordering issues that was causing the planar projection to not work
		last_plane_normal = query_normal
		last_plane_origin = query_position
		# reset the collision data variable so it returns empty when there is not collision
		query_collision_data = Dictionary()
		was_previously_planar = false
	
	# if we don't have an existing query params object to use, then create one
	if !is_instance_valid(rayquery_holder):
		rayquery_holder = PhysicsRayQueryParameters3D.new()
	# set the from to be the origin of wherever this node is
	rayquery_holder.from = global_position
	
	# if laser smoothing is enabled we need to...
	if smoothing_enabled:
		# lerp between where we are pointing and where we just were
		# TODO: we should probably make it calculate it's own delta so it can behave consistently
		smooth_raycast_position = smooth_raycast_position.lerp(
			target_position,
			smoothing_speed*get_process_delta_time()
		)
		rayquery_holder.to = smooth_raycast_position
	# if smoothing isn't enabled...
	else:
		# just go where we are pointing
		rayquery_holder.to = target_position
	
	# now we set our excludes, this allows the intersection calls below to ignore certain colliders
	# this is useful for if the player's collider blocks the ray, thus causing broken interactions
	rayquery_holder.exclude = query_exceptions
	# now for actually checking for intersections
	# we start by querying for anything on the private ui layer
	rayquery_holder.collision_mask = private_ui_collision_layers
	
	# update holder variable so it has the latest state
	if query_on_process and !physspace_holder:
		await get_tree().physics_frame
	physspace_holder = get_world_3d().direct_space_state
	query_collision_data = physspace_holder.intersect_ray(rayquery_holder)
	# if we get data back from the intersection check, then we return it
	if query_collision_data:
		return query_collision_data
	# if no get data back then go next layer
	rayquery_holder.collision_mask = edit_ui_collision_layers
	query_collision_data = physspace_holder.intersect_ray(rayquery_holder)
	# if we get data back from the intersection check, then we return it
	if query_collision_data:
		return query_collision_data
	# if no get data back then go next layer
	rayquery_holder.collision_mask = world_collision_layers
	query_collision_data = physspace_holder.intersect_ray(rayquery_holder)
	# return it anyway because if it's empty, then we know we hit nothing
	return query_collision_data

## this is the function that actually causes the ray to do an interaction
## 
## TODO: this is a piece of shit and needs to be rewritten holy fuck, not gonna
## bother adding comments to this because it just doesn't deserve it. if you have
## Qs then ask zodie
func interact() -> void:
	_place_grabbed_nodes.call_deferred()
	var tmpcol
	var point : Vector3
	if is_instance_valid(prevHover):
		tmpcol = prevHover
		if query_is_colliding:
			if query_collider == prevHover:
				point = query_position
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
				#print_debug("does this plane look right?\n", last_collider_plane.get_center(), "\n", get_collision_point(), "\n", get_collision_normal())
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
		last_plane_normal = get_collision_normal()
		last_plane_origin = get_collision_point()
		#print_debug("does this plane look right?\n", last_collider_plane.get_center(), "\n", get_collision_point(), "\n", get_collision_normal())
		#print_debug("does the collision point exist in the plane??\n", last_collider_plane.has_point(get_collision_point()))
	if is_instance_valid(tmpcol) and "laser_input" in tmpcol:
		tmpcol.laser_input({
			'hovering': prevHover == tmpcol,
			'pressed': pressed,
			'position': point,
			'action': 'hover',
			'index': interaction_index
		})

## here we use the input method to capture any relevant input device stuff
## this is basically only for flat mode inputs
func _input(event):
	# reset the using touch option until we know whether we are still using touch or not
	using_touch = false
	# if we are told to follow the mouse inputs and the user is actually touching the screen
	# then we want to switch to using touch mode
	if follow_mouse and event is InputEventScreenTouch or event is InputEventScreenDrag:
		using_touch = true
		# this updates the raycast target position so it aligns with where the user is touching
		target_position = to_local(get_viewport().get_camera_3d().project_position(event.position,10000))
	# if we get a gesture, we just wanna pass it on through to the laser_input compatible object
	# this allows us to use nice features like pinch and drag as the engine gets them instead
	# of shimming them in some weird way. 
	if event is InputEventGesture:
		if is_colliding() and prevHover is Panel3D:
			prevHover.laser_input({
				'action':'custom',
				'position':get_collision_point(),
				'event':event,
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': -1
			})
	# if we are told to follow the mouse and we just got a mouse input event
	if follow_mouse and event is InputEventMouse:
		# if we aren't in vr... (note, this function assumes that `target_position_is_local = true`)
		if !get_viewport().use_xr and !using_touch:
			# and the mouse is not captured by the window...
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				# get the current viewport's camera and project a ray
				# from the camera based on the cursor position
				var cam = get_viewport().get_camera_3d()
				target_position = to_local(cam.project_position(get_viewport().get_mouse_position(),10000))
			# and if the mouse *is* captured by the window...
			else:
				# set the target_position to be very far straight ahead
				# TODO: make the target position distance a setting
				target_position = Vector3(0,0,-1000000000.0)
		# here, we check for scrolling since those inputs are a little weird
		# and we have a shim for them to behave correctly
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				4:
					scrollup()
				5:
					scrolldown()
	# if the user starts directing inputs with a gamepad, we wanna snap
	# the raycast target to the center of the screen for good measure
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var cam = get_viewport().get_camera_3d()
		target_position = to_local(cam.project_position(get_viewport().size/2,10000))

## sends a scroll up event to the object we are currently interacting with
## we have to send a press and release because that is what the input system expects
func scrollup():
	if query_is_colliding or prevHover:
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

## sends a scroll down event to the object we are currently interacting with
## we have to send a press and release because that is what the input system expects
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

## sends a left mouse click to the object we are currently interacting with
func click():
	LocalGlobals.playerreleaseuifocus.emit()
	if is_colliding():
		var tmpcol = get_collider()
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": query_position,
				"pressed": true,
				'action': 'click',
				'index': interaction_index
				})
			pressed = true
			prevPressed = tmpcol

## sends a left mouse button release to the object we are currently interacting with
func release():
	var tmpcol = get_collider() if is_colliding() and !prevPressed else prevPressed
	if tmpcol:
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				"position": query_position,
				"pressed": false,
				'action': 'click',
				'index': interaction_index
				})
			pressed = false
	prevPressed = null

## this allows us to forward a custom event to the object we are currently interacting with
func fwd_event(event:InputEvent):
	var tmpcol = get_collider() if is_colliding() and !prevPressed else prevPressed
	if tmpcol:
		if tmpcol.has_method("laser_input"):
			tmpcol.laser_input({
				'action':'custom',
				'position':get_collision_point(),
				'event':event,
				'ray_origin': global_position,
				'ray_direction': to_global(target_position),
				'index': -1
				})
			#pressed = false
	#prevPressed = null

### GRABBING LOGIC ###

class GrabbedNode3D:
	## accepts a target node and returns the GrabbedNode3D for the target
	static func create_from_target(new_target: Node3D) -> GrabbedNode3D:
		var tmp := GrabbedNode3D.new()
		tmp.target = new_target
		return tmp
	
	## accepts a target node, the laser global position, and the laser local position (local to the node being grabbed)
	## and returns a setup GrabbedNode3D based on that data. this allows us to track
	## the laser offsets for more intuitive interaction (aka: the node doesn't have to 
	## align it's origin with the goal position this way)
	static func create_from_target_and_laser_positions(new_target: Node3D,\
		current_laser_global_position: Vector3,\
		current_laser_local_position := Vector3()) -> GrabbedNode3D:
		var tmp := GrabbedNode3D.new()
		tmp.target = new_target
		tmp.start_target_offset_position = current_laser_global_position - new_target.global_position
		tmp.start_local_laser_position = current_laser_local_position
		return tmp
	## the node subject to this grab
	##[br] the setter here automatically grabs the initial transform
	var target : Node3D:
		set(val):
			target = val
			if is_instance_valid(val):
				start_global_position = target.global_position
				last_global_position = target.global_position
				start_global_rotation = target.global_rotation
	
	## update the transforms of the target node, we do this here so it is self 
	## managing
	func move_target(goal_global_position: Vector3, goal_global_rotation: Vector3, delta: float):
		if is_smooth_transform:
			goal_global_position = lerp(last_global_position, goal_global_position-start_target_offset_position, smooth_transform_speed * delta)
		target.global_position = goal_global_position
		last_global_position = target.global_position
	
	## is transform smoothing enabled?
	var is_smooth_transform : bool = true
	## smooth transform speed
	var smooth_transform_speed : float = 10.0
	## hold the previous global position for smoothing
	var last_global_position : Vector3
	## capture the initial position so we can revert if the user cancels
	var start_global_position : Vector3
	## capture the initial rotation so we can revert if the user cancels
	var start_global_rotation : Vector3
	## capture the collision position in local space to use in generating the goal
	## (relative to the laser, not the object)
	var start_local_laser_position : Vector3
	## capture the offset of the initial collision from the target's origin 
	## so we can use it to offset the center of the grabbed node
	## (relative to the targegt node, not the laser)
	var start_target_offset_position : Vector3
	## the transform we want the target to have now
	var goal_transform_3d : Transform3D = Transform3D()

## track all the nodes we have grabbed
var grabbed_nodes : Dictionary[int, GrabbedNode3D] = {}

func grab(target:Node=null):
	if !is_instance_valid(target) and is_colliding():
		target = get_collider()
	if target is Node3D:
		grabbed_nodes[target.get_instance_id()] = GrabbedNode3D.\
		create_from_target_and_laser_positions(\
			target,\
			get_collision_point(),\
			to_local( get_collision_point() )\
		)
		return
	if target is Node2D:
		pass

## ungrabs, not much to say here lol
func release_grab(target:Node=null):
	# if no target was passed in, clear all grabbed nodes
	if target == null:
		grabbed_nodes.clear()
	
	# if the instance is valid, find and remove it from the dictionary
	if is_instance_valid(target) and target.get_instance_id() in grabbed_nodes:
		grabbed_nodes.erase(target.get_instance_id())

## move the grabbed nodes to the goal transform
func _place_grabbed_nodes():
	# TODO: use goal and start offset to translate the grabbed nodes
	for grabbed_node : GrabbedNode3D in grabbed_nodes.values():
		grabbed_node.move_target(to_global(grabbed_node.start_local_laser_position), Vector3(), get_process_delta_time())
