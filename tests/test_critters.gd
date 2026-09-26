# Critters in hand: a hedgehog stuns you bare-handed (gloves fix it), a squirrel bites
# free, the dog wriggles free or gets carried home, and a thrown animal lands alive.
# Throwing one into something tiers the crime up.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0
var _heat := 0.0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _critters(kind: String) -> Array:
	return m.get_node("Animals").get_children().filter(func(a: Node) -> bool: return a is Animal and a.kind == kind and not a.is_queued_for_deletion())


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			g.heat = 0.0
			g.upgrades.assign([])
			m.hop_off()
			m.walker.global_position = Vector2(500, 400)
			var h: Animal = m.spawn_animal("hedgehog", Vector2(505, 400), Vector2(505, 400))
			h.speed = 0.0
			_wait = 2
		1:
			m.interact()
			assert(m.walker.carrying == "" and m.walker.dazed > 0.0 and m.tally.get("prickled", 0) == 1, "a hedgehog bare-handed: ow, dazed")
			g.upgrades.append("gloves")
			_wait = 100
		2:
			assert(m.walker.dazed <= 0.0, "the stars clear")
			m.interact()
			assert(m.walker.carrying == "hedgehog", "with gloves, you pick it up")
			_wait = 2
		3:
			assert(_critters("hedgehog").is_empty(), "it's in your hands, not on the lawn")
			m._on_thrown(Vector2.UP, 0.0) # a short lob onto the grass
			_wait = 30
		4:
			assert(_critters("hedgehog").size() == 1 and g.heat == 0.0, "it lands alive, and a hedgehog on the grass is no crime")
			# Into a window: one tier above the worse of window (1) and hedgehog (0), and heat for the method.
			var house: Node2D = m.get_node("Scenery/House")
			var f := FlyingStone.new()
			f.kind = "hedgehog"
			f.thrown = true
			f.velocity = Vector2.UP * 400.0
			f.position = house.position + Vector2(295, house.WALL_H - 26.0)
			m._on_stone_landed(f, "window")
			f.free()
			assert(g.heat == 3.0 and m.worst_crime == 2, "a hedgehog through a window is tier 2, +1 heat for the method")
			# A squirrel bites free after a few seconds.
			m.walker.carrying = "squirrel"
			m._held = 0.0
			_wait = 200
		5:
			assert(m.walker.carrying == "" and m.tally.get("bitten", 0) == 1, "the squirrel bites and escapes")
			assert(_critters("squirrel").size() == 1, "and bolts")
			# The dog: pick it up and carry it home.
			m.job.dog_name = "Rolo" # the default job has no dog
			m._release_dog()
			m.dog.position = m.walker.global_position + Vector2(10, 0)
			_wait = 1
		6:
			m.interact()
			assert(m.walker.carrying == "dog" and m.dog.held, "picked up the dog")
			m.walker.global_position = m.dog.home_point + Vector2(0, 30)
			_wait = 2
		7:
			assert(m.walker.carrying == "" and m.tally.get("dog_returned", 0) == 1, "carried home to its owner")
			# Thrown across the lawn, a dog is tier 1.
			m._release_dog()
			m.dog.hold()
			_heat = g.heat
			var f := FlyingStone.new()
			f.kind = "dog"
			f.thrown = true
			f.position = Vector2(640, 600)
			m._on_stone_landed(f, "")
			f.free()
			assert(g.heat == _heat + 1.0 and not m.dog.held and m.dog.visible, "a thrown dog lands and runs off: tier 1")
			print("PASS critters")
			quit()
	_step += 1
	return false
