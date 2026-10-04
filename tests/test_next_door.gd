# Next door meets the garden (2026-10-04, after the dev's screenshots of a bare strip and a
# hole in the back fence line, the third round of fence fixes): over many gardens of every
# shape, next door's ground starts exactly where the garden's side run's art ends, both
# sides (a fence's art is 8 wide in a 24 border: their plot used to start the full 24 out);
# and where next door's back fence starts at that corner, it runs on to their house's back
# wall or the plot's end (it used to stop at their garage, or before a house set forward).
extends SceneTree

var g: Node
var m: Node
var _jobs: Array = []
var _i := 0
var _wait := 0
var _checked := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	for rep in [5.0, 30.0, 55.0, 80.0]:
		g.reputation = rep
		for s in range(1, 11):
			_jobs.append(g.make_job(s * 37 + int(rep)))
	_open()


func _open() -> void:
	g.current_job = _jobs[_i]
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	_wait = 2


## The garden's side run on one side: its art's outer edge (x), or NAN where there's none (a ha-ha).
func _outer(left: bool) -> float:
	var w: float = m.lawn.size_px.x
	for c: Node in m.get_node("Borders").get_children():
		var t := c as TextureRect
		if t == null or t.texture == null or not t.texture.resource_path.ends_with("_v.png"):
			continue
		var used := t.texture.get_image().get_used_rect()
		var x0 := t.position.x + used.position.x
		var x1 := t.position.x + used.end.x
		if left and x1 <= 0.5:
			return x0
		if not left and x0 >= w - 0.5:
			return x1
	return NAN


## How far next door's back fence runs unbroken from the corner at x, outward (dir -1 or 1).
func _run_from(x: float, dir: int) -> float:
	var spans: Array[Vector2] = []
	for c: Node in m.get_node("Beyond").get_children():
		var t := c as TextureRect
		if t and t.texture and t.texture.resource_path.ends_with("fence_h.png") and is_equal_approx(t.position.y, -32.0):
			spans.append(Vector2(t.position.x, t.position.x + t.size.x))
	var at := x
	var grew := true
	while grew:
		grew = false
		for sp: Vector2 in spans:
			if dir > 0 and sp.x <= at + 0.5 and sp.y > at + 0.5:
				at = sp.y
				grew = true
			elif dir < 0 and sp.y >= at - 0.5 and sp.x < at - 0.5:
				at = sp.x
				grew = true
	return absf(at - x)


## Whether a house stands against the back line where a fence run stops (its wall is the boundary there).
func _house_at(x: float, left: bool) -> bool:
	for c: Node in m.get_node("Beyond").get_children():
		if c.has_method("rect"):
			var r: Rect2 = c.rect()
			if r.position.y <= 1.0 and absf((r.end.x if left else r.position.x) - x) <= 1.0:
				return true
	return false


func _process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	var job: Dictionary = _jobs[_i]
	var near: Array = m.get_node("Beyond").near
	var what := "seed %d (%s)" % [job.seed, job.get("venue", job.get("shape", "rect"))]
	for left: bool in [true, false]:
		var art := _outer(left)
		if is_nan(art):
			continue
		var edge: float = near[0] if left else near[1]
		assert(absf(edge - art) <= 1.0, "%s: next door's ground starts at %.1f, the %s run's art ends at %.1f" % [what, edge, "left" if left else "right", art])
		var run := _run_from(edge, -1 if left else 1)
		var stop := edge + (-run if left else run)
		assert(run < 1.0 or run >= 700.0 or _house_at(stop, left), "%s: next door's back fence on the %s stops %.0f out from the corner, at nothing" % [what, "left" if left else "right", run])
		_checked += 1
	m.free()
	_i += 1
	if _i >= _jobs.size():
		assert(_checked >= 60, "enough sides checked: %d" % _checked)
		print("PASS next door: %d gardens, %d sides" % [_jobs.size(), _checked])
		quit()
	else:
		_open()
	return false
