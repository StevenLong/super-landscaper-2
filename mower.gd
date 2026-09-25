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
@export var sprite_kind := "petrol" ## art/mower_<kind>.png: two frames of motion, then empty
@export var toughness := 1.0 ## damage taken is divided by this

@onready var fuel := max_fuel
var fuel_used := 0.0
var condition := 100.0 ## 0 = broken: crawls and cuts nothing until repaired at the truck
var repaired := 0.0 ## points repaired this job (costs money)
var occupied := true ## false while the player is off on foot
var throttle := 0.0
var _stride := 0.0
var _bump_cooldown := 0.0
var _was_touching := false
var _low_warned := false
var _engine: AudioStreamPlayer
var _clippings: CPUParticles2D


func _ready() -> void:
	_engine = AudioStreamPlayer.new()
	_engine.bus = "SFX"
	add_child(_engine)
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
	_apply_visual()


func _apply_visual() -> void:
	var spr: Sprite2D = $Sprite
	spr.texture = load("res://art/mower_%s.png" % sprite_kind)
	spr.hframes = 3 # two frames of motion, then empty
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
	for i in get_slide_collision_count():
		impact = maxf(impact, -velocity_before.dot(get_slide_collision(i).get_normal()))
	if impact > 60.0 and _bump_cooldown <= 0.0:
		_bump_cooldown = 0.4
		Sfx.play("bump")
		damage(impact / 25.0)


func apply_spec(spec: Dictionary) -> void:
	for k in ["power", "max_speed", "reverse_speed", "accel", "brake", "turn_rate", "cut_radius",
			"max_fuel", "fuel_burn", "regen", "empty_speed_scale", "toughness"]:
		set(k, spec[k])
	sprite_kind = spec.sprite
	var shape := RectangleShape2D.new()
	shape.size = spec.body
	$Shape.shape = shape
	_apply_visual()
	fuel = max_fuel
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
	throttle = Input.get_axis("move_back", "move_forward") if occupied else 0.0
	if power == "stamina":
		if throttle != 0.0:
			fuel = maxf(0.0, fuel - fuel_burn * delta)
		else:
			fuel = minf(max_fuel, fuel + regen * delta)
	else:
		fuel = maxf(0.0, fuel - fuel_burn * delta)
	fuel_changed.emit(fuel / max_fuel)
	var running := fuel > 0.0 and condition > 0.0

	if occupied:
		rotation += Input.get_axis("turn_left", "turn_right") * turn_rate * delta

	var fwd := Vector2.RIGHT.rotated(rotation)
	var target := throttle * (max_speed if throttle > 0.0 else reverse_speed)
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
		$Sprite.frame = 2
	elif _stride > 7.0 or $Sprite.frame == 2:
		_stride = 0.0
		$Sprite.frame = 1 - mini($Sprite.frame, 1)
	if lawn:
		global_position = lawn.global_position + lawn.keep_in(global_position - lawn.global_position, edge_margin)
		var was := lawn.cut_fraction()
		if running or (power == "stamina" and condition > 0.0):
			lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)
		# Clippings spray off the side while it's eating long grass.
		_clippings.emitting = lawn.cut_fraction() > was
		_clippings.position = Vector2(0, -cut_radius).rotated(0.0)
	_update_sound(delta, running)
