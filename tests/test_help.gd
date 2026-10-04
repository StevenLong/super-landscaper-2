# Hired help, slice 1 (design doc, The Business: Hired help; NOTES 209): the paper's
# situations wanted, a van to hire, the wage on Friday, a booking sent to a helper and done
# off screen on your clock's rules (as many as fit, too late is a no-show), the money and
# your name moving, a regular who wanted you, mishaps, crew kit, growth and raises, losing
# a van, the winter layoff, and the save.
extends SceneTree

var g: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	assert(g.wanted.size() >= 1 and g.wanted.size() <= 3, "the paper's situations wanted: %d" % g.wanted.size())
	var w: Dictionary = g.wanted[0]
	assert(w.wage == g.wage_for(w) and w.pace > 0.0 and w.care > 0.0, "each with a pace, a care and an asking wage")
	# No van, no hire.
	assert(g.cant_hire() != "", "no van, no crew")
	var due0: int = g.due()
	g.money = 5000
	assert(g.buy("van") and g.vans == 1 and g.money == 5000 - g.VAN.price, "a van from the shop")
	var m0: int = g.minute
	g.hire(w)
	assert(g.helpers.size() == 1 and w not in g.wanted and g.minute == m0 + g.RING_TIME, "rung and hired")
	var h: Dictionary = g.helpers[0]
	assert(h.kit == "push" and g.due() == due0 + h.wage, "on a push mower, their wage on Friday")
	assert(g.cant_hire() != "", "one van, one helper")

	# A booking sent out: not on your list; done at the day's end, on the clock's rules.
	var job: Dictionary = g.make_job(11)
	job.from = g.WINDOW_START
	job.by = g.DAY_END
	g.book(_today(job))
	var late: Dictionary = g.make_job(12)
	late.from = g.WINDOW_START + 30 # after the first, so they mow that first and miss this one
	late.by = g.WINDOW_START + 90
	g.book(_today(late))
	g.assign(job, h.id)
	g.assign(late, h.id)
	assert(g.jobs_today().is_empty(), "sent out: not on your list for today")
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
	h.pace = pace

	# Your own pending offer isn't the crew's to answer (the verifier's find).
	var mine := {"id": 777, "job": g.make_job(17), "cadence": 14, "rate": 50, "mood": 70.0, "day": g.day, "drift": []}
	g.offer = mine
	var sour: Dictionary = g.make_job(18)
	sour.from = g.WINDOW_START
	sour.by = g.DAY_END
	sour.start_mood = 0.0 # it can't win an offer itself
	g.book(_today(sour))
	g.assign(sour, h.id)
	g.end_day()
	assert(not g.regulars.has(777) and g.offer == mine, "your offer still waits for you")
	g.offer = {}
	# A regular won by a helper's job: its visits don't carry the sending (a stale set-off time).
	var won: Dictionary = g.make_job(19)
	won.from = g.WINDOW_START
	won.by = g.DAY_END
	won.start_mood = 100.0
	g.book(_today(won))
	g.minute = 900
	g.assign(won, h.id)
	g.minute = g.DAY_START
	var tries := 0
	while not g.regulars.has(won.seed) and tries < 50: # their offer's a chance: send them again till it comes
		g.end_day()
		won.erase("helper")
		g.book(_today(won))
		g.assign(won, h.id)
		tries += 1
	assert(g.regulars.has(won.seed), "won a regular")
	for k: String in ["sent_at", "helper", "prepaid"]:
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
	var on_petrol := {"pace": 1.0, "care": 0.5, "kit": "petrol"}
	assert(g.help_job(job, on_petrol, 0.0).minutes < g.help_job(job, careless, 0.0).minutes, "better kit, quicker")
	assert(not g.set_kit(h.id, "petrol"), "no crew petrol mower to give")
	g.buy("crew_petrol")
	assert(g.set_kit(h.id, "petrol") and g.crew_free("petrol") == 0, "bought one for the crew, given out")

	# A raise: they ask once they're worth it; yes pays it.
	h.pace = 1.2
	h.care = 0.9
	var raise: Dictionary = g.make_job(14)
	raise.from = g.WINDOW_START
	raise.by = g.DAY_END
	g.book(_today(raise))
	g.assign(raise, h.id)
	g.end_day()
	assert(h.has("asks") and g.crew_report.any(func(l: String) -> bool: return l.contains("asks $%d" % h.asks)), "worth more: they ask")
	var asks: int = h.asks
	g.answer_raise(h.id, true)
	assert(h.wage == asks and not h.has("asks"), "a yes pays it")

	# Skipping a day with only the crew's work in it: it doesn't stick there.
	var crew_only: Dictionary = g.make_job(15)
	crew_only.from = g.WINDOW_START
	crew_only.by = g.DAY_END
	g.book(_today(crew_only))
	g.assign(crew_only, h.id)
	day = g.day
	g.payday_pending = false # skipping stops at a payday
	g.skip()
	assert(g.day > day, "skips past a day the crew has")

	# The heavies take the van: the helper goes, their bookings back to you.
	var kept: Dictionary = g.make_job(16)
	kept.day = g.day + 1
	kept.from = g.WINDOW_START
	kept.by = g.DAY_END
	g.book(kept)
	g.assign(kept, h.id)
	g.sell("van")
	assert(g.helpers.is_empty() and not kept.has("helper"), "no van: they go, the booking's yours again")

	# The winter: laid off unpaid; back by how they were treated.
	g.money = 5000
	g.buy("van")
	g.buy("van")
	g.wanted.assign([{"id": 1, "name": "Keith Pratt", "pace": 0.7, "care": 0.5, "wage": 80}, {"id": 2, "name": "Agnes Crumb", "pace": 0.7, "care": 0.5, "wage": 80}])
	g.hire(g.wanted[0])
	g.hire(g.wanted[0])
	g.helpers[0].happy = 100.0
	g.helpers[1].happy = 0.0
	g.helpers[0].pace = 0.9
	var w2: Dictionary = g.settle_winter()
	assert(w2.crew_back == ["Keith Pratt"] and w2.crew_gone == ["Agnes Crumb"], "the treated well come back: %s" % [w2])
	assert(g.helpers.size() == 1 and g.helpers[0].pace == 0.9, "better, as they left")

	# The save keeps the crew.
	g.save()
	g.helpers.clear()
	g.vans = 0
	g.load_business()
	assert(g.helpers.size() == 1 and g.vans == 2 and g.crew_kit.get("petrol", 0) == 1, "saved and loaded")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
	print("PASS help")
	quit()


func _today(j: Dictionary) -> Dictionary:
	j.day = g.day
	return j
