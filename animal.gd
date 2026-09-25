class_name Animal
extends Area2D
## Wildlife that wanders across the lawn. Hedgehogs trundle in a straight line;
## squirrels dart and pause. A moving mower that touches one squashes it.
## Leaves the lawn (and frees itself) once it walks off the far side. Turns away
## from anything `blocked` says is solid (house, truck, trees, ponds).

signal squashed(animal: Animal)

@export var kind := "hedgehog"
@export var speed := 40.0
@export var radius := 9.0

var lawn_rect := Rect2()
var blocked: Callable ## (position) -> bool
var grace := 0.0 ## seconds before obstacles count (a squirrel climbing down a tree)
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
	var next := position + heading * speed * delta
	if grace > 0.0:
		grace -= delta
	elif blocked.is_valid() and blocked.call(next):
		# Something solid ahead: turn well away and try again next frame.
		heading = heading.rotated(randf_range(1.6, 2.6) * (1.0 if randf() < 0.5 else -1.0))
		queue_redraw()
		return
	position = next
	if not lawn_rect.grow(30.0).has_point(position):
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if dead or not ("cut_radius" in body):
		return # only mowers squash; people on foot just step round
	if (body.velocity as Vector2).length() < 15.0:
		# A stopped mower is just an obstacle: turn back the way we came.
		heading = -heading
		return
	squash()


func squash() -> void:
	if dead:
		return
	dead = true
	set_deferred("monitoring", false)
	squashed.emit(self)
	queue_redraw()
	get_tree().create_timer(12.0).timeout.connect(queue_free)


func _draw() -> void:
	if dead:
		return # main.gd's Decals draw the splat, which outlasts this node
	var tex: Texture2D = preload("res://art/hedgehog.png") if kind == "hedgehog" else preload("res://art/squirrel.png")
	var frame := int(_t * (8.0 if speed > 0.0 and _pause <= 0.0 else 0.0)) % 2
	Facing.draw(self, tex, 2, frame, heading.angle())
