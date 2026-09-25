# Drives the mower in the real main scene: holding forward moves it and cuts grass,
# it stays on the lawn when driven into the edge, and its camera is bounded by the lawn.
extends SceneTree

var _main: Node
var _frame := 0
var _start: Vector2


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
	elif _frame == 600:
		Input.action_release("move_forward")
		assert(mower.global_position.y < _start.y - 200.0, "mower should have driven up the lawn")
		assert(mower.global_position.y >= 0.0, "mower must stay on the lawn")
		assert(lawn.cut_fraction() > 0.01, "driving should cut grass, got %f" % lawn.cut_fraction())
		assert(_main.get_node("HUD/Percent").text != "0%", "HUD should show progress")
		print("PASS mower drive")
		quit()
	return false
