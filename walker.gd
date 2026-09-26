extends CharacterBody2D
## The player on foot. Direct 8-way walking. Can carry one thing at a time: a
## stone off the lawn, or the fuel can from the truck to the mower.

@export var speed := 140.0

var carrying := "" ## "", "stone" or "jerrycan"
var keep_in := func(p: Vector2) -> Vector2: return p ## main: the garden, you don't wander off the property
var _stride := 0.0
var _frame := 0


func is_walker() -> bool:
	return true


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	cs.shape = shape
	add_child(cs)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("turn_left", "turn_right", "move_forward", "move_back")
	velocity = dir * speed * (0.8 if carrying != "" else 1.0)
	if dir != Vector2.ZERO and not is_equal_approx(rotation, dir.angle()):
		rotation = dir.angle()
		queue_redraw() # the cached drawing is counter-rotated for the old heading
	var before := global_position
	move_and_slide()
	global_position = keep_in.call(global_position)
	_stride += global_position.distance_to(before)
	if _stride > 9.0:
		_stride = 0.0
		_frame = 1 - _frame
		queue_redraw()


## Drawn upright whatever way the body faces: rotation picks the art's facing row.
## A carried thing is held out in front, so it's behind you while you walk away.
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var held := Vector2(10, 0).rotated(rotation) * Vector2(1.0, 0.6) + Vector2(0, -12)
	var away := sin(rotation) < -0.1
	if away:
		_draw_held(held)
	Facing.draw(self, preload("res://art/walker.png"), 2, _frame, rotation)
	if not away:
		_draw_held(held)


func _draw_held(at: Vector2) -> void:
	if carrying != "":
		var c: Texture2D = preload("res://art/stone.png") if carrying == "stone" else preload("res://art/jerrycan.png")
		draw_texture(c, at - c.get_size() / 2.0)
