extends Node2D
## The customer's "do not touch" flowerbed. Not solid: anything with a cut_radius
## that drives over it flattens the flowers under it. The count of flattened
## flowers is what the customer will react to later.

signal trampled(flattened: int, total: int)

@export var size := Vector2(200, 80)
@export var spacing := 16.0

var _flowers: Array[Vector2] = []
var _flat: Array[bool] = []
var _flattened := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for y in range(int(spacing / 2), int(size.y), int(spacing)):
		for x in range(int(spacing / 2), int(size.x), int(spacing)):
			_flowers.append(Vector2(x, y) + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)))
			_flat.append(false)
	var shape := RectangleShape2D.new()
	shape.size = size
	$Area/Shape.shape = shape
	$Area/Shape.position = size / 2.0


func rect() -> Rect2:
	return Rect2(position, size)


func flattened_count() -> int:
	return _flattened


func _physics_process(_delta: float) -> void:
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
	draw_texture_rect(preload("res://art/soil.png"), Rect2(Vector2.ZERO, size), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("2e1c10"), false, 2.0)
	var tex := preload("res://art/flowers.png")
	var kind := int(position.x + position.y) # one bed tends to one palette, with a mix
	for i in _flowers.size():
		var col := (kind + (i % 5 if i % 7 == 0 else 0)) % 6
		draw_texture_rect_region(tex, Rect2(_flowers[i] - Vector2(4, 5), Vector2(8, 8)),
			Rect2(col * 8, 8 if _flat[i] else 0, 8, 8))
