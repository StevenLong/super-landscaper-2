# A whole run through the real scenes: title -> board -> job -> pay -> board,
# then the shop, then bankruptcy when reputation is gone.
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
			assert(game.in_run and game.day == 1 and game.owned == ["push"], "fresh run state")
			assert(current_scene.offers.size() == 3, "fair reputation shows 3 offers")
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
			current_scene.hand_in()
			current_scene._on_choice("leave_paid")
			assert(game.last_result.outcome == "paid", "a mowed lawn is accepted and you drive off (the scene is already on its way out)")
		4:
			assert(current_scene.name == "Board", "back to the board after a job")
			assert(game.day == 2 and game.jobs_done == 1, "the day advanced")
			assert(game.money > 0, "the job paid")
			var rundown := current_scene.find_children("*", "Label", true, false).filter(
				func(l: Label) -> bool: return l.text.begins_with("Last job: Job done"))
			assert(rundown.size() == 1, "the board shows the last job's rundown")
			assert(game.last_result.has("rep_before") and game.last_result.has("rep_after"), "the rundown knows the rep change")
			game.money = 1000
			assert(game.buy("petrol") and game.equipped == "petrol", "buying a mower equips it")
			assert(not game.buy("petrol"), "you can't buy the same mower twice")
			assert(game.money == 1000 - game.MOWERS.petrol.price, "the price came off")
			game.reputation = 0.0
			current_scene._ready()
		5:
			assert(current_scene.offers.is_empty(), "no reputation, no offers")
			current_scene._run_over("BANKRUPT")
			print("PASS run flow")
			quit()
	_step += 1
	return false
