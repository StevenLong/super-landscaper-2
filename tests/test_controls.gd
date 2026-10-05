# Controls, 2026-09-28 (NOTES 122, 127, 130): back (Esc, the pad's B) or pause again backs
# out of a panel with a way out; interact gets you back on the mower; walking into the dog
# does nothing, interact puts the lead on, again picks it up; the pad's B hops, X throws;
# with several things in reach, interact does the one you face (NOTES 123); at the truck
# on the mower, interact opens it only when you're not on the throttle; left and right
# on the desk's pages stay level, and every page fits.
extends SceneTree

var g: Node
var m: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	for pair: Array in [["hop", JOY_BUTTON_B], ["throw", JOY_BUTTON_X], ["interact", JOY_BUTTON_A]]:
		assert(InputMap.action_get_events(pair[0]).any(func(e: InputEvent) -> bool:
			return e is InputEventJoypadButton and e.button_index == pair[1]), "%s is on pad button %d" % pair)
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	_wait = 2


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	m.hud._input(ev) # parse_input_event doesn't flush headless; the panel's handler is what's under test


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			assert(m.at_truck(), "the mower starts at the truck")
			m.mower.throttle = 1.0 # the pad's A is sprint while you're pushing
			m.interact()
			assert(not m.hud.is_open(), "with the throttle held, interact doesn't open the truck")
			m.mower.throttle = 0.0
			m.interact()
			assert(m.hud.is_open(), "stopped, it does")
			m._on_choice("resume")
			m.open_pause()
			assert(m.hud.is_open() and paused, "paused")
			_press("ui_cancel")
			_wait = 2
		1:
			assert(not m.hud.is_open() and not paused, "back closes the pause menu")
			m.open_pause()
			_press("pause")
			_wait = 2
		2:
			assert(not m.hud.is_open() and not paused, "so does pause again")
			m.mower.global_position = Vector2(640, 420) # away from the truck
			m.hop_off()
			m.walker.global_position = m.mower.global_position + Vector2(0, 30)
			m.walker.carrying = ""
			_wait = 1
		3:
			assert(m._hint().ends_with("get back on") and m._hint().contains(g.key("interact")), "the hint says interact: %s" % m._hint())
			m.interact()
			assert(m.walker == null and m.mower.occupied, "interact gets you back on")
			m.hop_off()
			m.job["dog_name"] = "Rex"
			m._release_dog()
			m.dog.position = m.walker.global_position + Vector2(8, 0)
			_wait = 5
		4:
			assert(m.dog.following == null, "walking into the dog doesn't put the lead on")
			m.dog.position = m.walker.global_position + Vector2(8, 0)
			m.interact()
			assert(m.dog.following == m.walker and m.walker.carrying == "", "interact puts the lead on")
			m.interact()
			assert(m.walker.carrying == "dog", "and again picks them up")
			# A heap: a gnome one side, a body the other. What you face is what you get.
			m.walker.carrying = ""
			m.dog.queue_free()
			m.dog = null
			var at: Vector2 = m.walker.global_position
			m.add_stone(at + Vector2(12, 0), "gnome")
			m.spawn_animal("hedgehog", at + Vector2(-12, 0), at + Vector2(-12, 1)).kill()
			_wait = 2
		5:
			m.walker.rotation = 0.0
			assert(m._hint().ends_with("pick up the gnome"), "facing the gnome: %s" % m._hint())
			m.walker.rotation = PI
			assert(m._hint().ends_with("pick up the dead hedgehog"), "turn round, the body: %s" % m._hint())
			m.interact()
			assert(m.walker.carrying == "body_hedgehog", "and interact takes what you face")
			m.queue_free()
			g.new_run(7)
			g.money = 5000
			change_scene_to_file("res://board.tscn")
			_wait = 10
		6:
			_wait = 2
		7:
			# A busy paper and three regulars: every page fits the screen.
			for i in 3:
				var j: Dictionary = g.make_job(40 + i)
				g.regulars[j.seed] = {"id": j.seed, "job": j, "cadence": 7, "rate": j.pay, "mood": 70.0, "drift": []}
			for i in 6:
				g.paper.append(g.make_job(100 + i))
				g.paper[-1].day = g.day + 1
			current_scene._show("calendar")
			_wait = 5
		8, 9, 10:
			_fits()
			_sideways()
			current_scene._show(["paper", "book", "calendar"][_step - 8])
			if _step == 8: # past the front page, a page of ads
				current_scene._page = 1
				current_scene._build()
			_wait = 5
		11:
			_fits()
			_sideways()
			# Shift and Ctrl step the calendar's day; from its month, they turn the board's pages.
			var shift := InputEventKey.new()
			shift.keycode = KEY_SHIFT
			shift.physical_keycode = KEY_SHIFT
			shift.pressed = true
			var today: int = g.day
			current_scene._unhandled_input(shift)
			assert(current_scene._view == "calendar" and current_scene._open_day == today + 1, "Shift on a day: the next day")
			current_scene._to_month()
			current_scene._unhandled_input(shift)
			assert(current_scene._view == "paper" and current_scene._page == 0, "Shift turns to the paper, its front page")
			current_scene._unhandled_input(shift)
			assert(current_scene._view == "paper" and current_scene._page == 1, "and again turns its page")
			assert(current_scene.find_children("*", "RichTextLabel", true, false).size() == current_scene.PER_PAGE, "a page of the paper at a time")
			current_scene.find_child("NextPage", true, false).pressed.emit()
			assert(current_scene._page == 2 and not current_scene.find_child("PrevPage", true, false).disabled, "and the next page")
			print("PASS controls")
			quit()
	_step += 1
	return false


## Left and right on the board's page never step up or down a column (NOTES 221, 47).
func _sideways() -> void:
	for b: Button in current_scene.find_children("*", "Button", true, false):
		if not b.is_visible_in_tree():
			continue
		for a: String in ["ui_left", "ui_right"]:
			b.grab_focus()
			var ev := InputEventAction.new()
			ev.action = a
			ev.pressed = true
			root.push_input(ev)
			var to := root.gui_get_focus_owner()
			var v := to.get_global_rect().get_center() - b.get_global_rect().get_center()
			assert(to == b or absf(v.x) > absf(v.y) and signf(v.x) == (1.0 if a == "ui_right" else -1.0),
				"%s from %s (%s page) goes to %s, up or down a column" % [a, b.text, current_scene._view, to.text if to is Button else to])


## Every button on the board's page is on the screen (one in a scrolling list: the list is,
## and it follows the cursor).
func _fits() -> void:
	var r := root.get_visible_rect().size
	for b: Button in current_scene.find_children("*", "Button", true, false):
		var at: Control = b
		var up := b.get_parent()
		while up:
			if up is ScrollContainer:
				at = up
			up = up.get_parent()
		var e := at.get_global_rect().end
		assert(e.x <= r.x + 1.0 and e.y <= r.y + 1.0, "%s (%s page) fits on the screen (ends at %s)" % [b.text, current_scene._view, e])
