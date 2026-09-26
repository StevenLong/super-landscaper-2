extends Node
## Run state (autoload "Game"). A run is a season: WEEKS weeks of JOBS_PER_WEEK jobs
## picked from a job board, with the loan shark's payment due at each week's end. Pay the
## last one and you've won; miss one and his heavies repossess kit; bankrupt only when
## nothing left covers it. Score = total earned this run.

var save_path := "user://best.cfg" ## tests point this elsewhere so they never touch the real save

## Mower specs. The mower scene's own exports are the petrol defaults; a run
## applies the equipped spec on top.
const MOWERS := {
	"push": {
		"name": "Push mower", "price": 0, "power": "stamina", "sprite": "push", "body": Vector2(30, 22),
		"max_speed": 165.0, "reverse_speed": 80.0, "accel": 420.0, "brake": 900.0,
		"turn_rate": 3.6, "cut_radius": 14.0, "max_fuel": 20.0, "fuel_burn": 1.0,
		"regen": 4.0, "empty_speed_scale": 0.4, "fuel_price": 0.0, "toughness": 0.8,
		"blurb": "Legs for an engine. Narrow, nimble.",
	},
	"petrol": {
		"name": "Petrol mower", "price": 180, "power": "fuel", "sprite": "petrol", "body": Vector2(36, 28),
		"max_speed": 220.0, "reverse_speed": 110.0, "accel": 600.0, "brake": 900.0,
		"turn_rate": 3.0, "cut_radius": 16.0, "max_fuel": 60.0, "fuel_burn": 1.0,
		"regen": 0.0, "empty_speed_scale": 0.35, "fuel_price": 0.25, "toughness": 1.0,
		"blurb": "Faster, wider. Burns fuel nonstop.",
	},
	"rideon": {
		"name": "Ride-on mower", "price": 650, "power": "fuel", "sprite": "rideon", "body": Vector2(52, 40),
		"max_speed": 300.0, "reverse_speed": 120.0, "accel": 340.0, "brake": 520.0,
		"turn_rate": 1.9, "cut_radius": 26.0, "max_fuel": 80.0, "fuel_burn": 1.5,
		"regen": 0.0, "empty_speed_scale": 0.2, "fuel_price": 0.25, "toughness": 2.0,
		"blurb": "Huge cut. Turns like a barge.",
	},
}

const UPGRADES := {
	"tank": {"name": "Bigger tank", "price": 120, "blurb": "+50% fuel or stamina."},
	"blades": {"name": "Sharp blades", "price": 150, "blurb": "+15% cutting width."},
}

const FIRST := ["Margaret", "Derek", "Priya", "Gordon", "Yvonne", "Colin", "Shirley", "Nigel",
	"Bernadette", "Keith", "Fatima", "Trevor", "Agnes", "Barry", "Hilary", "Rajesh", "Doreen", "Clive"]
const LAST := ["Pemberton", "Figgis", "Oakley", "Thistlewood", "Grubb", "Hedges", "Mowbray",
	"Featherstone", "Bramble", "Nettlefold", "Pratt", "Ashdown", "Gubbins", "Crumb"]

## Customer personalities. Mood effects are hidden from the player; the brief hints.
## An "instant" line is stated plainly: breaking it fires you on the spot.
const PERSONAS := {
	"nature": {
		"brief": ["I do love the hedgehogs that visit.", "Please be gentle with the little ones."],
		"ads": [["LAWN MOWING.", "Wildlife-friendly garden; hedgehogs visit nightly. Gentle hands only."],
			["CAREFUL MOWER SOUGHT", "by nature lover. The little ones must come to no harm."]],
		"hedgehog": -40.0, "squirrel": -30.0, "flower": -2.0, "patience": 1.3, "target": 0.8,
	},
	"squirrel_hater": {
		"brief": ["The squirrels have dug up every bulb I own.", "I shan't be sad if one has an... accident."],
		"ads": [["GARDENER WANTED.", "Squirrel problem: every bulb dug up. Accidents happen."],
			["LAWN MOWN,", "squirrels discouraged by any means. No questions asked."]],
		"hedgehog": -20.0, "squirrel": 14.0, "flower": -2.0, "patience": 1.0, "target": 0.8,
	},
	"gardener": {
		"brief": ["DO NOT touch my prize flowerbeds.", "Tread on more than a couple of my flowers and you're finished."],
		"ads": [["MOWING AROUND PRIZE BORDERS.", "Careful applicants only. Beds strictly out of bounds."],
			["EXPERIENCED MOWER WANTED.", "Award-winning flowerbeds: tread on them and you're finished."]],
		"hedgehog": -20.0, "squirrel": -10.0, "flower": -6.0, "instant_flowers": 3, "patience": 1.1, "target": 0.85,
	},
	"busy": {
		"brief": ["I'm on a call. Just get it done, quickly.", "I'm paying for speed, not a masterpiece."],
		"ads": [["LAWN MOWED ASAP.", "Speed over finesse. Owner on calls, do not disturb."],
			["QUICK MOW WANTED,", "today if possible. Not fussy, just fast."]],
		"hedgehog": -15.0, "squirrel": -5.0, "flower": -1.0, "patience": 0.7, "target": 0.7,
	},
	"perfectionist": {
		"brief": ["Every blade, please. I will be checking.", "Take the time you need to do it properly."],
		"ads": [["METICULOUS MOWER WANTED.", "Every blade. Work will be inspected. Take your time."],
			["LAWN TO BOWLING-GREEN STANDARD.", "No stripe missed, no corner cut. No rush."]],
		"hedgehog": -25.0, "squirrel": -15.0, "flower": -4.0, "patience": 1.6, "target": 0.96,
	},
	"grump": {
		"brief": ["Last lad was useless.", "Don't make me regret calling you."],
		"ads": [["MOWER WANTED.", "Last one was useless. Don't waste my time."],
			["LAWN. NEEDS CUTTING.", "Previous contractor dismissed. Prove me wrong."]],
		"hedgehog": -30.0, "squirrel": -20.0, "flower": -3.0, "patience": 0.9, "target": 0.85, "start_mood": 45.0,
	},
}

const PAYMENTS := [120, 250, 450, 750] ## the shark's payment due at the end of each week (tuning, not measured)
const JOBS_PER_WEEK := 3
const RESALE := 0.5 ## what kit fetches sold (by you or the heavies), as a share of its price

## The crime ladder (design doc, The Run): heat added by tier. 0 isn't a crime (rep only),
## 1 a nuisance (fined if caught), 2 assault (fined, and a night in the cells costs your
## next job), 3 the worst (not built: nothing can kill a customer yet).
const HEAT := [0.0, 1.0, 2.0, 5.0]
const HIGH_HEAT := 3.0 ## from here, a nuisance gets the police called too

const LAWN_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var money := 0
var total_earned := 0
var reputation := 50.0 ## 0..100; the job board dries up as it falls
var rep_trend := 50.0 ## where behaviour is pushing reputation; reputation lags toward it
var owned: Array[String] = ["push"]
var equipped := "push"
var upgrades: Array[String] = []
var week := 1 ## the week whose payment is next due
var jobs_done := 0
var in_run := false
var current_job := {}
var last_result := {}
var run_tally := {} ## the job tallies added up over the run
var run_tally_cost := {}

## Names for everything the jobs count, in the order they're shown. Only counts above
## zero appear, so most of these are a surprise the first time.
const TALLY := {
	"squashed_hedgehog": "Hedgehogs flattened", "squashed_squirrel": "Squirrels flattened",
	"stoned_hedgehog": "Hedgehogs stoned", "stoned_squirrel": "Squirrels sniped",
	"dog_bowled": "Dogs bowled over", "dog_returned": "Dogs walked home",
	"customer_hits": "Customers hit with a stone", "knockouts": "Customers knocked out cold",
	"windows": "Windows put through", "car_dents": "Dents in the customer's car", "dents": "Dents in your own truck",
	"own_goals": "Stones at your own mower", "flowers": "Flowers flattened",
	"stones_mowed": "Stones through the blades", "stones_thrown": "Stones thrown",
	"trees_hit": "Trees stoned", "splashes": "Stones fed to the pond",
	"stones_picked": "Stones picked up", "stones_binned": "Stones tidied into the truck",
	"cans": "Cans of fuel carried", "sent_back": "Times sent back out to finish",
}
## Button prompts follow what you last touched: keyboard keys, or an Xbox-style pad.
const PROMPTS := {"interact": ["E", "A"], "hop": ["F", "X"], "throw": ["Q", "B"], "look": ["Tab", "Y"], "pause": ["Esc", "Start"]}
var pad := false

var best_score := 0
var run_over_reason := "" ## "" while running; "bankrupt" or "won" once it's over
var heat := 0.0 ## the wanted level: only crimes add it (HEAT), a week paid on time cools it one

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # hears the pad in paused menus too
	# The pixel font everywhere: glyphs are 10px, so sizes render at whole multiples.
	var font := PixelFont.make()
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = 20
	ThemeDB.get_default_theme().default_font = font
	ThemeDB.get_default_theme().default_font_size = 20
	# WASD drives the menus too, alongside the arrows and the pad.
	for pair: Array in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D]]:
		var k := InputEventKey.new()
		k.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], k)
	# Godot's ui_accept has no pad button; A presses menu buttons like it interacts in a job.
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	InputMap.action_add_event("ui_accept", a)
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		best_score = cfg.get_value("best", "score", 0)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false


## The prompt for an action: "[E]" on the keyboard, "(A)" on a pad.
func key(action: String) -> String:
	return ("(%s)" if pad else "[%s]") % PROMPTS[action][1 if pad else 0]


func new_run(seed_value := 0) -> void:
	if seed_value:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	money = 0
	total_earned = 0
	reputation = 50.0
	rep_trend = 50.0
	owned = ["push"]
	equipped = "push"
	upgrades = []
	week = 1
	jobs_done = 0
	in_run = true
	current_job = {}
	last_result = {}
	run_tally = {}
	run_tally_cost = {}
	heat = 0.0
	run_over_reason = ""


## The mower spec for the equipped mower, with upgrades applied.
func mower_spec() -> Dictionary:
	var s: Dictionary = MOWERS[equipped].duplicate()
	if "tank" in upgrades:
		s.max_fuel *= 1.5
	if "blades" in upgrades:
		s.cut_radius *= 1.15
	return s


## A job as a newspaper classified (BBCode): the headline, the customer's hint worked
## into the wording, the plot, anything to watch for, the pay and who to ring.
func ad_text(job: Dictionary) -> String:
	var ads: Array = PERSONAS[job.persona].ads
	var ad: Array = ads[job.seed % ads.size()]
	var parts: Array[String] = [ad[1]]
	parts.append(["Small lawn.", "Good-sized garden.", "Extensive grounds."][LAWN_SIZES.find(job.size)])
	if job.get("ponds", 0) > 0:
		parts.append("Ornamental pond.")
	if job.get("dog", false):
		parts.append("Friendly dog, a known escapee.")
	var names: PackedStringArray = job.customer.split(" ")
	parts.append("$%d cash. Ring %s." % [job.pay, names[0] if job.seed % 2 == 0 else "%s. %s" % [names[0][0], names[-1]]])
	return "[color=#7a1c14]%s[/color] %s" % [ad[0], " ".join(parts)]


## How many offers the board shows at this reputation. At the bottom it's one job,
## the dregs (see make_job), never none.
func offer_count() -> int:
	if reputation < 20.0:
		return 1
	if reputation < 45.0:
		return 2
	return 3


func make_offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in offer_count():
		out.append(make_job(_rng.randi()))
	return out


## A job is plain data: who, where, how big, what they secretly want, and what it pays.
func make_job(seed_value: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var persona_key: String = PERSONAS.keys()[r.randi() % PERSONAS.size()]
	var dregs := reputation <= 0.0 # nobody decent will have you: cheap and hostile
	if dregs:
		persona_key = "grump"
	var p: Dictionary = PERSONAS[persona_key]
	# Better reputation unlocks bigger, better-paying lawns.
	var max_size := 0 if reputation < 55.0 else (1 if reputation < 75.0 else 2)
	var size_i := r.randi_range(0, max_size)
	var size: Vector2i = LAWN_SIZES[size_i]
	var area := float(size.x * size.y) / (1280.0 * 720.0)
	var target: float = clampf(p.target + r.randf_range(-0.05, 0.04), 0.5, 1.0)
	return {
		"seed": seed_value,
		"customer": "%s %s" % [FIRST[r.randi() % FIRST.size()], LAST[r.randi() % LAST.size()]],
		"persona": persona_key,
		"brief": p.brief,
		"look": {"hair_style": r.randi() % 5, "skin": r.randi() % 5, "hair": r.randi() % 6, "shirt": r.randi() % 6},
		"size": size,
		"trees": r.randi_range(1, 2 + size_i * 2),
		"beds": r.randi_range(1, 1 + size_i),
		"target": target,
		# Seconds they'll happily wait: scales with lawn area and their patience.
		"patience": 300.0 * area * p.patience, # tools: tests/sim_balance.gd measures mowing times
		"pay": int(round((70.0 + 50.0 * size_i) * area * (1.0 + (target - 0.8)) * (0.5 if dregs else 1.0) / 5.0) * 5),
		"hedgehog_every": 7.0 / (1.0 + 0.25 * size_i),
		"squirrel_every": 13.0 / (1.0 + 0.25 * size_i),
		"stones": 4 + size_i * 2 + r.randi_range(0, 2),
		"ponds": 1 if (size_i > 0 and r.randf() < 0.6) else 0,
		"dog": r.randf() < 0.4,
		"dog_name": ["Biscuit", "Rolo", "Duchess", "Pickle", "Monty", "Waffles", "Sir Barkley"][r.randi() % 7],
	}


## The slice's hand-made lawn, used when no run is active (tests, editor play).
func default_job() -> Dictionary:
	return {
		"seed": 1, "customer": "Margaret Pemberton", "persona": "gardener",
		"brief": PERSONAS.gardener.brief,
		"look": {"hair_style": 3, "skin": 0, "hair": 4, "shirt": 1},
		"size": Vector2i(1280, 720), "fixed_layout": true,
		"target": 0.85, "patience": 165.0, "pay": 80,
		"hedgehog_every": 7.0, "squirrel_every": 13.0,
	}


func job() -> Dictionary:
	return current_job if not current_job.is_empty() else default_job()


## The non-zero counts as "Name 3" (with "-$40" where it cost money), in TALLY order.
func tally_lines(counts: Dictionary, costs: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for k: String in TALLY:
		if counts.get(k, 0) > 0:
			var line := "%s %d" % [TALLY[k], counts[k]]
			if costs.get(k, 0.0) > 0.0:
				line += " (-$%d)" % roundi(costs[k])
			out.append(line)
	return out


## Apply a finished job's result to the run. Reputation drifts toward the trend
## rather than jumping, so bad behaviour catches up with you a job or two later.
func record_result(result: Dictionary) -> void:
	last_result = result
	if not in_run:
		return
	result.rep_before = reputation
	for k: String in result.get("tally", {}):
		run_tally[k] = run_tally.get(k, 0) + result.tally[k]
	for k: String in result.get("tally_cost", {}):
		run_tally_cost[k] = run_tally_cost.get(k, 0.0) + result.tally_cost[k]
	money += int(result.net)
	total_earned += maxi(0, int(result.paid))
	rep_trend = clampf(rep_trend + float(result.rep), 0.0, 100.0)
	reputation = clampf(reputation + (rep_trend - reputation) * 0.5 + float(result.rep) * 0.25, 0.0, 100.0)
	jobs_done += 1
	if result.get("cells", false):
		jobs_done += 1 # a night in the cells: the next job slot is gone
	result.rep_after = reputation
	if total_earned > best_score:
		best_score = total_earned
		var cfg := ConfigFile.new()
		cfg.set_value("best", "score", best_score)
		cfg.save(save_path)


## Seconds from the police being called to them arriving: your record shortens it.
func police_time(at_heat: float) -> float:
	return maxf(20.0, 60.0 - 8.0 * at_heat)


## Caught for a crime of this tier: damages are billed separately, this is the charge,
## and your record raises it.
func fine(tier: int, at_heat: float) -> int:
	return int((50.0 if tier <= 1 else 150.0) * (1.0 + 0.25 * at_heat))


func buy(key: String) -> bool:
	var price: int = MOWERS[key].price if MOWERS.has(key) else UPGRADES[key].price
	if money < price:
		return false
	if MOWERS.has(key):
		if key in owned:
			return false
		owned.append(key)
		equipped = key
	else:
		if key in upgrades:
			return false
		upgrades.append(key)
	money -= price
	return true


## Which job of the week is next, 1 to JOBS_PER_WEEK.
func job_of_week() -> int:
	return jobs_done - (week - 1) * JOBS_PER_WEEK + 1


## The week's jobs are done and the shark's man is due.
func payday_due() -> bool:
	return in_run and jobs_done >= week * JOBS_PER_WEEK


func payment() -> int:
	return PAYMENTS[mini(week, PAYMENTS.size()) - 1]


## What kit fetches sold: everything but the push mower.
func resale(key: String) -> int:
	return int((MOWERS[key].price if MOWERS.has(key) else UPGRADES[key].price) * RESALE)


## Kit that can be sold or taken, dearest first (the heavies take your best).
func sellable() -> Array[String]:
	var out: Array[String] = []
	out.assign(owned.filter(func(k: String) -> bool: return k != "push") + upgrades)
	out.sort_custom(func(a: String, b: String) -> bool: return resale(a) > resale(b))
	return out


func sell(key: String) -> void:
	money += resale(key)
	if MOWERS.has(key):
		owned.erase(key)
		if equipped == key: # onto the best you have left
			for k in owned:
				if equipped not in owned or MOWERS[k].price > MOWERS[equipped].price:
					equipped = k
	else:
		upgrades.erase(key)


## The week's end: pay the shark. Short, the heavies take kit, dearest first, until its
## resale covers it (you keep the change). Returns {paid, taken, outcome}, outcome one of
## "paid", "repossessed", "bankrupt" (nothing left covers it) or "won" (the last payment).
func settle_payday() -> Dictionary:
	var due := payment()
	var taken: Array[String] = []
	for k in sellable():
		if money >= due:
			break
		sell(k)
		taken.append(k)
	if money < due:
		money = 0
		run_over_reason = "bankrupt"
		return {"paid": due, "taken": taken, "outcome": "bankrupt"}
	money -= due
	week += 1
	heat = maxf(0.0, heat - 1.0) # paid on time: things cool off
	var outcome := "won" if week > PAYMENTS.size() else ("repossessed" if taken else "paid")
	if outcome == "won":
		run_over_reason = "won"
	return {"paid": due, "taken": taken, "outcome": outcome}
