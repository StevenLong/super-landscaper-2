# Each mower's feel (NOTES 109, 110; design doc Mowers and Equipment). The petrol mower
# starts by ripcord: hold the throttle to draw it while a marker sweeps, let go in the
# sweet spot and it catches; outside it, a cough and a second lost; the worse its
# condition, the narrower the spot; in poor condition a knock can stall it. The ride-on
# has four gears: each a top speed, higher ones turning wider.
extends SceneTree

var m: Node
var mower: CharacterBody2D
var g: Node
var _step := 0
var _wait := 0
var _fuel := 0.0


func _initialize() -> void:
	g = root.get_node("Game")
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	_wait = 2


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			mower = m.mower
			mower.apply_spec(g.MOWERS.petrol)
			mower.global_position = Vector2(400, 650)
			mower.rotation = -PI / 2.0
			assert(mower.engine_off, "a petrol mower starts by hand each job")
			assert(m._hint().contains("pull the cord"), "and the hint says how")
			var good: Vector2 = mower.sweet()
			mower.condition = 30.0
			assert(mower.sweet().y - mower.sweet().x < good.y - good.x, "in worse condition the sweet spot is narrower")
			mower.condition = 100.0
			_fuel = mower.fuel
			Input.action_press("move_forward")
			_wait = int(mower.PULL_TIME * 60.0 * 0.3) # let go too early
		1:
			assert(mower.velocity.length() < 1.0 and mower.pull > 0.0, "drawing the cord, it doesn't move")
			Input.action_release("move_forward")
			_wait = 2
		2:
			assert(mower.engine_off and mower._cough > 0.0, "let go outside the green: a cough")
			assert(mower.fuel == _fuel, "an engine that isn't going burns nothing")
			_wait = int(mower.COUGH * 60.0) + 2
		3:
			Input.action_press("move_forward")
			_wait = int(mower.PULL_TIME * 60.0 * (mower.sweet().x + mower.sweet().y) * 0.5) # into the green
		4:
			Input.action_release("move_forward")
			_wait = 2
		5:
			assert(not mower.engine_off, "let go in the green: it catches")
			Input.action_press("move_forward")
			_wait = 30
		6:
			assert(mower.velocity.length() > 100.0, "and drives")
			Input.action_release("move_forward")
			mower.condition = 80.0
			mower.stall_check(0.0)
			assert(not mower.engine_off, "in good condition a knock doesn't stall it")
			mower.condition = 30.0
			mower.stall_check(0.9)
			assert(not mower.engine_off, "in poor condition, not every knock...")
			mower.stall_check(0.1)
			assert(mower.engine_off, "...but one can, and it needs the cord again")
			# The ride-on: two gears to start, a third and fourth as upgrades.
			g.upgrades.erase("gear3")
			g.upgrades.erase("gear4")
			assert(g.mower_spec("rideon").gears == 2 and not g.buy("gear4"), "two gears, and no fourth before the third")
			g.money = 1000
			assert(g.buy("gear3") and g.mower_spec("rideon").gears == 3, "the third")
			assert(g.buy("gear4") and g.mower_spec("rideon").gears == 4, "then the fourth")
			var cash: int = g.money
			g.sell("gear3")
			assert(not "gear4" in g.upgrades and g.money == cash + g.resale("gear3") + g.resale("gear4"), "selling the third sells the fourth with it")
			g.buy("gear3")
			g.upgrades.erase("gear4")
			mower.apply_spec(g.mower_spec("rideon")) # with the third gear, above
			mower.condition = 100.0
			mower.global_position = Vector2(640, 650)
			mower.rotation = -PI / 2.0
			mower.velocity = Vector2.ZERO
			assert(mower.engine_off and mower.gear == 1 and m._hint().contains("turn the key"), "a ride-on starts on the key, in first")
			m.interact()
			assert(not mower.engine_off, "interact turns the key")
			Input.action_press("move_forward")
			_wait = 60
		7:
			assert(absf(mower.velocity.length() - mower.max_speed * mower.GEARS[0]) < 2.0, "first gear's top speed: %.0f" % mower.velocity.length())
			Input.action_press("gear_up")
			_wait = 1
		8:
			Input.action_release("gear_up")
			assert(mower.gear == 2, "up a gear")
			_wait = 1
		9:
			Input.action_press("gear_up")
			_wait = 1
		10:
			Input.action_release("gear_up")
			assert(mower.gear == 3 and m._hint().contains("Gear 3"), "and another (bought), shown in the hint")
			_wait = 60
		11:
			assert(absf(mower.velocity.length() - mower.max_speed * mower.GEARS[2]) < 2.0, "third gear's faster: %.0f" % mower.velocity.length())
			Input.action_press("turn_right")
			_wait = 10
		12:
			Input.action_release("turn_right")
			Input.action_release("move_forward")
			assert(mower.GEAR_TURN[2] < mower.GEAR_TURN[0], "higher gears turn wider")
			Input.action_press("gear_down")
			_wait = 1
		13:
			Input.action_release("gear_down")
			assert(mower.gear == 2, "and down again")
			# Switched off, a powered mower burns nothing; the petrol needs its cord again.
			_fuel = mower.fuel
			m.interact()
			assert(mower.engine_off, "interact switches it off")
			_wait = 30
		14:
			assert(mower.fuel == _fuel, "off, it burns no fuel")
			m.interact()
			assert(not mower.engine_off, "and the key turns it back on")
			mower.apply_spec(g.MOWERS.petrol)
			mower.engine_off = false
			m.interact()
			assert(mower.engine_off and m._hint().contains("pull the cord"), "the petrol switches off, and wants the cord again")
			m.interact()
			assert(mower.engine_off, "interact doesn't start a petrol: the cord does")
			print("PASS mower feel")
			quit()
	_step += 1
	return false
