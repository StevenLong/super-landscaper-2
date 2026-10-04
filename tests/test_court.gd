# Court and community service through the real scenes: a court day on the board opens
# the court, a lawyer is picked and the verdict shown; community service is the
# churchyard, unpaid, signed off, and mends your name.
extends SceneTree

var game: Node
var _frame := 0
var _step := 0


func _initialize() -> void:
	game = root.get_node("Game")
	game.save_path = "user://test_best.cfg"
	game.new_run(7)
	game.calendar[game.day] = [{"court": {"charge": 2.0, "tier": 2, "caught": false, "customer": "Keith Figgis"}}]
	change_scene_to_file("res://board.tscn")


func _labels() -> Array:
	return current_scene.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	if current_scene.name == "Pack": # packing the truck: test_pack has it; drive on
		current_scene.drive()
		return false
	match _step:
		0:
			assert("COURT" in _labels(), "a court day opens the court")
			var lawyers := current_scene.find_children("*", "Button", true, false)
			assert(lawyers.size() == game.LAWYERS.size() and lawyers[3].disabled and not lawyers[0].disabled, "four ways to plead; $0 buys only yourself")
			current_scene._verdict(0)
			var said := _labels()
			assert("GUILTY" in said or "NOT GUILTY" in said, "a verdict")
			if "GUILTY" in said:
				assert(said.any(func(t: String) -> bool: return t.contains("community service")), "a first assault, summoned: service")
			# Today's community service.
			game.calendar = {game.day: [game.service_job()]}
			game.day_end = {} # the court day's end, read
			current_scene._ready()
			assert(current_scene.find_child("Today", true, false).text.begins_with("Go"), "service to go to")
			current_scene.find_child("Today", true, false).pressed.emit()
		1:
			assert(current_scene.name == "Main" and current_scene.job.service and current_scene.job.venue == "graveyard", "the churchyard")
			current_scene._on_choice("start")
			var lawn: Lawn = current_scene.get_node("Lawn")
			for y in range(0, lawn.size_px.y, 20):
				lawn.cut_segment(Vector2(0, y), Vector2(lawn.size_px.x, y), 20.0)
			current_scene.hand_in()
			assert(current_scene.settled.paid == 0, "unpaid")
			current_scene._on_choice("drive_off")
			var r: Dictionary = game.last_result
			assert(r.rep_lines.any(func(l: Array) -> bool: return l[0] == "Community service done"), "and it mends your name")
			assert(game.offer.is_empty(), "the vicar never asks you back as a regular")
			print("PASS court")
			quit()
	_step += 1
	return false
