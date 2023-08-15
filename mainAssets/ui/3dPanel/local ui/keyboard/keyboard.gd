extends Control

@onready var tilde = $VBoxContainer/HBoxContainer/tilde
@onready var one = $VBoxContainer/HBoxContainer/one
@onready var two = $VBoxContainer/HBoxContainer/two
@onready var three = $VBoxContainer/HBoxContainer/three
@onready var four = $VBoxContainer/HBoxContainer/four
@onready var five = $VBoxContainer/HBoxContainer/five
@onready var six = $VBoxContainer/HBoxContainer/six
@onready var seven = $VBoxContainer/HBoxContainer/seven
@onready var eight = $VBoxContainer/HBoxContainer/eight
@onready var nine = $VBoxContainer/HBoxContainer/nine
@onready var zero = $VBoxContainer/HBoxContainer/zero
@onready var dash = $VBoxContainer/HBoxContainer/dash
@onready var equal = $VBoxContainer/HBoxContainer/equal
@onready var backspace = $VBoxContainer/HBoxContainer/backspace
@onready var q = $VBoxContainer/HBoxContainer2/q
@onready var w = $VBoxContainer/HBoxContainer2/w
@onready var e = $VBoxContainer/HBoxContainer2/e
@onready var r = $VBoxContainer/HBoxContainer2/r
@onready var t = $VBoxContainer/HBoxContainer2/t
@onready var y = $VBoxContainer/HBoxContainer2/y
@onready var u = $VBoxContainer/HBoxContainer2/u
@onready var i = $VBoxContainer/HBoxContainer2/i
@onready var o = $VBoxContainer/HBoxContainer2/o
@onready var p = $VBoxContainer/HBoxContainer2/p
@onready var left_square_bracket = $"VBoxContainer/HBoxContainer2/left square bracket"
@onready var right_square_bracket = $"VBoxContainer/HBoxContainer2/right square bracket"
@onready var slash = $VBoxContainer/HBoxContainer2/slash
@onready var delete = $VBoxContainer/HBoxContainer2/delete
@onready var a = $VBoxContainer/HBoxContainer3/a
@onready var s = $VBoxContainer/HBoxContainer3/s
@onready var d = $VBoxContainer/HBoxContainer3/d
@onready var f = $VBoxContainer/HBoxContainer3/f
@onready var g = $VBoxContainer/HBoxContainer3/g
@onready var h = $VBoxContainer/HBoxContainer3/h
@onready var j = $VBoxContainer/HBoxContainer3/j
@onready var k = $VBoxContainer/HBoxContainer3/k
@onready var l = $VBoxContainer/HBoxContainer3/l
@onready var semicolon = $VBoxContainer/HBoxContainer3/semicolon
@onready var quote = $VBoxContainer/HBoxContainer3/quote
@onready var z = $VBoxContainer/HBoxContainer4/z
@onready var x = $VBoxContainer/HBoxContainer4/x
@onready var c = $VBoxContainer/HBoxContainer4/c
@onready var v = $VBoxContainer/HBoxContainer4/v
@onready var b = $VBoxContainer/HBoxContainer4/b
@onready var n = $VBoxContainer/HBoxContainer4/n
@onready var m = $VBoxContainer/HBoxContainer4/m
@onready var comma = $VBoxContainer/HBoxContainer4/comma
@onready var dot = $VBoxContainer/HBoxContainer4/dot
@onready var slash2 = $VBoxContainer/HBoxContainer4/slash

var keys = [tilde,
	one,
	two,
	three,
	four,
	five,
	six,
	seven,
	eight,
	nine,
	zero,
	dash,
	equal,
	backspace,
	q,
	w,
	e,
	r,
	t,
	y,
	u,
	i,
	o,
	p,
	left_square_bracket,
	right_square_bracket,
	slash,
	delete,
	a,
	s,
	d,
	f,
	g,
	h,
	j,
	k,
	l,
	semicolon,
	quote,
	z,
	x,
	c,
	v,
	b,
	n,
	m,
	comma,
	dot,
	slash2
]

func _ready():
	for key in keys:
		pass
