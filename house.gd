extends Node2D
## The customer's house along the top of the garden, with a patio they watch from.
## Not lawn. Fixed size to match art/house.png.

var size := Vector2(440, 130)
var broken: Array[int] = [] ## x of each smashed window (main.gd WINDOWS)


func rect() -> Rect2:
	return Rect2(position, size)


func patio_point() -> Vector2:
	return position + Vector2(size.x * 0.5 + 44, size.y - 6)


func smash(window_x: int) -> void:
	if window_x not in broken:
		broken.append(window_x)
		queue_redraw()


func _draw() -> void:
	draw_texture(preload("res://art/house.png"), Vector2.ZERO)
	# A smashed pane: a dark hole inside the frame, jagged glass left round the edges.
	var glass := Color("a8d0e8")
	for x in broken:
		var o := Vector2(x + 3, 72)
		draw_rect(Rect2(o, Vector2(24, 18)), Color("1a1820"))
		for shard: PackedVector2Array in [
			[Vector2(0, 0), Vector2(9, 0), Vector2(2, 7)],
			[Vector2(24, 0), Vector2(24, 11), Vector2(17, 0)],
			[Vector2(0, 18), Vector2(0, 10), Vector2(6, 18)],
			[Vector2(24, 18), Vector2(13, 18), Vector2(21, 13)],
		]:
			var pts := PackedVector2Array()
			for v in shard:
				pts.append(o + v)
			draw_colored_polygon(pts, glass)
