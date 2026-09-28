# The hose (NOTES 120): green, on a reel below a tap on the house. Only its end and the
# reel can be taken hold of; the end drags it out, holding you to its length from the
# reel; it never stretches or kinks; at the reel it winds back in, and pulls out again
# off the reel. A moving mower cuts it: the far end shredded, a puddle, and it's theirs.
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


func _check_shape(h: Hose) -> void:
	for i in h.points.size() - 1:
		assert(h.points[i].distance_to(h.points[i + 1]) <= h.SEG + 1.0, "it never stretches: %.1f at link %d of %d, step %d" % [h.points[i].distance_to(h.points[i + 1]), i, h.points.size(), _step])
	for i in range(1, h.points.size() - 1):
		var turn := absf((h.points[i] - h.points[i - 1]).angle_to(h.points[i + 1] - h.points[i]))
		assert(turn <= h.MAX_BEND + 0.2, "and never kinks: %.2f at link %d" % [turn, i])


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.hud.close()
			paused = false
			var h: Hose = m._hose
			assert(h != null and h.points.size() == h.LINKS + 1 and h.stored() == 0, "a hose laid out on the lawn")
			assert(absf(h.tap.y - (m._house.position.y + m._house.WALL_H - 8.0)) < 0.1, "fed from a tap on the house wall")
			assert(h.reel.get_parent() == m.get_node("Scenery"), "its reel stands in the garden")
			m.mower.global_position = Vector2(640, 600)
			m.hop_off()
			m.walker.global_position = h.points[8]
			_wait = 2
		1:
			assert(m._hose_grip() == "", "the middle of the hose isn't a grip")
			var h: Hose = m._hose
			m.walker.global_position = h.end()
			_wait = 1
		2:
			m.interact()
			assert(m.walker.carrying == "hose" and m._hose.grabbed, "picked up by the end")
			m.walker.global_position = m._hose.points[0] + Vector2(0, 900) # try to walk off with it
			_wait = 40
		3:
			var h: Hose = m._hose
			assert(m.walker.global_position.distance_to(h.points[0]) <= h.reach() + 0.5, "held to its length from the reel")
			_check_shape(h)
			m.interact()
			assert(m.walker.carrying == "" and not h.grabbed, "let go")
			m.walker.global_position = h.points[0] + Vector2(0, 10)
			_wait = 1
		4:
			assert(m._hose_grip() == "wind", "at the reel: wind it in")
			m.interact()
			_wait = int(Hose.LINKS * Hose.WIND * 60.0) + 20
		5:
			var h: Hose = m._hose
			assert(h.points.size() == 1 and h.stored() == h.LINKS and not h.winding, "wound in")
			assert(m._hose_grip() == "pull", "and it pulls out again")
			m.interact()
			assert(m.walker.carrying == "hose", "off the reel")
			m.walker.global_position = h.points[0] + Vector2(0, 120)
			_wait = 30
		6:
			var h: Hose = m._hose
			assert(h.points.size() > 5, "paid out as you walk: %d" % h.points.size())
			_check_shape(h)
			m.interact()
			m.walker.global_position = m.mower.global_position + Vector2(0, 30)
			m.hop_on()
			_len = h.points.size()
			m.mower.global_position = h.points[_len - 2]
			m.mower.velocity = Vector2(100, 0)
			_wait = 1
		7:
			var h: Hose = m._hose
			assert(h.cut and h.points.size() < _len and m.tally.get("hoses_mowed", 0) == 1, "mowed: cut, the end shredded")
			assert(h.length < Hose.LINKS, "and it's shorter now")
			assert(m._spills.size() == 1, "a puddle")
			print("PASS hose")
			quit()
	_step += 1
	return false
