extends CharacterBody2D
## Arcade mower: throttle forward/back along its heading, turn in place. Faces +x
## in local space. The exports are the petrol defaults; apply_spec() swaps in a
## run's equipped mower.
##
## power "fuel": burns constantly while the engine runs; refill at the truck.
## power "stamina": a push mower. Pushing tires you; resting recovers. Exhausted,
## it crawls (but still cuts: it's your legs, not an engine).

signal fuel_changed(fraction: float)
signal condition_changed(fraction: float)
signal bumped(what: Object, impact: float) ## a hard knock into something solid

@export var lawn: Lawn
@export var power := "fuel"
@export var max_speed := 220.0
@export var reverse_speed := 110.0
@export var accel := 600.0
@export var brake := 900.0
@export var turn_rate := 3.0 ## radians per second
@export var cut_radius := 16.0
@export var edge_margin := 12.0 ## small enough that cut_radius reaches the lawn edge AND corners
@export var max_fuel := 40.0 ## seconds of running
@export var fuel_burn := 1.0 ## per second
@export var regen := 0.0 ## stamina recovered per second while not pushing
@export var empty_speed_scale := 0.35 ## pushing a dead mower
@export var sprite_kind := "petrol" ## art/mower_<kind>.png: two frames of motion, then empty; a row per facing
@export var toughness := 1.0 ## damage taken is divided by this
@export var knock_out := 0.3 ## how often a critter it runs over is knocked out, not splatted: the smaller the mower, the likelier
@export var body := Vector2(36, 28) ## length x width, as the voxel model is built

const WALK := 0.6 ## a push mower walks at this share of its top speed; hold sprint for all of it
const IDLE_BURN := 0.3 ## an engine running with the mower standing still, of fuel_burn
const WALK_BURN := 0.6 ## walking tires you slowly (of fuel_burn)...
const SPRINT_BURN := 1.5 ## ...sprinting fast
const PULL_TIME := 0.9 ## seconds for the ripcord's marker to sweep the meter
const SWEET_AT := 0.62 ## where the sweet spot starts on the meter
const COUGH := 1.0 ## seconds lost to a missed pull
const YANK := 0.3 ## seconds the hand takes to yank the cord on a good pull
const STALL_BELOW := 40.0 ## a petrol mower in worse condition than this can stall on a knock...
const STALL_CHANCE := 0.5 ## ...this often
const GEARS := [0.3, 0.5, 0.75, 1.0] ## a ride-on's top speed in each gear, of max_speed
const GEAR_TURN := [1.0, 0.85, 0.7, 0.55] ## and its turn rate: higher gears, wider circles

@onready var fuel := max_fuel
var fuel_used := 0.0
var condition := 100.0 ## 0 = broken: crawls and cuts nothing until repaired at the truck
var repaired := 0.0 ## points repaired this job (costs money)
var occupied := true ## false while the player is off on foot
var throttle := 0.0
var sprinting := false ## a push mower, pushed flat out (hold sprint)
var engine_off := false ## a powered mower switched off: burns nothing and won't go. The petrol starts by
## ripcord (each job, after a stall, after you switch it off); the ride-on on its key (interact)
var pull := -1.0 ## the ripcord's marker, 0 to 1, while you draw the cord; -1 when not
var gear := 1 ## a ride-on's gear, 1 to 4
var _cough := 0.0
var _yank := 0.0 ## seconds left of a good pull's yank (drawn after it's started)
var _yank_at := 0.0 ## where on the meter it was let go
var _cord: Node2D ## the ripcord's meter, over the mower
var _stride := 0.0
var _bump_cooldown := 0.0
var _was_touching := false
var _low_warned := false
var _engine: AudioStreamPlayer2D ## heard from where the mower is: fainter and off to one side when you're away on foot
var _clippings: CPUParticles2D


func _ready() -> void:
	_engine = AudioStreamPlayer2D.new()
	_engine.bus = "SFX"
	_engine.max_distance = 1100.0
	_engine.attenuation = 1.5
	add_child(_engine)
	_cord = Node2D.new()
	_cord.z_index = 5
	_cord.draw.connect(_draw_cord)
	add_child(_cord)
	_clippings = CPUParticles2D.new()
	_clippings.emitting = false
	_clippings.amount = 24
	_clippings.lifetime = 0.45
	_clippings.local_coords = false
	_clippings.direction = Vector2(0, -1)
	_clippings.spread = 70.0
	_clippings.initial_velocity_min = 40.0
	_clippings.initial_velocity_max = 90.0
	_clippings.gravity = Vector2.ZERO
	_clippings.damping_min = 120.0
	_clippings.damping_max = 160.0
	_clippings.scale_amount_min = 1.5
	_clippings.scale_amount_max = 2.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color("86c85a"))
	ramp.set_color(1, Color(0.3, 0.55, 0.2, 0.0))
	_clippings.color_ramp = ramp
	add_child(_clippings)
	$Shape.shape = ConvexPolygonShape2D.new()
	_apply_visual()


var _anim := 0 ## 0/1 while moving, 2 standing empty


## The sprite stays upright; the body's rotation picks the facing row.
func _show() -> void:
	var spr: Sprite2D = $Sprite
	spr.global_rotation = 0.0
	spr.frame = Facing.of(rotation) * 3 + _anim
	_fit_shape()


## The collision is the body's footprint as the 3/4 view draws it: depth is foreshortened
## (tools/voxel.py G = 0.6), so heading north the mower is shorter on screen than east.
func _fit_shape() -> void:
	var cs: CollisionShape2D = $Shape
	if not cs.shape is ConvexPolygonShape2D:
		return # before _ready
	var pts := PackedVector2Array()
	for c: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		pts.append((c * body / 2.0).rotated(rotation) * Vector2(1.0, 0.6))
	cs.shape.points = pts
	cs.global_rotation = 0.0


func _apply_visual() -> void:
	var spr: Sprite2D = $Sprite
	spr.texture = load("res://art/mower_%s.png" % sprite_kind)
	spr.hframes = 3 # two frames of motion, then empty
	spr.vframes = 8 # the facings: the body turns, the sprite picks a row and stays upright
	_show()
	if _engine == null:
		return # not in the tree yet; _ready will finish the job
	_engine.stream = load("res://audio/%s.wav" % {"push": "reel", "rideon": "engine_rideon"}.get(sprite_kind, "engine_petrol"))
	_engine.volume_db = -80.0 # the loops don't start at zero: at full volume that step pops
	_engine.play()


## Engine note follows speed; a push mower's reel only whirrs while it rolls.
func _update_sound(delta: float, running: bool) -> void:
	var s := clampf(velocity.length() / max_speed, 0.0, 1.0)
	if power == "stamina":
		_engine.volume_db = linear_to_db(maxf(s, 0.001)) - 4.0
		_engine.pitch_scale = 0.8 + 0.6 * s
	elif running:
		_engine.volume_db = -10.0 + 4.0 * s
		_engine.pitch_scale = 0.85 + 0.7 * s
	else:
		_engine.volume_db = -80.0
	var frac := fuel / max_fuel
	if frac < 0.2 and not _low_warned and power == "fuel":
		_low_warned = true
		Sfx.play("fuel_low", 0.0)
	elif frac > 0.3:
		_low_warned = false
	_bump_cooldown -= delta


## Drawing the ripcord: holding the throttle draws it while the marker sweeps the meter;
## let go in the sweet spot and it starts. Let go outside it, or draw it all the way, and it
## coughs and you lose a second. The throttle does nothing till it's going.
func _ripcord(delta: float) -> void:
	var held := throttle > 0.0 and occupied
	throttle = 0.0
	if _cough > 0.0:
		_cough -= delta
		pull = -1.0
	elif held:
		pull = maxf(pull, 0.0) + delta / PULL_TIME
		if pull >= 1.0:
			_miss()
	elif pull >= 0.0:
		var s := sweet()
		if pull >= s.x and pull <= s.y:
			engine_off = false
			_yank = YANK
			_yank_at = pull
			Sfx.play("ui_select", 0.0)
		else:
			_miss()
		pull = -1.0
	_cord.queue_redraw()


func _miss() -> void:
	pull = -1.0
	_cough = COUGH
	Sfx.play("cough")


## Where on the meter the ripcord catches: [from, to], narrower the worse its condition.
func sweet() -> Vector2:
	return Vector2(SWEET_AT, SWEET_AT + lerpf(0.06, 0.2, condition / 100.0))


## Interact on a powered mower: the ride-on's key turns it on or off; the petrol only
## switches off this way (its ripcord starts it). Off, it burns no fuel.
func toggle_engine() -> void:
	if power != "fuel" or (engine_off and sprite_kind == "petrol"):
		return
	engine_off = not engine_off
	pull = -1.0
	Sfx.play("ui_select" if not engine_off else "ui_move", 0.0)
	_cord.queue_redraw()


## A knock can stall a petrol mower in poor condition; it needs the ripcord again.
func stall_check(roll := randf()) -> void:
	if sprite_kind == "petrol" and not engine_off and condition < STALL_BELOW and roll < STALL_CHANCE:
		engine_off = true
		Sfx.play("cough")


## The ripcord's meter over the mower: the sweet spot in green with PULL over it (lit while
## the marker's in it). A hand grips the cord's handle and draws it along the meter as you
## hold; let go in the green and it yanks the cord up and away as the engine catches.
func _draw_cord() -> void:
	if not (engine_off and occupied and sprite_kind == "petrol" and fuel > 0.0) and _yank <= 0.0:
		return
	_cord.global_rotation = 0.0
	var at := Vector2(-22, -46)
	var s := sweet()
	_cord.draw_rect(Rect2(at - Vector2(1, 1), Vector2(46, 8)), Color(0, 0, 0, 0.7))
	_cord.draw_rect(Rect2(at, Vector2(44, 6)), Color("5a3030") if _cough > 0.0 else Color("3a3a42"))
	_cord.draw_rect(Rect2(at + Vector2(44 * s.x, 0), Vector2(44 * (s.y - s.x), 6)), Color("58c048"))
	var t := 1.0 - _yank / YANK if _yank > 0.0 else 0.0 # through the yank, 0 to 1
	var drawn := _yank_at if _yank > 0.0 else maxf(pull, 0.0) # at rest, the hand waits at the start
	var lit := drawn >= s.x and drawn <= s.y
	_cord.draw_string(ThemeDB.fallback_font, at + Vector2(44 * (s.x + s.y) / 2.0 - 20, -3), "PULL", HORIZONTAL_ALIGNMENT_CENTER, 40, 10,
		Color("f8d048") if lit else Color("f0ead8")) # UI.GOLD, UI.TEXT
	var hand := at + Vector2(44 * drawn, 3) + Vector2(18, -5) * sqrt(t)
	_cord.draw_line(at + Vector2(0, 3), hand, Color("d8d0c0"), 1.0) # the cord, from the engine end
	_cord.draw_rect(Rect2(hand - Vector2(1, 4), Vector2(3, 8)), Color("c83828")) # the handle
	_cord.draw_rect(Rect2(hand + Vector2(-3, -3), Vector2(7, 6)), Color("5a3020")) # a fist round it
	_cord.draw_rect(Rect2(hand + Vector2(-2, -2), Vector2(5, 4)), Color("e0a878"))


## Damage from what we just drove into: only the moment of contact, and only the
## speed INTO the obstacle, counts. Scraping along a wall, or pressing against it,
## is free; a head-on smack is not.
func _check_impacts(velocity_before: Vector2) -> void:
	var touching := get_slide_collision_count() > 0
	var fresh := touching and not _was_touching
	_was_touching = touching
	if not fresh:
		return
	var impact := 0.0
	var what: Object = null
	for i in get_slide_collision_count():
		var into := -velocity_before.dot(get_slide_collision(i).get_normal())
		if into > impact:
			impact = into
			what = get_slide_collision(i).get_collider()
	if impact > 60.0 and _bump_cooldown <= 0.0:
		bumped.emit(what, impact)
		_bump_cooldown = 0.4
		Sfx.play("bump")
		damage(impact / 25.0)
		stall_check()


func apply_spec(spec: Dictionary) -> void:
	for k in ["power", "max_speed", "reverse_speed", "accel", "brake", "turn_rate", "cut_radius",
			"max_fuel", "fuel_burn", "regen", "empty_speed_scale", "toughness", "knock_out"]:
		set(k, spec[k])
	sprite_kind = spec.sprite
	body = spec.body
	_apply_visual()
	fuel = max_fuel
	engine_off = power == "fuel" # started by hand (or key), each job
	gear = 1
	edge_margin = minf(edge_margin, cut_radius * 0.75)


func damage(amount: float) -> void:
	condition = maxf(0.0, condition - amount / toughness)
	condition_changed.emit(condition / 100.0)


func repair(amount: float) -> void:
	var before := condition
	condition = minf(100.0, condition + amount)
	repaired += condition - before
	condition_changed.emit(condition / 100.0)


func add_fuel(amount: float) -> void:
	var before := fuel
	fuel = minf(max_fuel, fuel + amount)
	if power == "fuel":
		fuel_used += fuel - before


func _physics_process(delta: float) -> void:
	# Pad triggers too (right to go, left to back up), so the stick is free to steer.
	# On a pad the triggers drive and the stick only steers: a stick pushed a little off
	# true while turning shouldn't creep the mower forward or back.
	var keys := 0.0 if Game.pad else Input.get_axis("move_back", "move_forward")
	throttle = clampf(keys + Input.get_axis("reverse", "accelerate"), -1.0, 1.0) if occupied else 0.0
	sprinting = power == "stamina" and throttle > 0.0 and fuel > 0.0 and Input.is_action_pressed("sprint")
	if _yank > 0.0:
		_yank -= delta
		_cord.queue_redraw()
	if engine_off and fuel <= 0.0:
		pass # dry: pushed along slowly, as ever, till there's petrol to start it on
	elif engine_off and sprite_kind == "petrol":
		_ripcord(delta)
	elif engine_off:
		throttle = 0.0 # sat on it, key off
	if sprite_kind == "rideon" and occupied:
		if Input.is_action_just_pressed("gear_up"):
			gear = mini(gear + 1, GEARS.size())
		if Input.is_action_just_pressed("gear_down"):
			gear = maxi(gear - 1, 1)
	if power == "stamina":
		if throttle != 0.0:
			fuel = maxf(0.0, fuel - fuel_burn * (SPRINT_BURN if sprinting else WALK_BURN) * delta)
		else:
			fuel = minf(max_fuel, fuel + regen * delta)
	elif not engine_off: # an engine that isn't going burns nothing; ticking over, a little
		fuel = maxf(0.0, fuel - fuel_burn * (1.0 if throttle != 0.0 else IDLE_BURN) * delta)
		if fuel <= 0.0: # run dry, it dies: refuelled, it wants starting again
			engine_off = true
			Sfx.play("cough")
	fuel_changed.emit(fuel / max_fuel)
	var running := fuel > 0.0 and condition > 0.0 and not engine_off

	if occupied and (running or empty_speed_scale > 0.0): # a dead ride-on won't budge
		var turn: float = turn_rate * (GEAR_TURN[gear - 1] if sprite_kind == "rideon" else 1.0)
		rotation += Input.get_axis("turn_left", "turn_right") * turn * delta

	var fwd := Vector2.RIGHT.rotated(rotation)
	var top: float = max_speed * (WALK if power == "stamina" and not sprinting else 1.0)
	if sprite_kind == "rideon":
		top = max_speed * GEARS[gear - 1]
	var target := throttle * (top if throttle > 0.0 else reverse_speed)
	if not running:
		target *= empty_speed_scale
	elif condition < 35.0:
		target *= 0.8 # sputtering
	var speed := move_toward(velocity.dot(fwd), target, (accel if throttle != 0.0 else brake) * delta)
	velocity = fwd * speed

	var before := global_position
	var v_before := velocity
	move_and_slide()
	_check_impacts(v_before)
	# Walk / wheel animation: flip frames every few pixels travelled.
	_stride += global_position.distance_to(before)
	if not occupied:
		_anim = 2
	elif _stride > 7.0 or _anim == 2:
		_stride = 0.0
		_anim = 1 - mini(_anim, 1)
	_show()
	if lawn:
		global_position = lawn.global_position + lawn.keep_in(global_position - lawn.global_position, edge_margin)
		var was := lawn.cut_fraction()
		if running or (power == "stamina" and condition > 0.0):
			lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)
		# Clippings spray off the side while it's eating long grass.
		_clippings.emitting = lawn.cut_fraction() > was
		_clippings.position = Vector2(0, -cut_radius).rotated(0.0)
	_update_sound(delta, running)
