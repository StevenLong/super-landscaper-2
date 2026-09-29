# Thrown critters (the S12 fallout): a hater doesn't mind one hitting the house wall, and a
# slam knockout they see pleases them; one thrown already out cold dies of the slam, and a
# stone at a knocked-out critter kills it; a stone that hits a critter lands beside it; a
# real throw over the hedge is seen going over, and one from right by it bounces back.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0
var _stones := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _critters(kind: String) -> Array:
	return m.get_node("Animals").get_children().filter(func(a: Node) -> bool: return a is Animal and a.kind == kind and not a.is_queued_for_deletion())


func _fly(kind: String, target: String, speed: float, out := 0.0) -> void:
	var f := FlyingStone.new()
	f.kind = kind
	f.thrown = true
	f.out = out
	f.velocity = Vector2.UP * speed
	f.position = Vector2(640, 600) # open grass the patio can see (as test_critters)
	m._on_stone_landed(f, target)
	f.free()


func _loose_stones() -> int:
	return m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return not s is FlyingStone).size()


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.customer.where = "patio"
			assert(m.customer.sees(Vector2(640, 600)), "the test spot is in sight")
			m.customer.persona = g.PERSONAS.squirrel_hater
			m.customer.mood = 50.0
			_fly("squirrel", "wall", 0.0) # a soft one: no knockout, just the wall
			assert(m.customer.mood == 50.0, "a hater doesn't mind a squirrel against the house")
			_fly("squirrel", "fence", 400.0) # hard: knocked out
			assert(m.customer.mood > 50.0 and m.tally.get("ko_squirrel", 0) == 1, "a slam knockout pleases a hater")
			m.customer.persona = g.PERSONAS.nature
			m.customer.mood = 50.0
			_fly("squirrel", "wall", 0.0)
			assert(m.customer.mood < 50.0, "but the wall still bothers anyone else")
			_wait = 2 # they land a frame later
		1:
			for a in _critters("squirrel"):
				a.free()
			_fly("squirrel", "fence", 400.0, 3.0) # thrown out cold already
			_wait = 2
		2:
			var s := _critters("squirrel")
			assert(s.size() == 1 and s[0].body and m.tally.get("slammed_squirrel", 0) == 1, "slammed out cold, it dies: a body")
			var h: Animal = m.spawn_animal("hedgehog", Vector2(700, 500), Vector2(700, 500))
			h.speed = 0.0
			m._stone_critter(h, true, 0.0) # a roll that knocks out
			assert(h.out > 0.0 and not h.body, "one stone knocks it out")
			m._stone_critter(h, true, 0.0)
			assert(h.body, "a second, out cold, kills it")
			_stones = _loose_stones()
			var f := FlyingStone.new()
			f.thrown = true
			f.velocity = Vector2.UP * 300.0
			f.position = h.position
			m._on_stone_landed(f, "animal")
			f.free()
			_wait = 2
		3:
			assert(_loose_stones() == _stones + 1, "a stone that hits a critter lands beside it")
			m.hop_off()
			m.walker.global_position = Vector2(100, 600)
			m.walker.rotation = PI
			m.walker.pitch = 0.5
			m.walker.carrying = "squirrel"
			var path: Array = m._throw_path(1.0)
			assert(path[1] == "ground" and path[0][-1].x < -24.0, "a full throw from 100 px clears the hedge: %s at %s" % [path[1], path[0][-1]])
			assert(m.customer.sees(Vector2(path[0][-1].x, path[0][-1].y)), "and lands in sight")
			for a in _critters("squirrel"):
				a.free()
			m.customer.persona = g.PERSONAS.squirrel_hater
			m.customer.mood = 50.0
			m._on_thrown(Vector2.LEFT, 1.0)
			_wait = 75 # about a second's flight; checked before it wanders off
		4:
			assert(m.customer.mood > 50.0, "seen going over, a hater is glad")
			assert(_critters("squirrel").any(func(a: Animal) -> bool: return a.position.x < 0.0), "and it's next door")
			m.walker.global_position = Vector2(8, 600)
			m.walker.carrying = "squirrel"
			assert(m._throw_path(1.0)[1] == "fence", "right by the hedge, it bounces off")
			print("PASS slam")
			quit()
	_step += 1
	return false
