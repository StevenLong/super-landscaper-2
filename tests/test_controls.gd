# Controls, 2026-09-28 (NOTES 122, 127, 130): back (Esc, the pad's B) or pause again backs
# out of a panel with a way out; interact gets you back on the mower; walking into the dog
# does nothing, interact puts the lead on, again picks it up; the pad's B hops, X throws;
# buying on the board keeps the cursor in that row.
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
			m.queue_free()
			g.new_run(7)
			g.money = 5000
			change_scene_to_file("res://board.tscn")
			_wait = 10
		5:
			var board := current_scene
			var row: Control = board.find_child("petrol", true, false)
			assert(row != null, "the petrol mower's row")
			var buy: Button = row.find_children("*", "Button", true, false)[0]
			buy.pressed.emit()
			_wait = 3
		6:
			var focused := root.gui_get_focus_owner()
			assert(focused != null and current_scene.find_child("petrol", true, false).is_ancestor_of(focused),
				"after buying, the cursor stays in that row, on %s" % [focused])
			print("PASS controls")
			quit()
	_step += 1
	return false
