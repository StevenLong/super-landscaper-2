# Button prompts match the real bindings, and follow the last device touched.
extends SceneTree

const PAD_NAMES := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y", JOY_BUTTON_START: "Start"}
const KEY_NAMES := {"Escape": "Esc"}

var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		var game: Node = root.get_node("Game")
		for action: String in game.PROMPTS:
			var keys: Array = []
			var pads: Array = []
			for e in InputMap.action_get_events(action):
				if e is InputEventKey:
					var k := OS.get_keycode_string(e.physical_keycode)
					keys.append(KEY_NAMES.get(k, k))
				elif e is InputEventJoypadButton:
					pads.append(PAD_NAMES.get(e.button_index, "?"))
			assert(game.PROMPTS[action][0] in keys, "%s's key prompt is one of its keys %s" % [action, keys])
			assert(game.PROMPTS[action][1] in pads, "%s's pad prompt is its button %s" % [action, pads])
		var b := InputEventJoypadButton.new()
		b.button_index = JOY_BUTTON_A
		b.pressed = true
		Input.parse_input_event(b)
	elif _frame == 5:
		var game: Node = root.get_node("Game")
		assert(game.pad and game.key("interact") == "(A)", "a pad press switches prompts to pad buttons")
		var k := InputEventKey.new()
		k.physical_keycode = KEY_E
		k.pressed = true
		Input.parse_input_event(k)
	elif _frame == 7:
		var game: Node = root.get_node("Game")
		assert(not game.pad and game.key("interact") == "[E]", "a key press switches them back")
		print("PASS prompts")
		quit()
	return false
