class_name Pond
extends StaticBody2D
## A garden pond: a solid oval (rim stones and all) to steer around. The water
## ripples between two frames.

const RX := 62.0
const RY := 42.0

var _t := 0.0


func _ready() -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * RX, sin(a) * RY))
	var cs := CollisionPolygon2D.new()
	cs.polygon = pts
	add_child(cs)


func contains(p: Vector2) -> bool:
	var d := p - position
	return (d.x * d.x) / (RX * RX) + (d.y * d.y) / (RY * RY) <= 1.0


func _process(delta: float) -> void:
	var before := int(_t / 0.7)
	_t += delta
	if int(_t / 0.7) != before:
		queue_redraw()


func _draw() -> void:
	var t := preload("res://art/pond.png")
	var fw := t.get_width() / 2.0
	var frame := int(_t / 0.7) % 2
	draw_texture_rect_region(t, Rect2(-fw / 2.0, -t.get_height() / 2.0, fw, t.get_height()),
		Rect2(frame * fw, 0, fw, t.get_height()))
