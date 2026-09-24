class_name Dog
extends Area2D
## The customer's dog, loose on the lawn. Bounds about at random. A moving mower
## bowls it over (it yelps and limps home). On foot, walk into it and it follows
## you; bring it back to its owner.

signal bowled(dog: Dog)
signal home(dog: Dog)

var lawn_rect := Rect2()
var home_point := Vector2.ZERO
var following: Node2D = null
var heading := Vector2.RIGHT
var _dash := 0.0
var _t := 0.0
var _limping := false


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	var speed := 0.0
	if _limping or following:
		var goal := home_point if _limping else following.global_position
		var to := goal - global_position
		if _limping and to.length() < 12.0:
			queue_free()
			return
		if following and global_position.distance_to(home_point) < 60.0:
			home.emit(self)
			queue_free()
			return
		if to.length() > (4.0 if _limping else 28.0):
			heading = to.normalized()
			speed = 60.0 if _limping else 150.0
	else:
		_dash -= delta
		if _dash <= 0.0:
			_dash = randf_range(0.5, 1.6)
			heading = Vector2.RIGHT.rotated(randf() * TAU)
		speed = 120.0 if fmod(_t, 2.0) < 1.4 else 0.0
	position += heading * speed * delta
	if not _limping:
		position = position.clamp(lawn_rect.position + Vector2(10, 10), lawn_rect.end - Vector2(10, 10))
	queue_redraw()


func bowl() -> void:
	if _limping:
		return
	_limping = true
	following = null
	bowled.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if _limping:
		return
	if "cut_radius" in body:
		if (body.velocity as Vector2).length() > 15.0:
			bowl()
	elif body.has_method("is_walker"):
		following = body


func _draw() -> void:
	var t := preload("res://art/dog.png")
	var fw := t.get_width() / 2.0
	var frame := int(_t * 9.0) % 2
	var flip := -1.0 if heading.x < 0.0 else 1.0
	var hop := -absf(sin(_t * 12.0)) * 3.0
	draw_set_transform(Vector2(0, hop), 0.0, Vector2(flip, 1))
	draw_texture_rect_region(t, Rect2(-fw / 2.0, -t.get_height() / 2.0, fw, t.get_height()), Rect2(frame * fw, 0, fw, t.get_height()))
	if _limping:
		draw_set_transform(Vector2.ZERO)
		for i in 3:
			var a := _t * 5.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 10.0, -14.0 + sin(a) * 3.0), 1.5, Color("f8e070"))
