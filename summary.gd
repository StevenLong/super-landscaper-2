extends Control
## Back at base after a job (design doc, The Customer): how it ended, the money, what it
## did to your name, what the job counted, and what the customer found after you'd gone.
## Then on to the board.


func _ready() -> void:
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := UI.vbox(18)
	center.add_child(root)
	var r: Dictionary = Game.last_result
	root.add_child(_rundown(r))
	var noticed: Array = r.get("noticed", [])
	if not noticed.is_empty():
		var box := UI.vbox(6)
		box.add_child(UI.label("After you left, the customer noticed:", 24, UI.GOLD))
		var total := 0.0
		for n: Array in noticed:
			var rep: float = n[1]
			total += rep
			box.add_child(UI.label("   %s:  reputation %+d" % [n[0], _shown(rep)], 20, UI.GOOD if rep >= 0.0 else UI.BAD))
		box.add_child(UI.label("Word gets round: reputation %+d all told" % _shown(total), 22, UI.GOOD if total >= 0.0 else UI.BAD))
		root.add_child(UI.panel(box))
	var go := UI.button("Back to the board", func() -> void: get_tree().change_scene_to_file("res://board.tscn"), 24)
	go.name = "Continue"
	root.add_child(go)
	UI.focus(go)


## Whole points, but never a flat zero for something that did count.
func _shown(rep: float) -> int:
	var n := roundi(rep)
	return n if n != 0 else int(signf(rep))


## The last job in one panel: how it ended, the money, and what it did to your name.
func _rundown(r: Dictionary) -> Control:
	var row := UI.hbox(14)
	if r.has("look"):
		var f := Face.new()
		f.pixel_scale = 2
		f.custom_minimum_size = Vector2(92, 92)
		f.set_look(r.look)
		f.expression = r.face
		row.add_child(f)
	var info := UI.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title: String = {"fired": "FIRED!", "walked": "You drove off unpaid",
		"ko": "Well, that happened", "nicked": "Nicked!"}.get(r.outcome, "Job done")
	info.add_child(UI.label("Last job: %s   %s" % [title, r.get("customer", "")], 22,
		UI.GOOD if r.outcome == "paid" else UI.BAD))
	info.add_child(UI.label(r.comment if r.outcome == "ko" else "\"%s\"" % r.comment, 18, UI.DIM))
	var money := "Paid $%d" % r.paid
	if r.tip > 0:
		money += " (incl. $%d tip)" % r.tip
	if r.fuel_cost > 0.0:
		money += "   Costs -$%d" % roundi(r.fuel_cost)
	if r.get("robbed", 0) > 0:
		money += "   Lifted $%d" % r.robbed
	if r.get("fine", 0) > 0:
		money += "   Fine -$%d" % r.fine
	money += "   Net %s$%d" % ["+" if r.net >= 0.0 else "-", absi(roundi(r.net))]
	info.add_child(UI.label(money, 20))
	var d: float = r.get("rep_after", 0.0) - r.get("rep_before", 0.0)
	var rep := "Reputation %+d" % roundi(d)
	if Game.rep_trend - Game.reputation < -3.0:
		rep += ", and sliding"
	if r.get("mischief", 0.0) > 0.0:
		rep += "   (mischief after payment: -%d)" % roundi(r.mischief)
	if r.get("heat_up", false):
		rep += "   Wanted level up"
	if r.get("cells", false):
		rep += "   A night in the cells: next job lost"
	info.add_child(UI.label(rep, 20, UI.GOOD if d >= 0.0 and r.outcome == "paid" else UI.BAD))
	for l: Label in info.get_children(): # long lines wrap, not shove the shop off the screen
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 560
	var tally := Game.tally_lines(r.get("tally", {}), r.get("tally_cost", {}), r.get("records", []))
	if not tally.is_empty(): # everything the job counted, going by like a news ticker
		info.add_child(Ticker.new("   *   ".join(tally), 18, UI.GOLD, 560))
	return UI.panel(row)
