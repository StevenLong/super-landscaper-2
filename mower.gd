extends CharacterBody2D
## Arcade petrol mower: throttle forward/back along its heading, turn in place.
## Burns fuel constantly while the engine runs. With an empty tank it can only be
## pushed slowly and does not cut. Faces +x in local space. Tuning values are
## exported for per-tier variation later.

signal fuel_changed(fraction: float)

@export var lawn: Lawn
@export var max_speed := 220.0
@export var reverse_speed := 110.0
@export var accel := 600.0
@export var brake := 900.0
@export var turn_rate := 3.0 ## radians per second
@export var cut_radius := 16.0
@export var edge_margin := 12.0 ## small enough that cut_radius reaches the lawn edge AND corners
@export var max_fuel := 40.0 ## seconds of running
@export var fuel_burn := 1.0 ## per second, engine always on
@export var empty_speed_scale := 0.35 ## pushing a dead mower

@onready var fuel := max_fuel


func add_fuel(amount: float) -> void:
	fuel = minf(max_fuel, fuel + amount)


func _physics_process(delta: float) -> void:
	fuel = maxf(0.0, fuel - fuel_burn * delta)
	fuel_changed.emit(fuel / max_fuel)
	var running := fuel > 0.0

	var throttle := Input.get_axis("move_back", "move_forward")
	rotation += Input.get_axis("turn_left", "turn_right") * turn_rate * delta

	var fwd := Vector2.RIGHT.rotated(rotation)
	var target := throttle * (max_speed if throttle > 0.0 else reverse_speed)
	if not running:
		target *= empty_speed_scale
	var speed := move_toward(velocity.dot(fwd), target, (accel if throttle != 0.0 else brake) * delta)
	velocity = fwd * speed

	var before := global_position
	move_and_slide()
	if lawn:
		var lo := lawn.global_position + Vector2(edge_margin, edge_margin)
		var hi := lawn.global_position + Vector2(lawn.size_px) - Vector2(edge_margin, edge_margin)
		global_position = global_position.clamp(lo, hi)
		if running:
			lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)
