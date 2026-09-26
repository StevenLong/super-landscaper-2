# Objects by size: small things are carried, thrown and mowed (each with its own
# consequence), the dog fetches a thrown ball, and decorative rocks are solid.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0
var _ball: Stone


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
			g.current_job = {}
			print("PASS objects")
			quit()
	_step += 1
	return false
