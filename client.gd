extends Node2D
## The customer standing on their patio, watching. Faces the mower and throws their
## arms up when they react. Palette-swapped to match their portrait.

var watch: Node2D
var _hop := 0.0
var _tex: Texture2D


func set_look(look: Dictionary) -> void:
	_tex = ImageTexture.create_from_image(Face.swapped("res://art/client.png", look))
	queue_redraw()


func react() -> void:
	_hop = 0.8


func _process(delta: float) -> void:
	_hop = maxf(0.0, _hop - delta)
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var y := -absf(sin(_hop * 16.0)) * 5.0 if _hop > 0.0 else 0.0
	var flip := watch != null and watch.global_position.x < global_position.x
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(_tex, Rect2(-9, -30 + y, 18, 30), Rect2(18 if _hop > 0.0 else 0, 0, 18, 30))
