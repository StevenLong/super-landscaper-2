# The garden's edges: hedges/fences border the property, critters come in from the
# right places (hedges, fences, trees; never behind the house), never walk through
# solid things, and the player on foot can't leave the garden.
extends SceneTree

var m: Node
var _frame := 0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	m.max_animals = 999
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		assert(m.get_node("Borders").get_child_count() >= 6, "the property has a border on every side (and a road out)")
		var house: Rect2 = m.get_node("Scenery/House").rect()
		var hedges: Array = m._edges.filter(func(e: Dictionary) -> bool: return e.kind == "hedge")
		for i in 40:
			var kind := "hedgehog" if i % 2 == 0 else "squirrel"
			var spot: Dictionary = m._spawn_spot(kind)
			var at: Vector2 = spot.get("edge", spot.at) # where it comes in over the boundary (or down a tree)
			assert(not (at.x > house.position.x and at.x < house.end.x and at.y < 20.0), "nothing comes from behind the house")
			if kind == "hedgehog" and not hedges.is_empty():
				assert(hedges.any(func(e: Dictionary) -> bool: return _near_line(at, e.from, e.to, 1.0)),
					"hedgehogs come in through a hedge, got %s" % at)
			if spot.grace <= 0.0:
				assert(not m._on_plot(spot.at), "walking in from next door, not popping up in the garden")
			assert(m.spawn_animal(kind) != null, "spawned")
		# Off the mower, you stay in the garden.
		m.hop_off()
		m.walker.global_position = Vector2(-200, -200)
	elif _frame == 4:
		assert(m.walker.global_position.x >= 0.0 and m.walker.global_position.y >= 0.0, "the player can't walk off the property")
	elif _frame > 4 and _frame < 600:
		for a in m.get_node("Animals").get_children():
			if a is Animal and not a.dead and a.grace <= 0.0:
				assert(not m._blocked(a.position), "a %s walked into something solid at %s" % [a.kind, a.position])
	elif _frame == 600:
		print("PASS edges")
		quit()
	return false


func _near_line(p: Vector2, a: Vector2, b: Vector2, tol: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= tol
