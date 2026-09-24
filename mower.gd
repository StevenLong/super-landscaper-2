extends CharacterBody2D
## Arcade mower: throttle forward/back along its heading, turn in place. Faces +x
## in local space. The exports are the petrol defaults; apply_spec() swaps in a
## run's equipped mower.
##
## power "fuel": burns constantly while the engine runs; refill at the truck.
## power "stamina": a push mower. Pushing tires you; resting recovers. Exhausted,
## it crawls (but still cuts: it's your legs, not an engine).

signal fuel_changed(fraction: float)

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
@export var sprite_kind := "petrol" ## art/mower_<kind>.png, two frames

@onready var fuel := max_fuel
var fuel_used := 0.0
var throttle := 0.0
var _stride := 0.0
var _bump_cooldown := 0.0
var _low_warned := false
var _engine: AudioStreamPlayer


func _ready() -> void:
	_engine = AudioStreamPlayer.new()
	add_child(_engine)
	_apply_visual()


func _apply_visual() -> void:
	var spr: Sprite2D = $Sprite
	spr.texture = load("res://art/mower_%s.png" % sprite_kind)
	spr.hframes = 2
	_engine.stream = load("res://audio/%s.wav" % {"push": "reel", "rideon": "engine_rideon"}.get(sprite_kind, "engine_petrol"))
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
	if get_slide_collision_count() > 0 and _bump_cooldown <= 0.0 and s > 0.25:
		_bump_cooldown = 0.5
		Sfx.play("bump")


func apply_spec(spec: Dictionary) -> void:
	for k in ["power", "max_speed", "reverse_speed", "accel", "brake", "turn_rate", "cut_radius",
			"max_fuel", "fuel_burn", "regen", "empty_speed_scale"]:
		set(k, spec[k])
	sprite_kind = spec.sprite
	var shape := RectangleShape2D.new()
	shape.size = spec.body
	$Shape.shape = shape
	_apply_visual()
	fuel = max_fuel
	edge_margin = minf(edge_margin, cut_radius * 0.75)


func add_fuel(amount: float) -> void:
	var before := fuel
	fuel = minf(max_fuel, fuel + amount)
	if power == "fuel":
		fuel_used += fuel - before


func _physics_process(delta: float) -> void:
	throttle = Input.get_axis("move_back", "move_forward")
	if power == "stamina":
		if throttle != 0.0:
			fuel = maxf(0.0, fuel - fuel_burn * delta)
		else:
			fuel = minf(max_fuel, fuel + regen * delta)
	else:
		fuel = maxf(0.0, fuel - fuel_burn * delta)
	fuel_changed.emit(fuel / max_fuel)
	var running := fuel > 0.0

	rotation += Input.get_axis("turn_left", "turn_right") * turn_rate * delta

	var fwd := Vector2.RIGHT.rotated(rotation)
	var target := throttle * (max_speed if throttle > 0.0 else reverse_speed)
	if not running:
		target *= empty_speed_scale
	var speed := move_toward(velocity.dot(fwd), target, (accel if throttle != 0.0 else brake) * delta)
	velocity = fwd * speed

	var before := global_position
	move_and_slide()
	# Walk / wheel animation: flip frames every few pixels travelled.
	_stride += global_position.distance_to(before)
	if _stride > 7.0:
		_stride = 0.0
		$Sprite.frame = 1 - $Sprite.frame
	if lawn:
		var lo := lawn.global_position + Vector2(edge_margin, edge_margin)
		var hi := lawn.global_position + Vector2(lawn.size_px) - Vector2(edge_margin, edge_margin)
		global_position = global_position.clamp(lo, hi)
		if running or power == "stamina":
			lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)
	_update_sound(delta, running)
