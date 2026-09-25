extends Control
## Title screen: new run, best score, music/sound settings, quit.

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
	for which: String in ["music", "sound"]:
		var b := UI.button(_setting(which), Sfx.toggle.bind(which), 22)
		b.pressed.connect(func() -> void: b.text = _setting(which))
		btns.add_child(b)
	btns.add_child(UI.button("Quit", func() -> void: get_tree().quit(), 22))
	UI.focus(start)

	_help_label = UI.label("", 18, UI.DIM)
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_help_label)


func _setting(which: String) -> String:
	var on: bool = Sfx.music_on if which == "music" else Sfx.sound_on
	return "%s: %s" % [which.capitalize(), "on" if on else "off"]


func _start() -> void:
	Game.new_run()
	get_tree().change_scene_to_file("res://board.tscn")


func _help() -> void:
	_help_label.text = "\n".join([
		("Stick up/down: throttle.  Left/right: turn.  %s at your truck: hand in or leave." if Game.pad
			else "W/S or Up/Down: throttle.  A/D or Left/Right: turn.  %s at your truck: hand in or leave.") % Game.key("interact"),
		"%s: hop off (carry stones, fetch fuel, catch the dog).  Hold %s: look around.  %s: pause." % [
			Game.key("hop"), Game.key("look"), Game.key("pause")],
		"Every customer wants a different share of their lawn mowed, in a different time. They won't say.",
		"Read the briefing. Squashed wildlife and trampled flowers go down badly (usually).",
		"Pay buys better mowers. Reputation brings better jobs. Run out of reputation and you're finished.",
	])
