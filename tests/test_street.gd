# The garden sits on a street: a garage on one side of the house, the drive from it
# down through the front hedge to the kerb where the truck is parked. You can drive
# out of the drive's mouth to the truck, but not onto the road or next door.
extends SceneTree

var m: Node
var _frame := 0
var _sides := {}


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


## A few generated jobs: the garage lands on either side, and the drive always runs
## from it to the front of the garden.
func _layouts() -> void:
	var game: Node = root.get_node("Game")
	for s in range(1, 13):
		game.current_job = game.make_job(s)
		var job: Node = load("res://main.tscn").instantiate()
		root.add_child(job)
		var house: Node2D = job.get_node("Scenery/House")
		var drive: Control = job.get_node("Driveway")
		var g: Rect2 = house.garage_rect()
		_sides[house.garage] = true
		assert(drive.position.x > g.position.x and drive.position.x + drive.size.x < g.end.x, "the drive leads up to the garage door")
		assert(drive.position.y + drive.size.y == job.lawn.size_px.y, "and runs to the front of the garden")
		assert(house.footprint().position.x >= 0.0 and house.footprint().end.x <= job.lawn.size_px.x, "house and garage fit the plot")
		job.free()
	game.current_job = {}


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_layouts()
		assert(_sides.size() == 2, "garages come on both sides across jobs")
		var h := float(m.lawn.size_px.y)
		var spot: Vector2 = m.truck_spot()
		assert(spot.y > h, "which is out past the hedge, on the pavement")
		assert(m.lawn.keep_in(spot + Vector2(0, 200), 10.0).y < h + m.BORDER + m.FOOTPATH, "the road itself is off limits")
		assert(m.lawn.keep_in(Vector2(spot.x + 300, h + 40), 10.0).y <= h, "and so is the pavement past the drive")
		assert(m._stone_hit_test(m.get_node("Truck").position) == "truck", "a stone can still dent the truck at the kerb")
	elif _frame == 6:
		assert(m.at_truck(), "the job starts pulled up at the truck")
		var spot: Vector2 = m.truck_spot()
		var h := float(m.lawn.size_px.y)
		# Drive up out of the mouth and back down to the truck.
		m.mower.global_position = Vector2(spot.x, h - 150)
		m.mower.rotation = PI / 2.0
		Input.action_press("move_forward")
	elif _frame == 150:
		Input.action_release("move_forward")
		assert(m.mower.global_position.y > float(m.lawn.size_px.y), "the mower drives out of the drive's mouth")
		assert(m.at_truck(), "to the truck")
		print("PASS street")
		quit()
	return false
