# The robot mower (design doc, Mowers and Equipment): bought as many as you like, packed
# 2 x 2; at the job taken off the truck, set down, it mows on its own inside the lawn,
# stones and critters its problem and so yours; picked up again; left on the lawn when
# you flee the police, it's gone.
extends SceneTree

var g: Node
var m: Node
var _frame := 0
var _step := 0
var _cut := 0.0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 1000
	for i in 3:
		assert(g.buy("robot"), "robots on sale")
	assert(g.robots == 3 and g.packed_count("robot") == 2 and g.unpacked().count("robot") == 1, "two fit the bed, one stays home")
	g.sell("robot")
	assert(g.robots == 2 and g.packed_count("robot") == 2, "selling the one at home leaves the packed pair")
	g.sell("robot")
	assert(g.robots == 1 and g.packed_count("robot") == 1, "then one off the truck")
	g.buy("robot")
	g.calendar[g.day] = g.make_job(3)
	g.start_job()
	change_scene_to_file("res://main.tscn")


## A spot with open lawn for 160 px to its right: nothing in the way, nothing excluded.
func _clear_strip() -> Vector2:
	for y in range(80, m.lawn.size_px.y - 80, 20):
		for x in range(80, m.lawn.size_px.x - 240, 20):
			var ok := true
			for d in range(-30, 161, 4):
				for dy: int in [-14, 0, 14]:
					ok = ok and m.lawn._cell(Vector2(x + d, y + dy)) == Lawn.UNCUT
			if ok:
				return Vector2(x, y) + m.lawn.global_position
	assert(false, "no open strip of lawn")
	return Vector2.ZERO


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	match _step:
		0:
			m = current_scene
			m.hedgehog_every = 9999.0
			m.squirrel_every = 9999.0
			m._on_choice("start")
			assert(m.robots_left == 2, "two robots on the truck")
			m.hop_off()
			m.walker.global_position = m.get_node("Truck").position + Vector2(0, -60)
			m.open_truck_menu()
			m._on_choice("robot")
			assert(m.robots_left == 1 and m.walker.carrying == "robot", "one off the truck, in your hands")
			m.walker.global_position = _clear_strip() - Vector2(20, 0) # it's set down 20 px ahead
		1:
			m.walker.rotation = 0.0 # facing right, along the strip
			m.interact() # set it going
			assert(m.robots.size() == 1 and m.walker.carrying == "", "set down")
			_cut = m.lawn.cut_fraction()
			var r: Robot = m.robots[0]
			r.heading = Vector2.RIGHT
			m.add_stone(r.global_position + Vector2(40, 0)) # right in its way
		8:
			var r: Robot = m.robots[0]
			assert(m.lawn.cut_fraction() > _cut, "it mows by itself")
			assert(Rect2(Vector2.ZERO, m.lawn.size_px).has_point(r.global_position - m.lawn.global_position), "and stays on the lawn")
			assert(m.tally.get("stones_mowed", 0) == 1, "the stone in its way went through its blades: yours")
			# Pick it up again.
			m.walker.global_position = r.global_position + Vector2(-10, 0)
			r.set_physics_process(false)
		9:
			var t: Dictionary = m._target()
			assert(t.get("hint", "") == "pick up the robot mower", "empty hands by it: pick it up")
			t.act.call()
			assert(m.robots.is_empty() and m.walker.carrying == "robot", "in your hands again")
			m.interact() # and down again
			m._call_police()
			m.walker.global_position = m.get_node("Truck").position + Vector2(0, -60)
		10:
			m._on_choice("leave")
			assert(g.robots == 1 and g.packed_count("robot") == 1, "fled: the one on the lawn is gone, the one on the truck came home")
			assert(g.last_result.left_behind.contains("robot mower"), "and the summary says so")
			print("PASS robot")
			quit()
	_step += 1
	return false
