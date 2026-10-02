extends StaticBody2D
## The player's truck: a solid obstacle, and the only fuel source. A petrol mower
## parked in the refuel zone fills up at refill_rate (glugging). A push mower's
## stamina is not fuel: only resting brings it back.

@export var refill_rate := 20.0 ## fuel per second
@export var repair_rate := 12.0 ## condition points per second

var _glug: AudioStreamPlayer
var _bay: Node2D


func _ready() -> void:
	_glug = AudioStreamPlayer.new()
	_glug.stream = preload("res://audio/glug.wav")
	_glug.volume_db = -10.0
	_glug.bus = "SFX"
	add_child(_glug)
	_bay = Node2D.new() # the refuel zone, painted on the ground like a parking bay (paint_bay)
	_bay.z_index = -1
	_bay.draw.connect(func() -> void:
		var shape: CollisionShape2D = $RefuelZone/Shape
		var size: Vector2 = (shape.shape as RectangleShape2D).size
		var r := Rect2($RefuelZone.position + shape.position - size / 2.0, size)
		_bay.draw_rect(r, Color(1.0, 0.85, 0.3, 0.1))
		_bay.draw_rect(r.grow(-1.0), Color(1.0, 0.85, 0.3, 0.45), false, 2.0))
	add_child(_bay)


## The refuel zone's been set for this kerb: paint its bay to match.
func paint_bay() -> void:
	_bay.queue_redraw()


func _physics_process(delta: float) -> void:
	var filling := false
	for body in $RefuelZone.get_overlapping_bodies():
		if body.has_method("add_fuel"):
			if body.power == "fuel":
				filling = filling or body.fuel < body.max_fuel - 0.5
				body.add_fuel(refill_rate * delta)
			if body.condition < 100.0 and body.occupied:
				body.repair(repair_rate * delta)
	if filling and not _glug.playing:
		_glug.play()
	elif not filling and _glug.playing:
		_glug.stop()
