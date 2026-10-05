# Hired help on the board (NOTES 209, 248): the paper's situations wanted (no van yet,
# said so), a van, ringing hires; a calendar day's booking sent to a helper and back (picked
# from the list beside it, with their facts), their colour on the month's tile; their day in
# the day's end, a raise asked and paid there. Kit and vans: test_hub.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 5000
	g.premises = 1 # a unit with a staff corner: two seats (test_premises)
	g.staff_room = "corner"
	change_scene_to_file("res://board.tscn")


func _texts() -> Array:
	return current_scene.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel or n is Button) \
		.map(func(n: Node) -> String: return n.text)


## Press a reply in the open talk.
func _reply(s: Node, text: String) -> void:
	var talks := s.find_children("Talk", "", true, false).filter(func(t: Node) -> bool: return not t.is_queued_for_deletion())
	for b: Node in (talks[-1].find_children("*", "Button", true, false) if talks else []):
		if (b as Button).text == text and not b.is_queued_for_deletion():
			(b as Button).pressed.emit()
			return
	assert(false, "no %s to say" % text)


func _button(text: String) -> Button:
	for b: Node in current_scene.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text):
			return b
	return null


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 5 != 0:
		return false
	var s: Node = current_scene
	match _step:
		0:
			s._show("paper")
			s._page = 99 # the situations wanted are at the back
			s._build()
		1:
			assert(_texts().any(func(t: String) -> bool: return t.contains("SITUATION WANTED")), "situations wanted, at the back of the paper")
			assert(g.buy("van"), "a van (the shop's: test_hub)")
		2:
			assert(g.vans == 1, "a van bought")
			s._show("paper")
			s._page = 99
			s._build()
		3:
			var n: int = g.helpers.size()
			(s.find_child("Wanted", true, false) as Button).pressed.emit() # ring them: a talk in the portrait box
			assert(s.find_child("Talk", true, false) != null, "they pick up")
			_reply(s, "You're hired")
			assert(g.helpers.size() == n + 1, "rung, hired")
			_reply(s, "Bye")
			var job: Dictionary = g.make_job(21)
			job.day = g.day + 1
			job.from = g.WINDOW_START
			job.by = g.DAY_END
			g.book(job)
			s._show("calendar")
		4:
			var h: Dictionary = g.helpers[0]
			s._open_day = g.day + 1
			s._cal_month = false
			s._build()
			var who := s.find_child("Calendar", true, false).find_child("Who", true, false) as Button
			assert(who != null and not who.disabled and who.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "You"),
				"tomorrow's booking: you're going")
			who.pressed.emit()
			var menu := s.find_child("WhoMenu", true, false)
			var picks := menu.find_children("*", "Button", true, false)
			assert(picks.size() == 2 and picks[0].text.begins_with("You
") and picks[1].text.begins_with(h.name + "
")
				and picks[1].text.contains("Sets off 7:30am, done in time") and picks[1].text.contains("Pace"), "who can go: you, and the helper with their facts: %s" % [picks[1].text])
			(picks[1] as Button).pressed.emit()
		5:
			var h: Dictionary = g.helpers[0]
			var b: Dictionary = g.bookings(g.day + 1)[0]
			assert(b.get("helper", -1) == h.id and s.find_child("WhoMenu", true, false) == null, "sent, the list shut")
			assert(_texts().has(h.name.split(" ")[0]), "their name on the row")
			# The mower: best free, then each kind the crew can take (not one marked yours).
			assert(s._next_kit("") == "push" and s._next_kit("push") == "", "only push mowers to step through")
			g.buy("petrol")
			g.mark_mine("petrol", true)
			assert(s._next_kit("push") == "", "a petrol marked yours isn't one to pick")
			g.set_job_kit(b, "petrol")
			s._build()
			assert((s.find_child("Mower", true, false) as Button).text == "Push\n(petrol not free)", "a pick that isn't free says so")
			g.set_job_kit(b, "")
			s._to_month()
			var dots := (s.find_child("Tile_%d" % (g.day + 1), true, false) as Node).find_children("*", "ColorRect", true, false)
			assert(dots.size() == 1 and (dots[0] as ColorRect).color == s._who_color(h.id), "and their colour on the day's tile")
			s._open_day = g.day + 1
			s._cal_month = false
			s._build()
			(s.find_child("Who", true, false) as Button).pressed.emit()
			(s.find_child("WhoMenu", true, false).find_children("*", "Button", true, false)[0] as Button).pressed.emit()
		6:
			assert(not g.bookings(g.day + 1)[0].has("helper"), "picked again: back to you")
			g.assign(g.bookings(g.day + 1)[0], g.helpers[0].id)
			g.helpers[0].pace = (roundi(g.helpers[0].pace * 10.0) + 0.5) / 10.0 - 0.001 # a whisker under their next point: tomorrow's job ticks it
			g.end_day() # tomorrow's done by them... first today ends
			g.day_end = {}
			g.end_day()
			s._ready()
		7:
			var card := s.find_child("Card_0", true, false) as Button
			assert(card != null and card.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == g.helpers[0].name.split(" ")[0]),
				"their job a card in the day's end: %s" % [_texts()])
			card.pressed.emit()
			var opened: Node = s.find_children("Card_0", "Button", true, false)[-1] # the old one's freed at the frame's end
			assert(opened.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "Paid"), "A opens its report")
			assert(g.helpers[0].has("asks") and _texts().any(func(t: String) -> bool: return t.contains(" asks for $")), "a point up: they ask, a card at the day's end")
			_button("Pay it").pressed.emit()
		8:
			assert(not g.helpers[0].has("asks"), "paid")
			assert(not _texts().any(func(t: String) -> bool: return t.contains(" asks for $")), "and the ask's gone from the day's end")
			_button("Next day").pressed.emit()
			print("PASS crew board")
			quit()
	_step += 1
	return false
