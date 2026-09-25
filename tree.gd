extends StaticBody2D
## A tree, seen 3/4 like the house: a solid trunk at its base (the only part you
## bump into) under a canopy held up above it. The canopy fades while the player is
## near or behind it, so nothing hides there. Canopy art comes in 26/34/42/50 radius.

@export var canopy := 34.0 ## canopy radius, picks the art
@export var variant := 0

var radius := 8.0 ## the trunk: solid, and all that critters, stones and the mower meet
var near := false: ## set by main while the player is close; fades the canopy
	set(v):
		if v != near:
			near = v
			var tw := create_tween()
			tw.tween_property(_crown, "modulate:a", 0.35 if v else 1.0, 0.2)

var _crown: Sprite2D


func _ready() -> void:
	radius = roundf(canopy * [0.2, 0.26, 0.32][variant % 3]) # varied trunks
	var shape := CircleShape2D.new()
	shape.radius = radius
	$Shape.shape = shape
	_crown = Sprite2D.new()
	_crown.texture = load("res://art/tree_%d.png" % (int(round(canopy)) * 2))
	_crown.hframes = 3
	_crown.frame = variant % 3
	_crown.position = crown_centre()
	_crown.offset = Vector2(2, 2) # the art pads for the shadow; centre it on the canopy
	_crown.z_index = 1 # canopies overhang the mower and animals
	add_child(_crown)


## Where the canopy sits, relative to the trunk's base: high enough to show some trunk.
func crown_centre() -> Vector2:
	return Vector2(0, -canopy - radius * 1.6 - 6.0)


## The canopy's footprint in the world, for fading it.
func crown_rect() -> Rect2:
	return Rect2(position + crown_centre() - Vector2(canopy, canopy), Vector2(canopy, canopy) * 2.0)


func _draw() -> void:
	var bark := Color("6a4428")
	var dark := Color("3a2414")
	var top := crown_centre().y + canopy * 0.5
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, radius + 6.0, Color(0.05, 0.12, 0.05, 0.45)) # shadow on the grass
	draw_circle(Vector2.ZERO, radius + 2.0, dark) # the root flare
	draw_set_transform(Vector2.ZERO)
	var trunk := Rect2(-radius, top, radius * 2.0, -top)
	draw_rect(trunk.grow(1.0), dark)
	draw_rect(trunk, bark)
	draw_rect(Rect2(-radius + 2.0, top, maxf(2.0, radius * 0.5), -top - 2.0), Color("8a6038")) # lit side
	draw_rect(Rect2(radius * 0.4, top, 2.0, -top - 2.0), Color("50321c")) # a groove of bark
