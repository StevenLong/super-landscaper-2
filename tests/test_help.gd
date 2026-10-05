# Hired help (design doc, The Business: Hired help; The hub, redesigned, NOTES 248): the
# paper's situations wanted, hired with no van (on the wage, can't go), kit as one pool (a
# van brings a push mower; a helper takes the best free mower when they set off, never one
# marked yours nor one you've out), the crew's day on your clock (gone from the yard while
# out, as many bookings as fit, too late is a no-show, no van free and it's yours), the
# money and your name moving, a regular who wanted you, mishaps, growth and raises, the
# winter layoff, and the save (old saves' vans and crew mowers into the pool).
extends SceneTree

var g: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.premises = 2 # a warehouse with a breakroom: room and seats (test_premises)
	g.staff_room = "breakroom"
	assert(g.wanted.size() >= 1 and g.wanted.size() <= 3, "the paper's situations wanted: %d" % g.wanted.size())
	var w: Dictionary = g.wanted[0]
	assert(w.wage == g.wage_for(w) and w.pace > 0.0 and w.care > 0.0, "each with a pace, a care and an asking wage")
	# Hired with no van: on the books and the wage, but they can't go out till there's one.
	var due0: int = g.due()
	g.money = 5000
	var m0: int = g.minute
	g.hire(w)
	assert(g.helpers.size() == 1 and w not in g.wanted and g.minute == m0 + g.RING_TIME, "rung and hired, no van needed")
	var h: Dictionary = g.helpers[0]
	assert(g.due() == due0 + h.wage, "no van: still their wage on Friday")
	var early: Dictionary = _job(10, g.WINDOW_START, g.DAY_END)
	g.assign(early, h.id)
	assert(g.crew_plan()[early.seed].cant.begins_with("no van free"), "sent with no van: the calendar says they can't go")
	g._unbook(early)
	assert(g.buy("van") and g.vans == 1 and g.money == 5000 - g.VAN.price and g.total("push") == 2, "a van from the shop, a push mower with it")
	assert(g.mine == {"push": 1}, "your first push mower is marked yours")

	# A booking sent out: not on your list; done on the clock's rules, reported at the day's end.
	var job: Dictionary = _job(11, g.WINDOW_START, g.DAY_END)
	var late: Dictionary = _job(12, g.WINDOW_START + 30, g.WINDOW_START + 90) # after the first: they mow that first and miss this
	g.assign(job, h.id)
	g.assign(late, h.id)
	assert(g.jobs_today().is_empty(), "sent out: not on your list for today")
	var plan: Dictionary = g.crew_plan()
	assert(plan[job.seed].kit == "push" and plan[job.seed].leave == job.from - g.DRIVE, "off on the free push mower, just in time: %s" % [plan[job.seed]])
	var money: int = g.money
	var pace: float = h.pace
	var day: int = g.day
	h.pace = 0.4 # slow, so the first job runs into the second's window
	g.end_day()
	assert(g.day == day + 1 and g.bookings(day).is_empty(), "the day's done, both off the calendar")
	assert(g.crew_report.size() >= 2 and g.crew_report[0].begins_with(h.name.split(" ")[0] + " mowed for " + job.customer), "the evening report: %s" % [g.crew_report])
	assert(g.crew_report.any(func(l: String) -> bool: return l.contains("couldn't get to " + late.customer)), "too late for the second: a no-show")
	assert(late.customer in g.missed, "and it's yours, missed")
	assert(g.money != money and h.jobs == 1 and h.pace > 0.4, "the money moved, and they grew")
	assert(g.crew_trips.is_empty() and g.my_trips.is_empty(), "a new day: nobody out")
	h.pace = pace

	# The pool: the best free mower, never one marked yours, nor one you've out on a job.
	g.buy("petrol")
	var mow: Dictionary = _job(13, g.WINDOW_START + 120, g.DAY_END)
	g.assign(mow, h.id)
	assert(g.crew_plan()[mow.seed].kit == "petrol", "a petrol mower in the yard: they take it, the best free")
	g.mark_mine("petrol", true)
	assert(g.crew_plan()[mow.seed].kit == "push", "marked yours: they leave it")
	g.mark_mine("petrol", false)
	g.set_job_kit(mow, "push")
	assert(g.crew_plan()[mow.seed].kit == "push", "a booking's own pick, if it's free")
	g.set_job_kit(mow, "")
	g.my_trips.append({"from": g.DAY_START, "to": g.DAY_END, "kinds": ["push", "petrol"]})
	assert(g.crew_plan()[mow.seed].kit == "push", "you've the petrol out on a job: they take the other push mower")
	g.my_trips.clear()
	# Gone from the yard while out: their van and mower with them; packing can't have it.
	g.packed.append({"kind": "petrol", "grid": "bed", "at": Vector2i.ZERO, "turned": false})
	var leave: int = g.crew_plan()[mow.seed].leave
	g.minute = leave + 5
	g.advance_crew()
	assert(g.out_till(h.id) > g.minute and g.out_now("van") == 1 and g.out_now("petrol") == 1, "set off: out till they're back")
	assert(not g.free_for_you("petrol") and "petrol" not in g.unpacked(), "their mower's not yours to pack")
	g.unpack_gone()
	assert(not g.packed_has("petrol"), "nor still in the truck")
	assert(not g.let_go(h.id) and g.helpers.size() == 1, "not let go while out on a job")
	g.assign(mow, -1)
	assert(mow.get("helper", -1) == h.id, "set off: too late to take it back")
	g.minute = g.out_till(h.id)
	g.advance_crew()
	assert(g.out_till(h.id) < 0 and g.free_for_you("petrol"), "back: in the yard again")
	assert(not g.let_go(h.id) and g.cant_let_go(h.id).begins_with("they've worked today"),
		"back, but not let go till the day's done: their job's settled then (the verifier's run 11)")
	# No van free when the next sets off: they don't go, it's yours again, and the day's end says why.
	var w2 := {"id": 2, "name": "Agnes Crumb", "pace": 0.7, "care": 0.5, "wage": 80}
	g.wanted.append(w2)
	g.hire(w2)
	var h2: Dictionary = g.helpers[1]
	var a: Dictionary = _job(14, g.minute + 60, g.DAY_END)
	var b2: Dictionary = _job(15, g.minute + 60, g.DAY_END)
	g.assign(a, h.id)
	g.assign(b2, h2.id)
	assert(g.crew_plan()[b2.seed].cant.begins_with("no van free"), "one van, two going at once: the second can't")
	g.minute += 60
	g.advance_crew()
	assert(not b2.has("helper") and g.crew_cant.size() == 1 and b2 in g.jobs_today(), "the second's yours again")
	g.end_day()
	assert(g.crew_report.any(func(l: String) -> bool: return l.contains("couldn't go to " + b2.customer)), "and the day's end says why: %s" % [g.crew_report])
	g.let_go(h2.id)
	g.missed.clear()

	# Home between bookings with an hour or more from finishing to the next window; on, with less.
	var one: Dictionary = _job(20, g.WINDOW_START, g.DAY_END)
	var two: Dictionary = _job(21, g.WINDOW_START, g.DAY_END)
	g.assign(one, h.id)
	g.assign(two, h.id)
	var done_at: int = g.crew_plan()[one.seed].end
	for gap: int in [59, 60]:
		two.from = done_at + gap
		var p2: Dictionary = g.crew_plan()[two.seed]
		assert((p2.leave == two.from - g.DRIVE) == (gap >= 60), "a gap of %d: %s" % [gap, "home between" if gap >= 60 else "straight on"])
	g._unbook(one)
	g._unbook(two)

	# Your own pending offer isn't the crew's to answer (the verifier's find).
	var mine := {"id": 777, "job": g.make_job(17), "cadence": 14, "rate": 50, "mood": 70.0, "day": g.day, "drift": []}
	g.offer = mine
	var sour: Dictionary = _job(18, g.WINDOW_START, g.DAY_END)
	sour.start_mood = 0.0 # it can't win an offer itself
	g.assign(sour, h.id)
	g.end_day()
	assert(not g.regulars.has(777) and g.offer == mine, "your offer still waits for you")
	g.offer = {}
	# A regular won by a helper's job: its visits don't carry the sending (a stale set-off time, a mower picked).
	var won: Dictionary = g.make_job(19)
	won.from = g.WINDOW_START
	won.by = g.DAY_END
	won.start_mood = 100.0
	var tries := 0
	while not g.regulars.has(won.seed) and tries < 50: # their offer's a chance: send them again till it comes
		won.erase("helper")
		g.book(_today(won))
		g.minute = 900
		g.assign(won, h.id)
		g.set_job_kit(won, "push")
		g.minute = g.DAY_START
		g.end_day()
		tries += 1
	assert(g.regulars.has(won.seed), "won a regular")
	for k: String in ["sent_at", "helper", "prepaid", "kit"]:
		assert(not g.regulars[won.seed].job.has(k), "the regular's job doesn't keep %s" % k)
	g.drop(won.seed)
	for b: Dictionary in g.bookings():
		g.assign(b, -1)
	g.calendar.erase(g.day)

	# A regular who wants you: the helper's visit says so.
	g.missed.clear()
	var reg_job: Dictionary = g.make_job(13)
	reg_job.persona = "perfectionist"
	reg_job.from = g.WINDOW_START
	reg_job.by = g.DAY_END
	g.regulars[reg_job.seed] = {"id": reg_job.seed, "job": reg_job, "cadence": 14, "rate": reg_job.pay, "mood": 90.0, "day": g.day, "drift": []}
	var visit: Dictionary = g._visit(reg_job.seed)
	assert(g.wants_you(visit) > 0.0 and g.wants_you(job) == 0.0, "a perfectionist regular wants you; a classified doesn't mind")
	g._add(g.day, visit)
	g.assign(visit, h.id)
	g.end_day()
	assert(g.crew_report[0].contains("they wanted you"), "explained in the report: %s" % [g.crew_report])
	assert(not g.regulars.has(reg_job.seed) or g.regulars[reg_job.seed].visits == 1, "a visit, counted like yours")

	# Mishaps by want of care: none at full care, often at none.
	var careless := {"pace": 1.0, "care": 0.0, "kit": "push"}
	var careful := {"pace": 1.0, "care": 1.0, "kit": "push"}
	var mishaps := [0, 0]
	for i in 200:
		mishaps[0] += int(g.help_job(job, careless, 0.0).has("mishap"))
		mishaps[1] += int(g.help_job(job, careful, 0.0).has("mishap"))
	assert(mishaps[1] == 0 and mishaps[0] > 30 and mishaps[0] < 90, "mishaps by care: %s" % [mishaps])
	# Kit: a petrol mower is quicker than a push.
	assert(g.help_job(job, careless, 0.0, "petrol").minutes < g.help_job(job, careless, 0.0).minutes, "better kit, quicker")

	# Your name climbing doesn't make them ask (NOTES 222): their wage is priced on the name
	# they answered the ad at.
	var was_rep: float = g.reputation
	g.reputation = minf(100.0, g.reputation + 40.0)
	g.assign(_job(16, g.WINDOW_START, g.DAY_END), h.id)
	g.end_day()
	assert(not h.has("asks"), "a better name alone: no raise asked (wage $%d, now worth $%d)" % [h.wage, g.wage_for(h)])
	g.reputation = was_rep
	# Care a point up alone: no ask (it rides along with the next pace point: the verifier's
	# run 9 found pace and care ticking days apart, asks in pairs).
	h.pace = 1.0
	h.care = 0.849
	g.assign(_job(13, g.WINDOW_START, g.DAY_END), h.id)
	g.end_day()
	assert(g.points_of(h).y == 9 and not h.has("asks"), "care up a point alone: no ask")
	# A raise: a job that ticks their pace a point up, and they ask; yes pays it.
	h.pace = 1.149
	h.care = 0.9
	g.assign(_job(14, g.WINDOW_START, g.DAY_END), h.id)
	g.end_day()
	assert(h.has("asks") and g.crew_report.any(func(l: String) -> bool: return l.contains("asks $%d" % h.asks)), "worth more: they ask")
	var asks: int = h.asks
	g.answer_raise(h.id, true)
	assert(h.wage == asks and not h.has("asks"), "a yes pays it")

	# A day with only the crew's work in it ends on its own day's end, report and all.
	g.assign(_job(15, g.WINDOW_START, g.DAY_END), h.id)
	day = g.day
	g.end_day()
	assert(g.day == day + 1 and g.day_end.day == day and g.day_end.crew.size() == 1 and g.day_end.crew_net != 0, "the crew's day, in its day's end")

	# The heavies take the van: the helper stays, their bookings can't go.
	var kept: Dictionary = g.make_job(16)
	kept.day = g.day + 1
	kept.from = g.WINDOW_START
	kept.by = g.DAY_END
	g.book(kept)
	g.assign(kept, h.id)
	g.sell("van")
	assert(g.helpers.size() == 1 and g.vans == 0 and g.crew_plan(kept.day)[kept.seed].cant.begins_with("no van"), "no van: they stay on, and can't go")
	assert(g.total("push") == 1 and g.total("petrol") == 1, "the push mower it brought goes with it (the verifier's run 11)")
	g.let_go(h.id)

	# The winter: laid off unpaid; back by how they were treated.
	g.money = 5000
	g.wanted.assign([{"id": 1, "name": "Keith Pratt", "pace": 0.7, "care": 0.5, "wage": 80}, {"id": 2, "name": "Agnes Crumb", "pace": 0.7, "care": 0.5, "wage": 80}])
	g.hire(g.wanted[0])
	g.hire(g.wanted[0])
	g.helpers[0].happy = 100.0
	g.helpers[1].happy = 0.0
	g.helpers[0].pace = 0.9
	var wint: Dictionary = g.settle_winter()
	assert(wint.crew_back == ["Keith Pratt"] and wint.crew_gone == ["Agnes Crumb"], "the treated well come back: %s" % [wint])
	assert(g.helpers.size() == 1 and g.helpers[0].pace == 0.9, "better, as they left")

	# The save keeps the crew and the pool.
	g.money = 5000 # the winter's keep took the rest
	g.buy("van")
	g.buy("van")
	g.mark_mine("petrol", true)
	g.save()
	g.helpers.clear()
	g.vans = 0
	g.spares = {}
	g.mine = {}
	g.load_business()
	assert(g.helpers.size() == 1 and g.vans == 2 and g.total("push") == 3 and g.mine.get("petrol", 0) == 1, "saved and loaded, the pool and its marks: %s" % [[g.helpers.size(), g.vans, g.total("push"), g.mine]])
	# A save from before kit was one pool: its vans a count, each with a push mower; the crew's mowers spares.
	var f := FileAccess.open(g.business_path(), FileAccess.READ)
	var state: Dictionary = f.get_var()
	f.close()
	for k: String in ["vans", "spares", "mine", "crew_trips", "my_trips", "crew_cant"]:
		state.erase(k)
	state.owned = ["push"]
	state.fleet = [{"id": 0, "helper": g.helpers[0].id, "kit": "petrol"}, {"id": 1, "helper": -1, "kit": "push"}]
	state.crew_kit = {"petrol": 1, "rideon": 1}
	_write(state)
	g.load_business()
	assert(g.vans == 2 and g.total("push") == 3 and g.total("petrol") == 1 and g.total("rideon") == 1 and g.mine == {"push": 1},
		"an old save: two vans, a push mower each, the crew's mowers in the pool")
	assert("trailer" in g.upgrades, "the crew's ride-on comes with its trailer, so you can tow it too")
	# Older still: vans a count, a helper's kit their own.
	state.erase("fleet")
	state.erase("crew_kit")
	state.vans = 1
	state.helpers[0].kit = "petrol"
	_write(state)
	g.load_business()
	assert(g.vans == 1 and g.total("petrol") == 1 and g.total("push") == 2 and not g.helpers[0].has("kit"), "an older save: the helper's petrol mower into the pool")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
	print("PASS help")
	quit()


## A booking today, from `from` to `by`.
func _job(n: int, from: int, by: int) -> Dictionary:
	var j: Dictionary = g.make_job(n)
	j.from = from
	j.by = by
	g.book(_today(j))
	return j


func _today(j: Dictionary) -> Dictionary:
	j.day = g.day
	return j


func _write(state: Dictionary) -> void:
	var f := FileAccess.open(g.business_path(), FileAccess.WRITE)
	f.store_var(state)
	f.close()
