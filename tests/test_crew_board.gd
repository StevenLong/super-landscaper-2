# Hired help on the board (NOTES 209): the paper's situations wanted (no van, no ringing),
# a van from the shop, ringing hires; the Crew page sends a booking to a helper and back,
# gives out crew kit, answers a raise; their day's report on the calendar and the Crew page.
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
			s._show("shop")
			s.find_child("van", true, false).find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text.begins_with("Buy"))[0].pressed.emit()
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
			s._show("crew")
		4:
			var h: Dictionary = g.helpers[0]
			assert(_texts().any(func(t: String) -> bool: return t.begins_with(h.name + ": pace")), "the helper on the Crew page")
			var send := _button("You")
			assert(send != null and not send.disabled, "a booking to send")
			send.pressed.emit()
		5:
			var h: Dictionary = g.helpers[0]
			var b: Dictionary = g.bookings(g.day + 1)[0]
			assert(b.get("helper", -1) == h.id and _button(h.name.split(" ")[0]) != null, "sent: their name on it")
			_button(h.name.split(" ")[0]).pressed.emit()
		6:
			assert(not g.bookings(g.day + 1)[0].has("helper"), "pressed again: back to you")
			_button("You").pressed.emit()
			g.buy("crew_petrol")
			_button("Kit:").pressed.emit()
		7:
			assert(g.helpers[0].kit == "petrol" and _button("Kit: Petrol") != null, "given the crew's petrol mower")
			g.helpers[0].asks = g.helpers[0].wage + 20
			s._build()
		8:
			var asks: int = g.helpers[0].asks
			_button("Pay it").pressed.emit()
			assert(g.helpers[0].wage == asks, "a raise paid")
			g.end_day() # tomorrow's done by them... first today ends
			g.end_day()
			s._show("calendar")
		9:
			assert(s.find_child("CrewNews", true, false) != null, "their day's news on the calendar: %s" % [g.crew_report])
			s._show("crew")
		10:
			assert(_texts().has("Their last day"), "and on the Crew page")
			print("PASS crew board")
			quit()
	_step += 1
	return false
