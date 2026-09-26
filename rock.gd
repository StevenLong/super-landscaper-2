extends StaticBody2D
## A decorative boulder, or a headstone: big, so solid. Stones bounce off it.

var radius := 13.0
var art := "rock"
var frames := 1 ## the sheet's columns (the gravestones come in two)
var frame := 0


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
