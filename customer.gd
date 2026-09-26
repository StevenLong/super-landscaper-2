class_name Customer
extends RefCounted
## The customer's hidden mood for one job, and how they pay. Pure logic: the job
## scene feeds it events and reads face() and evaluate().

const GLANCES := [0.75, 0.9] ## shares of their patience at which they glance at their watch
## Nags past their patience escalate with their mood: [mood at or above, face, lines].
const NAGS := [[40.0, "annoyed", ["Any time now...", "Are we nearly there?"]],
	[20.0, "annoyed", ["Tick tock!", "I haven't got all day!"]],
	[0.0, "furious", ["Last warning. Finish up or you're done."]]]
const TIERS := [[80.0, "delighted"], [60.0, "happy"], [40.0, "neutral"], [20.0, "annoyed"], [0.0, "furious"]]

var job: Dictionary
var persona: Dictionary
var mood := 60.0
var fired := false
var knocked_out := false ## out cold: nobody can pay you, and nobody can fire you
var fire_line := ""
var flowers_flat := 0
var coverage := 0.0
var elapsed := 0.0
var last_line := ""
var paid := false ## once paid they stop watching the clock

var where := "patio" ## "patio" watching, "inside" (sees nothing), or at a "window" (sees it all)
var window_x := -1 ## which window (house.gd windows()) while at one
var windows: Array = [40, 120, 290, 370] ## main sets the building's
var nags := 0 ## the first comes as the tip goes, with a sigh
var _nag_at := 0.0
var _glances := 0
var _stint := 0.0 ## seconds until they move
var _unseen: Array[Callable] = [] ## what they missed, replayed when they come out and see what's left
var _unseen_what: Array[String] = []
var _unseen_flowers := 0

var _react_face := ""
var _react_left := 0.0


func _init(job_data: Dictionary) -> void:
	job = job_data
	persona = Game.PERSONAS[job.persona]
	mood = persona.get("start_mood", 60.0)
	_stint = randf_range(20.0, 35.0)


## Can they see the garden right now? From the patio or a window, yes; indoors, no.
func sees() -> bool:
	return where != "inside" and not knocked_out


## Share of the job they spend indoors or at a window: the fusspot hardly goes in.
func indoors() -> float:
	return job.get("indoors", persona.get("indoors", 0.3))


## Out onto the patio, and a look at what's left: anything they missed gets an itemised
## meltdown (or, for the squirrel hater, delight). Returns true if they had something to say.
func come_out() -> bool:
	if where == "patio":
		return false
	where = "patio"
	window_x = -1
	_stint = randf_range(15.0, 30.0)
	return _look_around()


func _look_around() -> bool:
	if _unseen.is_empty() and _unseen_flowers <= flowers_flat:
		return false
	var before := mood
	var what := _unseen_what.duplicate()
	for f in _unseen:
		f.call()
	_unseen.clear()
	_unseen_what.clear()
	if _unseen_flowers > flowers_flat:
		on_flowers(_unseen_flowers)
		what.append("my flowers")
	if fired:
		return true # the evidence finished it: on_flowers or the mood said so
	if mood >= before:
		_react("laughing", 2.0, "Ha! Somebody got %s!" % " and ".join(what))
	else:
		_react("horrified", 3.0, "What happened to %s?!" % ", ".join(what))
	return true

## The expression to show right now: a short reaction if one is playing, else the mood tier.
func face() -> String:
	if knocked_out:
		return "ko"
	if _react_left > 0.0:
		return _react_face
	if fired:
		return "fired"
	for t: Array in TIERS:
		if mood >= t[0]:
			return t[1]
	return "furious"


## Returns a line to say if they've something to say about the time.
func tick(delta: float) -> String:
	elapsed += delta
	_react_left -= delta
	if knocked_out:
		return ""
	if fired or paid: # settled: they come out and watch you leave
		return last_line if come_out() else ""
	_stint -= delta
	if _stint <= 0.0 and _move():
		return last_line
	# Patience running low: a glance at the watch, no words (waits out any reaction).
	if _glances < GLANCES.size() and elapsed >= job.patience * GLANCES[_glances] and _react_left <= 0.0:
		_glances += 1
		_react_face = "watch"
		_react_left = 1.5
	if elapsed > job.patience:
		_change(-0.35 * delta) # waiting past their patience wears them down, slowly
		if elapsed >= _nag_at:
			_nag_at = elapsed + 25.0
			nags += 1
			if nags == 1:
				_react("annoyed", 1.5, "Are you nearly done?")
			else:
				for n: Array in NAGS:
					if mood >= n[0]:
						_react(n[1], 1.5, n[2][randi() % n[2].size()])
						break
			return last_line
	return ""


## Time for a change of scene: in for a cup of tea, back out, or peering from a window.
## Returns true if they came out to something worth a word.
func _move() -> bool:
	var going_in := randf() < indoors()
	if where == "patio":
		if not going_in:
			_stint = randf_range(15.0, 30.0)
			return false
		where = "inside"
		_stint = randf_range(10.0, 25.0)
		return false
	if going_in and randf() < 0.5:
		where = "window" if where == "inside" else "inside"
		window_x = windows[randi() % windows.size()] if where == "window" else -1
		_stint = randf_range(8.0, 15.0)
		return where == "window" and _look_around()
	return come_out()


func on_progress(new_coverage: float) -> void:
	if new_coverage > coverage:
		_change((new_coverage - coverage) * 30.0)
		coverage = new_coverage


## Returns true if they saw it (the scene reacts); unseen, the splat waits for them.
func on_squash(kind: String) -> bool:
	if not sees():
		_unseen.append(on_squash.bind(kind))
		_unseen_what.append("the " + kind)
		return false
	var d: float = persona.get(kind, -20.0)
	_change(d)
	if d > 0.0:
		_react("laughing", 2.0, "Ha! Good riddance!")
	elif d <= -30.0:
		_react("horrified", 2.5, "NO! Not the %s!" % kind)
	else:
		_react("annoyed", 1.5, "Oi! Watch it!")
	return true


## Returns true if this was news (newly flattened flowers), so the scene can react.
func on_flowers(total_flat: int) -> bool:
	if not sees():
		_unseen_flowers = maxi(_unseen_flowers, total_flat)
		return false
	var fresh := total_flat - flowers_flat
	if fresh <= 0:
		return false
	flowers_flat = total_flat
	if fired:
		_react("horrified", 2.0, ["Stop that!", "Get OFF my lawn!", "Vandal!"][randi() % 3])
		return true
	var limit: int = persona.get("instant_flowers", 0)
	if limit > 0 and total_flat >= limit:
		fire("My FLOWERS! Get off my property!")
		return true
	_change(persona.flower * fresh)
	_react("horrified" if limit > 0 else "annoyed", 1.5, "Mind the flowers!")
	return true


## A flung stone (or worse) lands on something of theirs. Returns true if it knocked them out.
func on_stone(target: String) -> bool:
	if not sees():
		if target == "wall":
			return false # a thud, nothing to see
		come_out() # glass breaking, a clonk on the car, the dog yelping: they're out at once
	match target:
		"customer":
			_change(-35.0)
			if randf() < 0.35 or mood < 25.0:
				knock_out()
				return true
			_react("hurt", 3.0, "OW! My EYE!")
		"window":
			_change(-25.0)
			_react("horrified", 2.5, "My WINDOW!")
		"car":
			_change(-20.0)
			_react("horrified", 2.5, "My CAR!")
		"wall":
			_change(-5.0)
			_react("annoyed", 1.5, "Careful!")
		"dog":
			_change(-40.0)
			_react("horrified", 2.5, "You hit %s!" % job.get("dog_name", "the dog"))
	return false


## Something of theirs wrecked (a gnome, the hose, a spill on the lawn). Returns true if
## they saw it; unseen, what's left of it waits for them.
func on_property(what: String, d: float) -> bool:
	if not sees():
		_unseen.append(on_property.bind(what, d))
		_unseen_what.append("my " + what)
		return false
	_change(d)
	_react("horrified", 2.0, "My %s!" % what.to_upper())
	return true


func knock_out() -> void:
	knocked_out = true
	last_line = "..."


func on_dog_hit() -> void:
	if not sees():
		come_out() # the yelp brings them out
	_change(-60.0)
	_react("horrified", 3.0, "%s! NO!" % job.get("dog_name", "My dog"))


## Returns true if they saw it.
func on_dog_returned() -> bool:
	if not sees():
		return false
	_change(10.0)
	_react("delighted", 2.0, "Oh, thank you! Bad %s!" % job.get("dog_name", "dog"))
	return true


func fire(line: String) -> void:
	if fired or knocked_out:
		return
	fired = true
	mood = 0.0
	fire_line = line
	last_line = line


func _change(d: float) -> void:
	if knocked_out:
		return
	mood = clampf(mood + d, 0.0, 100.0)
	if mood <= 0.0:
		fire("That's it. You're fired!")


## Fired you or not, they still react to what you do next (that's the fun of spite).
func _react(face_name: String, seconds: float, line: String) -> void:
	if knocked_out:
		return
	_react_face = face_name
	_react_left = seconds
	last_line = line


## Whether they'll accept the job as done. Under 60% of what they wanted, they
## send you back out.
func accepts(cov: float) -> bool:
	return cov >= job.target * 0.6


## What they pay and how it lands on your reputation, itemised for the board's rundown.
func evaluate(cov: float, fuel_cost: float) -> Dictionary:
	var target: float = job.target
	var patience: float = job.patience
	var quality := 1.0 if cov >= target else pow(cov / target, 2.0)
	var time_f := 1.0 if elapsed <= patience else maxf(0.4, 1.0 - (elapsed - patience) / patience)
	var mood_f := 0.5 + mood / 100.0
	var base: float = job.pay
	var pay := int(round(base * quality * time_f * mood_f))
	var tip := int(round(base * 0.25)) if (cov >= target and elapsed <= patience and mood >= 75.0) else 0
	var rep := (mood - 50.0) / 5.0 + (2.0 if cov >= target else -3.0)
	var comment := "Lovely job. Thank you!" if mood >= 75.0 else ("That'll do." if mood >= 45.0 else "Hmph. Take your money and go.")
	return {
		"outcome": "paid", "coverage": cov, "target_met": cov >= target,
		"elapsed": elapsed, "on_time": elapsed <= patience, "mood": mood,
		"paid": pay + tip, "tip": tip, "fuel_cost": fuel_cost,
		"net": pay + tip - fuel_cost, "rep": rep, "comment": comment,
	}


func fired_result(fuel_cost: float) -> Dictionary:
	return {
		"outcome": "fired", "coverage": coverage, "target_met": false,
		"elapsed": elapsed, "on_time": false, "mood": 0.0,
		"paid": 0, "tip": 0, "fuel_cost": fuel_cost, "net": -fuel_cost,
		"rep": -18.0, "comment": fire_line,
	}


## Out cold: nobody pays, but nobody conscious saw enough to hurt your reputation.
func ko_result(fuel_cost: float) -> Dictionary:
	return {
		"outcome": "ko", "coverage": coverage, "target_met": false,
		"elapsed": elapsed, "on_time": false, "mood": 0.0,
		"paid": 0, "tip": 0, "fuel_cost": fuel_cost, "net": -fuel_cost,
		"rep": 0.0, "comment": "(They're out cold. Nobody is paying you today.)",
	}


func walked_result(fuel_cost: float) -> Dictionary:
	return {
		"outcome": "walked", "coverage": coverage, "target_met": false,
		"elapsed": elapsed, "on_time": false, "mood": mood,
		"paid": 0, "tip": 0, "fuel_cost": fuel_cost, "net": -fuel_cost,
		"rep": -12.0, "comment": "Where are you going?! Come back here!",
	}
