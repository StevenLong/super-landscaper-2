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
	if not Game.upfront.is_empty() and not Game.regulars.has(Game.upfront.id): # they've gone since
		Game.upfront = {}
	var offered := not Game.offer.is_empty() or not Game.upfront.is_empty()
	var row := UI.hbox(14)
	root.add_child(row)
	var go := UI.button("Continue" if offered else "Back to the board", func() -> void:
		if not Game.offer.is_empty():
			_offer_screen()
		elif not Game.upfront.is_empty():
			_upfront_screen()
		else:
			get_tree().change_scene_to_file("res://board.tscn"), 24)
	go.name = "Continue"
	row.add_child(go)
	var id: int = Game.current_job.get("regular", -1)
	if r.get("can_raise", false) and Game.regulars.has(id) and not offered: # a good visit: try your luck
		var raise := UI.button("Ask for a raise", _raise_screen.bind(id), 24)
		raise.name = "Raise"
		row.add_child(raise)
	UI.focus(go)


## A screen of its own with a title and a customer's face beside their words. Returns
## [root column, face, words].
func _page(title_text: String, look: Dictionary, expression: String, words: String) -> Array:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := UI.vbox(18)
	center.add_child(root)
	var title := UI.label(title_text, 40, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var top := UI.hbox(18)
	root.add_child(top)
	var face := Face.new()
	face.custom_minimum_size = Vector2(132, 132)
	face.set_look(look)
	face.expression = expression
	top.add_child(face)
	var said := UI.label(words, 22)
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.custom_minimum_size.x = 620
	said.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(said)
	return [root, face, said]


## Back to the board, focused.
func _back(root: Control) -> void:
	var go := UI.button("Back to the board", func() -> void: get_tree().change_scene_to_file("res://board.tscn"), 24)
	go.name = "Continue"
	root.add_child(go)
	UI.focus(go)


## A good visit from a regular: ask for more (design doc, Regulars change softly). You
## name the figure; ask a lot and they may not afford you.
func _raise_screen(id: int) -> void:
	var reg: Dictionary = Game.regulars[id]
	var p := _page("A RAISE?", reg.job.look, "happy", "%s pays you $%d a visit. They look pleased with the lawn. Ask for more?" % [reg.job.customer, reg.rate])
	var root: VBoxContainer = p[0]
	var asked := [roundi(reg.rate * 1.1 / 5.0) * 5]
	var choices := UI.vbox(12)
	root.add_child(choices)
	var buttons := UI.hbox(12)
	var ask := UI.button("Ask for $%d" % asked[0], func() -> void:
		var reply := Game.ask_raise(id, asked[0])
		p[2].text = {"yes": "\"Fair enough. $%d it is.\"", "grudging": "\"...If I must. $%d.\" They're not pleased.",
			"no": "\"I can't afford that, I'm afraid.\" Still $%d a visit, and they're a little put out."}[reply] % Game.regulars[id].rate
		p[1].expression = {"yes": "happy", "grudging": "annoyed", "no": "neutral"}[reply]
		choices.queue_free()
		_back(root), 20)
	ask.name = "AskRaise"
	buttons.add_child(ask)
	var leave := UI.button("Leave it", func() -> void: get_tree().change_scene_to_file("res://board.tscn"), 20)
	leave.name = "Leave"
	buttons.add_child(leave)
	var row := UI.hbox(14)
	row.add_child(UI.label("Ask for:", 22))
	row.add_child(UI.amount(reg.rate + 5, roundi(reg.rate * Game.ASK_MAX / 5.0) * 5, 5, asked[0], func(v: int) -> void:
		asked[0] = v
		ask.text = "Ask for $%d" % v))
	choices.add_child(row)
	choices.add_child(buttons)
	UI.focus(ask)


## A loyal regular offers a month up front: money now, the visits owed.
func _upfront_screen() -> void:
	var u: Dictionary = Game.upfront
	var reg: Dictionary = Game.regulars[u.id]
	var p := _page("A MONTH UP FRONT", reg.job.look, "delighted", "%s: \"Shall I pay you for the next %d visit%s now? $%d.\" (Drop them before those are done and you owe the rest back.)"
		% [reg.job.customer, u.visits, "" if u.visits == 1 else "s", u.amount])
	var root: VBoxContainer = p[0]
	var buttons := UI.hbox(12)
	root.add_child(buttons)
	var take := UI.button("Take it: $%d" % u.amount, func() -> void:
		Game.take_upfront()
		p[2].text = "$%d in your pocket. %d visit%s owed." % [u.amount, u.visits, "" if u.visits == 1 else "s"]
		buttons.queue_free()
		_back(root), 20)
	take.name = "Accept"
	buttons.add_child(take)
	var no := UI.button("No thanks", func() -> void:
		Game.upfront = {}
		Game.save()
		p[2].text = "\"As you like.\""
		buttons.queue_free()
		_back(root), 20)
	no.name = "Decline"
	buttons.add_child(no)
	UI.focus(take)


## They want you back (design doc, The Business: regulars): a win, so its own screen.
## Their face and their words; take it, push for more (you name the figure: ask less and
## they're likelier to say yes), or turn them down politely, which still does your name good.
func _offer_screen() -> void:
	var o: Dictionary = Game.offer
	var every: String = {7: "every week", 14: "every fortnight", 28: "every four weeks"}[o.cadence]
	var p := _page("THEY WANT YOU BACK", o.job.look, "delighted", "%s catches you at the truck: \"Could you come %s? $%d a visit.%s\"" % [o.job.customer, every, o.rate,
		" More often till August, mind: the grass is growing." if Game.cadence_now(o) < o.cadence else ""])
	var root: VBoxContainer = p[0]
	var face: Face = p[1]
	var said: Label = p[2]
	var asked := [roundi(o.rate * Game.HAGGLE / 5.0) * 5]
	var choices := UI.vbox(12)
	root.add_child(choices)
	var buttons := UI.hbox(12)
	var go := UI.button("Back to the board", func() -> void: get_tree().change_scene_to_file("res://board.tscn"), 24)
	go.name = "Continue"
	for b: Array in [["Accept", "accept", "Deal: $%d" % o.rate], ["Haggle", "haggle", "Ask for $%d" % asked[0]], ["Decline", "decline", "Sorry, I'm booked up"]]:
		var btn := UI.button(b[2], func() -> void:
			var reply := Game.answer_offer(b[1], asked[0])
			var rate: int = Game.regulars.get(o.id, o).rate
			said.text = {"yes": "\"Lovely. See you then.\" A regular: $%d %s." % [rate, every],
				"grudging": "\"...Fine. But it had better be good.\" $%d %s, and they're not pleased." % [rate, every],
				"walk": "\"At that price? Forget it.\" They're gone.",
				"no": "\"Shame. Well, you know where we are.\" Being asked does your name a little good."}[reply]
			face.expression = {"yes": "happy", "grudging": "annoyed", "walk": "furious", "no": "neutral"}[reply]
			choices.queue_free()
			root.add_child(go)
			UI.focus(go), 20)
		btn.name = b[0]
		buttons.add_child(btn)
	var ask_btn: Button = buttons.get_node("Haggle")
	var row := UI.hbox(14)
	row.add_child(UI.label("Ask for:", 22))
	row.add_child(UI.amount(o.rate + 5, roundi(o.rate * Game.ASK_MAX / 5.0) * 5, 5, asked[0], func(v: int) -> void:
		asked[0] = v
		ask_btn.text = "Ask for $%d" % v))
	choices.add_child(row)
	choices.add_child(buttons)
	UI.focus(buttons.get_node("Accept") as Control)


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
	if r.has("rep_cut"): # the gains above, cut by how known you are already (Game.climb)
		total += _shown(r.rep_cut)
		_line(box, "Most folk won't hear of it", "%+d" % _shown(r.rep_cut), UI.BAD)
	_line(box, "All told", "%+d" % total, UI.GOOD if total >= 0 else UI.BAD, 24)
	if r.has("rep_after"):
		var moved := roundi(r.rep_after - r.rep_before)
		var standing := "Word travels: your standing is %s" % UI.rep_word(r.rep_after)
		if total != moved: # it lags: this job's word, and earlier jobs', arrive over time
			standing += " (%+d for now: word takes time to travel)" % moved
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
	if r.has("left_behind"):
		also.append("Your %s's still on their lawn. The police have it now" % r.left_behind.to_lower())
	if r.get("lost_regular", false):
		also.append("They won't be booking you again")
	if r.has("owed_back") and r.owed_back > 0:
		also.append("You owe back $%d they paid up front" % r.owed_back)
	match r.get("terms", ""):
		"fewer":
			also.append("They'll have you less often now")
		"cheaper":
			also.append("They want it cheaper: $%d a visit" % Game.regulars.get(Game.current_job.get("regular", -1), {}).get("rate", 0))
	if not also.is_empty():
		info.add_child(UI.label("   ".join(also), 20, UI.BAD))
	var good: Array[String] = []
	if r.get("sooner", false):
		good.append("The grass is growing: they want you back sooner")
	match r.get("terms", ""):
		"more":
			good.append("Pleased: they want you more often")
		"better":
			good.append("Pleased: they've put you up to $%d" % Game.regulars.get(Game.current_job.get("regular", -1), {}).get("rate", 0))
	if Game.current_job.get("prepaid", false):
		good.append("Paid up front")
	if not good.is_empty():
		info.add_child(UI.label("   ".join(good), 20, UI.GOOD))
	for l: Label in info.get_children(): # long lines wrap, not shove the books off the screen
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 640
	var tally := Game.tally_lines(r.get("tally", {}), r.get("tally_cost", {}), r.get("records", []))
	if not tally.is_empty(): # everything the job counted, going by like a news ticker
		info.add_child(Ticker.new("   *   ".join(tally), 18, UI.GOLD, 640))
	return UI.panel(row)
