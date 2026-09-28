# Drives the mower in the real main scene: holding forward (key, then the pad's right
# trigger) moves it and cuts grass,
# it stays on the lawn when driven into the edge, and its camera is bounded by the lawn.
extends SceneTree

var _main: Node
var _frame := 0
var _start: Vector2
var _fuel := 0.0


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var mower: Node2D = _main.get_node("Mower")
	var lawn: Lawn = _main.get_node("Lawn")
	if _frame == 2:
		mower.global_position = Vector2(400, 650) # on the grass (it starts on the drive, facing up)
		mower.rotation = -PI / 2.0
		_start = mower.global_position
		var cam: Camera2D = mower.get_node("Camera")
		assert(cam.is_current(), "the mower camera should be the active one")
		assert(cam.limit_right > 100000 and cam.limit_bottom > 100000, "the camera never clamps: the street and next door are there to see")
		Input.action_press("move_forward")
	elif _frame == 300: # halfway, over to the pad's right trigger
		Input.action_release("move_forward")
		Input.action_press("accelerate")
	elif _frame == 600:
		Input.action_release("accelerate")
		mower._physics_process(0.0)
		assert(mower.throttle == 0.0, "let go, no throttle")
		Input.action_press("reverse")
		mower._physics_process(0.0)
		assert(mower.throttle < 0.0, "the left trigger backs up")
		Input.action_release("reverse")
		assert(mower.global_position.y < _start.y - 200.0, "mower should have driven up the lawn")
		assert(mower.global_position.y >= 0.0, "mower must stay on the lawn")
		assert(lawn.cut_fraction() > 0.01, "driving should cut grass, got %f" % lawn.cut_fraction())
		assert(_main.get_node("HUD/Percent").text != "0%", "HUD should show progress")
		# The push mower walks at 60% of its top speed; held, sprint pushes it flat out and
		# tires you faster (NOTES 108).
		mower.apply_spec(root.get_node("Game").MOWERS.push)
		mower.global_position = Vector2(400, 650)
		mower.rotation = -PI / 2.0
		mower.velocity = Vector2.ZERO
		Input.action_press("move_forward")
	elif _frame == 660:
		assert(absf(mower.velocity.length() - mower.max_speed * mower.WALK) < 2.0, "walking: %.0f" % mower.velocity.length())
		_fuel = mower.fuel
		Input.action_press("sprint")
	elif _frame == 720:
		assert(absf(mower.velocity.length() - mower.max_speed) < 2.0 and mower.sprinting, "sprinting, flat out: %.0f" % mower.velocity.length())
		assert(_fuel - mower.fuel > 1.4 * mower.fuel_burn, "and tiring fast: %.2f in a second" % (_fuel - mower.fuel))
		Input.action_release("sprint")
		Input.action_release("move_forward")
		print("PASS mower drive")
		quit()
	return false
