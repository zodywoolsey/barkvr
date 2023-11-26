extends Control
@onready var tree : Tree = $Tree

@onready var tree_root : TreeItem = tree.create_item()
signal selected(item)

@onready var thread = Thread.new()
@onready var tree_check_semaphore = Semaphore.new()

func _ready():
	tree.item_selected.connect(func():
		selected.emit(tree.get_selected().get_metadata(0).node)
		LocalGlobals.clear_gizmos.emit()
		var giz = load("res://mainSystem/scenes/objects/tools/gizmo/gizmo.tscn").instantiate()
		var node = tree.get_selected().get_metadata(0).node
		if node is Node3D:
			get_tree().get_first_node_in_group('localworldroot').add_child(giz)
			giz.global_position = node.global_position
			giz.target = node
		)
	gui_input.connect(func(event):
		pass
		)
	get_tree().tree_changed.connect(func():
		tree_check_semaphore.post()
		)
	thread.start(_check_tree_for_updates)

func _exit_tree():
	Journaling.rejoin_thread_when_finished(thread)

func _check_tree_for_updates():
	Thread.set_thread_safety_checks_enabled(false)
	while true:
		tree_check_semaphore.wait()
		var root = get_tree().get_first_node_in_group('localworldroot')
		if is_instance_valid(root):
			setRoot(root)
			tree.check_children()

func init():
#	tree.clear()
	tree_root = tree.create_item()
	tree_root.set_text(0,"")

func setRoot(item:Node):
	addchildren(item)

func addchildren(node:Node, parent:Node=null):
	if parent:
		tree.add_item(node.name, {
			'node':node,
			'parent':parent,
		})
	else:
		tree.add_item(node.name,{
			'node':node
		})
	if node.get_child_count() > 0:
		await get_tree().process_frame
		if is_instance_valid(node):
			for i in node.get_children():
				addchildren(i,node)
