extends StaticBody2D
## The player's truck: a solid obstacle, and the only fuel source. Anything with
## add_fuel() parked in the refuel zone fills up at refill_rate (glugging).

@export var refill_rate := 20.0 ## fuel per second

var _glug: AudioStreamPlayer


func _ready() -> void:
	_glug = AudioStreamPlayer.new()
	_glug.stream = preload("res://audio/glug.wav")
	_glug.volume_db = -10.0
	add_child(_glug)


func _physics_process(delta: float) -> void:
	var filling := false
	for body in $RefuelZone.get_overlapping_bodies():
		if body.has_method("add_fuel"):
			filling = filling or (body.power == "fuel" and body.fuel < body.max_fuel - 0.5)
			body.add_fuel(refill_rate * delta)
	if filling and not _glug.playing:
		_glug.play()
	elif not filling and _glug.playing:
		_glug.stop()
