# Every bit of lawn can be cut (S15-FENCE): on each plot shape and venue, with each mower,
# sweeping the mower's centre everywhere it may stand (Lawn.keep_in at its edge margin,
# as mower.gd clamps it) cuts every lawn cell, the corners where your fence meets next
# door's included. Solid things (trees, the house, the car) aren't modelled: only the
# boundary and next door's corner.
extends SceneTree

var g: Node
var m: Node
var _runs: Array = [] ## [job, mower key]
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_reach.cfg"
	for want: Array in [[20.0, "terrace"], [50.0, "forward"], [85.0, "L"], [50.0, "rect"], [85.0, "mansion"], [10.0, "graveyard"]]:
		g.reputation = want[0]
		for s in range(1, 600):
			var j: Dictionary = g.make_job(s)
			if j.get("venue", j.get("shape", "rect")) == want[1]:
				for key: String in g.MOWERS:
					_runs.append([j, key])
				break
	assert(_runs.size() == 6 * g.MOWERS.size(), "found a job of every shape")


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	if m:
		var lawn: Lawn = m.lawn
		var r: float = m.mower.cut_radius
		var margin: float = m.mower.edge_margin
		for y in range(-16, lawn.size_px.y + 17, 6):
			for x in range(-16, lawn.size_px.x + 17, 6):
				var at := lawn.keep_in(Vector2(x, y), margin)
				lawn.cut_segment(at, at, r)
		var kind: String = m.job.get("venue", m.job.get("shape", "rect"))
		assert(lawn.cut_fraction() == 1.0, "%s with the %s mower: %.4f cut, first left at %s" % [kind, m.mower.sprite_kind, lawn.cut_fraction(), _first_uncut(lawn)])
		m.free()
		m = null
	if _runs.is_empty():
		g.current_job = {}
		print("PASS reach")
		quit()
		return false
	var run: Array = _runs.pop_front()
	g.current_job = run[0]
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	m.mower.apply_spec(g.mower_spec(run[1]))
	_wait = 2
	return false


func _first_uncut(lawn: Lawn) -> Vector2:
	for y in range(2, lawn.size_px.y, 4):
		for x in range(2, lawn.size_px.x, 4):
			if lawn._cell(Vector2(x, y)) == Lawn.UNCUT:
				return Vector2(x, y)
	return Vector2(-1, -1)
