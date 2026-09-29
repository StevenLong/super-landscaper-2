extends Control
## Back at base after a job (design doc, The Customer): how it ended and what the job
## counted; then two books, the money and your name, each line by line to one total
## (what the customer found after you'd gone is in your name's). Then on to the board.


func _ready() -> void:
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := UI.vbox(16)
	center.add_child(root)
	var r: Dictionary = Game.last_result
	root.add_child(_rundown(r))
	var books := UI.hbox(16) # the money and your name, each with its one total
	books.add_child(_money(r))
	books.add_child(_reputation(r))
	root.add_child(books)
	var go := UI.button("Back to the board", func() -> void:
		Game.answer_offer("decline") # walking away is a no
		get_tree().change_scene_to_file("res://board.tscn"), 24)
	go.name = "Continue"
	root.add_child(go)
	UI.focus(go)
	if not Game.offer.is_empty():
		root.add_child(_offer(go))
		root.move_child(go, -1)
		UI.focus(find_child("Accept", true, false) as Control)


## They want you back (design doc, The Business: regulars): the terms, then accept,
## decline, or push for more. What they say replaces the buttons.
func _offer(go: Button) -> Control:
	var o: Dictionary = Game.offer
	var box := UI.vbox(8)
	var every: String = {7: "every week", 14: "every fortnight", 28: "every four weeks"}[o.cadence]
	var ask := UI.label("%s catches you at the truck: \"Could you come %s? $%d a visit.\"" % [o.job.customer, every, o.rate], 22, UI.GOLD)
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.custom_minimum_size.x = 780
	box.add_child(ask)
	var row := UI.hbox(12)
	box.add_child(row)
	var push := roundi(o.rate * Game.HAGGLE / 5.0) * 5
	for b: Array in [["Accept", "accept", "Deal"], ["Haggle", "haggle", "Ask for $%d" % push], ["Decline", "decline", "No thanks"]]:
		var btn := UI.button(b[2], func() -> void:
			var said := Game.answer_offer(b[1])
			ask.text = {"yes": "\"Lovely. See you then.\" A regular: $%d %s." % [Game.regulars.get(o.id, o).rate, every],
				"grudging": "\"...Fine. But it had better be good.\" $%d %s, and they're not pleased." % [Game.regulars.get(o.id, o).rate, every],
				"walk": "\"At that price? Forget it.\" They're gone.", "no": "\"Suit yourself.\""}[said]
			row.queue_free()
			UI.focus(go), 20)
		btn.name = b[0]
		row.add_child(btn)
	return UI.panel(box)


## Whole points, but never a flat zero for something that did count.
func _shown(rep: float) -> int:
	var n := roundi(rep)
	return n if n != 0 else int(signf(rep))


## A line in one of the books: what, then its amount at the right.
func _line(box: Control, what: String, amount: String, color := UI.TEXT, font_size := 20) -> void:
	var row := UI.hbox(12)
	var l := UI.label(what, font_size, color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(UI.label(amount, font_size, color))
	box.add_child(row)


func _dollars(v: float) -> String:
	return "%s$%d" % ["-" if v < 0.0 else "+", absi(roundi(v))]


## Every dollar in and out, and the net.
func _money(r: Dictionary) -> Control:
	var box := UI.vbox(4)
	box.custom_minimum_size.x = 340
	box.add_child(UI.label("Money", 24, UI.GOLD))
	var bills: float = r.get("bills", 0.0)
	var upkeep: float = r.fuel_cost - bills
	if r.paid > 0:
		_line(box, "Paid" + (" (incl. $%d tip)" % r.tip if r.tip > 0 else ""), _dollars(r.paid), UI.GOOD)
	if r.get("robbed", 0) > 0:
		_line(box, "Lifted from their pockets", _dollars(r.robbed), UI.GOOD)
	if upkeep >= 1.0:
		_line(box, "Fuel and repairs", _dollars(-upkeep), UI.BAD)
	if bills > 0.0:
		_line(box, "Damages", _dollars(-bills), UI.BAD)
	if r.get("fine", 0) > 0:
		_line(box, "Fine", _dollars(-r.fine), UI.BAD)
	if box.get_child_count() == 1:
		_line(box, "Nothing in, nothing out", "$0", UI.DIM)
	_line(box, "Net", _dollars(r.net), UI.GOOD if r.net >= 0.0 else UI.BAD, 24)
	return UI.panel(box)


## What moved your name, the job and after, and what they found once you'd gone; the
## total, and how much of it shows yet (your standing catches up over the next jobs).
func _reputation(r: Dictionary) -> Control:
	var box := UI.vbox(4)
	box.custom_minimum_size.x = 420
	box.add_child(UI.label("Reputation", 24, UI.GOLD))
	var total := 0 # what's shown adds up, whatever the rounding
	for l: Array in r.get("rep_lines", []):
		total += _shown(l[1])
		_line(box, l[0], "%+d" % _shown(l[1]), UI.GOOD if l[1] >= 0.0 else UI.BAD)
	var noticed: Array = r.get("noticed", [])
	if not noticed.is_empty():
		box.add_child(UI.label("After you left, the customer noticed:", 20, UI.DIM))
		for n: Array in noticed:
			total += _shown(n[1])
			_line(box, "   " + n[0], "%+d" % _shown(n[1]), UI.GOOD if n[1] >= 0.0 else UI.BAD)
	_line(box, "All told", "%+d" % total, UI.GOOD if total >= 0 else UI.BAD, 24)
	if r.has("rep_after"):
		var moved := roundi(r.rep_after - r.rep_before)
		var standing := "Word travels: your standing is %s" % UI.rep_word(r.rep_after)
		if total != moved:
			standing += " (%+d so far, the rest over the next jobs)" % moved
		var s := UI.label(standing, 18, UI.DIM)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 420
		box.add_child(s)
	return UI.panel(box)


## How the job ended: who, what they said, what else came of it, and what it counted.
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
	var also: Array[String] = []
	if r.has("court_day"):
		also.append(("A night in the cells: court %s" if r.outcome == "nicked" else "A summons: court on %s") % Game.date_text(r.court_day))
	if r.get("lost_regular", false):
		also.append("They won't be booking you again")
	if not also.is_empty():
		info.add_child(UI.label("   ".join(also), 20, UI.BAD))
	for l: Label in info.get_children(): # long lines wrap, not shove the books off the screen
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 640
	var tally := Game.tally_lines(r.get("tally", {}), r.get("tally_cost", {}), r.get("records", []))
	if not tally.is_empty(): # everything the job counted, going by like a news ticker
		info.add_child(Ticker.new("   *   ".join(tally), 18, UI.GOLD, 640))
	return UI.panel(row)
