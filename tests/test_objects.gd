# Objects by size: small things are carried, thrown and mowed (each with its own
# consequence; litter minded only if seen, croquet hoops on the manor, a sapling snaps if rammed), the dog fetches a thrown ball, and decorative rocks are solid.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _flying() -> Array:
	return m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			var mower: Node2D = m.mower
			# A gnome: shatters, hurts the mower, and it was theirs.
			var mood: float = m.customer.mood
			var cond: float = mower.condition
			var gnome: Stone = m.add_stone(Vector2(640, 600), "gnome")
			m._on_stone_mowed(gnome, mower)
			assert(gnome.is_queued_for_deletion() and mower.condition < cond, "a mowed gnome shatters and dents the mower")
			assert(m.customer.mood < mood and m.tally.get("gnomes_mowed", 0) == 1, "and they saw their gnome go")
			# The petrol can: a spill browns the lawn.
			m._on_stone_mowed(m.add_stone(Vector2(700, 600), "jerrycan"), mower)
			assert(m._spills.size() == 1, "a mowed petrol can leaves a brown patch")
			# A cone is always knocked flying, and it's not theirs.
			mood = m.customer.mood
			m._on_stone_mowed(m.add_stone(Vector2(760, 600), "cone"), mower)
			_wait = 1
		1:
			var cones: Array = _flying().filter(func(f: FlyingStone) -> bool: return f.kind == "cone")
			assert(cones.size() == 1, "a mowed cone always goes flying, as a cone")
			# Carry a flamingo and throw it: it lands as a flamingo.
			m.hop_off()
			m.walker.global_position = Vector2(500, 400)
			m.add_stone(Vector2(505, 400), "flamingo")
			_wait = 2
		2:
			m.interact()
			assert(m.walker.carrying == "flamingo", "anything small can be picked up")
			m._on_thrown(Vector2.RIGHT, 0.0)
			_wait = 30
		3:
			var landed: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is Stone and s.kind == "flamingo")
			assert(landed.size() == 1 and m.walker.carrying == "", "and thrown, where it lands as itself")
			# The dog fetches a thrown ball, and brings it back to you.
			m.job.dog_name = "Rolo" # the default job has no dog
			m._release_dog()
			m.dog.position = Vector2(560, 450)
			m._land(Vector2(600, 450), "ball")
			_wait = 2
		4:
			assert(m.dog.fetching != null, "the dog goes after a ball that lands")
			_wait = 90
		5:
			assert(m.tally.get("fetches", 0) == 1, "and brings it back")
			var balls: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is Stone and s.kind == "ball")
			assert(balls.size() == 1 and balls[0].position.distance_to(m.walker.global_position) < 40.0, "dropped at your feet")
			# Mow the ball in front of it and it sulks.
			m._on_stone_mowed(balls[0], m.mower)
			assert(m.dog._grief > 0.0, "a ball mowed in front of the dog: it grieves")
			# A ball past the house (NOTES 211): it can't get there without running through it,
			# so it stays put; and you past the house, it brings a ball only as far as its side.
			var far := Vector2(m._house.rect().position.x - 40.0, m._house.rect().get_center().y) # beside the house, off its side
			assert(m._on_plot(far) and not m.dog.lawn_rect.has_point(far), "the far side's on the plot, off the dog's side")
			m.dog.fetch(m.add_stone(far, "ball"), m.walker)
			assert(m.dog.fetching == null, "a ball past the house: it doesn't go")
			m.dog._grief = 0.0
			m.dog.has_ball = true
			m.dog.bring_to = m.walker
			m.walker.global_position = far
			for i in 200:
				m.dog._physics_process(1.0 / 60.0)
				assert(m.dog.lawn_rect.has_point(m.dog.position), "it never leaves its side of the house")
			assert(not m.dog.has_ball, "it drops the ball at the nearest it can get to you")
			m.walker.global_position = Vector2(500, 400)
			# Litter: shredded, minded only if they see it done; never found afterwards.
			var where: String = m.customer.where
			m.customer.where = "inside"
			var mood: float = m.customer.mood
			m._on_stone_mowed(m.add_stone(Vector2(640, 560), "litter"), m.mower)
			assert(m.customer.mood == mood and m.customer._owned.is_empty(), "litter shredded unseen: nothing, now or later")
			m.customer.where = where
			m._on_stone_mowed(m.add_stone(Vector2(660, 560), "litter"), m.mower)
			assert(m.customer.mood < mood and m.tally.get("litters_mowed", 0) == 2, "shredded where they see: they mind the mess")
			# A croquet hoop: sent flying sometimes, always a knock to the mower.
			var cond: float = m.mower.condition
			m._on_stone_mowed(m.add_stone(Vector2(680, 560), "hoop"), m.mower)
			assert(m.mower.condition < cond and m.tally.get("hoops_mowed", 0) == 1, "a mowed hoop dents the mower")
			# Where they turn up: the manor's croquet lawn, litter now and then anywhere.
			g.reputation = 90.0
			var manor := {}
			var litter := 0
			for seed_value in range(1, 400):
				var j: Dictionary = g.make_job(seed_value)
				litter += int("litter" in j.props)
				if manor.is_empty() and j.get("venue", "") == "mansion":
					manor = j
			assert(manor.props.count("hoop") >= 4 and manor.props.count("hoop") <= 6, "a manor's croquet hoops: %s" % [manor.props])
			assert(litter > 60 and litter < 220, "litter in about a third of gardens: %d of 400" % litter)
			g.reputation = 50.0
			# A garden with rocks: solid, and stones bounce off.
			var job: Dictionary = {}
			for seed_value in range(1, 200):
				job = g.make_job(seed_value)
				if job.rocks > 0 and job.props.size() > 1:
					break
			g.current_job = job
			var m2: Node = load("res://main.tscn").instantiate()
			root.add_child(m2)
			var rocks: Array = m2.get_node("Scenery").get_children().filter(func(n: Node) -> bool: return n.get_script() == preload("res://rock.gd"))
			assert(rocks.size() >= 1, "a job's rocks are in the garden")
			assert(m2._stone_hit_test(rocks[0].position) == "rock", "a stone hits a rock")
			var props: Array = m2.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is Stone and s.kind != "stone")
			assert(props.size() >= 1, "and its small things lie about: %s" % str(job.props))
			# A sapling: a nudge leaves it, ramming it snaps it, and it was theirs.
			for seed_value in range(1, 400):
				job = g.make_job(seed_value)
				if "sapling" in job.props:
					break
			g.current_job = job
			var m3: Node = load("res://main.tscn").instantiate()
			root.add_child(m3)
			var sap: Array = m3.get_node("Scenery").get_children().filter(func(n: Node) -> bool: return "art" in n and n.art == "sapling")
			assert(sap.size() == 1, "a sapling in the garden: %s" % [job.props])
			var mood3: float = m3.customer.mood
			m3._on_mower_bumped(sap[0], 80.0)
			assert(sap[0].frame == 0 and m3.customer.mood == mood3, "a nudge: still standing")
			m3._on_mower_bumped(sap[0], 200.0)
			assert(sap[0].frame == 1 and m3.tally.get("saplings", 0) == 1, "rammed: snapped")
			assert(m3.customer.mood < mood3 or not m3.customer._owned.is_empty(), "their sapling: minded now, or found later")
			m3._on_mower_bumped(sap[0], 200.0)
			assert(m3.tally.saplings == 1, "it snaps once")
			# Gardens keep the layout they had before litter, hoops and saplings (the verifier's
			# find: rocks and the dog's ball moved): those are placed last, on their own draws.
			for seed_value in [2, 4, 9, 10]:
				var full: Dictionary = g.make_job(seed_value)
				var old: Dictionary = full.duplicate(true)
				old.props = old.props.filter(func(k: String) -> bool: return k not in m3.LATER_PROPS)
				assert(old.props.size() < full.props.size(), "seed %d has a new prop" % seed_value)
				assert(_layout(full) == _layout(old), "seed %d: its rocks and small things where they were" % seed_value)
			g.current_job = {}
			print("PASS objects")
			quit()
	_step += 1
	return false


## Where a job's rocks and its older small things lie (not the new ones).
func _layout(job: Dictionary) -> Array:
	g.current_job = job
	var mm: Node = load("res://main.tscn").instantiate()
	root.add_child(mm)
	var out: Array = []
	for n: Node in mm.get_node("Scenery").get_children() + mm.get_node("Stones").get_children():
		if (n.get_script() == preload("res://rock.gd") and n.art == "rock") or (n is Stone and n.kind not in mm.LATER_PROPS):
			out.append([str(n.get("kind")), (n as Node2D).position])
	mm.free()
	return out
