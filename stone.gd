class_name Stone
extends Area2D
## A stone lying on the lawn. Mow over it and it damages the mower and, more often
## than not, gets flung. Or get off and carry it away.

signal mowed_over(stone: Stone, mower: Node2D)

const LAUNCH_CHANCE := 0.7


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	cs.shape = shape
	add_child(cs)
	body_entered.connect(func(b: Node2D) -> void:
		if "cut_radius" in b and (b.velocity as Vector2).length() > 15.0:
			mowed_over.emit(self, b))


func _draw() -> void:
	var t := preload("res://art/stone.png")
	draw_texture(t, -t.get_size() / 2.0)
