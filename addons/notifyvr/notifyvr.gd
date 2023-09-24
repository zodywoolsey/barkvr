extends Node

var queuedmessages = []

func send_notification(message:String):
	var lbl = Label3D.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.set_script(load("res://addons/notifyvr/textscript.gd"))
	queuedmessages.append(lbl)

func _process(delta):
	if queuedmessages.size() > 0:
		for i in queuedmessages:
			var tmp = get_tree().get_first_node_in_group("notificationparent")
			if tmp:
				tmp.add_child(i)
				tmp.move_child(i,0)
				queuedmessages.erase(i)
				var tmpsize = 0.0
				for a in tmp.get_children():
					tmpsize += a.get_aabb().size.y
#					print(a)
				i.position.y = tmpsize
			
