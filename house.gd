extends Node2D
## The customer's house along the top of the garden, with a patio they watch from.
## Not lawn. Placeholder art until the art pass replaces _draw with a sprite.

@export var size := Vector2(440, 130)


func rect() -> Rect2:
	return Rect2(position, size)


func patio_point() -> Vector2:
	return position + Vector2(size.x * 0.5, size.y - 16)


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y - 34), Color("b86848"))
	draw_rect(Rect2(0, 0, size.x, 26), Color("6a3a3a"))
	for i in 4:
		draw_rect(Rect2(30 + i * (size.x - 80) / 3.0, 40, 36, 30), Color("88b8d8"))
	draw_rect(Rect2(size.x * 0.5 - 18, size.y - 80, 36, 46), Color("5a3a28"))
	draw_rect(Rect2(0, size.y - 34, size.x, 34), Color("a8a098"))
