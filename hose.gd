class_name Hose
extends Node2D
## The garden hose: fixed to a tap on the house wall, lying across the lawn as a chain
## of points (a rope that can go slack, never stretch). On foot you pick it up by
## whichever bit is nearest and drag it out of the way: grab it near the tap and you
## can't take it far. A moving mower that touches it cuts it there, and the loose end
## is shredded. Points are in the garden's coordinates.

signal mowed(at: Vector2)

const SEG := 16.0 ## the length of each link
const COLOURS := [Color("6a3a10"), Color("e8902c"), Color("f8c070")] ## outline, hose, sheen: orange, to stand out on grass

var points := PackedVector2Array() ## [0] is at the tap
var mower: Node2D ## main's, to see if it runs over us
var grabbed := -1 ## which point is in your hand, or -1
var hand := Vector2.ZERO
var cut := false
var _prev := PackedVector2Array()
var _tap: Node2D ## drawn over the house wall it's fixed to


## Laid out from the tap along `path` (points SEG apart, the first at the tap).
func lay(path: PackedVector2Array) -> void:
	points = path
	_prev = path.duplicate()
	z_index = -1 # flat on the ground
	_tap = Node2D.new()
	_tap.z_index = 2 # relative: over the house
	_tap.position = path[0]
	_tap.draw.connect(func() -> void: # a brass tap on the wall, the hose pushed onto it
		_tap.draw_rect(Rect2(-3, -14, 6, 10), Color("8a6a2a"))
		_tap.draw_rect(Rect2(-5, -16, 10, 3), Color("c8a048"))
		_tap.draw_circle(Vector2(0, -3), 3.0, Color("c8a048")))
	add_child(_tap)
	queue_redraw()


## The point nearest p, if it's within reach of a hand; else -1. Not the tap itself.
func nearest(p: Vector2) -> int:
	var best := -1
	for i in range(1, points.size()):
		if points[i].distance_to(p) < 14.0 and (best < 0 or points[i].distance_to(p) < points[best].distance_to(p)):
			best = i
	return best


## How far from the tap you can take the point you're holding: the hose between is all
## the slack there is.
func reach() -> float:
	return grabbed * SEG


func _physics_process(_delta: float) -> void:
	if points.size() < 2:
		return
	# Verlet, heavily damped: the grass holds it, so slack stays where it falls.
	for i in range(1, points.size()):
		var p := points[i]
		points[i] = p + (p - _prev[i]) * 0.3
		_prev[i] = p
	for _k in 8:
		if grabbed > 0:
			points[grabbed] = hand
		for i in points.size() - 1:
			var d := points[i + 1] - points[i]
			var over := d.length() - SEG
			if over <= 0.0:
				continue # slack is fine; only too long gets pulled in
			var fix := d.normalized() * over
			var a_fixed := i == 0 or i == grabbed
			var b_fixed := i + 1 == grabbed
			if a_fixed and not b_fixed:
				points[i + 1] -= fix
			elif b_fixed and not a_fixed:
				points[i] += fix
			elif not a_fixed:
				points[i] += fix * 0.5
				points[i + 1] -= fix * 0.5
	if not cut and mower and mower.velocity.length() > 15.0:
		var r: float = mower.cut_radius
		for i in range(1, points.size()):
			if points[i].distance_to(mower.global_position) < r:
				_cut_at(i)
				break
	queue_redraw()


## Through the blades at point i: everything past it is shredded; the rest stays on the tap.
func _cut_at(i: int) -> void:
	cut = true
	var at := points[i]
	points.resize(i)
	_prev.resize(i)
	if grabbed >= i:
		grabbed = -1
	mowed.emit(at)


func _draw() -> void:
	if points.is_empty():
		return
	draw_polyline(points, COLOURS[0], 5.0)
	draw_polyline(points, COLOURS[1], 3.0)
	draw_polyline(points, COLOURS[2], 1.0)
	if cut: # the chewed end
		draw_circle(points[-1], 2.5, COLOURS[0])
