extends Control
## The desk in the office (design doc, The hub): the paper things. Three pages: the
## calendar (five weeks of tiles, a day open beside them, who goes to each booking), the
## week's paper to ring, and the client book. Step away and you're in the office (hub.gd),
## where the yard and the shop are. The desk also has what's waiting to be read: the
## day's end, Friday's payday (the loan shark's man), court, September's end the winter,
## and a job you never finished, the blackout.

const VIEWS := ["calendar", "paper", "book"]
const PER_PAGE := 3 ## ads to a page of the paper
const CORK := Color("8a6238")
const NOTE := Color("efe6cc")
const INK := Color("2a2420")
const CREW := Color("2a4a8a") ## a booking sent to a helper, on the corkboard

var _call := "" ## what the last ad you rang said, shown by the paper
var _view := "calendar"
var _page := 0 ## the paper's page
var _open_day := -1 ## the day open beside the calendar (today by default)


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	if not Game.blackout.is_empty():
		_blackout()
	elif not Game.day_end.is_empty():
		_day_end()
	elif Game.today().has("court"):
		_court()
	elif Game.payday_pending:
		_payday()
	elif Game.winter_pending:
		_winter()
	else:
		_build()


## Lay the desk out. `keep`: what you just changed (a booking's card), which keeps the
## cursor there instead of it jumping back to the top.
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
	var root := UI.vbox(8)
	margin.add_child(root)

	# Header, two rows so it never runs off the side: the day, the time and money, then your name.
	var head := UI.hbox(26)
	head.add_child(UI.label(Game.date_text(), 30, UI.GOLD))
	var now := UI.label(Game.time_text(Game.minute), 30, UI.BAD if Game.minute >= Game.DAY_END else UI.TEXT)
	now.name = "Now"
	head.add_child(now)
	head.add_child(UI.label("$%d" % Game.money, 26))
	head.add_child(UI.label("Friday: $%d" % Game.due(), 20, UI.BAD if Game.money < Game.due() else UI.DIM))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	var away := UI.button("Step away %s" % Game.key("hop"), _away, 18)
	away.name = "Away"
	head.add_child(away)
	var leave := UI.button("Save and quit", _save_and_quit, 18) # the board's always saved: this just says so
	leave.name = "Quit"
	head.add_child(leave)
	root.add_child(head)
	head = UI.hbox(26)
	var trend := Game.rep_trend - Game.reputation
	var arrow := "  (rising)" if trend > 3.0 else ("  (sliding)" if trend < -3.0 else "")
	head.add_child(UI.label("Reputation: %s%s" % [UI.rep_word(Game.reputation), arrow], 20,
		UI.GOOD if Game.reputation >= 45.0 else (UI.GOLD if Game.reputation >= 20.0 else UI.BAD)))
	head.add_child(UI.label("Owed the shark: $%d" % Game.principal if Game.principal > 0 else "Free of the shark", 20,
		UI.DIM if Game.principal > 0 else UI.GOOD))
	if Game.record > 0.0:
		head.add_child(UI.label("Record: %d" % roundi(Game.record), 20, UI.BAD))
	root.add_child(head)

	# The pages, as tabs: Shift and Ctrl (RB and LB) turn them too.
	var tabs := UI.hbox(10)
	for v: String in VIEWS:
		var open := Game.paper.filter(func(o: Dictionary) -> bool: return Game.cant_book(o) == "" and not o.get("refused", false)).size()
		if Game.cant_hire() == "":
			open += Game.wanted.size()
		var t := UI.button({"calendar": "Calendar", "paper": "Paper (%d to ring)" % open, "shop": "Shop",
			"book": "Client book" + (" (%d)" % Game.regulars.size() if Game.regulars else "")}[v], _show.bind(v), 20)
		t.name = "Tab_" + v
		if v == _view:
			t.add_theme_color_override("font_color", UI.GOLD)
			t.add_theme_color_override("font_focus_color", UI.GOLD)
		tabs.add_child(t)
	var hint := UI.label("%s %s turn the page" % [Game.key("gear_down"), Game.key("gear_up")], 18, UI.DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(hint)
	root.add_child(tabs)

	var first: Control
	match _view:
		"paper":
			first = _paper_view(root)
		"book":
			first = _book_view(root)
		_:
			first = _calendar(root, keep)
	UI.focus(first)


func _show(view: String) -> void:
	_view = view
	_page = 0
	_build()
	UI.focus(find_child("Tab_" + view, true, false))


## Light up on the clock what pressing this would use: from now to `to`.
## The calendar (design doc, The hub): five rolling weeks from this Monday, a tile for
## every day. The tile under the cursor opens in the panel beside it (today's to start);
## pressing one steps into its panel. There each job says how it stands, in words and
## colour, and who's going. Returns the button to focus.
func _calendar(root: Control, keep := "") -> Control:
	if _open_day < Game.day:
		_open_day = Game.day
	var cols := UI.hbox(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	var grid := GridContainer.new()
	grid.name = "Calendar"
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	var monday: int = Game.day - (Game.date().weekday + 6) % 7
	for i in 7:
		var wd: int = (i + 1) % 7
		grid.add_child(_ink(Game.DAYS[wd].left(3) + (" payday" if wd == Game.FRIDAY else ""),
			Color("f8e0a0") if wd == Game.FRIDAY else Color("e8d8b8")))
	for d in range(monday, monday + 35):
		grid.add_child(_tile(d))
	var board := PanelContainer.new()
	var cork := StyleBoxFlat.new()
	cork.bg_color = CORK
	cork.border_color = Color("5a3c20")
	cork.set_border_width_all(4)
	cork.set_content_margin_all(8)
	board.add_theme_stylebox_override("panel", cork)
	board.add_child(grid)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(board)
	var side := ScrollContainer.new() # a busy day scrolls, following the cursor
	side.name = "DayScroll"
	side.follow_focus = true
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.custom_minimum_size.x = 440
	cols.add_child(side)
	var panel := UI.vbox(8)
	panel.name = "DayPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(panel)
	_fill_day(panel)
	var kept := find_child(keep, true, false) if keep != "" else null
	if kept:
		for b: Button in kept.find_children("*", "Button", true, false):
			if not b.disabled:
				return b
	if _open_day == Game.day:
		return find_child("EndDay", true, false)
	return find_child("Tile_%d" % _open_day, true, false)


## A day's tile on the corkboard: its date and what's on (a helper's name on what's
## theirs). Today ringed; days gone, faded and out of reach.
func _tile(d: int) -> Control:
	var t := Game.date(d)
	var b := Button.new()
	b.name = "Tile_%d" % d
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = NOTE.darkened(0.35) if d < Game.day else (NOTE.lightened(0.4) if state == "focus" or state == "hover" else NOTE)
		style.border_color = Color("f0b020") if state == "focus" else (Color("c08a10") if d == Game.day else Color("5a3c20"))
		style.set_border_width_all(4 if state == "focus" else (3 if d == Game.day else 1))
		style.set_content_margin_all(4)
		b.add_theme_stylebox_override(state, style)
	var notes := UI.vbox(0)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notes.set_anchors_preset(Control.PRESET_FULL_RECT)
	notes.offset_left = 4
	notes.offset_top = 2
	b.add_child(notes)
	notes.add_child(_ink("%d%s" % [t.day, " " + Game.MONTHS[t.month - 1].left(3) if t.day == 1 or d == Game.day else ""], Color("7a6a50")))
	var l := Game.bookings(d)
	for i in mini(l.size(), 2 if l.size() > 3 else 3):
		var bk: Dictionary = l[i]
		var text := "Court" if bk.has("court") else ("Jail" if bk.has("jail") else ("%s %s" % [_hours(bk.from), "Duty" if bk.has("service") else bk.customer.split(" ")[-1]]))
		if bk.has("helper"): # sent out: whose it is
			text = Game.helper(bk.helper).get("name", "?").split(" ")[0] + ": " + bk.customer.split(" ")[-1]
		notes.add_child(_ink(text, Color("b03020") if bk.has("court") or bk.has("jail") or bk.has("service") else (CREW if bk.has("helper") else (Color("2e6a1e") if bk.has("regular") else INK))))
	if l.size() > 3:
		notes.add_child(_ink("+%d more" % (l.size() - 2), Color("7a6a50")))
	for c: Control in notes.find_children("*", "Label", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if d < Game.day: # gone: still reachable, as a disabled button is on the board
		b.disabled = true
	else:
		b.focus_entered.connect(_open.bind(d))
		b.pressed.connect(func() -> void:
			var first := _panel_first()
			if first:
				first.grab_focus())
	return b


## Open a day beside the calendar.
func _open(d: int) -> void:
	if d == _open_day and find_child("DayPanel", true, false).get_child_count() > 0:
		return
	_open_day = d
	var panel := find_child("DayPanel", true, false)
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	_fill_day(panel)


## The first button in the open day's panel, or null.
func _panel_first() -> Button:
	for b: Button in find_child("DayPanel", true, false).find_children("*", "Button", true, false):
		if not b.disabled:
			return b
	return null


## The open day: each booking, how it stands and who's going; today, going and calling it a day.
func _fill_day(panel: Control) -> void:
	var d := _open_day
	var t := Game.date(d)
	panel.add_child(UI.label("%s, %d %s" % [Game.day_word(d) if d <= Game.day + 1 else Game.DAYS[t.weekday], t.day, Game.MONTHS[t.month - 1]], 24, UI.GOLD))
	if t.weekday == Game.FRIDAY:
		panel.add_child(UI.label("Payday: the shark's man, rent and food%s." % (", wages" if Game.helpers else ""), 18, UI.DIM))
	var l := Game.bookings(d)
	var mine := Game.jobs_today() if d == Game.day else []
	if not mine.is_empty():
		var go := UI.label("Your truck's in the yard: step away from the desk to go.", 18, UI.DIM)
		go.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(go)
	for b: Dictionary in l:
		if b.has("jail"):
			panel.add_child(UI.label("A day in jail.", 20, UI.BAD))
		elif b.has("court"):
			panel.add_child(UI.label("Court: what happened at %s's." % b.court.customer, 20, UI.BAD))
		else:
			panel.add_child(_job_card(b))
	if l.is_empty():
		panel.add_child(UI.label("Nothing booked.", 20, UI.DIM))
	if d == Game.day:
		# Every day ends on its own day's end, worked or not (the hub grill): nothing skips.
		var end := UI.button("Call it a day" + (" (miss %d)" % mine.size() if mine else ""), func() -> void:
			Game.end_day()
			_open_day = -1
			_ready(), 20)
		end.name = "EndDay"
		panel.add_child(end)
	if not panel.is_inside_tree():
		return
	for b: Button in panel.find_children("*", "Button", true, false): # left from the panel, back to its tile
		b.focus_neighbor_left = b.get_path_to(find_child("Tile_%d" % d, true, false))


## A booking in the open day: who, when and the pay; how it stands now (today); a regular
## who wants you; who's going (pick from the crew). Going yourself is the truck's, in the yard.
func _job_card(b: Dictionary) -> Control:
	var box := UI.vbox(4)
	var line := UI.label(b.customer + _job_line(b), 18, UI.BAD if b.has("service") else (UI.GOOD if b.has("regular") else UI.GOLD))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(line)
	if _open_day == Game.day:
		var st := _state(b)
		var l := UI.label(st[0], 20, st[1])
		l.name = "State"
		box.add_child(l)
	if Game.wants_you(b) > 0.0:
		var w := UI.label("Wants you: a helper starts them sour.", 18, UI.DIM)
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(w)
	var row := UI.hbox(10)
	if not Game.helpers.is_empty() and (Game.can_send(b) or b.has("helper")):
		var who: Dictionary = Game.helper(b.get("helper", -1))
		var pick := UI.button("Going: " + ("you" if who.is_empty() else who.name.split(" ")[0]), func() -> void: pass, 18)
		pick.name = "Who"
		pick.pressed.connect(_pick_who.bind(b, pick))
		row.add_child(pick)
	if row.get_child_count() > 0:
		box.add_child(row)
	var p := UI.panel(box)
	p.name = "job_%d_%d" % [_open_day, b.get("seed", 0)]
	return p


## How a booking today stands, in words and a colour (the board's clock, NOTES 224).
func _state(b: Dictionary) -> Array:
	if b.has("helper"):
		return ["%s's going." % Game.helper(b.helper).get("name", "?").split(" ")[0], CREW.lightened(0.5)]
	if not Game.can_go(b):
		return ["Missed: too late to get there.", UI.BAD]
	if Game.minute + Game.DRIVE < b.from:
		return ["Opens at %s." % Game.time_text(b.from), UI.TEXT]
	var left: int = b.by - Game.arrival(b)
	if left * 2 < b.by - b.from:
		return ["You'd get there late: %s left." % _span(left), UI.GOLD]
	return ["Open now: %s left." % _span(b.by - Game.minute), UI.GOOD]


## Minutes as a span: 40 min, 3h, 2h 30m.
func _span(m: int) -> String:
	if m < 60:
		return "%d min" % m
	return "%dh%s" % [floori(m / 60.0), " %dm" % (m % 60) if m % 60 else ""]


## Who goes to a booking: you, or one of the crew, each with how good, their kit and what
## else they've got that day.
func _pick_who(b: Dictionary, from: Button) -> void:
	var pop := PopupMenu.new()
	pop.name = "WhoMenu"
	pop.theme = theme
	pop.add_theme_font_size_override("font_size", UI.px(20))
	pop.add_item("You", 0)
	for i in Game.helpers.size():
		var h: Dictionary = Game.helpers[i]
		var others := Game.bookings(_open_day).filter(func(x: Dictionary) -> bool: return x.get("helper", -1) == h.id and x != b).size()
		pop.add_item("%s: %s, %s%s" % [h.name, Game.card_text(h), Game.MOWERS[h.kit].name.to_lower(),
			", %d more that day" % others if others else ", free that day"], i + 1)
	pop.id_pressed.connect(func(id: int) -> void:
		Game.assign(b, -1 if id == 0 else Game.helpers[id - 1].id)
		_build("job_%d_%d" % [_open_day, b.get("seed", 0)]))
	pop.popup_hide.connect(pop.queue_free)
	add_child(pop)
	pop.popup(Rect2i(Vector2i(from.get_global_rect().position + Vector2(0, from.size.y)), Vector2i.ZERO))
	pop.set_focused_item(maxi(0, Game.helpers.find(Game.helper(b.get("helper", -1))) + 1)) # the cursor on who's going now


## What a job is, after the customer's name.
func _job_line(b: Dictionary) -> String:
	var when := "%s to %s" % [Game.time_text(b.from), Game.time_text(b.by)]
	if b.has("regular"):
		return ", your regular, %s. %s" % [when, "Paid up front." if Game.regulars.get(b.regular, {}).get("prepaid", 0) > 0 else "$%d, no tips." % b.pay]
	if b.has("service"):
		return "'s churchyard, %s. Community service, unpaid." % when
	return ", from the paper, %s. $%d." % [when, b.pay]


## A time as short as it'll go, for a calendar note: 9, 9:30, 12.
func _hours(m: int) -> String:
	var h := (floori(m / 60.0) + 11) % 12 + 1
	return str(h) if m % 60 == 0 else "%d:%02d" % [h, m % 60]


## A line in ink on paper: no drop shadow, clipped so a long name never widens the board.
func _ink(text: String, color := INK, font_size := 20) -> Label:
	var l := UI.label(text, font_size, color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.clip_text = true
	return l


## The week's paper, a few ads to a page, and your regulars beside it. Returns the first
## Ring button (or a page button).
func _paper_view(root: Control) -> Control:
	var col := UI.vbox(8)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	if _call != "": # what the last one you rang said
		var said := UI.label(_call, 18, UI.GOLD)
		said.name = "Call"
		said.clip_text = true
		col.add_child(said)
	var ads := _paper_ads()
	var pages := _paper_pages()
	_page = clampi(_page, 0, pages - 1)
	if _page == 0:
		col.add_child(_front_page(ads))
	else:
		var page := UI.vbox(8)
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.add_child(_ink("CLASSIFIEDS" if ads.slice((_page - 1) * PER_PAGE).any(func(o: Dictionary) -> bool: return not o.has("care")) else "SITUATIONS WANTED", INK, 30))
		for o: Dictionary in ads.slice((_page - 1) * PER_PAGE, _page * PER_PAGE):
			page.add_child(_wanted(o) if o.has("care") else _ad(o))
		if ads.is_empty():
			page.add_child(_ink("Nothing else in this week's paper.", Color("7a6a50")))
		col.add_child(_newsprint(page, true))
	var nav := UI.hbox(14)
	var prev := UI.button("< Page back", func() -> void:
		_page -= 1
		_build()
		_focus_page("PrevPage"), 20)
	prev.name = "PrevPage"
	prev.disabled = _page == 0
	nav.add_child(prev)
	var where := UI.label("Front page" if _page == 0 else "Page %d of %d" % [_page + 1, pages], 20, UI.DIM)
	where.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(where)
	var next := UI.button("Turn the page >", func() -> void:
		_page += 1
		_build()
		_focus_page("NextPage"), 20)
	next.name = "NextPage"
	next.disabled = _page >= pages - 1
	nav.add_child(next)
	col.add_child(nav)
	var ring := col.find_child("Ring", true, false)
	return ring if ring else (next if not next.disabled else (prev if not prev.disabled else find_child("Tab_paper", true, false)))


## This week's ads still to come (a day gone, its ad's gone), the situations wanted at the back.
func _paper_ads() -> Array:
	var ads := Game.paper.filter(func(o: Dictionary) -> bool: return o.day >= Game.day)
	ads.append_array(Game.wanted)
	return ads


## The front page, then the classifieds three to a page.
func _paper_pages() -> int:
	return 1 + maxi(1, ceili(_paper_ads().size() / float(PER_PAGE)))


## The front page: the masthead, the week's lead story and the rest of the news (only what
## the game knows: Game.front_page), and what's inside.
func _front_page(ads: Array) -> Control:
	var page := UI.vbox(6)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mast := _ink("THE WEEKLY ADVERTISER", INK, 50)
	mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(mast)
	var out := Game.day # it came out last Friday, or with the season
	var opened := Game.day_of(Game.year, Game.start_month, 1)
	while Game.date(out).weekday != Game.FRIDAY and out > opened:
		out -= 1
	var dated := _ink("%s.   Ads, situations wanted, the week's news.   10p" % Game.date_text(out), Color("5a4a38"), 18)
	dated.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(dated)
	page.add_child(HSeparator.new())
	var news := Game.front_page()
	var colours := {"bad": Color("8a2018"), "event": INK, "good": Color("2e6a1e"), "dim": Color("5a4a38")}
	for i in news.size():
		var n: Array = news[i]
		var head := _ink(n[0], colours[n[2]], 40 if i == 0 else 30)
		head.clip_text = false
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(head)
		var body := _ink(n[1], INK, 20)
		body.clip_text = false
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if n[2] == "event" and n[1].begins_with("Today"):
			body.name = "News" # today's news (NOTES 216)
		page.add_child(body)
	page.add_child(HSeparator.new())
	var ads_n := ads.filter(func(o: Dictionary) -> bool: return not o.has("care")).size()
	var inside := _ink("INSIDE: %d ad%s to ring%s." % [ads_n, "" if ads_n == 1 else "s",
		", %d situation%s wanted" % [Game.wanted.size(), "" if Game.wanted.size() == 1 else "s"] if not Game.wanted.is_empty() else ""], INK, 20)
	page.add_child(inside)
	return _newsprint(page, true)


## After turning the paper's page: stay on that page button, or the other one once you
## reach an end (a disabled button can't hold the cursor).
func _focus_page(pressed: String) -> void:
	var b := find_child(pressed, true, false) as Button
	UI.focus(b if b and not b.disabled else find_child("NextPage" if pressed == "PrevPage" else "PrevPage", true, false))


## An ad as a classified on newsprint: no picture, just the words and the hints buried
## in them, and when they want it. You meet the customer at the briefing. Ringing gets an
## answer at once (Game.ring) and takes the call's time: yes books it on its day, no stamps it.
func _ad(o: Dictionary) -> Control:
	var row := UI.hbox(14)
	var ad := RichTextLabel.new()
	ad.bbcode_enabled = true
	ad.fit_content = true
	ad.scroll_active = false
	ad.custom_minimum_size.x = 480
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.add_theme_color_override("default_color", INK)
	ad.add_theme_font_size_override("normal_font_size", UI.px(18))
	ad.text = Game.ad_text(o)
	var busy := Game.jobs_on(o.day)
	if busy > 0:
		ad.text += "\n[color=#2e6a1e]You've %d job%s that day.[/color]" % [busy, "" if busy == 1 else "s"]
	row.add_child(ad)
	var why := Game.cant_book(o)
	if o.get("refused", false): # stamped for the week, what's above you kept in view
		ad.text += "\n[color=#b03020]NO: %s[/color]" % o.reply
		ad.modulate.a = 0.7
	elif why != "":
		ad.text += "\n[color=#b03020]%s.[/color]" % why
		ad.modulate.a = 0.7
	else:
		var ring := UI.button("Ring\n+%d min" % Game.RING_TIME, func() -> void:
			_call = Game.ring(o)
			_build()
			UI.focus(find_child("Ring", true, false) if find_child("Ring", true, false) else find_child("Tab_paper", true, false)), 20)
		ring.name = "Ring"
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ring)
	return _newsprint(row)


## c on a scrap of newsprint (`sheet`: a whole page of it, filling the space).
func _newsprint(c: Control, sheet := false) -> Control:
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e8e0c8")
	paper.border_color = Color("b8ac8c")
	paper.set_border_width_all(2)
	paper.set_content_margin_all(8)
	if sheet:
		paper.set_content_margin_all(16)
	var p := UI.panel(c)
	p.add_theme_stylebox_override("panel", paper)
	if sheet:
		p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return p


## The client book on the desk: your regulars, how often and what they pay, and dropping one.
func _book_view(root: Control) -> Control:
	var side := ScrollContainer.new() # a long list of regulars scrolls, following the cursor
	side.follow_focus = true
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(side)
	var list := UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(list)
	list.add_child(UI.label("Your regulars", 22))
	if Game.regulars.is_empty():
		list.add_child(UI.label("None yet. A good job from the paper might earn one.", 18, UI.DIM))
	for id: int in Game.regulars:
		list.add_child(_regular_row(id))
	for b: Button in list.find_children("*", "Button", true, false):
		return b
	return find_child("Tab_book", true, false)


func _regular_row(id: int) -> Control:
	var reg: Dictionary = Game.regulars[id]
	var row := UI.hbox(10)
	var every: String = {7: "weekly", 14: "fortnightly", 28: "four-weekly"}[reg.cadence]
	if Game.cadence_now(reg) < reg.cadence:
		every += " (more in summer)"
	var l := UI.label("%s, %s, %s, $%d" % [reg.job.customer, every, _hours(reg.job.from) + "-" + _hours(reg.job.by), reg.rate], 18, UI.GOOD)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var owed := roundi(reg.get("prepaid", 0) * reg.get("prepaid_each", 0.0))
	row.add_child(UI.button("Drop" + (" (owe $%d)" % owed if owed > 0 else ""), func() -> void:
		Game.drop(id)
		_build(), 18))
	return UI.panel(row)


## A situation wanted, on newsprint like the ads: who, how quick and how careful (in
## words and out of ten), what they ask a week. Ringing hires them, if you've a van free.
func _wanted(w: Dictionary) -> Control:
	var row := UI.hbox(14)
	var ad := RichTextLabel.new()
	ad.bbcode_enabled = true
	ad.fit_content = true
	ad.scroll_active = false
	ad.custom_minimum_size.x = 480
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.add_theme_color_override("default_color", INK)
	ad.add_theme_font_size_override("normal_font_size", UI.px(18))
	var pace: String = "Steady rather than quick" if w.pace < 0.65 else ("Reasonably quick" if w.pace < 0.85 else "A quick worker")
	var care: String = "not fussy" if w.care < 0.4 else ("tidy" if w.care < 0.7 else "careful, takes a pride")
	ad.text = "[color=#7a1c14]SITUATION WANTED.[/color] %s seeks gardening work. %s (%d/10), %s (%d/10). $%d a week. Ring %s." % [
		w.name, pace, roundi(w.pace * 10.0), care, roundi(w.care * 10.0), w.wage, w.name.split(" ")[0]]
	row.add_child(ad)
	var why := Game.cant_hire()
	if why != "":
		ad.text += "\n[color=#b03020]%s: a van each, from the shop.[/color]" % why
		ad.modulate.a = 0.7
	else:
		var ring := UI.button("Ring\n+%d min" % Game.RING_TIME, func() -> void:
			_call = Game.hire(w)
			_build()
			UI.focus(find_child("Ring", true, false) if find_child("Ring", true, false) else find_child("Tab_paper", true, false)), 20)
		ring.name = "Ring"
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ring)
	return _newsprint(row)


func _save_and_quit() -> void:
	Game.save()
	Game.in_run = false
	get_tree().change_scene_to_file("res://title.tscn")


## Pause (Esc, Start) on the board goes to Save and quit; Shift and Ctrl (RB and LB)
## turn its pages.
## Left and right step along a row of buttons, never up or down a column (NOTES 221, 47).
func _input(event: InputEvent) -> void:
	var dir := 1 if event.is_action_pressed("ui_right", true) else (-1 if event.is_action_pressed("ui_left", true) else 0)
	var c := get_viewport().gui_get_focus_owner()
	if dir == 0 or not c is BaseButton:
		return
	var to := UI.row_step(c, dir)
	if to:
		to.grab_focus()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	var leave := find_child("Quit", true, false) as Button
	if leave and event.is_action_pressed("pause"):
		UI.focus(leave)
		get_viewport().set_input_as_handled()
	elif leave and event.is_action_pressed("hop"): # away from the desk
		_away()
		get_viewport().set_input_as_handled()
	elif leave and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down")):
		var step := 1 if event.is_action_pressed("gear_up") else -1
		if _view == "paper" and _page + step >= 0 and _page + step < _paper_pages(): # the paper's pages first
			_page += step
			_build()
			UI.focus(find_child("Ring", true, false) if find_child("Ring", true, false) else find_child("NextPage" if step > 0 else "PrevPage", true, false))
		else:
			_show(VIEWS[posmod(VIEWS.find(_view) + step, VIEWS.size())])
			if _view == "paper" and step < 0: # back into the paper: its last page
				_page = _paper_pages() - 1
				_build()
				UI.focus(find_child("Tab_paper", true, false))
		get_viewport().set_input_as_handled()


## Playtest cheats, debug builds only: [1] adds $500, [2] adds 20 reputation and [4]
## takes 20 off (both reprint the paper), [3] skips to payday. No function keys: the editor owns them.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (OS.is_debug_build() and event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_1:
		Game.money += 500
		_build()
	elif event.keycode == KEY_3: # skip to payday, the jobs on the way not counted against you
		var trend := Game.rep_trend
		var moods := {}
		for id: int in Game.regulars:
			moods[id] = Game.regulars[id].mood
		while not Game.payday_pending and not Game.winter_pending:
			Game.end_day()
		Game.rep_trend = trend
		for id: int in moods:
			if Game.regulars.has(id):
				Game.regulars[id].mood = moods[id]
		Game.missed.clear()
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


## Step away from the desk: into the office, stood by it.
func _away() -> void:
	Game.place = "office"
	Game.spot = "desk"
	get_tree().change_scene_to_file("res://hub.tscn")


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
	_centred(col, "Rent and food: $%d.%s You have $%d." % [Game.LIVING, " Wages: $%d." % Game.wages() if Game.helpers else "", Game.money], 26, UI.GOOD if Game.money >= due else UI.BAD)
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
			var keep := "$%d rent and food%s" % [Game.LIVING, " + $%d wages" % Game.wages() if Game.helpers else ""]
			sums.text = ("$%d interest + %s + $%d off the debt. Owed after: $%d." % [Game.vig(), keep, off, Game.principal - off]) 				if Game.principal > 0 else keep + "."
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
	if w.get("owed_back", 0) > 0:
		_centred(col, "Paid back to those not coming back, for visits paid up front: $%d." % w.owed_back, 22, UI.BAD)
	if w.topped > 0:
		_centred(col, "Short, so the shark tops you up: $%d more on what you owe ($%d)." % [w.topped, Game.principal], 22, UI.BAD)
	if not w.back.is_empty():
		_centred(col, "Back in April: " + ", ".join(w.back), 22, UI.GOOD)
	if not w.gone.is_empty():
		_centred(col, "Not coming back: " + ", ".join(w.gone), 22, UI.BAD)
	if not w.crew_back.is_empty():
		_centred(col, "Your crew, laid off for the winter, back in April: " + ", ".join(w.crew_back), 22, UI.GOOD)
	if not w.crew_gone.is_empty():
		_centred(col, "Found other work over the winter: " + ", ".join(w.crew_gone), 22, UI.BAD)
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


## The day's end (design doc, The hub): every day, worked or not. Your jobs, the crew's
## (a raise asked is answered here), then the money: today's, and what Friday will take.
func _day_end() -> void:
	var e: Dictionary = Game.day_end
	var col := _screen()
	col.add_theme_constant_override("separation", 8)
	_centred(col, "DAY'S END", 48, UI.GOLD)
	_centred(col, Game.date_text(e.day), 24, UI.DIM)
	_centred(col, "Your day", 26, UI.GOLD)
	var mine_net := 0
	for m: Dictionary in e.mine:
		mine_net += m.net
		var how: String = {"fired": "fired you", "walked": "you drove off unpaid", "ko": "knocked out",
			"nicked": "nicked"}.get(m.outcome, "pleased" if m.mood >= 70.0 else ("not happy" if m.mood < 45.0 else "fine"))
		_centred(col, "%s: %s, %s" % [m.customer, how, _signed(m.net)], 22,
			UI.GOOD if m.outcome == "paid" and m.net > 0 else (UI.TEXT if m.outcome == "paid" else UI.BAD))
	if not e.missed.is_empty():
		_centred(col, "You never turned up for %s. They'll remember." % ", ".join(e.missed), 22, UI.BAD)
	if e.mine.is_empty() and e.missed.is_empty():
		_centred(col, "You didn't work today.", 22, UI.DIM)
	if not Game.helpers.is_empty() or not e.crew.is_empty():
		_centred(col, "Your crew", 26, UI.GOLD)
		for line: String in e.crew: # ponytail: a big crew's lines run long; a scroll once crews get that big
			_centred(col, line, 18)
		if e.crew.is_empty():
			_centred(col, "Nothing on today.", 18, UI.DIM)
	var first: Button = null
	for h: Dictionary in Game.helpers:
		if not h.has("asks"):
			continue
		var row := UI.hbox(12)
		row.add_child(UI.label("Raise %s to $%d a week (now $%d)?" % [h.name.split(" ")[0], h.asks, h.wage], 20, UI.GOLD))
		var yes := UI.button("Pay it", func() -> void:
			Game.answer_raise(h.id, true)
			_day_end(), 20)
		yes.name = "PayRaise"
		row.add_child(yes)
		row.add_child(UI.button("No", func() -> void:
			Game.answer_raise(h.id, false)
			_day_end(), 20))
		var holder := CenterContainer.new()
		holder.add_child(row)
		col.add_child(holder)
		if first == null:
			first = yes
	var today: int = e.now - e.was
	var other: int = today - mine_net - e.crew_net
	var parts := ["your jobs " + _signed(mine_net)]
	if not Game.helpers.is_empty() or e.crew_net != 0:
		parts.append("the crew " + _signed(e.crew_net))
	if other != 0:
		parts.append("bought, sold and the rest " + _signed(other))
	_centred(col, "Today %s (%s). You have $%d." % [_signed(today), ", ".join(parts), Game.money], 22)
	var due := Game.due()
	var bill := "rent and food $%d" % Game.LIVING
	if not Game.helpers.is_empty():
		bill += ", wages $%d" % Game.wages()
	if Game.principal > 0:
		bill += ", the vig $%d" % Game.vig()
	_centred(col, "%s takes $%d: %s. That leaves %s." % ["Payday" if Game.payday_pending else "Friday", due, bill,
		_signed(Game.money - due).trim_prefix("+")], 22,
		UI.GOOD if Game.money >= due else UI.BAD)
	var go := _centred_button(col, "Payday" if Game.payday_pending else ("The winter" if Game.winter_pending else "Next day"), func() -> void:
		Game.day_end = {}
		Game.missed.clear()
		Game.save()
		_ready())
	go.name = "NextDay"
	UI.focus(first if first else go)


func _signed(n: int) -> String:
	return ("+$%d" if n >= 0 else "-$%d") % absi(n)


## A job started and never finished (quit, or a crash): you blacked out. Ironman.
func _blackout() -> void:
	var j: Dictionary = Game.blackout
	Game.blackout = {}
	var col := _screen()
	_centred(col, "YOU BLACKED OUT", 56, UI.BAD)
	_centred(col, "You come to at home. Of %s's garden, you remember nothing." % j.get("customer", "someone"), 24)
	_centred(col, "A note through the door: \"Don't bother coming back.\"", 24, UI.DIM)
	_centred(col, "The job's lost, and word gets round.", 22, UI.BAD)
	if j.get("owed_back", 0) > 0:
		_centred(col, "And the $%d they paid up front, you pay back." % j.owed_back, 22, UI.BAD)
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
