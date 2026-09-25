extends Node2D
## The customer's house along the top of the garden, with a patio they watch from,
## and a garage attached on one side that the drive leads up to. Not lawn. Seen 3/4:
## the ground footprint is `size` (the wall's foot at WALL_H, the patio below it) and
## the art stands up from the foot, over the neighbour's lawn behind.

const GARAGE_W := 120.0
const WALL_H := 106.0 ## the solid part, down to the foot of the front wall
const ART_FOOT := 348.0 ## y of the wall's foot in art/house.png (tools/art_sprites.py HOUSE_BASE)
const GARAGE_FOOT := 150.0 ## the same in art/garage.png
const GLASS := Rect2(0, 44, 30, 36) ## a ground-floor window's glass, from its x (main.gd WINDOWS)

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
	draw_texture(preload("res://art/house.png"), Vector2(0, WALL_H - ART_FOOT))
	draw_texture(preload("res://art/garage.png"), Vector2(-GARAGE_W if garage < 0 else size.x, WALL_H - GARAGE_FOOT))
	# A smashed pane: a dark hole inside the frame, jagged glass left round the edges.
	var glass := Color("a8d0e8")
	for x in broken:
		var o := GLASS.position + Vector2(x, 0)
		var s := GLASS.size
		draw_rect(Rect2(o, s), Color("1a1820"))
		for shard: PackedVector2Array in [
			[Vector2(0, 0), Vector2(0.4, 0), Vector2(0.08, 0.35)],
			[Vector2(1, 0), Vector2(1, 0.55), Vector2(0.7, 0)],
			[Vector2(0, 1), Vector2(0, 0.55), Vector2(0.25, 1)],
			[Vector2(1, 1), Vector2(0.55, 1), Vector2(0.88, 0.7)],
		]:
			var pts := PackedVector2Array()
			for v in shard:
				pts.append(o + v * s)
			draw_colored_polygon(pts, glass)
