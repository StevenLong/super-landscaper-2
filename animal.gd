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
	squashed.emit(self)
	queue_redraw()
	get_tree().create_timer(12.0).timeout.connect(queue_free)


func _draw() -> void:
	if dead:
		var s := preload("res://art/splat.png")
		draw_texture(s, -s.get_size() / 2.0)
		return
	var tex: Texture2D = preload("res://art/hedgehog.png") if kind == "hedgehog" else preload("res://art/squirrel.png")
	var fw := tex.get_width() / 2.0
	var frame := int(_t * (8.0 if speed > 0.0 and _pause <= 0.0 else 0.0)) % 2
	# Walking left would draw upside down once rotated; mirror vertically instead.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, -1 if heading.x < 0.0 else 1))
	draw_texture_rect_region(tex, Rect2(Vector2(-fw / 2.0, -tex.get_height() / 2.0), Vector2(fw, tex.get_height())),
		Rect2(frame * fw, 0, fw, tex.get_height()))
