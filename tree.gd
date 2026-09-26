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
	add_child(_crown)


## Knocked by a stone: the canopy sways side to side and settles.
func shake() -> void:
	var tw := create_tween()
	for x in [4.0, -3.0, 2.0, -1.0, 0.0]:
		tw.tween_property(_crown, "position:x", crown_centre().x + x, 0.07)


## Where the canopy sits, relative to the trunk's base: high enough to show some trunk.
func crown_centre() -> Vector2:
	return Vector2(0, -canopy - radius * 1.6 - 6.0)


## The canopy's footprint in the world, for fading it.
func crown_rect() -> Rect2:
	return Rect2(position + crown_centre() - Vector2(canopy, canopy), Vector2(canopy, canopy) * 2.0)


const BARK := [Color("2e1c10"), Color("4a2e18"), Color("6a4428"), Color("8a6038"), Color("a87c4c")]


## The trunk, drawn a row at a time: round (lit from the left), tapering a little,
## flaring into roots at the foot, with grooves of bark. The canopy hides its top.
func _draw() -> void:
	var top := crown_centre().y + canopy * 0.5
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, canopy * 0.8, Color(0.05, 0.12, 0.05, 0.35)) # the canopy's shadow, sun overhead
	draw_set_transform(Vector2.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 31 + int(canopy)
	var grooves: Array[Vector3] = [] # x across (-1..1), from height, to height
	for i in 2 + int(radius / 5.0):
		var a := rng.randf_range(0.0, -top * 0.6)
		grooves.append(Vector3(rng.randf_range(-0.6, 0.6), a, a + rng.randf_range(6.0, -top * 0.6)))
	# (edge of the band across the trunk, colour): rim, highlight, mid, shade, rim
	var bands := [[-0.7, BARK[2]], [-0.25, BARK[4]], [0.2, BARK[3]], [0.7, BARK[2]], [1.0, BARK[1]]]
	# The foot is round, not a flat line: the near half of the trunk's footprint ellipse
	# (squashed like the ground), over a dark contact shadow.
	var foot := radius + 4.0
	draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, foot + 4.0, Color(0.03, 0.08, 0.03, 0.45))
	draw_set_transform(Vector2.ZERO)
	for xi in range(-int(foot), int(foot) + 1):
		var depth := foot * 0.4 * sqrt(maxf(0.0, 1.0 - pow(xi / foot, 2.0)))
		var col: Color = bands[-1][1]
		for b: Array in bands:
			if xi <= foot * b[0]:
				col = b[1]
				break
		draw_rect(Rect2(xi, -1.0, 1.0, depth + 1.0), col.darkened(0.15)) # the underside's in shade
		draw_rect(Rect2(xi, roundf(depth), 1.0, 1.0), BARK[0])
	for h in int(-top):
		var hw := radius * (1.0 - 0.12 * h / -top) + 4.0 * pow(maxf(0.0, 1.0 - h / 7.0), 2.0)
		var y := -1.0 - h
		draw_rect(Rect2(-hw - 1.0, y, hw * 2.0 + 2.0, 1.0), BARK[0]) # outline
		var from := -hw
		for b: Array in bands:
			var to: float = hw * b[0]
			draw_rect(Rect2(from, y, to - from, 1.0), b[1])
			from = to
		for g in grooves:
			if h >= g.y and h <= g.z:
				draw_rect(Rect2(roundf(g.x * hw), y, 1.0, 1.0), BARK[1])
