class_name Pond
extends StaticBody2D
## A garden pond: a solid oval (rim stones and all) to steer around. The water
## ripples between two frames.

const RX := 62.0
const RY := 42.0
const WATER_RX := 56.0 ## the water inside the rim stones (tools/art_sprites.py pond)
const WATER_RY := 36.0

var _t := 0.0


func _ready() -> void:
	z_index = -1 # flat on the ground: under anything that stands, whatever the depth
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


## Where a stone landing at p splashes, and how big the splash can be before its rings
## (26 x 14 px at full size) cross the rim: [centre, size 0.3..1]. On the rim stones it
## goes in at the water's edge.
func splash_fit(p: Vector2) -> Array:
	var d := p - position
	var q := sqrt((d.x * d.x) / (WATER_RX * WATER_RX) + (d.y * d.y) / (WATER_RY * WATER_RY))
	if q > 0.85:
		d *= 0.85 / q
		q = 0.85
	return [position + d, clampf((1.0 - q) / 0.5, 0.3, 1.0)]


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
