extends Node

func node_to_var(node:Node, _type:String='', _cust_name:String='') -> Dictionary:
	var out: Dictionary = {}
	if node.get_child_count() > 0:
		var children := Array()
		for child in node.get_children():
			children.append(Marshalls.variant_to_base64(child,true))
		out.children = children
	#out.node = var_to_str(node)
	out.node = var_to_bytes_with_objects(node)
	return out
####OLD:
	#var dict:Dictionary = {}
	#if type:
		#dict['asset_type'] = type
	#else:
		#dict['asset_type'] = node.get_class()
	#if cust_name:
		#dict['name'] = cust_name
	#else:
		#dict['name'] = node.name
	#dict['node'] = Array(var_to_bytes_with_objects(node))
##	dict['node'] = var_to_str(node)
	### prop list will be in the format of:
	###		name, class_name, type, hint, hint_string, usage
	#dict['properties'] = node.get_property_list()
	#dict['groups'] = PackedStringArray()
	#for group in node.get_groups():
		#if !group.begins_with("_"):
			#dict.groups.append(group)
	#if node.get_child_count() > 0:
		#var children : Array = []
		#for i in node.get_children():
			#print('added child')
			#children.append(node_to_var(i))
		#dict['children']=children
	#return dict

func var_to_node(_item:String='', dict:Dictionary={}):
	var node:Node
	if dict.has('node'):
		node = bytes_to_var_with_objects(dict.node)
		if dict.has('children'):
			for child in dict.children:
				node.add_child(Marshalls.base64_to_variant(child))
	return node
####OLD:
	#var j = JSON.new()
	#if dict.is_empty() and !item.is_empty():
##		print(item)
		#var err = j.parse(item)
		#if err == OK:
			#dict = j.data
		#else:
			#print("Error parsing imported json: "+str(j.get_error_message()))
	#if !dict.is_empty():
		#var node :Node = bytes_to_var_with_objects(dict.node)
##		var node :Node = str_to_var(dict.node)
		#if dict.has('groups') and dict['groups'].size()>0:
			#for group in dict.groups:
				#node.add_to_group(group)
		#if dict.has('children'):
			#for child in dict.children:
				#node.add_child(var_to_node('',child))
		#if dict.has('name'):
			#node.name = dict.name
		#return node


func normalize_float32_array(array:PackedFloat32Array):
	# holder for normalized array
	var norm_array :PackedFloat32Array = PackedFloat32Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func normalize_float64_array(array:PackedFloat64Array):
	# holder for normalized array
	var norm_array :PackedFloat64Array = PackedFloat64Array(array)
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	for i in norm_array.size():
		norm_array[i] = norm_array[i]/mag
	return norm_array

func float64_array_size(array:PackedFloat64Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

func float32_array_size(array:PackedFloat32Array):
	# magnitude
	var mag = 0.0
	# create some vars for intermediate math
	var a = 0.0
	# use pythagorian theorem to calculate the ^2 length of vector
	for i in array:
		a += pow(i,2)
	# root the ^2 length of the array to get it's length
	mag = sqrt(a)
	return mag

func rejoin_thread_when_finished(thread: Thread) -> void:
	if thread and thread.is_started() and thread.is_alive():
		get_tree().create_timer(1).timeout.connect(rejoin_thread_when_finished.bind(thread))
		return
	thread.wait_to_finish()

func invert_image(image:Image):
	print(image.data)
