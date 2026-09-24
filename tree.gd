extends StaticBody2D
## A tree: a solid round obstacle to mow around, drawn as a canopy from above that
## casts its shadow over whatever passes by. Art comes in 26/34/42 radius sizes.

@export var radius := 34.0
@export var variant := 0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	$Shape.shape = shape
	var spr := Sprite2D.new()
	spr.texture = load("res://art/tree_%d.png" % (int(round(radius)) * 2))
	spr.hframes = 3
	spr.frame = variant % 3
	spr.offset = Vector2(2, 2) # the art pads for the shadow; centre it on the canopy
	spr.z_index = 1 # canopies overhang the mower and animals
	add_child(spr)
