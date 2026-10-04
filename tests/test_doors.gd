# A back-patio house (NOTES 212): with them indoors, either door can be knocked. They
# answer the one you knocked at; from the front door they go back in after, and come out
# the back in their own time.
extends SceneTree

var g: Node
var m: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	for seed_value in range(1, 400):
		var job: Dictionary = g.make_job(seed_value)
		if job.get("shape", "") == "forward":
			g.current_job = job
			break
	assert(not g.current_job.is_empty(), "a back-patio garden")
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			assert(m._house.back_patio, "the patio's out the back")
			m.hop_off()
			m.customer.where = "inside"
			m.walker.global_position = m._house.front_step() + Vector2(0, 20)
			_wait = 2
		1:
			assert(m.near_customer() and m._hint().contains("knock on the door"), "they're in: the front door can be knocked too")
			m.interact()
			_wait = 75
		2:
			assert(m.hud.is_open(), "they answer, and you talk")
			assert(m._house.front_open and not m._house.door_open, "the front door stands open, not the back")
			assert(m.get_node("Client").position == m._house.front_step(), "standing in the front doorway")
			m._on_choice("resume")
			_wait = 2
		3:
			assert(not m._house.front_open and m.customer.where == "inside", "chat over, back in and the door shut")
			assert(not m.get_node("Client").visible, "out of sight indoors")
			# The back door still works as it did.
			m.walker.global_position = m._house.door_point() + Vector2(0, -20)
			_wait = 2
		4:
			assert(m.near_customer(), "the back door can be knocked")
			m.interact()
			_wait = 75
		5:
			assert(m.hud.is_open() and m._house.door_open and not m._house.front_open, "answered at the back")
			assert(m.get_node("Client").position == m._house.door_point(), "standing at the back door")
			m._on_choice("resume")
			# The dog put down past the house (thrown, or wriggling free at the front step):
			# back round the house to its side, never through it (the verifier's find, NOTES 211).
			m.job.dog_name = "Rolo"
			m._release_dog()
			m.dog.let_go(m._house.front_step() + Vector2(0, 20))
			for i in 600:
				var was: Vector2 = m.dog.position
				m.dog._physics_process(1.0 / 60.0)
				assert(not m._house.rect().has_point(m.dog.position), "never through the house (at %s)" % m.dog.position)
				assert(was.distance_to(m.dog.position) < 5.0, "it runs, never jumps (from %s to %s)" % [was, m.dog.position])
			assert(m.dog.lawn_rect.has_point(m.dog.position), "back on its side")
			g.current_job = {}
			print("PASS doors")
			quit()
	_step += 1
	return false
