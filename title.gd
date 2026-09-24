extends Control
## Title screen: new run, best score, quit.

var _help_label: Label


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	add_child(preload("res://attract.gd").new())
	var dim := ColorRect.new() # keep the menu readable over the mowing
	dim.color = Color(0.05, 0.1, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var col := UI.vbox(14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	var title := UI.label("SUPER LANDSCAPER", 80, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.shadow(title, 6)
	col.add_child(title)
	var sub := UI.label("Mow the lawn. Mind the wildlife. Keep the customer happy. Mostly.", 22, UI.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	col.add_child(Control.new())
	var best := UI.label("Best run: $%d" % Game.best_score, 24)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(best)

	var btns := UI.vbox(10)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	var holder := CenterContainer.new()
	holder.add_child(btns)
	col.add_child(holder)
	var start := UI.button("Start a new run", _start, 26)
	btns.add_child(start)
	btns.add_child(UI.button("How to play", _help, 22))
	btns.add_child(UI.button("Quit", func() -> void: get_tree().quit(), 22))
	UI.focus(start)

	_help_label = UI.label("", 18, UI.DIM)
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_help_label)


func _start() -> void:
	Game.new_run()
	get_tree().change_scene_to_file("res://board.tscn")


func _help() -> void:
	_help_label.text = "\n".join([
		"W/S or Up/Down: throttle.  A/D or Left/Right: turn.  E at your truck: hand in or leave.",
		"F: hop off (carry stones, fetch fuel, catch the dog).  Hold Tab: look around.  Esc: pause.",
		"Every customer wants a different share of their lawn mowed, in a different time. They won't say.",
		"Read the briefing. Squashed wildlife and trampled flowers go down badly (usually).",
		"Pay buys better mowers. Reputation brings better jobs. Run out of reputation and you're finished.",
	])
