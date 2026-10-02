# Robot mowers that earn their keep: they plan only grass still uncut, skip what's been cut
# since (by you, another robot), stop when there's none left, and never jam: two nose to
# nose get past each other, and one stuck short of a waypoint gives it up. Rammed by a mower,
# a robot takes a knock by the mower's weight. (test_robot has the basics.)
extends SceneTree

var m: Node
var g: Node
var _frame := 0
var _step := 0
var _a: Robot
var _b: Robot
var _at: Array[Vector2] = []
var _wall: StaticBody2D


func _initialize() -> void:
	seed(1) # the robots' patience jitter, the same every run
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.calendar[g.day] = g.make_job(3)
	g.start_job()
	change_scene_to_file("res://main.tscn")


## A spot with open lawn for 160 px to its right (as test_robot).
func _clear_strip() -> Vector2:
	for y in range(80, m.lawn.size_px.y - 80, 20):
		for x in range(80, m.lawn.size_px.x - 240, 20):
			var ok := true
			for d in range(-30, 161, 4):
				for dy: int in [-14, 0, 14]:
					ok = ok and m.lawn._cell(Vector2(x + d, y + dy)) == Lawn.UNCUT
			if ok:
				return Vector2(x, y) + m.lawn.global_position
	assert(false, "no open strip of lawn")
	return Vector2.ZERO


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	match _step:
		0:
			m = current_scene
			m.hedgehog_every = 9999.0
			m.squirrel_every = 9999.0
			m._on_choice("start")
			m.mower.global_position = Vector2(-5000, -5000) # out of every robot's way
			# Nose to nose on one lane: neither may wait on the other for ever.
			var p := _clear_strip()
			_a = m.set_robot(p, Vector2.RIGHT)
			_b = m.set_robot(p + Vector2(90, 0), Vector2.LEFT)
			_at = [_a.global_position, _b.global_position]
		40: # about 6.5 s on: past the 2.5 s most either waits, a give-up each, and round
			assert(_a.global_position.distance_to(_at[0]) > 60.0 and _b.global_position.distance_to(_at[1]) > 60.0,
				"nose to nose, they got past each other: %s %s" % [_a.global_position - _at[0], _b.global_position - _at[1]])
			# Its plan is only grass still uncut: cut a band across the lawn, plan again.
			var lp: Vector2 = m.lawn.global_position
			var y := (_a.global_position - lp).y + 60.0
			for dy in range(-10, 11, 4):
				m.lawn.cut_segment(Vector2(0, y + dy), Vector2(m.lawn.size_px.x, y + dy), 12.0)
			_a.plan()
			for c: Vector2i in _a._targets:
				assert(_a._wants(c), "planned only uncut cells: %s" % c)
			assert(not _a._targets.has(_a._cell(Vector2(m.lawn.size_px.x / 2.0, y))), "not the band just cut")
			for i in _a.route.size() - 1: # only ever by the grid: no straight line over a bed
				var d := (_a._cell(_a.route[i + 1]) - _a._cell(_a.route[i])).abs()
				assert(maxi(d.x, d.y) <= 1, "one cell at a time: %s to %s" % [_a.route[i], _a.route[i + 1]])
			# Cut since it planned (by you, say): its next few stops go, and it heads straight
			# for the first one still uncut, by a fresh short way round.
			m.lawn.cut_segment(_a.route[2], _a.route[2], 50.0)
			var wanted := _a.route.filter(func(p: Vector2) -> bool: return _a._targets.has(_a._cell(p)) and _a._wants(_a._cell(p)))
			var here := _a._cell(_a.global_position - lp)
			assert(not _a._wants(_a._cell(_a.route[0])), "the setup: its next stop is cut")
			_a._reroute()
			var gap: Vector2i = (_a._cell(wanted[0]) - here).abs()
			var i := _a.route.find(wanted[0])
			assert(i >= 0 and i <= maxi(gap.x, gap.y), "skipped what was cut since it planned: stop %d, %s away" % [i, gap])
		43:
			# Rammed by the ride-on: a knock to it by the mower's weight.
			var before := _b.condition
			m.mower.toughness = 2.0
			m._on_mower_bumped(_b, 200.0)
			assert(is_equal_approx(_b.condition, before - 200.0 / 25.0 * 2.0), "rammed: %f from %f" % [_b.condition, before])
			# Stuck short of a waypoint (pressed against something solid): it gives it up.
			_b.route.push_front(_b.global_position - m.lawn.global_position + Vector2(4, 0))
			_b._waited = 0.0
			_wall = StaticBody2D.new()
			var cs := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(4, 40)
			cs.shape = box
			_wall.add_child(cs)
			_wall.global_position = _b.global_position + Vector2(13.5, 0) # flush with its nose
			m.add_child(_wall)
			_at = [_b.global_position, _b.route[0]]
		63: # about 3.5 s: past its patience
			assert(_b.route.is_empty() or _b.route[0] != _at[1], "the waypoint it couldn't reach is given up")
			_wall.queue_free()
			# Nothing left anywhere: it stops, done.
			for y in range(0, m.lawn.size_px.y + 8, 8):
				m.lawn.cut_segment(Vector2(0, y), Vector2(m.lawn.size_px.x, y), 12.0)
		85:
			for r: Robot in [_a, _b]:
				assert(r._done and r.velocity == Vector2.ZERO, "a cut lawn: done, light green")
			print("PASS robot_jam")
			quit()
	_step += 1
	return false
