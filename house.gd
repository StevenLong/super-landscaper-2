extends Node2D
## The customer's house along the top of the garden, with a patio they watch from,
## and a garage attached on one side that the drive leads up to. Not lawn. Fixed size
## to match art/house.png; the garage is built from slices of the same art.

const GARAGE_W := 120.0
const WALL_H := 106.0 ## the solid part, down to the bottom of the brick course

var size := Vector2(440, 130)
var garage := 1 ## which side it's on: -1 left, 1 right
var broken: Array[int] = [] ## x of each smashed window (main.gd WINDOWS)


func rect() -> Rect2:
	return Rect2(position, size)


func garage_rect() -> Rect2:
	return Rect2(position + Vector2(-GARAGE_W if garage < 0 else size.x, 0), Vector2(GARAGE_W, WALL_H))


## The house and garage together, for keeping other things clear of them.
func footprint() -> Rect2:
	return rect().merge(garage_rect())


func patio_point() -> Vector2:
	return position + Vector2(size.x * 0.5 + 44, size.y - 6)


func smash(window_x: int) -> void:
	if window_x not in broken:
		broken.append(window_x)
		queue_redraw()


func _draw() -> void:
	var art := preload("res://art/house.png")
	draw_texture(art, Vector2.ZERO)
	# The garage: the house's roof and plain wall carried on, with an up-and-over door.
	var gx := -GARAGE_W if garage < 0 else size.x
	draw_texture_rect_region(art, Rect2(gx, 0, GARAGE_W, 62), Rect2(4, 0, GARAGE_W, 62))
	for i in ceili(GARAGE_W / 32.0):
		var w := minf(32.0, GARAGE_W - i * 32.0)
		draw_texture_rect_region(art, Rect2(gx + i * 32.0, 62, w, WALL_H - 62), Rect2(4, 62, w, WALL_H - 62))
	var door := Rect2(gx + 12, 68, GARAGE_W - 24, WALL_H - 68)
	draw_rect(door.grow(2), Color("4a3a2e"))
	draw_rect(door, Color("d8d2c2"))
	for y in range(int(door.position.y) + 5, int(door.end.y), 6):
		draw_line(Vector2(door.position.x, y), Vector2(door.end.x, y), Color("aaa498"))
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
