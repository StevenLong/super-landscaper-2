extends Node
## Business state (autoload "Game"; design doc, The Business). Seasons of real days,
## April to September, at most one job a day. Each Friday the loan shark takes his vig on
## what you still owe, plus the week's living cost; anything more cuts the debt. Miss it
## and his heavies repossess kit; bankrupt only when nothing left covers it. The weekly
## paper's ads are booked into free days, a good job can earn a regular, and the business
## is saved between days (ironman: a job quit halfway loads as the blackout).

var save_path := "user://best.cfg" ## tests point this elsewhere so they never touch the real saves (the business is saved beside it)

## Mower specs. The mower scene's own exports are the petrol defaults; a run
## applies the equipped spec on top.
const MOWERS := {
	"push": {
		"name": "Push mower", "price": 0, "power": "stamina", "sprite": "push", "body": Vector2(30, 22),
		"max_speed": 165.0, "reverse_speed": 80.0, "accel": 420.0, "brake": 900.0,
		"turn_rate": 3.6, "cut_radius": 14.0, "max_fuel": 20.0, "fuel_burn": 1.0,
		"regen": 4.0, "empty_speed_scale": 0.4, "fuel_price": 0.0, "toughness": 0.8, "knock_out": 0.7,
		"blurb": "Legs for an engine. Narrow, nimble.",
	},
	"petrol": {
		"name": "Petrol mower", "price": 180, "power": "fuel", "sprite": "petrol", "body": Vector2(36, 28),
		"max_speed": 220.0, "reverse_speed": 110.0, "accel": 600.0, "brake": 900.0,
		"turn_rate": 3.0, "cut_radius": 16.0, "max_fuel": 60.0, "fuel_burn": 1.0,
		"regen": 0.0, "empty_speed_scale": 0.35, "fuel_price": 0.25, "toughness": 1.0, "knock_out": 0.3,
		"blurb": "Faster, wider. Burns fuel nonstop.",
	},
	"rideon": {
		"name": "Ride-on mower", "price": 650, "power": "fuel", "sprite": "rideon", "body": Vector2(52, 40),
		"max_speed": 300.0, "reverse_speed": 120.0, "accel": 340.0, "brake": 520.0,
		"turn_rate": 1.9, "cut_radius": 26.0, "max_fuel": 80.0, "fuel_burn": 1.5,
		"regen": 0.0, "empty_speed_scale": 0.0, "fuel_price": 0.25, "toughness": 2.0, "knock_out": 0.0,
		"blurb": "Huge cut. Turns like a barge.",
	},
}

const UPGRADES := {
	"tank": {"name": "Bigger tank", "price": 120, "blurb": "+50% fuel or stamina."},
	"gloves": {"name": "Gardening gloves", "price": 40, "blurb": "Pick up a hedgehog without the prickles."},
	"blades": {"name": "Sharp blades", "price": 150, "blurb": "+15% cutting width."},
}

const FIRST := ["Margaret", "Derek", "Priya", "Gordon", "Yvonne", "Colin", "Shirley", "Nigel",
	"Bernadette", "Keith", "Fatima", "Trevor", "Agnes", "Barry", "Hilary", "Rajesh", "Doreen", "Clive"]
const LAST := ["Pemberton", "Figgis", "Oakley", "Thistlewood", "Grubb", "Hedges", "Mowbray",
	"Featherstone", "Bramble", "Nettlefold", "Pratt", "Ashdown", "Gubbins", "Crumb"]

## Customer personalities. Mood effects are hidden from the player; the brief hints.
## "indoors": how much of the job they spend inside or at a window, not on the patio.
## An "instant" line is stated plainly: breaking it fires you on the spot.
const PERSONAS := {
	"nature": {
		"brief": ["I do love the hedgehogs that visit.", "Please be gentle with the little ones."],
		"ads": [["LAWN MOWING.", "Wildlife-friendly garden; hedgehogs visit nightly. Gentle hands only."],
			["CAREFUL MOWER SOUGHT", "by nature lover. The little ones must come to no harm."]],
		"hedgehog": -40.0, "squirrel": -30.0, "flower": -2.0, "patience": 1.3, "target": 0.8, "indoors": 0.3,
	},
	"squirrel_hater": {
		"brief": ["The squirrels have dug up every bulb I own.", "I shan't be sad if one has an... accident."],
		"ads": [["GARDENER WANTED.", "Squirrel problem: every bulb dug up. Accidents happen."],
			["LAWN MOWN,", "squirrels discouraged by any means. No questions asked."]],
		"hedgehog": -20.0, "squirrel": 14.0, "flower": -2.0, "patience": 1.0, "target": 0.8, "indoors": 0.4,
	},
	"gardener": {
		"brief": ["DO NOT touch my prize flowerbeds.", "Tread on more than a couple of my flowers and you're finished."],
		"ads": [["MOWING AROUND PRIZE BORDERS.", "Careful applicants only. Beds strictly out of bounds."],
			["EXPERIENCED MOWER WANTED.", "Award-winning flowerbeds: tread on them and you're finished."]],
		"hedgehog": -20.0, "squirrel": -10.0, "flower": -6.0, "instant_flowers": 3, "patience": 1.1, "target": 0.85, "indoors": 0.25,
	},
	"busy": {
		"brief": ["I'm on a call. Just get it done, quickly.", "I'm paying for speed, not a masterpiece."],
		"ads": [["LAWN MOWED ASAP.", "Speed over finesse. Owner on calls, do not disturb."],
			["QUICK MOW WANTED,", "today if possible. Not fussy, just fast."]],
		"hedgehog": -15.0, "squirrel": -5.0, "flower": -1.0, "patience": 0.7, "target": 0.7, "indoors": 0.7,
	},
	"perfectionist": {
		"brief": ["Every blade, please. I will be checking.", "Take the time you need to do it properly."],
		"ads": [["METICULOUS MOWER WANTED.", "Every blade. Work will be inspected. Take your time."],
			["LAWN TO BOWLING-GREEN STANDARD.", "No stripe missed, no corner cut. No rush."]],
		"hedgehog": -25.0, "squirrel": -15.0, "flower": -4.0, "patience": 1.6, "target": 0.96, "indoors": 0.1,
	},
	"grump": {
		"brief": ["Last lad was useless.", "Don't make me regret calling you."],
		"ads": [["MOWER WANTED.", "Last one was useless. Don't waste my time."],
			["LAWN. NEEDS CUTTING.", "Previous contractor dismissed. Prove me wrong."]],
		"hedgehog": -30.0, "squirrel": -20.0, "flower": -3.0, "patience": 0.9, "target": 0.85, "start_mood": 45.0, "indoors": 0.35,
	},
	# Venues (design doc, Levels): the mansion at the top of the ladder, the churchyard at the bottom.
	"toff": {
		"brief": ["The grounds must be immaculate. Every inch.", "Do mind the urns. They're older than you are."],
		"ads": [["GROUNDSMAN REQUIRED", "for a country house. Discretion and precision essential."],
			["ESTATE LAWNS", "want an experienced hand. Priceless urns on the terrace; do take care."]],
		"hedgehog": -20.0, "squirrel": -5.0, "flower": -5.0, "patience": 1.2, "target": 0.92, "indoors": 0.5,
	},
	"vicar": {
		"brief": ["Mind the graves, and the flowers on them.", "The Lord sees everything. So do I, mostly."],
		"ads": [["CHURCHYARD", "grass wants cutting. Respect for the departed essential. Modest fee."],
			["GRAVEYARD MOWING,", "St. Swithin's. Tread softly among the stones."]],
		"hedgehog": -25.0, "squirrel": -10.0, "flower": -8.0, "patience": 1.3, "target": 0.75, "indoors": 0.4,
		# Their own voice (customer.gd _say): an id, then a line or a pick of lines.
		"lines": {"squash": ["May God forgive you.", "Lord have mercy!"], "flowers": "Those were for the departed!",
			"window": "The VESTRY window!", "car": "Thou shalt not dent!", "hit": "Heavens! My EYE!",
			"fire": "Go, and sin no more. Elsewhere.", "stunned": "Rise, little one!",
			"status_good": "The Lord is pleased.", "status_bad": "My patience is not infinite, even if His is.", "paid_good": "Bless you, my child.",
			"paid_ok": "The Lord loves a trier.", "paid_bad": "I shall pray for you."},
	},
}

## The season's numbers (guesses, not measured; play decides).
const PRINCIPAL := 1000 ## what you owe the shark at the start
const VIG := 0.10 ## his weekly interest on what you still owe
const LIVING := 50 ## rent and food, a week
const LAST_MONTH := 9 ## the season ends with September
const WINTER_WEEKS := 26 ## October to March: the living cost only (the vig sleeps, for now)
const FRIDAY := 5 ## payday, in Time's weekday numbers (Sunday is 0)
const FLOOR := 35.0 ## a regular's visit ending in a mood under this loses them
const HAGGLE := 1.2 ## pushing for more asks this much
const BLACKOUT_REP := 15.0 ## the reputation a blacked-out job costs (on the trend)
## Who asks to become a regular: [chance factor, visits every so many days].
const REGULAR := {"nature": [1.0, 14], "squirrel_hater": [1.0, 14], "gardener": [0.6, 14], "busy": [1.3, 7],
	"perfectionist": [0.5, 7], "grump": [0.4, 28], "toff": [0.7, 7], "vicar": [1.0, 14]}
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December"]
const PAPER := [-25.0, -12.0, 0.0, 0.0, 12.0, 25.0] ## a week's ads against your name: two below, two around, two above
const REACH := 15.0 ## how far under an ad's bar a call can still get a yes
const DAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const RESALE := 0.5 ## what kit fetches sold (by you or the heavies), as a share of its price

## The crime ladder (design doc, The Run): heat added by tier. 0 isn't a crime (rep only),
## 1 a nuisance (fined if caught), 2 assault (fined, and a night in the cells costs your
## next job), 3 the worst (not built: nothing can kill a customer yet).
const HEAT := [0.0, 1.0, 2.0, 5.0]
const HIGH_HEAT := 3.0 ## from here, a nuisance gets the police called too

## The ordinary customers, in PERSONAS order (the venues bring their own).
const SUBURBAN := ["nature", "squirrel_hater", "gardener", "busy", "perfectionist", "grump"]

const LAWN_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const TERRACE := Vector2i(560, 1600) ## a terrace's long thin garden: about a small lawn's area
const MANOR := Vector2i(1760, 1340) ## taller than the biggest lawn for the approach, about the old mansion's grass (measured)

var money := 0
var total_earned := 0
var reputation := 50.0 ## 0..100; callers say no as it falls (yes_chance)
var rep_trend := 50.0 ## where behaviour is pushing reputation; reputation lags toward it
var owned: Array[String] = ["push"]
var equipped := "push"
var upgrades: Array[String] = []
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
	"ko_hedgehog": "Hedgehogs knocked out", "ko_squirrel": "Squirrels knocked out",
	"slammed_hedgehog": "Hedgehogs dashed against things", "slammed_squirrel": "Squirrels dashed against things",
	"bodies_hidden": "Bodies disposed of", "bodies_mulched": "Bodies mulched",
	"dog_bowled": "Dogs bowled over", "dog_returned": "Dogs walked home",
	"customer_hits": "Customers hit with a stone", "knockouts": "Customers knocked out cold",
	"robberies": "Pockets rifled",
	"windows": "Windows put through", "car_dents": "Dents in the customer's car", "topiary": "Topiary clipped the hard way", "dents": "Dents in your own truck",
	"own_goals": "Stones at your own mower", "flowers": "Flowers flattened",
	"stones_mowed": "Stones through the blades", "stones_thrown": "Things thrown",
	"gnomes_mowed": "Gnomes shattered", "flamingos_mowed": "Flamingos shredded", "cones_mowed": "Cones sent flying",
	"hoses_mowed": "Hoses cut", "urns_mowed": "Urns smashed", "balls_mowed": "Tennis balls shredded", "jerrycans_mowed": "Petrol cans mowed",
	"fetches": "Balls fetched", "animals_thrown": "Animals thrown", "prickled": "Hedgehogs grabbed bare-handed",
	"bitten": "Bitten by squirrels", "own_head": "Stones on your own head",
	"trees_hit": "Trees stoned", "splashes": "Stones fed to the pond",
	"stones_picked": "Stones picked up", "stones_binned": "Stones tidied into the truck",
	"cans": "Cans of fuel carried", "sent_back": "Times sent back out to finish",
}
## What can only happen once a job: shown as the event, never a count or a record.
const EVENTS := {"dog_bowled": "Bowled the dog over", "dog_returned": "Walked the dog home",
	"knockouts": "Knocked the customer out cold", "robberies": "Rifled their pockets", "hoses_mowed": "Cut the hose"}
## The counts it's good to beat: a record in one of these is a personal best. A record
## in anything else is a personal worst.
const GOOD_TALLY := ["dog_returned", "fetches", "stones_picked", "stones_binned", "cans"]
## Button prompts follow what you last touched: keyboard keys, or an Xbox-style pad.
const PROMPTS := {"interact": ["E", "A"], "hop": ["F", "B"], "throw": ["Q", "X"], "look": ["Tab", "Y"], "pause": ["Esc", "Start"], "sprint": ["Shift", "A"],
	"gear_up": ["Shift", "RB"], "gear_down": ["Ctrl", "LB"]}
var pad := false

var best_score := 0
var records := {} ## the most of each TALLY key in any one job, ever (saved)
var run_over_reason := "" ## "" while running; "bankrupt" or "won" once it's over
var heat := 0.0 ## the wanted level: only crimes add it (HEAT), a week paid on time cools it one

var start_month := 4 ## a knob: June reaches a busy calendar sooner for play-checks
var year := 1980
var day := 0 ## today, not yet over, in days since 1970 (Time's unix time / a day)
var principal := 0
var calendar := {} ## day -> what's booked: a job (a classified or a regular's visit), or {"cells": true}
var paper: Array[Dictionary] = [] ## this week's ads not yet booked
var regulars := {} ## id (their first job's seed) -> {id, job, cadence, rate, mood, drift}
var offer := {} ## a regular's offer after the job just done, until answered
var payday_pending := false
var winter_pending := false
var in_job := false ## a job started and not finished: loading onto it is the blackout
var blackout := {} ## the job you blacked out on, for the board to break the news
## What the save keeps: the whole business.
const SAVED := ["money", "total_earned", "reputation", "rep_trend", "owned", "equipped", "upgrades",
	"jobs_done", "heat", "run_tally", "run_tally_cost", "start_month", "year", "day", "principal",
	"calendar", "paper", "regulars", "offer", "payday_pending", "winter_pending", "in_job", "current_job"]

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
		records = cfg.get_value("best", "records", {})


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
	jobs_done = 0
	in_run = true
	current_job = {}
	last_result = {}
	run_tally = {}
	run_tally_cost = {}
	heat = 0.0
	run_over_reason = ""
	year = 1980
	day = day_of(year, start_month, 1)
	principal = PRINCIPAL
	calendar = {}
	regulars = {}
	offer = {}
	payday_pending = false
	winter_pending = false
	in_job = false
	blackout = {}
	paper = make_paper()
	save()


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
func ad_text(j: Dictionary) -> String:
	var ads: Array = PERSONAS[j.persona].ads
	var ad: Array = ads[j.seed % ads.size()]
	var parts: Array[String] = [ad[1]]
	parts.append({"mansion": "Country estate.", "graveyard": "Churchyard."}.get(j.get("venue", ""),
		"Long garden, terraced house." if j.get("shape", "") == "terrace"
		else ["Small lawn.", "Good-sized garden.", "Extensive grounds."][LAWN_SIZES.find(j.size)]))
	if j.get("ponds", 0) > 0:
		parts.append("Ornamental pond.")
	if j.get("dog", false):
		parts.append("Friendly dog, a known escapee.")
	var names: PackedStringArray = j.customer.split(" ")
	var who := names[0] if j.seed % 2 == 0 else "%s. %s" % [names[0][0], names[-1]]
	parts.append("$%d cash. Ring %s." % [j.pay, "the vicarage" if j.persona == "vicar" else who])
	return "[color=#7a1c14]%s[/color] %s" % [ad[0], " ".join(parts)]


## The week's paper (design doc, The Business: you ring the ad): a spread round your
## name, not only what it earns you. Each ad is made as if for a name PAPER away from
## yours (give or take 5), in no particular order.
func make_paper() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for off: float in PAPER:
		out.append(make_job(_rng.randi(), clampf(reputation + off + _rng.randf_range(-5.0, 5.0), 0.0, 100.0)))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.seed < b.seed)
	return out


## The chance ringing this ad gets a yes: certain at or over its bar, falling away over
## REACH below it, so you can push a little higher.
func yes_chance(ad: Dictionary) -> float:
	return clampf((reputation - ad.bar + REACH) / REACH, 0.0, 1.0)


## Ring an ad: an answer at once, no cost either way. Yes books it into the week's first
## free day; no stamps it for the week. Returns what they said.
func ring(ad: Dictionary) -> String:
	var chance := yes_chance(ad)
	if _rng.randf() < chance:
		var d := book(ad)
		var when: String = DAYS[date(d).weekday]
		if ad.persona == "vicar":
			return "\"All are welcome at St. Swithin's. %s, then.\"" % when
		if ad.persona == "grump":
			return "\"Fine. %s. Don't be late.\"" % when
		return ("\"Oh, I've heard of you. Come round %s.\"" if chance >= 1.0 else "\"I've heard mixed things... go on, then. %s.\"") % when
	ad.refused = true
	ad.reply = "\"Oh, I've heard of you. No.\"" if chance <= 0.0 else "\"Hmm. I'll keep looking, thanks.\""
	save()
	return ad.reply


## A job is plain data: who, where, how big, what they secretly want, and what it pays.
## `at`: the name it's pitched at (yours by default): a better name, bigger and better-paying
## lawns. Its `bar` is the name it asks for (yes_chance).
func make_job(seed_value: int, at := -1.0) -> Dictionary:
	if at < 0.0:
		at = reputation
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var persona_key: String = SUBURBAN[r.randi() % SUBURBAN.size()]
	var dregs := at <= 0.0 # nobody decent will have you: cheap and hostile
	if dregs:
		persona_key = "grump"
	var p: Dictionary = PERSONAS[persona_key]
	# Better reputation unlocks bigger, better-paying lawns.
	var max_size := 0 if at < 55.0 else (1 if at < 75.0 else 2)
	var size_i := r.randi_range(0, max_size)
	var size: Vector2i = LAWN_SIZES[size_i]
	var area := float(size.x * size.y) / (1280.0 * 720.0)
	var target: float = clampf(p.target + r.randf_range(-0.05, 0.04), 0.5, 1.0)
	var j := {
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
		"props": _props(seed_value, persona_key, size_i),
		"rocks": (seed_value >> 3) % (2 + size_i),
	}
	# The venue, by reputation band, from its own draws so the rest stays put.
	var rv := RandomNumberGenerator.new()
	rv.seed = seed_value + 5
	if not dregs and at >= 75.0 and rv.randf() < 0.4:
		_venue(j, "mansion", "toff", 2, 1.8)
		j.props = ["urn", "urn"] + (["urn"] if rv.randf() < 0.5 else []) + ["hose"]
		j.size = MANOR
		j.ponds = 1 if rv.randf() < 0.5 else 0
		j.beds = 0 # the parterre is the beds
		j.trees = rv.randi_range(2, 3)
	elif not dregs and at < 20.0 and rv.randf() < 0.5:
		_venue(j, "graveyard", "vicar", 1, 0.7)
		j.merge({"props": [], "ponds": 0, "beds": 0, "rocks": 0, "dog": false, "stones": 3, "trees": rv.randi_range(2, 3)}, true)
	else:
		_shape(j, at)
	# The name it asks for: the dregs and the churchyard take anyone, nobody decent takes
	# a Dire name, and a bigger lawn or a better street asks more.
	j.bar = 0.0 if dregs or j.get("venue", "") == "graveyard" else maxf(20.0, maxf([0.0, 55.0, 75.0][size_i],
		{"forward": 40.0, "L": 70.0}.get(j.get("shape", ""), 75.0 if j.get("venue", "") == "mansion" else 0.0)))
	return j


## The plot's shape, by neighbourhood (design doc, Levels): terraces at the bottom of the
## ladder, semis with the house set forward in the middle, odd-shaped detached plots at
## the top, and a plain rectangle now and then in each. Its own draws.
func _shape(j: Dictionary, at: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = j.seed + 6
	if r.randf() < 0.3:
		return
	if at < 40.0:
		j.shape = "terrace"
		j.size = TERRACE
	elif at < 70.0:
		j.shape = "forward"
	else:
		j.shape = "L"


## Turn a job into a venue's: its persona, its lawn size, and its pay scaled.
func _venue(j: Dictionary, venue: String, persona_key: String, size_i: int, pay_scale: float) -> void:
	var p: Dictionary = PERSONAS[persona_key]
	var size: Vector2i = LAWN_SIZES[size_i]
	var area := float(size.x * size.y) / (1280.0 * 720.0)
	j.venue = venue
	j.persona = persona_key
	j.brief = p.brief
	j.size = size
	j.target = p.target
	j.patience = 300.0 * area * p.patience
	j.pay = int(round((70.0 + 50.0 * size_i) * area * (1.0 + (p.target - 0.8)) * pay_scale / 5.0) * 5)
	if persona_key == "vicar": # dressed for it, so they read as one
		j.customer = "Reverend " + j.customer.split(" ")[-1]
		j.look.shirt = Face.CLERICAL
		j.look.collar = true


## The small things lying about a garden (Stone.KINDS). Its own draws, so the rest of
## the job stays as it was for a given seed.
func _props(seed_value: int, persona_key: String, size_i: int) -> Array[String]:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value + 3
	var out: Array[String] = []
	for i in r.randi_range(0, 1 + size_i) + (1 if persona_key == "gardener" else 0):
		out.append("gnome")
	if r.randf() < 0.3:
		out.append("flamingo")
	if r.randf() < 0.2:
		out.append("cone") # not theirs: nobody minds
	if r.randf() < 0.6:
		out.append("hose")
	return out


## The slice's hand-made lawn, used when no run is active (tests, editor play).
func default_job() -> Dictionary:
	return {
		"seed": 1, "customer": "Margaret Pemberton", "persona": "gardener",
		"brief": PERSONAS.gardener.brief,
		"look": {"hair_style": 3, "skin": 0, "hair": 4, "shirt": 1},
		"size": Vector2i(1280, 720), "fixed_layout": true,
		"target": 0.85, "patience": 165.0, "pay": 80, "indoors": 0.0, # always watching: tests rely on it
		"hedgehog_every": 7.0, "squirrel_every": 13.0,
	}


func job() -> Dictionary:
	return current_job if not current_job.is_empty() else default_job()


## The non-zero counts as "Name 3" (with "-$40" where it cost money), in TALLY order.
func tally_lines(counts: Dictionary, costs: Dictionary, beaten: Array = []) -> Array[String]:
	var out: Array[String] = []
	for k: String in TALLY:
		if counts.get(k, 0) > 0:
			var line: String = EVENTS[k] if EVENTS.has(k) else "%s %d" % [TALLY[k], counts[k]]
			if costs.get(k, 0.0) > 0.0:
				line += " (-$%d)" % roundi(costs[k])
			if k in beaten:
				line += " PERSONAL %s!" % ("BEST" if k in GOOD_TALLY else "WORST")
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
	in_job = false
	result.rep_after = reputation
	# Counts past your old record for a job (not firsts: everything's a first once).
	result.records = []
	for k: String in result.get("tally", {}):
		if EVENTS.has(k):
			continue # once a job: nothing to beat
		if records.get(k, 0) > 0 and result.tally[k] > records[k]:
			result.records.append(k)
		records[k] = maxi(records.get(k, 0), result.tally[k])
	best_score = maxi(best_score, total_earned)
	var cfg := ConfigFile.new()
	cfg.set_value("best", "score", best_score)
	cfg.set_value("best", "records", records)
	cfg.save(save_path)
	if current_job.has("regular"):
		_visited(current_job.regular, result)
	elif current_job.has("seed"):
		_maybe_offer(result)
	if result.get("cells", false) and day + 1 <= season_end(): # a night in the cells: tomorrow's gone
		var lost: Dictionary = calendar.get(day + 1, {})
		calendar[day + 1] = {"cells": true}
		if lost.has("regular") and regulars.has(lost.regular):
			_place(lost.regular, day + 1 + regulars[lost.regular].cadence)
	end_day()


## Seconds from the police being called to them arriving: your record shortens it.
func police_time(at_heat: float) -> float:
	return maxf(20.0, 60.0 - 8.0 * at_heat)


## Caught for a crime of this tier: damages are billed separately, this is the charge,
## and your record raises it.
func fine(tier: int, at_heat: float) -> int:
	return int((50.0 if tier <= 1 else 150.0) * (1.0 + 0.25 * at_heat))


func buy(item: String) -> bool:
	var price: int = MOWERS[item].price if MOWERS.has(item) else UPGRADES[item].price
	if money < price:
		return false
	if MOWERS.has(item):
		if item in owned:
			return false
		owned.append(item)
		equipped = item
	else:
		if item in upgrades:
			return false
		upgrades.append(item)
	money -= price
	return true


## What kit fetches sold: everything but the push mower.
func resale(item: String) -> int:
	return int((MOWERS[item].price if MOWERS.has(item) else UPGRADES[item].price) * RESALE)


## Kit that can be sold or taken, dearest first (the heavies take your best).
func sellable() -> Array[String]:
	var out: Array[String] = []
	out.assign(owned.filter(func(k: String) -> bool: return k != "push") + upgrades)
	out.sort_custom(func(a: String, b: String) -> bool: return resale(a) > resale(b))
	return out


func sell(item: String) -> void:
	money += resale(item)
	if MOWERS.has(item):
		owned.erase(item)
		if equipped == item: # onto the best you have left
			for k in owned:
				if equipped not in owned or MOWERS[k].price > MOWERS[equipped].price:
					equipped = k
	else:
		upgrades.erase(item)




## Friday's payday: the shark's vig and the week's living cost, then `extra` off what you
## owe (as much as you can spare). Short, the heavies take kit, dearest first, until its
## resale covers it (you keep the change). Then the coming week's paper. Returns {paid,
## off, taken, outcome}, outcome one of "paid", "repossessed", "free" (the debt's cleared)
## or "bankrupt" (nothing left covers it: the business is over, and so is its save).
func settle_payday(extra := 0) -> Dictionary:
	var owed := due()
	var taken: Array[String] = []
	for k in sellable():
		if money >= owed:
			break
		sell(k)
		taken.append(k)
	payday_pending = false
	if money < owed:
		money = 0
		run_over_reason = "bankrupt"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(business_path()))
		return {"paid": owed, "off": 0, "taken": taken, "outcome": "bankrupt"}
	money -= owed
	var off := mini(extra, mini(money, principal))
	money -= off
	principal -= off
	heat = maxf(0.0, heat - 1.0) # paid on time: things cool off
	paper = make_paper()
	save()
	var outcome := "free" if off > 0 and principal == 0 else ("repossessed" if taken else "paid")
	return {"paid": owed, "off": off, "taken": taken, "outcome": outcome}


# ---------------------------------------------------------------- the calendar

func day_of(y: int, m: int, d: int) -> int:
	return floori(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d}) / 86400.0)


## {year, month, day, weekday} for a day (today by default).
func date(d := day) -> Dictionary:
	return Time.get_date_dict_from_unix_time(d * 86400)


func date_text(d := day) -> String:
	var t := date(d)
	return "%s %d %s %d" % [DAYS[t.weekday], t.day, MONTHS[t.month - 1], t.year]


## The season's last day: the end of September.
func season_end() -> int:
	return day_of(year, LAST_MONTH + 1, 1) - 1


func vig() -> int:
	return roundi(principal * VIG)


## What Friday takes: the vig and the week's keep.
func due() -> int:
	return vig() + LIVING


## Today through the coming Friday (or the season's end): the days this week's paper books into.
func week_left() -> Array[int]:
	var out: Array[int] = [day]
	while date(out[-1]).weekday != FRIDAY and out[-1] < season_end():
		out.append(out[-1] + 1)
	return out


## Book an ad from the paper into this week's first free day. Returns the day, or -1 with
## the week full.
func book(ad: Dictionary) -> int:
	for d in week_left():
		if not calendar.has(d):
			calendar[d] = ad
			paper.erase(ad)
			save()
			return d
	return -1


## Today's booking: a job, {"cells": true}, or empty.
func today() -> Dictionary:
	return calendar.get(day, {})


## Off to today's job. Saved as started: quit before it's done and it loads as the blackout.
func start_job() -> void:
	current_job = today()
	in_job = true
	save()


## The day's over, worked or not: Friday brings payday, September's last day the winter.
func end_day() -> void:
	calendar.erase(day)
	if date().weekday == FRIDAY:
		payday_pending = true
	if day >= season_end():
		winter_pending = true
	day += 1
	save()


## Through the days with no job to the next booking, payday or the winter.
func skip() -> void:
	while not today().has("seed") and not payday_pending and not winter_pending:
		end_day()


## Carried mood: the next visit starts halfway between their usual and how the last ended.
func carried(j: Dictionary, last: float) -> float:
	return (PERSONAS[j.persona].get("start_mood", 60.0) + last) * 0.5


## How a visit really ended: their mood, less what they found once you'd gone (the
## aftermath's reputation is a fifth of the mood it cost).
func end_mood(r: Dictionary) -> float:
	var m: float = r.get("mood", 60.0)
	for n: Array in r.get("noticed", []):
		m += n[1] * 5.0
	return m


## After a good classifieds job: a hidden chance they ask you back, by how it ended and
## who they are. A no is silence.
func _maybe_offer(r: Dictionary) -> void:
	var j := current_job
	if r.outcome != "paid" or regulars.has(j.seed):
		return
	var m := end_mood(r)
	var ask: Array = REGULAR[j.persona]
	if _rng.randf() < clampf((m - 60.0) / 40.0, 0.0, 1.0) * ask[0]:
		offer = {"id": j.seed, "job": j, "cadence": ask[1], "rate": j.pay, "mood": carried(j, m), "day": day, "drift": []}


## Answer a regular's offer: "accept", "decline" or "haggle" (HAGGLE times the rate).
## Returns what they said: "yes", "grudging" (yes, but their mood drops), "walk" or "no".
func answer_offer(how: String) -> String:
	var o := offer
	offer = {}
	if how == "decline" or o.is_empty():
		save()
		return "no"
	var said := "yes"
	if how == "haggle": # the better their mood, the likelier yes; near the edge, grudging
		var yes := clampf((o.mood - 50.0) / 40.0, 0.0, 1.0)
		var roll := _rng.randf()
		if roll >= yes + 0.3:
			save()
			return "walk"
		if roll >= yes:
			said = "grudging"
			o.mood -= 10.0
		o.rate = roundi(o.rate * HAGGLE / 5.0) * 5
	regulars[o.id] = o
	_place(o.id, o.day + o.cadence)
	save()
	return said


## A regular's visit as a job: their garden by its seed, their rate (no tips), their
## carried mood, and whatever's crept in since.
func _visit(id: int) -> Dictionary:
	var reg: Dictionary = regulars[id]
	var j: Dictionary = reg.job.duplicate(true)
	j.regular = id
	j.pay = reg.rate
	j.start_mood = reg.mood
	j.drift = reg.drift.duplicate()
	return j


## Put a regular's next visit on the calendar near `target`: a clash shifts it a day
## either way; nothing fits and that visit's missed, on to the one after.
func _place(id: int, target: int) -> void:
	var reg: Dictionary = regulars[id]
	while target <= season_end():
		for d: int in [target, target + 1, target - 1]:
			if d > day and d <= season_end() and not calendar.has(d):
				calendar[d] = _visit(id)
				return
		target += reg.cadence


## A regular's visit is done: under the floor (or anything but paid) and they're gone;
## otherwise the mood carries, the garden drifts, and the next visit's booked.
func _visited(id: int, r: Dictionary) -> void:
	if not regulars.has(id):
		return
	var reg: Dictionary = regulars[id]
	var m := end_mood(r)
	if r.outcome != "paid" or m < FLOOR:
		drop(id)
		r.lost_regular = true
		return
	reg.mood = carried(reg.job, m)
	reg.drift.append(["gnome", "flamingo"][reg.drift.size() % 2]) # ponytail: a token drift; beds, ponds, leaves when it matters
	_place(id, day + reg.cadence)


## Let a regular go: they and their bookings leave the calendar.
func drop(id: int) -> void:
	regulars.erase(id)
	for d: int in calendar.keys():
		if calendar[d].get("regular", -1) == id:
			calendar.erase(d)


## September's done: the winter as one ledger. The living cost to March (short, the
## shark tops you up onto what you owe), who's back by their carried mood, reputation
## drifting toward the middle, then April. Returns {cost, topped, back, gone} (names).
func settle_winter() -> Dictionary:
	var cost := LIVING * WINTER_WEEKS
	var topped := maxi(0, cost - money)
	principal += topped
	money += topped - cost
	var back: Array[String] = []
	var gone: Array[String] = []
	for id: int in regulars.keys():
		var reg: Dictionary = regulars[id]
		if _rng.randf() < reg.mood / 100.0:
			back.append(reg.job.customer)
		else:
			gone.append(reg.job.customer)
			regulars.erase(id)
	reputation = lerpf(reputation, 50.0, 0.2)
	rep_trend = lerpf(rep_trend, 50.0, 0.2)
	year += 1
	day = day_of(year, start_month, 1)
	calendar = {}
	winter_pending = false
	for id: int in regulars:
		_place(id, day + posmod(id, regulars[id].cadence))
	paper = make_paper()
	save()
	return {"cost": cost, "topped": topped, "back": back, "gone": gone}


# ---------------------------------------------------------------- the save

## The business save, beside the best-score file (so a test's save_path covers both).
func business_path() -> String:
	return save_path.get_basename() + "_business.save"


func has_business() -> bool:
	return FileAccess.file_exists(business_path())


## Written between days (and at the board), one file per business. Ironman: no other.
func save() -> void:
	if not in_run:
		return
	var state := {}
	for k: String in SAVED:
		state[k] = get(k)
	var f := FileAccess.open(business_path(), FileAccess.WRITE)
	f.store_var(state)


## Back to the business as it was saved. On a job started and never finished: you
## blacked out. The job's failed, that client's lost, your name takes the hit.
func load_business() -> void:
	var f := FileAccess.open(business_path(), FileAccess.READ)
	var state: Dictionary = f.get_var()
	for k: String in state:
		if get(k) is Array:
			(get(k) as Array).assign(state[k])
		else:
			set(k, state[k])
	_rng.randomize()
	in_run = true
	run_over_reason = ""
	last_result = {}
	blackout = {}
	if in_job:
		in_job = false
		blackout = current_job
		if current_job.has("regular"):
			drop(current_job.regular)
		rep_trend = maxf(0.0, rep_trend - BLACKOUT_REP)
		reputation = maxf(0.0, reputation - BLACKOUT_REP * 0.5)
		end_day()
