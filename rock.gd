extends StaticBody2D
## A decorative boulder, a headstone, or the manor's clipped topiary: big, so solid.
## Stones bounce off it.

var radius := 13.0
var height := 24.0 ## a stone lower than this hits it
var art := "rock"
var frames := 1 ## the sheet's columns (the gravestones come in two, the topiary in six)
var frame := 0:
	set(v):
		frame = v
		if _sprite:
			_sprite.frame = v

var _sprite: Sprite2D


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	add_child(cs)
	var s := Sprite2D.new()
	s.texture = load("res://art/%s.png" % art)
	s.hframes = frames
	s.frame = frame
	s.offset = Vector2(0, 6 - s.texture.get_height() / 2.0) # its foot on the ground
	add_child(s)
	_sprite = s
