# The hose: fixed to a tap on the house, you pick it up by the nearest bit and drag it;
# it holds you to its length from the tap (less, the nearer the tap you grabbed it). A
# moving mower cuts it: the far end is shredded, a puddle, and it's theirs.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0
var _len := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	for s in range(1, 400):
		var j: Dictionary = g.make_job(s)
		if "hose" in j.get("props", []) and not j.has("venue") and not j.has("shape"): # a plain plot: the tap on the front corner
			g.current_job = j
			break
	assert("hose" in g.current_job.props, "found a garden with a hose")
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
			m.hud.close()
			paused = false
			var h: Hose = m._hose
			assert(h != null and h.points.size() == 19, "a hose on the lawn")
			assert(absf(h.points[0].y - (m._house.position.y + m._house.WALL_H - 8.0)) < 0.1, "on a tap at the house wall")
			m.hop_off()
			m.walker.global_position = h.points[5]
			_wait = 2
		1:
			m.interact()
			assert(m.walker.carrying == "hose" and m._hose.grabbed == 5, "picked up by the nearest bit")
			m.walker.global_position = m._hose.points[0] + Vector2(0, 400) # try to walk off with it
			_wait = 30
		2:
			var h: Hose = m._hose
			assert(m.walker.global_position.distance_to(h.points[0]) <= 5 * h.SEG + 0.5, "held to its length from the tap")
			for i in h.points.size() - 1:
				assert(h.points[i].distance_to(h.points[i + 1]) <= h.SEG + 1.0, "it never stretches")
			m.interact()
			assert(m.walker.carrying == "" and h.grabbed == -1, "let go")
			m.hop_on()
			_len = h.points.size()
			m.mower.global_position = h.points[_len - 3]
			m.mower.velocity = Vector2(100, 0)
			_wait = 1
		3:
			var h: Hose = m._hose
			assert(h.cut and h.points.size() < _len and m.tally.get("hoses_mowed", 0) == 1, "mowed: cut, the end shredded")
			assert(m._spills.size() == 1, "a puddle")
			print("PASS hose")
			quit()
	_step += 1
	return false
