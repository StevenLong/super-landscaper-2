class_name Robot
extends CharacterBody2D
## The robot mower (design doc, Mowers and Equipment), like a real one: it knows the
## lawn's shape (the lawn grid: trees, beds, ponds and the house are off it) and mows what's
## still uncut in straight stripes, lane by lane along the way it was set down facing, going
## round what isn't lawn. Grass cut since it planned (by you, another robot) it skips; with
## none left it stops, done. It stops for anything alive or breakable in its way
## (main's `blocked`) and, kept waiting, gives up on that spot and moves on. A stone it
## grinds up, taking a knock. Nothing it does is yours: no crimes, no squashes (animal.gd,
## dog.gd).

const SPEED := 55.0
const LANE := 20.0 ## between stripes, a little under its cut so they overlap; also its planning grid
const WAIT := 2.0 ## seconds stopped for something before it gives up on that spot...
const WAIT_JITTER := 0.5 ## ...plus up to this, so two robots nose to nose don't give up in step
const STONE_KNOCK := 10.0 ## condition lost grinding up a stone (my number: ten stones and it's done for the job)

var cut_radius := 12.0
var body := Vector2(22, 18) ## its size, as a mower's
var condition := 100.0 ## at 0 it's broken down and stops (carried over a pick-up, fresh each job)
var lawn: Lawn
var blocked: Callable ## (p: Vector2, me: Robot) -> bool, global: something alive or breakable there
var heading := Vector2.RIGHT ## set before it's added: the stripes run this way
var crossable := Rect2() ## lawn space, off the lawn but fine to drive over (the drive), never mowed
var been := {} ## cells any robot on this lawn has stood in (main shares one): what's left there no robot can reach (by the fence, a bed's rim)
var route: Array[Vector2] = [] ## waypoints still to visit, lawn space: the plan

var _grid := AStarGrid2D.new()
var _across := true ## its lanes run left-right (else up-down), the way it was set down
var _targets := {} ## the cells the plan mows, not those it only crosses: Vector2i -> true
var _waited := 0.0
var _patience := WAIT
var _done := false ## nothing left to cut: it sits, light green
var _walled := false ## stopped by something solid (not something alive): that spot's out of reach for good
var _gave_up := {} ## cells it's given up on once: twice, and they're out of reach for good (a gnome stays put)


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body
	cs.shape = shape
	add_child(cs)
	_across = absf(heading.x) >= absf(heading.y)
	_patience = WAIT + randf() * WAIT_JITTER
	_map()
	plan()


## The lawn's shape on the planning grid, afresh: what it gave up on is open again.
func _map() -> void:
	var cells := Vector2i(Vector2(lawn.size_px) / LANE)
	_grid.region = Rect2i(Vector2i.ZERO, cells)
	_grid.cell_size = Vector2(LANE, LANE)
	_grid.offset = Vector2(LANE, LANE) * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for y in cells.y:
		for x in cells.x:
			_grid.set_point_solid(Vector2i(x, y), not _fits(_grid.get_point_position(Vector2i(x, y))))


## The route from here: every open cell still uncut that it can get to by the grid, lane by
## lane from the one it's on to the far side, then back for the lanes behind it; along each
## lane alternately, and round by the grid wherever the next cell isn't straight on. It
## only ever drives by the grid, so never over a bed.
func plan() -> void:
	var cells := _grid.region.size
	var across := _across
	var lanes_n := cells.y if across else cells.x
	var along_n := cells.x if across else cells.y
	var start := _cell(global_position - lawn.global_position)
	var first := clampi(start.y if across else start.x, 0, lanes_n - 1)
	var forward := (heading.x if across else heading.y) >= 0.0
	var order: Array[Vector2i] = []
	var behind: Array[Vector2i] = [] # its own lane behind where it was set down: done last
	var at := start.x if across else start.y
	var reach := {start: true} # what it can get to from here, by the grid
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + o
			if _grid.is_in_boundsv(n) and not reach.has(n) and not _grid.is_point_solid(n):
				reach[n] = true
				todo.append(n)
	for i: int in range(first, lanes_n) + range(first - 1, -1, -1):
		for k in along_n:
			var a := k if forward else along_n - 1 - k
			var c := Vector2i(a, i) if across else Vector2i(i, a)
			if reach.has(c) and not _grid.is_point_solid(c) and _wants(c):
				(behind if i == first and (a < at if forward else a > at) else order).append(c)
		forward = not forward
	behind.reverse() # back out from where it started
	order.append_array(behind)
	route.clear()
	_targets.clear()
	for c in order:
		_targets[c] = true
	var from := start
	for c in order:
		var d := (c - from).abs()
		if d.x + d.y > 1: # not straight on: by the grid, never cutting a corner
			var path := _path(from, c)
			for j in range(1, path.size() - 1):
				route.append(path[j])
		route.append(_grid.get_point_position(c))
		from = c


## Its body sits on lawn (or the drive) here (lawn space): nothing else excluded under it,
## so it never clips a bed (and tramples it). Past the lawn's outer edge is the fence: fine.
func _fits(p: Vector2) -> bool:
	for o: Vector2 in [Vector2.ZERO, Vector2(11, 0), Vector2(-11, 0), Vector2(0, 11), Vector2(0, -11)]:
		var q := (p + o).clamp(Vector2.ZERO, Vector2(lawn.size_px) - Vector2.ONE)
		if lawn._cell(q) == Lawn.EXCLUDED and not crossable.has_point(q):
			return false
	return true


## The grid's way from cell to cell, even from a cell it's standing in but wouldn't plan
## onto (set down by a bed): none if either end's off the grid or there's no way.
func _path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	if not (_grid.is_in_boundsv(from) and _grid.is_in_boundsv(to)):
		return PackedVector2Array()
	var shut := _grid.is_point_solid(from)
	_grid.set_point_solid(from, false)
	var path := _grid.get_point_path(from, to)
	_grid.set_point_solid(from, shut)
	return path


## Grass still uncut in cell c, anywhere its pass would cut, and it hasn't been there yet.
func _wants(c: Vector2i) -> bool:
	if been.has(c):
		return false
	var p := _grid.get_point_position(c)
	for o: Vector2 in [Vector2.ZERO, Vector2(7, 0), Vector2(-7, 0), Vector2(0, 7), Vector2(0, -7),
			Vector2(7, 7), Vector2(-7, 7), Vector2(7, -7), Vector2(-7, -7)]:
		if lawn._cell((p + o).clamp(Vector2.ZERO, Vector2(lawn.size_px) - Vector2.ONE)) == Lawn.UNCUT:
			return true
	return false


func _cell(p: Vector2) -> Vector2i:
	return Vector2i((p / LANE).floor())


func damage(amount: float) -> void:
	condition = maxf(0.0, condition - amount)
	queue_redraw()


func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if condition <= 0.0 or _done:
		return
	if route.is_empty(): # the plan's run out: whatever's still uncut, round nothing it gave up on before
		_map()
		plan()
		_done = route.is_empty()
		queue_redraw()
		return
	var here := global_position - lawn.global_position
	var to := route[0] - here
	if to.length() < 2.0:
		been[_cell(route.pop_front())] = true
		_reroute()
		return
	var dir := to.normalized()
	var ahead := global_position + dir * (cut_radius + 10.0)
	var stuck: bool = blocked.is_valid() and blocked.call(ahead, self)
	_walled = false
	if not stuck:
		rotation = dir.angle()
		velocity = dir * SPEED
		_walled = move_and_collide((velocity * delta).limit_length(to.length())) != null # never past the waypoint
		stuck = _walled
		lawn.cut_segment(here, global_position - lawn.global_position, cut_radius)
	if stuck:
		velocity = Vector2.ZERO
		_waited += delta
		if _waited > _patience:
			_skip(ahead - lawn.global_position)
		return
	_waited = 0.0


## Kept waiting: the waypoint it couldn't reach is dropped (for good if something solid's in
## the way), and the spot ahead (lawn space) and whatever of the cells round it the blocker
## covers are off the plan (till the plan next runs out); go round them.
func _skip(at: Vector2) -> void:
	_waited = 0.0
	_patience = WAIT + randf() * WAIT_JITTER
	var c := _cell(at)
	var here := _cell(global_position - lawn.global_position)
	for y in range(-1, 2):
		for x in range(-1, 2):
			var n := c + Vector2i(x, y)
			if n != here and _grid.is_in_boundsv(n) and (n == c or blocked.call(lawn.global_position + _grid.get_point_position(n), self)):
				_grid.set_point_solid(n)
	if not route.is_empty():
		var gone := _cell(route.pop_front())
		if _walled or _gave_up.has(gone):
			been[gone] = true
		_gave_up[gone] = true
	_reroute(true)


## Drop what's no use off the front of the route: cells given up on, cells cut since it
## planned (by you, another robot), and the way there; then round by the grid to the next
## cell it still wants. No way there now (it's given up on the only way): plan afresh.
func _reroute(dropped := false) -> void:
	while not route.is_empty():
		var c := _cell(route[0])
		if not _grid.is_point_solid(c) and (_wants(c) if _targets.has(c) else not dropped): # still wanted, or a step on an unbroken way to one
			if not dropped:
				return
			var path := _path(_cell(global_position - lawn.global_position), c)
			if path.is_empty():
				plan()
				return
			for j in range(path.size() - 2, 0, -1):
				route.push_front(path[j])
			return
		route.pop_front()
		dropped = true


func _draw() -> void:
	draw(self, Vector2.ZERO, Color("f8d048") if condition > 0.0 and not _done else (Color("e04030") if condition <= 0.0 else Color("78c850")))
	if condition < 100.0: # its own wear, under it (drawn unrotated)
		draw_set_transform(Vector2.ZERO, -rotation)
		draw_rect(Rect2(-12, 12, 24, 4), Color("1a1820"))
		draw_rect(Rect2(-12, 12, 24 * condition / 100.0, 4), Color("78c850") if condition > 30.0 else Color("e04030"))


func _process(_delta: float) -> void:
	queue_redraw()


## A squat grey shell with a green lid and a light (yellow mowing, green done, red
## broken down): drawn on the lawn and in your hands.
static func draw(on: CanvasItem, at: Vector2, light := Color("f8d048")) -> void:
	on.draw_rect(Rect2(at - Vector2(11, 9), Vector2(22, 18)), Color("5a5e66"))
	on.draw_rect(Rect2(at - Vector2(9, 7), Vector2(18, 12)), Color("5e9e4a"))
	on.draw_circle(at + Vector2(6, 0), 2.0, light)
