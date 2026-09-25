# Fuel in the real main scene: the engine burns fuel constantly, an empty mower is
# slow and cuts nothing, and parking at the truck refills the tank.
extends SceneTree

var _main: Node
var _mower: CharacterBody2D
var _lawn: Lawn
var _frame := 0
var _fuel0: float
var _cut0: float
var _pos0: Vector2


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_mower = _main.get_node("Mower")
		_lawn = _main.get_node("Lawn")
		_mower.global_position = Vector2(640, 440) # away from the truck
	elif _frame == 3:
		_fuel0 = _mower.fuel
	elif _frame == 63:
		var burned: float = _fuel0 - _mower.fuel
		assert(absf(burned - 1.0) < 0.1, "should burn about 1 fuel per second, burned %f" % burned)
		_mower.fuel = 0.0
		_cut0 = _lawn.cut_fraction()
		_pos0 = _mower.global_position
		Input.action_press("move_forward")
	elif _frame == 123:
		Input.action_release("move_forward")
		var moved := _mower.global_position.distance_to(_pos0)
		assert(moved > 20.0, "an empty mower can still be pushed")
		assert(moved < _mower.max_speed * 0.5, "an empty mower should be slow, moved %f in 1s" % moved)
		assert(_lawn.cut_fraction() == _cut0, "an empty mower must not cut")
		_mower.global_position = _main.truck_spot() # pulled up at the truck
	elif _frame == 303:
		assert(_mower.fuel > _mower.max_fuel - 0.1, "parking at the truck should fill the tank (the engine still burns while parked), got %f" % _mower.fuel)
		assert(_main.get_node("HUD/Fuel").value > 0.99, "HUD fuel bar should read full")
		print("PASS fuel")
		quit()
	return false
