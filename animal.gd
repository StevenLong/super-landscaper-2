class_name Animal
extends Area2D
## Wildlife that wanders across the lawn. Hedgehogs trundle in a straight line;
## squirrels dart and pause. A moving mower that touches one squashes it.
## Leaves the lawn (and frees itself) once it walks off the far side.

signal squashed(animal: Animal)

@export var kind := "hedgehog"
@export var speed := 40.0
@export var radius := 9.0

var lawn_rect := Rect2()
var heading := Vector2.RIGHT
var dead := false
var _pause := 0.0
var _dart := 0.0
var _t := 0.0


func _ready() -> void:
	if kind == "squirrel":
		speed = 110.0
		radius = 7.0
	var shape := CircleShape2D.new()
	shape.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	if dead:
		return
	if kind == "squirrel":
		if _pause > 0.0:
			_pause -= delta
			queue_redraw()
			return
		_dart -= delta
		if _dart <= 0.0:
			_dart = randf_range(0.4, 1.2)
			_pause = randf_range(0.2, 0.9)
			heading = heading.rotated(randf_range(-0.9, 0.9))
	position += heading * speed * delta
	rotation = heading.angle()
	if not lawn_rect.grow(40.0).has_point(position):
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if dead or not ("velocity" in body):
		return
	if (body.velocity as Vector2).length() < 15.0:
		# A stopped mower is just an obstacle: turn back the way we came.
		heading = -heading
		return
	dead = true
	set_deferred("monitoring", false)
	rotation = 0.0
	z_index = -1
	squashed.emit(self)
	queue_redraw()
	get_tree().create_timer(12.0).timeout.connect(queue_free)


func _draw() -> void:
	if dead:
		draw_circle(Vector2.ZERO, radius * 1.4, Color(0.45, 0.08, 0.08, 0.8))
		draw_circle(Vector2(3, -2), radius * 0.6, Color(0.35, 0.25, 0.18))
		return
	var bob := sin(_t * 14.0) * 1.0
	if kind == "hedgehog":
		draw_circle(Vector2(0, bob * 0.3), radius, Color(0.36, 0.26, 0.18))
		draw_circle(Vector2(radius * 0.8, 0), radius * 0.45, Color(0.85, 0.7, 0.55))
	else:
		draw_circle(Vector2(0, bob * 0.3), radius, Color(0.62, 0.35, 0.15))
		draw_circle(Vector2(-radius * 1.2, 0), radius * 0.8, Color(0.7, 0.42, 0.2))
