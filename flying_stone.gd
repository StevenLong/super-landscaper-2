class_name FlyingStone
extends Node2D
## A stone in flight: travels along the ground in a straight line with a hop drawn
## above its shadow. Each frame it asks hit_test (a Callable taking a position and
## returning a target name, or "") whether it struck something; on impact or
## landing it reports via `landed` with what it hit ("" for plain ground).

signal landed(stone: FlyingStone, target: String)

var velocity := Vector2.ZERO
var kind := "stone" ## what's flying (Stone.KINDS): it lands as one
var thrown := false ## by hand, on purpose: what it hits can be a crime (a flung one is an accident)
var range_left := 200.0
var hit_test: Callable
var _travelled := 0.0
var _total := 200.0


func launch(from: Vector2, dir: Vector2, speed: float, distance: float, test: Callable) -> void:
	position = from
	velocity = dir.normalized() * speed
	_total = distance
	range_left = distance
	hit_test = test
	z_index = 2


func _physics_process(delta: float) -> void:
	var step := velocity * delta
	position += step
	_travelled += step.length()
	range_left -= step.length()
	var hit: String = hit_test.call(position) if hit_test.is_valid() else ""
	if hit != "" or range_left <= 0.0:
		landed.emit(self, hit)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := Stone.texture(kind)
	var h := sin(clampf(_travelled / _total, 0.0, 1.0) * PI) * 26.0
	draw_circle(Vector2(0, 2), 4.0, Color(0, 0, 0, 0.35))
	draw_texture(t, -t.get_size() / 2.0 - Vector2(0, h))
