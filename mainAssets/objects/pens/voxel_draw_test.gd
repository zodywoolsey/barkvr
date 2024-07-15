extends Node3D

## distance in meters (godot units) between each voxel point
@export var density : float = 0.1
## material used on the linemesh
@export var mat : Material

@export var chunk_size : int = 50

var points : Dictionary
var mesh_dict : Dictionary
var new_entries :Array[Dictionary] 

var events : Array[Dictionary] = []
var updated_chunks : Array[Vector3] = []
var mesh_semaphore := Semaphore.new()
var dictionary_semaphore := Semaphore.new()
var dictionary_mutex := Mutex.new()
var mesh_thread := Thread.new()
var dictionary_thread := Thread.new()

var mesh : MeshInstance3D
var armesh : ArrayMesh

var strokes :Array[MeshInstance3D] = []

var undo_pressed := false

var meshparent := Node3D.new()

func _ready():
	add_child(meshparent)
	#mesh_thread.start(_update_mesh_thread)
	#dictionary_thread.start(_update_dictionary_thread)
	#BarkHelpers.rejoin_thread_when_finished(mesh_thread)
	#BarkHelpers.rejoin_thread_when_finished(dictionary_thread)

func new_stroke():
	mesh = MeshInstance3D.new()
	armesh = ArrayMesh.new()
	mesh.mesh = armesh
	mesh.material_override = mat
	points.clear()
	strokes.append(mesh)
	meshparent.add_child(mesh)

func _input(event):
	if event is InputEventKey:
		if event.ctrl_pressed and event.physical_keycode == KEY_Z and !strokes.is_empty():
			if event.pressed:
				if !undo_pressed:
					undo_pressed = true
					strokes.pop_back().queue_free()
			else:
				undo_pressed = false

func set_true_nearest(global_point:Vector3):
	var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	var chunk_point :Vector3 = floor(local_point/chunk_size)
	var local_chunk_point :Vector3 = abs(Vector3( int(local_point.x)%chunk_size, int(local_point.y)%chunk_size, int(local_point.z)%chunk_size))
	if chunk_point.x < 0:
		local_chunk_point.x = chunk_size-local_chunk_point.x
	if chunk_point.y < 0:
		local_chunk_point.y = chunk_size-local_chunk_point.y
	if chunk_point.z < 0:
		local_chunk_point.z = chunk_size-local_chunk_point.z
	if chunk_point in points:
		if points[chunk_point] is Dictionary:
			points[ chunk_point ][ local_chunk_point ] = true
	else:
		points[chunk_point] = {}
		points[ chunk_point ][ local_chunk_point ] = true
	#_update_mesh()
	
	if !updated_chunks.has(chunk_point):
		updated_chunks.append(chunk_point)
	#mesh_semaphore.post()
	WorkerThreadPool.add_task(update_meshes)

func set_false_nearest(global_point:Vector3):
	var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	var chunk_point :Vector3 = round(local_point/chunk_size)
	var local_chunk_point :Vector3 = Vector3( int(local_point.x)%chunk_size, int(local_point.y)%chunk_size, int(local_point.z)%chunk_size)
	dictionary_mutex.lock()
	if chunk_point in points:
		if points[chunk_point] is Dictionary:
			points[chunk_point].erase(local_chunk_point)
	dictionary_mutex.unlock()
	#_update_mesh()
	#mesh_semaphore.post()
	WorkerThreadPool.add_task(update_meshes)

func set_true_cube(global_point:Vector3, size:float):
	var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	var radius_int := int( (size/2)*(1/density) )
	for x in radius_int*2:
		for y in radius_int*2:
			for z in radius_int*2:
				var offset := Vector3(x-radius_int,y-radius_int,z-radius_int)
				var chunk_point :Vector3 = round((local_point+offset)/chunk_size)
				var local_chunk_point :Vector3 = Vector3( int(local_point.x+offset.x)%chunk_size, int(local_point.y+offset.y)%chunk_size, int(local_point.z+offset.z)%chunk_size)
				if chunk_point in points:
					if points[chunk_point] is Dictionary:
						points[ chunk_point ][ local_chunk_point ] = true
					else:
						#print('new dict')
						points[chunk_point] = {}
						points[ chunk_point ][ local_chunk_point ] = true
	#points[ round(local_point) ] = true
	#_update_mesh()
	#dictionary_semaphore.post()
	WorkerThreadPool.add_task(update_dictionary)

func set_true_sphere(global_point:Vector3,size:float):
	var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	events.append({"action":"_set_true_sphere", "local_point":local_point,"size":size})
	#dictionary_semaphore.post()
	WorkerThreadPool.add_task(update_dictionary)

func _set_true_sphere(local_point:Vector3, size:float):
	print("sphere")
	var dict:Dictionary
	var start_sphere_time := Time.get_ticks_msec()
	var radius_int := int( ((size/2.0)/density) )
	var chunk_point :Vector3 = floor((local_point)/chunk_size)
	var local_chunk_point :Vector3 = abs(Vector3( int(local_point.x)%chunk_size, int(local_point.y)%chunk_size, int(local_point.z)%chunk_size))
	if chunk_point.x < 0:
		local_chunk_point.x = chunk_size-local_chunk_point.x
	if chunk_point.y < 0:
		local_chunk_point.y = chunk_size-local_chunk_point.y
	if chunk_point.z < 0:
		local_chunk_point.z = chunk_size-local_chunk_point.z
	
	dictionary_mutex.lock()
	var chunk_points :Dictionary
	if chunk_point in points:
		chunk_points = points[chunk_point].duplicate(true)
	dictionary_mutex.unlock()
	await get_tree().process_frame
	for x in radius_int*2:
		for y in radius_int*2:
			for z in radius_int*2:
				var offset := Vector3(x-radius_int,y-radius_int,z-radius_int)
				#if local_point.distance_to(offset+local_point) <= (size/2.0)/density and local_point.distance_to(offset+local_point) > ((size/2.0)/density)*.9:
				if local_chunk_point.distance_to(offset+local_chunk_point) <= (size/2.0)/density:
					#print("local point: "+str(local_point))
					#print("chunk point: "+str(chunk_point))
					#print("local_chunk_point: "+str(local_chunk_point))
					if !chunk_points.is_empty():
						chunk_points[ local_chunk_point+offset ] = true
					else:
						#print('new dict')
						chunk_points = {}
						chunk_points[ local_chunk_point+offset ] = true
	
	if !updated_chunks.has(chunk_point):
		updated_chunks.append(chunk_point)
	dictionary_mutex.lock()
	points[chunk_point] = chunk_points
	dictionary_mutex.unlock()
	
	#print("sphere: "+str(Time.get_ticks_msec()-start_sphere_time))
	#points.merge(dict,true)
	#points[ round(local_point) ] = true
	#_update_mesh()
	#dictionary_semaphore.post()

func set_false_sphere(global_point:Vector3,size:float):
	var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	events.append({"action":"_set_false_sphere", "local_point":local_point,"size":size})
	#dictionary_semaphore.post()
	WorkerThreadPool.add_task(update_dictionary)

func _set_false_sphere(local_point:Vector3, size:float):
	var dict:Dictionary
	#var local_point :Vector3 = (to_local(global_point)*(1.0/density))
	var radius_int := int( (size/2.0)*(1.0/density) )
	var chunk_point :Vector3 = floor((local_point)/chunk_size)
	var local_chunk_point :Vector3 = abs(Vector3( int(local_point.x)%chunk_size, int(local_point.y)%chunk_size, int(local_point.z)%chunk_size))
	if chunk_point.x < 0:
		local_chunk_point.x = chunk_size-local_chunk_point.x
	if chunk_point.y < 0:
		local_chunk_point.y = chunk_size-local_chunk_point.y
	if chunk_point.z < 0:
		local_chunk_point.z = chunk_size-local_chunk_point.z
	for x in radius_int*2:
		for y in radius_int*2:
			for z in radius_int*2:
				var offset := Vector3(x-radius_int,y-radius_int,z-radius_int)
				if local_point.distance_to(offset+local_point) <= (size/2.0)/density:
					if !updated_chunks.has(chunk_point):
						updated_chunks.append(chunk_point)
					dictionary_mutex.lock()
					if chunk_point in points:
						if points[chunk_point] is Dictionary:
							points[ chunk_point ].erase( local_chunk_point+offset )
					dictionary_mutex.unlock()
	
	#points[ round(local_point) ] = true
	#_update_mesh()
	#dictionary_semaphore.post()

func _update_mesh_thread():
	while true:
		update_meshes()

func update_meshes():
	#print(updated_chunks)
	var upd = updated_chunks.duplicate(true)
	updated_chunks.clear()
	for i in upd:
		if i != null:
			_update_mesh(i)

func _update_mesh(part:Vector3=Vector3()):
	var start_meshes_time := Time.get_ticks_msec()
	var vertices = PackedVector3Array()
	if part in points:
		dictionary_mutex.lock()
		var keys :Dictionary = points[part].duplicate(true)
		dictionary_mutex.unlock()
		#print("keys size: "+str(keys[part].size()))
		for a in keys:
			#we're gonna start with cubes
			if !keys.has(a+Vector3(0,0,-1)):
				_add_back_quad(vertices,(part*chunk_size)+a)
			if !keys.has(a+Vector3(0,-1,0)):
				_add_bottom_quad(vertices,(part*chunk_size)+a)
			if !keys.has(a+Vector3(0,1,0)):
				_add_top_quad(vertices,(part*chunk_size)+a)
			if !keys.has(a+Vector3(0,0,1)):
				_add_front_quad(vertices,(part*chunk_size)+a)
			if !keys.has(a+Vector3(-1,0,0)):
				_add_left_quad(vertices,(part*chunk_size)+a)
			if !keys.has(a+Vector3(1,0,0)):
				_add_right_quad(vertices,(part*chunk_size)+a)
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		#arrays[Mesh.ARRAY_TANGENT] = []
		
		if part not in mesh_dict:
			mesh_dict[part] = {'amesh':ArrayMesh.new(),'meshin':MeshInstance3D.new()}
			mesh_dict[part].meshin.material_override = mat
			meshparent.call_deferred("add_child",mesh_dict[part].meshin)
		mesh_dict[part].amesh.clear_surfaces()
		mesh_dict[part].amesh
		mesh_dict[part].amesh.call_deferred("add_surface_from_arrays",Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh_dict[part].meshin.mesh = mesh_dict[part].amesh
	#print("meshes: "+str(Time.get_ticks_msec()-start_meshes_time))
	# Create the Mesh.
	#armesh.clear_surfaces()
	#armesh.call_deferred("add_surface_from_arrays",Mesh.PRIMITIVE_TRIANGLES, arrays,[],{},536870912)
	#armesh.call_deferred("add_surface_from_arrays",Mesh.PRIMITIVE_TRIANGLES, arrays)

func _update_dictionary_thread():
	while true:
		dictionary_semaphore.wait()
		update_dictionary()

func update_dictionary():
	var start_dict_time := Time.get_ticks_msec()
	if !events.is_empty():
		var l_events := events.duplicate(true)
		events.clear()
		for event in l_events:
			match event.action:
				"_set_true_sphere":
					_set_true_sphere(event.local_point,event.size)
				"_set_false_sphere":
					_set_false_sphere(event.local_point,event.size)
			#mesh_semaphore.post()
			WorkerThreadPool.add_task(update_meshes)
	
	#print("dictionaries: "+str(Time.get_ticks_msec()-start_dict_time))

func _add_cube_to_array(array:PackedVector3Array, pos:Vector3):
	#these need to be tris, so here we go
	# for reference i am thinking of front as z+, right as x+, and up as y+
	var offset := Vector3()
	var ofs := density/2.0
	_add_back_quad(array,pos)
	_add_bottom_quad(array,pos)
	_add_front_quad(array,pos)
	_add_left_quad(array,pos)
	_add_right_quad(array,pos)

func _add_left_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# bottom left tri
	offset = Vector3(-ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	# top left tri
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,ofs,ofs)
	array.append((pos*density)+offset)

func _add_right_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# bottom right tri
	offset = Vector3(ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)
	# top right tri
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,-ofs,-ofs)
	array.append((pos*density)+offset)

func _add_back_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# bottom back tri
	offset = Vector3(ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	# top back tri
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,ofs,-ofs)
	array.append((pos*density)+offset)

func _add_front_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# bottom front tri
	offset = Vector3(-ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	# top front tri
	offset = Vector3(-ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,ofs)
	array.append((pos*density)+offset)

func _add_top_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# top back tri
	offset = Vector3(-ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,ofs,ofs)
	array.append((pos*density)+offset)
	# top front tri
	offset = Vector3(-ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,ofs,ofs)
	array.append((pos*density)+offset)

func _add_bottom_quad(array:PackedVector3Array, pos:Vector3):
	var offset := Vector3()
	var ofs := density/2.0
	# bottom back tri
	offset = Vector3(-ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	# bottom front tri
	offset = Vector3(ofs,-ofs,ofs)
	array.append((pos*density)+offset)
	offset = Vector3(ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
	offset = Vector3(-ofs,-ofs,-ofs)
	array.append((pos*density)+offset)
