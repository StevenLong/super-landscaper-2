extends Control
## Between jobs: the job board (offers depend on reputation), the shop, and your
## van's mower rack. At each week's end, payday: the loan shark's man comes to collect.

var offers: Array[Dictionary] = []


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	if Game.run_over_reason == "arrested":
		_run_over("ARRESTED")
		return
	if Game.payday_due():
		_payday()
		return
	offers = Game.make_offers()
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := UI.vbox(16)
	margin.add_child(root)

	# Header: day, money, reputation.
	var head := UI.hbox(26)
	head.add_child(UI.label("Week %d, job %d of %d" % [Game.week, Game.job_of_week(), Game.JOBS_PER_WEEK], 30, UI.GOLD))
	head.add_child(UI.label("Owed Friday: $%d" % Game.payment(), 22, UI.BAD if Game.money < Game.payment() else UI.TEXT))
	head.add_child(UI.label("Money: $%d" % Game.money, 26))
	head.add_child(UI.label("Earned this run: $%d" % Game.total_earned, 22, UI.DIM))
	var trend := Game.rep_trend - Game.reputation
	var arrow := "  (rising)" if trend > 3.0 else ("  (sliding)" if trend < -3.0 else "")
	head.add_child(UI.label("Reputation: %s%s" % [UI.rep_word(Game.reputation), arrow], 22,
		UI.GOOD if Game.reputation >= 45.0 else (UI.GOLD if Game.reputation >= 20.0 else UI.BAD)))
	if Game.heat > 0.0:
		head.add_child(UI.label("WANTED " + "*".repeat(ceili(Game.heat)), 22, UI.BAD))
	root.add_child(head)

	var cols := UI.hbox(24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# Left: the job board.
	var jobs := UI.vbox(12)
	jobs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(jobs)
	if not Game.last_result.is_empty():
		jobs.add_child(_rundown(Game.last_result))
	jobs.add_child(UI.label("Classifieds: gardens & grounds", 26))
	var first: Control = null
	if Game.reputation <= 0.0:
		jobs.add_child(UI.label("Nobody decent's calling. Word has got around.", 22, UI.BAD))
	for o in offers:
		var card := _offer_card(o)
		jobs.add_child(card)
		if first == null:
			first = card.find_child("Take", true, false)

	# Right: shop and rack.
	var shop := UI.vbox(10)
	shop.custom_minimum_size = Vector2(430, 0)
	cols.add_child(shop)
	shop.add_child(UI.label("Your mowers", 30))
	for key: String in Game.MOWERS:
		shop.add_child(_mower_row(key))
	shop.add_child(UI.label("Upgrades", 30))
	for key: String in Game.UPGRADES:
		shop.add_child(_upgrade_row(key))
	if first:
		UI.focus(first)


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
		"ko": "Well, that happened"}.get(r.outcome, "Job done")
	info.add_child(UI.label("Last job: %s   %s" % [title, r.get("customer", "")], 22,
		UI.GOOD if r.outcome == "paid" else UI.BAD))
	info.add_child(UI.label(r.comment if r.outcome == "ko" else "\"%s\"" % r.comment, 18, UI.DIM))
	var money := "Paid $%d" % r.paid
	if r.tip > 0:
		money += " (incl. $%d tip)" % r.tip
	if r.fuel_cost > 0.0:
		money += "   Costs -$%d" % roundi(r.fuel_cost)
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
	info.add_child(UI.label(rep, 20, UI.GOOD if d >= 0.0 and r.outcome == "paid" else UI.BAD))
	var tally := Game.tally_lines(r.get("tally", {}), r.get("tally_cost", {}))
	if not tally.is_empty():
		var shown := tally.slice(0, 5) # the rest wait for the run's end, so the panel stays short
		if tally.size() > 5:
			shown.append("and %d more" % (tally.size() - 5))
		var t := UI.label("Also counted: " + ",  ".join(shown), 18, UI.GOLD)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size.x = 560
		info.add_child(t)
	return UI.panel(row)


## An offer as a classified ad on newsprint: no picture, just the words and the hints
## buried in them. You meet the customer at the briefing.
func _offer_card(o: Dictionary) -> Control:
	var row := UI.hbox(14)
	var ad := RichTextLabel.new()
	ad.bbcode_enabled = true
	ad.fit_content = true
	ad.scroll_active = false
	ad.custom_minimum_size.x = 540
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.add_theme_color_override("default_color", Color("2a2420"))
	ad.text = Game.ad_text(o)
	row.add_child(ad)
	var take := UI.button("Take", func() -> void: _take(o), 20)
	take.name = "Take"
	take.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(take)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e8e0c8")
	paper.border_color = Color("b8ac8c")
	paper.set_border_width_all(2)
	paper.set_content_margin_all(12)
	var p := UI.panel(row)
	p.add_theme_stylebox_override("panel", paper)
	return p


func _mower_row(key: String) -> Control:
	var m: Dictionary = Game.MOWERS[key]
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(m.name + ("  (in use)" if Game.equipped == key else ""), 20,
		UI.GOLD if Game.equipped == key else UI.TEXT))
	info.add_child(UI.label(m.blurb, 20, UI.DIM))
	row.add_child(info)
	if key in Game.owned:
		var use := UI.button("Use", func() -> void:
			Game.equipped = key
			_build(), 18)
		use.disabled = Game.equipped == key
		row.add_child(use)
		if key != "push":
			row.add_child(_sell_button(key, _build))
	else:
		var buy := UI.button("Buy $%d" % m.price, func() -> void:
			Game.buy(key)
			_build(), 18)
		buy.disabled = Game.money < m.price
		row.add_child(buy)
	return UI.panel(row)


func _upgrade_row(key: String) -> Control:
	var u: Dictionary = Game.UPGRADES[key]
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(u.name, 20))
	info.add_child(UI.label(u.blurb, 20, UI.DIM))
	row.add_child(info)
	if key in Game.upgrades:
		row.add_child(_sell_button(key, _build))
	else:
		var buy := UI.button("Buy $%d" % u.price, func() -> void:
			Game.buy(key)
			_build(), 18)
		buy.disabled = Game.money < u.price
		row.add_child(buy)
	return UI.panel(row)


## Playtest cheats, debug builds only: [1] adds $500, [2] adds 20 reputation (and
## redeals the offers, so bigger lawns show up). No function keys: the editor owns them.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (OS.is_debug_build() and event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_1:
		Game.money += 500
		_build()
	elif event.keycode == KEY_3: # skip to the week's end
		Game.jobs_done = Game.week * Game.JOBS_PER_WEEK
		_ready()
	elif event.keycode == KEY_2:
		Game.reputation = minf(100.0, Game.reputation + 20.0)
		Game.rep_trend = minf(100.0, Game.rep_trend + 20.0)
		offers = Game.make_offers()
		_build()


func _sell_button(key: String, then: Callable) -> Button:
	return UI.button("Sell $%d" % Game.resale(key), func() -> void:
		Game.sell(key)
		then.call(), 18)


func _take(o: Dictionary) -> void:
	Game.current_job = o
	get_tree().change_scene_to_file("res://main.tscn")


## A fresh screen with a centred column, for payday and the run's end.
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


func _centred(col: VBoxContainer, text: String, size: int, color := UI.TEXT) -> void:
	var lab := UI.label(text, size, color)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lab)


func _centred_button(col: VBoxContainer, text: String, on_press: Callable) -> Button:
	var holder := CenterContainer.new()
	var b := UI.button(text, on_press, 24)
	holder.add_child(b)
	col.add_child(holder)
	return b


## The week's end: the loan shark's man wants his money. Short, you can sell kit first
## (you choose what goes), or let his heavies take what they like.
func _payday() -> void:
	var col := _screen()
	var due := Game.payment()
	_centred(col, "FRIDAY. PAYDAY.", 56, UI.GOLD)
	_centred(col, "The shark's man is leaning on your van. Week %d: he wants $%d." % [Game.week, due], 24)
	_centred(col, "You have $%d." % Game.money, 26, UI.GOOD if Game.money >= due else UI.BAD)
	var go: Button
	if Game.money >= due:
		go = _centred_button(col, "Hand over $%d" % due, _collect)
	else:
		_centred(col, "Short by $%d. Sell something, or his heavies take what they like, your best first." % (due - Game.money), 20, UI.DIM)
		for k in Game.sellable():
			var name: String = Game.MOWERS[k].name if Game.MOWERS.has(k) else Game.UPGRADES[k].name
			var row := UI.hbox(12)
			row.add_child(UI.label(name, 20))
			row.add_child(_sell_button(k, _payday))
			var holder := CenterContainer.new()
			holder.add_child(row)
			col.add_child(holder)
		go = _centred_button(col, "Let them take it" if Game.sellable() else "Turn out your pockets", _collect)
	UI.focus(go)


func _collect() -> void:
	var r := Game.settle_payday()
	match r.outcome:
		"won":
			_run_over("SEASON WON")
		"bankrupt":
			_run_over("BANKRUPT")
		_:
			var col := _screen()
			_centred(col, "He counts it twice.", 40, UI.GOLD)
			if r.taken:
				var names: Array = r.taken.map(func(k: String) -> String:
					return Game.MOWERS[k].name if Game.MOWERS.has(k) else Game.UPGRADES[k].name)
				_centred(col, "His heavies load up your %s." % ", ".join(names), 24, UI.BAD)
			_centred(col, "\"See you next Friday. $%d.\"" % Game.payment(), 24)
			_centred(col, "You have $%d left." % Game.money, 22, UI.DIM)
			UI.focus(_centred_button(col, "Back to the classifieds", func() -> void:
				offers = Game.make_offers()
				_build()))


func _run_over(title: String) -> void:
	var col := _screen()
	var won := title == "SEASON WON"
	_centred(col, title, 64, UI.GOOD if won else UI.BAD)
	_centred(col, "The shark's paid off. See you next season." if won else "You made it to week %d." % Game.week, 26)
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
