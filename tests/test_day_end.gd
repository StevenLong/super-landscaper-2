# The day's end as cards and the client book (design doc, The hub, redesigned; NOTES 250).
# The day's end: a card a job in the day's order, yours and the crew's together, a job
# nobody went to last; A opens a card's report; the sum card adds the jobs, each thing
# bought or sold, and whatever else moved the money, to today's total. The client book: an
# index with a mood dot a regular, A to their page (their face, when, the rate, the next
# visit, Drop), the shoulders turning pages, B back to the index.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _ids: Array = []


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 50000
	# The ledger: kit left behind isn't sold; a breakroom's a breakroom (the verifier's run 13).
	g.premises = 2
	g.buy("petrol")
	g.lose("petrol")
	assert(not g.day_ledger.any(func(l: Array) -> bool: return (l[0] as String).begins_with("Sold")), "left behind: not sold")
	g.buy("staff")
	assert(g.day_ledger[-1][0] == "Bought breakroom", "the breakroom, by its name: %s" % [g.day_ledger])
	g.day_ledger.clear()
	g.helpers.assign([{"id": 9, "name": "Nigel Pratt", "pace": 0.7, "care": 0.4, "wage": 470, "jobs": 3, "happy": 70.0, "asks": 520}])
	g.money = 1000
	g.day_end = {"day": g.day, "was": 1000, "now": 1060, "crew": [], "crew_net": 40, "missed": ["Gwen Hughes"],
		"mine": [{"customer": "Tom Okafor", "net": 140, "outcome": "paid", "mood": 88.0, "at": 840, "paid": 160, "tip": 0, "fuel": 20, "rep": 3.0}],
		"crew_jobs": [{"who": "Nigel", "helper": -1, "customer": "Raj Patel", "at": 600, "net": 40, "flag": "flowerbed",
			"lines": [["Paid", "$82"], ["Fuel", "-$12"], ["Flattened a flowerbed", "-$30"]]}],
		"ledger": [["Bought petrol mower", -180]]}
	for i in 3:
		var j: Dictionary = g.make_job(40 + i)
		g.regulars[j.seed] = {"id": j.seed, "job": j, "cadence": [7, 14, 28][i], "rate": j.pay, "mood": [90.0, 60.0, 30.0][i], "drift": []}
		_ids.append(j.seed)
	g.place = "home"
	g.spot = "desk"
	change_scene_to_file("res://board.tscn")


func _labels(n: Node) -> Array:
	return n.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 5 != 0:
		return false
	var s: Node = current_scene
	match _step:
		0:
			assert("DAY'S END" in _labels(s), "the day's end, first")
			var order: Array = []
			for i in 3:
				var c: Node = s.find_child("Card_%d" % i, true, false)
				assert(c != null, "a card a job")
				order.append(_labels(c)[1])
			assert(order == ["Raj Patel", "Tom Okafor", "Gwen Hughes"], "in the day's order, nobody's last: %s" % [order])
			assert("missed" in _labels(s.find_child("Card_2", true, false)) and "flowerbed" in _labels(s.find_child("Card_0", true, false)), "a word when something happened")
			var sum := _labels(s.find_child("Summary", true, false))
			assert(sum.slice(0, 6) == ["The jobs", "+$180", "Bought petrol mower", "-$180", "Everything else", "+$60"],
				"the jobs, each thing bought, and the rest, adding up to today: %s" % [sum])
			assert("Today" in sum and "+$60" in sum.slice(6, 8), "today")
			(s.find_child("Card_1", true, false) as Button).pressed.emit()
		1:
			var opened: Node = s.find_children("Card_1", "Button", true, false)[-1]
			assert("Fuel and repairs" in _labels(opened) and "-$20" in _labels(opened), "A opens a card's report")
			assert(root.gui_get_focus_owner() == opened and g.helpers[0].has("asks"),
				"the cursor stays on the card, not on a raise's Pay it (the verifier's run 13)")
			(s.find_child("NextDay", true, false) as Button).pressed.emit()
		2:
			assert(g.day_end.is_empty() and s._view == "book" and s.find_child("Index", true, false) != null, "then the desk: the client book's index")
			assert(s.find_children("Client", "Button", true, false).size() == 3, "a line a regular")
			var dots: Array = s.find_child("Index", true, false).find_children("*", "ColorRect", true, false).map(func(c: ColorRect) -> Color: return c.color)
			assert(dots == [s._mood_color(90.0), s._mood_color(60.0), s._mood_color(30.0)] and dots[0] != dots[1] and dots[1] != dots[2], "a mood dot each: %s" % [dots])
			(s.find_children("Client", "Button", true, false)[1] as Button).pressed.emit()
		3:
			assert(s._client == _ids[1] and s.find_children("*", "Face", true, false).size() == 1 and s.find_child("Drop", true, false) != null,
				"their page: their face, Drop")
			assert(_labels(s).any(func(t: String) -> bool: return t.begins_with("Next visit:")), "and the next visit")
			var rb := InputEventAction.new()
			rb.action = "gear_up"
			rb.pressed = true
			root.push_input(rb)
		4:
			assert(s._client == _ids[2], "the shoulder: the next page")
			var b := InputEventAction.new()
			b.action = "hop"
			b.pressed = true
			root.push_input(b)
		5:
			assert(s._client == -1 and s.find_child("Index", true, false) != null, "B: back to the index")
			print("PASS day end")
			quit()
	_step += 1
	return false
