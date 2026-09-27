class_name FlyingStone
extends Node2D
## Something in flight: along the ground at a steady speed while its height rises and
## falls under gravity, drawn that high above its shadow. Each frame it asks hit_test (a
## Callable taking the ground position, the height and whether it's falling, returning a
## target name, or "") whether it struck something; on impact or touching down it reports
## via `landed` with what it hit ("" for plain ground).

signal landed(stone: FlyingStone, target: String)

const GRAVITY := 600.0 ## px/s/s: snappy, a full lob is about a second

var velocity := Vector2.ZERO ## along the ground
var z := 0.0 ## height above the ground
var vz := 0.0 ## rising (+) or falling (-)
var kind := "stone" ## what's flying (Stone.KINDS): it lands as one
var thrown := false ## by hand, on purpose: what it hits can be a crime (a flung one is an accident)
var hit_test: Callable
var _age := 0.0


## Off from `from`, `z0` up, at `speed` along dir tilted `pitch` radians above the ground.
func launch(from: Vector2, dir: Vector2, speed: float, pitch: float, z0: float, test: Callable) -> void:
	position = from
	velocity = dir.normalized() * speed * cos(pitch)
	vz = speed * sin(pitch)
	z = z0
	hit_test = test
	z_index = 2


## How far along the ground a flight like this comes down, if nothing's in the way.
static func reach(speed: float, pitch: float, z0: float) -> float:
	var up := speed * sin(pitch)
	return speed * cos(pitch) * (up + sqrt(up * up + 2.0 * GRAVITY * z0)) / GRAVITY


## Where this one comes down, if nothing's in the way.
func landing() -> Vector2:
	return position + velocity * (vz + sqrt(vz * vz + 2.0 * GRAVITY * maxf(z, 0.0))) / GRAVITY


func _physics_process(delta: float) -> void:
	_age += delta
	position += velocity * delta
	z += vz * delta - 0.5 * GRAVITY * delta * delta
	vz -= GRAVITY * delta
	var hit: String = hit_test.call(position, maxf(z, 0.0), vz < 0.0) if hit_test.is_valid() else ""
	if hit != "" or z <= 0.0:
		if hit == "": # back to where it actually touched down
			position -= velocity * (-z / maxf(-vz, 1.0))
			z = 0.0
		landed.emit(self, hit)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := Stone.texture(kind)
	var lift := Vector2(0, -z)
	if kind in ["dog", "hedgehog", "squirrel"]: # a live animal, tumbling
		draw_circle(Vector2(0, 2), 6.0, Color(0, 0, 0, 0.35))
		Facing.draw(self, t, 2, 0, velocity.angle() + _age * 12.0, lift)
		return
	if kind.begins_with("body_"):
		draw_circle(Vector2(0, 2), 6.0, Color(0, 0, 0, 0.35))
		Animal.draw_body(self, kind, lift)
		return
	draw_circle(Vector2(0, 2), 4.0, Color(0, 0, 0, 0.35))
	draw_texture(t, -t.get_size() / 2.0 + lift)
