class_name Bark_Journal
extends Node

var actions: Array[Dictionary] = []
var undid_actions: Array[Dictionary] = []
var new_actions: Array[Dictionary] = []

var root: Node:
	get:
		if !is_instance_valid(root):
			_get_root()
		return root

var local_root: Node:
	get:
		if !is_instance_valid(local_root):
			local_root = get_tree().root
		return local_root

func is_path_remote(path:NodePath, from_journal_root:bool=true):
	var t_node :Node
	if from_journal_root:
		t_node = root.get_node_or_null(path)
	else:
		t_node = get_tree().root.get_node_or_null(path)
	if t_node != null and root.is_ancestor_of(t_node):
		return true
	return false

func _init():
	print('journal init')

func _ready() -> void:
	check_root()

func _add_action(data:Dictionary, undid:=false) -> void:
	if undid:
		#undid_actions.append(data)
		new_actions.append(data)
	else:
		actions.append(data)
		new_actions.append(data)

func undo_action() -> void:
	check_root()
	if !actions.is_empty():
		var action_to_undo :Dictionary = actions.pop_back()
		print(action_to_undo)
		if action_to_undo and "action_name" in action_to_undo:
			match action_to_undo.action_name:
				'set_property':
					set_property(action_to_undo.target, action_to_undo.prop_name, action_to_undo.previous_value, false, true)
				'delete_node':
					pass
				'add_node':
					pass

func get_actions() -> Array[Dictionary]:
	var tmp := new_actions.duplicate(true)
	new_actions.clear()
	return tmp

func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')

# TODO create function to iterate over the current scene and prepare it for remote syncing
func _prepare_root_for_remote_sync() -> void:
	pass

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

## Adds a node to the scene[br]
## should provide the nodepath for the node that will be the parent of the added
## nodes.[br]
## the nodes dictionary should be a heirarchy that directly reflects the desired
## node heirarchy once added to the scene and have parameters as follows:
## [code] {node_class: "ClassStringForThisNode", properties: ArrayOfPropertyDictionaries, children: ArrayOfChildren}
## [br]the array of property dictionaries should be an array of dictionaries 
## where each dictionary contains {name: "property_name", value: "property_value"}
## [br]the array of children should be an array of nodes with an identical format
## to the example dictionary.
## [br]if you do not wish to change the properties from default you can exclude the properties array
## [br]if you do not wish to have children added to a given node, you can exclude the children array
## [br]node_class is always required
## [br]if you would like to add metadata to the node use "metadata/property_name"
## as the name for the property so it will get parsed as a metadata property
func add_node(parent: NodePath, nodes:Dictionary, recieved := false, undid := false):
	check_root()
	print("journal_add_node")
	var p_node := root.get_node(parent)
	if is_instance_valid(p_node):
		var t_node :Node = _read_add_node_nodes_dict(nodes)
		while p_node.has_node("./"+t_node.name):
			var placeholder_name :String=  str(str(str(nodes.node_class) + str( str(nodes) + str( Time.get_unix_time_from_system() + float(Time.get_ticks_usec()) ))).hash())
			t_node.name = placeholder_name
		p_node.add_child(t_node)
		if !recieved and !undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(t_node),
				'nodes': nodes
			})
		if undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(t_node),
				'nodes': nodes
			},true)

func _read_add_node_nodes_dict(node_dict:Dictionary) -> Node:
	check_root()
	if "node_class" in node_dict and ClassDB.can_instantiate(node_dict.node_class):
		var node = ClassDB.instantiate(node_dict.node_class)
		var node_props = node.get_property_list()
		if "properties" in node_dict and node_dict.properties is Array:
			for prop in node_dict.properties:
				if prop is Dictionary and "name" in prop and "value" in prop:
					if prop.name in node and !(typeof(node[prop.name]) in [TYPE_CALLABLE, TYPE_OBJECT, TYPE_SIGNAL]):
						node[prop.name] = prop.value
					elif prop.name.begins_with('metadata/'):
						node.set_meta(prop.name.trim_prefix("metadata/"), prop.value)
		if node.name:
			var placeholder_name :String= str(str(str(node_dict.node_class) + str( str(node) + str( Time.get_unix_time_from_system() + float(Time.get_ticks_usec()) ))).hash())
			if "properties" in node_dict:
				node_dict.properties.append({"name":"name","value":placeholder_name})
			else:
				node_dict.properties = [{"name":"name","value":placeholder_name}]
			node.name = placeholder_name
		if "children" in node_dict:
			for child in node_dict.children:
				node.add_child(_read_add_node_nodes_dict(child))
				
		return node
	var tmp = Node.new()
	tmp.name = "ERROR"
	return tmp

func delete_node(target: NodePath, recieved := false, undid := false) -> void:
	check_root()
	print(is_path_remote(target))
	var t_node := root.get_node(target)
	var deleted_node_as_packed_scene := PackedScene.new()
	take_owner_of_node_and_all_children(t_node, t_node)
	deleted_node_as_packed_scene.pack(t_node)
	t_node.queue_free()
	if !recieved:
		_add_action({
			'action_name': 'delete_node',
			'target': target,
			'deleted_node': t_node.name#Marshalls.variant_to_base64(deleted_node_as_packed_scene,true)
		})

func set_property(target: NodePath, prop_name: String, value: Variant, recieved := false, undid := false) -> void:
	print(target)
	check_root()
	var t_node := root.get_node(target)
	if is_instance_valid(t_node) and prop_name.split(':')[0] in t_node:
		var previous_value = t_node.get_indexed(prop_name)
		t_node.set_indexed(prop_name,value)
		if !recieved and !undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			})
		if undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			},true)

func take_owner_of_node_and_all_children(node:Node,new_owner:Node):
	check_root()
	node.owner = new_owner
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
	print(type)
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
		elif asset_to_import is Image:
			content = asset_to_import.get_data()
	# Decide how to import asset based on type.
	# TODO pck support
	match type:
		"text":
			_import_text(asset_to_import,asset_to_import, data)
		"glb", "vrm":
			_import_glb(asset_to_import, asset_name, data)
		"res":
			# TODO scenes and resources can't easily be sent to peers because of
			# possible dependencies in other files.
			_import_res(asset_name, asset_to_import, data)
		"image":
			if asset_to_import is Image:
				_import_image_image(asset_name, asset_to_import, data)
			else:
				_import_image_bytes(asset_name, content, data)
		"file":
			_import_file(asset_name, content, data)
		"uri":
			_import_uri(asset_to_import, data)
		"zip":
			_import_zip(asset_name, asset_to_import, data)
		_:
			if "loader" in data:
				data.loader.done('failed')
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

func _import_uri(uri:String, data:Dictionary={}):
	var tmpdir:String = "user://tmp/"+str(hash(uri))
	if !("iterations" in data):
		data.iterations = 0
	if uri.begins_with("http://") or uri.begins_with("https://"):
		if "iterations" in data and data.iterations > 4:
			print("loop while trying to import uri, cancelling import")
			return
		var req := HTTPRequest.new()
		req.download_file = tmpdir
		call_deferred("add_child",req)
		if !req.is_node_ready():
			await req.ready
		Thread.set_thread_safety_checks_enabled(false)
		req.request_completed.connect(_uri_request_completed.bind(req,data,uri))
		Thread.set_thread_safety_checks_enabled(true)
		req.request(uri)

func _uri_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req:HTTPRequest, data:Dictionary, uri:String):
			print('req completed')
			print('response code: '+str(response_code))
			var msg = body.get_string_from_ascii()
			for header in headers:
				if header.begins_with("Content-Type:"):
					print('content')
					print(header.trim_prefix("Content-Type: "))
					var trimmed := header.trim_prefix("Content-Type: ")
					if trimmed.begins_with("image") and !trimmed.contains("gif"):
						print('importing uri image')
						while body.size() < 1:
							if data.iterations > 4:
								return
							data.iterations += 1
							body = (FileAccess.get_file_as_bytes(req.download_file))
						_import_image_bytes(uri, body, data)
						return
			print('uri returned text')
			print('uri: '+uri)
			if uri.contains('.gltf') or uri.contains('.glb'):
				import_asset('glb', req.download_file, uri, false, data)
			elif uri.contains('.vrm'):
				import_asset('vrm',req.download_file, uri, false, data)
			elif uri.contains('.res') or uri.contains('.tres') or uri.contains('.scn') or uri.contains('.tscn'):
				import_asset('res',req.download_file, uri, false, data)
			#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
			elif uri.contains('.pck'):
				import_asset('pck', req.download_file, uri, false, data)
			elif uri.contains('.png') or \
				uri.contains('.jpg') or \
				uri.contains('.jpeg') or \
				uri.contains('.bmp') or \
				uri.contains('.svg') or \
				uri.contains('.tga') or \
				uri.contains('.ktx') or \
				uri.contains('.webp'):
				import_asset('image', req.download_file, uri, false, data)
			else:
				# hit "https://image.thum.io/get/" to grab an image of the website
				if !uri.begins_with("https://image.thum.io/get/"):
					uri = "https://image.thum.io/get/"+uri
				if "iterations" in data:
					data.iterations += 1
				else:
					data.iterations = 1
				print("get preview:\n"+uri)
				_import_uri(uri,data)
				#elif dropped.ends_with(".zip"):
					#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
				#else:
					#import_asset('file', reader.read_file(dropped), asset_name, false, data)
			req.queue_free()

func _import_zip(asset_name:String, asset_path:String, data:Dictionary={}):
	var reader := ZIPReader.new()
	if reader.open(asset_path) == 0:
		for dropped in reader.get_files():
			print('dropped: '+dropped)
			if reader.file_exists(dropped):
				print('is file')
				if dropped.contains('.gltf') or dropped.contains('.glb'):
					import_asset('glb', reader.read_file(dropped), asset_name, false, data)
				elif dropped.contains('.vrm'):
					import_asset('vrm',reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.res') or dropped.ends_with('.tres') or dropped.ends_with('.scn') or dropped.ends_with('.tscn'):
					import_asset('res',reader.read_file(dropped), asset_name, false, data)
				#elif dropped.ends_with('.zip') or dropped.ends_with('.pck'):
				elif dropped.ends_with('.pck'):
					import_asset('pck', reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.png') or \
					dropped.ends_with('.jpg') or \
					dropped.ends_with('.jpeg') or \
					dropped.ends_with('.bmp') or \
					dropped.ends_with('.svg') or \
					dropped.ends_with('.tga') or \
					dropped.ends_with('.ktx') or \
					dropped.ends_with('.webp'):
					import_asset('image', reader.read_file(dropped), asset_name, false, data)
				#elif dropped.ends_with(".zip"):
					#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
				#else:
					#import_asset('file', reader.read_file(dropped), asset_name, false, data)

func _check_loaded(path: String, asset_name:String, data:Dictionary={}, last_time:float=0.0) -> void:
	check_root()
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
		#get_tree().create_timer(1).timeout.connect(_check_loaded.bind(path, asset_name, position))
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		var res := ResourceLoader.load_threaded_get(path)
		if res != null:
			var node = res.instantiate()
			_post_import.call_deferred(root,node,asset_name,data)

#
var gltf_document_extension_class = load("res://addons/vrm/vrm_extension.gd")
const SAVE_DEBUG_GLTFSTATE_RES: bool = false

#COPIED FROM https://github.com/godotengine/godot/blob/c4279fe3e0b27d0f40857c00eece7324a967285f/modules/gltf/gltf_document.cpp#L62
# BECAUSE THIS SHIT IS NOT LOCATED ANYWHERE SENSIBLE IN THE ENGINE!!!!
#define GLTF_IMPORT_GENERATE_TANGENT_ARRAYS 8
#define GLTF_IMPORT_USE_NAMED_SKIN_BINDS 16
#define GLTF_IMPORT_DISCARD_MESHES_AND_MATERIALS 32
#define GLTF_IMPORT_FORCE_DISABLE_MESH_COMPRESSION 64

func _import_glb(content: Variant, asset_name := '', data := {}) -> void:
	print(content)
	check_root()
	#Thread.set_thread_safety_checks_enabled(false)
	var logging_prefix := asset_name+" : "
	print("Import VRM: " + asset_name + " ----------------------")
	var gltf: GLTFDocument = GLTFDocument.new()
	var flags := 16+8
	var vrm_extension: GLTFDocumentExtension = gltf_document_extension_class.new()
	GLTFDocument.register_gltf_document_extension(vrm_extension, true)
	var state: GLTFState = GLTFState.new()
	# HANDLE_BINARY_EMBED_AS_BASISU crashes on some files in 4.0 and 4.1
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED  # GLTFState.HANDLE_BINARY_EXTRACT_TEXTURES
	var err :int
	if content is String:
		err = gltf.append_from_file(content, state, flags)
	elif content is PackedByteArray:
		err = gltf.append_from_buffer(content, '', state, flags)
	if err != OK:
		GLTFDocument.unregister_gltf_document_extension(vrm_extension)
		return
	for mesh in state.meshes:
			if mesh.mesh.get_surface_lod_count(0) == 0:
				print(logging_prefix+'generating lods')
				mesh.mesh.generate_lods(25,60,[])
	print("generated scene")
	var generated_scene = gltf.generate_scene(state)
	#if SAVE_DEBUG_GLTFSTATE_RES and content != "":
		#if !ResourceLoader.exists(content + ".res"):
			#state.take_over_path(content + ".res")
			#ResourceSaver.save(state, content + ".res")
	GLTFDocument.unregister_gltf_document_extension(vrm_extension)
	print('post importing glb/gltf/vrm')
	_post_import.call_deferred(root, generated_scene, asset_name, data, false)

## Imports a Godot resource.
func _import_res(asset_name: String, asset_to_import: Variant, data:Dictionary={}) -> void:
	check_root()
	# If asset to import is not a path, create a path.
	# Note that this may mean assets might not load for peers.
	if asset_to_import is PackedByteArray:
		# Write the content to a temporary file.
		# TODO cleanup of the file?
		var path := "user://tmp/" + str(str(asset_to_import).hash()) + ".res"
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(asset_to_import)
		file.flush()
		file.close()
		asset_to_import = path
	ResourceLoader.set_abort_on_missing_resources(false)
	ResourceLoader.load_threaded_request(asset_to_import, '', true, ResourceLoader.CACHE_MODE_IGNORE)
	_check_loaded(asset_to_import,asset_name,data)

## Imports an image from bytes.
func _import_image_bytes(asset_name: String, content: PackedByteArray, data:Dictionary={}) -> void:
	check_root()
	var img := Image.new()
	var err: Error
	
	err = img.load_webp_from_buffer(content)
	if err != OK:
		err = img.load_png_from_buffer(content)
	if err != OK:
		err = img.load_bmp_from_buffer(content)
	if err != OK:
		err = img.load_tga_from_buffer(content)
	if err != OK:
		err = img.load_jpg_from_buffer(content)
	if err != OK:
		err = img.load_svg_from_buffer(content)
	if err != OK:
		err = img.load_ktx_from_buffer(content)
	
	if err != OK:
		if "loader" in data:
			data.loader.done('failed')
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, true)


## Imports an image from an existing image resource.
func _import_image_image(asset_name: String, img: Image, data:Dictionary={}) -> void:
	check_root()
	
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, true)

## Imports some text.
func _import_text(asset_name: String, content: String, data:Dictionary={} ) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = asset_name.hash()
	tex.height = 100
	tex.width = 100
	tex.noise = noise
	var mesh := MeshInstance3D.new()
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
	mesh.mesh = tmpmesh
	tmpbody.add_child(mesh)
	_post_import.call_deferred(root, tmpbody, asset_name, data, true)

## Imports a file.
func _import_file(asset_name: String, content: PackedByteArray, data:Dictionary={} ) -> void:
	check_root()
	var tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.seed = asset_name.hash()
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, true)

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	check_root()
	match action.action_name:
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			import_asset(action.type, action.asset_to_import, '', true)
		"delete_node":
			delete_node(action.target, true)
		"add_node":
			add_node(action.parent,action.nodes,true)

func _post_import(_root_node:Node,node_to_add:Node,node_name:String,data:Dictionary={},lookatuser:bool=false):
	check_root()
	var position = Vector3()
	if "position" in data:
		position = data.position
	var scale = 1.0
	if "scale" in data:
		scale = data.scale
	root.add_child(node_to_add)
	if node_to_add is Node3D:
		if lookatuser:
			node_to_add.look_at_from_position(position,get_viewport().get_camera_3d().global_position,Vector3.UP,true)
		node_to_add.global_position = position
		node_to_add.scale *= scale
	node_to_add.name = node_name
	print(node_name)
	# add IK stuff if VRM
	if node_name.ends_with(".vrm"):
		print('attempting ik')
		var quickreniksetup :Node3D = load("res://addons/renik-gdscript/quick_renik_setup.tscn").instantiate()
		node_to_add.add_child(quickreniksetup)
		quickreniksetup.head.global_position += quickreniksetup.global_position
		quickreniksetup.hips.global_position += quickreniksetup.global_position
		quickreniksetup.left_hand.global_position += quickreniksetup.global_position
		quickreniksetup.right_hand.global_position += quickreniksetup.global_position
		quickreniksetup.left_foot.global_position += quickreniksetup.global_position
		quickreniksetup.right_foot.global_position += quickreniksetup.global_position
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
	if "loader" in data:
		data.loader.done()
