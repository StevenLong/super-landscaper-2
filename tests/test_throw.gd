# Charged throws: holding throw locks you in place, left/right turn the aim, up/down tilt
# it, power fills; letting go throws in an arc that lands where the marker was; hop
# cancels and keeps the stone; straight up comes down on your head.
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
			assert(m.walker.pitch > 0.8, "up tilts it up")
			assert(m.walker.power > 0.4 and m.walker.power < 0.6, "power fills over about a second")
			assert(m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone).is_empty(), "nothing thrown yet")
			_wait = 60
		3:
			assert(m.walker.power == 1.0, "power stops at max")
			m.walker.pitch = PI / 4.0
			Input.action_release("turn_right")
			Input.action_release("move_forward")
			Input.action_release("throw")
			_wait = 1
		4:
			var flying: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone)
			assert(flying.size() == 1 and m.walker.carrying == "" and not m.walker.aiming, "letting go throws the stone")
			var f: FlyingStone = flying[0]
			assert(absf(f.velocity.angle() - m.walker.rotation) < 0.01 and f.vz > 0.0, "along the aim, and up")
			var reach: float = m._throw_reach(1.0)
			assert(absf(f.landing().distance_to(_at) - reach) < 1.0, "it comes down where the marker was")
			assert(reach > m.THROW_MAX and reach < m.THROW_MAX + 40.0, "a full wind-up at 45 degrees carries full reach")
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
			# Straight up, a tap: it comes down on your head.
			m.walker.pitch = m.walker.PITCH_MAX
			_press("throw")
			Input.action_release("throw")
			_wait = 90
		6:
			assert(m.tally.get("own_head", 0) == 1 and m.walker.dazed > 0.0, "what goes up comes down on your head")
			# A squirrel thrown out of the garden, landing where they can't see: they react
			# only if they watched it leave your hand.
			m.customer.where = "patio"
			var f := FlyingStone.new()
			f.kind = "squirrel"
			f.thrown = true
			f.position = Vector2(-3000, -3000) # well out of sight
			var mood: float = m.customer.mood
			m._on_stone_landed(f, "gone")
			assert(m.customer.mood == mood, "unseen throw, unseen landing: nothing")
			f.throw_seen = true
			m._on_stone_landed(f, "gone")
			assert(m.customer.mood != mood, "they saw you throw it: that's enough")
			f.free()
			print("PASS throw")
			quit()
	_step += 1
	return false
