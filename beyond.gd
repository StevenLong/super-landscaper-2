extends Node2D
## What lies past the garden, varying per job: next door on each side (another house
## and garden, a patch of woods, or an empty lot), a row of trees behind the back
## fence, and houses across the road. Scenery only: none of it can be reached, and
## none of it is in main's Scenery, so critters, stones and canopy fading ignore it.

const HouseScript := preload("res://house.gd")
const TreeScript := preload("res://tree.gd")
const PLOT := 760.0 ## how wide each neighbour's plot is
const TINTS := [Color(1, 1, 1), Color(1, 0.92, 0.84), Color(0.86, 0.94, 1.0), Color(1, 1, 0.88), Color(0.96, 0.88, 0.92)]

var _r: RandomNumberGenerator
var _tree_i := 0


## w, h: the lawn; border: the hedge/fence run's depth; far: y of the road's far
## pavement's far edge; up: how far a hedge or fence rises.
func build(w: float, h: float, border: float, far: float, up: float, r: RandomNumberGenerator) -> void:
	y_sort_enabled = true
	_r = r
	for side in [-1, 1]:
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
	# Across the road: their front hedges, lawns, and the houses beyond.
	x = -PLOT - 280.0
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
	var hs := _house(Vector2(plot.position.x + (PLOT - 560.0) * 0.5 + (120.0 if side < 0 else 0.0), 0))
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
	if _r.randf() < 0.7:
		_tree(Vector2(plot.position.x + _r.randf_range(80, PLOT - 80), _r.randf_range(420, h - 60)), 42.0)


## A patch of woods: darker ground and trees packed in.
func _woods(plot: Rect2, side: int) -> void:
	_ground(preload("res://art/grass_dark.png"), Rect2(plot.position - Vector2(0, 80), plot.size + Vector2(0, 80)), Color(0.7, 0.8, 0.7))
	for i in 28:
		var x := _r.randf_range(plot.position.x + (60.0 if side > 0 else 0.0), plot.end.x - (60.0 if side < 0 else 0.0))
		_tree(Vector2(x, _r.randf_range(-20, plot.end.y - 20)), [34.0, 42.0, 50.0][_r.randi() % 3])


## An empty lot: patchy long grass and bare earth, a few stones, a sagging fence.
func _lot(plot: Rect2, h: float, border: float, up: float) -> void:
	_ground(preload("res://art/grass_long.png"), Rect2(plot.position, plot.size), Color(1.0, 0.95, 0.72))
	for i in 7:
		var sz := Vector2(_r.randf_range(60, 200), _r.randf_range(40, 120))
		var at := Vector2(_r.randf_range(plot.position.x, plot.end.x - sz.x), _r.randf_range(20, h - sz.y))
		_ground(preload("res://art/soil.png"), Rect2(at, sz))
	for i in 10:
		var s := Sprite2D.new()
		s.texture = preload("res://art/stone.png")
		s.position = Vector2(_r.randf_range(plot.position.x, plot.end.x), _r.randf_range(20, h - 20))
		add_child(s)
	_strip(preload("res://art/fence_h.png"), Rect2(plot.position.x, h + border - 32, plot.size.x, 32), 0, Color(0.8, 0.72, 0.6))


func _house(at: Vector2) -> Node2D:
	var hs: Node2D = HouseScript.new()
	hs.garage = [-1, 1][_r.randi() % 2]
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
