extends Node
## Run state (autoload "Game"). A run is a chain of jobs picked from a job board;
## it ends when reputation runs out (bankruptcy). Score = total earned this run.

const SAVE_PATH := "user://best.cfg"

## Mower specs. The mower scene's own exports are the petrol defaults; a run
## applies the equipped spec on top.
const MOWERS := {
	"push": {
		"name": "Push mower", "price": 0, "power": "stamina",
		"max_speed": 150.0, "reverse_speed": 80.0, "accel": 420.0, "brake": 900.0,
		"turn_rate": 3.6, "cut_radius": 12.0, "max_fuel": 12.0, "fuel_burn": 1.0,
		"regen": 2.0, "empty_speed_scale": 0.4, "fuel_price": 0.0,
		"blurb": "Your legs are the engine. Narrow, slow, nimble. Rests to recover.",
	},
	"petrol": {
		"name": "Petrol mower", "price": 180, "power": "fuel",
		"max_speed": 220.0, "reverse_speed": 110.0, "accel": 600.0, "brake": 900.0,
		"turn_rate": 3.0, "cut_radius": 16.0, "max_fuel": 40.0, "fuel_burn": 1.0,
		"regen": 0.0, "empty_speed_scale": 0.35, "fuel_price": 0.25,
		"blurb": "Faster and wider. Burns fuel the whole time; refill at the truck.",
	},
	"rideon": {
		"name": "Ride-on mower", "price": 650, "power": "fuel",
		"max_speed": 300.0, "reverse_speed": 120.0, "accel": 340.0, "brake": 520.0,
		"turn_rate": 1.9, "cut_radius": 26.0, "max_fuel": 60.0, "fuel_burn": 1.5,
		"regen": 0.0, "empty_speed_scale": 0.2, "fuel_price": 0.25,
		"blurb": "Huge cut, huge speed, turns like a barge. Comes with a trailer.",
	},
}

const UPGRADES := {
	"tank": {"name": "Bigger tank", "price": 120, "blurb": "+50% fuel (or stamina) capacity."},
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
		"hedgehog": -40.0, "squirrel": -30.0, "flower": -2.0, "patience": 1.3, "target": 0.8,
	},
	"squirrel_hater": {
		"brief": ["The squirrels have dug up every bulb I own.", "I shan't be sad if one has an... accident."],
		"hedgehog": -20.0, "squirrel": 14.0, "flower": -2.0, "patience": 1.0, "target": 0.8,
	},
	"gardener": {
		"brief": ["DO NOT touch my prize flowerbeds.", "Tread on more than a couple of my flowers and you're finished."],
		"hedgehog": -20.0, "squirrel": -10.0, "flower": -6.0, "instant_flowers": 3, "patience": 1.1, "target": 0.85,
	},
	"busy": {
		"brief": ["I'm on a call. Just get it done, quickly.", "I'm paying for speed, not a masterpiece."],
		"hedgehog": -15.0, "squirrel": -5.0, "flower": -1.0, "patience": 0.7, "target": 0.7,
	},
	"perfectionist": {
		"brief": ["Every blade, please. I will be checking.", "Take the time you need to do it properly."],
		"hedgehog": -25.0, "squirrel": -15.0, "flower": -4.0, "patience": 1.6, "target": 0.96,
	},
	"grump": {
		"brief": ["Last lad was useless.", "Don't make me regret calling you."],
		"hedgehog": -30.0, "squirrel": -20.0, "flower": -3.0, "patience": 0.9, "target": 0.85, "start_mood": 45.0,
	},
}

const LAWN_SIZES := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var money := 0
var total_earned := 0
var reputation := 50.0 ## 0..100; the job board dries up as it falls
var rep_trend := 50.0 ## where behaviour is pushing reputation; reputation lags toward it
var owned: Array[String] = ["push"]
var equipped := "push"
var upgrades: Array[String] = []
var day := 1
var jobs_done := 0
var in_run := false
var current_job := {}
var last_result := {}
var best_score := 0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_score = cfg.get_value("best", "score", 0)


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
	day = 1
	jobs_done = 0
	in_run = true
	current_job = {}
	last_result = {}


## The mower spec for the equipped mower, with upgrades applied.
func mower_spec() -> Dictionary:
	var s: Dictionary = MOWERS[equipped].duplicate()
	if "tank" in upgrades:
		s.max_fuel *= 1.5
	if "blades" in upgrades:
		s.cut_radius *= 1.15
	return s


## How many offers the board shows at this reputation. Zero means bankrupt.
func offer_count() -> int:
	if reputation <= 0.0:
		return 0
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
	var p: Dictionary = PERSONAS[persona_key]
	# Better reputation unlocks bigger, better-paying lawns.
	var max_size := 0 if reputation < 40.0 else (1 if reputation < 70.0 else 2)
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
		"patience": 150.0 * area * p.patience,
		"pay": int(round((70.0 + 50.0 * size_i) * area * (1.0 + (target - 0.8)) / 5.0) * 5),
		"hedgehog_every": 7.0 / (1.0 + 0.25 * size_i),
		"squirrel_every": 13.0 / (1.0 + 0.25 * size_i),
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


## Apply a finished job's result to the run. Reputation drifts toward the trend
## rather than jumping, so bad behaviour catches up with you a job or two later.
func record_result(result: Dictionary) -> void:
	last_result = result
	if not in_run:
		return
	money += int(result.net)
	total_earned += maxi(0, int(result.paid))
	rep_trend = clampf(rep_trend + float(result.rep), 0.0, 100.0)
	reputation = clampf(reputation + (rep_trend - reputation) * 0.5 + float(result.rep) * 0.25, 0.0, 100.0)
	jobs_done += 1
	day += 1
	if total_earned > best_score:
		best_score = total_earned
		var cfg := ConfigFile.new()
		cfg.set_value("best", "score", best_score)
		cfg.save(SAVE_PATH)


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
