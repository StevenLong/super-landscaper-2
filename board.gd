extends Control
## Between jobs (design doc, The Business): the month's calendar with today's job, the
## week's paper to ring, your regulars, the shop and your van's mower rack.
## Friday brings payday (the loan shark's man), September's end the winter, and a job
## you never finished the blackout.

var _call := "" ## what the last ad you rang said, shown by the paper


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	if not Game.blackout.is_empty():
		_blackout()
	elif Game.today().has("court"):
		_court()
	elif Game.payday_pending:
		_payday()
	elif Game.winter_pending:
		_winter()
	else:
		_build()


## Lay the board out. `keep`: the shop row you just bought or sold in, which keeps the
## cursor instead of it jumping back to the top.
func _build(keep := "") -> void:
	Game.save()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var root := UI.vbox(10)
	margin.add_child(root)

	# Header, two rows so it never runs off the side: the date and money, then your name.
	var head := UI.hbox(26)
	head.add_child(UI.label(Game.date_text(), 30, UI.GOLD))
	head.add_child(UI.label("Money: $%d" % Game.money, 26))
	head.add_child(UI.label("Friday: $%d" % Game.due(), 22, UI.BAD if Game.money < Game.due() else UI.TEXT))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	var leave := UI.button("Save and quit", _save_and_quit, 18) # the board's always saved: this just says so
	leave.name = "Quit"
	head.add_child(leave)
	root.add_child(head)
	head = UI.hbox(26)
	var trend := Game.rep_trend - Game.reputation
	var arrow := "  (rising)" if trend > 3.0 else ("  (sliding)" if trend < -3.0 else "")
	head.add_child(UI.label("Reputation: %s%s" % [UI.rep_word(Game.reputation), arrow], 22,
		UI.GOOD if Game.reputation >= 45.0 else (UI.GOLD if Game.reputation >= 20.0 else UI.BAD)))
	head.add_child(UI.label("Owed the shark: $%d" % Game.principal if Game.principal > 0 else "Free of the shark", 22,
		UI.DIM if Game.principal > 0 else UI.GOOD))
	if Game.record > 0.0:
		head.add_child(UI.label("Record: %d" % roundi(Game.record), 22, UI.BAD))
	root.add_child(head)

	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# Left: the calendar, today, and the paper.
	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(_month())
	var first := _today(left)
	var heading := UI.hbox(14)
	heading.add_child(UI.label("This week's paper" if not Game.paper.is_empty() else "Nothing else in this week's paper.", 22))
	if _call != "": # what the last one you rang said
		var said := UI.label(_call, 18, UI.GOLD)
		said.name = "Call"
		said.clip_text = true
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(said)
	left.add_child(heading)
	var ads := ScrollContainer.new() # a long paper scrolls, following the cursor
	ads.follow_focus = true
	ads.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ads.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(ads)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ads.add_child(list)
	var full := Game.week_left().all(func(d: int) -> bool: return Game.calendar.has(d))
	for o in Game.paper:
		list.add_child(_ad(o, full))
	# Following focus shows only the Ring button: show its whole ad, and from the last one
	# the stamped ads below it, which have no button to reach them by.
	var ringing := list.get_children().filter(func(p: Node) -> bool: return p.find_child("Ring", true, false) != null)
	for p: Control in ringing:
		var also: Control = list.get_child(-1) if p == ringing[-1] else p
		p.find_child("Ring", true, false).focus_entered.connect(func() -> void:
			ads.ensure_control_visible.call_deferred(p)
			ads.ensure_control_visible.call_deferred(also))

	# Right: your regulars, then the shop and rack.
	var scroll := ScrollContainer.new() # a long list of regulars scrolls, following the cursor
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(scroll)
	var shop := UI.vbox(6)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(shop)
	if not Game.regulars.is_empty():
		shop.add_child(UI.label("Your regulars", 26))
		for id: int in Game.regulars:
			shop.add_child(_regular_row(id))
	shop.add_child(UI.label("Your mowers", 26))
	for key: String in Game.MOWERS:
		shop.add_child(_mower_row(key))
	shop.add_child(UI.label("Upgrades", 26))
	for key: String in Game.UPGRADES:
		shop.add_child(_upgrade_row(key))
	shop.add_child(_robot_row())
	for l: Label in shop.find_children("*", "Label", true, false): # wrap, so no row's words widen the column off the screen
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var kept := find_child(keep, true, false) if keep != "" else null
	if kept:
		for b: Button in kept.find_children("*", "Button", true, false):
			if not b.disabled:
				first = b
				break
	UI.focus(first)


## The month as a grid, Monday first: what's booked each day, today ringed, Fridays gold.
func _month() -> Control:
	var t := Game.date()
	var first := Game.day_of(t.year, t.month, 1)
	var last := Game.day_of(t.year + (1 if t.month == 12 else 0), t.month % 12 + 1, 1) - 1
	var box := UI.vbox(2)
	box.add_child(UI.label("%s %d" % [Game.MONTHS[t.month - 1], t.year], 22, UI.GOLD))
	var grid := GridContainer.new()
	grid.name = "Calendar"
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	box.add_child(grid)
	for n: String in ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]:
		grid.add_child(UI.label(n, 16, UI.GOLD if n == "Fri" else UI.DIM))
	for i in (Game.date(first).weekday + 6) % 7: # blanks before the 1st
		grid.add_child(Control.new())
	for d in range(first, last + 1):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(90, 30)
		var style := StyleBoxFlat.new()
		style.bg_color = UI.PANEL if d >= Game.day else UI.BG
		style.border_color = UI.GOLD if d == Game.day else UI.PANEL_EDGE
		style.set_border_width_all(2 if d == Game.day else (1 if d >= Game.day else 0))
		style.set_content_margin_all(3)
		cell.add_theme_stylebox_override("panel", style)
		var b: Dictionary = Game.calendar.get(d, {})
		var what := ""
		var color := UI.DIM
		if b.has("court") or b.has("jail") or b.has("service"):
			what = "Court" if b.has("court") else ("Jail" if b.has("jail") else "Duty") # community service
			color = UI.BAD
		elif b.has("seed"):
			what = b.customer.split(" ")[-1]
			color = UI.GOOD if b.has("regular") else UI.TEXT
		var l := UI.label("%d %s" % [Game.date(d).day, what], 16, color if d >= Game.day else UI.DIM)
		l.clip_text = true # a long surname never widens the grid
		cell.add_child(l)
		grid.add_child(cell)
	return box


## Today: the job to go to, or nothing booked and on to the next. Returns the button.
func _today(box: Control) -> Button:
	var j := Game.today()
	var row := UI.hbox(14)
	var go: Button
	if j.has("seed"):
		var what := RichTextLabel.new()
		what.bbcode_enabled = true
		what.fit_content = true
		what.scroll_active = false
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		what.text = ("Today: [color=#98e070]%s[/color], your regular. $%d, no tips." % [j.customer, j.pay]) if j.has("regular") \
			else ("Today: community service, [color=#f07060]%s[/color]'s churchyard. Unpaid." % j.customer) if j.has("service") \
			else "Today: [color=#f8d048]%s[/color], from the paper. $%d." % [j.customer, j.pay]
		row.add_child(what)
		go = UI.button("Go", _go, 22)
	else:
		var l := UI.label("Nothing booked today." if j.is_empty() else "A day in jail.", 20, UI.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		go = UI.button("On to the next job", func() -> void:
			Game.skip()
			_ready(), 20)
	go.name = "Today"
	row.add_child(go)
	box.add_child(UI.panel(row))
	return go


## An ad as a classified on newsprint: no picture, just the words and the hints buried
## in them. You meet the customer at the briefing. Ringing gets an answer at once
## (Game.ring): yes books the week's first free day, no stamps the ad.
func _ad(o: Dictionary, full: bool) -> Control:
	var row := UI.hbox(14)
	var ad := RichTextLabel.new()
	ad.bbcode_enabled = true
	ad.fit_content = true
	ad.scroll_active = false
	ad.custom_minimum_size.x = 540
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.add_theme_color_override("default_color", Color("2a2420"))
	ad.add_theme_font_size_override("normal_font_size", UI.px(18))
	ad.text = Game.ad_text(o)
	row.add_child(ad)
	if o.get("refused", false): # stamped for the week, what's above you kept in view
		ad.text += "\n[color=#b03020]NO: %s[/color]" % o.reply
		ad.modulate.a = 0.7
	else:
		var ring := UI.button("Ring", func() -> void:
			_call = Game.ring(o)
			_build(), 20)
		ring.name = "Ring"
		ring.disabled = full
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ring)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e8e0c8")
	paper.border_color = Color("b8ac8c")
	paper.set_border_width_all(2)
	paper.set_content_margin_all(8)
	var p := UI.panel(row)
	p.add_theme_stylebox_override("panel", paper)
	return p


func _regular_row(id: int) -> Control:
	var reg: Dictionary = Game.regulars[id]
	var row := UI.hbox(10)
	var every: String = {7: "weekly", 14: "fortnightly", 28: "four-weekly"}[reg.cadence]
	var l := UI.label("%s, %s, $%d" % [reg.job.customer, every, reg.rate], 18, UI.GOOD)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(UI.button("Drop", func() -> void:
		Game.drop(id)
		_build(), 18))
	return UI.panel(row)


func _mower_row(key: String) -> Control:
	var m: Dictionary = Game.MOWERS[key]
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var on_truck := key == "push" or Game.packed_has(key)
	info.add_child(UI.label(m.name + ("  (packed)" if on_truck and key in Game.owned else ""), 20,
		UI.GOLD if on_truck and key in Game.owned else UI.TEXT))
	info.add_child(UI.label(m.blurb, 18, UI.DIM))
	row.add_child(info)
	if key in Game.owned:
		if key != "push":
			row.add_child(_sell_button(key, _build.bind(key)))
	else:
		var buy := UI.button("Buy $%d" % m.price, func() -> void:
			Game.buy(key)
			_build(key), 18)
		buy.disabled = Game.money < m.price
		row.add_child(buy)
	var p := UI.panel(row)
	p.name = key # _build(key) finds the row again
	return p


## Robot mowers: as many as you like.
func _robot_row() -> Control:
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(Game.ROBOT.name + ("  (you have %d)" % Game.robots if Game.robots > 0 else ""), 20))
	info.add_child(UI.label(Game.ROBOT.blurb, 18, UI.DIM))
	row.add_child(info)
	if Game.robots > 0:
		row.add_child(_sell_button("robot", _build.bind("robot")))
	var buy := UI.button("Buy $%d" % Game.ROBOT.price, func() -> void:
		Game.buy("robot")
		_build("robot"), 18)
	buy.disabled = Game.money < Game.ROBOT.price
	row.add_child(buy)
	var p := UI.panel(row)
	p.name = "robot" # _build("robot") finds the row again
	return p


func _upgrade_row(key: String) -> Control:
	var u: Dictionary = Game.UPGRADES[key]
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(u.name, 20))
	info.add_child(UI.label(u.blurb, 18, UI.DIM))
	row.add_child(info)
	if key in Game.upgrades:
		row.add_child(_sell_button(key, _build.bind(key)))
	else:
		var buy := UI.button("Buy $%d" % u.price, func() -> void:
			Game.buy(key)
			_build(key), 18)
		buy.disabled = Game.money < u.price
		row.add_child(buy)
	var p := UI.panel(row)
	p.name = key # _build(key) finds the row again
	return p


func _save_and_quit() -> void:
	Game.save()
	Game.in_run = false
	get_tree().change_scene_to_file("res://title.tscn")


## Pause (Esc, Start) on the board goes to Save and quit.
func _unhandled_input(event: InputEvent) -> void:
	var leave := find_child("Quit", true, false) as Button
	if leave and event.is_action_pressed("pause"):
		UI.focus(leave)
		get_viewport().set_input_as_handled()


## Playtest cheats, debug builds only: [1] adds $500, [2] adds 20 reputation and [4]
## takes 20 off (both reprint the paper), [3] skips to payday. No function keys: the editor owns them.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (OS.is_debug_build() and event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_1:
		Game.money += 500
		_build()
	elif event.keycode == KEY_3: # skip to payday
		while not Game.payday_pending and not Game.winter_pending:
			Game.end_day()
		_ready()
	elif event.keycode == KEY_4: # down the ladder, for the churchyard
		Game.reputation = maxf(1.0, Game.reputation - 20.0)
		Game.rep_trend = maxf(1.0, Game.rep_trend - 20.0)
		Game.paper = Game.make_paper()
		_build()
	elif event.keycode == KEY_2:
		Game.reputation = minf(100.0, Game.reputation + 20.0)
		Game.rep_trend = minf(100.0, Game.rep_trend + 20.0)
		Game.paper = Game.make_paper()
		_build()


func _sell_button(key: String, then: Callable) -> Button:
	return UI.button("Sell $%d" % Game.resale(key), func() -> void:
		Game.sell(key)
		then.call(), 18)


func _go() -> void: # packing first (pack.gd), then the job
	get_tree().change_scene_to_file("res://pack.tscn")


## A fresh screen with a centred column, for payday, the winter and the business's end.
func _screen() -> VBoxContainer:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := UI.vbox(14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	return col


func _centred(col: VBoxContainer, text: String, font_size: int, color := UI.TEXT) -> void:
	var lab := UI.label(text, font_size, color)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lab)


func _centred_button(col: VBoxContainer, text: String, on_press: Callable) -> Button:
	var holder := CenterContainer.new()
	var b := UI.button(text, on_press, 24)
	holder.add_child(b)
	col.add_child(holder)
	return b


## Friday: the vig on what you owe and your keep for the week. Pay more and the debt
## shrinks. Short, you can sell kit first (you choose what goes), or let his heavies take
## what they like.
func _payday() -> void:
	var col := _screen()
	var due := Game.due()
	_centred(col, "FRIDAY. PAYDAY.", 56, UI.GOLD)
	if Game.principal > 0:
		_centred(col, "The shark's man is leaning on your van. The vig: $%d on the $%d you owe." % [Game.vig(), Game.principal], 24)
	else:
		_centred(col, "No shark's man this week. You're free of him.", 24, UI.GOOD)
	_centred(col, "Rent and food: $%d. You have $%d." % [Game.LIVING, Game.money], 26, UI.GOOD if Game.money >= due else UI.BAD)
	var go: Button
	if Game.money >= due:
		# Pick what comes off the debt; the sum says what the payment does. The vig is
		# only interest: nothing but the extra comes off what you owe.
		var spare := mini(Game.money - due, Game.principal)
		var holder := CenterContainer.new()
		if spare > 0:
			_centred(col, "Off the debt:", 22)
			col.add_child(holder)
		var sums := UI.label("", 22)
		sums.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(sums)
		var extra := [0]
		go = _centred_button(col, "", func() -> void: _collect(extra[0]))
		go.name = "Pay"
		var pay := go
		var tell := func(off: int) -> void:
			extra[0] = off
			pay.text = "Hand over $%d" % (due + off)
			sums.text = ("$%d interest + $%d rent and food + $%d off the debt. Owed after: $%d." % [Game.vig(), Game.LIVING, off, Game.principal - off]) 				if Game.principal > 0 else "$%d rent and food." % Game.LIVING
		if spare > 0:
			holder.add_child(UI.amount(0, spare, maxi(5, roundi(spare / 40.0 / 5.0) * 5), 0, tell))
		tell.call(0)
	else:
		_centred(col, "Short by $%d. Sell something, or his heavies take what they like, your best first." % (due - Game.money), 20, UI.DIM)
		for k in Game.sellable():
			var kit: String = Game.kit_name(k)
			var row := UI.hbox(12)
			row.add_child(UI.label(kit, 20))
			row.add_child(_sell_button(k, _payday))
			var holder := CenterContainer.new()
			holder.add_child(row)
			col.add_child(holder)
		go = _centred_button(col, "Let them take it" if Game.sellable() else "Turn out your pockets", _collect.bind(0))
	UI.focus(go)


func _collect(extra: int) -> void:
	var r := Game.settle_payday(extra)
	if r.outcome == "bankrupt":
		_run_over()
		return
	var col := _screen()
	_centred(col, "He counts it twice." if r.paid > Game.LIVING else "Paid up.", 40, UI.GOLD)
	if r.taken:
		var names: Array = r.taken.map(func(k: String) -> String:
			return Game.kit_name(k))
		_centred(col, "His heavies load up your %s." % ", ".join(names), 24, UI.BAD)
	if r.outcome == "free":
		_centred(col, "PAID OFF. You're free of him.", 32, UI.GOOD)
	elif r.off > 0:
		_centred(col, "$%d off the debt. You still owe $%d." % [r.off, Game.principal], 24, UI.GOOD)
	if Game.principal > 0:
		_centred(col, "\"See you next Friday. $%d.\"" % Game.vig(), 24)
	_centred(col, "You have $%d left." % Game.money, 22, UI.DIM)
	UI.focus(_centred_button(col, "Read the paper", _ready))


## September's done: the winter in one ledger (Game.settle_winter), then April.
func _winter() -> void:
	var w := Game.settle_winter()
	var col := _screen()
	_centred(col, "WINTER", 64, UI.GOLD)
	_centred(col, "October to March: rent and food, $%d." % w.cost, 26)
	if w.topped > 0:
		_centred(col, "Short, so the shark tops you up: $%d more on what you owe ($%d)." % [w.topped, Game.principal], 22, UI.BAD)
	if not w.back.is_empty():
		_centred(col, "Back in April: " + ", ".join(w.back), 22, UI.GOOD)
	if not w.gone.is_empty():
		_centred(col, "Not coming back: " + ", ".join(w.gone), 22, UI.BAD)
	_centred(col, "You have $%d. Reputation: %s." % [Game.money, UI.rep_word(Game.reputation)], 22, UI.DIM)
	UI.focus(_centred_button(col, "Spring, %d" % Game.year, _build))


## Court (design doc, The Business: the record): the charge, then a lawyer or yourself,
## each a better chance to walk free for money. Deliberately shallow.
func _court() -> void:
	var case: Dictionary = Game.today().court
	var col := _screen()
	_centred(col, "COURT", 64, UI.GOLD)
	_centred(col, "%s. The charge: what happened at %s's." % [Game.date_text(), case.customer], 24)
	_centred(col, ("Caught at the scene." if case.caught else "Summoned: you got away, this time.") +
		("  Your record: %d." % roundi(Game.record) if Game.record > 0.0 else "  A first offence."), 22, UI.DIM)
	_centred(col, "You have $%d." % Game.money, 22)
	var first: Button = null
	for i in Game.LAWYERS.size():
		var l: Array = Game.LAWYERS[i]
		var b := _centred_button(col, "%s%s: %s" % [l[0], " ($%d)" % l[1] if l[1] > 0 else "", l[3]], _verdict.bind(i))
		b.disabled = Game.money < l[1]
		if first == null:
			first = b
	UI.focus(first)


func _verdict(lawyer: int) -> void:
	var v := Game.court(lawyer)
	var col := _screen()
	if v.walked:
		_centred(col, "NOT GUILTY", 64, UI.GOOD)
		_centred(col, "You walk free." + (" $%d well spent." % v.fee if v.fee > 0 else ""), 26)
	elif v.prison:
		_centred(col, "PRISON", 64, UI.BAD)
		_centred(col, "Your record's caught up with you. The business is done, %s." % Game.date_text(), 26)
		_centred(col, "Total earned: $%d" % Game.total_earned, 30, UI.GOLD)
		UI.focus(_centred_button(col, "Back to the title", func() -> void:
			Game.in_run = false
			get_tree().change_scene_to_file("res://title.tscn")))
		return
	else:
		_centred(col, "GUILTY", 64, UI.BAD)
		_centred(col, "Fined $%d. Your record: %d." % [v.fine, roundi(Game.record)], 26)
		if v.jail > 0:
			_centred(col, "%d day%s in jail, starting now." % [v.jail, "" if v.jail == 1 else "s"], 26, UI.BAD)
		if v.service > 0:
			_centred(col, "%d day%s of community service, on your next free day%s." % [v.service, "" if v.service == 1 else "s",
				"" if v.service == 1 else "s"], 26, UI.GOLD)
		if v.jail == 0 and v.service == 0:
			_centred(col, "And no more than that. This time.", 22, UI.DIM)
	_centred(col, "You have $%d." % Game.money, 22, UI.DIM)
	UI.focus(_centred_button(col, "Carry on", _ready))


## A job started and never finished (quit, or a crash): you blacked out. Ironman.
func _blackout() -> void:
	var j: Dictionary = Game.blackout
	Game.blackout = {}
	var col := _screen()
	_centred(col, "YOU BLACKED OUT", 56, UI.BAD)
	_centred(col, "You come to at home. Of %s's garden, you remember nothing." % j.get("customer", "someone"), 24)
	_centred(col, "A note through the door: \"Don't bother coming back.\"", 24, UI.DIM)
	_centred(col, "The job's lost, and word gets round.", 22, UI.BAD)
	UI.focus(_centred_button(col, "Carry on", _ready))


## The shark's lost patience: the business is over.
func _run_over() -> void:
	var col := _screen()
	_centred(col, "BANKRUPT", 64, UI.BAD)
	_centred(col, "The shark's lost patience. The business is done, %s." % Game.date_text(), 26)
	_centred(col, "Total earned: $%d" % Game.total_earned, 30, UI.GOLD)
	_centred(col, "Best ever: $%d" % Game.best_score, 22, UI.DIM)
	var tally := Game.tally_lines(Game.run_tally, Game.run_tally_cost)
	if not tally.is_empty():
		col.add_child(Control.new())
		_centred(col, "The tally", 22, UI.GOLD)
		var grid := GridContainer.new() # two columns once it's long, so it fits the screen
		grid.columns = 2 if tally.size() > 6 else 1
		grid.add_theme_constant_override("h_separation", 40)
		var centre := CenterContainer.new()
		centre.add_child(grid)
		col.add_child(centre)
		for line in tally:
			grid.add_child(UI.label(line, 20))
	UI.focus(_centred_button(col, "Back to the title", func() -> void:
		Game.in_run = false
		get_tree().change_scene_to_file("res://title.tscn")))
