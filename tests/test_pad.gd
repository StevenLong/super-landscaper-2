# The pad on every menu screen session 24 added or touched (NOTES 221's measuring, made a
# test): from where the cursor starts, the four directions reach every control on the
# screen, and no press jumps the wrong way (left goes left, more sideways than up or down;
# up goes up). A slider's left and right change its value, so only its up and down count.
# Screens: the summary (a raise to ask, a month up front, a regular's offer), the desk's
# day's end with raises to answer, payday (paying, and short with kit to sell), court, the
# winter, the places' cards (a van, a helper, a mower, the truck, the shop's stock, paused),
# the calendar (a day, who goes, the month; B shuts the list, then goes up to the month), the
# paper's classifieds, a call (B hangs up) and Vince's (with no offer, and with one: taken).
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _wait := 0
var _id := 0
var _walked: Array[String] = [] ## each screen walked, and how many stops it had


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 5000
	var j: Dictionary = g.make_job(3)
	_id = j.seed
	g.regulars[_id] = {"id": _id, "job": j, "cadence": 7, "rate": 100, "mood": 95.0, "drift": [], "seasons": 1}
	g.current_job = g._visit(_id)
	g.last_result = {"outcome": "paid", "customer": j.customer, "comment": "Lovely.", "paid": 100, "net": 100, "fuel_cost": 0,
		"rep": 2.0, "rep_lines": [["The job", 2.0]], "tip": 0, "rep_before": 50.0, "rep_after": 51.0, "can_raise": true, "mood": 95.0}
	change_scene_to_file("res://summary.tscn")


## Every control the cursor can sit on, on screen.
func _stops() -> Array[Control]:
	var out: Array[Control] = []
	for n: Node in current_scene.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree() and (c is BaseButton or c is Range):
			out.append(c)
	return out


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	root.push_input(ev)
	var up := InputEventAction.new()
	up.action = action
	root.push_input(up)


## Walk a screen from where the cursor is: every stop reached, no press the wrong way.
func _audit(where: String) -> void:
	var stops := _stops()
	assert(not stops.is_empty(), "%s: something to press" % where)
	var start := root.gui_get_focus_owner()
	assert(start != null and start in stops, "%s: the cursor starts on something (%s)" % [where, start])
	var seen: Array[Control] = [start]
	var i := 0
	while i < seen.size():
		var from: Control = seen[i]
		i += 1
		for dir: String in ["ui_left", "ui_right", "ui_up", "ui_down"]:
			if from is Range and dir in ["ui_left", "ui_right"]:
				continue # a slider's value, not a move
			from.grab_focus()
			_press(dir)
			var to := root.gui_get_focus_owner()
			if to == null or to == from:
				continue
			var v := to.get_global_rect().get_center() - from.get_global_rect().get_center()
			var ok: bool = {"ui_left": v.x < 0.0 and absf(v.x) > absf(v.y), "ui_right": v.x > 0.0 and absf(v.x) > absf(v.y),
				"ui_up": v.y < 0.0, "ui_down": v.y > 0.0}[dir]
			assert(ok, "%s: %s from %s jumps to %s" % [where, dir, _say(from), _say(to)])
			if to not in seen:
				seen.append(to)
	for c: Control in stops:
		assert(c in seen, "%s: %s can't be reached with the pad (reached %s)" % [where, _say(c), seen.map(_say)])
	_walked.append("%s %d" % [where, stops.size()])
	start.grab_focus()


func _say(c: Control) -> String:
	return "\"%s\"" % c.text if c is Button else str(c.name)


func _process(_delta: float) -> bool:
	_frame += 1
	if _wait > 0:
		_wait -= 1
		return false
	var s: Node = current_scene
	if s == null: # a scene still coming in
		return false
	match _step:
		0:
			_audit("the summary, a raise to ask")
			s._raise_screen(_id)
		1:
			_audit("asking a regular for a raise")
			g.upfront = {"id": _id, "visits": 4, "amount": 360}
			s._upfront_screen()
		2:
			_audit("a month up front")
			var o: Dictionary = g.make_job(9)
			g.offer = {"id": o.seed, "job": o, "cadence": 14, "rate": o.pay, "mood": 80.0, "day": g.day, "drift": []}
			s._offer_screen()
		3:
			_audit("they want you back")
			g.money = 5000
			g.premises = 2 # a warehouse with a breakroom: room and seats (test_premises)
			g.staff_room = "breakroom"
			g.buy("van")
			g.buy("van")
			g.wanted.assign([{"id": 1, "name": "Keith Pratt", "pace": 0.8, "care": 0.5, "wage": 80, "rep": 50.0},
				{"id": 2, "name": "Agnes Crumb", "pace": 0.8, "care": 0.5, "wage": 80, "rep": 50.0}])
			g.hire(g.wanted[0])
			g.hire(g.wanted[0])
			for h: Dictionary in g.helpers:
				h.asks = h.wage + 20
			g.day_end = {"day": g.day, "mine": [{"customer": "Mrs X", "net": 80, "outcome": "paid", "mood": 80.0}],
				"crew": ["Keith: 2 jobs, $160.", "Agnes: 1 job, $70."], "crew_net": 230, "missed": [], "was": 4000, "now": 4310}
			change_scene_to_file("res://board.tscn")
		4:
			_audit("the day's end, two raises to answer")
			g.day_end = {}
			g.payday_pending = true
			s._ready()
		5:
			_audit("payday, paying the shark")
			g.money = 0
			s._payday()
		6:
			_audit("payday, short, kit to sell")
			g.payday_pending = false
			g.money = 5000
			g.calendar[g.day] = [{"court": {"charge": 2.0, "tier": 2, "caught": false, "customer": "Keith Figgis"}}]
			s._ready()
		7:
			_audit("court")
			g.calendar.erase(g.day)
			s._winter()
		8:
			_audit("the winter")
			g.money = 5000 # the winter's keep took the rest
			g.buy("petrol")
			g.place = "home"
			g.spot = "truck"
			change_scene_to_file("res://hub.tscn")
		9:
			s.use("look at the van")
		10:
			_audit("a van's card")
			s._close_card()
			change_scene_to_file("res://hub.tscn")
		11:
			s.use("talk to %s" % g.helpers[0].name.split(" ")[0])
		12:
			_audit("a helper's card")
			s._close_card()
			s.use("look at the petrol mower")
		13:
			_audit("a mower")
			s._close_card()
			s.use("get in your truck")
		14:
			_audit("the truck")
			s._close_card()
			var pause := InputEventAction.new()
			pause.action = "pause"
			pause.pressed = true
			root.push_input(pause)
		15:
			_audit("the planner")
			s._close_card()
			g.place = "shop"
			change_scene_to_file("res://hub.tscn")
		16:
			s.use("look at the petrol mower")
		17:
			_audit("the shop's stock")
			for d in [0, 1]: # a day on the calendar: one booking each helper's, one yours
				var j: Dictionary = g.make_job(60 + d)
				j.day = g.day + 1
				j.from = g.WINDOW_START + 120 * d
				j.by = g.DAY_END
				g.book(j)
			g.assign(g.bookings(g.day + 1)[0], g.helpers[0].id)
			g.place = "home"
			g.spot = "corkboard"
			change_scene_to_file("res://board.tscn")
		18:
			s._open_day = g.day + 1
			s._build()
		19:
			_audit("the calendar's day")
			(s.find_child("Who", true, false) as Button).pressed.emit()
		20:
			_audit("who goes")
			_press("gear_up")
			assert(s._pick != null and s._open_day == g.day + 1, "the shoulders don't get past the list")
			_press("hop")
		21:
			assert(s._pick == null and root.gui_get_focus_owner() == s.find_child("Who", true, false), "B shuts the list, back on its booking")
			_press("hop")
		22:
			assert(s._cal_month, "B on a day: its month")
			_audit("the calendar's month")
			g.paper = g.make_paper()
			s._show("paper")
			s._turn_page(1)
		23:
			s.edge_turns = false # the walk stays on the page (test_controls turns it)
			_audit("the paper's classifieds")
			s.edge_turns = true
			(s.find_child("Ad", true, false) as Button).pressed.emit()
		24:
			_audit("a call")
			_press("hop")
		25:
			assert(s._pick == null, "B hangs up")
			s._page = 0
			g.principal = 0
			g.shark_offer = false
			s._build()
			(s.find_child("Vince", true, false) as Button).pressed.emit()
		26:
			assert(s.find_child("Said", true, false).text.contains("ready to grow"), "Vince, with no offer: come back later")
			_press("hop")
			g.principal = 0
			g.premises = 0 # the lock-up, outgrown: his offer stands (the warehouse's kit gone, so the unit takes what's left)
			g.vans = 0
			g.robots = 0
			g.spares = {}
			g.staff_room = ""
			g.shark_offer = true
			g.money = 0
		27:
			(s.find_child("Vince", true, false) as Button).pressed.emit()
		28:
			_audit("Vince's offer")
			(s.find_children("Reply", "Button", true, false)[0] as Button).pressed.emit() # Take it
			assert(g.premises == 1 and g.principal == g.PREMISES[1].deposit, "his offer taken: the unit, on his money")
			assert(_walked.size() == 21, "every screen walked: %s" % [_walked])
			print("PASS pad: %s" % ", ".join(_walked))
			quit()
	_step += 1
	_wait = 4
	return false
