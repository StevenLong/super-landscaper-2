# Check fallout, 2026-09-28 (NOTES 114, 115, 118, 119, 124, 131, 138, 139): paid means
# you can't be fired; a broken pane is a hole, not another bill; a knocked-out critter
# stays out in your hands and where you put it; thrown hard into a wall, one is knocked
# out; squirrels only climb down trees; at the L plot and the churchyard, critters get
# into the garden instead of spinning in a wall; a stone lobbed over the fence lands
# next door, out of reach.
extends SceneTree

var g: Node
var m: Node
var _step := 0
var _wait := 0
var _a: Animal
var _spawned: Array = []


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	var c := Customer.new(g.default_job())
	c.paid = true
	c._change(-200.0)
	assert(not c.fired, "once paid, you can't be fired")
	c = Customer.new(g.default_job())
	c.where = "inside"
	c.sight = func(_p: Vector2) -> bool: return false
	var mood := c.mood
	assert(c.on_dog_returned(Vector2(10, 10)) and c.mood > mood and c.where == "patio", "the dog brought home while they're in: they come out, pleased")
	_open({})


func _open(job: Dictionary) -> void:
	g.current_job = job
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	m.max_animals = 999
	root.add_child(m)
	_wait = 2


func _find(rep: float, key: String, want: String) -> Dictionary:
	g.reputation = rep
	for s in range(1, 400):
		var j: Dictionary = g.make_job(s)
		if j.get(key, "") == want:
			return j
	return {}


## Spawn a batch from next door and give them time to walk in.
func _spawn_batch() -> void:
	_spawned.clear()
	for i in 24:
		var a: Animal = m.spawn_animal("hedgehog" if i % 2 == 0 else "squirrel")
		if a:
			_spawned.append(a)
	assert(_spawned.size() > 0, "critters come")
	_wait = 600


func _check_batch(where: String) -> void:
	# Stuck is what the dev saw: at the boundary, never getting in (spinning in a wall). One
	# still out past it, far off, is walking in or has wandered off next door.
	var stuck := _spawned.filter(func(a: Animal) -> bool:
		return is_instance_valid(a) and not a.visited and not a.on_plot and a.position.distance_to(m.lawn.keep_in(a.position, 0.0)) < 40.0)
	assert(stuck.is_empty(), "%s: %d of %d critters stuck at the boundary: %s" % [where, stuck.size(), _spawned.size(),
		stuck.map(func(a: Animal) -> String: return "%s at %s" % [a.kind, a.position])])


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			# A broken pane is a hole: the next stone goes in, no second bill.
			var h: Node2D = m._house
			var p := Vector2(h.position.x + h.windows()[0] + 15.0, h.position.y + h.WALL_H - 2.0)
			var z := 40.0
			assert(m._building_hit(p, z) == "window", "glass there")
			h.smash(m._window_at(p, z))
			assert(m._building_hit(p, z) == "hole", "broken, it's a hole")
			var bills: float = m.bills
			var f := FlyingStone.new()
			f.position = p
			f.z = z
			m._on_stone_landed(f, "hole")
			f.free()
			assert(m.bills == bills and m.tally.get("windows", 0) == 0, "no second bill for the same window")
			# Squirrels only come down trees, never out of a rock or a headstone.
			for i in 200:
				var spot: Dictionary = m._spawn_spot("squirrel")
				if spot.grace > 0.0:
					var trees: Array = m.get_node("Scenery").get_children().filter(func(t: Node) -> bool:
						return t.has_method("shake") and (t as Node2D).position.distance_to(spot.at) < 60.0)
					assert(not trees.is_empty(), "a squirrel climbs down a tree, got %s" % spot.at)
			# A knocked-out squirrel stays out in your hands (no bite) and where you put it.
			m.hop_off()
			m.walker.global_position = Vector2(500, 400)
			_a = m.spawn_animal("squirrel", Vector2(510, 400), Vector2(511, 400))
			_a.stun(5.0)
			_wait = 1
		1:
			m.interact()
			assert(m.walker.carrying == "squirrel", "picked up")
			_wait = int(m.CRITTERS.squirrel.hold * 60.0) - 60 # awake it would bite; out cold it's past the bite by 1 s less
		2:
			assert(m.walker.carrying == "squirrel" and m.tally.get("bitten", 0) == 0, "out cold, it doesn't bite")
			m.interact()
			_wait = 2
		3:
			var laid: Array = m.get_node("Animals").get_children().filter(func(a: Node) -> bool: return a is Animal and a.kind == "squirrel")
			assert(laid.size() == 1 and laid[0].out > 0.0, "put down, it's still out cold")
			laid[0].free()
			# Thrown hard into the house wall, a live squirrel is knocked out.
			var h: Node2D = m._house
			var f := FlyingStone.new()
			f.kind = "squirrel"
			f.thrown = true
			f.position = Vector2(h.position.x + 5.0, h.position.y + h.WALL_H - 2.0)
			f.velocity = Vector2(0, -300)
			m._on_stone_landed(f, "wall")
			f.free()
			_wait = 2
		4:
			var laid: Array = m.get_node("Animals").get_children().filter(func(a: Node) -> bool: return a is Animal and a.kind == "squirrel")
			assert(laid.size() == 1 and laid[0].out > 0.0, "slammed into the wall, it's knocked out")
			laid[0].free()
			# Lobbed high over the side fence: it lands next door and stays there, out of reach.
			var edge := Vector2(float(m.lawn.size_px.x) - 60.0, 400.0) # far enough back to clear the fence
			m.walker.global_position = edge
			var f: FlyingStone = m.throw_stone(edge, Vector2.RIGHT, 260.0, 1.0, "stone")
			f.thrown = true
			_wait = 120
		5:
			var out: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is Stone and not m._on_plot(s.position))
			assert(out.size() == 1, "the stone lies next door, not gone")
			assert(m._stone_near(m.walker.global_position) == null and m._stone_near(out[0].position) == null, "and you can't reach it")
			m.queue_free()
			_open(_find(85.0, "shape", "L"))
		6:
			assert(m._notch.has_area(), "an L plot")
			_spawn_batch()
		7:
			_check_batch("L plot")
			m.queue_free()
			_open(_find(10.0, "venue", "graveyard"))
		8:
			assert(m._house.venue == "graveyard", "the churchyard")
			_spawn_batch()
		9:
			_check_batch("churchyard")
			g.current_job = {}
			print("PASS fallout")
			quit()
	_step += 1
	return false
