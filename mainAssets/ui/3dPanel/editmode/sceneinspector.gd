extends Control
@onready var tree : Tree = $Tree

@onready var tree_root : TreeItem = tree.create_item()
signal selected(item)

func _ready():
	tree.item_selected.connect(func():
		selected.emit(tree.get_selected().get_metadata(0).node)
		)
	gui_input.connect(func(event):
		pass
		)

func _process(delta):
	var root = get_tree().get_first_node_in_group('localworldroot')
	if is_instance_valid(root):
		setRoot(root)
		tree.check_children()

func init():
#	tree.clear()
	tree_root = tree.create_item()
	tree_root.set_text(0,"")

func setRoot(item:Node):
#	tree.clear()
#	init()
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
		for i in node.get_children():
			addchildren(i,node)
