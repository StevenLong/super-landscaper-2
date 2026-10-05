# The paper and its calls (design doc, The hub, redesigned; NOTES 251, verifier run 14).
# A call's time is owed however it ends (Never mind, Not now, B), once; an ad you can't
# act on can't hold the cursor, nor a page button at an end; only an ad or a page button
# turns the page past an edge, not the header's; booking the last ad on the classifieds
# leaves you on the classifieds, the cursor near the ad you rang; Vince's ad says when his
# offer stands; B on the shark's man at payday is Not now, the payday screen kept.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0
var _was := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.paper.clear()
	for i in 7: # two pages of classifieds: six, then one
		g.paper.append(g.make_job(70 + i))
	for o: Dictionary in g.paper:
		o.bar = 0.0 # a sure yes
		o.day = g.day + 1
	g.paper[1].refused = true
	g.paper[1].reply = "\"No.\""
	g.place = "home"
	g.spot = "paper"
	change_scene_to_file("res://board.tscn")


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	root.push_input(ev)


func _talk() -> Node:
	var talks := current_scene.find_children("Talk", "", true, false).filter(func(t: Node) -> bool: return not t.is_queued_for_deletion())
	return talks[-1] if talks else null


func _reply(text: String) -> void:
	for b: Node in _talk().find_children("*", "Button", true, false):
		if (b as Button).text == text:
			(b as Button).pressed.emit()
			return
	assert(false, "no %s to say" % text)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 5 != 0:
		return false
	var s: Node = current_scene
	match _step:
		0:
			s._turn_page(1)
		1:
			var refused: Array = s.get_tree().get_nodes_in_group("paper_ad").filter(func(a: Button) -> bool: return a.disabled and not a.is_queued_for_deletion())
			assert(refused.size() == 1 and refused[0].focus_mode == Control.FOCUS_NONE, "an ad you can't ring can't hold the cursor")
			var prev: Button = s.find_child("PrevPage", true, false)
			assert(not prev.disabled and prev.focus_mode == Control.FOCUS_ALL, "a page button that turns can")
			# Never mind: the call's time all the same.
			_was = g.minute
			(s.get_tree().get_nodes_in_group("paper_ad")[0] as Button).pressed.emit()
			_reply("Never mind")
			assert(g.minute == _was + g.RING_TIME and _talk() == null, "Never mind: the call took its time")
		2:
			# B: the same.
			_was = g.minute
			(s.find_child("Ad", true, false) as Button).pressed.emit()
			_press("hop")
		3:
			assert(g.minute == _was + g.RING_TIME and _talk() == null, "B: hung up, and the call took its time")
			# The header's left doesn't turn the page.
			var page: int = s._page
			(s.find_child("Away", true, false) as Button).grab_focus()
			_press("ui_left")
			assert(s._page == page, "left from the header: the same page")
			# Booking the last ad on the classifieds: still on the classifieds, the cursor on an ad there.
			s._turn_page(1)
		4:
			assert(s._paper_page_list()[s._page] == "ads:1", "the second page of classifieds: %s of %s" % [s._page, s._paper_page_list()])
			_was = g.minute
			(s.find_child("Ad", true, false) as Button).pressed.emit()
			_reply("Book it")
			_reply("Bye")
			assert(g.minute == _was + g.RING_TIME, "booked: the call's time, once")
		5:
			assert(s._paper_page_list()[s._page].begins_with("ads"), "still on the classifieds, not situations wanted: %s" % s._paper_page_list()[s._page])
			assert(root.gui_get_focus_owner() is Button and (root.gui_get_focus_owner() as Node).is_in_group("paper_ad"), "the cursor on an ad")
			# Vince's ad says when his offer stands.
			g.principal = 0
			g.shark_offer = true
			s._page = 0
			s._build()
			assert((s.find_child("Vince", true, false) as Button).text.contains("offer for you"), "Vince's ad: an offer for you")
			# The shark's man at payday: B is Not now, the payday screen kept.
			g.money = 5000
			g.payday_pending = true
			s._collect(0)
		6:
			assert(_talk() != null, "his man has a word")
			_press("hop")
		7:
			assert(_talk() == null and g.shark_offer and s.find_child("Station", true, false) == null
				and s.find_children("*", "Button", true, false).any(func(b: Button) -> bool: return b.text == "Read the paper"),
				"B: not now, the offer standing, the payday screen still there")
			print("PASS paper")
			quit()
	_step += 1
	return false
