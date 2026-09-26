extends Node2D
## The customer's "do not touch" flowerbed. Not solid: anything with a cut_radius
## that drives over it flattens the flowers under it. The count of flattened
## flowers is what the customer will react to later. Shaped like a real bed (an oval,
## a kidney, a bean: a few overlapping ellipses inside `size`), sunk into the lawn,
## so in 3/4 its far edge shows as a cut face of earth. The slice's bed stays "rect".

signal trampled(flattened: int, total: int)

@export var size := Vector2(200, 80)
@export var spacing := 16.0
@export var shape := "rect" ## "rect", "oval", "kidney" or "bean"

const EDGE := Color("2e1c10")
const WALL := Color("3a2616") ## the cut face of the lawn along the far edge

var _flowers: Array[Vector2] = []
var _flat: Array[bool] = []
var _flattened := 0
var _blobs: Array = [] ## [centre, radii] ellipses whose union is the bed (not for "rect")


func _ready() -> void:
	z_index = -1 # flat on the ground: under anything that stands, whatever the depth
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var c := size / 2.0
	match shape:
		"oval":
			_blobs = [[c, c]]
		"kidney": # lobes along a curve, the middle bowed back: a crescent with fat ends
			var r := Vector2(size.x * 0.2, size.y * 0.38)
			for i in 5:
				var t := i / 4.0
				var bow := 1.0 - 4.0 * (t - 0.5) * (t - 0.5) # 0 at the ends, 1 in the middle
				_blobs.append([Vector2(lerpf(r.x, size.x - r.x, t), size.y - r.y - (size.y - 2.0 * r.y) * bow), r * (1.1 - 0.15 * bow)])
		"bean": # a long border with rounded ends
			var r := Vector2(size.y * 0.5, size.y * 0.5)
			for i in 4:
				_blobs.append([Vector2(lerpf(r.x, size.x - r.x, i / 3.0), c.y), r])
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for y in range(int(spacing / 2), int(size.y), int(spacing)):
		for x in range(int(spacing / 2), int(size.x), int(spacing)):
			var at := Vector2(x, y) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			if _inside(at, 5.0):
				_flowers.append(at)
				_flat.append(false)
	var shape := RectangleShape2D.new()
	shape.size = size
	$Area/Shape.shape = shape
	$Area/Shape.position = size / 2.0


func rect() -> Rect2:
	return Rect2(position, size)


## Is a local point in the bed, at least `margin` in from its edge?
func _inside(p: Vector2, margin := 0.0) -> bool:
	if _blobs.is_empty():
		return Rect2(Vector2.ZERO, size).grow(-margin).has_point(p)
	for b: Array in _blobs:
		var d: Vector2 = (p - b[0]) / (b[1] - Vector2(margin, margin))
		if d.length_squared() <= 1.0:
			return true
	return false


## Take the bed out of the lawn (lawn space = this node's parent's).
func exclude_from(lawn: Lawn) -> void:
	if _blobs.is_empty():
		lawn.exclude_rect(rect())
	for b: Array in _blobs:
		lawn.exclude_ellipse(position + b[0], b[1].x, b[1].y)


func flattened_count() -> int:
	return _flattened


func _physics_process(_delta: float) -> void:
	if not $Area.monitoring:
		return # a bed next door: scenery
	for body in $Area.get_overlapping_bodies():
		if "cut_radius" in body:
			_trample(to_local(body.global_position), body.cut_radius)


func _trample(at: Vector2, radius: float) -> void:
	var before := _flattened
	for i in _flowers.size():
		if not _flat[i] and _flowers[i].distance_to(at) <= radius:
			_flat[i] = true
			_flattened += 1
	if _flattened != before:
		queue_redraw()
		trampled.emit(_flattened, _flowers.size())


func _draw() -> void:
	var soil := preload("res://art/soil.png")
	if _blobs.is_empty():
		draw_rect(Rect2(Vector2.ZERO, size), WALL)
		draw_texture_rect(soil, Rect2(Vector2(0, 3), size - Vector2(0, 3)), true)
		draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 2.0)
	else:
		# The union of the ellipses, three times: the edging, the cut face, then the soil
		# floor lowered by 3 px, so only the far edge's face shows.
		for b: Array in _blobs:
			draw_colored_polygon(_ellipse(b[0], b[1] + Vector2(1.5, 1.5)), EDGE)
		for b: Array in _blobs:
			draw_colored_polygon(_ellipse(b[0], b[1]), WALL)
		for b: Array in _blobs:
			var pts := _ellipse(b[0] + Vector2(0, 1.5), b[1] - Vector2(0.5, 1.5))
			var uvs := PackedVector2Array()
			for p in pts:
				uvs.append(p / soil.get_size())
			draw_colored_polygon(pts, Color.WHITE, uvs, soil)
	var tex := preload("res://art/flowers.png")
	var kind := int(position.x + position.y) # one bed tends to one palette, with a mix
	for i in _flowers.size(): # standing on their stems, a shadow at the foot
		var col := (kind + (i % 5 if i % 7 == 0 else 0)) % 6
		draw_rect(Rect2(_flowers[i] + Vector2(-2, 0), Vector2(4, 1)), Color(0, 0, 0, 0.3))
		draw_texture_rect_region(tex, Rect2(_flowers[i] - Vector2(4, 8), Vector2(8, 8)),
			Rect2(col * 8, 8 if _flat[i] else 0, 8, 8))


func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		pts.append(c + Vector2(cos(TAU * i / 28.0), sin(TAU * i / 28.0)) * r)
	return pts
