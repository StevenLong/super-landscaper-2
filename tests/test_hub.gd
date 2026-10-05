# Your own places on foot (design doc, The hub, redesigned; NOTES 232 to 234, 248, 249). The
# lock-up: the corkboard opens the calendar (B to its month, B away), the desk the client
# book; the phone rings the estate agent (you move to the unit) and a builder (a staff
# corner, and the filing cabinet with it); the cabinet lists your staff, each to their card;
# helpers who are in stand in the staff room; a thing picked up and put back stays put, set
# down elsewhere moves; a helper out on a job is gone with their van; the truck lists today's
# job, the shop and home for the night; the shop's card buys; a van's card sells it; the
# street door is there from the unit; Start opens the planner and B puts it away; ending the
# day with a job still reachable asks first, then the day's end; going to a job is packing;
# anything waiting to be read sends you to the desk.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _job := {}
var _was := 0
var _cell := Vector2i.ZERO


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	_days()
	g.new_run(7)
	g.money = 20000
	g.place = "home"
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


## A button on the open card, by how its text starts.
func _card(text: String) -> Button:
	var c: Control = current_scene._card
	assert(c != null, "a card is open")
	for b: Button in c.find_children("*", "Button", true, false):
		if b.text.begins_with(text):
			return b
	assert(false, "no %s on the card: %s" % [text, c.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)])
	return null


func _hints(start: String) -> Array:
	return current_scene._things.filter(func(t: Dictionary) -> bool: return (t.hint as String).begins_with(start))


func _pad_b() -> void:
	var back := InputEventJoypadButton.new() # the pad's B (it crashed stepping away, 2026-10-04)
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	root.push_input(back)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	var s: Node = current_scene
	match _step:
		0:
			assert(s.name == "Hub" and g.place == "home", "your premises")
			for h: String in ["read the calendar", "sit at the desk", "use the phone", "get in your truck"]:
				assert(_hints(h).size() == 1, "%s: there" % h)
			assert(_hints("lock up and go home").is_empty() and _hints("open the filing cabinet").is_empty(), "a lock-up: no street door, no staff")
			s.use("read the calendar")
		1:
			assert(s.name == "Board" and s._view == "calendar" and s.find_child("Tab_paper", true, false) == null, "the corkboard: the calendar, no tabs")
			_pad_b()
			assert(s._cal_month, "B on a day: its month")
			_pad_b()
		2:
			assert(s.name == "Hub" and g.spot == "corkboard", "stepped away: by the corkboard")
			s.use("sit at the desk")
		3:
			assert(s.name == "Board" and s._view == "book", "the desk: the client book")
			_pad_b()
		4:
			assert(s.name == "Hub", "away from the desk")
			s.use("use the phone")
			_card("Read the paper")
			_was = g.money
			_card("Ring the estate agent").pressed.emit()
		5:
			assert(g.premises == 1 and g.money == _was - g.PREMISES[1].deposit and s.name == "Hub", "moved to the unit")
			assert(_hints("lock up and go home").size() == 1, "a street door")
			s.use("use the phone")
			_card("Ring a builder").pressed.emit()
		6:
			assert(g.staff_room == "corner" and _hints("open the filing cabinet").size() == 1 and _hints("look at the staff corner").size() == 1,
				"a staff corner, and the filing cabinet with it")
			g.wanted.assign([{"id": 1, "name": "Keith Pratt", "pace": 0.8, "care": 0.5, "wage": 80, "rep": 50.0},
				{"id": 2, "name": "Agnes Crumb", "pace": 0.8, "care": 0.5, "wage": 80, "rep": 50.0}])
			g.hire(g.wanted[0])
			g.hire(g.wanted[0])
			g.buy("van")
			g.buy("van")
			g.buy("petrol")
			change_scene_to_file("res://hub.tscn")
		7:
			var room: Rect2 = _hints("look at the staff corner")[0].rect
			for h: Dictionary in g.helpers:
				var t: Array = _hints("talk to %s" % h.name.split(" ")[0])
				assert(t.size() == 1 and room.grow(4.0).has_point((t[0].node as Node2D).position), "%s waits in the staff corner" % h.name)
			s.use("open the filing cabinet")
			_card(g.helpers[1].name).pressed.emit()
		8:
			assert(s._card != null and s._card.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == g.helpers[1].name),
				"the cabinet: to their card")
			_card("Let %s go" % g.helpers[1].name.split(" ")[0])
			s._close_card()
			# Picked up and put back: where it was. Then set down somewhere clear.
			var was: Dictionary = g.spots["petrol:0"].duplicate()
			s.use("look at the petrol mower")
			_card("Move it").pressed.emit()
			assert(not s._carry.is_empty() and not (s._item_nodes["petrol:0"] as Node2D).visible, "picked up")
			s._end_carry(true)
			assert(g.spots["petrol:0"] == was, "put back: where it was")
		9:
			var petrol := {"kind": "petrol", "n": 0, "mine": false}
			s.use("look at the petrol mower")
			_card("Move it").pressed.emit()
			for y in g.floor_size().y: # a clear spot, not where it is
				for x in g.floor_size().x:
					if _cell == Vector2i.ZERO and Vector2i(x, y) != g.spots["petrol:0"].at and g.put_down(petrol, Vector2i(x, y), false, false):
						_cell = Vector2i(x, y)
			s.walker.rotation = 0.0 # stood so it'd go there: the footprint's a step ahead of you
			s.walker.position = s._floor_at + (Vector2(_cell) + Vector2(g.foot("petrol")) / 2.0) * s.CELL - Vector2(18, 0)
			assert(s._carry_cell() == _cell, "where you stand says where it goes")
			s._end_carry(false)
		10:
			assert(g.spots["petrol:0"].at == _cell, "set down where you put it")
			# A helper out on a job: gone from the staff room, their van with them.
			var h: Dictionary = g.helpers[0]
			var sent: Dictionary = g.make_job(32)
			sent.day = g.day
			sent.from = g.WINDOW_START + 60
			sent.by = g.DAY_END
			g._add(g.day, sent)
			g.assign(sent, h.id)
			g.minute = sent.from - g.DRIVE + 5
			change_scene_to_file("res://hub.tscn")
		11:
			assert(_hints("talk to %s" % g.helpers[0].name.split(" ")[0]).is_empty() and _hints("talk to %s" % g.helpers[1].name.split(" ")[0]).size() == 1,
				"out on a job: gone; the one still in, there")
			assert(_hints("look at the van").size() == g.vans - 1, "their van with them")
			_job = g.make_job(31)
			_job.day = g.day
			_job.from = g.WINDOW_START + 180
			_job.by = g.DAY_END
			g._add(g.day, _job)
			s.use("get in your truck")
			assert(_card("Go to %s" % _job.customer) != null and _card("Drive home for the night") != null, "the truck: today's job, and home")
			_was = g.minute
			_card("Drive to the mower shop").pressed.emit()
		12:
			assert(s.name == "Hub" and g.place == "shop" and g.minute == _was + g.DRIVE, "to the shop, a drive")
			_was = g.robots
			s.use("look at the robot")
			_card("Buy it").pressed.emit()
		13:
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
		14:
			assert(g.place == "home" and g.spot == "truck" and g.minute == _was + g.DRIVE, "home, a drive, by the truck")
			_was = g.vans
			s.use("look at the van")
			_card("Sell it").pressed.emit()
		15:
			assert(g.vans == _was - 1, "a van sold off its card")
			var pause := InputEventAction.new()
			pause.action = "pause"
			pause.pressed = true
			root.push_input(pause)
		16:
			assert(s._card != null and s._card.name == "Board" and s._card.planner and s._card.find_child("PlannerEnd", true, false) != null,
				"Start: the planner, today's plan and ending the day")
			_pad_b()
		17:
			assert(s._card == null and s.walker.is_physics_processing(), "B puts it away")
			s._end_day_card()
			assert(s._card != null and s._card.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text.contains(_job.customer)),
				"a job still in reach: it asks first")
			_was = g.day
			_card("End the day").pressed.emit()
		18:
			assert(s.name == "Board" and g.day == _was + 1 and "DAY'S END" in s.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text),
				"then the day's end, at the desk")
			g.day_end = {}
			_job.day = g.day
			g._add(g.day, _job)
			g.place = "home"
			change_scene_to_file("res://hub.tscn")
		19:
			s.go(_job)
		20:
			assert(s.name == "Pack" and g.next_job == _job, "going: packing first")
			g.day_end = {"day": g.day, "mine": [], "crew": [], "crew_net": 0, "missed": [], "was": 0, "now": 0}
			change_scene_to_file("res://hub.tscn")
		22:
			assert(s.name == "Board" and "DAY'S END" in s.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text),
				"something to read: the desk, first")
			g.day_end = {}
			g.calendar[g.day] = [{"jail": true}]
			change_scene_to_file("res://hub.tscn")
		24:
			assert(s.name == "Board" and (s.find_child("Away", true, false) as Button).disabled, "a day inside: the desk, and nowhere to step away to")
			print("PASS hub")
			quit()
	_step += 1
	return false
