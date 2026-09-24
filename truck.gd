extends StaticBody2D
## The player's truck: a solid obstacle, and the only fuel source. Anything with
## add_fuel() parked in the refuel zone fills up at refill_rate.

@export var refill_rate := 20.0 ## fuel per second


func _physics_process(delta: float) -> void:
	for body in $RefuelZone.get_overlapping_bodies():
		if body.has_method("add_fuel"):
			body.add_fuel(refill_rate * delta)
