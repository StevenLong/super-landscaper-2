# Hired help on the board (NOTES 209): the paper's situations wanted (no van, no ringing),
# a van, ringing hires; a calendar day's booking sent to a helper and back (picked from a
# list); their day in the day's end, a raise asked and paid there. Kit and vans: test_hub.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 5000
	change_scene_to_file("res://board.tscn")


func _texts() -> Array:
	return current_scene.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is Label or n is RichTextLabel or n is Button) \
		.map(func(n: Node) -> String: return n.text)


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
			assert(_texts().any(func(t: String) -> bool: return t.contains("SITUATION WANTED") and t.contains("No van for them")), "no van: they can't be rung")
			assert(g.buy("van"), "a van (the shop's: test_hub)")
		2:
			assert(g.vans == 1, "a van bought")
			s._show("paper")
			s._page = 99
			s._build()
		3:
			var ring: Button = s.find_child("Ring", true, false)
			assert(ring != null and _texts().any(func(t: String) -> bool: return t.contains("SITUATION WANTED") and not t.contains("No van")), "a van: ring them")
			# The last page's first Ring is a situation wanted if no ads are left on it.
			var n: int = g.helpers.size()
			for b: Node in s.find_children("Ring", "Button", true, false):
				if b.get_parent().get_child(0).text.contains("SITUATION WANTED"):
					(b as Button).pressed.emit()
					break
			assert(g.helpers.size() == n + 1, "rung, hired")
			var job: Dictionary = g.make_job(21)
			job.day = g.day + 1
			job.from = g.WINDOW_START
			job.by = g.DAY_END
			g.book(job)
			s._show("calendar")
		4:
			var h: Dictionary = g.helpers[0]
			s._open(g.day + 1) # the cursor on tomorrow's tile opens it
			var who := s.find_child("DayPanel", true, false).find_child("Who", true, false) as Button
			assert(who != null and who.text == "Going: you", "tomorrow's booking: you're going")
			who.pressed.emit()
			var menu := s.find_child("WhoMenu", true, false) as PopupMenu
			assert(menu != null and menu.item_count == 2 and menu.get_item_text(1).begins_with(h.name + ": pace") and menu.get_item_text(1).ends_with("free that day"),
				"who can go: you, and the helper with how good they are and their day")
			menu.id_pressed.emit(1)
		5:
			var h: Dictionary = g.helpers[0]
			var b: Dictionary = g.bookings(g.day + 1)[0]
			assert(b.get("helper", -1) == h.id and _button("Going: " + h.name.split(" ")[0]) != null, "sent: their name on it")
			assert(_texts().any(func(t: String) -> bool: return t.begins_with(h.name.split(" ")[0] + ": ")), "and on the day's tile")
			_button("Going: ").pressed.emit()
			(s.find_child("WhoMenu", true, false) as PopupMenu).id_pressed.emit(0)
		6:
			assert(not g.bookings(g.day + 1)[0].has("helper"), "picked again: back to you")
			g.assign(g.bookings(g.day + 1)[0], g.helpers[0].id)
			g.helpers[0].pace = (roundi(g.helpers[0].pace * 10.0) + 0.5) / 10.0 - 0.001 # a whisker under their next point: tomorrow's job ticks it
			g.end_day() # tomorrow's done by them... first today ends
			g.day_end = {}
			g.end_day()
			s._ready()
		7:
			assert(_texts().any(func(t: String) -> bool: return t.begins_with(g.helpers[0].name.split(" ")[0] + ": 1 job")), "their day in the day's end: %s" % [_texts()])
			assert(g.helpers[0].has("asks") and _texts().any(func(t: String) -> bool: return t.begins_with("Raise ")), "a point up: they ask, at the day's end")
			_button("Pay it").pressed.emit()
		8:
			assert(not g.helpers[0].has("asks"), "paid")
			assert(not _texts().any(func(t: String) -> bool: return t.begins_with("Raise ")), "and the ask's gone from the day's end")
			_button("Next day").pressed.emit()
			print("PASS crew board")
			quit()
	_step += 1
	return false
