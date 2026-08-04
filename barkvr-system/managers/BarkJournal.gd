## BarkJournal is the class that manages all the actions and history that happens
## during a session, whether it be only a local scene or a shared session with 
## other players
##
## rigth now, this handles the journal and imports. this will be changed in the future to move
## the import stuff to a different class. the goal is to make it so, instead of 
## sending the full file that we imported and allowing each client to import that
## file locally to replicate the netwroked scene, we want to process it (hopefully
## outside of the tree or something) so we can turn it into events compatible with 
## the journal. this sentiment may change in the future, but that's the thought right now.
## this journal implementation is a prototype of our initial approach to concepting
## how we could build out a PAXOS-like datamodel for the shared environment.
class_name BarkJournal
extends Node

## tracks all historical actions
var actions: Array[Dictionary] = []
## holder for actions that have been undone (intended to be used for the redo operation)
var undid_actions: Array[Dictionary] = []
## holder for incoming actions that need to be processed
var new_actions: Array[Dictionary] = []

## mutex for processing actions for multithreaded stability
var actions_mutex := Mutex.new()

# TODO: this still needs to actually be implemented. ideally, we want to use the journal 
# to process the shared state so we can have inspectors and other stuff just ask
# the journal for the current state of the tree. right now, we just have the inspector as
# a self contained object that reads the tree and operates against it on it's own. but that
# isn't the best design, so we intend to move it here so it can be central and processed
# immediately rather than latently, which reduces a massive amount of performance overhead 
# with the inspectors.
## holder which loads the journal_tree class
var JournalTreeClass = load("res://barkvr-system/managers/journal_tree.gd")
## holder for the actual instance of the journal tree
var journal_tree: Node 

## a list of extra classes that can be considered when processing some events.
## this allows us to have pre-made stuff available without needing to serialize them
## although we will turn these into bark journal assets that can be loaded within
## the journal context fully. this is currently used to allow the add_node stuff
## to show and instantiate bark-specific classes
static var extra_classes : PackedStringArray = [
	"Panel3D",
	"ParticlePen",
	"LinePen",
	"WindowCamera3D"
]

## accompanying list of where to get the files associated with the classes
## in the array above
static var extra_classes_spawn : Array[PackedScene] = [
	load("res://addons/Panel3D/Panel3D.tscn"),
	load("uid://og3t2qnt8ukh"), # particle pen
	load("uid://dj84bcm2jv1wq"), # linepen
	load("uid://bay38na2jeq1o") # placeable camera (WindowCamera3D)
]

# TODO: we should simplify this because we definitely don't need a check_root, _get_root, and a getter for the root variable lol
## holder for finding the shared root "localworldroot"
var root: Node:
	get:
		if !is_instance_valid(root):
			_get_root()
		return root

## holder for the root of the client scenetree itself (normally the main window)
var local_root: Node:
	get:
		if !is_instance_valid(local_root):
			local_root = get_tree().root
		return local_root

## this is written a little confusingly, but this just is a quick check
## for us to know if the journal event we recieved is properly contained within
## the shared root and isn't a remote change to the local portion of the tree
func is_path_remote(path:NodePath):
	# create holder for the target node
	var target_node :Node
	# try to get the target node
	target_node = root.get_node_or_null(path)
	# if we find a node with the path, then we check if the shared root is
	# an ancestor of it
	if target_node != null and root.is_ancestor_of(target_node):
		# if it is an ancestor, then return true
		return true
	# otherwise, return false
	return false

func _ready() -> void:
	# when the journal is ready we want to find the shared root
	check_root()
	# and create our journal tree (for centrally tracking the local tree)
	journal_tree = JournalTreeClass.new()
	add_child(journal_tree)

## this is a helper to add a new event into the journal
## accepts the action requested and whether it is an undo operation
func _add_action(data:Dictionary, undid:=false) -> void:
	actions_mutex.lock()
	if undid:
		#undid_actions.append(data)
		new_actions.append(data)
	else:
		actions.append(data)
		new_actions.append(data)
	actions_mutex.unlock()

## undoes the most recent action that is able to be undone
func undo_action() -> void:
	# checks that the shared root is still valid
	check_root()
	# lock mutex for thread safety
	actions_mutex.lock()
	# if the list of actions isn't empty
	if !actions.is_empty():
		# pop the most recent action to remove and return it
		var action_to_undo :Dictionary = actions.pop_back()
		# if it's valid
		if action_to_undo and "action_name" in action_to_undo:
			# run appropriate method to actualize the action
			match action_to_undo.action_name:
				'set_property':
					set_property(action_to_undo.target, action_to_undo.prop_name, action_to_undo.previous_value, false, true)
				'delete_node':
					pass
				'add_node':
					pass
	# unlock mutex so something else can run
	actions_mutex.unlock()

## this is a helper function used by the networking code to ask for all the new actions
## that need to be sent over the network
func get_actions() -> Array[Dictionary]:
	actions_mutex.lock()
	var tmp := new_actions.duplicate(true)
	new_actions.clear()
	actions_mutex.unlock()
	return tmp

## chekcs if the shared root is valid and if it isn't, we try to find it
func check_root() -> void:
	if !is_instance_valid(root):
		_get_root()

## attempts to query the tree for the shared root
func _get_root() -> void:
	root = get_tree().get_first_node_in_group('localworldroot')

# TODO create function to iterate over the current scene and prepare it for remote syncing
func _prepare_existing_tree_for_remote_sync() -> void:
	pass

## this runs the action of reparenting a node in the shared root
func set_parent(target: NodePath, new_parent: NodePath) -> void:
	# is the shared root valid?
	check_root()
	# find the node we are operating on
	var target_node := root.get_node(target)
	# find the new parent
	var np_node := root.get_node(new_parent)
	# reparent the targeted node to the new parent
	target_node.reparent(np_node)
	# add the action to the journal
	actions.append({
		'action_name': 'set_parent',
		'target': target,
		'new_parent': new_parent
	})

# TODO: we should do some of this in a gdextension so we can have direct memory creation access.
# doing so will allow us to create the nodes with the correct data immediately rather than doing it
# in gdscript and facing issues where gdscript is intentionally restricted (reasonably so in many cases)
# from some things since this is beyond the scope of what gdscript is intended to do.
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
	# check root validity
	check_root()
	# get the node we are attempting to operate on/under
	var p_node := root.get_node(parent)
	# if it returns a valid node...
	if is_instance_valid(p_node):
		# process the action into nodes outside of the tree
		var target_node :Node = _read_add_node_nodes_dict(nodes, recieved)
		# if the event isn't remote
		if !recieved:
			# i don't even know, this is some schizo bullshit that we need to rewrie i think.
			# even if this is valid code, this sucks and we shouldn't write code like this ngl
			while p_node.has_node("./"+target_node.name):
				# intended to generate a sufficient hash name for the node to mitigate 
				# node path struggles from years ago.
				var placeholder_name :String=  str(str(str(nodes.node_class) + str( str(nodes) + str( Time.get_unix_time_from_system() + float(Time.get_ticks_usec()) ))).hash())
				# set the new node's name
				target_node.name = placeholder_name
				# process the node properties and apply them to the node we just created.
				# some more crazy shit i wrote that needs to be fixed
				if "properties" in nodes:
					nodes.properties.append({"name":"name","value":placeholder_name})
				else:
					nodes.properties = [{"name":"name","value":placeholder_name}]
		# add the new node as a child of the designated parent node
		p_node.add_child(target_node)
		# if not a remote action and not an undo, then add it to the journal such that it will be
		# synced over the network
		if !recieved and !undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(target_node),
				'nodes': nodes
			})
		# if it is an undo, then add it to the journal with the undid flag enabled
		if undid:
			_add_action({
				'action_name': 'add_node',
				'parent': parent,
				'added_node_path': root.get_path_to(target_node),
				'nodes': nodes
			},true)

# TODO: replace the use of a dictionary with a class so it can have a fixed and documentable schema
## this method is intended to accept a dictionary of nodes to be added to the shared root
## and turn them from a dictionary of data into actual nodes to add
## documenting this method is a bit of a frivilous effort, look at the inline doc of the above function 
## for more info on what this is looking for
func _read_add_node_nodes_dict(node_dict:Dictionary, recieved:=false) -> Node:
	# check that the shared root is valid
	check_root()
	if "node_class" in node_dict and (ClassDB.can_instantiate(node_dict.node_class) or node_dict.node_class in extra_classes):
		var node : Node
		if node_dict.node_class in extra_classes:
			node = extra_classes_spawn[extra_classes.find(node_dict.node_class)].instantiate()
		node = ClassDB.instantiate(node_dict.node_class) if !node else node
		var _node_props = node.get_property_list()
		if "properties" in node_dict and node_dict.properties is Array:
			for prop in node_dict.properties:
				if prop is Dictionary and "name" in prop and "value" in prop:
					if prop.name in node and !(typeof(node[prop.name]) in [TYPE_CALLABLE, TYPE_OBJECT, TYPE_SIGNAL]):
						node[prop.name] = prop.value
					elif prop.name.begins_with('metadata/'):
						node.set_meta(prop.name.trim_prefix("metadata/"), prop.value)
		if !recieved:
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

## runs the delete node action
func delete_node(target: NodePath, recieved := false, undid := false) -> void:
	# check if root is valid
	check_root()
	# find the target node
	var target_node := root.get_node(target)
	# this is intended to pack the node into a scene so it can used when the
	# user wants to undo a deletion but this is tough in gdscript and a lil fickle
	# create packed scene we will use
	var deleted_node_as_packed_scene := PackedScene.new()
	# call our helper to set the node as "owner" of all the nodes beneath it.
	# we do this because a node packed into a scene will only include nodes that have
	# it set as their owner (and *allegedly* all the nodes that those are owners of
	# but that didn't work when i created this)
	take_owner_of_node_and_all_children(target_node, target_node)
	# TODO: do something with this packedscene ffs
	# pack the node into the PackedScene so we can save it
	deleted_node_as_packed_scene.pack(target_node)
	# delete the node
	target_node.queue_free()
	# if not remote add the actuion to the queue
	if !recieved:
		_add_action({
			'action_name': 'delete_node',
			'target': target,
			'deleted_node': target_node.name#Marshalls.variant_to_base64(deleted_node_as_packed_scene,true)
		})

## sets a property of the target node in the shared scene
func set_property(target: NodePath, prop_name: String, value: Variant, recieved := false, undid := false) -> void:
	check_root()
	# get the target node
	var target_node := root.get_node(target)
	# if the node is valid and the property path exists in the target...
	if is_instance_valid(target_node) and prop_name.split(':')[0] in target_node:
		# capture the previous value for undoing
		var previous_value = target_node.get_indexed(prop_name)
		# this sets the property to the value we have
		target_node.set_indexed(prop_name,value)
		# if not remote or undid, then we add it to the journal
		if !recieved and !undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			})
		# if it's an undo, we add it with the journal with the undo flag
		if undid:
			_add_action({
				'action_name': 'set_property',
				'target': target,
				'prop_name': prop_name,
				'value': value,
				'previous_value': previous_value
			},true)

## helper method to set a node as the owner of all nested nodes
func take_owner_of_node_and_all_children(node:Node,new_owner:Node):
	check_root()
	# set owner of targeted node
	node.owner = new_owner
	# iterate over all children recursively
	if node.get_child_count() > 0:
		for child in node.get_children():
			take_owner_of_node_and_all_children(child, new_owner)

## this is deprecated and will be removed soon. it's need will vanish once the networking overhaul is finished
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
func import_asset( type: String, asset_to_import: Variant, asset_name := '', recieved := false, data := {} ) -> void:
	print(type)
	# Make sure root is valid.
	check_root()
	# if the loader isn't in the scene, add it
	if "loader" in data and data.loader is Node:
		if !data.loader.is_inside_tree():
			if recieved:
				data.loader = load("res://barkvr-system/ui/3dui/loading_halo.tscn").instantiate()
				data.loader.text = "remote asset"
			root.add_child(data.loader)
			data.loader.global_position = data.position
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
			if content.is_empty():
				print(FileAccess.get_open_error())
		elif asset_to_import is Image:
			content = asset_to_import.data.data
	# Decide how to import asset based on type.
	# TODO pck support
	data.type = type
	match type:
		"text":
			_import_text(asset_to_import,asset_to_import, data)
		"glb", "vrm":
			_import_glb(asset_to_import, asset_name, data)
		"obj":
			_import_obj(asset_to_import, asset_name, data)
		"res":
			# TODO scenes and resources can't easily be sent to peers because of
			# possible dependencies in other files.
			_import_res(asset_name, asset_to_import, data)
		"image":
			if asset_to_import is Image:
				_import_image_image(asset_name, asset_to_import, data)
			else:
				_import_image_bytes(asset_name, content, data)
		"audio":
			if !content.is_empty():
				_import_audio(asset_name, content, data)
			elif asset_to_import is String:
				pass
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
		match type:
			"text":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"glb", "vrm":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"res":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"image":
				if asset_to_import is PackedByteArray and !asset_to_import.is_empty():
					data.image_data = asset_to_import
				elif asset_to_import is Image:
					data.image_data = var_to_bytes_with_objects(asset_to_import)
					data.image_image_alt = true
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"audio":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"file":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"uri":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"obj":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			"zip":
				_add_action({
					'action_name': 'import_asset',
					'type': type,
					'asset_to_import': asset_to_import,
					'content': content,
					'asset_name': asset_name,
					'data': data
				})
			_:
				if "loader" in data:
					data.loader.done('failed')


## imports a remote uri (currently only http[s])
func _import_uri(uri:String, data:Dictionary={}):
	# generate a temp directory to hold the data
	var temp_file_path :String = "user://tmp/"+str(hash(uri))
	# here we wanna track the number of iterations so we can
	# have a limit on the number of times we will attempt
	# to import the uri
	if !("iterations" in data):
		data.iterations = 0
	# ensure the uri is a valid http[s] url
	if uri.begins_with("http://") or uri.begins_with("https://"):
		# if we have already tried 4 times then we wanna say it failed
		if "iterations" in data and data.iterations > 4:
			print("loop while trying to import uri, cancelling import")
			return
		# create a new request object
		var req := HTTPRequest.new()
		# set the request to write to disk using the temp file path
		req.download_file = temp_file_path
		# add the request to the tree so it can be polled automatically by the engine
		call_deferred("add_child",req)
		# we wait for the node to be ready for some reason.
		if !req.is_node_ready():
			await req.ready
		req.request_completed.connect(_uri_request_completed.bind(req,data,uri))
		var headers = Engine.get_singleton("user_manager").headers
		req.request(uri, headers)

## finishing method for importing a uri
func _uri_request_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, req:HTTPRequest, data:Dictionary, uri:String):
			print('req completed')
			print('response code: '+str(response_code))
			var content_type:String = ""
			var _msg = body.get_string_from_ascii()
			for header in headers:
				if header.begins_with("Content-Type:"):
					print('content')
					print(header.trim_prefix("Content-Type: "))
					var trimmed := header.trim_prefix("Content-Type: ")
					if trimmed.begins_with("image") and !trimmed.contains("gif"):
						print('importing uri image')
						while body.size() < 1:
							if data.iterations > 4:
								data.loader.done()
								return
							data.iterations += 1
							body = (FileAccess.get_file_as_bytes(req.download_file))
						_import_image_bytes(uri, body, data)
						data.loader.done()
						return
					elif trimmed == "application/json":
						print('woof')
						data.loader.done()
						return
					elif trimmed.contains("gltf-binary"):
						content_type = "gltf-binary"
					elif trimmed.contains("vrm") or uri.ends_with("vrm"):
						content_type = "vrm"
			print('uri returned text')
			print('uri: '+uri)
			if uri.contains('.gltf') or uri.contains('.glb') or content_type == "gltf-binary":
				WorkerThreadPool.add_task(import_asset.bind('glb', req.download_file, uri, false, data))
			elif uri.contains('.vrm') or content_type == "vrm":
				WorkerThreadPool.add_task(import_asset.bind('vrm', req.download_file, uri, false, data))
			elif uri.contains('.obj'):
				import_asset('obj', req.download_file, uri, false, data)
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
	data.nolookatuser = true
	if reader.open(asset_path) == 0:
		for dropped in reader.get_files():
			print('dropped: '+dropped)
			if reader.file_exists(dropped):
				print('is file')
				var type = BarkHelpers.detect_file_type_from_header(reader.read_file(dropped))
				data.position = data.position+Vector3(0,0,-.01*get_tree().get_first_node_in_group("player").scale.length())
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
					dropped.ends_with('.webp') or \
					type == "img":
					import_asset('image', reader.read_file(dropped), asset_name, false, data)
				elif dropped.ends_with('.obj'):
					import_asset('obj', reader.read_file(dropped), asset_name, false, data)
				#elif dropped.ends_with(".zip"):
					#import_asset('zip', reader.read_file(dropped), asset_name, false, data)
				#else:
					#import_asset('file', reader.read_file(dropped), asset_name, false, data)

func _check_loaded(path: String, asset_name:String, data:Dictionary={}, _last_time:float=0.0) -> void:
	check_root()
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
		#get_tree().create_timer(1).timeout.connect(_check_loaded.bind(path, asset_name, position))
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		var res := ResourceLoader.load_threaded_get(path)
		if res != null:
			var node = res.instantiate()
			_post_import.call_deferred(root,node,asset_name,data, !data.has("nolookatuser"))

#
var gltf_document_extension_class = load("res://addons/vrm/vrm_extension.gd")
const SAVE_DEBUG_GLTFSTATE_RES: bool = false

#COPIED FROM https://github.com/godotengine/godot/blob/c4279fe3e0b27d0f40857c00eece7324a967285f/modules/gltf/gltf_document.cpp#L62
#define GLTF_IMPORT_GENERATE_TANGENT_ARRAYS 8
#define GLTF_IMPORT_USE_NAMED_SKIN_BINDS 16
#define GLTF_IMPORT_DISCARD_MESHES_AND_MATERIALS 32
#define GLTF_IMPORT_FORCE_DISABLE_MESH_COMPRESSION 64

func _import_glb(content: Variant, asset_name := '', data := {}) -> void:
	check_root()
	#Thread.set_thread_safety_checks_enabled(false)
	var logging_prefix := asset_name+" : "
	print("Import VRM/GLTF/GLB/FBX: " + asset_name + " ----------------------")
	var gltf : GLTFDocument
	var flags := 16+8
	var state : GLTFState
	if "type" in data and data.type == 'fbx':
		gltf = FBXDocument.new()
		state = FBXState.new()
		#state.allow_geometry_helper_nodes = true
	else:
		gltf = GLTFDocument.new()
		state = GLTFState.new()
		if data.type != "vrm":
			state.set_additional_data(&"vrm/already_processed",true)
	
	#if content is String and asset_name in content:
		#state.base_path = content.trim_suffix(asset_name)
	var err :int
	if content is String:
		err = gltf.append_from_file(content, state, flags)
	elif content is PackedByteArray:
		err = gltf.append_from_buffer(content, '', state, flags)
	match err:
		43:
			if "alreadytried" in data:
				return
			data.type = "fbx"
			data.alreadytried = 1
			_import_glb(content, asset_name, data)
			return
	if err != OK:
		if "loader" in data:
			data.loader.done('failed')
		return
	for mesh in state.meshes:
			if mesh.mesh.get_surface_lod_count(0) == 0:
				print(logging_prefix+'generating lods')
				mesh.mesh.generate_lods(25,60,[])
	print("generated scene")
	var generated_scene = gltf.generate_scene(state)
	var packed_scene_workaround := PackedScene.new()
	packed_scene_workaround.pack(generated_scene)
	generated_scene = packed_scene_workaround.instantiate()
	#if SAVE_DEBUG_GLTFSTATE_RES and content != "":
		#if !ResourceLoader.exists(content + ".res"):
			#state.take_over_path(content + ".res")
			#ResourceSaver.save(state, content + ".res")
	print('post importing glb/gltf/vrm')
	data.nolookatuser = true
	_post_import.call_deferred(root, generated_scene, asset_name, data, !data.has("nolookatuser"))

## Import Wavefront .obj files
func _import_obj(path_or_asset: String, asset_name := '', data := {}) -> void:
	# load the file into a mesh
	var logging_prefix := asset_name+" : "
	print("Import OBJ: " + asset_name + " ----------------------")
	
	print(path_or_asset)
	
	var mesh_data := MeshInstance3D.new()
	#this basically checks if its "local"-ish or if it's being fed through the network
	#assuming transmitting the object between clients will become a string
	if(path_or_asset.is_absolute_path() || path_or_asset.is_relative_path()):
		mesh_data.mesh = ObjParse.from_path(path_or_asset)
	else:
		mesh_data.mesh = ObjParse.from_obj_string(path_or_asset)

	#TODO: figure out a way to generate LOD's 
	
	#create the collision node
	var tmpbody := StaticBody3D.new()
	tmpbody.set_meta("grabbable",true)
	var tmpcol := CollisionShape3D.new()
	var tmpcolshape := SphereShape3D.new()
	tmpcol.scale = mesh_data.get_aabb().size
	
	tmpcol.shape = tmpcolshape
	tmpbody.add_child(tmpcol)
	tmpbody.collision_layer = 2
	tmpbody.collision_mask = 2

	tmpbody.add_child(mesh_data)

	#var compressed := content.compress()
	#print(compressed)
	#print(content)
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

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
	print(asset_to_import)
	#var res :Resource
	#print(ResourceLoader.get_dependencies(asset_to_import)[0])
	#print(asset_to_import)
	print(ResourceLoader.get_recognized_extensions_for_type(asset_to_import))
	var res = ResourceLoader.load(asset_to_import,'obj',ResourceLoader.CACHE_MODE_IGNORE)
	
	# var res = load(asset_to_import)
	#print(res.resource_path)
	#res = _load_res_with_dependencies(asset_to_import)
	if res != null:
		var node = res.instantiate()
		_post_import.call_deferred(root,node,asset_name,data, !data.has("nolookatuser"))
	ResourceLoader.load_threaded_request(asset_to_import, 'tres', false, ResourceLoader.CACHE_MODE_IGNORE)
	_check_loaded(asset_to_import,asset_name,data)

func _load_res_with_dependencies(path:String) -> Resource:
	var res :Resource
	for dep in ResourceLoader.get_dependencies(path):
		_load_res_with_dependencies(dep)
	res = ResourceLoader.load(path)
	return res

func _load_image_bytes_from_header(content: PackedByteArray) -> Image:
	var img := Image.new()
	
	var format_signatures = [
		# WEBP
		{
			"callable": Callable(img, "load_webp_from_buffer"),
			"magic": [0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50]
		},
		# PNG
		{
			"callable": Callable(img, "load_png_from_buffer"),
			"magic": [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		},
		# BMP
		{
			"callable": Callable(img, "load_bmp_from_buffer"),
			"magic": [0x42, 0x4D]
		},
		# TGA does not have a static header
		
		# JPG
		{
			"callable": Callable(img, "load_jpg_from_buffer"),
			# I think there are other possible magics
			# This could possibly miss some kinds of JPEGs!
			# TODO: Add more JPEG magics
			"magic": [0xFF, 0xD8, 0xFF, 0xE0]
		},
		# SVG does not have a static header
		
		# KTX
		{
			"callable": Callable(img, "load_ktx_from_buffer"),
			"magic": [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A]
		}
	]
	
	# Check each signature on the image to find a match
	for signature in format_signatures:
		var magic = signature.magic
		
		# Check to make sure there are enough bytes to read
		if content.size() >= magic.size():
			var matches = true
			
			# Loop over bytes until our signature is done
			# or there is a mismatch
			for i in range(magic.size()):
				# Dont read null (wildcard) magic bytes
				if magic[i] == null:
					continue
				
				if content[i] != magic[i]:
					# There was a mismatch
					matches = false
					break
			
			if matches:
				# We have a signature match!
				# Load the image
				signature.callable.call(content)
	
	return img

## Imports an image from bytes.
func _import_image_bytes(asset_name: String, content: PackedByteArray, data:Dictionary={}) -> void:
	check_root()
	
	var img: Image = _load_image_bytes_from_header(content)
	var err: Error
	
	# `img` will be empty if no signature was matched or loading failed
	if img.is_empty():
		# The image did not have a signature
		# The image could be TGA, SVG, or in the data dict
		
		err = img.load_tga_from_buffer(content)
		if err != OK:
			err = img.load_svg_from_buffer(content)
		if err != OK and "image_data" in data and "image_image_alt" in data:
			# Image was not TGA or SVG, test the data argument for image data
			img = bytes_to_var_with_objects(data.image_data)
			if !img.is_empty():
				err = OK
		if err != OK and "image_data" in data:
			var _img_formats_lookup = {"FORMAT_BPTC_RGBA": 22,
			"FORMAT_BPTC_RGBF": 23,
			"FORMAT_BPTC_RGBFU": 24,
			"FORMAT_ETC": 25,
			"FORMAT_ETC2_R11": 26,
			"FORMAT_ETC2_R11S": 27,
			"FORMAT_ETC2_RG11": 28,
			"FORMAT_ETC2_RG11S": 29,
			"FORMAT_ETC2_RGB8": 30,
			"FORMAT_ETC2_RGBA8": 31,
			"FORMAT_ETC2_RGB8A1": 32,
			"FORMAT_ETC2_RA_AS_RG": 33,
			"FORMAT_DXT5_RA_AS_RG": 34,
			"FORMAT_ASTC_4x4": 35,
			"FORMAT_ASTC_4x4_HDR": 36,
			"FORMAT_ASTC_8x8": 37,
			"FORMAT_ASTC_8x8_HDR": 38}
			#for format in img_formats_lookup.keys():
				#if data.image_data.format in format:
					#data.image_data.format = format
					#break
			img = null
			img = Image.new()
			img.data.data = data.image_data
			print('create image from data:')
			print(img.data.size())
			print(img.is_empty())
			err = OK
	
	if err != OK or img.is_empty():
		if "loader" in data:
			data.loader.done('failed')
			printerr("image failed to load:\n",data)
		return
	
	var tex := ImageTexture.create_from_image(img)
	var plane := MeshInstance3D.new()
	var tmpmesh := PlaneMesh.new()
	var tmpmat := StandardMaterial3D.new()
	tmpmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
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
	tmpbody.set_meta("image_texture", tex)
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))


## Imports an image from an existing image resource.
func _import_image_image(asset_name: String, img: Image, data:Dictionary={}) -> void:
	check_root()
	
	var tex := ImageTexture.create_from_image(img)
	var plane := MeshInstance3D.new()
	var tmpmesh := PlaneMesh.new()
	var tmpmat := StandardMaterial3D.new()
	tmpmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

## Imports an audio file.
func _import_audio(asset_name: String, content: PackedByteArray, data:Dictionary={} ) -> void:
	check_root()
	var audio3d: Audio3D = load("res://barkvr-system/ui/3dui/import helpers/audio3d.tscn").instantiate()
	audio3d.load_audio_from_bytes(content, "mp3")
	_post_import.call_deferred(root, audio3d, asset_name, data, !data.has("nolookatuser"))

## Imports some text.
func _import_text(asset_name: String, _content: String, data:Dictionary={} ) -> void:
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
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

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

	#var compressed := content.compress()
	#print(compressed)
	#print(content)
	
	tmpbody.set_meta("file_bytes",str(content.compress(2)))
	_post_import.call_deferred(root, tmpbody, asset_name, data, !data.has("nolookatuser"))

## Accept an incoming network message and handle it appropriately.
func receive(action: Dictionary) -> void:
	check_root()
	if "content" in action and !action.content.is_empty():
		action.asset_to_import = action.content
	match action.action_name:
		"set_property":
			set_property(action.target, action.prop_name, action.value, true)
		"import_asset":
			import_asset(action.type, action.asset_to_import, action.asset_name, true, action.data)
		"delete_node":
			delete_node(action.target, true)
		"add_node":
			add_node(action.parent,action.nodes,true)

func _post_import(_rootarget_node:Node,node_to_add:Node,node_name:String,data:Dictionary={},lookatuser:bool=false):
	check_root()
	var position = Vector3()
	if "position" in data:
		position = data.position
	var scale = 1.0
	if "scale" in data:
		scale = data.scale
	root.call_deferred("add_child", node_to_add)
	await get_tree().process_frame
	if node_to_add is Node3D:
		if lookatuser:
			node_to_add.look_at_from_position(position,get_viewport().get_camera_3d().global_position,Vector3.UP,true)
		node_to_add.global_position = position
		node_to_add.scale *= scale
	node_to_add.name = node_name
	print(node_name)
	# add IK stuff if VRM
	if node_name.ends_with(".vrm") or data.type == "vrm":
		print('attempting ik')
		var quickiksetup :Node3D = load("res://barkvr-system/ik/auto setup for avatars/quick_ik_setup.tscn").instantiate()
		node_to_add.add_child(quickiksetup)
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
			await get_tree().process_frame
		if skele:
			print('found skele')
			quickiksetup.armature_skeleton = skele
	if "loader" in data:
		data.loader.done()
