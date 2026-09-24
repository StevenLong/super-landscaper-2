extends CharacterBody2D
## Arcade mower: throttle forward/back along its heading, turn in place.
## Faces +x in local space. Tuning values are exported for per-tier variation later.

@export var lawn: Lawn
@export var max_speed := 220.0
@export var reverse_speed := 110.0
@export var accel := 600.0
@export var brake := 900.0
@export var turn_rate := 3.0 ## radians per second
@export var cut_radius := 16.0
@export var edge_margin := 18.0


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("move_back", "move_forward")
	rotation += Input.get_axis("turn_left", "turn_right") * turn_rate * delta

	var fwd := Vector2.RIGHT.rotated(rotation)
	var target := throttle * (max_speed if throttle > 0.0 else reverse_speed)
	var speed := move_toward(velocity.dot(fwd), target, (accel if throttle != 0.0 else brake) * delta)
	velocity = fwd * speed

	var before := global_position
	move_and_slide()
	if lawn:
		var lo := lawn.global_position + Vector2(edge_margin, edge_margin)
		var hi := lawn.global_position + Vector2(lawn.size_px) - Vector2(edge_margin, edge_margin)
		global_position = global_position.clamp(lo, hi)
		lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)
