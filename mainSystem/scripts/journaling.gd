class_name Bark_Journal
extends Node

var registered_actions: PackedStringArray = [
	'set_parent'
]

var actions: Array[Dictionary] = []

var root: Node

func _ready() -> void:
	_get_root()

func get_actions() -> Array[Dictionary]:
	var tmp := actions.duplicate()
	actions.clear()
	return tmp

func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')

func set_parent(target: NodePath, new_parent: NodePath) -> void:
	check_root()
	var t_node := root.get_node(target)
	var np_node := root.get_node(new_parent)
	t_node.reparent(np_node)
	actions.append({
		'action_name': 'set_parent',
		'target': target,
		'new_parent': new_parent
	})

func delete_node(target: NodePath, recieved := false) -> void:
	check_root()
	var t_node := root.get_node(target)
	t_node.queue_free()
	if !recieved:
		actions.append({
			'action_name': 'delete_node',
			'target': target
		})

func set_property(target: NodePath, prop_name: String, value: Variant, recieved := false) -> void:
	check_root()
	var t_node := root.get_node(target)
	if is_instance_valid(t_node) and prop_name.split(':')[0] in t_node:
		t_node.get_indexed(prop_name)
		t_node.set_indexed(prop_name,value)
		if !recieved:
			actions.append({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value
			})

func take_owner_of_node_and_all_children(node:Node,new_owner:Node):
	set_property(root.get_path_to(node),"owner",new_owner)
	if node.get_child_count() > 0:
		for child in node.get_children():
			take_owner_of_node_and_all_children(child, new_owner)

func net_propagate_node(node_string: String, parent := ^'', node_name := '', recieved := false) -> void:
	check_root()
	if node_name.is_empty():
		node_name = node_string.sha256_text()
	var node = BarkHelpers.var_to_node(node_string)
	if parent:
		root.get_node(parent).add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string,
				'parent': parent
			})
	else:
		root.add_child(node)
		if !recieved:
			actions.append({
				'action_name': 'net_propagate_node',
				'node_string': node_string
			})

## Imports an asset and adds that to the action log unless it was a recieved action.
func import_asset(
	type: String,
	asset_to_import: Variant,
	asset_name := '',
	recieved := false,
	data := {}
) -> void:
	# Make sure root is valid.
	check_root()
	# Generate an asset name if not given.
	if asset_name.is_empty():
		# If we have a string path for the asset import, use that instead.
		if asset_to_import is String:
			asset_name = asset_to_import.split('/')[-1]
		else:
			asset_name = str(Time.get_unix_time_from_system())
	# Get asset content if needed.
	var content := PackedByteArray()
	if type != "res":
		if asset_to_import is PackedByteArray:
			content = asset_to_import
		elif asset_to_import is String:
			content = FileAccess.get_file_as_bytes(asset_to_import)
	# Decide how to import asset based on type.
	# TODO pck support
	match type:
		"glb", "vrm":
			#var thread := Thread.new()
			#thread.start(_import_glb.bind(asset_to_import, asset_name, data))
			#rejoin_thread_when_finished(thread)
			if "position" in data:
				_import_glb(asset_to_import, asset_name, data, data.position)
			else:
				_import_glb(asset_to_import, asset_name, data)
		"res":
			# TODO scenes and resources can't easily be sent to peers because of
			# possible dependencies in other files.
			if "position" in data:
				_import_res(asset_name, asset_to_import, data.position)
			else:
				_import_res(asset_name, asset_to_import)
		"image":
			if "position" in data:
				_import_image(asset_name, content, data.position)
			else:
				_import_image(asset_name, content)
		"file":
			#var thread := Thread.new()
			#thread.start(_import_file.bind(asset_name,content))
			#rejoin_thread_when_finished(thread)
			if "position" in data:
				_import_file(asset_name, content, data.position)
			else:
				_import_file(asset_name, content)
	# Send message to peers.
	if !recieved:
		if type == "res":
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': content,
				'asset_name': asset_name
			})
		else:
			actions.append({
				'action_name': 'import_asset',
				'type': type,
				'asset_to_import': asset_to_import,
				'asset_name': asset_name
			})

func _check_loaded(path: String) -> void:
	match ResourceLoader.load_threaded_get_status(path):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_check_loaded.call_deferred(path)
		ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path)
			if res != null:
				var node = res.instantiate()
				node.position.y = 2.0
				root.add_child(node)


const gltf_document_extension_class = preload("res://addons/vrm/vrm_extension.gd")
const SAVE_DEBUG_GLTFSTATE_RES: bool = false

#COPIED FROM https://github.com/godotengine/godot/blob/c4279fe3e0b27d0f40857c00eece7324a967285f/modules/gltf/gltf_document.cpp#L62
# BECAUSE THIS SHIT IS NOT LOCATED ANYWHERE SENSIBLE IN THE ENGINE!!!!
#define GLTF_IMPORT_GENERATE_TANGENT_ARRAYS 8
#define GLTF_IMPORT_USE_NAMED_SKIN_BINDS 16
#define GLTF_IMPORT_DISCARD_MESHES_AND_MATERIALS 32
#define GLTF_IMPORT_FORCE_DISABLE_MESH_COMPRESSION 64

func _import_glb(content: Variant, asset_name := '', _data := {}, position:Vector3=Vector3(0,0,0)) -> void:
	Thread.set_thread_safety_checks_enabled(false)
	var logging_prefix := asset_name+" : "
	print("Import VRM: " + asset_name + " ----------------------")
	var gltf: GLTFDocument = GLTFDocument.new()
	var flags =\
		EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS+\
		EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS
	var vrm_extension: GLTFDocumentExtension = gltf_document_extension_class.new()
	GLTFDocument.register_gltf_document_extension(vrm_extension, true)
	var state: GLTFState = GLTFState.new()
	# HANDLE_BINARY_EMBED_AS_BASISU crashes on some files in 4.0 and 4.1
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED  # GLTFState.HANDLE_BINARY_EXTRACT_TEXTURES
	var err = gltf.append_from_file(content, state, flags)
	if err != OK:
		GLTFDocument.unregister_gltf_document_extension(vrm_extension)
		return
	for mesh in state.meshes:
			if mesh.mesh.get_surface_lod_count(0) == 0:
				print(logging_prefix+'generating lods')
				mesh.mesh.generate_lods(25,60,[])
		
	var generated_scene = gltf.generate_scene(state)
	if SAVE_DEBUG_GLTFSTATE_RES and content != "":
		if !ResourceLoader.exists(content + ".res"):
			state.take_over_path(content + ".res")
			ResourceSaver.save(state, content + ".res")
	GLTFDocument.unregister_gltf_document_extension(vrm_extension)
	
	_post_import.call_deferred(root, generated_scene, asset_name, position, false)
	
	# OLD IMPORT CODE
	#TODO: remove old import code
	#print(logging_prefix+"loading gltf/glb/vrm of ")
	#var doc := GLTFDocument.new()
	#doc.register_gltf_document_extension(LocalGlobals.VRMC_node_constraint_inst)
	#doc.register_gltf_document_extension(LocalGlobals.VRMC_vrm_inst)
	#doc.register_gltf_document_extension(LocalGlobals.VRMC_springBone_inst)
	#doc.register_gltf_document_extension(LocalGlobals.VRMC_materials_hdr_emissiveMultiplier_inst)
	#doc.register_gltf_document_extension(LocalGlobals.VRMC_materials_mtoon_inst)
	#var state := GLTFState.new()
	#var base_path := ''
	#if 'base_path' in data:
		#base_path = data.base_path
	#var err:int
	#if content is PackedByteArray:
		#err = doc.append_from_buffer(content, base_path, state)
	#elif content is String:
		#err = doc.append_from_file(content, state)
	#if err == OK:
		#for node in state.nodes:
			#var scene_node := state.get_scene_node(0)
		##var scene := Node
		#print(logging_prefix+"loading meshes")
		#for mesh in state.get_meshes():
			#print(logging_prefix+'mesh: '+str(mesh.mesh))
			#
			#print(logging_prefix+'surfaces: '+str(mesh.mesh.get_surface_count()))
			#if mesh.mesh.get_surface_lod_count(0) == 0:
				#print(logging_prefix+'generating lod')
				#mesh.mesh.generate_lods(25,60,[])
			#
		#var scene := doc.generate_scene(state)
		#
		#if root:
			#asset_name += str(Time.get_unix_time_from_system())
		#scene.name = asset_name
##		if scene is Node3D:
##			scene.scale = Vector3(.1,.1,.1)
		#root.call_deferred('add_child', scene)
		##root.add_child(scene)
	#else:
		#Notifyvr.send_notification("error importing gltf document")

## Imports a Godot resource.
func _import_res(_asset_name: String, asset_to_import: Variant, _position:Vector3=Vector3(0,0,0)) -> void:
	# If asset to import is not a path, create a path.
	# Note that this may mean assets might not load for peers.
	if asset_to_import is PackedByteArray:
		# Write the content to a temporary file.
		# TODO cleanup of the file?
		var path := "user://tmp/" + str(str(asset_to_import).hash())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(asset_to_import)
		file.flush()
		file.close()
		asset_to_import = path
	ResourceLoader.load_threaded_request(asset_to_import, '', true, ResourceLoader.CACHE_MODE_IGNORE)
	_check_loaded.call_deferred(asset_to_import)

## Imports an image.
func _import_image(asset_name: String, content: PackedByteArray, position:Vector3=Vector3(0,0,0)) -> void:
	var img := Image.new()
	var err: Error

	if asset_name.ends_with('.jpg') or asset_name.ends_with('.jpeg'):
		err = img.load_jpg_from_buffer(content)
	elif asset_name.ends_with('.png'):
		err = img.load_png_from_buffer(content)
	elif asset_name.ends_with('.bmp'):
		err = img.load_bmp_from_buffer(content)
	elif asset_name.ends_with('.tga'):
		err = img.load_tga_from_buffer(content)
	elif asset_name.ends_with('.webp'):
		err = img.load_webp_from_buffer(content)
	else:
		return

	if err != OK:
		return

	var tex := ImageTexture.create_from_image(img)
	var plane := MeshInstance3D.new()
	var tmpmesh := PlaneMesh.new()
	var tmpmat := StandardMaterial3D.new()
	tmpmesh.size.y = 1.0
	tmpmesh.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpmat.albedo_texture = tex
	tmpmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	tmpmesh.orientation = PlaneMesh.FACE_Z
	plane.mesh = tmpmesh
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	tmpcolshape.size.y = 1.0
	tmpcolshape.size.x = ((tex.get_size()).x/(tex.get_size()).y)
	tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpbody.add_child(plane)
	_post_import.call_deferred(root, tmpbody, asset_name, position, true)


## Imports a file.
func _import_file(asset_name: String, content: PackedByteArray, position:Vector3=Vector3(0,0,0) ) -> void:
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var plane := MeshInstance3D.new()
	#var tmpmesh := PlaneMesh.new()
	var tmpmesh := TextMesh.new()
	tmpmesh.text = asset_name
	tmpmesh.autowrap_mode = TextServer.AUTOWRAP_WORD
	tmpmesh.font_size = 4
	tmpmesh.depth = .01
	#tmpmesh.size = tex.get_size()*.001
	var tmpmat := StandardMaterial3D.new()
	
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := BoxShape3D.new()
	#tmpcolshape.size.x = (tex.get_size()*.001).x
	#tmpcolshape.size.y = (tex.get_size()*.001).y
	tmpcolshape.size = tmpmesh.get_aabb().size
	
	#tmpcolshape.size.z = .001
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2
	
	tmpmat.albedo_texture = tex
	tmpmat.shading_mode = tmpmat.SHADING_MODE_UNSHADED
	tmpmesh.material = tmpmat
	#tmpmesh.orientation = PlaneMesh.FACE_Z
	plane.mesh = tmpmesh
	tmpbody.add_child(plane)
	tmpbody.set_meta("file_bytes",content.compress())
	_post_import.call_deferred(root, tmpbody, asset_name, position, true)

func rejoin_thread_when_finished(thread: Thread) -> void:
	if thread and thread.is_started() and thread.is_alive():
		get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
		return
	thread.wait_to_finish()

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	match action.action_name:
		"net_propagate_node":
			var parent: String = action.get('parent', '')
			net_propagate_node(action.node_string, parent, '', true)
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			import_asset(action.type, action.asset_to_import, '', true)
		"delete_node":
			delete_node(action.target, true)

func _post_import(_root_node:Node,node_to_add:Node,node_name:String,position:Vector3=Vector3(),lookatuser:bool=false):
	check_root()
	root.add_child(node_to_add)
	if lookatuser and node_to_add is Node3D:
		node_to_add.look_at_from_position(position,get_viewport().get_camera_3d().global_position,Vector3.UP,true)
	node_to_add.global_position = position
	node_to_add.name = node_name
	print(node_name)
	# add IK stuff if VRM
	if node_name.ends_with(".vrm"):
		print('attempting ik')
		var quickreniksetup :Node3D = load("res://addons/renik-gdscript/quick_renik_setup.tscn").instantiate()
		node_to_add.add_child(quickreniksetup)
		var skele :Skeleton3D=null
		for i in node_to_add.get_children():
			if skele:
				break
			if i is Skeleton3D:
				skele = i
			elif i.get_child_count() > 0:
				for a in i.get_children():
					if a is Skeleton3D:
						skele = a
		if skele:
			print('found skele')
			quickreniksetup.armature_skeleton = skele
