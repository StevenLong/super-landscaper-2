# The ride-on's horn (H): critters near it turn and run, twice as fast; ones further off
# and anything out cold don't stir. Only on the ride-on, sat on it.
extends SceneTree

var m: Node
var _frame := 0
var _step := 0
var _near: Animal
var _far: Animal
var _cold: Animal


func _initialize() -> void:
	var g := root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	match _step:
		0:
			m._on_choice("start")
			m.hud.close()
			m.get_tree().paused = false
			m.mower.apply_spec(root.get_node("Game").mower_spec("rideon"))
			var at: Vector2 = m.lawn.global_position + Vector2(m.lawn.size_px) / 2.0
			m.mower.global_position = at
			_near = m.spawn_animal("hedgehog", at + Vector2(80, 0), at + Vector2(80, -100)) # heading up, past it
			_far = m.spawn_animal("squirrel", at + Vector2(-300, 0), at + Vector2(-300, -100))
			_cold = m.spawn_animal("hedgehog", at + Vector2(0, 90), at + Vector2(0, 0))
			_cold.stun(10.0)
			Input.action_press("horn") # through the real key binding
		1:
			Input.action_release("horn")
			assert(_near.scared > 0.0 and _near.heading.dot(Vector2.RIGHT) > 0.9, "near: away from the mower, at a run")
			assert(_far.scared == 0.0, "far off: not bothered")
			assert(_cold.scared == 0.0, "out cold: can't run")
			assert(m._horn_cool > 0.0, "it honked")
			# On foot, no horn.
			m.hop_off()
			m._horn_cool = 0.0
			_near.scared = 0.0
			Input.action_press("horn")
		2:
			Input.action_release("horn")
			assert(_near.scared == 0.0 and m._horn_cool == 0.0, "on foot: no horn")
			print("PASS horn")
			quit()
	_step += 1
	return false
