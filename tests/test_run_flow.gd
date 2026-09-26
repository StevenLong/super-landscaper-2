# A whole run through the real scenes: title -> board -> job -> pay -> board,
# then the shop, the dregs when reputation is gone, and payday at the week's end.
extends SceneTree

var game: Node
var _frame := 0
var _step := 0


func _initialize() -> void:
	game = root.get_node("Game")
	game.save_path = "user://test_best.cfg"
	change_scene_to_file("res://title.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	match _step:
		0:
			assert(current_scene.name == "Title", "starts on the title")
			current_scene._start()
		1:
			assert(current_scene.name == "Board", "new run goes to the board")
			assert(game.in_run and game.week == 1 and game.job_of_week() == 1 and game.owned == ["push"], "fresh run state")
			assert(current_scene.offers.size() == 3, "fair reputation shows 3 offers")
			for o: Dictionary in current_scene.offers:
				var ad: String = game.ad_text(o)
				assert(ad.contains("$%d cash" % o.pay) and ad.contains(o.customer.split(" ")[0][0]), "an ad gives the pay and who to ring: %s" % ad)
				assert(not ad.contains("\""), "and reads as an ad, not a quote")
			for k: String in game.PERSONAS:
				assert(game.PERSONAS[k].ads.size() >= 2, "every kind of customer has ads")
			current_scene._take(current_scene.offers[0])
		2:
			assert(current_scene.name == "Main", "taking a job loads it")
			assert(paused, "the briefing pauses the job")
			assert(current_scene.mower.power == "stamina", "a new run mows with the push mower")
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
			assert(current_scene.name == "Board", "back to the board after a job")
			assert(game.job_of_week() == 2 and game.jobs_done == 1 and not game.payday_due(), "on to the week's second job")
			assert(game.money > 0, "the job paid")
			var rundown := current_scene.find_children("*", "Label", true, false).filter(
				func(l: Label) -> bool: return l.text.begins_with("Last job: Job done"))
			assert(rundown.size() == 1, "the board shows the last job's rundown")
			assert(game.last_result.has("rep_before") and game.last_result.has("rep_after"), "the rundown knows the rep change")
			var tally := current_scene.find_children("*", "Label", true, false).filter(
				func(l: Label) -> bool: return l.text.begins_with("Also counted:"))
			assert(tally.size() == 1 and tally[0].text.contains("Windows put through 1 (-$40)") and tally[0].text.contains("sent back"),
				"the rundown lists what the job counted, with what it cost")
			assert(not tally[0].text.contains("Hedgehogs"), "and nothing that didn't happen")
			assert(game.run_tally.get("windows", 0) == 1, "the run adds it up")
			game.money = 1000
			assert(game.buy("petrol") and game.equipped == "petrol", "buying a mower equips it")
			assert(not game.buy("petrol"), "you can't buy the same mower twice")
			assert(game.money == 1000 - game.MOWERS.petrol.price, "the price came off")
			game.reputation = 0.0
			current_scene._ready()
		5:
			assert(current_scene.offers.size() == 1 and current_scene.offers[0].persona == "grump", "no reputation: the dregs, one hostile job")
			assert(current_scene.find_children("Take", "Button", true, false).size() == 1, "and it can be taken")
			game.jobs_done = 3
			game.money = 40 # plus the petrol mower's resale covers week 1
			current_scene._ready()
			assert(current_scene.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "FRIDAY. PAYDAY."), "the week's end brings payday")
			current_scene._collect()
			assert(game.run_over_reason == "" and game.week == 2 and "petrol" not in game.owned, "short, the heavies took the petrol mower and it covered it")
			current_scene._run_over("BANKRUPT")
			var lines := current_scene.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
			assert("The tally" in lines and "Windows put through 1 (-$40)" in lines, "the run-over screen shows the run's tally")
			print("PASS run flow")
			quit()
	_step += 1
	return false
