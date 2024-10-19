class_name Color_Attribute
extends Control

@onready var label = $VBoxContainer/Panel2/Label
@onready var rval: LineEdit = $VBoxContainer/TabContainer/rgba/r/rval
@onready var gval: LineEdit = $VBoxContainer/TabContainer/rgba/g/gval
@onready var bval: LineEdit = $VBoxContainer/TabContainer/rgba/b/bval
@onready var rgbaval: LineEdit = $VBoxContainer/TabContainer/rgba/a/rgbaval
@onready var hval: LineEdit = $VBoxContainer/TabContainer/hsva/h/hval
@onready var sval: LineEdit = $VBoxContainer/TabContainer/hsva/s/sval
@onready var vval: LineEdit = $VBoxContainer/TabContainer/hsva/v/vval
@onready var hsvaval: LineEdit = $VBoxContainer/TabContainer/hsva/a/hsvaval
@onready var hexval: LineEdit = $VBoxContainer/TabContainer/hex/h/hexval
@onready var v_box_container = $VBoxContainer

var target:Object
var _is_editing:bool = false
var property_name:String = ''

var event_supplier

func _ready():
	event_supplier = Engine.get_singleton("event_manager")
	print("event suppliervec3: "+str(event_supplier))
	rval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":r",
			#float(new_text)
			#)
		target[property_name].r = float(new_text)
		)
	gval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":g",
			#float(new_text)
			#)
		target[property_name].g = float(new_text)
		)
	bval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":b",
			#float(new_text)
			#)
		target[property_name].b = float(new_text)
		)
	rgbaval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":a",
			#float(new_text)
			#)
		target[property_name].a = float(new_text)
		)
	hsvaval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":a",
			#float(new_text)
			#)
		target[property_name].a = float(new_text)
		)
	hval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":h",
			#float(new_text)
			#)
		target[property_name].h = float(new_text)
		)
	sval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":s",
			#float(new_text)
			#)
		target[property_name].s = float(new_text)
		)
	vval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":v",
			#float(new_text)
			#)
		target[property_name].v = float(new_text)
		)
	hexval.text_changed.connect(func(new_text):
		#event_supplier.set_property(
			#event_supplier.root.get_path_to(target),
			#property_name+":v",
			#float(new_text)
			#)
		target[property_name]= Color.html((new_text))
		)

func _process(_delta):
	var scrollparentrect = get_parent_control().get_parent_control().get_global_rect()
	var rect = get_global_rect()
	if (rect.end.y > scrollparentrect.position.y and rect.position.y < scrollparentrect.end.y):
		update_fields()

func update_fields():
	if target and !property_name.is_empty() and !_is_editing and is_instance_valid(target) and !_check_focus():
		rval.text = str(target[property_name].r)
		gval.text = str(target[property_name].g)
		bval.text = str(target[property_name].b)
		rval.text = str(target[property_name].r)
		gval.text = str(target[property_name].g)
		bval.text = str(target[property_name].b)
		rgbaval.text = str(target[property_name].a)
		hval.text = str(target[property_name].h)
		sval.text = str(target[property_name].s)
		vval.text = str(target[property_name].v)
		hsvaval.text = str(target[property_name].a)
		hexval.text = str(target[property_name].to_html())
	elif !is_instance_valid(target):
		target = null
		rval.text = ""
		gval.text = ""
		bval.text = ""
		rval.text = ""
		gval.text = ""
		bval.text = ""
		rgbaval.text = ""
		hval.text = ""
		sval.text = ""
		vval.text = ""
		hsvaval.text = ""
		hexval.text = ""

func _check_focus():
	if rval.has_focus() or gval.has_focus() or bval.has_focus() or rgbaval.has_focus() or hval.has_focus() or sval.has_focus() or vval.has_focus() or hsvaval.has_focus() or hexval.has_focus():
		return true
	return false

## sets the name, field target node, and the property name for the field to look for
## name:String, new_target:Node, new_property_name:String
func set_data(new_name:String, new_target:Object, new_property_name:String):
	label.text = new_name
	target = new_target
	property_name = new_property_name
