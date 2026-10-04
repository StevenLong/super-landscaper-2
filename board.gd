extends Control
## Between jobs (design doc, The Business): the corkboard the office will open (design
## doc, Time is the scarce thing). Four pages: the calendar (today's jobs, the next two
## weeks), the week's paper to ring, your crew (who goes where), and the shop. The day's clock runs along the top and
## lights up what an action will cost before you take it. Friday brings payday (the loan
## shark's man), September's end the winter, and a job you never finished the blackout.

const VIEWS := ["calendar", "paper", "crew", "shop"]
const PER_PAGE := 3 ## ads to a page of the paper
const CORK := Color("8a6238")
const NOTE := Color("efe6cc")
const INK := Color("2a2420")
const CREW := Color("2a4a8a") ## a booking sent to a helper, on the corkboard

var _call := "" ## what the last ad you rang said, shown by the paper
var _view := "calendar"
var _page := 0 ## the paper's page
var _clock: DayClock


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

	_clock = DayClock.new()
	_clock.name = "DayClock"
	_clock.custom_minimum_size = Vector2(0, 54)
	root.add_child(_clock)

	# The pages, as tabs: Shift and Ctrl (RB and LB) turn them too.
	var tabs := UI.hbox(10)
	for v: String in VIEWS:
		var open := Game.paper.filter(func(o: Dictionary) -> bool: return Game.cant_book(o) == "" and not o.get("refused", false)).size()
		if Game.cant_hire() == "":
			open += Game.wanted.size()
		var asks := Game.helpers.filter(func(h: Dictionary) -> bool: return h.has("asks")).size()
		var t := UI.button({"calendar": "Calendar", "paper": "Paper (%d to ring)" % open, "shop": "Shop",
			"crew": "Crew" + (" (%d)" % Game.helpers.size() if Game.helpers else "") + (" !" if asks else "")}[v], _show.bind(v), 20)
		t.name = "Tab_" + v
		if v == _view:
			t.add_theme_color_override("font_color", UI.GOLD)
			t.add_theme_color_override("font_focus_color", UI.GOLD)
		tabs.add_child(t)
	var hint := UI.label("%s %s turn the page" % [Game.key("gear_down"), Game.key("gear_up")], 18, UI.DIM)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(hint)
	root.add_child(tabs)
	if not Game.missed.is_empty():
		var m := UI.label("You never turned up for %s. They'll remember." % ", ".join(Game.missed), 20, UI.BAD)
		m.name = "Missed"
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(m)
		Game.missed.clear()
	if _view == "calendar" and not Game.crew_report.is_empty():
		var r := UI.label("Your crew (Crew page): " + Game.crew_report[0], 18, UI.GOLD)
		r.name = "CrewNews"
		r.clip_text = true
		root.add_child(r)

	var first: Control
	match _view:
		"paper":
			first = _paper_view(root)
		"shop":
			first = _shop_view(root, keep)
		"crew":
			first = _crew_view(root, keep)
		_:
			first = _today(root)
			root.add_child(_corkboard())
	UI.focus(first)


func _show(view: String) -> void:
	_view = view
	_page = 0
	_build()
	UI.focus(find_child("Tab_" + view, true, false))


## Light up on the clock what pressing this would use: from now to `to`.
func _preview(c: Control, to: int) -> void:
	for s: String in ["focus_entered", "mouse_entered"]:
		c.connect(s, func() -> void: _clock.cost_to = to; _clock.queue_redraw())
	for s: String in ["focus_exited", "mouse_exited"]:
		c.connect(s, func() -> void: _clock.cost_to = -1; _clock.queue_redraw())


## Today: each job to go to (when you'd get there), and calling it a day. Returns the
## first button.
func _today(box: Control) -> Button:
	var col := UI.vbox(6)
	var list := UI.vbox(6) # more than three and they scroll, so the fortnight stays in view
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(list)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var jobs := Game.jobs_today()
	scroll.custom_minimum_size.y = 42 * clampi(jobs.size(), 1, 3)
	var first: Button = null
	if jobs.is_empty():
		var row := UI.hbox(14)
		var sent := Game.bookings().filter(func(b: Dictionary) -> bool: return b.has("helper")).size()
		var l := UI.label("A day in jail." if Game.today().has("jail") else ("Nothing for you today; your crew has %d." % sent if sent else "Nothing booked today."), 20, UI.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		first = UI.button("On to the next job", func() -> void:
			Game.skip()
			_ready(), 20)
		first.name = "Today"
		row.add_child(first)
		list.add_child(row)
	else:
		for b: Dictionary in jobs:
			var row := UI.hbox(0) # one line each (labels, not rich text, so the scroll can measure them)
			var who := UI.label(b.customer, 20, UI.BAD if b.has("service") else (UI.GOOD if b.has("regular") else UI.GOLD))
			who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(who)
			var what := UI.label(_job_line(b), 20)
			what.clip_text = true
			what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(what)
			var go: Button
			if Game.can_go(b):
				var at := Game.arrival(b)
				go = UI.button("Go: there at %s" % Game.time_text(at), _go.bind(b), 20)
				_preview(go, at)
			else:
				go = UI.button("Too late", func() -> void: pass, 20)
				go.disabled = true
			go.name = "Today" if b == jobs[0] else "Go"
			row.add_child(go)
			list.add_child(row)
			if first == null and not go.disabled:
				first = go
		var end := UI.button("Call it a day" + (" (miss %d)" % jobs.size()), func() -> void:
			Game.end_day()
			_ready(), 20)
		end.name = "EndDay"
		var holder := UI.hbox(0)
		holder.alignment = BoxContainer.ALIGNMENT_END
		holder.add_child(end)
		col.add_child(holder)
		if first == null:
			first = end
	box.add_child(UI.panel(col))
	return first


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


## The corkboard: the next fortnight from today, a note for every day with what's booked
## on it and when. Today ringed.
func _corkboard() -> Control:
	var grid := GridContainer.new()
	grid.name = "Calendar"
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for d in range(Game.day, Game.day + 7):
		var n: String = Game.DAYS[Game.date(d).weekday].left(3)
		var friday: bool = Game.date(d).weekday == Game.FRIDAY
		grid.add_child(_ink(n + ("  payday" if friday else ""), Color("f8e0a0") if friday else Color("e8d8b8")))
	for d in range(Game.day, Game.day + 14):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(0, 112)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = NOTE
		style.border_color = Color("c08a10") if d == Game.day else Color("5a3c20")
		style.set_border_width_all(3 if d == Game.day else 1)
		style.set_content_margin_all(4)
		cell.add_theme_stylebox_override("panel", style)
		var notes := UI.vbox(0)
		cell.add_child(notes)
		var t := Game.date(d)
		notes.add_child(_ink("%d%s" % [t.day, " " + Game.MONTHS[t.month - 1].left(3) if t.day == 1 or d == Game.day else ""], Color("7a6a50")))
		var l := Game.bookings(d)
		for i in mini(l.size(), 3 if l.size() > 4 else 4):
			var b: Dictionary = l[i]
			var text := "Court" if b.has("court") else ("Jail" if b.has("jail") else ("%s-%s %s" % [_hours(b.from), _hours(b.by), "Duty" if b.has("service") else b.customer.split(" ")[-1]]))
			if b.has("helper"): # sent out: whose it is
				text = Game.helper(b.helper).get("name", "?").split(" ")[0] + ": " + b.customer.split(" ")[-1]
			notes.add_child(_ink(text, Color("b03020") if b.has("court") or b.has("jail") or b.has("service") else (CREW if b.has("helper") else (Color("2e6a1e") if b.has("regular") else INK))))
		if l.size() > 4:
			notes.add_child(_ink("+%d more" % (l.size() - 3), Color("7a6a50")))
		grid.add_child(cell)
	var board := PanelContainer.new()
	var cork := StyleBoxFlat.new()
	cork.bg_color = CORK
	cork.border_color = Color("5a3c20")
	cork.set_border_width_all(4)
	cork.set_content_margin_all(8)
	board.add_theme_stylebox_override("panel", cork)
	board.add_child(grid)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return board


## A line in ink on paper: no drop shadow, clipped so a long name never widens the board.
func _ink(text: String, color := INK) -> Label:
	var l := UI.label(text, 20, color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.clip_text = true
	return l


## The week's paper, a few ads to a page, and your regulars beside it. Returns the first
## Ring button (or a page button).
func _paper_view(root: Control) -> Control:
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.0
	cols.add_child(left)
	var heading := UI.hbox(14)
	heading.add_child(UI.label("This week's paper" if Game.paper.any(func(o: Dictionary) -> bool: return o.day >= Game.day) or not Game.wanted.is_empty()
		else "Nothing else in this week's paper.", 22))
	if _call != "": # what the last one you rang said
		var said := UI.label(_call, 18, UI.GOLD)
		said.name = "Call"
		said.clip_text = true
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(said)
	left.add_child(heading)
	var ev := Game.day_event()
	if ev != "": # today's news, a headline over the ads (NOTES 216)
		var news := UI.label(Game.DAY_EVENTS[ev].news.to_upper(), 22, INK)
		news.name = "News"
		news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(_newsprint(news))
	var ads := Game.paper.filter(func(o: Dictionary) -> bool: return o.day >= Game.day) # a day gone, its ad's gone
	ads.append_array(Game.wanted) # the situations wanted at the back
	var pages := maxi(1, ceili(ads.size() / float(PER_PAGE)))
	_page = clampi(_page, 0, pages - 1)
	for o: Dictionary in ads.slice(_page * PER_PAGE, _page * PER_PAGE + PER_PAGE):
		left.add_child(_wanted(o) if o.has("care") else _ad(o))
	var nav := UI.hbox(14)
	var prev := UI.button("< Page back", func() -> void:
		_page -= 1
		_build()
		_focus_page("PrevPage"), 20)
	prev.name = "PrevPage"
	prev.disabled = _page == 0
	nav.add_child(prev)
	var where := UI.label("Page %d of %d" % [_page + 1, pages], 20, UI.DIM)
	where.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(where)
	var next := UI.button("Turn the page >", func() -> void:
		_page += 1
		_build()
		_focus_page("NextPage"), 20)
	next.name = "NextPage"
	next.disabled = _page >= pages - 1
	nav.add_child(next)
	left.add_child(nav)

	var side := ScrollContainer.new() # a long list of regulars scrolls, following the cursor
	side.follow_focus = true
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(side)
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(right)
	right.add_child(UI.label("Your regulars", 22))
	if Game.regulars.is_empty():
		var none := UI.label("None yet. A good job from the paper might earn one.", 18, UI.DIM)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(none)
	for id: int in Game.regulars:
		right.add_child(_regular_row(id))
	var ring := left.find_child("Ring", true, false)
	return ring if ring else (next if not next.disabled else (prev if not prev.disabled else find_child("Tab_paper", true, false)))


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
		_preview(ring, Game.minute + Game.RING_TIME)
		row.add_child(ring)
	return _newsprint(row)


## c on a scrap of newsprint.
func _newsprint(c: Control) -> Control:
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e8e0c8")
	paper.border_color = Color("b8ac8c")
	paper.set_border_width_all(2)
	paper.set_content_margin_all(8)
	var p := UI.panel(c)
	p.add_theme_stylebox_override("panel", paper)
	return p


## The shop: your mowers, upgrades and robots. Returns the first button (or the row kept).
func _shop_view(root: Control, keep: String) -> Control:
	var scroll := ScrollContainer.new() # a long list scrolls, following the cursor
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var shop := GridContainer.new() # two columns, so it fits without scrolling far
	shop.columns = 2
	shop.add_theme_constant_override("h_separation", 16)
	shop.add_theme_constant_override("v_separation", 6)
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(shop)
	for key: String in Game.MOWERS:
		shop.add_child(_mower_row(key))
	for key: String in Game.UPGRADES:
		shop.add_child(_upgrade_row(key))
	shop.add_child(_van_row())
	for key: String in ["petrol", "rideon"]:
		shop.add_child(_crew_mower_row(key))
	shop.add_child(_robot_row())
	for c: Control in shop.get_children():
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for l: Label in shop.find_children("*", "Label", true, false): # wrap, so no row's words widen the column off the screen
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var first: Control = null
	var kept := find_child(keep, true, false) if keep != "" else null
	for b: Button in (kept if kept else shop).find_children("*", "Button", true, false):
		if not b.disabled:
			first = b
			break
	return first if first else find_child("Tab_shop", true, false)


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


## The day's clock, 6am to 8pm: today's windows as bars, now as a gold line, the past
## shaded, and (cost_to) what the focused button would use lit up.
class DayClock extends Control:
	var cost_to := -1

	func _x(m: int) -> float:
		return clampf(float(m - Game.DAY_START) / (Game.DAY_END - Game.DAY_START), 0.0, 1.0) * size.x

	func _draw() -> void:
		var font := get_theme_default_font()
		var top := 22.0
		var h := size.y - top
		draw_rect(Rect2(0, top, size.x, h), UI.PANEL)
		for hh in range(6, 21, 2):
			var x := _x(hh * 60)
			draw_line(Vector2(x, top), Vector2(x, size.y), UI.PANEL_EDGE, 1.0)
			var t: String = Game.time_text(hh * 60)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(font, Vector2(clampf(x - w / 2.0, 0.0, size.x - w), 17), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.DIM)
		draw_rect(Rect2(0, top, _x(Game.minute), h), Color(0, 0, 0, 0.4))
		var lanes: Array[int] = [] # each window in the first lane free by its start
		var on: Array[int] = []
		for b: Dictionary in Game.jobs_today():
			var lane := 0
			while lane < lanes.size() and lanes[lane] > b.from:
				lane += 1
			if lane == lanes.size():
				lanes.append(0)
			lanes[lane] = b.by
			on.append(lane)
		var step := minf(10.0, (h - 6.0) / maxf(1.0, lanes.size())) # many overlapping, thinner bars
		var jobs := Game.jobs_today()
		for i in jobs.size():
			var b: Dictionary = jobs[i]
			var color := UI.BAD if b.has("service") else (UI.GOOD if b.has("regular") else UI.GOLD)
			draw_rect(Rect2(_x(b.from), top + 3 + on[i] * step, _x(b.by) - _x(b.from), maxf(2.0, step - 2.0)), color)
		if cost_to > Game.minute:
			var x0 := _x(Game.minute)
			var x1 := maxf(_x(cost_to), x0 + 3.0)
			draw_rect(Rect2(x0, top, x1 - x0, h), Color(UI.GOLD, 0.5))
			var mins := cost_to - Game.minute
			var t := "+%d min" % mins if mins < 60 else "+%dh%s" % [floori(mins / 60.0), " %dm" % (mins % 60) if mins % 60 else ""]
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var at := Vector2(minf(x1 + 6.0, size.x - tw - 6.0), size.y - 7)
			draw_rect(Rect2(at.x - 4, top + 2, tw + 8, h - 4), UI.BG)
			draw_string(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.GOLD)
		draw_rect(Rect2(0, top, size.x, h), UI.PANEL_EDGE, false, 2.0)
		var now := _x(Game.minute)
		draw_line(Vector2(now, top - 2), Vector2(now, size.y), UI.GOLD, 3.0)


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
		buy.disabled = Game.money < u.price or (key == "gear4" and "gear3" not in Game.upgrades)
		row.add_child(buy)
	var p := UI.panel(row)
	p.name = key # _build(key) finds the row again
	return p


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
		_preview(ring, Game.minute + Game.RING_TIME)
		row.add_child(ring)
	return _newsprint(row)


## Your crew (design doc, Hired help): each helper, their kit and wage (a raise they've
## asked for, yes or no), last evening's report; and the week's bookings, each to you or a
## helper. Returns the first button. `keep`: the row just changed, which keeps the cursor.
func _crew_view(root: Control, keep: String) -> Control:
	var cols := UI.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	var crew := ScrollContainer.new() # a big crew and a long report scroll, following the cursor
	crew.follow_focus = true
	crew.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	crew.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(crew)
	var left := UI.vbox(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crew.add_child(left)
	left.add_child(UI.label("Your crew (%d van%s)" % [Game.vans, "" if Game.vans == 1 else "s"], 22))
	if Game.helpers.is_empty():
		var none := UI.label("Nobody yet. Buy a van in the shop, then ring a situation wanted in the paper. A helper's paid every Friday, busy or not.", 18, UI.DIM)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(none)
	for h: Dictionary in Game.helpers:
		left.add_child(_helper_row(h))
	if not Game.crew_report.is_empty():
		left.add_child(UI.label("Their last day", 22))
		for line: String in Game.crew_report:
			var l := UI.label(line, 18, UI.DIM)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			left.add_child(l)

	var side := ScrollContainer.new() # a busy week scrolls, following the cursor
	side.follow_focus = true
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(side)
	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(right)
	right.add_child(UI.label("Who goes", 22))
	var any := false
	for d in range(Game.day, Game.day + 7):
		for b: Dictionary in Game.bookings(d):
			if Game.can_send(b) or b.has("helper"): # one sent stays, to take back
				right.add_child(_send_row(b))
				any = true
	if not any:
		right.add_child(UI.label("Nothing booked this week.", 18, UI.DIM))
	var kept := find_child(keep, true, false) if keep != "" else null
	for c: Node in (kept.find_children("*", "Button", true, false) if kept else []) + cols.find_children("*", "Button", true, false):
		if not (c as Button).disabled:
			return c
	return find_child("Tab_crew", true, false)


## A helper: how good, what they cost, their kit (pressing it tries the next), a raise
## asked for, letting them go.
func _helper_row(h: Dictionary) -> Control:
	var box := UI.vbox(4)
	box.add_child(UI.label("%s: pace %d, care %d, $%d a week, %d job%s" % [h.name, roundi(h.pace * 10.0), roundi(h.care * 10.0),
		h.wage, h.jobs, "" if h.jobs == 1 else "s"], 18, UI.GOOD))
	var row := UI.hbox(10)
	var kit := UI.button("Kit: " + Game.MOWERS[h.kit].name, func() -> void:
		var kinds: Array = Game.MOWERS.keys()
		var i := kinds.find(h.kit)
		for step in range(1, kinds.size() + 1): # the next one free, round to the push mower
			if Game.set_kit(h.id, kinds[(i + step) % kinds.size()]):
				break
		_build("helper_%d" % h.id), 18)
	kit.name = "Kit"
	row.add_child(kit)
	if h.has("asks"):
		row.add_child(UI.label("Asks $%d:" % h.asks, 18, UI.GOLD))
		row.add_child(UI.button("Pay it", func() -> void:
			Game.answer_raise(h.id, true)
			_build("helper_%d" % h.id), 18))
		row.add_child(UI.button("No", func() -> void:
			Game.answer_raise(h.id, false)
			_build("helper_%d" % h.id), 18))
	row.add_child(UI.button("Let go", func() -> void:
		Game.let_go(h.id)
		_build(), 18))
	box.add_child(row)
	var p := UI.panel(box)
	p.name = "helper_%d" % h.id
	return p


## A booking this week: who goes (pressing it hands it to the next helper, round to you),
## and if a regular wants you, said before you choose.
func _send_row(b: Dictionary) -> Control:
	var row := UI.hbox(10)
	var text := "%s %s-%s %s, $%d" % [Game.day_word(b.day).left(3) if b.day > Game.day + 1 else Game.day_word(b.day),
		_hours(b.from), _hours(b.by), b.customer.split(" ")[-1], b.pay]
	if Game.wants_you(b) > 0.0:
		text += ", wants you"
	var l := UI.label(text, 18, UI.GOOD if b.has("regular") else UI.TEXT)
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var who: Dictionary = Game.helper(b.get("helper", -1))
	var go := UI.button("You" if who.is_empty() else who.name.split(" ")[0], func() -> void:
		var ids: Array = [-1] + Game.helpers.map(func(h: Dictionary) -> int: return h.id)
		Game.assign(b, ids[(ids.find(b.get("helper", -1)) + 1) % ids.size()])
		_build("send_%d_%d" % [b.day, b.seed]), 18)
	go.name = "Send"
	go.disabled = Game.helpers.is_empty()
	go.custom_minimum_size.x = 110
	row.add_child(go)
	var p := UI.panel(row)
	p.name = "send_%d_%d" % [b.day, b.seed]
	return p


## Vans: one per helper.
func _van_row() -> Control:
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label(Game.VAN.name + ("  (you have %d)" % Game.vans if Game.vans > 0 else ""), 20))
	info.add_child(UI.label(Game.VAN.blurb, 18, UI.DIM))
	row.add_child(info)
	if Game.vans > 0:
		row.add_child(_sell_button("van", _build.bind("van")))
	var buy := UI.button("Buy $%d" % Game.VAN.price, func() -> void:
		Game.buy("van")
		_build("van"), 18)
	buy.disabled = Game.money < Game.VAN.price
	row.add_child(buy)
	var p := UI.panel(row)
	p.name = "van"
	return p


## A mower for the crew: as many as you like, given out on the Crew page.
func _crew_mower_row(kind: String) -> Control:
	var m: Dictionary = Game.MOWERS[kind]
	var n: int = Game.crew_kit.get(kind, 0)
	var row := UI.hbox(10)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UI.label("%s for the crew%s" % [m.name, "  (%d)" % n if n > 0 else ""], 20))
	info.add_child(UI.label("A helper on it mows quicker. Give it out on the Crew page.", 18, UI.DIM))
	row.add_child(info)
	if n > 0:
		row.add_child(_sell_button("crew_" + kind, _build.bind("crew_" + kind)))
	var buy := UI.button("Buy $%d" % m.price, func() -> void:
		Game.buy("crew_" + kind)
		_build("crew_" + kind), 18)
	buy.disabled = Game.money < m.price
	row.add_child(buy)
	var p := UI.panel(row)
	p.name = "crew_" + kind
	return p


func _save_and_quit() -> void:
	Game.save()
	Game.in_run = false
	get_tree().change_scene_to_file("res://title.tscn")


## Pause (Esc, Start) on the board goes to Save and quit; Shift and Ctrl (RB and LB)
## turn its pages.
func _unhandled_input(event: InputEvent) -> void:
	var leave := find_child("Quit", true, false) as Button
	if leave and event.is_action_pressed("pause"):
		UI.focus(leave)
		get_viewport().set_input_as_handled()
	elif leave and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down")):
		_show(VIEWS[posmod(VIEWS.find(_view) + (1 if event.is_action_pressed("gear_up") else -1), VIEWS.size())])
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


func _go(b: Dictionary) -> void: # packing first (pack.gd), then the job
	Game.next_job = b
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
