extends Control
## Between jobs: the job board (offers depend on reputation), the shop, and your
## van's mower rack. At zero reputation the only thing left is bankruptcy.

var offers: Array[Dictionary] = []


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	if Game.run_over_reason == "arrested":
		_run_over("ARRESTED")
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
	var head := UI.hbox(40)
	head.add_child(UI.label("Day %d" % Game.day, 30, UI.GOLD))
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
	jobs.add_child(UI.label("Job board", 26))
	var first: Control = null
	if offers.is_empty():
		jobs.add_child(UI.label("Nobody's calling. Word has got around.", 22, UI.BAD))
		var b := UI.button("File for bankruptcy", func() -> void: _run_over("BANKRUPT"), 22)
		jobs.add_child(b)
		first = b
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
	return UI.panel(row)


func _offer_card(o: Dictionary) -> Control:
	var row := UI.hbox(14)
	var f := Face.new()
	f.pixel_scale = 2
	f.custom_minimum_size = Vector2(92, 92)
	f.set_look(o.look)
	f.expression = "neutral"
	row.add_child(f)
	var info := UI.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var size_word: String = ["Small", "Medium", "Large"][Game.LAWN_SIZES.find(o.size)]
	info.add_child(UI.label("%s   %s lawn   $%d" % [o.customer, size_word, o.pay], 22))
	info.add_child(UI.label("\"%s\"" % o.brief[0], 18, UI.DIM))
	var take := UI.button("Take job", func() -> void: _take(o), 20)
	take.name = "Take"
	info.add_child(take)
	return UI.panel(row)


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
		row.add_child(UI.label("Owned", 18, UI.GOOD))
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
	elif event.keycode == KEY_2:
		Game.reputation = minf(100.0, Game.reputation + 20.0)
		Game.rep_trend = minf(100.0, Game.rep_trend + 20.0)
		offers = Game.make_offers()
		_build()


func _take(o: Dictionary) -> void:
	Game.current_job = o
	get_tree().change_scene_to_file("res://main.tscn")


func _run_over(title: String) -> void:
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
	for l: Array in [[title, 64, UI.BAD], ["You lasted %d days." % Game.day, 26, UI.TEXT],
			["Total earned: $%d" % Game.total_earned, 30, UI.GOLD], ["Best ever: $%d" % Game.best_score, 22, UI.DIM]]:
		var lab := UI.label(l[0], l[1], l[2])
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lab)
	var holder := CenterContainer.new()
	var again := UI.button("Back to the title", func() -> void:
		Game.in_run = false
		get_tree().change_scene_to_file("res://title.tscn"), 24)
	holder.add_child(again)
	col.add_child(holder)
	UI.focus(again)
