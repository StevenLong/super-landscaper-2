# Everything in your premises can be got at on foot (the verifier's run 15: the corkboard
# couldn't be, in the lock-up and the unit; a spawn wedged you between the truck and a van).
# For the lock-up, the unit and the warehouse (a staff room, vans and kit about): from some
# clear spot in the office, facing some way, each fitting is what you'd use; and coming
# back to the truck you stand somewhere clear, free to walk.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _premises := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	_setup(0)


func _setup(p: int) -> void:
	g.new_run(7)
	g.money = 50000
	for i in p:
		g.move_to(i + 1)
	if p > 0:
		g.buy("staff")
		g.buy("rideon")
		g.buy("van")
		g.buy("van")
		g.buy("petrol")
	else:
		g.buy("petrol")
	g.place = "home"
	g.spot = "truck"
	change_scene_to_file("res://hub.tscn")


## Whether a fitting's reachable: some clear spot in the office, facing some way, has it as the target.
func _reachable(s: Node, hint: String) -> bool:
	var solid: Array = s._things.filter(func(t: Dictionary) -> bool: return t.get("solid", false)).map(func(t: Dictionary) -> Rect2: return t.rect)
	var b: Rect2 = s._bounds
	var x := b.position.x
	while x < s._floor_at.x:
		var y := b.position.y
		while y < b.end.y:
			var p := Vector2(x, y)
			if not solid.any(func(r: Rect2) -> bool: return r.grow(6.0).has_point(p)):
				for k in 8:
					s.walker.position = p
					s.walker.rotation = k * PI / 4.0
					if s._target().get("hint", "") == hint:
						return true
			y += 5.0
		x += 5.0
	return false


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	var s: Node = current_scene
	if s == null or s.name != "Hub":
		return false
	match _step:
		0:
			# Back at the truck: somewhere clear, free to walk.
			var at: Vector2 = s.walker.position
			var solid: Array = s._things.filter(func(t: Dictionary) -> bool: return t.get("solid", false))
			assert(not solid.any(func(t: Dictionary) -> bool: return (t.rect as Rect2).has_point(at)), "by the truck, not wedged in anything (%d)" % _premises)
			var hints: Array = ["read the calendar on the corkboard", "sit at the desk (the client book)", "use the phone (the paper, ringing round)"]
			if _premises > 0:
				hints.append_array(["open the filing cabinet (your staff)", "lock up and go home (end the day)"])
			for h: String in hints:
				assert(_reachable(s, h), "%s: reachable on foot in %s" % [h, g.PREMISES[_premises].name])
			_premises += 1
			if _premises < g.PREMISES.size():
				_setup(_premises)
				_frame = 0
				return false
			print("PASS reach hub")
			quit()
	return false
