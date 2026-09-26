# Heat and the police: crimes add heat by tier, assault calls the police with a visible
# countdown, and getting caught fines you (and costs a job slot for assault). A thrown
# stone through a window is a crime; one flung by the blades isn't. Paying the week cools it.
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
			g.heat = 0.0
			var house: Node2D = m.get_node("Scenery/House")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			m._on_stone_landed(f, "window")
			assert(g.heat == 0.0, "a stone flung by the blades through a window is an accident")
			f.thrown = true
			m._on_stone_landed(f, "window")
			assert(g.heat == 1.0 and m.police_left < 0.0, "thrown, it's a nuisance: +1 heat, nobody calls the police")
			f.free()
			m._knock_out()
			assert(g.heat == 3.0 and m.worst_crime == 2, "knocking them out is assault: +2")
			assert(m.police_left == g.police_time(0.0), "and the police are called, on a clock set by your record at the start")
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
			assert(g.heat == 4.0 and m.tally.get("robberies", 0) == 1, "robbery is its own crime: +1 heat, once")
			m.police_left = 0.01
			_wait = 2
		3:
			assert(m.over and paused, "caught")
			m._on_choice("nicked")
			var r: Dictionary = g.last_result
			assert(r.outcome == "nicked" and r.fine == g.fine(2, 4.0) and r.cells and not r.has("robbed"), "a fine for assault, a night in the cells, and the cash taken back")
			assert(r.net == -r.fine - r.fuel_cost, "the fine comes off, and nobody paid")
			# Get away with it and the cash is yours, at the worst rep hit in the game.
			m.robbed = 12.0
			m._finish(m.customer.ko_result(0.0))
			r = g.last_result
			assert(r.robbed == 12 and r.net == 12.0 and r.rep == -m.ROB_REP, "escaped: the lifted cash is yours, the rep hit is huge")
			# Ramming the customer's car dents it, harder hits cost more, and it's a nuisance.
			var car := StaticBody2D.new()
			m._car = car
			var bills: float = m.bills
			var heat: float = g.heat
			m._on_mower_bumped(car, 100.0)
			assert(m.bills == bills + m.CAR_BILL and g.heat == heat + 1.0, "a knock into the car dents it: $40, +1 heat")
			m._on_mower_bumped(car, 300.0)
			assert(m.bills == bills + m.CAR_BILL * 3.0, "a ride-on at full tilt costs double")
			car.free()
			# The run side: a night in the cells takes the next job slot; paying the week cools heat.
			g.new_run(3)
			g.heat = 3.0
			g.record_result({"outcome": "nicked", "net": -100, "paid": 0, "rep": -12.0, "cells": true})
			assert(g.jobs_done == 2, "the cells cost the next job slot")
			assert(g.money == -100, "the fine can put you in the red")
			g.money = 1000
			g.jobs_done = 3
			g.settle_payday()
			assert(g.heat == 2.0, "a week paid on time cools heat a level")
			assert(g.police_time(3.0) < g.police_time(0.0) and g.fine(1, 3.0) > g.fine(1, 0.0), "your record brings them faster and fines harder")
			print("PASS police")
			quit()
	_step += 1
	return false
