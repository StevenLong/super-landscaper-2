extends CharacterBody2D
## The player on foot. Direct 8-way walking. Can carry one thing at a time: a
## stone off the lawn, or the fuel can from the truck to the mower.

@export var speed := 140.0

var carrying := "" ## "", "stone" or "jerrycan"
var bounds := Rect2(-1e9, -1e9, 2e9, 2e9) ## the garden; you don't wander off the property
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
	if dir != Vector2.ZERO:
		rotation = dir.angle()
	var before := global_position
	move_and_slide()
	global_position = global_position.clamp(bounds.position, bounds.end)
	_stride += global_position.distance_to(before)
	if _stride > 9.0:
		_stride = 0.0
		_frame = 1 - _frame
		queue_redraw()


func _draw() -> void:
	var t := preload("res://art/walker.png")
	var fw := t.get_width() / 2.0
	draw_texture_rect_region(t, Rect2(-fw / 2.0, -t.get_height() / 2.0, fw, t.get_height()), Rect2(_frame * fw, 0, fw, t.get_height()))
	if carrying != "":
		var c: Texture2D = preload("res://art/stone.png") if carrying == "stone" else preload("res://art/jerrycan.png")
		draw_set_transform(Vector2(10, 0), -rotation, Vector2.ONE)
		draw_texture(c, -c.get_size() / 2.0)
