# Controls, 2026-09-28 (NOTES 122, 127, 130): back (Esc, the pad's B) or pause again backs
# out of a panel with a way out; interact gets you back on the mower; walking into the dog
# does nothing, interact puts the lead on, again picks it up; the pad's B hops, X throws;
# with several things in reach, interact does the one you face (NOTES 123); at the truck
# on the mower, interact opens it only when you're not on the throttle; buying on the
# board keeps the cursor in that row.
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
			var board := current_scene
			var row: Control = board.find_child("petrol", true, false)
			assert(row != null, "the petrol mower's row")
			var buy: Button = row.find_children("*", "Button", true, false)[0]
			buy.pressed.emit()
			_wait = 3
		7:
			var focused := root.gui_get_focus_owner()
			assert(focused != null and current_scene.find_child("petrol", true, false).is_ancestor_of(focused),
				"after buying, the cursor stays in that row, on %s" % [focused])
			# The paper on a pad: the last Ring brings the stamped ad below it into view too.
			g.paper[-1].refused = true
			g.paper[-1].reply = "No."
			current_scene._build()
			var rings := current_scene.find_children("Ring", "Button", true, false)
			rings[-1].grab_focus()
			_wait = 5
		8:
			var last: Control = current_scene.find_children("Ring", "Button", true, false)[0].get_parent().get_parent().get_parent().get_child(-1)
			var view: ScrollContainer = last.get_parent().get_parent()
			assert(last.get_global_rect().end.y <= view.get_global_rect().end.y + 1.0, "the last ad scrolled into view")
			print("PASS controls")
			quit()
	_step += 1
	return false
