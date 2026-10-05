# A season through the real scenes: title -> board (book an ad) -> job -> pay -> summary
# (a regular's offer, haggled) -> board, the regular's visit (carried mood, drift), quitting
# halfway and the blackout on Continue, the dregs, and payday with the heavies.
extends SceneTree

var game: Node
var _frame := 0
var _step := 0
var _visit_day := 0


func _initialize() -> void:
	game = root.get_node("Game")
	game.save_path = "user://test_best.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.business_path()))
	change_scene_to_file("res://title.tscn")


func _labels() -> Array:
	return current_scene.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


## Say something in the open talk.
func _reply(text: String) -> void:
	var talks := current_scene.find_children("Talk", "", true, false).filter(func(t: Node) -> bool: return not t.is_queued_for_deletion())
	for b: Node in (talks[-1].find_children("*", "Button", true, false) if talks else []):
		if (b as Button).text == text and not b.is_queued_for_deletion():
			(b as Button).pressed.emit()
			return
	assert(false, "no %s to say" % text)


func _press(button: String) -> void:
	var b: Button = current_scene.find_child(button, true, false)
	assert(b != null and not b.disabled, "a %s button to press" % button)
	b.pressed.emit()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	if current_scene.name == "Pack": # packing the truck: test_pack has it; drive on
		current_scene.drive()
		return false
	match _step:
		0:
			assert(current_scene.name == "Title", "starts on the title")
			assert(current_scene.find_child("Continue", true, false) == null, "no business yet, nothing to continue")
			current_scene._start()
		1:
			assert(current_scene.name == "Board", "a new business goes to the board")
			assert(game.in_run and game.date_text() == "Tuesday 1 April 1980" and game.owned == ["push"], "fresh business")
			game.new_run(7) # the same business every time
			current_scene._build()
			assert(game.paper.size() == game.PAPER_SIZE[4], "April's paper")
			for o: Dictionary in game.paper:
				var text: String = game.ad_text(o)
				assert(text.contains("$%d cash" % o.pay) and text.contains(o.customer.split(" ")[0][0]), "an ad gives the pay and who to ring: %s" % text)
				assert(not text.contains("\""), "and reads as an ad, not a quote")
			for k: String in game.PERSONAS:
				assert(game.PERSONAS[k].ads.size() >= 2, "every kind of customer has ads")
			assert(current_scene.find_child("Today", true, false) == null and current_scene.find_child("EndDay", true, false).text == "Call it a day", "nothing booked yet")
			var ad: Dictionary = game.paper[0]
			ad.bar = 0.0 # a sure yes
			ad.day = game.day # today, ten till three
			ad.from = 600
			ad.by = 900
			current_scene._show("paper")
			assert(current_scene.find_child("Ad", true, false) == null and "THE WEEKLY ADVERTISER" in _labels(), "the paper opens on its front page")
			current_scene._page = 1
			current_scene._build()
			_press("Ad") # ring it: they pick up, and you book it
			_reply("Book it")
			assert(game.today() == ad and game.paper.size() == game.PAPER_SIZE[4] - 1, "they said yes: booked into today")
			assert(game.minute == game.DAY_START + game.RING_TIME, "the call took its time")
			_reply("Bye")
			assert(current_scene.find_child("Call", true, false).text.contains("today after 10am"), "and what they said is shown")
			current_scene._show("calendar")
			assert(current_scene.find_child("Calendar", true, false) != null, "the corkboard's calendar")
			assert(current_scene.find_child("State", true, false).text == "Opens at 10am.", "today's job, and when it opens")
			game.next_job = game.today() # off in the truck (test_hub has the truck)
			change_scene_to_file("res://pack.tscn")
		2:
			assert(current_scene.name == "Main", "going loads the job")
			assert(game.in_job and game.has_business(), "saved as started")
			assert(paused, "the briefing pauses the job")
			assert(current_scene.mower.power == "stamina", "a new business mows with the push mower")
			current_scene._on_choice("start")
			assert(not paused, "starting the job unpauses")
		3:
			var lawn: Lawn = current_scene.get_node("Lawn")
			for y in range(0, lawn.size_px.y, 20):
				lawn.cut_segment(Vector2(0, y), Vector2(lawn.size_px.x, y), 20.0)
			current_scene._count("windows", 40.0) # as if a stone went through one
			current_scene._count("sent_back")
			current_scene.hand_in()
			current_scene.customer.elapsed += 100.0 # dawdling after they've paid
			current_scene._on_choice("drive_off")
			assert(game.last_result.outcome == "paid", "a mowed lawn is accepted and you drive off (the scene is already on its way out)")
			assert(game.last_result.elapsed >= 100.0 and game.minute == 600 + roundi(game.last_result.elapsed * game.MPS), "the day goes on from when you drove off, not when they paid")
		4:
			assert(current_scene.name == "Summary", "back at base, the job's summary")
			assert(game.date_text() == "Tuesday 1 April 1980" and game.minute >= 600 and not game.in_job, "the day goes on, from when you got there")
			var labels := _labels()
			assert(labels.any(func(t: String) -> bool: return t.begins_with("Last job: Job done")), "how it ended")
			assert(game.last_result.has("rep_before") and game.last_result.has("rep_after"), "the rundown knows the rep change")
			var tally := current_scene.find_children("*", "Ticker", true, false)
			assert(tally.size() == 1 and tally[0].text.contains("Windows put through 1 (-$40)") and tally[0].text.contains("sent back"),
				"the rundown lists what the job counted, with what it cost")
			assert(not tally[0].text.contains("Hedgehogs"), "and nothing that didn't happen")
			assert("After you left, the customer noticed:" in labels and labels.any(func(t: String) -> bool: return t.contains("Every blade cut")),
				"what they found after you'd gone: every blade cut")
			assert("Money" in labels and "Reputation" in labels and "Net" in labels and "All told" in labels, "two books, a total each")
			assert(labels.count("All told") == 1 and not labels.any(func(t: String) -> bool: return t.begins_with("Reputation ")), "one reputation total, not two")
			# The offer's a hidden chance: make sure of one, and see it again.
			var j: Dictionary = game.current_job
			game.offer = {"id": j.seed, "job": j, "cadence": 14, "rate": j.pay, "mood": 90.0, "day": game.day, "drift": []}
			_visit_day = game.day + 14
			change_scene_to_file("res://summary.tscn")
		5:
			assert(not _labels().any(func(t: String) -> bool: return t.contains("Could you come")), "the summary first")
			_press("Continue")
			assert(_labels().any(func(t: String) -> bool: return t.contains("Could you come every fortnight?")), "then they ask you back, on a screen of its own")
			_press("Haggle")
			var j: Dictionary = game.current_job
			assert(game.regulars.has(j.seed) and game.regulars[j.seed].rate == roundi(j.pay * 1.2 / 5.0) * 5, "happy: they take the higher rate")
			assert(_labels().any(func(t: String) -> bool: return t.contains("A regular")), "and say so")
			_press("Continue")
		6:
			assert(current_scene.name == "Hub" and game.place == "home" and game.spot == "truck", "then home: your premises, by the truck")
			var desk: Node = load("res://board.tscn").instantiate() # and in, to the desk
			current_scene.free()
			root.add_child(desk)
			current_scene = desk
			current_scene._show("book")
			assert("Your regulars (1)" in _labels(), "your regulars listed, in the client book")
			assert(game.bookings(_visit_day).any(func(b: Dictionary) -> bool: return b.get("regular", -1) == game.current_job.seed), "their first visit a fortnight on")
			assert(game.money > 0 and game.run_tally.get("windows", 0) == 1, "the job paid, the season adds it up")
			game.money = 1000
			game.premises = 1 # room for two petrol mowers (the lock-up's: test_premises)
			assert(game.buy("petrol") and game.equipped == "petrol", "buying a mower equips it")
			assert(game.money == 1000 - game.MOWERS.petrol.price, "the price came off")
			assert(game.buy("petrol") and game.total("petrol") == 2 and game.equipped == "petrol", "another goes in the pool")
			game.sell("petrol")
			assert(game.total("petrol") == 1 and "petrol" in game.owned, "and sold, one's left")
			game.premises = 0 # back in the lock-up: its rent's the one the sums below expect
			# To the regular's day, with things crept into the garden since.
			game.day = _visit_day
			game.minute = game.DAY_START
			game.calendar[_visit_day][0].drift = ["flamingo", "flamingo", "flamingo"]
			game.next_job = game.today()
			change_scene_to_file("res://pack.tscn")
		7:
			assert(current_scene.name == "Main" and current_scene.job.has("regular"), "the regular's visit")
			assert(current_scene.customer.mood == 90.0, "they start in the mood they were left in")
			var flamingos: int = current_scene.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s.kind == "flamingo").size()
			assert(flamingos >= 3, "what crept in is there")
			current_scene._on_choice("quit") # halfway: ironman remembers
		8:
			assert(current_scene.name == "Title", "quit to the title")
			_press("Continue")
		9:
			assert(current_scene.name == "Board" and "YOU BLACKED OUT" in _labels(), "the job you quit loads as the blackout")
			assert(game.regulars.is_empty() and game.day == _visit_day + 1, "that client's lost, and the day")
			current_scene._ready() # carry on: the lost day's end
			assert(not game.day_end.is_empty() and "DAY'S END" in _labels(), "then the day you lost, ended")
			game.day_end = {}
			game.reputation = 0.0
			game.paper = game.make_paper()
			current_scene._build()
			var never: Dictionary = game.make_job(999, 60.0) # an ad for a Good name
			never.day = game.day + 1
			game.paper.push_front(never) # on the first page
			current_scene._call = game.ring(never)
			current_scene._show("paper")
			current_scene._page = 1
			current_scene._build()
			var stamped := current_scene.find_children("Ad", "Button", true, false).filter(func(b: Button) -> bool: return b.text.contains("NO:"))
			assert(never.refused and stamped.size() == 1 and stamped[0].disabled, "no reputation: a no, stamped, and no more ringing it")
			game.money = 70 # plus the petrol mower's resale covers $150
			game.payday_pending = true
			current_scene._ready()
			assert("FRIDAY. PAYDAY." in _labels(), "Friday brings payday")
			current_scene._collect(0)
			assert(game.run_over_reason == "" and "petrol" not in game.owned and game.money == 10, "short, the heavies took the petrol mower and it covered it")
			current_scene._run_over()
			var lines := _labels()
			assert("The tally" in lines and "Windows put through 1 (-$40)" in lines, "the business's end shows its tally")
			print("PASS run flow")
			quit()
	_step += 1
	return false
