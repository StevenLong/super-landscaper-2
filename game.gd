extends Node
## Business state (autoload "Game"; design doc, The Business). Seasons of real days,
## April to September, on one clock (design doc, Time is the scarce thing): a booking is a
## window in the day, as many a day as you dare. Each Friday the loan shark takes his vig on
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
	"trailer": {"name": "Trailer", "price": 100, "blurb": "Tows a ride-on. Comes free with one."},
	"tank": {"name": "Bigger tank", "price": 120, "blurb": "+50% fuel or stamina."},
	"gloves": {"name": "Gardening gloves", "price": 40, "blurb": "Pick up a hedgehog without the prickles."},
	"blades": {"name": "Sharp blades", "price": 150, "blurb": "+15% cutting width."},
	"gear3": {"name": "Third gear", "price": 150, "blurb": "Ride-on: a faster gear."},
	"gear4": {"name": "Fourth gear", "price": 250, "blurb": "Ride-on: its top speed. After the third."},
}

## Packing the truck (design doc, Mowers and Equipment): what comes to a job is what you
## packed. The cab holds the push mower, always. The bed and the trailer (if you own
## one) are grids; kit is a rectangle of cells, turned on its side to fit. A ride-on
## only goes on the trailer. Petrol cans are cargo like the rest, as many as fit.
const GRIDS := {"bed": Vector2i(4, 3), "trailer": Vector2i(4, 4)}
const SHAPES := {"petrol": Vector2i(2, 3), "rideon": Vector2i(4, 4), "can": Vector2i(1, 1), "robot": Vector2i(2, 2)}
## Robot mowers (design doc, Mowers and Equipment): own as many as you like.
const ROBOT := {"name": "Robot mower", "price": 150, "blurb": "Mows by itself, in neat stripes. Slowly."}

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
const FLOOR := 35.0 ## a regular's visit ending under this: they want it cheaper; twice running and they're gone
const SOUR := 50.0 ## a regular's visit ending under this: they want you less often
const PLEASED := 85.0 ## a regular of a few visits ending over this may offer more (visits, or a better rate)
const RAISE_MOOD := 60.0 ## a regular's visit ending this well: you can ask for a raise
const LOYAL_RAISE := 1.1 ## a regular back after the winter: their rate creeps up this much
const UPFRONT_OFF := 0.9 ## a month up front comes at this share of the visits' pay
const HAGGLE := 1.2 ## pushing for more asks this much, by default (you pick the figure)
const ASK_MAX := 1.5 ## the most you can ask, times their rate
const ASK_SLOPE := 2.5 ## each 10% asked under (over) HAGGLE adds (takes) this tenth to the chance of a yes
const OFFER_REP := 2.0 ## reputation for being asked to become a regular, even if you say no
const BLACKOUT_REP := 15.0 ## the reputation a blacked-out job costs (on the trend)
## Who asks to become a regular: [chance factor, visits every so many days].
const REGULAR := {"nature": [1.0, 14], "squirrel_hater": [1.0, 14], "gardener": [0.6, 14], "busy": [1.3, 7],
	"perfectionist": [0.5, 7], "grump": [0.4, 28], "toff": [0.7, 7], "vicar": [1.0, 14]}
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August",
	"September", "October", "November", "December"]
const PAPER := [-25.0, -12.0, 0.0, 0.0, 12.0, 25.0] ## a week's ads against your name: two below, two around, two above (repeating as the paper swells)
const PAPER_SIZE := {4: 5, 5: 8, 6: 10, 7: 10, 8: 7, 9: 5} ## ads a week by month: the paper swells as the grass grows
const PEAK := [5, 6, 7] ## the months regulars want you back sooner (half their cadence, a week at least)
## Critters by month (design doc, Jobs stay fresh): the usual gap between arrivals times
## these, [hedgehogs, squirrels]; under 1 is more of them. Guesses.
const SEASON_CRITTERS := {4: [1.3, 1.0], 5: [1.0, 1.0], 6: [1.0, 1.1], 7: [0.9, 1.1], 8: [0.8, 0.9], 9: [0.75, 0.7]}
## Event days: now and then one kind's out in force, at every job that day, and the
## morning's news says so. The gaps times these; room for more of them at once.
const DAY_EVENTS := {
	"hedgehogs": {"months": [5, 6, 7], "news": "Hedgehogs everywhere today: it's their courting season.", "hedgehog": 0.35, "squirrel": 1.0},
	"squirrels": {"months": [8, 9], "news": "The squirrels have lost their minds today, burying for the winter.", "hedgehog": 1.0, "squirrel": 0.35, "squirrel_speed": 1.5},
}
const EVENT_CHANCE := 0.12 ## of a day in an event's months
const EVENT_CROWD := 8 ## critters at once on an event day (5 usually)
## The day's clock (design doc, Time is the scarce thing). Minutes since midnight. Guesses.
const DAY_START := 480 ## 8am
const DAY_END := 1200 ## 8pm: no driving to a job after this
const MPS := 0.4 ## in a job, minutes of the day a real second: a small lawn's 5 minutes of patience is 2 hours
const SLACK := 1.5 ## a booking's window is their patience times this: you needn't go the moment it opens
const DRIVE := 30 ## minutes to drive to a job
const RING_TIME := 10 ## minutes a phone call takes
const NO_SHOW_REP := 6.0 ## a classified you never turned up to (on the trend)
const NO_SHOW_MOOD := 10.0 ## a regular's visit missed
const REP_CLIMB := 2.0 ## a good job's reputation times (1 - trend/100) to this: at 50 a quarter, at 75 a sixteenth
const REACH := 15.0 ## how far under an ad's bar a call can still get a yes
const DAYS := ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const RESALE := 0.5 ## what kit fetches sold (by you or the heavies), as a share of its price

## The crime ladder (design doc, The Business: the record): what a conviction weighs by
## tier. 0 isn't a crime (rep only), 1 a nuisance, 2 assault, 3 the worst (not built:
## nothing can kill a customer yet). A job's witnessed crimes add up to its charge; only
## court turns a charge into record.
const RECORD := [0.0, 1.0, 2.0, 5.0]
const HIGH_RECORD := 3.0 ## from here, a nuisance gets the police called too
## Court and sentences (the numbers are guesses, to be felt out).
const LAWYERS := [["Represent yourself", 0, 0.1, "a slim chance"], ["Mr. Gubbins, solicitor", 60, 0.3, "a fair chance"],
	["Crumb & Crumb", 200, 0.5, "a good chance"], ["Sir Hilary Ashdown QC", 600, 0.75, "the best money buys"]] ## [who, fee, walk-free chance, how they sound]
const SUMMONS_DAYS := 3 ## escaped the scene: court on the first free day this many on
const MENACE := 8.0 ## from this record, community service becomes jail
const PRISON := 16.0 ## a record this long is prison: the business is over
const SERVICE_REP := 5.0 ## community service done, on top of the job's own

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
var equipped := "push" ## the mower a job starts on: the best one packed (start_job)
var packed: Array[Dictionary] = [] ## what's in the truck: {kind, grid, at (Vector2i), turned}
var robots := 0 ## robot mowers owned
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
	"windows": "Windows put through", "car_dents": "Dents in the customer's car", "topiary": "Topiary clipped the hard way", "saplings": "Saplings snapped", "dents": "Dents in your own truck",
	"own_goals": "Stones at your own mower", "flowers": "Flowers flattened",
	"stones_mowed": "Stones through the blades", "stones_thrown": "Things thrown",
	"gnomes_mowed": "Gnomes shattered", "flamingos_mowed": "Flamingos shredded", "cones_mowed": "Cones sent flying",
	"hoses_mowed": "Hoses cut", "urns_mowed": "Urns smashed", "balls_mowed": "Tennis balls shredded", "litters_mowed": "Litter shredded", "hoops_mowed": "Croquet hoops sent flying", "jerrycans_mowed": "Petrol cans mowed",
	"fetches": "Balls fetched", "animals_thrown": "Animals thrown", "prickled": "Hedgehogs grabbed bare-handed",
	"bitten": "Bitten by squirrels", "own_head": "Stones on your own head",
	"trees_hit": "Trees stoned", "splashes": "Stones fed to the pond",
	"stones_picked": "Stones picked up", "stones_binned": "Stones tidied into the truck", "litter_binned": "Litter tidied into the truck",
	"cans": "Cans of fuel carried", "sent_back": "Times sent back out to finish",
}
## What can only happen once a job: shown as the event, never a count or a record.
const EVENTS := {"dog_bowled": "Bowled the dog over", "dog_returned": "Walked the dog home",
	"knockouts": "Knocked the customer out cold", "robberies": "Rifled their pockets", "hoses_mowed": "Cut the hose"}
## The counts it's good to beat: a record in one of these is a personal best. A record
## in anything else is a personal worst.
const GOOD_TALLY := ["dog_returned", "fetches", "stones_picked", "stones_binned", "litter_binned", "cans"]
## Button prompts follow what you last touched: keyboard keys, or an Xbox-style pad.
const PROMPTS := {"interact": ["E", "A"], "hop": ["F", "B"], "throw": ["Q", "X"], "look": ["Tab", "Y"], "pause": ["Esc", "Start"], "sprint": ["Shift", "A"],
	"gear_up": ["Shift", "RB"], "gear_down": ["Ctrl", "LB"], "horn": ["H", "L3"]}
var pad := false

var best_score := 0
var records := {} ## the most of each TALLY key in any one job, ever (saved)
var run_over_reason := "" ## "" while running; "bankrupt" or "won" once it's over
var record := 0.0 ## convictions, each weighing its tier (RECORD): fines, sentences and the police follow it

var start_month := 4 ## a knob: June reaches a busy calendar sooner for play-checks
var year := 1980
var day := 0 ## today, not yet over, in days since 1970 (Time's unix time / a day)
var minute := DAY_START ## now, in minutes since midnight
var principal := 0
var calendar := {} ## day -> what's booked, earliest first: jobs (a classified, a regular's visit, community service), or a day taken whole by {"court": case} or {"jail": true}
var paper: Array[Dictionary] = [] ## this week's ads not yet booked, each with its day and window
var next_job := {} ## the booking picked on the board, for packing and the job
var booked := {} ## the job under way as it was booked, before the day (critters, arriving late) touched it
var missed: Array[String] = [] ## who you didn't turn up for, for the board to say
var regulars := {} ## id (their first job's seed) -> {id, job, cadence, rate, mood, drift}
var offer := {} ## a regular's offer after the job just done, until answered
var upfront := {} ## a loyal regular's offer of a month up front {id, visits, amount}, until answered
var payday_pending := false
var winter_pending := false
var in_job := false ## a job started and not finished: loading onto it is the blackout
var blackout := {} ## the job you blacked out on, for the board to break the news
## What the save keeps: the whole business.
const SAVED := ["money", "total_earned", "reputation", "rep_trend", "owned", "equipped", "packed", "robots", "upgrades",
	"jobs_done", "record", "run_tally", "run_tally_cost", "start_month", "year", "day", "minute", "principal",
	"calendar", "paper", "regulars", "offer", "upfront", "booked", "payday_pending", "winter_pending", "in_job", "current_job"]

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
	packed = []
	robots = 0
	upgrades = []
	jobs_done = 0
	in_run = true
	current_job = {}
	last_result = {}
	run_tally = {}
	run_tally_cost = {}
	record = 0.0
	run_over_reason = ""
	year = 1980
	day = day_of(year, start_month, 1)
	minute = DAY_START
	principal = PRINCIPAL
	calendar = {}
	next_job = {}
	missed = []
	regulars = {}
	offer = {}
	upfront = {}
	payday_pending = false
	winter_pending = false
	in_job = false
	blackout = {}
	paper = make_paper()
	save()


## The mower spec for a mower (the equipped one by default), with upgrades applied.
func mower_spec(kind := "") -> Dictionary:
	var s: Dictionary = MOWERS[kind if kind != "" else equipped].duplicate()
	if "tank" in upgrades:
		s.max_fuel *= 1.5
	if "blades" in upgrades:
		s.cut_radius *= 1.15
	s.gears = 2 + int("gear3" in upgrades) + int("gear3" in upgrades and "gear4" in upgrades) # a ride-on's
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
	if j.has("from"):
		parts.append("[color=#7a1c14]%s%s to %s.[/color]" % ["%s, " % day_word(j.day) if j.has("day") else "",
			time_text(j.from), time_text(j.by)])
	return "[color=#7a1c14]%s[/color] %s" % [ad[0], " ".join(parts)]


## The week's paper (design doc, The Business: you ring the ad): a spread round your
## name, not only what it earns you. Each ad is made as if for a name PAPER away from
## yours (give or take 5), in no particular order.
func make_paper() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var week := week_left()
	for i in PAPER_SIZE.get(date().month, 5):
		var o := make_job(_rng.randi(), clampf(reputation + PAPER[i % PAPER.size()] + _rng.randf_range(-5.0, 5.0), 0.0, 100.0))
		o.day = week[_rng.randi() % week.size()]
		out.append(o)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return [a.day, a.from] < [b.day, b.from])
	return out


## The chance ringing this ad gets a yes: certain at or over its bar, falling away over
## REACH below it, so you can push a little higher.
func yes_chance(ad: Dictionary) -> float:
	return clampf((reputation - ad.bar + REACH) / REACH, 0.0, 1.0)


## Ring an ad: an answer at once, the call's time either way. Yes books it on its day;
## no stamps it for the week. Returns what they said.
func ring(ad: Dictionary) -> String:
	minute += RING_TIME
	var chance := yes_chance(ad)
	if _rng.randf() < chance and book(ad) >= 0:
		var when := "%s after %s" % [day_word(ad.day) if ad.day > day + 1 else day_word(ad.day).to_lower(), time_text(ad.from)]
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
		for i in rv.randi_range(4, 6): # a croquet lawn
			j.props.append("hoop")
	elif not dregs and at < 20.0 and rv.randf() < 0.5:
		_churchyard(j, rv)
	else:
		_shape(j, at)
	# The name it asks for: the dregs and the churchyard take anyone, nobody decent takes
	# a Dire name, and a bigger lawn or a better street asks more.
	j.bar = 0.0 if dregs or j.get("venue", "") == "graveyard" else maxf(20.0, maxf([0.0, 55.0, 75.0][size_i],
		{"forward": 40.0, "L": 70.0}.get(j.get("shape", ""), 75.0 if j.get("venue", "") == "mansion" else 0.0)))
	_window(j)
	return j


## When they want it done: a window sized from their patience (SLACK times it, on the
## day's clock), opening on the half hour somewhere it fits in the day. Its own draws.
func _window(j: Dictionary) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = j.seed + 7
	var length := clampi(roundi(j.patience * MPS * SLACK / 30.0) * 30, 60, DAY_END - DAY_START)
	j.from = DAY_START + 30 * r.randi_range(0, floori((DAY_END - DAY_START - length) / 30.0))
	j.by = j.from + length


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


func _churchyard(j: Dictionary, rv: RandomNumberGenerator) -> void:
	_venue(j, "graveyard", "vicar", 1, 0.7)
	j.erase("shape")
	j.merge({"props": [], "ponds": 0, "beds": 0, "rocks": 0, "dog": false, "stones": 3, "trees": rv.randi_range(2, 3)}, true)


## Community service (design doc, Levels): the council's churchyard, unpaid. Done, it
## mends your name (SERVICE_REP).
func service_job() -> Dictionary:
	var j := make_job(_rng.randi(), 10.0)
	if j.get("venue", "") != "graveyard":
		var rv := RandomNumberGenerator.new()
		rv.seed = j.seed + 5
		_churchyard(j, rv)
	j.service = true
	j.pay = 0
	j.from = DAY_START + 60 # the council's hours, the day's taken
	j.by = DAY_START + 540
	j.brief = ["The council sent you, did they? Community service.", "Mind the graves. And no nonsense this time."]
	return j


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
	if r.randf() < 0.35: # blown in: nobody's, and only minded if they see it shredded
		for i in r.randi_range(1, 3):
			out.append("litter")
	if r.randf() < 0.25: # newly planted: rammed, it snaps (main.gd)
		out.append("sapling")
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


## How much of a gain in reputation lands: the better known you are, the less (193d).
func climb(gain: float) -> float:
	return gain * pow(1.0 - rep_trend / 100.0, REP_CLIMB)


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
	# Only the gains are cut, the job's and what they noticed; losses land whole (193d).
	var lines: Array = result.get("rep_lines", []) + result.get("noticed", [])
	var gains := maxf(0.0, result.rep) if lines.is_empty() else 0.0
	for l: Array in lines:
		gains += maxf(0.0, l[1])
	var cut := climb(gains) - gains
	result.rep += cut
	if roundi(cut) != 0:
		result.rep_cut = cut # the summary's book shows it
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
	elif current_job.has("seed") and not current_job.has("service"):
		_maybe_offer(result)
	if result.get("charge", 0.0) > 0.0 and (result.outcome == "nicked" or result.get("police", false)):
		_charge(result)
	# The day goes on: it's as late as you left (a night in the cells ends it).
	if current_job.has("from"):
		minute = mini(1439, maxi(minute, current_job.from + roundi(float(result.get("elapsed", 0.0)) * MPS)))
	if result.outcome == "nicked":
		end_day()
	save()


## Seconds from the police being called to them arriving: your record shortens it.
func police_time(at_record: float) -> float:
	return maxf(20.0, 60.0 - 8.0 * at_record)


## Caught for a crime of this tier: damages are billed separately, this is the charge,
## and your record raises it.
func fine(tier: int, at_record: float) -> int:
	return int((50.0 if tier <= 1 else 150.0) * (1.0 + 0.25 * at_record))


func price_of(item: String) -> int:
	return ROBOT.price if item == "robot" else (MOWERS[item].price if MOWERS.has(item) else UPGRADES[item].price)


func buy(item: String) -> bool:
	var price := price_of(item)
	if money < price:
		return false
	if item == "robot":
		robots += 1
		pack_first(item)
	elif MOWERS.has(item):
		if item in owned:
			return false
		owned.append(item)
		equipped = item
		if item == "rideon" and "trailer" not in upgrades: # bundled
			upgrades.append("trailer")
		pack_first(item)
	else:
		if item in upgrades or (item == "gear4" and "gear3" not in upgrades):
			return false
		upgrades.append(item)
	money -= price
	return true


## Kit left behind when you fled the police: gone, no money for it.
func lose(item: String) -> void:
	var cash := money
	sell(item)
	money = cash


## What kit fetches sold: everything but the push mower.
func resale(item: String) -> int:
	return int(price_of(item) * RESALE)


## Kit that can be sold or taken, dearest first (the heavies take your best).
func sellable() -> Array[String]:
	var out: Array[String] = []
	out.assign(owned.filter(func(k: String) -> bool: return k != "push") + upgrades)
	for i in robots:
		out.append("robot")
	out.sort_custom(func(a: String, b: String) -> bool: return resale(a) > resale(b))
	return out


func sell(item: String) -> void:
	if item == "gear3" and "gear4" in upgrades: # the fourth's no use without the third: it goes too
		sell("gear4")
	money += resale(item)
	if item == "robot": # one of them; off the truck only if none's left at home
		robots -= 1
		if packed_count("robot") > robots:
			packed.erase(packed.filter(func(p: Dictionary) -> bool: return p.kind == "robot")[-1])
		return
	packed = packed.filter(func(p: Dictionary) -> bool: return p.kind != item and not (item == "trailer" and p.grid == "trailer"))
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


## A day as you'd say it: today, tomorrow, or its weekday.
func day_word(d: int) -> String:
	return "Today" if d == day else ("Tomorrow" if d == day + 1 else DAYS[date(d).weekday])


## Minutes since midnight as a clock reads: 9:30am, 12pm.
func time_text(m: int) -> String:
	var h := floori(m / 60.0) % 24
	var ampm := "am" if h < 12 else "pm"
	var hh := (h + 11) % 12 + 1
	return "%d%s" % [hh, ampm] if m % 60 == 0 else "%d:%02d%s" % [hh, m % 60, ampm]


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


## What's booked on a day, earliest first.
func bookings(d := day) -> Array:
	return calendar.get(d, [])


## A day taken whole: court, jail, community service.
func blocked(d: int) -> bool:
	return bookings(d).any(func(b: Dictionary) -> bool: return b.has("court") or b.has("jail") or b.has("service"))


func day_free(d: int) -> bool:
	return bookings(d).is_empty()


## Put a booking on a day, in time order.
func _add(d: int, b: Dictionary) -> void:
	var l: Array = bookings(d).duplicate()
	b.day = d
	l.append(b)
	l.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.get("from", 0) < y.get("from", 0))
	calendar[d] = l


## Why an ad can't be booked, or "" if it can: its day's gone, taken whole, or its
## window shuts before you could get there.
func cant_book(ad: Dictionary) -> String:
	if ad.day < day:
		return "Gone"
	if blocked(ad.day):
		return "Day taken"
	if ad.day == day and not can_go(ad, RING_TIME):
		return "Too late"
	return ""


## Book an ad from the paper on its day, however full (the gamble's yours). Returns the
## day, or -1 if it can't be (its day gone or taken whole).
func book(ad: Dictionary) -> int:
	if ad.day < day or blocked(ad.day):
		return -1
	_add(ad.day, ad)
	paper.erase(ad)
	save()
	return ad.day


## Today's first booking: a job, {"court": case}, {"jail": true}, or empty.
func today() -> Dictionary:
	var l := bookings()
	return l[0] if not l.is_empty() else {}


## A day's event (DAY_EVENTS), or "": the same for a day however often you ask.
func day_event(d := day) -> String:
	var r := RandomNumberGenerator.new()
	r.seed = d * 7919 + 13
	var month: int = date(d).month
	var keys := DAY_EVENTS.keys().filter(func(k: String) -> bool: return month in DAY_EVENTS[k].months)
	if keys.is_empty() or r.randf() >= EVENT_CHANCE:
		return ""
	return keys[r.randi() % keys.size()]


## How many jobs are booked on a day.
func jobs_on(d: int) -> int:
	return bookings(d).filter(func(b: Dictionary) -> bool: return b.has("seed")).size()


## Today's jobs still to go to, earliest first.
func jobs_today() -> Array:
	return bookings().filter(func(b: Dictionary) -> bool: return b.has("seed"))


## When you'd get to a booking if you set off now: the drive, or its window opening.
func arrival(b: Dictionary) -> int:
	return maxi(minute + DRIVE, b.get("from", 0))


## Whether you can still get there inside its window, before the day's out (`first`:
## minutes of something else before you set off, a call).
func can_go(b: Dictionary, first := 0) -> bool:
	return minute + first < DAY_END and minute + first + DRIVE <= b.get("by", DAY_END)


## Off to a job (the one picked on the board, else today's first), on the best mower
## packed. You arrive when arrival() says, and their patience is what's left of the
## window: `late` seconds of it gone already. Saved as started: quit before it's done and
## it loads as the blackout.
func start_job(b := {}) -> void:
	if b.is_empty():
		b = next_job if not next_job.is_empty() else today()
	next_job = {}
	upfront = {} # an offer's for the summary it came with, not later
	equipped = "rideon" if packed_has("rideon") else ("petrol" if packed_has("petrol") else "push")
	booked = b.duplicate(true)
	current_job = b.duplicate(true)
	if b.has("regular") and regulars.has(b.regular) and regulars[b.regular].get("prepaid", 0) > 0:
		current_job.pay = 0 # paid up front
		current_job.prepaid = true
	# The critters: the month's, and the day's event if there is one.
	var ev := day_event()
	var e: Dictionary = DAY_EVENTS.get(ev, {})
	var m: Array = SEASON_CRITTERS.get(date().month, [1.0, 1.0])
	if current_job.has("hedgehog_every"):
		current_job.hedgehog_every *= m[0] * e.get("hedgehog", 1.0)
		current_job.squirrel_every *= m[1] * e.get("squirrel", 1.0)
	if ev != "":
		current_job.event = ev
		current_job.max_animals = EVENT_CROWD
		current_job.squirrel_speed = e.get("squirrel_speed", 1.0)
	if b.has("from"):
		var at := arrival(b)
		current_job.patience = (b.by - b.from) / MPS
		current_job.late = (at - b.from) / MPS
		minute = at
	_unbook(b)
	in_job = true
	save()


## Take a booking off today's list.
func _unbook(b: Dictionary) -> void:
	var l: Array = bookings().filter(func(x: Dictionary) -> bool: return x != b)
	if l.is_empty():
		calendar.erase(day)
	else:
		calendar[day] = l


## The day's over, worked or not: whatever's left you never turned up to. Friday brings
## payday, September's last day the winter.
func end_day() -> void:
	for b: Dictionary in jobs_today():
		_no_show(b)
	calendar.erase(day)
	if date().weekday == FRIDAY:
		payday_pending = true
	if day >= season_end():
		winter_pending = true
	day += 1
	minute = DAY_START
	save()


## A booking you never turned up to: a classified's word gets round; a regular's mood
## drops and their next visit's booked; community service waits for your next free day.
func _no_show(b: Dictionary) -> void:
	if b.has("service"):
		var d := day + 1
		while not day_free(d):
			d += 1
		_add(d, b)
		return
	missed.append(b.customer)
	if b.has("regular") and regulars.has(b.regular):
		var reg: Dictionary = regulars[b.regular]
		reg.mood -= NO_SHOW_MOOD
		_place(b.regular, day + cadence_now(reg))
	else:
		rep_trend = maxf(0.0, rep_trend - NO_SHOW_REP)


## Through the days with no job (or in jail) to the next booking, court, payday or the winter.
func skip() -> void:
	while not today().has("seed") and not today().has("court") and not payday_pending and not winter_pending:
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
	var j := booked if not booked.is_empty() else current_job # the job as booked: not today's critters or patience
	if r.outcome != "paid" or regulars.has(j.seed):
		return
	var m := end_mood(r)
	var ask: Array = REGULAR[j.persona]
	if _rng.randf() < clampf((m - 60.0) / 40.0, 0.0, 1.0) * ask[0]:
		offer = {"id": j.seed, "job": j, "cadence": ask[1], "rate": j.pay, "mood": carried(j, m), "day": day, "drift": []}


## Answer a regular's offer: "accept", "decline" or "haggle" for `ask` a visit (HAGGLE
## times the rate if not given). Returns what they said: "yes", "grudging" (yes, but
## their mood drops), "walk" or "no". Declining still earns a little name: you were wanted.
func answer_offer(how: String, ask := 0) -> String:
	var o := offer
	offer = {}
	if how == "decline" or o.is_empty():
		if not o.is_empty():
			var gain := climb(OFFER_REP)
			rep_trend = minf(100.0, rep_trend + gain)
			reputation = minf(100.0, reputation + gain)
		save()
		return "no"
	var said := "yes"
	if how == "haggle": # the better their mood, the likelier yes; near the edge, grudging; ask less, likelier
		if ask <= 0:
			ask = roundi(o.rate * HAGGLE / 5.0) * 5
		var yes := clampf((o.mood - 50.0) / 40.0 + (HAGGLE - float(ask) / o.rate) * ASK_SLOPE, 0.0, 1.0)
		var roll := _rng.randf()
		if roll >= yes + 0.3:
			save()
			return "walk"
		if roll >= yes:
			said = "grudging"
			o.mood -= 10.0
		o.rate = ask
	regulars[o.id] = o
	_place(o.id, o.day + cadence_now(o))
	save()
	return said


## Money to the nearest $5.
func _round5(x: float) -> int:
	return roundi(x / 5.0) * 5


## A rate cut (`share` under 1) or raised, always by at least $5 (never under $5).
func _rate(rate: int, share: float) -> int:
	return maxi(5, floori(rate * share / 5.0 + 1e-6) * 5) if share < 1.0 else ceili(rate * share / 5.0 - 1e-6) * 5 # float slop: 100 * 1.1 is 110.00000000000001


## Ask a regular for a raise to `ask` a visit, after a good visit (the haggle, design doc
## Regulars change softly): the happier they are and the less you ask, the likelier a yes;
## near the edge, yes but sore; past it, they can't afford you and say so, a little put
## out. Returns "yes", "grudging" or "no".
func ask_raise(id: int, ask: int) -> String:
	var reg: Dictionary = regulars[id]
	var yes := clampf((reg.mood - 50.0) / 40.0 + (HAGGLE - float(ask) / reg.rate) * ASK_SLOPE, 0.0, 1.0)
	var roll := _rng.randf()
	var said := "yes"
	if roll >= yes + 0.3:
		reg.mood -= 5.0
		said = "no"
	else:
		if roll >= yes:
			reg.mood -= 10.0
			said = "grudging"
		reg.rate = ask
	_rebook(id)
	save()
	return said


## A month of a loyal regular's visits paid now, at a discount: take it, and those visits
## pay nothing on the day. Drop them (or lose them) before they're done and you owe the
## rest back.
func take_upfront() -> void:
	var u := upfront
	upfront = {}
	if u.is_empty() or not regulars.has(u.id):
		return
	var reg: Dictionary = regulars[u.id]
	money += u.amount
	reg.prepaid = u.visits
	reg.prepaid_each = float(u.amount) / u.visits
	save()


## What you owe a regular you're losing for visits they paid up front: paid back, once.
func _repay(reg: Dictionary) -> int:
	var owed := roundi(maxi(0, reg.get("prepaid", 0)) * reg.get("prepaid_each", 0.0))
	money -= owed
	reg.prepaid = 0
	return owed


## Their booked visits take their terms as they stand now (rate, start mood).
func _rebook(id: int) -> void:
	for l: Array in calendar.values():
		for b: Dictionary in l:
			if b.get("regular", -1) == id:
				b.pay = regulars[id].rate
				b.start_mood = regulars[id].mood


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


## How often a regular wants you just now: at the season's peak, twice as often (a week
## at least), since the grass grows.
func cadence_now(reg: Dictionary) -> int:
	return maxi(7, floori(reg.cadence / 2.0)) if date().month in PEAK else reg.cadence


## Put a regular's next visit on the calendar near `target`, however busy the day (their
## window's their usual one): only a day taken whole shifts it a day either way; nothing
## fits and that visit's missed, on to the one after.
func _place(id: int, target: int) -> int:
	var reg: Dictionary = regulars[id]
	while target <= season_end():
		for d: int in [target, target + 1, target - 1]:
			if d > day and d <= season_end() and not blocked(d):
				_add(d, _visit(id))
				return d
		target += reg.cadence
	return -1


## A regular's visit is done. Anything but paid, or a second visit running under the
## floor, and they're gone. Otherwise their terms move softly with how it ended (_terms),
## the mood carries, the garden drifts, and the next visit's booked. A good one and you
## can ask for a raise; a loyal one may offer a month up front.
func _visited(id: int, r: Dictionary) -> void:
	if not regulars.has(id):
		return
	var reg: Dictionary = regulars[id]
	var m := end_mood(r)
	reg.visits = reg.get("visits", 0) + 1
	if current_job.get("prepaid", false):
		reg.prepaid -= 1
	if r.outcome != "paid" or (m < FLOOR and reg.get("strikes", 0) >= 1):
		r.owed_back = _repay(reg)
		drop(id)
		r.lost_regular = true
		return
	r.terms = _terms(reg, m)
	r.can_raise = m >= RAISE_MOOD
	reg.mood = carried(reg.job, m)
	if reg.get("seasons", 0) >= 1 and m >= 80.0 and reg.get("prepaid", 0) <= 0 and _rng.randf() < 0.3:
		var n := maxi(1, floori(28.0 / cadence_now(reg)))
		upfront = {"id": id, "visits": n, "amount": _round5(n * reg.rate * UPFRONT_OFF)}
	reg.drift.append(["gnome", "flamingo"][reg.drift.size() % 2]) # ponytail: a token drift; beds, ponds, leaves when it matters
	var every := cadence_now(reg)
	r.sooner = every < reg.cadence and r.terms != "fewer" # wanting you less, the summer doesn't count as more
	_place(id, day + every)


## How a regular's terms move after a visit ending in mood `m` (design doc, Regulars
## change softly): under the floor, a cheaper rate (and a strike: twice running loses
## them); sour, fewer visits (cheaper once they're four-weekly); pleased, after a few
## visits, now and then more visits or a better rate. Returns what changed, or "".
func _terms(reg: Dictionary, m: float) -> String:
	if m < FLOOR:
		reg.strikes = 1
		reg.rate = _rate(reg.rate, 0.9)
		return "cheaper"
	reg.strikes = 0
	if m < SOUR:
		if reg.cadence < 28:
			reg.cadence *= 2
			return "fewer"
		reg.rate = _rate(reg.rate, 0.9)
		return "cheaper"
	if m >= PLEASED and reg.visits >= 3 and _rng.randf() < 0.5:
		if reg.cadence > 7:
			reg.cadence = floori(reg.cadence / 2.0)
			return "more"
		reg.rate = _rate(reg.rate, 1.1)
		return "better"
	return ""


## Let a regular go: they and their bookings leave the calendar, and what they paid up
## front for visits not yet done goes back. Returns that.
func drop(id: int) -> int:
	var owed := _repay(regulars[id]) if regulars.has(id) else 0
	regulars.erase(id)
	if upfront.get("id", -1) == id:
		upfront = {}
	for d: int in calendar.keys():
		var l: Array = bookings(d).filter(func(b: Dictionary) -> bool: return b.get("regular", -1) != id)
		if l.is_empty():
			calendar.erase(d)
		else:
			calendar[d] = l
	return owed


## September's done: the winter as one ledger. The living cost to March (short, the
## shark tops you up onto what you owe), who's back by their carried mood, reputation
## drifting toward the middle, then April. Returns {cost, topped, back, gone} (names).
func settle_winter() -> Dictionary:
	var back: Array[String] = []
	var gone: Array[String] = []
	var owed_back := 0
	for id: int in regulars.keys():
		var reg: Dictionary = regulars[id]
		if _rng.randf() < reg.mood / 100.0:
			reg.seasons = reg.get("seasons", 0) + 1 # loyalty compounds: their rate creeps up
			reg.rate = _rate(reg.rate, LOYAL_RAISE)
			back.append("%s ($%d)" % [reg.job.customer, reg.rate])
		else:
			gone.append(reg.job.customer)
			owed_back += _repay(reg) # what they paid up front for next year goes back
			regulars.erase(id)
	var cost := LIVING * WINTER_WEEKS
	var topped := maxi(0, cost - money)
	principal += topped
	money += topped - cost
	reputation = lerpf(reputation, 50.0, 0.2)
	rep_trend = lerpf(rep_trend, 50.0, 0.2)
	record = maxf(0.0, record - 1.0) # a winter fades it, a little
	var owed: Array = []
	for l: Array in calendar.values():
		owed.append_array(l.filter(func(b: Dictionary) -> bool: return b.has("court") or b.has("service")))
	year += 1
	day = day_of(year, start_month, 1)
	minute = DAY_START
	calendar = {}
	winter_pending = false
	for i in owed.size(): # court and service the season ran out on come first in spring
		calendar[day + i] = [owed[i]]
	for id: int in regulars:
		_place(id, day + posmod(id, regulars[id].cadence))
	paper = make_paper()
	save()
	return {"cost": cost, "topped": topped, "back": back, "gone": gone, "owed_back": owed_back}


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
	minute = DAY_START # a save from before the clock has none
	for k: String in state:
		if get(k) is Array:
			(get(k) as Array).assign(state[k])
		else:
			set(k, state[k])
	_rng.randomize()
	_upgrade_save()
	in_run = true
	run_over_reason = ""
	last_result = {}
	blackout = {}
	if in_job:
		in_job = false
		blackout = current_job
		if current_job.has("regular"):
			blackout.owed_back = drop(current_job.regular)
		elif current_job.has("service"): # a sentence isn't wiped by blacking out: the next free day
			var d := day + 1
			while not day_free(d):
				d += 1
			_add(d, booked if not booked.is_empty() else current_job)
		rep_trend = maxf(0.0, rep_trend - BLACKOUT_REP)
		reputation = maxf(0.0, reputation - BLACKOUT_REP * 0.5)
		end_day()


## A business saved before the day's clock (one booking a day, no windows): each day's
## booking into a list, and every job and ad given its window.
func _upgrade_save() -> void:
	for d: int in calendar:
		if calendar[d] is Dictionary:
			calendar[d] = [calendar[d]]
		for b: Dictionary in calendar[d]:
			if b.has("service") and not b.has("from"):
				b.from = DAY_START + 60
				b.by = DAY_START + 540
			elif b.has("seed") and not b.has("from"):
				_window(b)
	for reg: Dictionary in regulars.values():
		if not reg.job.has("from"):
			_window(reg.job)
	for o: Dictionary in paper:
		if not o.has("from"):
			_window(o)
		if not o.has("day"):
			o.day = day
	if current_job.has("seed") and not current_job.has("from"):
		_window(current_job)


# ---------------------------------------------------------------- the record

## The police are involved: caught at the scene, a night in the cells and court tomorrow;
## escaped, a summons, court on the first free day SUMMONS_DAYS on. Court takes that day.
func _charge(r: Dictionary) -> void:
	var caught: bool = r.outcome == "nicked"
	var case := {"charge": r.charge, "tier": r.get("tier", 1), "caught": caught, "customer": current_job.get("customer", "")}
	var d := day + 1
	if not caught:
		d = day + SUMMONS_DAYS
		while not day_free(d) and d < season_end():
			d += 1
	_take_day(d, {"court": case})
	r.court_day = d


## Put something that takes the whole day (court, jail): a regular booked then shifts a
## day if the calendar allows, else that visit's missed and their mood drops; a classified's lost.
func _take_day(d: int, what: Dictionary) -> void:
	var lost := bookings(d)
	calendar[d] = [what]
	for b: Dictionary in lost:
		if b.has("seed") and not b.has("regular") and not b.has("service"): # a classified you can't now turn up to
			missed.append(b.customer)
			rep_trend = maxf(0.0, rep_trend - NO_SHOW_REP)
		elif b.has("regular") and regulars.has(b.regular):
			var moved := _place(b.regular, d)
			if moved < 0 or moved > d + 1:
				regulars[b.regular].mood -= NO_SHOW_MOOD
				for v: Dictionary in bookings(moved):
					if v.get("regular", -1) == b.regular:
						v.start_mood = regulars[b.regular].mood
		elif b.has("court") or b.has("service"): # never lost: the next free day
			var e := d + 1
			while not day_free(e):
				e += 1
			calendar[e] = [b]


## Today's court: pay a lawyer (LAWYERS index), then the roll. Guilty: the fine, the
## charge onto your record, and a sentence by the charge, your record before it, and
## whether you were caught at it. Returns {walked, fee, fine, service, jail, prison}.
func court(lawyer: int) -> Dictionary:
	var case: Dictionary = today().court
	var l: Array = LAWYERS[lawyer]
	money -= l[1]
	var out := {"walked": false, "fee": l[1], "fine": 0, "service": 0, "jail": 0, "prison": false}
	if _rng.randf() < l[2]:
		out.walked = true
		end_day()
		return out
	var before := record
	record += case.charge
	out.fine = fine(case.tier, before)
	money -= out.fine
	var days := sentence(case, before)
	if record >= PRISON:
		out.prison = true
		run_over_reason = "prison"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(business_path()))
		return out
	if before >= MENACE: # a menace on community service goes to jail
		days = [0, days[0] + days[1]]
	out.service = days[0]
	out.jail = days[1]
	for i in out.jail: # at once
		_take_day(day + 1 + i, {"jail": true})
	var d: int = day + 1 + out.jail
	for i in out.service: # your next free days
		while not day_free(d):
			d += 1
		calendar[d] = [service_job()]
	end_day()
	return out


## [community service days, jail days] for a conviction. A nuisance: nothing more than
## the fine at first, a day of service as the record grows. Assault: service, then jail
## as the record grows. Caught red-handed, a day more than escaping would have cost.
func sentence(case: Dictionary, before: float) -> Array:
	var extra := 1 if case.caught else 0
	if case.tier <= 1:
		return [(1 if before >= 2.0 else 0) + (extra if before >= 2.0 else 0), 0]
	if before < 4.0:
		return [1 + extra, 0]
	return [0, 1 + floori(before / 4.0) + extra]


# ---------------------------------------------------------------- packing the truck

## A packed item's footprint: its shape, on its side if turned.
func footprint(kind: String, turned: bool) -> Vector2i:
	var sh: Vector2i = SHAPES[kind]
	return Vector2i(sh.y, sh.x) if turned else sh


## Could `kind` go at `at` in `grid` (leaving out `moving`, the item being moved)?
func fits(kind: String, grid: String, at: Vector2i, turned: bool, moving: Dictionary = {}) -> bool:
	if grid == "trailer" and "trailer" not in upgrades:
		return false
	if kind == "rideon" and grid != "trailer":
		return false
	var box := Rect2i(at, footprint(kind, turned))
	if not Rect2i(Vector2i.ZERO, GRIDS[grid]).encloses(box):
		return false
	for p: Dictionary in packed:
		if p != moving and p.grid == grid and box.intersects(Rect2i(p.at, footprint(p.kind, p.turned))):
			return false
	return true


## The packed item covering this cell, or empty.
func packed_at(grid: String, cell: Vector2i) -> Dictionary:
	for p: Dictionary in packed:
		if p.grid == grid and Rect2i(p.at, footprint(p.kind, p.turned)).has_point(cell):
			return p
	return {}


## Pack `kind` into the first place it fits, the bed first. False if it can't go anywhere.
func pack_first(kind: String) -> bool:
	for grid: String in GRIDS:
		for turned: bool in [false, true]:
			var g: Vector2i = GRIDS[grid]
			for y in g.y:
				for x in g.x:
					if fits(kind, grid, Vector2i(x, y), turned):
						packed.append({"kind": kind, "grid": grid, "at": Vector2i(x, y), "turned": turned})
						return true
	return false


func packed_has(kind: String) -> bool:
	return packed.any(func(p: Dictionary) -> bool: return p.kind == kind)


func packed_count(kind: String) -> int:
	return packed.filter(func(p: Dictionary) -> bool: return p.kind == kind).size()


func cans_packed() -> int:
	return packed_count("can")


## Kit you own that isn't on the truck (the push mower rides in the cab), and cans, always.
func unpacked() -> Array[String]:
	var out: Array[String] = []
	for k in owned:
		if k != "push" and not packed_has(k):
			out.append(k)
	for i in robots - packed_count("robot"):
		out.append("robot")
	out.append("can")
	return out


## What to call a packable thing.
func kit_name(kind: String) -> String:
	if kind == "can":
		return "Petrol can"
	if kind == "robot":
		return ROBOT.name
	return MOWERS[kind].name if MOWERS.has(kind) else UPGRADES[kind].name
