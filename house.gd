extends Node2D
## The customer's house along the top of the garden, with a patio they watch from.
## Not lawn. Fixed size to match art/house.png.

var size := Vector2(440, 130)


func rect() -> Rect2:
	return Rect2(position, size)


func patio_point() -> Vector2:
	return position + Vector2(size.x * 0.5 + 44, size.y - 6)


func _draw() -> void:
	draw_texture(preload("res://art/house.png"), Vector2.ZERO)
