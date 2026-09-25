# Balance probe (not part of run_all): a bot mows the small hand-made lawn in lanes
# with each mower, refuelling/resting as needed, and prints how long it took to
# reach each coverage mark. Compare against customer patience (240s x 0.7..1.6 on a
# small lawn). The bot turns and lines up far better than a person, so treat its
# times as a floor.
#   "$GODOT" --headless --fixed-fps 60 --path . -s tests/sim_balance.gd
extends SceneTree

const MARKS := [0.5, 0.7, 0.85, 0.95]
const LIMIT := 60 * 60 * 12 # frames (12 simulated minutes)

var kinds := ["push", "petrol", "rideon"]
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


func _initialize() -> void:
	pass # the first run starts on the first physics frame, once the tree is live


func _next() -> void:
	if m:
		m.queue_free()
		Input.action_release("move_forward")
		Input.action_release("turn_left")
		Input.action_release("turn_right")
	if kinds.is_empty():
		quit()
		return
	var kind: String = kinds.pop_front()
	# The default lawn, but a customer who won't fire the bot for trampling flowers.
	var game: Node = root.get_node("Game")
	game.current_job = game.default_job().merged({"persona": "busy"}, true)
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	mower = m.get_node("Mower")
	var spec: Dictionary = root.get_node("Game").MOWERS[kind].duplicate()
	mower.apply_spec(spec)
	lawn = m.get_node("Lawn")
	# Lanes across the lawn, spaced a little under the cut width. The strips either
	# side of the house are mowed as their own blocks, joined by a detour under it.
	waypoints.clear()
	var step: float = mower.cut_radius * 1.7
	var house: Rect2 = m.get_node("Scenery/House").footprint().grow(40)
	var lo: float = mower.edge_margin
	var hi: float = lawn.size_px.x - mower.edge_margin
	var below: float = house.end.y + 30.0
	_block(lo, house.position.x, mower.edge_margin, house.end.y, step)
	waypoints.append(Vector2(house.position.x, below))
	waypoints.append(Vector2(house.end.x, below))
	_block(house.end.x, hi, mower.edge_margin, house.end.y, step)
	_block(lo, hi, house.end.y, lawn.size_px.y, step)
	wp = 0
	frame = 0
	hit = {"kind": kind}
	resting = false
	refuelling = false


## Boustrophedon lanes over the rect x0..x1, y0..y1.
func _block(x0: float, x1: float, y0: float, y1: float, step: float) -> void:
	var right := true
	var y := y0
	while y < y1:
		waypoints.append(Vector2(x0 if right else x1, y))
		waypoints.append(Vector2(x1 if right else x0, y))
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
	m.customer.mood = 60.0 # the probe measures mowing time, not customer management
	var cov := lawn.cut_fraction()
	for mark: float in MARKS:
		if cov >= mark and not hit.has(mark):
			hit[mark] = frame / 60.0
	if hit.has(MARKS[-1]) or frame > LIMIT or wp >= waypoints.size():
		var parts := []
		for mark: float in MARKS:
			parts.append("%d%%: %s" % [roundi(mark * 100.0), ("%ds" % roundi(hit[mark])) if hit.has(mark) else "never"])
		print("%-7s %s  (cut %d%% by %ds)" % [hit.kind, "  ".join(parts), roundi(cov * 100.0), roundi(frame / 60.0)])
		_next()
		return false

	var frac: float = mower.fuel / mower.max_fuel
	var target: Vector2 = waypoints[wp]
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
				return false
			target = m.truck_spot()
	if backing > 0:
		backing -= 1
		Input.action_release("move_forward")
		Input.action_press("move_back")
		Input.action_press("turn_left")
		return false
	Input.action_release("move_back")
	_drive(target)
	if not refuelling and mower.global_position.distance_to(target) < 14.0:
		wp += 1
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
	if diff > 0.05:
		Input.action_press("turn_right")
	elif diff < -0.05:
		Input.action_press("turn_left")
	if absf(diff) < 0.5:
		Input.action_press("move_forward")
