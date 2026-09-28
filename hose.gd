class_name Hose
extends Node2D
## The garden hose, green, on a reel below a tap on the house. Take the far end and walk:
## it pays off the reel as you go, up to its length. Walk up to the reel and it winds back
## in. It lies as a chain of points, a rope that can go slack but never stretch, fold back
## or kink (each link turns at most MAX_BEND from the one before). A moving mower that
## touches it cuts it there: a link's shredded, and what was past it lies loose on the lawn,
## a piece of its own (no reel) you can take by either end and drag. Points are in the
## garden's coordinates; [0] is at the reel (or a loose piece's cut end).

signal mowed(at: Vector2)
signal split(piece: PackedVector2Array, nozzle_on: int) ## the far side of a cut, lying loose

const SEG := 16.0 ## the length of each link
const LINKS := 18 ## the whole hose, in links
const MAX_BEND := 0.6 ## radians a link may turn from the one before it
const WIND := 0.06 ## seconds to wind in a link
const COLOURS := [Color("1c4a1e"), Color("3c9a3a"), Color("8ad06a")] ## outline, hose, sheen

var points := PackedVector2Array()
var mower: Node2D ## main's, to see if it runs over us
var grabbed := false ## the far end is in your hand
var hand := Vector2.ZERO
var cut := false ## cut, or a loose piece: the blades can't cut it (again)
var loose := false ## a cut-off piece: no reel, and nothing holds either end
var nozzle_at := 1 ## which end has the brass nozzle: 1 the far end (points[-1]), 0 points[0], -1 neither
var winding := false ## going back onto the reel, a link at a time
var length := LINKS ## links in all, out and on the reel (fewer once it's cut)
var tap := Vector2.ZERO ## on the wall above the reel
var reel: Node2D ## stands on the ground at points[0]; main puts it in the scenery, y-sorted
var _prev := PackedVector2Array()
var _wind_t := 0.0


## Laid out from the reel along `path` (points SEG apart, the first at the reel), fed
## from the tap at `tap_at`.
func lay(path: PackedVector2Array, tap_at: Vector2) -> void:
	points = path
	_prev = path.duplicate()
	tap = tap_at
	reel = Node2D.new()
	reel.position = path[0]
	reel.draw.connect(_draw_reel)


## A cut-off piece lying along `path`, with the nozzle where `nozzle_on` says (nozzle_at).
func lay_loose(path: PackedVector2Array, nozzle_on: int) -> void:
	points = path
	_prev = path.duplicate()
	loose = true
	cut = true # ponytail: a loose piece isn't cut again; split it further if play asks
	nozzle_at = nozzle_on
	length = path.size() - 1


## Turn a loose piece end for end, so the end you take hold of is the far one.
func flip() -> void:
	points.reverse()
	_prev.reverse()
	if nozzle_at >= 0:
		nozzle_at = 1 - nozzle_at


## Links still on the reel.
func stored() -> int:
	return 0 if loose else length - (points.size() - 1)


## The far end, where you pick it up (the reel end stays on the reel).
func end() -> Vector2:
	return points[points.size() - 1]


## How far from the reel you can take the end: all of it, paid out.
func reach() -> float:
	return length * SEG


func _physics_process(delta: float) -> void:
	if loose:
		pass
	elif winding and not grabbed:
		_wind_t += delta
		while _wind_t >= WIND and points.size() > 1:
			_wind_t -= WIND
			points.remove_at(1) # the link by the reel goes onto it; the rest is pulled after
			_prev.remove_at(1)
		if points.size() <= 1:
			winding = false
		reel.queue_redraw()
	elif grabbed and stored() > 0 and hand.distance_to(points[0]) > (points.size() - 1) * SEG * 0.9:
		points.insert(1, points[0]) # pulled off the reel
		_prev.insert(1, points[0])
		reel.queue_redraw()
	if points.size() < 2:
		queue_redraw()
		return
	# Verlet, heavily damped: the grass holds it, so slack stays where it falls.
	for i in range(0 if loose else 1, points.size()): # a loose piece has no reel end holding it
		var p := points[i]
		points[i] = p + (p - _prev[i]) * 0.3
		_prev[i] = p
	var last := points.size() - 1
	for _k in 8:
		if grabbed:
			points[last] = hand
		for i in last:
			var d := points[i + 1] - points[i]
			var over := d.length() - SEG
			if over <= 0.0:
				continue # slack is fine; only too long gets pulled in
			var fix := d.normalized() * over
			var a_fixed := i == 0 and not loose
			var b_fixed := grabbed and i + 1 == last
			if a_fixed and not b_fixed:
				points[i + 1] -= fix
			elif b_fixed and not a_fixed:
				points[i] += fix
			elif not a_fixed:
				points[i] += fix * 0.5
				points[i + 1] -= fix * 0.5
		for i in range(1, last): # no folds or kinks: a sharp corner eases toward straight
			var a := points[i] - points[i - 1]
			var b := points[i + 1] - points[i]
			if a.length() > 0.5 and b.length() > 0.5 and absf(a.angle_to(b)) > MAX_BEND:
				points[i] = points[i].lerp((points[i - 1] + points[i + 1]) * 0.5, 0.5)
	if not cut and mower and mower.velocity.length() > 15.0:
		var r: float = mower.cut_radius
		for i in range(1, points.size()):
			if points[i].distance_to(mower.global_position) < r:
				_cut_at(i)
				break
	queue_redraw()


## Through the blades at point i: that link's shredded, the reel side stays on the reel and
## what's past it lies loose (split), if there's enough of it to pick up.
func _cut_at(i: int) -> void:
	cut = true
	var at := points[i]
	if points.size() - (i + 1) >= 2:
		split.emit(points.slice(i + 1), nozzle_at)
	length = stored() + i - 1
	points.resize(i)
	_prev.resize(i)
	grabbed = false
	winding = false
	nozzle_at = -1
	reel.queue_redraw()
	mowed.emit(at)


## The hose as a smooth curve through its points (Catmull-Rom), so bends are round.
func _curve() -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n - 1:
		var p0 := points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[mini(i + 2, n - 1)]
		for s in 4:
			var t := s / 4.0
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(points[n - 1])
	return out


func _draw() -> void:
	if points.size() < 2:
		return
	var line := _curve()
	draw_polyline(line, COLOURS[0], 5.0)
	draw_polyline(line, COLOURS[1], 3.0)
	draw_polyline(line, COLOURS[2], 1.0)
	var n := points.size()
	for e in ([1, 0] if loose else [1]): # the far end, and a loose piece's other end
		var tip := points[n - 1] if e == 1 else points[0]
		if nozzle_at == e:
			var d := (tip - (points[n - 2] if e == 1 else points[1])).normalized()
			draw_line(tip, tip + d * 4.0, Color("8a6a2a"), 4.0)
			draw_line(tip, tip + d * 4.0, Color("c8a048"), 2.0)
		else: # a chewed end
			draw_circle(tip, 2.5, COLOURS[0])


## The reel: a drum on a stand, fatter the more hose is on it; the tap on the wall above
## with a short feed down to the drum.
func _draw_reel() -> void:
	var t := tap - reel.position
	var steel := Color("7a7a82")
	# The tap: a stone plate on the wall, a brass body, a spout, a cross handle.
	reel.draw_rect(Rect2(t + Vector2(-7, -14), Vector2(14, 16)), Color("9a9488"))
	reel.draw_rect(Rect2(t + Vector2(-7, -14), Vector2(14, 1)), Color("c4beb0"))
	reel.draw_rect(Rect2(t + Vector2(-3, -10), Vector2(6, 8)), Color("8a6a2a"))
	reel.draw_rect(Rect2(t + Vector2(-2, -10), Vector2(4, 6)), Color("d8b050"))
	reel.draw_rect(Rect2(t + Vector2(-5, -13), Vector2(10, 2)), Color("c8a048"))
	reel.draw_rect(Rect2(t + Vector2(-1, -2), Vector2(3, 4)), Color("8a6a2a"))
	reel.draw_line(t + Vector2(0, 2), Vector2(0, -20), COLOURS[0], 4.0) # the feed down to the drum
	reel.draw_line(t + Vector2(0, 2), Vector2(0, -20), COLOURS[1], 2.0)
	# The stand and the drum between two flanges, wound with what's left on it.
	var hub := Vector2(0, -12)
	reel.draw_circle(Vector2(0, 1), 9.0, Color(0, 0, 0, 0.25)) # its shadow
	for x: float in [-7.0, 7.0]: # an A-frame leg under each flange
		reel.draw_line(Vector2(x - 3.0, 0), hub + Vector2(x, 0), steel, 2.0)
		reel.draw_line(Vector2(x + 3.0, 0), hub + Vector2(x, 0), steel, 2.0)
	var r := 3.0 + 5.0 * stored() / float(LINKS)
	reel.draw_rect(Rect2(hub + Vector2(-6, -3), Vector2(12, 6)), Color("5a5a62")) # the bare drum
	reel.draw_rect(Rect2(hub + Vector2(-6, -r), Vector2(12, 2.0 * r)), COLOURS[1])
	for y in range(int(-r) + 1, int(r), 2): # the coils
		reel.draw_line(hub + Vector2(-6, y), hub + Vector2(6, y), COLOURS[0] if y % 4 == 0 else COLOURS[2], 1.0)
	for x: float in [-7.0, 7.0]: # the flanges, seen edge-on
		reel.draw_rect(Rect2(hub + Vector2(x - 1.5, -9), Vector2(3, 18)), Color("2e6a30"))
		reel.draw_rect(Rect2(hub + Vector2(x - 1.5, -9), Vector2(1, 18)), Color("5aa04e"))
	reel.draw_line(hub + Vector2(8.5, 0), hub + Vector2(12, -4), steel, 1.5) # the crank
	reel.draw_circle(hub + Vector2(12, -4), 1.5, Color("c03828"))
