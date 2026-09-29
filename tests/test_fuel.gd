# Fuel in the real main scene: a running engine burns fuel, less standing still than going;
# an empty mower is slow and cuts nothing, an empty ride-on won't budge; and parking at
# the truck refills the tank.
extends SceneTree

var _main: Node
var _mower: CharacterBody2D
var _lawn: Lawn
var _frame := 0
var _fuel0: float
var _cut0: float
var _pos0: Vector2
var _rot0: float


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_mower = _main.get_node("Mower")
		_lawn = _main.get_node("Lawn")
		_mower.global_position = Vector2(300, 560) # away from the truck, open lawn ahead
		_mower.rotation = 0.0
	elif _frame == 3:
		_fuel0 = _mower.fuel
	elif _frame == 63:
		var idle: float = _fuel0 - _mower.fuel
		assert(absf(idle - _mower.IDLE_BURN) < 0.05, "standing still, it ticks over at about %f a second, burned %f" % [_mower.IDLE_BURN, idle])
		_fuel0 = _mower.fuel
		Input.action_press("move_forward")
	elif _frame == 123:
		Input.action_release("move_forward")
		var going: float = _fuel0 - _mower.fuel
		assert(absf(going - 1.0) < 0.1, "going, it burns about 1 fuel per second, burned %f" % going)
		_mower.fuel = 0.0
	elif _frame == 183: # stopped by now
		_cut0 = _lawn.cut_fraction()
		_pos0 = _mower.global_position
		Input.action_press("move_forward")
	elif _frame == 243:
		Input.action_release("move_forward")
		var moved := _mower.global_position.distance_to(_pos0)
		assert(moved > 20.0, "an empty mower can still be pushed")
		assert(moved < _mower.max_speed * 0.5, "an empty mower should be slow, moved %f in 1s" % moved)
		assert(_lawn.cut_fraction() == _cut0, "an empty mower must not cut")
		_mower.empty_speed_scale = 0.0 # as the ride-on
	elif _frame == 273:
		_pos0 = _mower.global_position
		_rot0 = _mower.rotation
		Input.action_press("move_forward")
		Input.action_press("turn_right")
	elif _frame == 303:
		Input.action_release("move_forward")
		Input.action_release("turn_right")
		assert(_mower.global_position.distance_to(_pos0) < 0.5 and _mower.rotation == _rot0, "an empty ride-on won't budge")
		_mower.global_position = _main.truck_spot() # pulled up at the truck
	elif _frame == 483:
		assert(_mower.fuel > _mower.max_fuel - 0.1, "parking at the truck should fill the tank (the engine still burns while parked), got %f" % _mower.fuel)
		assert(_main.get_node("HUD/Fuel").value > 0.99, "HUD fuel bar should read full")
		assert(_mower.engine_off, "run dry, it died: refuelled, it wants starting again")
		print("PASS fuel")
		quit()
	return false
