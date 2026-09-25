extends Node2D
## The customer's house at the top of the garden, with a patio they watch from, and a
## garage attached on one side that the drive leads up to. Not lawn. Seen 3/4: the art
## stands up from the front wall's foot at WALL_H, and its ridge meets the back fence
## (y 0), so the ground from the fence to the foot is all house. What's behind the roof
## can't be seen, so it can't be reached either. The garage is lower: the lawn carries
## on behind it.

const GARAGE_W := 120.0
const ART_FOOT := 348.0 ## y of the wall's foot in art/house.png (tools/art_sprites.py HOUSE_BASE)
const ART_RIDGE := 36.0 ## y of its ridge
const WALL_H := ART_FOOT - ART_RIDGE ## back fence to the foot of the front wall: all solid
const GARAGE_FOOT := 150.0 ## the foot in art/garage.png
const GARAGE_H := GARAGE_FOOT - 4.0 ## its roof's top to its foot: the solid part
const GLASS := Rect2(0, -62, 30, 36) ## a ground-floor window's glass, from its x (main.gd WINDOWS) and the foot

var size := Vector2(440, WALL_H + 24.0) ## the house and its patio
var garage := 1 ## which side it's on: -1 left, 1 right
var broken: Array[int] = [] ## x of each smashed window (main.gd WINDOWS)


func rect() -> Rect2:
	return Rect2(position, size)


func garage_rect() -> Rect2:
	return Rect2(position + Vector2(-GARAGE_W if garage < 0 else size.x, WALL_H - GARAGE_H), Vector2(GARAGE_W, GARAGE_H))


## The house and garage together, for keeping other things clear of them.
func footprint() -> Rect2:
	return rect().merge(garage_rect())


func patio_point() -> Vector2:
	return position + Vector2(size.x * 0.5 + 44, size.y - 6)


func smash(window_x: int) -> void:
	if window_x not in broken:
		broken.append(window_x)
		_front.queue_redraw()


## The art hangs off two children standing at the wall's foot, so depth sorting puts
## whatever is behind the garage (or the house) behind it, not in front.
var _front: Node2D


func _ready() -> void:
	y_sort_enabled = true
	_front = Node2D.new()
	_front.position = Vector2(0, WALL_H)
	_front.draw.connect(_draw_house)
	add_child(_front)
	var g := Sprite2D.new()
	g.texture = preload("res://art/garage.png")
	g.centered = false
	g.position = Vector2(-GARAGE_W if garage < 0 else size.x, WALL_H)
	g.offset = Vector2(0, -GARAGE_FOOT)
	add_child(g)


func _draw_house() -> void:
	_front.draw_texture(preload("res://art/house.png"), Vector2(0, -ART_FOOT))
	# A smashed pane: a dark hole inside the frame, jagged glass left round the edges.
	var glass := Color("a8d0e8")
	for x in broken:
		var o := GLASS.position + Vector2(x, 0)
		var s := GLASS.size
		_front.draw_rect(Rect2(o, s), Color("1a1820"))
		for shard: PackedVector2Array in [
			[Vector2(0, 0), Vector2(0.4, 0), Vector2(0.08, 0.35)],
			[Vector2(1, 0), Vector2(1, 0.55), Vector2(0.7, 0)],
			[Vector2(0, 1), Vector2(0, 0.55), Vector2(0.25, 1)],
			[Vector2(1, 1), Vector2(0.55, 1), Vector2(0.88, 0.7)],
		]:
			var pts := PackedVector2Array()
			for v in shard:
				pts.append(o + v * s)
			_front.draw_colored_polygon(pts, glass)
