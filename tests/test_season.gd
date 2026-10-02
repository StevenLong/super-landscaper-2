# The season (design doc, The Business and Season Prototype): days from 1 April 1980,
# Friday's vig and keep, overpaying cuts the debt, short means the heavies, paid off means
# no vig; the weekly paper's ads booked on their days, the day's clock (windows, arriving
# late, no-shows, the paper swelling and regulars wanting you sooner at the peak); regulars (the offer, the haggle, a
# cadence placed round a busy week, carried mood, the floor, drift); the ironman save and
# the blackout; the winter ledger.
extends SceneTree

var g: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	_money()
	_paper()
	_clock()
	_regulars()
	_court()
	_save()
	_winter()
	print("PASS season")
	quit()


func _money() -> void:
	g.new_run(7)
	assert(g.date_text() == "Tuesday 1 April 1980", "the first season opens on 1 April 1980")
	assert(g.principal == g.PRINCIPAL and g.vig() == 100 and g.due() == 150, "the vig on $1,000 and a week's keep: $150")
	# A month of empty days: skipping stops at each Friday's payday.
	g.money = 10000
	for i in 4:
		g.skip()
		assert(g.payday_pending, "empty days skip to payday")
		assert(g.settle_payday().outcome == "paid", "paid")
	assert(g.date_text() == "Saturday 26 April 1980", "four Fridays in April 1980")
	assert(g.money == 10000 - 4 * 150 and g.principal == 1000, "the vig and the keep, four times; the debt untouched")
	# Paying more cuts the debt, and the vig with it.
	g.payday_pending = true
	var r: Dictionary = g.settle_payday(300)
	assert(r.off == 300 and g.principal == 700 and g.vig() == 70, "$300 off: $700 owed, a $70 vig")
	r = g.settle_payday(100000)
	assert(r.outcome == "free" and g.principal == 0 and g.due() == g.LIVING, "paid off: free of him, only the keep")
	# Short: the heavies take the dearest kit first, until it covers it.
	g.new_run(7)
	g.owned.assign(["push", "petrol", "rideon"])
	g.equipped = "rideon"
	g.upgrades.assign(["blades"])
	g.money = 0
	r = g.settle_payday()
	assert(r.taken == ["rideon"] and r.outcome == "repossessed", "the ride-on alone covers $150")
	assert(g.money == g.resale("rideon") - 150 and g.equipped == "petrol", "you keep the change, back on your best remaining mower")
	assert(g.sellable() == ["petrol", "blades"], "sellable, dearest first, no push mower")
	# Nothing left covers it: bankrupt, and the business's save is gone.
	g.owned.assign(["push"])
	g.upgrades.assign([])
	g.money = 0
	g.save()
	assert(g.has_business(), "saved")
	r = g.settle_payday()
	assert(r.outcome == "bankrupt" and g.run_over_reason == "bankrupt" and not g.has_business(), "bankrupt: the business is over")
	# Zero reputation: the paper's still full, but only the dregs and the churchyard say yes.
	g.new_run(7)
	g.reputation = 0.0
	var ruined: Array = g.make_paper()
	assert(ruined.all(func(o: Dictionary) -> bool: return g.yes_chance(o) == (1.0 if o.bar == 0.0 else 0.0)), "a ruined name: yes from the bottom, no from the rest")
	assert(ruined.any(func(o: Dictionary) -> bool: return o.persona == "grump" and o.bar == 0.0), "the dregs still answer")


func _paper() -> void:
	g.new_run(7)
	assert(g.paper.size() == g.PAPER_SIZE[4] and g.week_left().size() == 4, "April's ads for Tuesday to Friday")
	assert(g.paper.all(func(o: Dictionary) -> bool: return o.day in g.week_left()), "each on a day of the week")
	# A spread: over many papers, a Fair name sees ads above its level and below it.
	var bars := {}
	for i in 30:
		for o: Dictionary in g.make_paper():
			bars[o.bar] = true
	assert(bars.has(20.0) and bars.has(40.0) and (bars.has(55.0) or bars.has(70.0)), "bars below, around and above a Fair name: %s" % [bars.keys()])
	# The chance: certain at the bar, a third of the way at 10 under, none past REACH.
	var ad: Dictionary = g.paper[0].duplicate()
	for pair: Array in [[50.0, 1.0], [60.0, 1.0 / 3.0], [65.0, 0.0], [80.0, 0.0]]:
		ad.bar = pair[0]
		assert(is_equal_approx(g.yes_chance(ad), pair[1]), "a Fair name against a bar of %d" % pair[0])
	# Ringing: a sure yes books it; a sure no stamps it and it stays in view.
	var sure: Dictionary = g.paper[0]
	sure.bar = 0.0
	sure.day = g.day
	var said: String = g.ring(sure)
	assert(said.contains("today after") and g.today() == sure and sure not in g.paper, "yes: booked on its day, today: %s" % said)
	assert(g.minute == g.DAY_START + g.RING_TIME, "a call takes ten minutes")
	var never: Dictionary = g.paper[0]
	never.bar = 100.0
	said = g.ring(never)
	assert(said == "\"Oh, I've heard of you. No.\"" and never.refused and never in g.paper and g.today() == sure, "no: stamped, still in the paper")
	var first: Dictionary = g.paper[1]
	first.day = g.day
	var d: int = g.book(first)
	assert(d == g.day and g.jobs_on(d) == 2 and first not in g.paper, "however full the day: two jobs today")
	var left: Array = g.paper.duplicate()
	g.money = 1000
	while not g.payday_pending:
		g.end_day()
	g.settle_payday()
	for o: Dictionary in left:
		assert(o not in g.paper, "an unbooked ad is gone next week")
	assert(g.week_left().size() == 7, "the next paper books Saturday to Friday")
	var ad0: Dictionary = g.paper[0]
	g.calendar = {ad0.day: [{"jail": true}]}
	assert(g.cant_book(ad0) == "Day taken" and g.book(ad0) == -1, "a day taken whole takes no more")
	g.calendar = {}
	ad0.day = g.day - 1
	assert(g.cant_book(ad0) == "Gone", "a day gone")
	ad0.day = g.day
	ad0.by = g.minute + g.DRIVE - 10
	assert(g.cant_book(ad0) == "Too late", "today, too late to get there in time")


## The day's clock (design doc, Time is the scarce thing).
func _clock() -> void:
	g.new_run(7)
	for i in 40: # windows: on the half hour, inside the day, sized from their patience
		var w: Dictionary = g.make_job(500 + i, i * 2.5)
		var want := clampi(roundi(w.patience * g.MPS * g.SLACK / 30.0) * 30, 60, g.DAY_END - g.DAY_START)
		assert(w.from % 30 == 0 and w.from >= g.DAY_START and w.by <= g.DAY_END and w.by - w.from == want, "a window in the day: %s" % [[w.from, w.by, want]])
	# Arriving: the drive, or the window opening, whichever's later.
	var j := _job_for("busy")
	j.from = 720
	j.by = 960
	g.calendar[g.day] = [j]
	assert(g.arrival(j) == 720, "set off early: there when it opens")
	g.minute = 780
	assert(g.arrival(j) == 810 and g.can_go(j), "set off at 1pm: there at 1:30")
	g.start_job()
	assert(g.minute == 810 and g.current_job.patience == 240 / g.MPS and is_equal_approx(g.current_job.late, 90 / g.MPS), "their patience is the window, 90 minutes of it gone")
	assert(g.jobs_today().is_empty(), "off the list")
	var c := Customer.new(g.current_job)
	assert(is_equal_approx(c.elapsed, 90 / g.MPS), "the customer's clock starts where you came in")
	g.record_result({"outcome": "paid", "net": 50, "paid": 50, "rep": 2.0, "mood": 70.0, "elapsed": 150 / g.MPS})
	assert(g.minute == 870 and g.date_text() == "Tuesday 1 April 1980", "you leave at 2:30pm, and the day goes on")
	assert(not g.can_go({"from": 900, "by": 890}) and g.can_go({"from": 900, "by": 900}), "a window you can't reach in time")
	# Not turning up: a classified's word gets round; a regular's mood drops, and they're rebooked.
	g.regulars[9] = {"id": 9, "job": _job_for("nature"), "cadence": 14, "rate": 100, "mood": 70.0, "drift": []}
	g.calendar[g.day] = [_job_for("grump"), g._visit(9)]
	var trend: float = g.rep_trend
	var d0: int = g.day
	g.end_day()
	assert(g.rep_trend == trend - g.NO_SHOW_REP and g.missed.size() == 2, "a no-show, said so on the board")
	assert(g.regulars[9].mood == 70.0 - g.NO_SHOW_MOOD and g.bookings(d0 + 14).any(func(b: Dictionary) -> bool: return b.get("regular", -1) == 9),
		"the regular, sore, booked again")
	assert(g.minute == g.DAY_START and g.day == d0 + 1, "a new day at 8am")
	# The paper swells with the season, and at the peak regulars want you back sooner.
	g.day = g.day_of(1980, 6, 2)
	assert(g.make_paper().size() == g.PAPER_SIZE[6] and g.PAPER_SIZE[6] > g.PAPER_SIZE[4], "June's paper is fuller")
	assert(g.cadence_now({"cadence": 14}) == 7 and g.cadence_now({"cadence": 28}) == 14 and g.cadence_now({"cadence": 7}) == 7, "June: twice as often, a week at least")
	g.day = g.day_of(1980, 9, 2)
	assert(g.cadence_now({"cadence": 14}) == 14, "September: as agreed")
	# Court takes the whole day: two bookings on it move or go.
	g.calendar = {}
	g.day = g.day_of(1980, 4, 8)
	var d: int = g.day + 2
	g.calendar[d] = [_job_for("grump"), g._visit(9)]
	g._take_day(d, {"court": {}})
	assert(g.bookings(d).size() == 1 and g.bookings(d + 1).any(func(b: Dictionary) -> bool: return b.get("regular", -1) == 9), "court: the regular shifts a day, the classified's lost")


## A classified job for this persona, from the first seed that makes one.
func _job_for(persona: String) -> Dictionary:
	var s := 1
	while g.make_job(s).persona != persona:
		s += 1
	return g.make_job(s)


## Play today's booking to an end in this mood.
func _play(mood: float, outcome := "paid") -> Dictionary:
	g.start_job()
	var r := {"outcome": outcome, "net": 50, "paid": 50, "rep": 2.0, "mood": mood}
	g.record_result(r)
	return r


func _regulars() -> void:
	g.new_run(7)
	var j := _job_for("busy") # asks often, weekly
	var d0: int = g.day
	g.calendar[d0] = [j]
	_play(100.0)
	assert(not g.offer.is_empty() and g.offer.cadence == 7 and g.offer.rate == j.pay, "delighted and busy: they ask, weekly, at the job's pay")
	assert(g.day == d0, "the day goes on")
	# Days taken whole: the visit shifts a day to fit.
	g.calendar[d0 + 7] = [{"jail": true}]
	g.calendar[d0 + 8] = [{"jail": true}]
	assert(g.answer_offer("accept") == "yes" and g.offer.is_empty(), "accepted")
	var v: Dictionary = g.bookings(d0 + 6)[0]
	assert(v.get("regular", -1) == j.seed and v.pay == j.pay and v.start_mood == 80.0, "on the free day before: their rate, carried mood (60 + 100) / 2")
	assert(v.seed == j.seed and v.size == j.size, "the same garden, by its seed")
	# The visit: a good one carries its mood, drifts the garden and books the next.
	g.calendar.erase(d0 + 7)
	g.calendar.erase(d0 + 8)
	g.day = d0 + 6
	_play(70.0)
	var next: Dictionary = g.bookings(d0 + 13)[0]
	assert(next.get("regular", -1) == j.seed and next.start_mood == 65.0 and next.drift == ["gnome"], "the next week: mood (60 + 70) / 2, a gnome crept in")
	# A bad one loses them.
	g.day = d0 + 13
	var r := _play(30.0)
	assert(r.lost_regular and not g.regulars.has(j.seed) and g.calendar.values().all(func(l: Array) -> bool: return l.all(func(b: Dictionary) -> bool: return b.get("regular", -1) != j.seed)),
		"under the floor: gone, bookings and all")
	# The haggle: a happy client says yes to 20% more; an unhappy one never plainly.
	g.offer = {"id": 1, "job": j, "cadence": 14, "rate": 100, "mood": 90.0, "day": g.day, "drift": []}
	assert(g.answer_offer("haggle") == "yes" and g.regulars[1].rate == 120, "happy: $120")
	for i in 20:
		g.offer = {"id": 2, "job": j, "cadence": 14, "rate": 100, "mood": 50.0, "day": g.day, "drift": []}
		var said: String = g.answer_offer("haggle")
		assert(said in ["grudging", "walk"], "on the edge: grudging or gone")
		if said == "grudging":
			assert(g.regulars[2].mood == 40.0 and g.regulars[2].rate == 120, "grudging: the rate, and their mood drops")
		g.drop(2)
	g.drop(1)
	# You name the figure: asking only a little over their rate, a fairly happy one says yes.
	for i in 20:
		g.offer = {"id": 3, "job": j, "cadence": 14, "rate": 100, "mood": 70.0, "day": g.day, "drift": []}
		assert(g.answer_offer("haggle", 100) == "yes" and g.regulars[3].rate == 100, "a modest ask, a sure yes")
		g.drop(3)
	# Turning them down still does your name good: you were wanted.
	g.offer = {"id": 4, "job": j, "cadence": 14, "rate": 100, "mood": 70.0, "day": g.day, "drift": []}
	var rep: float = g.reputation
	assert(g.answer_offer("decline") == "no" and g.reputation == rep + g.OFFER_REP and not g.regulars.has(4), "declined: a little reputation")


## Put a case on today and hear it with this lawyer until it goes `guilty` (or not).
func _hear(case: Dictionary, lawyer: int, guilty: bool) -> Dictionary:
	var keep: Dictionary = g.calendar.duplicate(true)
	var state := [g.day, g.money, g.record]
	for i in 100:
		g.calendar = keep.duplicate(true)
		g.day = state[0]
		g.money = state[1]
		g.record = state[2]
		g.calendar[g.day] = [{"court": case}]
		var v: Dictionary = g.court(lawyer)
		if v.walked != guilty:
			return v
	assert(false, "a hundred hearings and never that verdict")
	return {}


func _court() -> void:
	g.new_run(7)
	var d0: int = g.day
	# Caught: court in the morning, and a regular booked then shifts a day.
	g.regulars[1] = {"id": 1, "job": _job_for("busy"), "cadence": 14, "rate": 100, "mood": 60.0, "drift": []}
	g.calendar[d0 + 1] = [g._visit(1)]
	g.calendar[d0] = [_job_for("nature")]
	g.start_job()
	var r := {"outcome": "nicked", "net": 0, "paid": 0, "rep": -12.0, "charge": 2.0, "tier": 2, "police": true}
	g.record_result(r)
	g.end_day()
	assert(r.court_day == d0 + 1 and g.day == d0 + 1 and g.today().has("court"), "caught: court in the morning")
	assert(g.bookings(d0 + 2).any(func(b: Dictionary) -> bool: return b.get("regular", -1) == 1), "the regular booked then shifts a day")
	var case: Dictionary = g.today().court
	assert(case.caught and case.charge == 2.0 and case.tier == 2, "the charge goes to court")
	# Guilty, a first assault, caught at it: the fine, the record, and two days' service on
	# the next free days (past the regular).
	g.money = 500
	var v := _hear(case, 0, true)
	assert(v.fine == g.fine(2, 0.0) and g.money == 500 - v.fine and g.record == 2.0, "fined $150, the record at 2")
	assert(v.service == 2 and v.jail == 0, "assault, first time, caught: two days of community service")
	for d: int in [d0 + 3, d0 + 4]:
		var job: Dictionary = g.bookings(d)[0]
		assert(job.get("service", false) and job.pay == 0 and job.venue == "graveyard", "the churchyard, unpaid")
	assert(g.day == d0 + 2, "court took the day")
	# A lawyer can get you off: the fee, nothing else.
	g.money = 1000
	var rec: float = g.record
	v = _hear(case, 3, false)
	assert(v.walked and g.money == 1000 - g.LAWYERS[3][1] and g.record == rec, "not guilty: only the fee")
	# Escaped with the police called: a summons, court a few days on.
	g.calendar = {}
	g.current_job = _job_for("nature")
	r = {"outcome": "paid", "net": 0, "paid": 0, "rep": 0.0, "charge": 1.0, "tier": 1, "police": true}
	var d1: int = g.day
	g.record_result(r)
	assert(r.court_day == d1 + g.SUMMONS_DAYS and g.calendar[r.court_day][0].court.caught == false, "a summons: court a few days on")
	# No police, no court.
	r = {"outcome": "paid", "net": 0, "paid": 0, "rep": 0.0, "charge": 1.0, "tier": 1, "police": false}
	g.record_result(r)
	assert(not r.has("court_day"), "nobody rang the police: no court")
	# Sentences grow with the record.
	assert(g.sentence({"tier": 1, "caught": false}, 0.0) == [0, 0], "a first nuisance: the fine only")
	assert(g.sentence({"tier": 1, "caught": true}, 2.0) == [2, 0], "with a record, caught: service")
	assert(g.sentence({"tier": 2, "caught": false}, 5.0) == [0, 2], "assault on a long record: jail")
	# A menace does jail for service; a long record is prison.
	g.calendar = {}
	g.record = g.MENACE
	v = _hear({"charge": 1.0, "tier": 1, "caught": false, "customer": "X"}, 0, true)
	assert(v.service == 0 and v.jail == 1 and g.today().has("jail"), "a menace: jail at once, not service")
	g.payday_pending = false
	g.skip()
	assert(not g.today().has("jail"), "jail days pass on their own")
	g.record = g.PRISON - 1.0
	v = _hear({"charge": 2.0, "tier": 2, "caught": true, "customer": "X"}, 0, true)
	assert(v.prison and g.run_over_reason == "prison" and not g.has_business(), "prison: the business is over")
	# Court the season ran out on comes first in spring; the winter fades the record.
	g.new_run(7)
	g.record = 3.0
	g.day = g.season_end()
	g.calendar[g.day + 1] = [{"court": {"charge": 1.0, "tier": 1, "caught": true, "customer": "X"}}]
	g.money = 5000
	g.end_day()
	g.settle_winter()
	assert(g.today().has("court") and g.record == 2.0, "court on 1 April, the record a little faded")


func _save() -> void:
	g.new_run(7)
	g.paper[0].day = g.day
	g.book(g.paper[0])
	g.money = 321
	g.owned.assign(["push", "petrol"])
	g.save()
	var cal: Dictionary = g.calendar.duplicate(true)
	g.money = 0
	g.calendar = {}
	g.owned.assign(["push"])
	g.in_run = false
	g.load_business()
	assert(g.in_run and g.money == 321 and g.calendar == cal and g.owned == ["push", "petrol"], "load: the same business")
	assert(g.today().size == cal[g.day][0].size, "a Vector2i survives the save")
	# Quit halfway through a job: it loads as the blackout.
	var rep: float = g.rep_trend
	var d: int = g.day
	g.start_job()
	g.in_run = false
	g.load_business()
	assert(not g.blackout.is_empty() and g.blackout.customer == cal[d][0].customer, "blacked out on that job")
	assert(g.day == d + 1 and not g.in_job and g.rep_trend == rep - g.BLACKOUT_REP, "the day's gone and word gets round")
	g.in_run = false
	g.load_business()
	assert(g.blackout.is_empty(), "only once")


func _winter() -> void:
	g.new_run(7)
	g.regulars[5] = {"id": 5, "job": _job_for("busy"), "cadence": 7, "rate": 100, "mood": 100.0, "drift": []}
	g.regulars[6] = {"id": 6, "job": _job_for("grump"), "cadence": 28, "rate": 100, "mood": 0.0, "drift": []}
	g.day = g.season_end()
	g.money = 100
	g.end_day()
	assert(g.winter_pending, "September's done")
	var w: Dictionary = g.settle_winter()
	assert(w.cost == 1300 and w.topped == 1200 and g.principal == 2200 and g.money == 0, "the winter's keep; short, the shark tops you up")
	assert(g.regulars.has(5) and not g.regulars.has(6), "the happy one's back, the sour one isn't")
	assert(g.date_text() == "Wednesday 1 April 1981" and not g.winter_pending and g.paper.size() > 0, "then April, and a paper")
	assert(g.calendar.values().any(func(l: Array) -> bool: return l.any(func(b: Dictionary) -> bool: return b.get("regular", -1) == 5)), "the one who's back is booked")
	# A business saved before the clock: one booking a day, no windows. It loads.
	g.calendar = {g.day: _job_for("grump")}
	g.calendar[g.day].erase("from")
	g.paper[0].erase("day")
	g.save()
	g.in_run = false
	g.load_business()
	assert(g.today().has("from") and g.paper[0].has("day"), "an old save gets its windows")
