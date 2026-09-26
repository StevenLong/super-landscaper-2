# Charged throws: holding throw locks you in place, turns the aim and fills the power;
# letting go throws that far; hop cancels and keeps the stone.
extends SceneTree

var m: Node
var _step := 0
var _wait := 0
var _at := Vector2.ZERO
var _aim0 := 0.0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.action_press(action)
	m._unhandled_input(ev)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.hop_off()
			m.walker.carrying = "stone"
			m.walker.global_position = Vector2(500, 400) # open grass, as in test_hazards
			m.walker.rotation = -PI / 2.0
			_wait = 2
		1:
			_at = m.walker.global_position
			_aim0 = m.walker.rotation
			_press("throw")
			assert(m.walker.aiming, "holding throw winds up")
			Input.action_press("turn_right")
			Input.action_press("move_forward")
			_wait = 30
		2:
			assert(m.walker.global_position == _at, "locked in place while aiming")
			assert(m.walker.rotation > _aim0 + 0.5, "right turns the aim")
			assert(m.walker.power > 0.4 and m.walker.power < 0.6, "power fills over about a second")
			assert(m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone).is_empty(), "nothing thrown yet")
			_wait = 60
		3:
			assert(m.walker.power == 1.0, "power stops at max")
			Input.action_release("turn_right")
			Input.action_release("move_forward")
			Input.action_release("throw")
			_wait = 1
		4:
			var flying: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone)
			assert(flying.size() == 1 and m.walker.carrying == "" and not m.walker.aiming, "letting go throws the stone")
			var f: FlyingStone = flying[0]
			assert(absf(f.velocity.angle() - m.walker.rotation) < 0.01, "along the aim")
			var landing: Vector2 = f.position + f.velocity.normalized() * f.range_left
			assert(absf(landing.distance_to(_at) - m.THROW_MAX) < 1.0, "a full wind-up lands at full reach, where the marker was")
			# Hop cancels the wind-up and you keep the stone.
			m.walker.carrying = "stone"
			_press("throw")
			var cancel := InputEventAction.new()
			cancel.action = "hop"
			cancel.pressed = true
			m._unhandled_input(cancel)
			assert(not m.walker.aiming and m.walker.carrying == "stone" and m.walker != null, "hop cancels, stone still in hand")
			Input.action_release("throw")
			_wait = 2
		5:
			assert(m.walker.carrying == "stone", "letting go after a cancel throws nothing")
			print("PASS throw")
			quit()
	_step += 1
	return false
