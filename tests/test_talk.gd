# Talking to the customer: walk up to them (or knock, if they're in) to ask to be paid
# or how it's going; the answer includes what they asked for, as does the pause menu.
# The truck is for leaving.
extends SceneTree

var m: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	root.get_node("Game").save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


## Every label and button text in the open menu.
func _menu() -> String:
	var out := []
	for n in m.hud._panel.find_children("*", "", true, false): # the open one: a closed panel lingers till freed
		if n is Label or n is Button:
			out.append(n.text)
	return " | ".join(out)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.hop_off()
			m.walker.global_position = m.get_node("Client").position + Vector2(0, 20)
			m.customer.where = "inside"
			_wait = 2
		1:
			assert(m.near_customer() and m._hint().contains("talk to"), "walk up and the hint offers a word")
			m.interact()
			assert(m.hud.is_open() and m.customer.where == "patio", "knock, and they come out to talk")
			var menu := _menu()
			assert(menu.contains("Ask to be paid") and menu.contains("How am I doing?"), "ask for pay, or how it's going: " + menu)
			m._on_choice("status")
			menu = _menu()
			assert(menu.contains("said:") and menu.contains("Wants it:") and menu.contains("Mowed:"), "their answer says what they asked for: " + menu)
			m._on_choice("resume")
			m.open_truck_menu()
			assert(not _menu().contains("Ask to be paid") and _menu().contains("Drive off"), "the truck is for leaving")
			m._on_choice("resume")
			m.open_pause()
			assert(_menu().contains("Wants it:"), "the pause menu reminds you too")
			m._on_choice("resume")
			var lawn: Lawn = m.get_node("Lawn")
			for y in range(0, 720, 20):
				lawn.cut_segment(Vector2(0, y), Vector2(1280, y), 20.0)
			m.interact()
			m._on_choice("handin")
			assert(not m.settled.is_empty() and m.settled.paid > 0 and _menu().contains("hand over"), "paid, face to face")
			assert(not _menu().contains("Ask to be paid"), "and not twice")
			print("PASS talk")
			quit()
	_step += 1
	return false
