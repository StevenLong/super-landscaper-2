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


func _press(button: String) -> void:
	var b: Button = current_scene.find_child(button, true, false)
	assert(b != null and not b.disabled, "a %s button to press" % button)
	b.pressed.emit()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
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
			assert(game.paper.size() == 3, "fair reputation: three ads in the paper")
			for o: Dictionary in game.paper:
				var text: String = game.ad_text(o)
				assert(text.contains("$%d cash" % o.pay) and text.contains(o.customer.split(" ")[0][0]), "an ad gives the pay and who to ring: %s" % text)
				assert(not text.contains("\""), "and reads as an ad, not a quote")
			for k: String in game.PERSONAS:
				assert(game.PERSONAS[k].ads.size() >= 2, "every kind of customer has ads")
			assert(current_scene.find_child("Today", true, false).text == "On to the next job", "nothing booked yet")
			var ad: Dictionary = game.paper[0]
			_press("Book")
			assert(game.today() == ad and game.paper.size() == 2, "booked into today")
			assert(current_scene.find_child("Calendar", true, false) != null, "the month's calendar")
			assert(current_scene.find_child("Today", true, false).text == "Go", "today's job to go to")
			_press("Today")
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
			current_scene._on_choice("drive_off")
			assert(game.last_result.outcome == "paid", "a mowed lawn is accepted and you drive off (the scene is already on its way out)")
		4:
			assert(current_scene.name == "Summary", "back at base, the job's summary")
			assert(game.date_text() == "Wednesday 2 April 1980" and not game.in_job, "the day's done")
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
			game.offer = {"id": j.seed, "job": j, "cadence": 14, "rate": j.pay, "mood": 90.0, "day": game.day - 1, "drift": []}
			_visit_day = game.day - 1 + 14
			change_scene_to_file("res://summary.tscn")
		5:
			assert(_labels().any(func(t: String) -> bool: return t.contains("Could you come every fortnight?")), "they ask you back")
			_press("Haggle")
			var j: Dictionary = game.current_job
			assert(game.regulars.has(j.seed) and game.regulars[j.seed].rate == roundi(j.pay * 1.2 / 5.0) * 5, "happy: they take the higher rate")
			assert(_labels().any(func(t: String) -> bool: return t.contains("A regular")), "and say so")
			_press("Continue")
		6:
			assert(current_scene.name == "Board", "then the board")
			assert("Your regulars" in _labels(), "your regulars listed")
			assert(game.calendar.get(_visit_day, {}).get("regular", -1) == game.current_job.seed, "their first visit a fortnight on")
			assert(game.money > 0 and game.run_tally.get("windows", 0) == 1, "the job paid, the season adds it up")
			game.money = 1000
			assert(game.buy("petrol") and game.equipped == "petrol", "buying a mower equips it")
			assert(not game.buy("petrol"), "you can't buy the same mower twice")
			assert(game.money == 1000 - game.MOWERS.petrol.price, "the price came off")
			# To the regular's day, with things crept into the garden since.
			game.day = _visit_day
			game.calendar[_visit_day].drift = ["flamingo", "flamingo", "flamingo"]
			current_scene._ready()
			_press("Today")
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
			current_scene._ready() # carry on
			game.reputation = 0.0
			game.paper = game.make_offers()
			current_scene._build()
			assert(game.paper.size() == 1 and game.paper[0].persona == "grump", "no reputation: the dregs, one hostile job")
			assert(current_scene.find_children("Book", "Button", true, false).size() == 1, "and it can be booked")
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
