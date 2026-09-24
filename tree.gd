extends StaticBody2D
## A tree: a solid round obstacle to mow around. Placeholder art, drawn from its radius.

@export var radius := 30.0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	$Shape.shape = shape


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.3, 0.1))
	draw_circle(Vector2.ZERO, radius * 0.35, Color(0.35, 0.22, 0.1))
