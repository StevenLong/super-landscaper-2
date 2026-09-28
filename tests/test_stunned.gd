# A stone into a critter: thrown, it knocks out (lies there, wakes and runs) or kills it
# leaving a body; flung by the blades, it splats or knocks out. A body can be carried,
# thrown over the fence or mowed to nothing. A body left lying in view is found after
# you've gone (not when they step out); one gone by then never is.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0
var _h: Animal
var _before := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _still(at: Vector2) -> Animal:
	var a: Animal = m.spawn_animal("hedgehog", at, at + Vector2.RIGHT)
	a.speed = 0.0
	return a


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			_h = _still(Vector2(640, 600))
			_wait = 2
		1:
			m._stone_critter(_h, true, 0.0) # thrown, the likely roll: out cold
			assert(_h.out > 0.0 and not _h.dead and not _h.body and m.tally.get("ko_hedgehog", 0) == 1, "a thrown stone knocks it out")
			assert(m._stone_hit_test(_h.position) == "animal", "out cold, it can still be hit")
			_wait = int(m.KO_TIME * 60.0) + 10
		2:
			assert(_h.out <= 0.0 and not _h.dead, "it comes round")
			_h.queue_free()
			_h = _still(Vector2(640, 600))
			m._stone_critter(_h, false, 0.0) # flung by the blades, the likely roll: a splat
			assert(_h.dead and m._splats.size() == 1, "a blade-flung stone splats it")
			# Thrown, the unlucky roll: a body, belly up, no splat.
			_h = _still(Vector2(500, 600))
			m.customer.where = "inside" # nobody watching
			m._stone_critter(_h, true, 0.99)
			assert(_h.body and not _h.dead and m._splats.size() == 1, "killed by a thrown stone: an intact body")
			assert(m._stone_hit_test(_h.position) == "", "stones fly over a body")
			assert(m._bodies("hedgehog") == 1, "one body on the lawn")
			# Pick it up and throw it over the fence.
			m.hop_off()
			m.walker.global_position = _h.position
			m.interact()
			assert(m.walker.carrying == "body_hedgehog", "you pick up the body")
			_wait = 2
		3:
			assert(m._bodies("hedgehog") == 0, "in your hands, not on the lawn")
			var f := FlyingStone.new()
			f.kind = "body_hedgehog"
			f.thrown = true
			f.position = Vector2(-5, 300)
			m._on_stone_landed(f, "gone")
			f.free()
			m.walker.carrying = ""
			assert(m.tally.get("bodies_hidden", 0) == 1, "over the fence: next door's problem")
			var mood: float = m.customer.mood
			m.customer.come_out()
			assert(m.customer.mood == mood, "they come out and find nothing")
			# Set down, a body lies there; mowed, it's mulch, and nothing is left to find.
			m._land(Vector2(700, 650), "body_hedgehog")
			_wait = 2
		4:
			assert(m._bodies("hedgehog") == 1, "set down, it lies there")
			var b: Animal = m.get_node("Animals").get_children().filter(func(a: Node) -> bool: return a is Animal and a.body)[0]
			# Left lying in view while they're in: stepping out finds nothing, leaving it does.
			m.customer.where = "inside"
			m._stone_critter(_still(Vector2(300, 650)), true, 0.99)
			var mood: float = m.customer.mood
			m.customer.come_out()
			assert(m.customer.mood == mood, "stepping out, they find nothing")
			var found: Array = m.customer.aftermath(m._bodies_in_view(), false)
			assert(found.size() == 1 and found[0][0] == "2 dead hedgehogs on the lawn" and found[0][1] < 0.0,
				"after you've gone, both bodies in view are found: %s" % [found])
			m.customer.where = "inside"
			b.squash()
			assert(m.tally.get("bodies_mulched", 0) == 1 and m._splats.size() == 1, "mowed: mulch, no splat")
			assert(m._bodies_in_view().get("hedgehog", 0) == 1, "and mulched, it isn't there to find")
			for a in m.get_node("Animals").get_children():
				a.queue_free()
			# Carried into view, a body counts once, however often it's put down and picked up.
			g.upgrades.assign(["gloves"])
			m.customer.where = "patio"
			_h = _still(Vector2(640, 600))
			_h.kill()
			m.walker.global_position = _h.position
			m.walker.rotation = 0.0
			_wait = 2
		5:
			m.interact()
			assert(m.walker.carrying == "body_hedgehog", "picked up")
			var mood: float = m.customer.mood
			m._carried_into_view()
			assert(m.customer.mood < mood, "they see you with it")
			m.interact() # put it down
			_wait = 2
		6:
			var mood: float = m.customer.mood
			m.interact()
			assert(m.walker.carrying == "body_hedgehog", "picked up again")
			m._carried_into_view()
			assert(m.customer.mood == mood, "the same body: no news")
			# Dead, a hedgehog still pricks bare hands.
			g.upgrades.assign([])
			m._held = 0.0
			_wait = 40
		7:
			assert(m.walker.carrying == "" and m.walker.dazed > 0.0, "a dead hedgehog pricks too")
			# A body thrown into a live one: it's stoned, and the body lands beside it.
			var live := _still(Vector2(400, 650))
			_h = live
			_before = m._bodies("hedgehog") # the dropped one
			var f := FlyingStone.new()
			f.kind = "body_hedgehog"
			f.thrown = true
			f.position = live.position
			m._on_stone_landed(f, "animal")
			f.free()
			_wait = 2
		8:
			var others: int = m._bodies("hedgehog") - (1 if _h.body else 0)
			assert(others == _before + 1, "the thrown body lies there, beside the one it felled")
			print("PASS stunned")
			quit()
	_step += 1
	return false
