class_name Animal
extends Area2D
## Wildlife that wanders across the lawn. Hedgehogs trundle in a straight line;
## squirrels dart and pause. A moving mower that touches one squashes it.
## Comes in from next door and wanders off there again (main._cross). Turns away
## from anything `blocked` says is solid (house, truck, trees, ponds). A stone can
## knock one out (it lies on its side, then wakes and runs) or kill it outright, which
## leaves a body, belly up, until someone moves it or mows it.

signal squashed(animal: Animal)
signal run_over(animal: Animal, mower: Node2D) ## knocked out by the blades, not splatted (main flings it clear)

@export var kind := "hedgehog"
@export var speed := 40.0
@export var radius := 9.0

var lawn_rect := Rect2()
var blocked: Callable ## (position) -> bool
var grace := 0.0 ## seconds before obstacles count (a squirrel climbing down a tree)
var heading := Vector2.RIGHT
var dead := false ## squashed: the splat is main's, this node is on its way out
var out := 0.0 ## seconds left knocked out
var immune := 0.0 ## seconds a mower can't hurt it: just knocked clear of one
var on_plot := true ## on the property, not out next door (main._cross)
var visited := true ## has been in the garden: once it wanders off out of sight, it's gone
var body := false ## killed by a stone, not the blades: intact, lying there
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
	immune = maxf(0.0, immune - delta)
	if dead or body:
		return
	if out > 0.0:
		out -= delta
		if out <= 0.0: # comes round and bolts
			heading = Vector2.RIGHT.rotated(randf() * TAU)
		queue_redraw()
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
	if not lawn_rect.grow(800.0).has_point(position): # main frees it once it's off the property out of sight (_cross)
		queue_free()
	queue_redraw()


func _on_body_entered(b: Node2D) -> void:
	if dead or not ("cut_radius" in b):
		return # only mowers squash; people on foot just step round
	if (b.velocity as Vector2).length() < 15.0:
		if out > 0.0 or body:
			return # lying there: it can't get out of the way, but a stopped mower can't hurt it
		# A stopped mower is just an obstacle: turn back the way we came.
		heading = -heading
		return
	if immune > 0.0:
		return
	if not body and randf() < b.knock_out:
		run_over.emit(self, b)
		return
	squash()


## Out cold for a few seconds, where it lies.
func stun(seconds: float) -> void:
	out = seconds
	queue_redraw()


## Dead, but in one piece.
func kill() -> void:
	body = true
	out = 0.0
	queue_redraw()


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
	if body:
		Animal.draw_body(self, kind, Vector2.ZERO)
		return
	if out > 0.0: # on its side, seeing stars
		draw_set_transform(Vector2(0, 2), PI / 2.0)
		Facing.draw(self, sheet(kind), 2, 0, 0.0)
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			var a := _t * 6.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 8.0, -12.0 + sin(a) * 2.5), 1.5, Color("f8e070"))
		return
	var frame := int(_t * (8.0 if speed > 0.0 and _pause <= 0.0 else 0.0)) % 2
	Facing.draw(self, sheet(kind), 2, frame, heading.angle())


static func sheet(of: String) -> Texture2D:
	return preload("res://art/hedgehog.png") if of.ends_with("hedgehog") else preload("res://art/squirrel.png")


## A body, belly up, drawn by whatever holds it (the lawn, your hands, the air). `base`
## is the transform the caller was already drawing with.
static func draw_body(ci: CanvasItem, of: String, at: Vector2, base := Transform2D.IDENTITY) -> void:
	ci.draw_set_transform_matrix(base * Transform2D(PI / 2.0, Vector2(1, -1), 0.0, at)) # flat on its back
	Facing.draw(ci, sheet(of), 2, 0, PI / 2.0) # facing you, upside down: feet in the air
	ci.draw_set_transform_matrix(base)
