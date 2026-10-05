# Economy probe (not part of run_all; NOTES 193d): a bot runs the business through the
# real Game code (the paper, ringing, booking, the day's clock, regulars, payday, the
# winter) and prints, month by month, what came in and where the time went. Each job's
# result is modelled, not mowed: mowing seconds are sim_balance's bot times per default
# lawn's area (to 85%), times HUMAN, times the plot's area; the customer ends at MOOD
# (shifted by where they start), less if you overran their window. So read it for shape
# (is April short of money, is summer short of time, when does money stop mattering),
# not for exact dollars. It flatters income: every job meets its target (a perfectionist's
# 0.96 included), and the ride-on's manor time is extrapolated (the balance bot gets it
# to 26%), so trust MOOD 75's dollars least. "paid$" leaves out money up front.
#   "$GODOT" --headless --path . -s tests/sim_season.gd
# Knobs (env): SIM_SEEDS (5), SIM_SEASONS (2), SIM_HUMAN (0.85), SIM_MOOD (75), SIM_SPREAD
# (15, each job's mood is MOOD give or take this), SIM_FILL (0.85, how much of a day the
# bot dares book), SIM_BUFFER (200, cash kept at payday), SIM_SHOW (the seed printed in full, 1),
# SIM_CREW (0, helpers the bot may hire: at a payday after a month it turned work away, a van
# and the best situation wanted by pace for the wage; the work it can't fit goes to them,
# on Game's own model, help_job; raises always paid). crew$ is what they brought in, net.
extends SceneTree

const BOT_SECS := {"push": 420.0, "petrol": 262.0, "rideon": 281.0} ## sim_balance, default lawn to 85% (push guessed: it never got there)
const BUY := ["petrol", "rideon", "gear3"] ## the bot's shopping list, in order

var g: Node
var human := 0.85
var mood := 75.0
var spread := 15.0
var rng := RandomNumberGenerator.new()
var fill := 0.85
var buffer := 200
var crew := 0
var rows := {} ## "season-month" -> totals over every seed


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://sim_season.cfg"
	human = float(OS.get_environment("SIM_HUMAN")) if OS.has_environment("SIM_HUMAN") else human
	mood = float(OS.get_environment("SIM_MOOD")) if OS.has_environment("SIM_MOOD") else mood
	spread = float(OS.get_environment("SIM_SPREAD")) if OS.has_environment("SIM_SPREAD") else spread
	fill = float(OS.get_environment("SIM_FILL")) if OS.has_environment("SIM_FILL") else fill
	buffer = int(OS.get_environment("SIM_BUFFER")) if OS.has_environment("SIM_BUFFER") else buffer
	crew = int(OS.get_environment("SIM_CREW")) if OS.has_environment("SIM_CREW") else crew
	var seeds := int(OS.get_environment("SIM_SEEDS")) if OS.has_environment("SIM_SEEDS") else 5
	var seasons := int(OS.get_environment("SIM_SEASONS")) if OS.has_environment("SIM_SEASONS") else 2
	var show := int(OS.get_environment("SIM_SHOW")) if OS.has_environment("SIM_SHOW") else 1
	print("human %.2f, mood %d +-%d, fill %.2f, buffer $%d, crew %d, %d seeds, %d seasons" % [human, mood, spread, fill, buffer, crew, seeds, seasons])
	for s in range(1, seeds + 1):
		var months := _season_run(s, seasons)
		if s == show:
			print("\nseed %d, month by month (each row as the month ends):" % s)
			_print(months, 1)
	print("\nmean over %d seeds:" % seeds)
	var mean: Array = []
	for k: String in rows:
		var r: Dictionary = rows[k].duplicate()
		for f: String in r:
			if r[f] is float or r[f] is int:
				r[f] = float(r[f]) / seeds
		mean.append(r)
	_print(mean, seeds)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
	quit()


## Minutes of the day a job takes once you're there.
func _mow_minutes(j: Dictionary, kind: String) -> float:
	var area := float(j.size.x * j.size.y) / (1280.0 * 720.0)
	return BOT_SECS[kind] * human * area * g.MPS


## The kit the bot would mow with now (Game picks the best packed at start_job).
func _kind() -> String:
	return "rideon" if g.packed_has("rideon") else ("petrol" if g.packed_has("petrol") else "push")


## Minutes a day's bookings would take: the drive and the mowing each.
func _load(d: int) -> float:
	var t := 0.0
	for b: Dictionary in g.bookings(d):
		if b.has("seed") and not b.has("helper"):
			t += g.DRIVE + _mow_minutes(b, _kind())
	return t


## Minutes a helper's bookings that day would take them, by Game's model (help_job).
func _help_load(d: int, h: Dictionary) -> float:
	var t := 0.0
	for b: Dictionary in g.bookings(d):
		if b.get("helper", -1) == h.id:
			t += g.DRIVE + _help_minutes(b, h)
	return t


func _help_minutes(j: Dictionary, h: Dictionary) -> float:
	return g.help_minutes(j, h, "push") # ponytail: the slowest mower, so the load's never under; the plan picks the real one


func _season_run(seed_value: int, seasons: int) -> Array:
	g.new_run(seed_value)
	rng.seed = seed_value
	var months: Array = []
	var m := _blank()
	var season := 1
	while season <= seasons and g.run_over_reason == "":
		var month: int = g.date().month
		# The morning: ring what's worth ringing, best pay first, while the day has room.
		var ads: Array = g.paper.duplicate()
		ads.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pay > b.pay)
		for ad: Dictionary in ads:
			if ad.get("refused", false) or g.cant_book(ad) != "" or g.yes_chance(ad) < 0.5:
				continue
			if _load(ad.day) + g.DRIVE + _mow_minutes(ad, _kind()) > (g.DAY_END - g.WINDOW_START) * fill:
				var sent := false
				for h: Dictionary in g.helpers: # the crew takes what you can't
					if _help_load(ad.day, h) + g.DRIVE + _help_minutes(ad, h) <= (g.DAY_END - g.WINDOW_START) * fill:
						m.rung += 1
						g.ring(ad)
						if not ad.get("refused", false):
							g.assign(ad, h.id)
							m.sent += 1
						sent = true
						break
				if not sent:
					m.full += 1 # wanted it, no time
				continue
			m.rung += 1
			g.ring(ad)
			m.no += int(ad.get("refused", false))
		# More today than you can do (regulars' visits pile up): the crew takes the rest.
		var cap: float = (g.DAY_END - g.WINDOW_START) * fill
		var mine: Array = g.jobs_today()
		mine.reverse()
		for b: Dictionary in mine:
			if _load(g.day) <= cap:
				break
			for h: Dictionary in g.helpers:
				if g.can_send(b) and _help_load(g.day, h) + g.DRIVE + _help_minutes(b, h) <= cap:
					g.assign(b, h.id)
					m.sent += 1
					break
		# The day: each job in turn while you can still make its window.
		var busy := 0.0
		while true:
			var go: Array = g.jobs_today().filter(func(b: Dictionary) -> bool: return g.can_go(b))
			if go.is_empty():
				break
			var next: Dictionary = go[0]
			var kind := _kind()
			g.start_job(next)
			var j: Dictionary = g.current_job
			var secs: float = _mow_minutes(j, kind) / g.MPS
			var elapsed: float = j.get("late", 0.0) + secs
			var over: bool = elapsed > j.patience
			var md := clampf(mood + rng.randf_range(-spread, spread) + float(j.get("start_mood", g.PERSONAS[j.persona].get("start_mood", 60.0))) - 60.0 - (25.0 if over else 0.0), 0.0, 100.0)
			var time_f := 1.0 if not over else maxf(0.4, 1.0 - (elapsed - j.patience) / j.patience)
			var pay := roundi(j.pay * time_f * (0.5 + md / 100.0))
			var tip := roundi(j.pay * 0.25) if not over and md >= 75.0 and not j.has("regular") else 0
			var spec: Dictionary = g.MOWERS[kind]
			var fuel: float = maxf(0.0, secs * spec.fuel_burn - spec.max_fuel) * spec.fuel_price # the first tank's in it already
			var rep := (md - 50.0) / 5.0 + 2.0
			g.record_result({"outcome": "paid", "paid": pay + tip, "net": pay + tip - roundi(fuel), "rep": rep,
				"rep_lines": [["The job", rep]], "mood": md, "elapsed": elapsed})
			m.visits += int(j.has("regular"))
			m.jobs += int(not j.has("regular"))
			m.late += int(over)
			m.paid += pay + tip
			m.fuel += fuel
			busy += g.DRIVE + secs * g.MPS
			if not g.offer.is_empty():
				g.answer_offer("accept")
			if not g.upfront.is_empty():
				g.take_upfront()
		m.missed += g.jobs_today().size()
		m.days += 1
		m.busy += busy / (g.DAY_END - g.WINDOW_START)
		var before: int = g.money
		g.end_day()
		m.crew += g.money - before # end_day's only money is the crew's day
		if g.payday_pending:
			for h: Dictionary in g.helpers:
				if h.has("asks"):
					g.answer_raise(h.id, true)
			if g.helpers.size() < crew and m.full > 0 and g.money - g.due() - g.VAN.price >= buffer and not g.wanted.is_empty():
				var best: Dictionary = g.wanted[0]
				for w: Dictionary in g.wanted:
					if w.pace / w.wage > best.pace / best.wage:
						best = w
				# The whole bill first: a month of their wage, a van, a staff room (and the move for one) if need be.
				var bill: int = best.wage * 4 + g.VAN.price
				if g.cant_hire() != "":
					bill += g.STAFF.corner.price + (g.PREMISES[1].deposit if g.premises == 0 else 0)
				if g.money - g.due() - bill >= buffer:
					if g.cant_hire() != "": # a staff room, moving up for one if need be
						if g.PREMISES[g.premises].staff == "":
							_move_up(m, g.STAFF.corner.price, buffer)
						_room(m, "staff", buffer)
						if g.staff_next() != "" and g.buy("staff"):
							m.bought.append("staff")
					_room(m, "van", buffer)
					if g.cant_hire() == "" and g.buy("van"):
						g.hire(best)
						m.bought.append("van")
			m.wages += g.wages()
			for item: String in BUY:
				if not (item in g.owned or item in g.upgrades) and g.money - g.due() - g.price_of(item) >= buffer:
					_room(m, item, buffer)
					if g.buy(item):
						m.bought.append(item)
			var r: Dictionary = g.settle_payday(maxi(0, g.money - g.due() - buffer))
			m.taken.append_array(r.taken)
		if g.date().month != month or g.winter_pending or g.run_over_reason != "":
			m.label = "S%d %s" % [season, g.MONTHS[month - 1].substr(0, 3)]
			m.money = g.money
			m.debt = g.principal
			m.rep = g.reputation
			m.regs = g.regulars.size()
			m.help = g.helpers.size()
			months.append(m)
			_add(m)
			m = _blank()
		if g.winter_pending:
			var w: Dictionary = g.settle_winter()
			print("seed %d, winter %d: $%d left after the winter's keep, topped up $%d, %d regulars back, %d gone" % [
				seed_value, season, g.money, w.topped, w.back.size(), w.gone.size()])
			season += 1
	if g.run_over_reason != "":
		print("seed %d: %s" % [seed_value, g.run_over_reason])
	return months


## No room in the yard for `item`: buy more yard first, if that leaves the buffer.
## No room on the floor for `item`: move up, if that leaves the buffer after it's bought.
func _room(m: Dictionary, item: String, buffer: int) -> void:
	var g: Node = root.get_node("Game")
	var kind: String = g.yard_kind(item)
	if kind != "" and not g.yard_room(kind):
		_move_up(m, g.price_of(item), buffer)


## To the next premises: on your own money if `then` (what you'll buy there) and a month of
## the rent and wages there still leave the buffer, else on the shark's if he's offered.
func _move_up(m: Dictionary, then: int, buffer: int) -> void:
	var g: Node = root.get_node("Game")
	if g.premises + 1 >= g.PREMISES.size():
		return
	var nx: Dictionary = g.PREMISES[g.premises + 1]
	if g.money - g.due() - nx.deposit - then - 4 * (nx.rent + g.wages()) >= buffer: # a month of the rent and wages there in hand
		if g.move_to(g.premises + 1):
			m.bought.append("move")
	elif g.shark_offer and g.take_shark_offer():
		m.bought.append("shark's move")


func _blank() -> Dictionary:
	return {"label": "", "rung": 0, "no": 0, "full": 0, "jobs": 0, "visits": 0, "late": 0, "missed": 0, "paid": 0,
		"fuel": 0.0, "busy": 0.0, "days": 0, "money": 0, "debt": 0, "rep": 0.0, "regs": 0, "bought": [], "taken": [],
		"sent": 0, "crew": 0, "wages": 0, "help": 0}


func _add(m: Dictionary) -> void:
	var t: Dictionary = rows.get(m.label, {})
	for f: String in m:
		if m[f] is float or m[f] is int:
			t[f] = t.get(f, 0) + m[f]
		elif m[f] is Array:
			t[f] = t.get(f, []) + m[f]
	t.label = m.label
	rows[m.label] = t


func _print(months: Array, n: int) -> void:
	print("month   rung  no full | jobs visits late missed | paid$  fuel$ |   day full% | cash$  debt$  rep  regs | help sent crew$ wages$ | bought, taken")
	for m: Dictionary in months:
		var busy: float = m.busy / maxf(1.0, m.days) * 100.0
		print("%-7s %4.1f %3.1f %4.1f | %4.1f %6.1f %4.1f %6.1f | %5d %5d | %13d | %5d %6d %4d %5.1f | %4.1f %4.1f %5d %6d | %s %s" % [
			m.label, m.rung, m.no, m.full, m.jobs, m.visits, m.late, m.missed, roundi(m.paid), roundi(m.fuel), roundi(busy),
			roundi(m.money), roundi(m.debt), roundi(m.rep), m.regs, m.help, m.sent, roundi(m.crew), roundi(m.wages), ",".join(m.bought) if n == 1 else "%d buys" % m.bought.size(),
			",".join(m.taken)])
