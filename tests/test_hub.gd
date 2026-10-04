# Your own places (design doc, The hub; NOTES 232 to 234). The yard's room in Game: what you
# own is placed on its floor without overlapping, no room is no sale, more is bought at the
# sign (dearer each time), a crew petrol mower given out rides in its van and comes back out
# only if there's room. Then on foot: the office's desk opens the board and stepping away
# comes back; the yard's van card is its helper (their mower taken back); the truck lists
# today's job and drives to the shop (+30 min each way); the shop's card buys; going to a
# job is packing; anything waiting to be read sends you to the desk.
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
	var h: Dictionary = g.helpers[0]
	assert(g.buy("crew_petrol") and _crew_petrols() == 1, "the crew's petrol mower, on the floor")
	assert(g.set_kit(h.id, "petrol") and _crew_petrols() == 0, "given out: it rides in their van")
	while g.buy("robot"):
		pass
	assert(not g.set_kit(h.id, "push") and g.kit_of(h) == "petrol", "the yard full: their mower stays in the van")
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


func _crew_petrols() -> int:
	return g.yard_kit().filter(func(it: Dictionary) -> bool: return it.kind == "petrol" and it.get("crew", false)).size()


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
			root.push_input(back)
		2:
			assert(s.name == "Hub" and g.place == "office" and s.walker.position.distance_to(Vector2(150, 80)) < 1.0, "stepped away: by the desk")
			s.use("go out to the yard")
		3:
			assert(s.name == "Hub" and g.place == "yard", "out to the yard")
			var vans: Array = s._things.filter(func(t: Dictionary) -> bool: return t.hint.begins_with("look in"))
			assert(vans.size() == g.fleet.size(), "a van for every van: %d" % vans.size())
			for t: Dictionary in s._things: # no kit hidden behind something you can't see through (NOTES 236); a van's roof shows
				for o: Dictionary in s._things:
					assert(o == t or (t.hint as String).begins_with("look in") or o.get("covering", false)
						or not s._covers(o.node, (t.node as Node2D).position + Vector2(0, -6)),
						"%s hidden behind %s" % [t.hint, o.hint])
			s.use("look in %s" % g.helpers[0].name.split(" ")[0])
			_card("Take the petrol mower out").pressed.emit()
		4:
			assert(g.kit_of(g.helpers[0]) == "push" and _crew_petrols() == 1, "taken out: on the floor again")
			s.use("look at the crew's petrol mower")
			_card("Put it in %s" % g.helpers[0].name.split(" ")[0]).pressed.emit()
		5:
			assert(g.kit_of(g.helpers[0]) == "petrol", "put in their van from its card")
			_job = g.make_job(31)
			_job.day = g.day
			_job.from = g.WINDOW_START + 60
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
			_was = g.minute
			s.use("drive home")
		8:
			assert(g.place == "yard" and g.minute == _was + g.DRIVE, "home, a drive")
			_was = g.fleet.size()
			s.use("look in %s" % g.helpers[0].name.split(" ")[0])
			_card("Sell the van").pressed.emit()
		9:
			assert(g.helpers.size() == 2 and g.fleet.size() == _was - 1 and g.van_of(g.helpers[0].id).is_empty() and _crew_petrols() == 1,
				"their van sold: they step out (still yours), its mower back in the yard")
			assert(s._things.any(func(t: Dictionary) -> bool: return t.hint == "talk to %s" % g.helpers[0].name.split(" ")[0]), "and stand in the yard")
			s.use("talk to %s" % g.helpers[0].name.split(" ")[0])
			_card("Into the empty van").pressed.emit()
		10:
			assert(not g.van_of(g.helpers[0].id).is_empty(), "into an empty van from their card")
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
			g.money = 5000
			while g.fleet.size() < 2:
				g.buy("yard")
				g.buy("van")
			for v: Dictionary in g.fleet:
				v.kit = "push"
			g.crew_kit = {"rideon": 2}
			g.set_van_kit(g.fleet[0].id, "rideon")
			g.set_van_kit(g.fleet[1].id, "rideon")
			g.place = "yard"
			g.spot = "truck"
			change_scene_to_file("res://hub.tscn")
		17:
			s._yard_card({"kind": "rideon", "crew": true, "n": 1}) # the second van's ride-on
			_card("Sell it").pressed.emit()
			assert(g.fleet[0].kit == "rideon" and g.fleet[1].kit == "push" and g.crew_kit.rideon == 1, "its card sells that ride-on, not the first van's")
			print("PASS hub")
			quit()
	_step += 1
	return false
