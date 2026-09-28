# Balance probe (not part of run_all): a bot mows each plot shape and venue (the default
# lawn, a terrace, a semi, an L, the manor, the churchyard) with each mower, in lanes,
# refuelling/resting as needed, and prints how long it took to reach each coverage mark
# next to that job's patience. Compare plots and mowers against each other more than
# against patience: the bot routes round obstacles cell by cell and is slower than the old
# straight-line bot on the default lawn (petrol to 85%: 262 s here, 179 s then). It pulls
# the cord first time, drives the ride-on in top gear (second to turn), sprints the push
# mower while fresh, and ignores the police.
#   "$GODOT" --headless --fixed-fps 60 --path . -s tests/sim_balance.gd
# Only some plots or mowers: SIM_PLOTS=terrace,manor SIM_MOWERS=push (comma lists).
extends SceneTree

const MARKS := [0.5, 0.7, 0.85, 0.95]
const LIMIT := 60 * 60 * 12 # frames (12 simulated minutes)
## label: [reputation to look at, job key, the value it must have] ("" key: the default lawn)
const PLOTS := {
	"default": [50.0, "", ""], "terrace": [20.0, "shape", "terrace"], "semi": [50.0, "shape", "forward"],
	"L": [85.0, "shape", "L"], "manor": [90.0, "venue", "mansion"], "churchyard": [10.0, "venue", "graveyard"],
}

var runs: Array = [] ## [plot label, job, mower kind]
var m: Node
var mower: CharacterBody2D
var lawn: Lawn
var waypoints: Array[Vector2] = []
var wp := 0
var frame := 0
var hit := {}
var resting := false
var refuelling := false
var stuck := 0
var backing := 0
var last_pos := Vector2.ZERO
var started := false
var _wp_frames := 0 ## how long it's been heading for this waypoint
var grid: AStarGrid2D ## the plot in 16 px cells, solid where the mower can't be: routes round the house
var route: Array[Vector2] = [] ## to the truck, while refuelling
const CELL := 16.0


func _initialize() -> void:
	var g: Node = root.get_node("Game")
	g.save_path = "user://sim_best.cfg"
	var want_plots := OS.get_environment("SIM_PLOTS").split(",", false)
	var want_mowers := OS.get_environment("SIM_MOWERS").split(",", false)
	for label: String in PLOTS:
		if not want_plots.is_empty() and label not in want_plots:
			continue
		var p: Array = PLOTS[label]
		var job: Dictionary = g.default_job()
		if p[1] != "":
			g.reputation = p[0]
			job = {}
			for s in range(1, 400):
				var j: Dictionary = g.make_job(s)
				if j.get(p[1], "") == p[2] and (p[1] == "venue" or not j.has("venue")):
					job = j
					break
			if job.is_empty():
				print("%-10s no job found" % label)
				continue
		for kind: String in ["push", "petrol", "rideon"]:
			if want_mowers.is_empty() or kind in want_mowers:
				runs.append([label, job.merged({"persona": "busy"}, true), kind]) # a customer who won't fire the bot


func _next() -> void:
	if m:
		m.queue_free()
		for a in ["move_forward", "move_back", "turn_left", "turn_right", "sprint"]:
			Input.action_release(a)
	if runs.is_empty():
		quit()
		return
	var run: Array = runs.pop_front()
	var game: Node = root.get_node("Game")
	game.current_job = run[1]
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	m.hud.close()
	paused = false
	mower = m.get_node("Mower")
	mower.apply_spec(game.MOWERS[run[2]].duplicate())
	mower.engine_off = false # a good pull first time
	lawn = m.get_node("Lawn")
	waypoints.clear()
	_grid()
	_lanes(mower.cut_radius * 1.7)
	# Between one lane's run and the next, go round what's in the way, not through it.
	var joined: Array[Vector2] = _path(mower.global_position, waypoints[0]) # from the truck, round the house
	for i in waypoints.size():
		if i > 0 and i % 2 == 0:
			joined.append_array(_path(waypoints[i - 1], waypoints[i]))
		joined.append(waypoints[i])
	waypoints = joined
	route.clear()
	wp = 0
	frame = 0
	hit = {"plot": run[0], "kind": run[2], "patience": run[1].get("patience", 0.0)}
	resting = false
	refuelling = false


## Room for this mower here: on the plot, and clear of anything solid by half its size.
func _free(p: Vector2) -> bool:
	if lawn.keep_in(p, 0.0) != p:
		return false
	var r: float = maxf(mower.body.x, mower.body.y) * 0.5 + 4.0
	for o: Vector2 in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r),
			Vector2(r, r) * 0.7, Vector2(-r, r) * 0.7, Vector2(r, -r) * 0.7, Vector2(-r, -r) * 0.7]:
		if m._blocked(p + o):
			return false
	return true


## The open cell nearest p (a lane's end can sit in a cell that brushes the house).
func _cell(p: Vector2) -> Vector2i:
	var c := Vector2i((p / CELL).floor()).clamp(Vector2i.ZERO, grid.region.size - Vector2i.ONE)
	for r in 4:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if grid.is_in_boundsv(q) and not grid.is_point_solid(q):
					return q
	return c


func _grid() -> void:
	grid = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, ceili(lawn.size_px.x / CELL), ceili(lawn.size_px.y / CELL))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			if not _free(Vector2(x, y) * CELL + grid.offset):
				grid.set_point_solid(Vector2i(x, y))


## Waypoints from a to b round anything solid (none if the way is clear or there's no way).
func _path(a: Vector2, b: Vector2) -> Array[Vector2]:
	var ca := _cell(a)
	var cb := _cell(b)
	var out: Array[Vector2] = []
	var pts := grid.get_point_path(ca, cb, true)
	for i in range(1, pts.size() - 1):
		out.append(pts[i])
	return out


## Boustrophedon lanes across the whole plot, each split round whatever's in the way
## (the house, trees, ponds, next door's corner): only the free runs become waypoints.
func _lanes(step: float) -> void:
	var margin: float = mower.edge_margin
	var free := func(p: Vector2) -> bool: return lawn.keep_in(p, margin) == p and _free(p)
	var right := true
	var y := margin
	while y < lawn.size_px.y - margin:
		var runs_here: Array = [] # [x0, x1]
		var x := margin
		var start := -1.0
		while x <= lawn.size_px.x - margin:
			if free.call(Vector2(x, y)):
				if start < 0.0:
					start = x
			elif start >= 0.0:
				runs_here.append([start, x - 8.0])
				start = -1.0
			x += 8.0
		if start >= 0.0:
			runs_here.append([start, lawn.size_px.x - margin])
		if not right:
			runs_here.reverse()
		for r: Array in runs_here:
			if r[1] - r[0] < 16.0:
				continue
			waypoints.append(Vector2(r[0] if right else r[1], y))
			waypoints.append(Vector2(r[1] if right else r[0], y))
		right = not right
		y += step


func _physics_process(_delta: float) -> bool:
	if not started:
		started = true
		_next()
		return false
	if mower == null or not is_instance_valid(mower):
		return false
	frame += 1
	if m.hud.is_open() and not m.over: # the dog's out, the truck's menu: carry on mowing
		m.hud.close()
		paused = false
	m.customer.mood = 60.0 # the probe measures mowing time, not customer management
	m.police_left = -1.0 # nor crime: it bumps the car now and then
	mower.engine_off = false # stalled on a knock: it pulls the cord again, first time
	var cov := lawn.cut_fraction()
	for mark: float in MARKS:
		if cov >= mark and not hit.has(mark):
			hit[mark] = frame / 60.0
	if hit.has(MARKS[-1]) or frame > LIMIT or wp >= waypoints.size():
		var parts := []
		for mark: float in MARKS:
			parts.append("%d%%: %s" % [roundi(mark * 100.0), ("%ds" % roundi(hit[mark])) if hit.has(mark) else "never"])
		print("%-10s %-7s patience %3ds   %s  (cut %d%% by %ds)" % [hit.plot, hit.kind, roundi(hit.patience), "  ".join(parts),
			roundi(cov * 100.0), roundi(frame / 60.0)])
		_next()
		return false

	var frac: float = mower.fuel / mower.max_fuel
	var target: Vector2 = waypoints[wp]
	if frac > 0.5: # push flat out while fresh
		Input.action_press("sprint")
	else:
		Input.action_release("sprint")
	if mower.power == "stamina":
		if frac < 0.05:
			resting = true
		if resting:
			_drive(Vector2.INF)
			resting = frac < 0.9
			return false
	else:
		if frac < 0.12:
			refuelling = true
		if refuelling:
			if m.get_node("Truck/RefuelZone").overlaps_body(mower):
				_drive(Vector2.INF)
				refuelling = frac < 0.98
				route.clear()
				if not refuelling: # back to where it left off, round the house again
					var back := _path(mower.global_position, waypoints[wp])
					for i in back.size():
						waypoints.insert(wp + i, back[i])
				return false
			if route.is_empty(): # round the house to the drive, then out to the truck
				route = _path(mower.global_position, m.lawn.keep_in(m.truck_spot(), 20.0))
				route.append(m.truck_spot())
			target = route[0]
			if mower.global_position.distance_to(target) < 20.0 and route.size() > 1:
				route.pop_front()
	if backing > 0:
		backing -= 1
		Input.action_release("move_forward")
		Input.action_press("move_back")
		Input.action_press("turn_left")
		return false
	Input.action_release("move_back")
	_drive(target)
	_wp_frames += 1
	if not refuelling and (mower.global_position.distance_to(target) < 18.0 or _wp_frames > 480): # can't get there in 8 s: skip it
		wp += 1
		_wp_frames = 0
	# Unstick: barely moved for 2s? Back off and turn; if it keeps happening, skip
	# the waypoint (a person would too).
	if frame % 120 == 0:
		if mower.global_position.distance_to(last_pos) < 10.0 and not resting:
			backing = 50
			stuck += 1
			if stuck >= 2 and not refuelling:
				wp += 1
				stuck = 0
		else:
			stuck = 0
		last_pos = mower.global_position
	return false


func _drive(target: Vector2) -> void:
	Input.action_release("turn_left")
	Input.action_release("turn_right")
	Input.action_release("move_forward")
	if target == Vector2.INF:
		return
	var want := (target - mower.global_position).angle()
	var diff := wrapf(want - mower.rotation, -PI, PI)
	mower.gear = 4 if absf(diff) < 0.3 else 2 # the ride-on shifts down to turn, as you would
	if diff > 0.05:
		Input.action_press("turn_right")
	elif diff < -0.05:
		Input.action_press("turn_left")
	if absf(diff) < 0.5:
		Input.action_press("move_forward")
