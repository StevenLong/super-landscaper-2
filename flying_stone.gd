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
var out := 0.0 ## a critter knocked out: seconds it has left out cold, carried through the flight
var thrown := false ## by hand, on purpose: what it hits can be a crime (a flung one is an accident)
var seen := false ## a body the customer has already seen (Animal.seen), carried through the flight
var throw_seen := false ## the customer watched it leave your hand (seeing that is enough to react to an eviction)
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


## One step of a flight at ground p, height h, rising rise: [p, h, rise, what it hit] after
## delta. What it hit is test's answer, or "ground" on touching down (p moved back to
## where it did). Throws and their aiming line (trace) both step through here.
static func step(p: Vector2, h: float, rise: float, vel: Vector2, delta: float, test: Callable) -> Array:
	p += vel * delta
	h += rise * delta - 0.5 * GRAVITY * delta * delta
	rise -= GRAVITY * delta
	var hit: String = test.call(p, maxf(h, 0.0), rise < 0.0) if test.is_valid() else ""
	if hit == "" and h <= 0.0:
		p -= vel * (-h / maxf(-rise, 1.0))
		h = 0.0
		hit = "ground"
	return [p, h, rise, hit]


## A whole flight, if nothing moves meanwhile: [each step's (x, y, height), what it hits].
static func trace(p: Vector2, vel: Vector2, h: float, rise: float, test: Callable, delta: float) -> Array:
	var pts := PackedVector3Array([Vector3(p.x, p.y, h)])
	for i in 900:
		var s := step(p, h, rise, vel, delta, test)
		p = s[0]
		h = s[1]
		rise = s[2]
		pts.append(Vector3(p.x, p.y, h))
		if s[3] != "":
			return [pts, s[3]]
	return [pts, "ground"]


func _physics_process(delta: float) -> void:
	_age += delta
	var s := step(position, z, vz, velocity, delta, hit_test)
	position = s[0]
	z = s[1]
	vz = s[2]
	if s[3] != "":
		landed.emit(self, "" if s[3] == "ground" else s[3])
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
