extends StaticBody2D
## A decorative boulder: big, so solid. Stones bounce off it.

var radius := 13.0


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	add_child(cs)
	var s := Sprite2D.new()
	s.texture = preload("res://art/rock.png")
	s.offset = Vector2(0, -7) # its foot on the ground
	add_child(s)
