extends Control
@onready var tree : Tree = $Tree

@onready var tree_root : TreeItem = tree.create_item()
signal selected(item)

func _process(delta):
#	print(tree.global_position)
#	print(tree.size)
	pass

func _ready():
	tree.item_selected.connect(func():
		selected.emit(tree.get_selected().get_metadata(0))
		)
	gui_input.connect(func(event):
#		print(event)
		)


func init():
	tree.clear()
	tree_root = tree.create_item()
	tree_root.set_text(0,"")

#func setItems(items:Array):
#	init()
#	var item : Node
#	for i in range(items.size()):
#		item = items[i]
#		var tmp = tree.create_item(tree_root)
#		tmp.set_text(0,item.name)
#		tmp.set_metadata(0,item)

func setRoot(item:Node):
	tree.clear()
	init()
	addchildren(item,tree_root)

func addchildren(node:Node, parent:TreeItem):
	var tmp = tree.create_item(parent)
	tmp.set_text(0,node.name)
	tmp.set_metadata(0,node)
	if node.get_child_count() > 0:
		for i in node.get_children():
			addchildren(i,tmp)
