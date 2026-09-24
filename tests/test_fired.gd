# Getting fired doesn't end the job: no pay and the rep hit are booked, you stay in the
# garden, spite costs more rep, and you leave only by driving off from the truck.
extends SceneTree

var _main: Node
var _bed: Node2D
var _frame := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_best.cfg"
	_main = load("res://main.tscn").instantiate() # the default job is the gardener: 3 flowers and you're out
	_main.hedgehog_every = 9999.0
	_main.squirrel_every = 9999.0
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		for c in _main.get_node("Scenery").get_children():
			if c.has_method("flattened_count"):
				_bed = c
		_main.mower.global_position = Vector2(640, 400) # away from the truck
		_bed._trample(Vector2(8, 8), 20.0) # a few flowers: enough to be fired
	elif _frame == 4:
		assert(_main.customer.fired, "trampling the gardener's flowers gets you fired")
		assert(_main.settled.get("outcome") == "fired", "the firing is booked")
		assert(not _main.over and not _main.hud.is_open() and not paused, "but you stay in the garden")
		assert(_main._hint().begins_with("Fired"), "and the hint says how to leave")
		assert(_main.mischief == 0.0, "the flowers that got you fired aren't mischief")
		_bed._trample(Vector2(_bed.size.x - 8, _bed.size.y - 8), 30.0) # spite
	elif _frame == 6:
		assert(_main.mischief > 0.0, "flattening the rest after being fired is mischief")
		_main.open_truck_menu()
		assert(_main.hud.is_open(), "the truck menu opens")
		_main._on_choice("drive_off")
		var r: Dictionary = root.get_node("Game").last_result
		assert(_main.over and r.outcome == "fired" and r.paid == 0, "driving off ends it, unpaid")
		assert(r.rep < -18.0 and r.mischief > 0.0, "and the spite cost extra rep, rep %f" % r.rep)
		print("PASS fired")
		quit()
	return false
