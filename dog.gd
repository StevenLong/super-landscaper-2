class_name Dog
extends Area2D
## The customer's dog, loose on the lawn. Bounds about at random. A moving mower
## bowls it over (it yelps and limps home). On foot, put the lead on (main) and it
## follows you; bring it back to its owner.

signal bowled(dog: Dog, by: String) ## by "mower" (run over) or "stone"
signal home(dog: Dog)
signal caught(dog: Dog)
signal dropped_ball(at: Vector2)

var lawn_rect := Rect2()
var house := Rect2() ## the house (and garage) it goes round, never through
var home_point := Vector2.ZERO
var following: Node2D = null
var heading := Vector2.RIGHT
var _dash := 0.0
var _t := 0.0
var limping := false
var fetching: Node2D = null ## a ball on the lawn it's gone after
var bring_to: Node2D = null ## who it takes the ball back to
var has_ball := false
var _grief := 0.0 ## seconds left sulking after watching its ball get mowed
var held := false ## in your arms (or in the air): the walker draws it, it does nothing


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	var speed := 0.0
	if held:
		return
	if _grief > 0.0 and not limping:
		_grief -= delta
		queue_redraw()
		return
	if not limping and not following and (fetching or has_ball):
		if fetching and not is_instance_valid(fetching):
			fetching = null
		var goal: Vector2 = fetching.global_position if fetching else (bring_to.global_position if is_instance_valid(bring_to) else home_point)
		var to := _inside(goal) - global_position # you're past its side of the house: it brings it to the nearest it can get
		if to.length() < (6.0 if fetching else 22.0):
			if fetching:
				fetching.queue_free()
				fetching = null
				has_ball = true
			else:
				has_ball = false
				dropped_ball.emit(global_position + heading * 8.0)
		else:
			heading = to.normalized()
			position = _inside(position + heading * 170.0 * delta)
		queue_redraw()
		return
	if limping or following:
		var goal := home_point if limping else following.global_position
		var to := goal - global_position
		if limping and to.length() < 12.0:
			queue_free()
			return
		if following and global_position.distance_to(home_point) < 60.0:
			home.emit(self)
			queue_free()
			return
		if to.length() > (4.0 if limping else 28.0):
			heading = to.normalized()
			speed = 60.0 if limping else 150.0
	elif _inside(position) != position: # put down past the house: back round it to its side
		var goal := _inside(position)
		if _through(position, goal):
			var sides: Array = [house.position.x - 16.0, house.end.x + 16.0].filter(func(x: float) -> bool: return x > lawn_rect.position.x and x < lawn_rect.end.x)
			if sides.is_empty(): # no way round: it's simply back
				position = goal
				queue_redraw()
				return
			sides.sort_custom(func(a: float, b: float) -> bool: return absf(a - position.x) < absf(b - position.x))
			goal = Vector2(sides[0], position.y)
		heading = (goal - position).normalized()
		position = position.move_toward(goal, 150.0 * delta)
		queue_redraw()
		return
	else:
		_dash -= delta
		if _dash <= 0.0:
			_dash = randf_range(0.5, 1.6)
			heading = Vector2.RIGHT.rotated(randf() * TAU)
		speed = 120.0 if fmod(_t, 2.0) < 1.4 else 0.0
	position += heading * speed * delta
	if not limping:
		position = _inside(position)
	queue_redraw()


## Whether the straight run from a to b goes through the house.
func _through(a: Vector2, b: Vector2) -> bool:
	for i in range(1, 20):
		if house.has_point(a.lerp(b, i / 20.0)):
			return true
	return false


## p kept on its side of the house (it never runs through it).
func _inside(p: Vector2) -> Vector2:
	return p.clamp(lawn_rect.position + Vector2(10, 10), lawn_rect.end - Vector2(10, 10))


## Picked up: it vanishes into your arms until let go.
func hold() -> void:
	held = true
	following = null
	fetching = null
	visible = false


## Back on the ground at `at`, and off at a run.
func let_go(at: Vector2) -> void:
	held = false
	visible = true
	position = at
	heading = Vector2.RIGHT.rotated(randf() * TAU)
	_dash = 1.2


## Off after a thrown ball, to bring it back to `to`: only one on its side of the house
## (past it, it would have to run through the house).
func fetch(ball: Node2D, to: Node2D) -> void:
	if not limping and not following and not has_ball and _inside(ball.global_position) == ball.global_position:
		fetching = ball
		bring_to = to


## Its ball just went through the blades in front of it: it lies down and sulks.
func grieve() -> void:
	fetching = null
	has_ball = false
	_grief = 5.0


func bowl(by := "mower") -> void:
	if limping:
		return
	limping = true
	following = null
	bowled.emit(self, by)


func _on_body_entered(body: Node2D) -> void:
	if limping or held:
		return
	if "cut_radius" in body and not body is Robot: # a robot stops for the dog
		if (body.velocity as Vector2).length() > 15.0:
			bowl()


## On the lead: it trots after `by` till it's home.
func lead(by: Node2D) -> void:
	following = by
	fetching = null
	caught.emit(self)


func _draw() -> void:
	var frame := int(_t * 9.0) % 2
	var hop := -absf(sin(_t * 12.0)) * 3.0
	if _grief > 0.0:
		frame = 0
		hop = 0.0
	Facing.draw(self, preload("res://art/dog.png"), 2, frame, heading.angle(), Vector2(0, hop))
	if has_ball:
		var mouth := Vector2(9, 0).rotated(heading.angle()) * Vector2(1.0, 0.6) + Vector2(0, -8.0 + hop)
		draw_texture(preload("res://art/ball.png"), mouth - Vector2(3.5, 3.5))
	if _grief > 0.0: # a sad little rain cloud
		draw_circle(Vector2(0, -26), 5.0, Color("8890a0"))
		draw_circle(Vector2(5, -25), 4.0, Color("8890a0"))
		for i in 3:
			draw_line(Vector2(-3 + i * 3, -20), Vector2(-4 + i * 3, -16 + fmod(_t * 20.0 + i * 3.0, 6.0)), Color("68a0e0"), 1.0)
	if following:
		# The lead, from the collar to the hand, sagging a little.
		var hand := to_local(following.global_position) + Vector2(0, -14)
		var collar := Vector2(6, 0).rotated(heading.angle()) * Vector2(1.0, 0.6) + Vector2(0, -10.0 + hop)
		var mid := (collar + hand) / 2.0 + Vector2(0, 6)
		draw_polyline(PackedVector2Array([collar, mid, hand]), Color("c03828"), 1.0)
	if limping:
		for i in 3:
			var a := _t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 10.0, -14.0 + sin(a) * 3.0), 1.5, Color("f8e070"))
