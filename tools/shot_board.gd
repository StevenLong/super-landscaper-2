extends SceneTree
# Screenshots of the corkboard for eyeballing its layout: a busy day in June with regulars,
# the calendar (a Go button focused, its cost lit on the clock), a page of the paper (a
# Ring focused), the shop, and a job's briefing and clock. Not a test. Needs a window:
# SHOT_DIR=<dir> "$GODOT" --path . --fixed-fps 60 -s tools/shot_board.gd
var f := 0
var out := OS.get_environment("SHOT_DIR")
var g: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://shot_best.cfg"
	g.start_month = 6
	g.new_run(11)
	g.reputation = 70.0
	g.paper = g.make_paper()
	g.minute = 650
	for i in 3: # three regulars, two of them today
		var j: Dictionary = g.make_job(40 + i)
		g.regulars[j.seed] = {"id": j.seed, "job": j, "cadence": [7, 14, 28][i], "rate": j.pay, "mood": 70.0, "drift": []}
		g._add(g.day + (0 if i < 2 else 3), g._visit(j.seed))
	for i in 5: # and the paper's, across the fortnight
		var o: Dictionary = g.make_job(60 + i)
		g._add(g.day + [0, 1, 1, 2, 9][i], o)
	g.calendar[g.day + 5] = [{"court": {}}]
	change_scene_to_file("res://board.tscn")


func _process(_d: float) -> bool:
	f += 1
	var b := current_scene
	if f == 30:
		(b.find_child("Today", true, false) as Control).grab_focus()
	if f == 40:
		root.get_texture().get_image().save_png(out + "/board_calendar.png")
		b._show("paper")
	if f == 50:
		var r := b.find_child("Ring", true, false) as Control
		if r:
			r.grab_focus()
	if f == 60:
		root.get_texture().get_image().save_png(out + "/board_paper.png")
		b._show("shop")
	if f == 80:
		root.get_texture().get_image().save_png(out + "/board_shop.png")
		b._go(g.jobs_today()[1]) # the regular's, at 1:30
	if f == 100:
		b.drive()
	if f == 130:
		root.get_texture().get_image().save_png(out + "/job_briefing.png")
		b._on_choice("start")
	if f == 160:
		root.get_texture().get_image().save_png(out + "/job_hud.png")
		quit()
	return false
