# The charge and the police: witnessed crimes go on the job's charge by tier, assault
# calls the police with a visible countdown, and getting caught means court tomorrow
# (test_season has the court). A thrown stone through a window is a crime; one flung by
# the blades isn't.
extends SceneTree

var m: Node
var g: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.charge = 0.0
			var house: Node2D = m.get_node("Scenery/House")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			m._on_stone_landed(f, "window")
			assert(m.charge == 0.0, "a stone flung by the blades through a window is an accident")
			f.thrown = true
			m._on_stone_landed(f, "window")
			assert(m.charge == 1.0 and m.police_left < 0.0, "thrown, it's a nuisance: +1, nobody calls the police")
			f.free()
			m._knock_out()
			assert(m.charge == 3.0 and m.worst_crime == 2, "knocking them out is assault: +2")
			assert(m._wallet >= m.job.pay * 0.2 and m._wallet <= m.job.pay * 0.6, "unpaid, their pockets hold 20 to 60% of the pay")
			assert(m.police_left == g.police_time(0.0), "and the police are called, on a clock set by your record at the start")
			assert(not m.customer.fired, "out cold, they can't fire you")
			_wait = 30
		1:
			assert(m.police_left < g.police_time(0.0), "the countdown runs")
			assert(m.hud.get_node("Police").text == "POLICE 1:00", "and shows (59.5 s rounds up)")
			# Rifle their pockets: hold interact over them.
			m.hop_off()
			m.walker.global_position = m.get_node("Client").position + Vector2(0, 10)
			Input.action_press("interact")
			_wait = 60
		2:
			Input.action_release("interact")
			assert(absf(m.robbed - m.RIFLE_RATE) < 0.5, "a second's rifling lifts a few dollars")
			assert(m.charge == 4.0 and m.tally.get("robberies", 0) == 1, "robbery is its own crime: +1, once")
			m.police_left = 0.01
			_wait = 2
		3:
			assert(m.over and paused, "caught")
			m._on_choice("nicked")
			var r: Dictionary = g.last_result
			assert(r.outcome == "nicked" and r.charge == 4.0 and r.tier == 2 and r.police and not r.has("robbed"), "the charge for court, and the cash taken back")
			assert(r.net == -r.fuel_cost, "no fine at the scene: that's for court")
			# Get away with it and the cash is yours, at the worst rep hit in the game.
			m.robbed = 12.0
			m._finish(m.customer.ko_result(0.0))
			r = g.last_result
			assert(r.robbed == 12 and r.net == 12.0 and r.rep == -m.ROB_REP, "escaped: the lifted cash is yours, the rep hit is huge")
			# Ramming the customer's car dents it and harder hits cost more; only a ram at speed is a crime.
			var car := StaticBody2D.new()
			m._car = car
			var bills: float = m.bills
			var charge: float = m.charge
			m._on_mower_bumped(car, 100.0)
			assert(m.bills == bills + m.CAR_BILL and m.charge == charge, "a knock into the car dents it: $40, an accident, no charge")
			m._on_mower_bumped(car, 300.0)
			assert(m.bills == bills + m.CAR_BILL * 3.0 and m.charge == charge + 1.0, "a ride-on at full tilt costs double, and it's a nuisance: +1")
			car.free()
			assert(g.police_time(3.0) < g.police_time(0.0) and g.fine(1, 3.0) > g.fine(1, 0.0), "your record brings them faster and fines harder")
			m.settled = {"outcome": "paid"}
			m._knock_out()
			assert(m._wallet <= m.job.pay * 0.2, "once they've paid you, small change")
			# Awake and ringing the police, they're done with you: fired there and then.
			m.customer.knocked_out = false
			m.police_left = -1.0
			m._call_police()
			assert(m.customer.fired and m.customer.fire_line.ends_with("called the police!"), "ringing the police fires you")
			print("PASS police")
			quit()
	_step += 1
	return false
