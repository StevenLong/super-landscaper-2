extends Control
## Vertical fuel gauge: fills from the bottom, green when full shading to red when
## empty, F at the top, E at the bottom, notches up the side. Below low_fraction a
## soft outline pulses around it.

@export var low_fraction := 0.2
@export var notches := 8
@export var pulse_speed := 4.0 ## radians per second

var value := 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()

@export var top_label := "F"
@export var bottom_label := "E"

var stamina := false: ## a push mower: label it as energy, not fuel
	set(v):
		stamina = v
		top_label = "PEP" if v else "F"
		bottom_label = "ZZZ" if v else "E"
		queue_redraw()

var _t := 0.0


func _process(delta: float) -> void:
	if value < low_fraction:
		_t += delta
		queue_redraw()


func fill_color() -> Color:
	return Color.from_hsv(value * 0.33, 0.8, 0.85)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var label_h := 22.0
	var tube := Rect2(0, label_h, size.x, size.y - label_h * 2.0)

	if value < low_fraction:
		var a := 0.25 + 0.35 * (0.5 + 0.5 * sin(_t * pulse_speed))
		draw_rect(tube.grow(5.0), Color(1, 0.2, 0.15, a), false, 4.0)

	draw_rect(tube, Color(0, 0, 0, 0.55))
	var fill_h := tube.size.y * value
	draw_rect(Rect2(tube.position.x, tube.end.y - fill_h, tube.size.x, fill_h), fill_color())
	for i in range(1, notches):
		var y := tube.end.y - tube.size.y * float(i) / notches
		var w := tube.size.x * (0.5 if i % 2 == 0 else 0.3)
		draw_line(Vector2(tube.position.x, y), Vector2(tube.position.x + w, y), Color(0, 0, 0, 0.6), 2.0)
	draw_rect(tube, Color(0.9, 0.9, 0.9), false, 2.0)

	var fs := 10
	draw_string(font, Vector2(-20, label_h - 4), top_label, HORIZONTAL_ALIGNMENT_CENTER, size.x + 40, fs)
	draw_string(font, Vector2(-20, size.y - 4), bottom_label, HORIZONTAL_ALIGNMENT_CENTER, size.x + 40, fs)
