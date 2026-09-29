class_name Robot
extends CharacterBody2D
## The robot mower (design doc, Mowers and Equipment): set down, it mows on its own,
## slowly and badly: straight until it bumps something solid or the lawn's edge, then off
## a random way. It turns back at a bed's edge (the boundary wire). Stones and critters
## are its problem, and so yours: to them it's a mower (cut_radius, velocity, knock_out).

const SPEED := 55.0

var cut_radius := 12.0
var knock_out := 0.5 ## the share of critters its blades only knock out (Animal)
var body := Vector2(22, 18) ## its size, as a mower's (main flings a knocked-out critter clear of it)
var lawn: Lawn
var beds: Array = [] ## the flowerbeds' _inside, [Callable]: its boundary wire
var heading := Vector2.RIGHT


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body
	cs.shape = shape
	add_child(cs)


## Blades don't mind stones (main calls this on anything that mows one).
func damage(_amount: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	var before := global_position
	var ahead := global_position + heading * (SPEED * delta + cut_radius)
	if not Rect2(Vector2.ZERO, lawn.size_px).grow(-cut_radius).has_point(ahead - lawn.global_position) \
			or beds.any(func(inside: Callable) -> bool: return inside.call(ahead)):
		_turn()
		return
	velocity = heading * SPEED
	rotation = heading.angle()
	if move_and_collide(velocity * delta):
		_turn()
	lawn.cut_segment(before - lawn.global_position, global_position - lawn.global_position, cut_radius)


## Off a random way, not straight back into what it hit.
func _turn() -> void:
	heading = heading.rotated(randf_range(PI * 0.5, PI * 1.5))
	velocity = Vector2.ZERO


func _draw() -> void:
	draw(self, Vector2.ZERO)


## A squat grey shell with a green lid and a light: drawn on the lawn and in your hands.
static func draw(on: CanvasItem, at: Vector2) -> void:
	on.draw_rect(Rect2(at - Vector2(11, 9), Vector2(22, 18)), Color("5a5e66"))
	on.draw_rect(Rect2(at - Vector2(9, 7), Vector2(18, 12)), Color("5e9e4a"))
	on.draw_circle(at + Vector2(6, 0), 2.0, Color("f8d048"))
