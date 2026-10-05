# A regular's terms through the real summary (design doc, Regulars change softly): after a
# good visit you can ask for a raise; a loyal one offering a month up front gets its own
# screen; a sour visit's change of terms is said; the board's Drop says what you'd owe back.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _id := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	var j: Dictionary = g.make_job(3)
	_id = j.seed
	g.regulars[_id] = {"id": _id, "job": j, "cadence": 7, "rate": 100, "mood": 95.0, "drift": [], "seasons": 1}
	g.current_job = g._visit(_id)
	g.last_result = {"outcome": "paid", "customer": j.customer, "comment": "Lovely.", "paid": 100, "net": 100, "fuel_cost": 0,
		"rep": 2.0, "rep_lines": [["The job", 2.0]], "tip": 0, "rep_before": 50.0, "rep_after": 51.0, "can_raise": true, "terms": "better", "mood": 95.0}
	change_scene_to_file("res://summary.tscn")


func _labels() -> Array:
	return current_scene.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


func _press(n: String) -> void:
	var b: Button = current_scene.find_child(n, true, false)
	assert(b != null and not b.disabled, "a %s button" % n)
	b.pressed.emit()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	match _step:
		0:
			assert(_labels().any(func(t: String) -> bool: return t.contains("Pleased: they've put you up to $100")), "a better rate is said, in good news")
			_press("Raise")
			assert("A RAISE?" in _labels(), "asking for a raise: its own screen")
			_press("AskRaise") # $110 of a happy regular: likely, not certain
			assert(_labels().any(func(t: String) -> bool: return t.contains("$110 it is") or t.contains("If I must") or t.contains("can't afford")), "an answer")
			assert(current_scene.find_child("Continue", true, false) != null, "then back to the board")
			# A month up front.
			g.upfront = {"id": _id, "visits": 4, "amount": 360}
			g.last_result.can_raise = false
			for c in current_scene.get_children(): # the summary afresh
				c.free()
			current_scene._ready()
			_press("Continue")
			assert("A MONTH UP FRONT" in _labels(), "a loyal regular's offer: its own screen")
			var cash: int = g.money
			_press("Accept")
			assert(g.money == cash + 360 and g.regulars[_id].prepaid == 4 and g.upfront.is_empty(), "taken: $360 now, four visits owed")
			_press("Continue")
		1:
			assert(current_scene.name == "Hub" and g.place == "home", "home: your premises")
			var desk: Node = load("res://board.tscn").instantiate() # and in, to the desk
			current_scene.free()
			root.add_child(desk)
			current_scene = desk
			current_scene._show("book")
			assert(current_scene.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.text == "Drop (owe $360)"), "Drop says what you'd owe back")
			g.calendar = {g.day: [g._visit(_id)]}
			current_scene._show("calendar")
			assert(_labels().any(func(t: String) -> bool: return t.to_lower().contains("paid up front")), "today's visit: paid up front")
			# A sour visit: the summary says what changed.
			g.last_result = {"outcome": "paid", "customer": "X", "comment": "Hmph.", "paid": 50, "net": 50, "fuel_cost": 0,
				"rep": -1.0, "rep_lines": [["The job", -1.0]], "tip": 0, "rep_before": 50.0, "rep_after": 49.0, "terms": "fewer", "mood": 40.0}
			change_scene_to_file("res://summary.tscn")
		2:
			assert(_labels().any(func(t: String) -> bool: return t.contains("less often")), "fewer visits, said")
			assert(current_scene.find_child("Raise", true, false) == null, "no raise after a poor visit")
			print("PASS terms")
			quit()
	_step += 1
	return false
