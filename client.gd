extends Node2D
## The customer standing on their patio, watching. Turns to follow the mower and
## hops when they react. Placeholder art until the art pass.

var watch: Node2D
var _hop := 0.0


func react() -> void:
	_hop = 0.5


func _process(delta: float) -> void:
	_hop = maxf(0.0, _hop - delta)
	queue_redraw()


func _draw() -> void:
	var y := -absf(sin(_hop * 18.0)) * 6.0 if _hop > 0.0 else 0.0
	var facing := 1.0
	if watch:
		facing = signf(watch.global_position.x - global_position.x)
		if facing == 0.0:
			facing = 1.0
	draw_rect(Rect2(-6, -22 + y, 12, 16), Color("4878c8"))
	draw_circle(Vector2(0, -28 + y), 7.0, Color("e8b088"))
	draw_circle(Vector2(3 * facing, -29 + y), 1.5, Color("1e2040"))
	draw_rect(Rect2(-5, -6 + y, 4, 8), Color("383040"))
	draw_rect(Rect2(1, -6 + y, 4, 8), Color("383040"))
