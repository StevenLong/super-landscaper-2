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

var where := "patio" ## "patio" watching, "inside" (sees nothing), or at a "window" (a cone out of it)
var window_x := -1 ## which window (house.gd windows()) while at one
var windows: Array = [40, 120, 290, 370] ## main sets the building's
var door_x := 205.0 ## main sets it: the front door, along the front the way windows are
const STROLL := 70.0 ## px/s indoors, walking past the windows to another (or to the door)
var stroll_from := 0.0 ## an indoor walk along the front, unseen but glimpsed through the glass
var stroll_to := 0.0
var _stroll_time := 0.0
var _stroll_left := 0.0
var _stroll_then := "" ## "window" or "patio" when it ends
var _at_x := 205.0 ## where along the front they last were indoors
var nags := 0 ## the first comes as the tip goes, with a sigh
var _nag_at := 0.0
var _glances := 0
var _stint := 0.0 ## seconds until they move
var sight := Callable() ## main: can they see this point from where they are? (unset: all of it)
var _owned: Array = [] ## their things wrecked out of sight, [what, mood]: found after you've gone
var _unseen_flowers := 0 ## flattened out of sight: found after you've gone

var _react_face := ""
var _react_left := 0.0


func _init(job_data: Dictionary) -> void:
	job = job_data
	persona = Game.PERSONAS[job.persona]
	mood = job.get("start_mood", persona.get("start_mood", 60.0)) # a regular brings their carried mood
	elapsed = job.get("late", 0.0) # turned up partway through their window: that much of their patience gone
	_stint = randf_range(20.0, 35.0)


## Can they see what happens at `at` (design doc, The Customer: line of sight)? Indoors,
## nothing; outside or at a window, whatever's in their line of sight (main's `sight`).
## With no point, whether they're looking at all.
func sees(at := Vector2.INF) -> bool:
	if where == "inside" or knocked_out:
		return false
	return at == Vector2.INF or not sight.is_valid() or sight.call(at)


## Share of the job they spend indoors or at a window: the fusspot hardly goes in.
func indoors() -> float:
	return job.get("indoors", persona.get("indoors", 0.3))


## Out onto the patio. Nothing is found just by stepping out: what they didn't see
## happen, they don't know about until you've gone (aftermath()).
func come_out() -> void:
	_stroll_left = 0.0 # something brings them straight out
	if where == "patio":
		return
	where = "patio"
	window_x = -1
	_stint = randf_range(15.0, 30.0)


## What they find after you've gone, by ownership (design doc, The Customer): their own
## things wrecked out of sight, and whatever main found lying in view (bodies, {kind: n}).
## Reputation only, the money's settled. Each entry is [what, reputation].
func aftermath(bodies: Dictionary, all_cut: bool) -> Array:
	var out: Array = []
	for o: Array in _owned:
		out.append(["Their %s, ruined" % o[0], o[1] / 5.0])
	if _unseen_flowers > 0:
		out.append(["%d of their flowers flattened" % _unseen_flowers, persona.flower * _unseen_flowers / 5.0])
	for kind: String in bodies:
		var n: int = bodies[kind]
		out.append([("A dead %s on the lawn" % kind) if n == 1 else ("%d dead %ss on the lawn" % [n, kind]),
			persona.get(kind, -20.0) * n / 5.0])
	if all_cut:
		out.append(["Every blade cut", 2.0])
	return out

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
		come_out()
		return ""
	if _stroll_left > 0.0:
		_stroll_left -= delta
		if _stroll_left <= 0.0:
			_at_x = stroll_to
			if _stroll_then == "window":
				where = "window"
				window_x = int(stroll_to)
			else:
				come_out()
	else:
		_stint -= delta
		if _stint <= 0.0:
			_move()
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
## Indoors they walk it, past the windows: to a window, or to the door and out.
func _move() -> void:
	var going_in := randf() < indoors()
	if where == "patio":
		_stint = randf_range(15.0, 30.0)
		if going_in:
			where = "inside"
			_at_x = door_x
			_stint = randf_range(10.0, 25.0)
		return
	_stint = randf_range(8.0, 15.0)
	if going_in and randf() < 0.5:
		if where == "inside":
			_stroll(windows[randi() % windows.size()], "window")
		else: # back from the glass, still in
			where = "inside"
			window_x = -1
		return
	_stroll(door_x, "patio")


func _stroll(to_x: float, then: String) -> void:
	where = "inside"
	window_x = -1
	stroll_from = _at_x
	stroll_to = to_x
	_stroll_time = maxf(0.5, absf(to_x - _at_x) / STROLL)
	_stroll_left = _stroll_time
	_stroll_then = then


## Mid-walk indoors, where along the front they are; -1 when they aren't walking.
func stroll_x() -> float:
	return lerpf(stroll_to, stroll_from, _stroll_left / _stroll_time) if _stroll_left > 0.0 else -1.0


func on_progress(new_coverage: float) -> void:
	if new_coverage > coverage:
		_change((new_coverage - coverage) * 30.0)
		coverage = new_coverage


## Returns true if they saw it happen at `at` (the scene reacts). Unseen, a critter isn't
## theirs: only a body left lying in view is found, after you've gone. `share` scales it:
## knocked out, not killed, counts for less.
func on_squash(kind: String, share := 1.0, at := Vector2.INF) -> bool:
	if not sees(at):
		return false
	var d: float = persona.get(kind, -20.0) * share
	_change(d)
	if share < 1.0 and d < 0.0:
		_react("annoyed", 2.0, _say("stunned", "Is it... breathing?"))
	elif d > 0.0:
		_react("laughing", 2.0, "Ha! Good riddance!")
	elif d <= -30.0:
		_react("horrified", 2.5, _say("squash", "NO! Not the %s!" % kind))
	else:
		_react("annoyed", 1.5, _say("squash", "Oi! Watch it!"))
	return true


## A critter thrown out over the boundary, seen at `at`: `share` of what its death would
## mean to them, glad or appalled. Returns true if they saw it.
func on_evict(kind: String, share: float, at := Vector2.INF) -> bool:
	if not sees(at):
		return false
	var d: float = persona.get(kind, -20.0) * share
	_change(d)
	if d > 0.0:
		_react("laughing", 2.0, _say("evict", "And STAY out!"))
	else:
		_react("horrified" if d <= -12.0 else "annoyed", 2.0, _say("evict_bad", "Don't THROW it!"))
	return true


## Returns true if this was news (newly flattened flowers, seen at `at`), so the scene can
## react. Unseen, they're theirs: found after you've gone.
func on_flowers(total_flat: int, at := Vector2.INF) -> bool:
	var fresh := total_flat - flowers_flat - _unseen_flowers
	if fresh <= 0:
		return false
	if not sees(at):
		_unseen_flowers += fresh
		return false
	flowers_flat += fresh
	if fired:
		_react("horrified", 2.0, ["Stop that!", "Get OFF my lawn!", "Vandal!"][randi() % 3])
		return true
	var limit: int = persona.get("instant_flowers", 0)
	if limit > 0 and total_flat >= limit:
		fire("My FLOWERS! Get off my property!")
		return true
	_change(persona.flower * fresh)
	_react("horrified" if limit > 0 else "annoyed", 1.5, _say("flowers", "Mind the flowers!"))
	return true


## A flung stone (or worse) lands on something of theirs at `at`. Returns true if it
## knocked them out. Noise brings them out: they hear it, so they know.
func on_stone(target: String, at := Vector2.INF) -> bool:
	if not sees(at):
		if target == "wall":
			return false # a thud, nothing to see
		come_out() # glass breaking, a clonk on the car, the dog yelping: they're out at once
	match target:
		"customer":
			_change(-35.0)
			if randf() < 0.35 or mood < 25.0:
				knock_out()
				return true
			_react("hurt", 3.0, _say("hit", "OW! My EYE!"))
		"window":
			_change(-25.0)
			_react("horrified", 2.5, _say("window", "My WINDOW!"))
		"car":
			_change(-20.0)
			_react("horrified", 2.5, _say("car", "My CAR!"))
		"wall":
			_change(-5.0)
			_react("annoyed", 1.5, "Careful!")
		"dog":
			_change(-40.0)
			_react("horrified", 2.5, "You hit %s!" % job.get("dog_name", "the dog"))
	return false


## Something of theirs wrecked at `at` (a gnome, the hose, a spill on the lawn). Returns
## true if they saw it; unseen, it's theirs, so it's found after you've gone.
func on_property(what: String, d: float, at := Vector2.INF, found_after := true) -> bool:
	if not sees(at):
		if found_after:
			_owned.append([what, d])
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
## Their dog brought home. Indoors, it scratches at the door and they come out: they
## get their dog back either way, so they always know.
func on_dog_returned(at := Vector2.INF) -> bool:
	if not sees(at):
		come_out()
	_change(10.0)
	_react("delighted", 2.0, "Oh, thank you! Bad %s!" % job.get("dog_name", "dog"))
	return true


func fire(line: String) -> void:
	if fired or knocked_out or paid: # once paid, what you do after goes on your reputation (main._mischief)
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
		fire(_say("fire", "That's it. You're fired!"))


## Asked how it's going: an honest answer, by mood, and a nudge if time's getting on.
func status_line() -> String:
	if fired:
		return fire_line
	if paid:
		return "You've been paid. Off you go."
	var line := _say("status_good", "Lovely so far!") if mood >= 75.0 else (
		_say("status_ok", "Coming along.") if mood >= 55.0 else (
		_say("status_meh", "I've seen better.") if mood >= 35.0 else _say("status_bad", "You're on thin ice.")))
	if elapsed > job.patience * GLANCES[0]:
		line += " And do get a move on."
	return line


## A line in this persona's own voice if it has one (PERSONAS "lines"), else the usual.
func _say(id: String, usual: String) -> String:
	var l: Variant = persona.get("lines", {}).get(id, usual)
	return l[randi() % l.size()] if l is Array else l


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
	var tip := int(round(base * 0.25)) if (cov >= target and elapsed <= patience and mood >= 75.0 and not job.has("regular")) else 0 # regulars don't tip
	var rep := (mood - 50.0) / 5.0 + (2.0 if cov >= target else -3.0)
	var comment := _say("paid_good", "Lovely job. Thank you!") if mood >= 75.0 else (_say("paid_ok", "That'll do.") if mood >= 45.0 else _say("paid_bad", "Hmph. Take your money and go."))
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
