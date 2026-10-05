extends SceneTree
# Screenshots of the desk's paper things for eyeballing (board.gd): the day's end as cards
# (one opened), the client book's index and a client's page, the paper's front page, a page
# of classifieds, situations wanted, and a call.
# Not a test. Needs a window:
# SHOT_DIR=<dir> "$GODOT" --path . --fixed-fps 60 -s tools/shot_desk.gd
var f := 0
var g: Node
var out := OS.get_environment("SHOT_DIR")


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://shot_best.cfg"
	g.start_month = 6
	g.new_run(11)
	g.money = 2330
	g.premises = 1
	g.staff_room = "corner"
	g.helpers.assign([{"id": 1, "name": "Nigel Thistlewood", "pace": 0.7, "care": 0.4, "wage": 470, "jobs": 3, "happy": 70.0, "asks": 520}])
	g.day_end = {"day": g.day, "was": 2400, "now": 2330, "crew": [], "crew_net": 9, "missed": ["Gwen Hughes"],
		"mine": [{"customer": "Doreen Ashdown", "net": 96, "outcome": "paid", "mood": 78.0, "at": 540, "paid": 120, "tip": 10, "fuel": 34, "rep": 4.0},
			{"customer": "Tom Okafor", "net": 140, "outcome": "paid", "mood": 88.0, "at": 840, "paid": 160, "tip": 0, "fuel": 20, "rep": 3.0}],
		"crew_jobs": [{"who": "Nigel", "helper": 1, "customer": "Raj Patel", "at": 600, "net": 9, "flag": "flattened a flowerbed",
			"lines": [["Paid", "$82"], ["Fuel", "-$12"], ["Flattened a flowerbed", "-$61"], ["Mood", "not happy, 41"], ["Reputation", "-1"]]}],
		"ledger": [["Bought petrol mower", -300]]}
	for i in 5:
		var j: Dictionary = g.make_job(40 + i)
		g.regulars[j.seed] = {"id": j.seed, "job": j, "cadence": [7, 14, 28, 7, 14][i], "rate": j.pay, "mood": [90.0, 60.0, 30.0, 75.0, 50.0][i], "drift": [],
			"visits": i + 1, "prepaid": 2 if i == 0 else 0, "prepaid_each": 80.0}
		g._add(g.day + 2 + i, g._visit(j.seed))
	g.place = "home"
	g.spot = "desk"
	change_scene_to_file("res://board.tscn")


func _process(_d: float) -> bool:
	f += 1
	var b := current_scene
	if f == 20:
		(b.find_child("Card_1", true, false) as Button).pressed.emit()
	if f == 26:
		_shot("desk_day_end")
		g.day_end = {}
		b._ready()
	if f == 32:
		_shot("desk_book")
		(b.find_children("Client", "Button", true, false)[0] as Button).pressed.emit()
	if f == 38:
		_shot("desk_client")
		b._client = -1
		g.paper = g.make_paper()
		g.wanted = g.make_wanted()
		b._show("paper")
	if f == 44:
		_shot("paper_front")
		b._turn_page(1)
	if f == 50:
		_shot("paper_ads")
		b._turn_page(1)
		b._turn_page(1)
	if f == 56:
		_shot("paper_wanted")
		b._page = 1
		b._build()
	if f == 60:
		for a: Node in b.find_children("Ad", "Button", true, false):
			if not (a as Button).disabled:
				(a as Button).pressed.emit()
				break
	if f == 70:
		_shot("paper_call")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
		quit()
	return false


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
