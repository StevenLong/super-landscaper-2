class_name Customer
extends RefCounted
## The customer's hidden mood for one job, and how they pay. Pure logic: the job
## scene feeds it events and reads face() and evaluate().

const TIERS := [[80.0, "delighted"], [60.0, "happy"], [40.0, "neutral"], [20.0, "annoyed"], [0.0, "furious"]]

var job: Dictionary
var persona: Dictionary
var mood := 60.0
var fired := false
var fire_line := ""
var flowers_flat := 0
var coverage := 0.0
var elapsed := 0.0
var last_line := ""

var _react_face := ""
var _react_left := 0.0


func _init(job_data: Dictionary) -> void:
	job = job_data
	persona = Game.PERSONAS[job.persona]
	mood = persona.get("start_mood", 60.0)


## The expression to show right now: a short reaction if one is playing, else the mood tier.
func face() -> String:
	if fired:
		return "fired"
	if _react_left > 0.0:
		return _react_face
	for t: Array in TIERS:
		if mood >= t[0]:
			return t[1]
	return "furious"


func tick(delta: float) -> void:
	elapsed += delta
	_react_left -= delta
	if elapsed > job.patience and not fired:
		_change(-1.0 * delta) # waiting past their patience wears them down


func on_progress(new_coverage: float) -> void:
	if new_coverage > coverage:
		_change((new_coverage - coverage) * 30.0)
		coverage = new_coverage


func on_squash(kind: String) -> void:
	var d: float = persona.get(kind, -20.0)
	_change(d)
	if d > 0.0:
		_react("laughing", 2.0, "Ha! Good riddance!")
	elif d <= -30.0:
		_react("horrified", 2.5, "NO! Not the %s!" % kind)
	else:
		_react("annoyed", 1.5, "Oi! Watch it!")


## Returns true if this was news (newly flattened flowers), so the scene can react.
func on_flowers(total_flat: int) -> bool:
	var fresh := total_flat - flowers_flat
	if fresh <= 0:
		return false
	flowers_flat = total_flat
	var limit: int = persona.get("instant_flowers", 0)
	if limit > 0 and total_flat >= limit:
		fire("My FLOWERS! Get off my property!")
		return true
	_change(persona.flower * fresh)
	_react("horrified" if limit > 0 else "annoyed", 1.5, "Mind the flowers!")
	return true


func fire(line: String) -> void:
	if fired:
		return
	fired = true
	mood = 0.0
	fire_line = line
	last_line = line


func _change(d: float) -> void:
	mood = clampf(mood + d, 0.0, 100.0)
	if mood <= 0.0:
		fire("That's it. You're fired!")


func _react(face_name: String, seconds: float, line: String) -> void:
	if fired:
		return
	_react_face = face_name
	_react_left = seconds
	last_line = line


## Whether they'll accept the job as done. Under 60% of what they wanted, they
## send you back out.
func accepts(cov: float) -> bool:
	return cov >= job.target * 0.6


## What they pay and how it lands on your reputation, itemised for the pay screen.
func evaluate(cov: float, fuel_cost: float) -> Dictionary:
	var target: float = job.target
	var patience: float = job.patience
	var quality := 1.0 if cov >= target else pow(cov / target, 2.0)
	var time_f := 1.0 if elapsed <= patience else maxf(0.4, 1.0 - (elapsed - patience) / patience)
	var mood_f := 0.5 + mood / 100.0
	var base: float = job.pay
	var paid := int(round(base * quality * time_f * mood_f))
	var tip := int(round(base * 0.25)) if (cov >= target and elapsed <= patience and mood >= 75.0) else 0
	var rep := (mood - 50.0) / 5.0 + (2.0 if cov >= target else -3.0)
	var comment := "Lovely job. Thank you!" if mood >= 75.0 else ("That'll do." if mood >= 45.0 else "Hmph. Take your money and go.")
	return {
		"outcome": "paid", "coverage": cov, "target_met": cov >= target,
		"elapsed": elapsed, "on_time": elapsed <= patience, "mood": mood,
		"paid": paid + tip, "tip": tip, "fuel_cost": fuel_cost,
		"net": paid + tip - fuel_cost, "rep": rep, "comment": comment,
	}


func fired_result(fuel_cost: float) -> Dictionary:
	return {
		"outcome": "fired", "coverage": coverage, "target_met": false,
		"elapsed": elapsed, "on_time": false, "mood": 0.0,
		"paid": 0, "tip": 0, "fuel_cost": fuel_cost, "net": -fuel_cost,
		"rep": -18.0, "comment": fire_line,
	}


func walked_result(fuel_cost: float) -> Dictionary:
	return {
		"outcome": "walked", "coverage": coverage, "target_met": false,
		"elapsed": elapsed, "on_time": false, "mood": mood,
		"paid": 0, "tip": 0, "fuel_cost": fuel_cost, "net": -fuel_cost,
		"rep": -12.0, "comment": "Where are you going?! Come back here!",
	}
