extends Node2D
## What lies past the garden, varying per job: next door on each side (another house
## and garden, a patch of woods, or an empty lot), a row of trees behind the back
## fence, and houses across the road. Scenery only: none of it can be reached, and
## none of it is in main's Scenery, so critters, stones and canopy fading ignore it.

const HouseScript := preload("res://house.gd")
const TreeScript := preload("res://tree.gd")
const BedScript := preload("res://flowerbed.gd")
const PLOT := 760.0 ## how wide each neighbour's plot is
const TINTS := [Color(1, 1, 1), Color(1, 0.92, 0.84), Color(0.86, 0.94, 1.0), Color(1, 1, 0.88), Color(0.96, 0.88, 0.92)]

var _r: RandomNumberGenerator
var _tree_i := 0
var _house_y := 0.0


## w, h: the lawn; border: the hedge/fence run's depth; far: y of the road's far
## pavement's far edge; up: how far a hedge or fence rises. The street matches the plot
## (game.gd _shape): a terrace has terraces either side, a house set forward has
## neighbours set forward too (house_y).
func build(w: float, h: float, border: float, far: float, up: float, r: RandomNumberGenerator, shape := "rect", house_y := 0.0) -> void:
	y_sort_enabled = true
	_r = r
	_house_y = house_y
	for side in [-1, 1]:
		if shape == "park": # the manor's estate: parkland past the ha-ha, no neighbours
			_park(Rect2(-border - PLOT * 2.0 if side < 0 else w + border, 0, PLOT * 2.0, h))
			continue
		if shape == "terrace":
			var park := r.randf() < 0.35 # the council playground at the end of the row
			for i in 3:
				var x := -border - (i + 1) * (w + border) if side < 0 else w + border + i * (w + border)
				if park and i == 0:
					_playground(Rect2(x, 0, w, h), border)
				else:
					_terrace(Rect2(x, 0, w, h), border, up)
			continue
		var plot := Rect2(-border - PLOT if side < 0 else w + border, 0, PLOT, h)
		match ["house", "house", "woods", "lot"][r.randi() % 4]:
			"house":
				_neighbour(plot, side, h, border, up)
			"woods":
				_woods(plot, side)
			"lot":
				_lot(plot, h, border, up)
	# Trees behind the back fence close the world off, poking up over the roofs.
	var x := -PLOT - border - 100.0
	while x < w + PLOT + 100.0:
		_tree(Vector2(x + r.randf_range(-15, 15), r.randf_range(-75, -50)), [42.0, 50.0][r.randi() % 2])
		x += r.randf_range(60.0, 95.0)
	# Across the road: their front hedges, lawns, and the houses beyond (fields, by the manor).
	x = -PLOT - 280.0
	if shape == "park":
		_strip(preload("res://art/hedge_h.png"), Rect2(x, far, w + PLOT * 2.0 + 280.0, 44), 0)
		_park(Rect2(x, far + 44, w + PLOT * 2.0 + 280.0, 420))
		return
	while x < w + PLOT:
		_strip(preload("res://art/hedge_h.png"), Rect2(x, far, 700, 44), 0)
		_ground(preload("res://art/gravel.png"), Rect2(x + 700, far, 60, 150), Color(1.0, 0.88, 0.68))
		_ground(preload("res://art/grass_light.png"), Rect2(x, far + 44, 700, 420), Color(0.85, 0.92, 0.8))
		_house(Vector2(x + r.randf_range(40, 100), far + 90))
		x += 760.0


## Another house like the customer's, with its garden, drive and front hedge or fence.
func _neighbour(plot: Rect2, side: int, h: float, border: float, up: float) -> void:
	var tidy := _r.randf() < 0.6
	if tidy: # mown in stripes
		for i in ceili(plot.size.x / 40.0):
			var tex: Texture2D = preload("res://art/grass_light.png") if i % 2 else preload("res://art/grass_dark.png")
			_ground(tex, Rect2(plot.position.x + i * 40.0, 0, minf(40.0, plot.end.x - plot.position.x - i * 40.0), h))
	else:
		_ground(preload("res://art/grass_long.png"), Rect2(plot.position, plot.size))
	# House and garage (560 wide) centred in the plot, so neither runs into a fence.
	var garage: int = [-1, 1][_r.randi() % 2]
	var hs := _house(Vector2(plot.position.x + (PLOT - 560.0) * 0.5 + (HouseScript.GARAGE_W if garage < 0 else 0.0), _house_y), garage)
	var g: Rect2 = hs.garage_rect()
	var drive := Rect2(g.position.x + 10, g.end.y, g.size.x - 20, h + border + 40.0 - g.end.y)
	_ground(preload("res://art/gravel.png"), drive, Color(1.0, 0.88, 0.68))
	var kind: Texture2D = [preload("res://art/hedge_h.png"), preload("res://art/fence_h.png")][_r.randi() % 2]
	for run: Vector2 in [Vector2(plot.position.x, drive.position.x), Vector2(drive.end.x, plot.end.x)]:
		_strip(kind, Rect2(run.x, h + border - kind.get_height(), run.y - run.x, kind.get_height()), 0)
	for run: Vector2 in [Vector2(plot.position.x, hs.rect().position.x), Vector2(hs.rect().end.x, plot.end.x)]:
		if hs.garage < 0 and run.x < hs.rect().position.x:
			run.y = g.position.x
		_strip(preload("res://art/fence_h.png"), Rect2(run.x, -32, run.y - run.x, 32), 0)
	var edge := plot.position.x - border if side < 0 else plot.end.x
	_strip(preload("res://art/fence_v.png"), Rect2(edge, -up, border, h + border), 0)
	# Their garden: stepping stones off the patio, and beds if they're tidy, dug-over
	# patches if not; a tree maybe. Kept clear of the drive.
	var p: Vector2 = hs.patio_point()
	for i in 5:
		_ground(preload("res://art/paving.png"), Rect2(p + Vector2(_r.randf_range(-3, 3) - 8.0, 14.0 + i * 24.0), Vector2(16, 10)))
	var yard := Rect2(plot.position.x + 40, hs.rect().end.y + 30, PLOT - 80, h - hs.rect().end.y - 90)
	for i in (_r.randi_range(1, 2) if tidy else _r.randi_range(2, 4)):
		var sz := Vector2(_r.randf_range(120, 220), _r.randf_range(60, 90)) if tidy else Vector2(_r.randf_range(50, 110), _r.randf_range(30, 50))
		var at := Vector2(_r.randf_range(yard.position.x, yard.end.x - sz.x), _r.randf_range(yard.position.y, yard.end.y - sz.y))
		if not Rect2(at, sz).grow(20).intersects(drive):
			_bed(Rect2(at, sz), tidy)
	if _r.randf() < 0.7 and yard.size.y > 100.0:
		_tree(Vector2(plot.position.x + _r.randf_range(80, PLOT - 80), _r.randf_range(yard.position.y + 60, yard.end.y)), 42.0)


## Another terrace like the customer's: the house at the road end with its passage, a
## long thin garden behind, fenced from the next.
func _terrace(plot: Rect2, border: float, up: float) -> void:
	var tidy := _r.randf() < 0.5
	_ground(preload("res://art/grass_light.png") if tidy else preload("res://art/grass_long.png"), plot, Color(0.85, 0.92, 0.8))
	var passage: int = [-1, 1][_r.randi() % 2]
	var hs: Node2D = HouseScript.new()
	hs.passage = true
	hs.garage = passage
	hs.position = Vector2(plot.position.x + (HouseScript.GARAGE_W if passage < 0 else 0.0), _house_y)
	hs.modulate = TINTS[_r.randi() % TINTS.size()]
	add_child(hs)
	var g: Rect2 = hs.garage_rect()
	_ground(preload("res://art/paving.png"), Rect2(g.position.x + 10, g.position.y, g.size.x - 20, plot.end.y + border + 40.0 - g.position.y))
	_strip(preload("res://art/fence_v.png"), Rect2(plot.end.x, -up, border, plot.size.y + border), 0)
	_strip(preload("res://art/fence_h.png"), Rect2(plot.position.x, -32, plot.size.x, 32), 0)
	_strip(preload("res://art/hedge_h.png"), Rect2(plot.position.x, plot.end.y + border - 44, hs.rect().size.x, 44), 0)
	for i in _r.randi_range(0, 2): # beds, or dug-over patches, down the garden
		var sz := Vector2(_r.randf_range(90, 200), _r.randf_range(40, 80))
		_bed(Rect2(plot.position + Vector2(_r.randf_range(30, plot.size.x - sz.x - 30), _r.randf_range(60, _house_y - sz.y - 80)), sz), tidy)
	if _r.randf() < 0.6:
		_tree(Vector2(plot.position.x + _r.randf_range(80, plot.size.x - 80), _r.randf_range(120, _house_y - 80)), [34.0, 42.0][_r.randi() % 2])


## The council playground next to the terraces: rough grass, a tarmac pad by the road with
## swings, a slide and a roundabout, railings along the front.
func _playground(plot: Rect2, border: float) -> void:
	_ground(preload("res://art/grass_long.png"), plot, Color(0.9, 0.95, 0.75))
	var pad := Rect2(plot.position.x + 30, _house_y + 40, plot.size.x - 60, plot.end.y - _house_y - 60)
	_ground(preload("res://art/paving.png"), pad, Color(0.95, 0.55, 0.45)) # the red safety surface
	var rail := Color(0.45, 0.6, 0.5)
	_strip(preload("res://art/fence_h.png"), Rect2(plot.position.x, plot.end.y + border - 32, plot.size.x, 32), 0, rail)
	_strip(preload("res://art/fence_v.png"), Rect2(plot.end.x, -32.0, border, plot.size.y + border), 0, rail)
	_kit(Vector2(pad.position.x + 90, pad.position.y + 90), "swings")
	_kit(Vector2(pad.end.x - 90, pad.position.y + 100), "slide")
	_kit(Vector2(pad.get_center().x, pad.end.y - 70), "roundabout")
	for i in 3:
		_tree(Vector2(plot.position.x + _r.randf_range(80, plot.size.x - 80), _r.randf_range(100, _house_y - 60)), 50.0)


## One bit of playground kit, standing at its foot. Drawn plain (tools/make_art.py has no art for it).
func _kit(foot: Vector2, what: String) -> void:
	var k := Node2D.new()
	k.position = foot
	k.scale = Vector2(1.6, 1.6)
	k.draw.connect(_draw_kit.bind(k, what))
	add_child(k)


func _draw_kit(k: Node2D, what: String) -> void:
	var steel := Color("c83c30")
	var dark := Color("2a2a30")
	match what:
		"swings": # an A-frame side-on to you: two posts, the bar, two seats on chains
			for x: float in [-48.0, 48.0]:
				k.draw_line(Vector2(x - 8, 0), Vector2(x, -60), steel, 3.0)
				k.draw_line(Vector2(x + 8, 0), Vector2(x, -60), steel, 3.0)
			k.draw_line(Vector2(-50, -60), Vector2(50, -60), steel, 4.0)
			for x: float in [-22.0, 22.0]:
				k.draw_line(Vector2(x - 8, -60), Vector2(x - 8, -18), dark, 1.0)
				k.draw_line(Vector2(x + 8, -60), Vector2(x + 8, -18), dark, 1.0)
				k.draw_rect(Rect2(x - 10, -19, 20, 4), dark)
		"slide": # a ladder up to a platform, and the chute down
			k.draw_line(Vector2(-30, 0), Vector2(-30, -56), Color("8a8a90"), 2.0)
			k.draw_line(Vector2(-18, 0), Vector2(-18, -56), Color("8a8a90"), 2.0)
			for y in range(-8, -56, -8):
				k.draw_line(Vector2(-30, y), Vector2(-18, y), Color("8a8a90"), 2.0)
			k.draw_rect(Rect2(-32, -60, 20, 5), steel)
			k.draw_colored_polygon(PackedVector2Array([Vector2(-12, -60), Vector2(-12, -52), Vector2(40, -2), Vector2(48, -2), Vector2(48, -8)]), Color("e8c040"))
		"roundabout": # a flat disc, seen at a slant, with a rail round the middle
			k.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			k.draw_circle(Vector2(0, 4), 38.0, dark)
			k.draw_circle(Vector2.ZERO, 38.0, Color("3a70c0"))
			k.draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, steel, 3.0)
			k.draw_set_transform(Vector2.ZERO)
			k.draw_line(Vector2(0, 0), Vector2(0, -22), steel, 3.0)


## Next door's corner of an L plot: their lawn, and a tree maybe.
func corner(box: Rect2, tint: Color) -> void:
	_ground(preload("res://art/grass_light.png"), box, tint)
	if box.size.x > 140.0 and _r.randf() < 0.7:
		_tree(Vector2(box.get_center().x + _r.randf_range(-30, 30), box.position.y + box.size.y * 0.5), 42.0)


## Estate parkland: rough pasture with big trees standing well apart.
func _park(box: Rect2) -> void:
	_ground(preload("res://art/grass_long.png"), box, Color(0.95, 1.0, 0.8))
	for i in int(box.size.x * box.size.y / 90000.0):
		_tree(Vector2(_r.randf_range(box.position.x + 40, box.end.x - 40), _r.randf_range(box.position.y + 60, box.end.y - 20)), [50.0, 50.0, 42.0][_r.randi() % 3])


## A patch of woods: darker ground and trees packed in.
func _woods(plot: Rect2, side: int) -> void:
	_ground(preload("res://art/grass_dark.png"), Rect2(plot.position - Vector2(0, 80), plot.size + Vector2(0, 80)), Color(0.7, 0.8, 0.7))
	for i in 28:
		var x := _r.randf_range(plot.position.x + (60.0 if side > 0 else 0.0), plot.end.x - (60.0 if side < 0 else 0.0))
		_tree(Vector2(x, _r.randf_range(-20, plot.end.y - 20)), [34.0, 42.0, 50.0][_r.randi() % 3])


## An empty lot: patchy long grass and bare earth, a few stones, a sagging fence.
func _lot(plot: Rect2, h: float, border: float, up: float) -> void:
	_ground(preload("res://art/grass_long.png"), Rect2(plot.position, plot.size), Color(1.0, 0.95, 0.72))
	for i in 7: # churned-up earth in rough curves, and weeds
		var sz := Vector2(_r.randf_range(60, 200), _r.randf_range(40, 120))
		var at := Vector2(_r.randf_range(plot.position.x, plot.end.x - sz.x), _r.randf_range(20, h - sz.y))
		_bed(Rect2(at, sz), false)
	for i in 10:
		var s := Sprite2D.new()
		s.texture = preload("res://art/stone.png")
		s.position = Vector2(_r.randf_range(plot.position.x, plot.end.x), _r.randf_range(20, h - 20))
		add_child(s)
	_strip(preload("res://art/fence_h.png"), Rect2(plot.position.x, h + border - 32, plot.size.x, 32), 0, Color(0.8, 0.72, 0.6))


## A curved bed (flowerbed.gd's shapes): in flower, or bare dug earth.
func _bed(box: Rect2, flowers: bool) -> void:
	var b: Node2D = BedScript.new()
	b.position = box.position
	b.size = box.size
	b.shape = ["oval", "kidney", "bean"][_r.randi() % 3]
	if not flowers:
		b.spacing = 10000.0
	var a := Area2D.new() # flowerbed.gd tramples through it; nothing reaches next door
	a.name = "Area"
	a.monitoring = false
	a.monitorable = false
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	a.add_child(cs)
	b.add_child(a)
	add_child(b)


func _house(at: Vector2, garage := 0) -> Node2D:
	var hs: Node2D = HouseScript.new()
	hs.garage = garage if garage != 0 else [-1, 1][_r.randi() % 2]
	hs.position = at
	hs.modulate = TINTS[_r.randi() % TINTS.size()]
	add_child(hs)
	return hs


func _tree(base: Vector2, canopy: float) -> void:
	var t: StaticBody2D = TreeScript.new()
	t.collision_layer = 0
	t.position = base
	t.canopy = canopy
	t.variant = _tree_i
	_tree_i += 1
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	cs.disabled = true
	t.add_child(cs)
	add_child(t)


func _ground(tex: Texture2D, box: Rect2, tint := Color.WHITE) -> void:
	var g := TextureRect.new()
	g.texture = tex
	g.stretch_mode = TextureRect.STRETCH_TILE
	g.position = box.position
	g.size = box.size
	g.self_modulate = tint
	g.z_index = -2 # the ground, under anything standing
	add_child(g)


func _strip(tex: Texture2D, box: Rect2, z: int, tint := Color.WHITE) -> void:
	var s := TextureRect.new()
	s.texture = tex
	s.stretch_mode = TextureRect.STRETCH_TILE
	s.position = box.position
	s.size = box.size
	s.self_modulate = tint
	s.z_index = z
	add_child(s)
