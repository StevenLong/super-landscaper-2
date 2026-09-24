extends StaticBody2D
## The player's truck: a solid obstacle, and the only fuel source. A petrol mower
## parked in the refuel zone fills up at refill_rate (glugging). A push mower's
## stamina is not fuel: only resting brings it back.

@export var refill_rate := 20.0 ## fuel per second
@export var repair_rate := 12.0 ## condition points per second

var _glug: AudioStreamPlayer


func _ready() -> void:
	_glug = AudioStreamPlayer.new()
	_glug.stream = preload("res://audio/glug.wav")
	_glug.volume_db = -10.0
	_glug.bus = "SFX"
	add_child(_glug)


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
