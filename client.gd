extends Node2D
## The customer standing on their patio, watching. Faces the mower and throws their
## arms up when they react. Palette-swapped to match their portrait.

var watch: Node2D
var _hop := 0.0
var _tex: Texture2D
var _out := false


func set_look(look: Dictionary) -> void:
	_tex = ImageTexture.create_from_image(Face.swapped("res://art/client.png", look))
	queue_redraw()


func react() -> void:
	if not _out:
		_hop = 0.8


func knock_out() -> void:
	_out = true
	_hop = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_hop = maxf(0.0, _hop - delta)
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var y := -absf(sin(_hop * 16.0)) * 5.0 if _hop > 0.0 else 0.0
	var flip := watch != null and is_instance_valid(watch) and watch.global_position.x < global_position.x
	var frame := 2 if _out else (1 if _hop > 0.0 else 0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if flip and not _out else 1, 1))
	draw_texture_rect_region(_tex, Rect2(-15, -30 + y, 30, 30), Rect2(frame * 30, 0, 30, 30))
