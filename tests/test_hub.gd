# Your own places (design doc, The hub; NOTES 232 to 234, 248). The yard's room in Game: what
# you own is placed on its floor without overlapping, no room is no sale, more is bought at
# the sign (dearer each time), a second mower of a kind takes its own room. Then on foot: the
# office's desk opens the board and stepping away comes back; a mower's card marks it yours;
# a helper out on a job is gone from the yard with a van and the unmarked mower, those still
# in stand there; the truck lists today's job and drives to the shop (+30 min each way); the
# shop's card buys; a van's card sells it; a helper's card says their day; going to a job is
# packing; anything waiting to be read sends you to the desk.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _job := {}
var _was := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	_days()
	g.new_run(7)
	g.money = 20000
	assert(g.yard_room("van") and g.cant_buy("van") == "", "an empty yard has room for a van")
	var n := 0
	while g.buy("van"):
		n += 1
		assert(n < 20, "the yard fills")
	assert(n >= 2 and g.cant_buy("van") == "No room in the yard" and not g.buy("van"), "full: no room, no sale (%d vans)" % n)
	_no_overlaps()
	var rows: int = g.yard_rows
	var price: int = g.price_of("yard")
	assert(g.buy("yard") and g.yard_rows == rows + g.YARD_MORE and g.price_of("yard") > price, "more yard, dearer the next lot")
	assert(g.buy("van"), "and room again")
	_no_overlaps()
	g.hire(g.wanted[0])
	g.hire(g.wanted[0])
	assert(g.buy("petrol") and g.buy("petrol") and _petrols() == 2, "two petrol mowers, each on the floor")
	_no_overlaps()
	while g.buy("robot"):
		pass
	assert(g.cant_buy("petrol") == "No room in the yard", "full: no third")
	g.sell("robot")
	g.sell("robot")
	g.place = "office"
	g.spot = "desk"
	change_scene_to_file("res://hub.tscn")


## The day's end's sums (the verifier's run 9): payday and the winter start the next day
## afresh; a classified lost to a day in jail is in that day's end.
func _days() -> void:
	g.new_run(7)
	g.money = 1000
	while not g.payday_pending:
		g.end_day()
	g.settle_payday()
	g.end_day()
	assert(g.day_end.now - g.day_end.was == 0, "the day after payday: nothing spent on it")
	var ad: Dictionary = g.make_job(5)
	ad.day = g.day
	g._add(g.day, ad)
	g._take_day(g.day, {"jail": true})
	g.end_day()
	assert(ad.customer in g.day_end.missed, "a job lost to jail: in the day's end (%s)" % [g.day_end.missed])
	g.run_tally = {"windows": 3}
	g.settle_winter()
	assert(g.paper_tally == g.run_tally and g.front_page()[0][0] == "QUIET WEEK IN THE GARDENS", "last season's mess isn't April's news")


func _no_overlaps() -> void:
	var lay: Dictionary = g.yard_layout()
	assert(lay.over.is_empty(), "everything placed")
	for a: Dictionary in lay.placed:
		assert(Rect2i(Vector2i.ZERO, Vector2i(g.YARD_W, g.yard_rows)).encloses(Rect2i(a.at, a.size)), "on the floor")
		for b: Dictionary in lay.placed:
			assert(a == b or not Rect2i(a.at, a.size).intersects(Rect2i(b.at, b.size)), "nothing on top of anything")


func _petrols() -> int:
	return g.yard_kit().filter(func(it: Dictionary) -> bool: return it.kind == "petrol").size()


func _hints(start: String) -> Array:
	return current_scene._things.filter(func(t: Dictionary) -> bool: return (t.hint as String).begins_with(start))


## A button on the open card, by how its text starts.
func _card(text: String) -> Button:
	var c: Control = current_scene._card
	assert(c != null, "a card is open")
	for b: Button in c.find_children("*", "Button", true, false):
		if b.text.begins_with(text):
			return b
	assert(false, "no %s on the card: %s" % [text, c.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)])
	return null


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	var s: Node = current_scene
	match _step:
		0:
			assert(s.name == "Hub" and g.place == "office", "the office")
			assert(s._things.any(func(t: Dictionary) -> bool: return t.hint.begins_with("use the desk")), "the desk's in it")
			s.use("use the desk")
		1:
			assert(s.name == "Board", "the desk opens the board")
			var back := InputEventJoypadButton.new() # the pad's B: away from the desk (it crashed, 2026-10-04)
			back.button_index = JOY_BUTTON_B
			back.pressed = true
			root.push_input(back) # the calendar's day, up to its month
			assert(s._cal_month, "B on a day: its month")
			root.push_input(back) # and away
		2:
			assert(s.name == "Hub" and g.place == "office" and s.walker.position.distance_to(Vector2(150, 80)) < 1.0, "stepped away: by the desk")
			s.use("go out to the yard")
		3:
			assert(s.name == "Hub" and g.place == "yard", "out to the yard")
			assert(_hints("look at the van").size() == g.vans, "a van for every van: %d" % g.vans)
			for t: Dictionary in s._things: # no kit hidden behind something you can't see through (NOTES 236); a van's roof shows
				for o: Dictionary in s._things:
					assert(o == t or (t.hint as String).begins_with("look at the van") or o.get("covering", false)
						or not s._covers(o.node, (t.node as Node2D).position + Vector2(0, -6)),
						"%s hidden behind %s" % [t.hint, o.hint])
			s.use("look at the petrol mower")
			_card("Mark it yours").pressed.emit()
		4:
			assert(g.mine.get("petrol", 0) == 1 and _hints("look at your petrol mower").size() == 1 and _hints("look at the petrol mower").size() == 1,
				"one petrol mower marked yours, from its card")
			var h: Dictionary = g.helpers[0]
			var sent: Dictionary = g.make_job(32)
			sent.day = g.day
			sent.from = g.WINDOW_START + 60
			sent.by = g.DAY_END
			g._add(g.day, sent)
			g.assign(sent, h.id)
			g.minute = sent.from - g.DRIVE + 5
			change_scene_to_file("res://hub.tscn")
		5:
			var h: Dictionary = g.helpers[0]
			assert(g.out_till(h.id) > g.minute, "set off")
			assert(_hints("talk to %s" % h.name.split(" ")[0]).is_empty() and _hints("talk to %s" % g.helpers[1].name.split(" ")[0]).size() == 1,
				"out on a job: gone from the yard; the one still in stands there")
			assert(_hints("look at the van").size() == g.vans - 1 and _hints("look at the petrol mower").is_empty() and _hints("look at your petrol mower").size() == 1,
				"their van and the unmarked petrol mower gone with them, yours left")
			_job = g.make_job(31)
			_job.day = g.day
			_job.from = g.WINDOW_START + 120
			_job.by = g.DAY_END
			g._add(g.day, _job)
			s.use("get in your truck")
			assert(_card("Go to %s" % _job.customer) != null, "the truck: today's job")
			_was = g.minute
			_card("Drive to the mower shop").pressed.emit()
		6:
			assert(s.name == "Hub" and g.place == "shop" and g.minute == _was + g.DRIVE, "to the shop, a drive")
			_was = g.robots
			s.use("look at the robot")
			_card("Buy it").pressed.emit()
		7:
			assert(g.robots == _was + 1, "bought off its card")
			s._close_card()
			s.use("look at the counter") # its card's lines came out untyped: an engine error (2026-10-04)
			assert(current_scene._card != null, "the counter's card opens")
			s._close_card()
			s.use("look at the petrol mower")
			_card("Buy another")
			s._close_card()
			_was = g.minute
			s.use("drive home")
		8:
			assert(g.place == "yard" and g.minute == _was + g.DRIVE, "home, a drive")
			_was = g.vans
			s.use("look at the van")
			_card("Sell it").pressed.emit()
		9:
			assert(g.helpers.size() == 2 and g.vans == _was - 1, "a van sold off its card")
			var h: Dictionary = g.helpers[1]
			s.use("talk to %s" % h.name.split(" ")[0])
			assert(s._card.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.begins_with("Today: nothing")), "their card: their day")
			_card("Let %s go" % h.name.split(" ")[0])
			s._close_card()
		10:
			s.go(_job)
		11:
			assert(s.name == "Pack" and g.next_job == _job, "going: packing first")
			g.day_end = {"day": g.day, "mine": [], "crew": [], "crew_net": 0, "missed": [], "was": 0, "now": 0}
			change_scene_to_file("res://hub.tscn")
		13:
			assert(s.name == "Board" and "DAY'S END" in s.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text),
				"something to read: the desk, first")
			g.day_end = {}
			g.calendar[g.day] = [{"jail": true}]
			change_scene_to_file("res://hub.tscn")
		15:
			assert(s.name == "Board" and (s.find_child("Away", true, false) as Button).disabled, "a day inside: the desk, and nowhere to step away to")
			g.calendar.erase(g.day)
			g.place = "yard"
			g.spot = "truck"
			change_scene_to_file("res://hub.tscn")
		17:
			s._yard_card({"kind": "petrol", "n": 0, "mine": true})
			_card("Let the crew use it").pressed.emit()
			assert(g.mine.get("petrol", 0) == 0, "a mower marked yours, let go to the crew from its card")
			print("PASS hub")
			quit()
	_step += 1
	return false
