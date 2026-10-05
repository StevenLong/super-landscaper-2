extends Control
## The office's paper things (design doc, The hub, redesigned), each its own fitting: the
## corkboard's calendar (a day, or the month), the paper by the phone, the desk's client
## book. Game.spot says which; step away and you're back in your premises (hub.gd). What's
## waiting to be read comes first: the day's end, Friday's payday (the loan shark's man),
## court, September's end the winter, and a job you never finished, the blackout. As the
## planner (Start, in the premises): today's plan, read-only, ending the day, save and quit.

signal closed ## the planner, put away
signal end_day_asked ## the planner's End the day

const VIEWS := {"corkboard": "calendar", "paper": "paper", "desk": "book"} ## each fitting's view
const PER_PAGE := 6 ## classifieds to a page of the paper
const NEWSPRINT := Color("e8e0c8")
const SHARK_LOOK := {"hair_style": 2, "skin": 1, "hair": 0, "shirt": 6} ## Vince, and his man
const DEAD_ADS := ["PIANO, FREE. You collect. Stairs.", "LOST CAT. Answers to Biscuit. Doesn't.", "BIKE FOR SALE. One careful owner, one not.",
	"ROOM TO LET. No dogs, no gardeners.", "CAR BOOT SALE, Sunday, the church field.", "WANTED: GARDEN GNOMES. Good homes, no questions.",
	"PIANO LESSONS. Mrs Pratt. Patience extra.", "DRUM KIT. Offers. Please.", "FOUND: ONE WELLY. Left foot.", "BUDGIE, TALKS. Swears."]
const CORK := Color("8a6238")
const NOTE := Color("efe6cc")
const INK := Color("2a2420")
const CREW_COLORS := [Color("1d9e75"), Color("7f77dd"), Color("e07050"), Color("d4537e"), Color("378add"), Color("8fbf3a"), Color("c8c8c8")] ## each helper's, on the calendar
const INFO_W := 430.0 ## a calendar row's who-and-what
const MOWER_W := 130.0 ## and its mower
const ROW_SEP := 10
const CARD_W := 860.0 ## a day's end card

var _call := "" ## what the last ad you rang said, shown by the paper
var _view := "calendar"
var _page := 0 ## the paper's page
var _open_day := -1 ## the calendar's day (today by default)
var _cal_month := false ## the calendar showing the month, to pick a day from
var _pick: Control = null ## who-goes list open beside a booking
var planner := false ## the planner over the premises, not the office's fitting
var _client := -1 ## the client book's page: a regular's id, or -1 for its index
var _open_card := -1 ## the day's end card opened to its report
var _talk_back := Callable() ## what B does in the open talk (hang up, by default)
var _ringing := false ## a call's open: its time's owed when you put the phone down
var _charged := false ## something said in it took the call's time already (a booking, a hire)
var _rang_from := "" ## the paper's page you rang from
var _rang_at := 0 ## and which of its circled ads
var edge_turns := true ## the paper's left and right past a page's edge turn it (test_pad's walk turns it off)
var _card_at := -1 ## the day's end card the cursor was last on (opened or closed there)


func _ready() -> void:
	theme = UI.theme()
	if planner:
		_build()
		return
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
	Game.advance_crew() # whoever's due off has gone
	_close_pick()
	_view = "calendar" if planner else VIEWS.get(Game.spot, "calendar")
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

	# The header: the time and your money, once (the rest is where it belongs); away and quit.
	var head := UI.hbox(26)
	var now := UI.label(Game.time_text(Game.minute), 24, UI.BAD if Game.minute >= Game.DAY_END else UI.TEXT)
	now.name = "Now"
	head.add_child(now)
	head.add_child(UI.label("$%d" % Game.money, 24))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	if planner:
		var end := UI.button("End the day", func() -> void: end_day_asked.emit(), 18)
		end.name = "PlannerEnd"
		head.add_child(end)
	var away := UI.button(("Put it away " if planner else "Step away ") + Game.key("hop"), _away, 18)
	away.name = "Away"
	away.disabled = Game.today().has("jail") # a day inside: nowhere to step to
	head.add_child(away)
	var leave := UI.button("Save and quit", _save_and_quit, 18) # the board's always saved: this just says so
	leave.name = "Quit"
	head.add_child(leave)
	root.add_child(head)

	var title := UI.label({"calendar": "Your planner" if planner else "The corkboard", "paper": "The Weekly Advertiser", "book": "The client book"}[_view], 22, UI.GOLD)
	title.name = "Station"
	root.add_child(title)

	var first: Control
	match _view:
		"paper":
			first = _paper_view(root)
		"book":
			first = _book_view(root)
		_:
			first = _calendar(root, keep)
	UI.focus(first)


## Open a fitting's view (the paper, the client book, the calendar).
func _show(view: String) -> void:
	for k: String in VIEWS:
		if VIEWS[k] == view:
			Game.spot = k
	_page = 0
	_build()


## The calendar (design doc, The hub, redesigned): a day, or the month to get to one. It
## opens on today. Returns the button to focus.
func _calendar(root: Control, keep := "") -> Control:
	if _open_day < Game.day:
		_open_day = Game.day
	return _month(root) if _cal_month else _day_view(root, keep)


## The month: five rolling weeks from this Monday, a tile a day with a dot a booking in the
## colour of who's going. A on one opens its day.
func _month(root: Control) -> Control:
	var grid := GridContainer.new()
	grid.name = "Calendar"
	grid.columns = 7
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
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
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(board)
	return find_child("Tile_%d" % _open_day, true, false)


## A day's tile: its date, and a dot a booking in who's going's colour (court and the like
## in words). Today ringed; days gone, faded and out of reach.
func _tile(d: int) -> Control:
	var t := Game.date(d)
	var b := Button.new()
	b.name = "Tile_%d" % d
	b.custom_minimum_size = Vector2(0, 80)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = NOTE.darkened(0.35) if d < Game.day else (NOTE.lightened(0.4) if state == "focus" or state == "hover" else NOTE)
		style.border_color = Color("f0b020") if state == "focus" else (Color("c08a10") if d == Game.day else Color("5a3c20"))
		style.set_border_width_all(4 if state == "focus" else (3 if d == Game.day else 1))
		style.set_content_margin_all(4)
		b.add_theme_stylebox_override(state, style)
	var notes := UI.vbox(4)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notes.set_anchors_preset(Control.PRESET_FULL_RECT)
	notes.offset_left = 6
	notes.offset_top = 2
	b.add_child(notes)
	notes.add_child(_ink("%d%s" % [t.day, " " + Game.MONTHS[t.month - 1].left(3) if t.day == 1 or d == Game.day else ""], Color("7a6a50")))
	var dots := HFlowContainer.new()
	dots.add_theme_constant_override("h_separation", 4)
	dots.add_theme_constant_override("v_separation", 4)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notes.add_child(dots)
	for bk: Dictionary in Game.bookings(d):
		if bk.has("court") or bk.has("jail") or bk.has("service"):
			notes.add_child(_ink("Court" if bk.has("court") else ("Jail" if bk.has("jail") else "Duty"), Color("b03020")))
			continue
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = _who_color(bk.get("helper", -1))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
	for c: Control in notes.find_children("*", "Label", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if d < Game.day: # gone: still there, as a disabled button is on the board
		b.disabled = true
	else:
		b.pressed.connect(func() -> void:
			_open_day = d
			_cal_month = false
			_build())
	return b


## Who's going's colour: you gold, each helper their own.
func _who_color(id: int) -> Color:
	if id < 0:
		return UI.GOLD
	var i := Game.helpers.find(Game.helper(id))
	return CREW_COLORS[maxi(0, i) % CREW_COLORS.size()]


## A day: a row a booking (who's going, when, the mower, what's wrong) with its window as a
## bar on the day's line beside it, and the drive before it; today, now and what's gone.
## The shoulders step days, B goes to the month.
func _day_view(root: Control, keep := "") -> Control:
	var d := _open_day
	var t := Game.date(d)
	var top := UI.hbox(14)
	var prev := UI.button("< " + Game.key("gear_down"), _step_day.bind(-1), 18)
	prev.name = "PrevDay"
	prev.disabled = d <= Game.day
	top.add_child(prev)
	var title := UI.label("%s %d %s%s" % [Game.DAYS[t.weekday], t.day, Game.MONTHS[t.month - 1], " (today)" if d == Game.day else ""], 26, UI.GOLD)
	title.custom_minimum_size.x = 420
	top.add_child(title)
	var next := UI.button(Game.key("gear_up") + " >", _step_day.bind(1), 18)
	next.name = "NextDay"
	top.add_child(next)
	if not planner: # the planner's B puts it away
		var month := UI.button("Month " + Game.key("hop"), _to_month, 18)
		month.name = "Month"
		top.add_child(month)
	if t.weekday == Game.FRIDAY:
		var pay := UI.label("Payday: $%d due" % Game.due(), 18, UI.DIM)
		pay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(pay)
	root.add_child(top)
	var axis := UI.hbox(ROW_SEP)
	var lead := Control.new()
	lead.custom_minimum_size.x = INFO_W + ROW_SEP + MOWER_W
	axis.add_child(lead)
	var hours := DayLine.new()
	hours.axis = true
	hours.custom_minimum_size.y = 24
	hours.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	axis.add_child(hours)
	root.add_child(axis)
	var scroll := ScrollContainer.new() # a busy day scrolls, following the cursor
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var rows := UI.vbox(6)
	rows.name = "Calendar"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var plan := Game.crew_plan(d)
	var l := Game.bookings(d)
	for b: Dictionary in l:
		if b.has("jail"):
			rows.add_child(UI.label("A day in jail.", 20, UI.BAD))
		elif b.has("court"):
			rows.add_child(UI.label("Court: what happened at %s's." % b.court.customer, 20, UI.BAD))
		else:
			rows.add_child(_row(b, plan))
	if l.is_empty():
		rows.add_child(UI.label("Nothing booked. A free day.", 20, UI.DIM))
	if d == Game.day and not planner:
		# Every day ends on its own day's end, worked or not (the hub grill): nothing skips.
		var mine := Game.jobs_today()
		var end := UI.button("Call it a day" + (" (miss %d)" % mine.size() if mine else ""), func() -> void:
			Game.end_day()
			_open_day = -1
			_ready(), 20)
		end.name = "EndDay"
		var holder := UI.hbox(0)
		holder.add_child(end)
		rows.add_child(holder)
	var kept := find_child(keep, true, false) if keep != "" else null
	if kept:
		for c: Button in kept.find_children("*", "Button", true, false):
			if not c.disabled:
				return c
	for b: Button in rows.find_children("Who", "Button", true, false):
		if not b.disabled:
			return b
	var end_day := find_child("EndDay", true, false)
	return end_day if end_day else next


func _step_day(by: int) -> void:
	_open_day = maxi(Game.day, _open_day + by)
	_build()


func _to_month() -> void:
	_cal_month = true
	_build()


## A booking's row: who's going and its facts (A picks who), the mower (A changes it, the
## crew's only: you pack yours), and its bar on the day's line.
func _row(b: Dictionary, plan: Dictionary) -> Control:
	var row := UI.hbox(ROW_SEP)
	row.name = "job_%d_%d" % [_open_day, b.get("seed", 0)]
	var p: Dictionary = plan.get(b.get("seed", -1), {})
	var id: int = b.get("helper", -1)
	var who := UI.button("", func() -> void: pass, 18)
	who.name = "Who"
	who.custom_minimum_size = Vector2(INFO_W, 0)
	who.clip_contents = true
	var lines := UI.vbox(0)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.offset_left = 10
	lines.offset_right = -10
	lines.offset_top = 4
	who.add_child(lines)
	var first := UI.hbox(10)
	var name_l := UI.label(b.customer, 20, UI.BAD if b.has("service") else UI.TEXT)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	first.add_child(name_l)
	first.add_child(UI.label("You" if id < 0 else Game.helper(id).get("name", "?").split(" ")[0], 20, _who_color(id)))
	lines.add_child(first)
	var what := "Community service, unpaid" if b.has("service") else ("Your regular, " + ("paid up front" if Game.regulars.get(b.get("regular", -1), {}).get("prepaid", 0) > 0 else "$%d" % b.pay)
		if b.has("regular") else "From the paper, $%d" % b.pay)
	lines.add_child(UI.label("%s to %s. %s" % [Game.time_text(b.from), Game.time_text(b.by), what], 18, UI.DIM))
	var warn := ""
	var warn_color := UI.GOLD
	if id < 0 and _open_day == Game.day:
		var st := _state(b)
		warn = st[0]
		warn_color = st[1]
	elif not p.is_empty():
		if p.cant != "":
			warn = "Can't go: %s." % p.cant
			warn_color = UI.BAD
		elif Game.set_off(b):
			warn = "Set off at %s, there %s." % [Game.time_text(p.leave), Game.time_text(p.at)]
			warn_color = UI.TEXT
		else:
			warn = "Sets off %s%s." % [Game.time_text(p.leave), ", won't finish in time" if p.over else ""]
			warn_color = UI.GOLD if p.over else UI.TEXT
	if Game.wants_you(b) > 0.0 and id >= 0:
		warn += (" " if warn else "") + "Wants you."
	if warn != "":
		var w := UI.label(warn, 18, warn_color)
		w.name = "State"
		w.clip_text = true
		lines.add_child(w)
	for c: Control in lines.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who.custom_minimum_size.y = 26.0 * lines.get_child_count() + 12.0
	var can_pick: bool = not planner and not Game.helpers.is_empty() and Game.can_send(b) and not Game.set_off(b)
	who.disabled = not can_pick
	if can_pick:
		who.pressed.connect(_pick_who.bind(b, who))
	row.add_child(who)
	if id >= 0:
		var kit: String = p.get("kit", "")
		var pick: String = b.get("kit", "")
		var why := "best free" if pick == "" else ("your pick" if kit == pick or kit == "" else "%s not free" % _mower_word(pick).to_lower())
		var mower := UI.button("%s\n(%s)" % [_mower_word(kit if kit != "" else pick), why], func() -> void:
			Game.set_job_kit(b, _next_kit(pick))
			_build(row.name)
			UI.focus(find_child(row.name, true, false).find_child("Mower", true, false)), 18)
		mower.name = "Mower"
		mower.custom_minimum_size.x = MOWER_W
		mower.disabled = planner or Game.set_off(b)
		row.add_child(mower)
	else:
		var yours := UI.label("You pack it", 18, UI.DIM)
		yours.custom_minimum_size.x = MOWER_W
		yours.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		yours.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(yours)
	var line := DayLine.new()
	line.b = b
	line.plan = p
	line.color = _who_color(id)
	line.today = _open_day == Game.day
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line)
	return row


func _mower_word(kind: String) -> String:
	return {"": "Any mower", "push": "Push", "petrol": "Petrol", "rideon": "Ride-on"}.get(kind, kind)


## The mower after `kind` for a booking's pick: the best free (""), then each kind the crew
## can take (one not marked yours).
func _next_kit(kind: String) -> String:
	var kinds: Array[String] = [""]
	for k: String in ["push", "petrol", "rideon"]:
		if Game.total(k) - Game.mine.get(k, 0) > 0:
			kinds.append(k)
	return kinds[(kinds.find(kind) + 1) % kinds.size()]


## How a booking of yours today stands, in words and a colour.
func _state(b: Dictionary) -> Array:
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


## Who goes to a booking, picked from a list beside it: you, then each helper with what
## matters for this one (free or out, on time or late, wants you; can't go in red). B shuts it.
func _pick_who(b: Dictionary, from: Button) -> void:
	_close_pick()
	var box := UI.vbox(6)
	var you := UI.button("You\n" + _your_facts(b), func() -> void: _picked(b, -1), 18)
	you.add_theme_color_override("font_color", UI.GOLD)
	box.add_child(you)
	for h: Dictionary in Game.helpers:
		var facts := _helper_facts(b, h)
		var pick := UI.button(h.name + "\n" + facts[0], func() -> void: _picked(b, h.id), 18)
		pick.add_theme_color_override("font_color", _who_color(h.id))
		pick.add_theme_color_override("font_disabled_color", UI.BAD)
		pick.disabled = facts[1]
		box.add_child(pick)
	for c: Button in box.find_children("*", "Button", true, false):
		c.alignment = HORIZONTAL_ALIGNMENT_LEFT
		c.custom_minimum_size.x = 560
	for w: Button in find_children("Who", "Button", true, false):
		w.set_meta("picking", w == from)
	for c: Control in find_children("*", "BaseButton", true, false): # the list's the only thing the cursor can be on
		if c.focus_mode != Control.FOCUS_NONE:
			c.set_meta("focus_was", c.focus_mode)
			c.focus_mode = Control.FOCUS_NONE
	_pick = ColorRect.new() # the shade: a click off the list shuts it
	_pick.name = "Shade"
	(_pick as ColorRect).color = Color(0, 0, 0, 0.35)
	_pick.top_level = true
	_pick.size = get_viewport_rect().size
	_pick.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			var row := _pick_row()
			_close_pick()
			UI.focus(row))
	add_child(_pick)
	var panel := UI.panel(box)
	panel.name = "WhoMenu"
	_pick.add_child(panel)
	panel.position = Vector2(minf(from.global_position.x + from.size.x + 8.0, 1280.0 - 600.0), clampf(from.global_position.y, 20.0, 400.0))
	var on := box.get_child(Game.helpers.find(Game.helper(b.get("helper", -1))) + 1) as Button
	UI.focus(on if on and not on.disabled else you)


## The Who button the open list was for, to go back to.
func _pick_row() -> Control:
	for b: Button in find_children("Who", "Button", true, false):
		if b.has_focus() or b.get_meta("picking", false):
			return b
	return null


func _picked(b: Dictionary, id: int) -> void:
	Game.assign(b, id)
	_close_pick()
	_build("job_%d_%d" % [_open_day, b.get("seed", 0)])


func _close_pick() -> void:
	if _pick:
		if _pick.get_parent(): # out at once: the next one takes its name
			_pick.get_parent().remove_child(_pick)
		_pick.queue_free()
		_pick = null
		for c: Control in find_children("*", "BaseButton", true, false):
			if c.has_meta("focus_was"):
				c.focus_mode = c.get_meta("focus_was")
				c.remove_meta("focus_was")


## Your facts for a booking: today how it stands; another day, a clash with your others.
func _your_facts(b: Dictionary) -> String:
	if b.day == Game.day:
		return _state(b)[0]
	for o: Dictionary in Game.bookings(b.day):
		if o != b and o.has("seed") and not o.has("helper") and o.from < b.by and b.from < o.by:
			return "Clashes with %s, %s to %s." % [o.customer, Game.time_text(o.from), Game.time_text(o.by)]
	return "Free then."


## A helper's facts for a booking, as if they went: [words, can't go]. Out now, when they'd
## set off and whether late, wants you, how good.
func _helper_facts(b: Dictionary, h: Dictionary) -> Array:
	var was: Variant = b.get("helper")
	var sent: Variant = b.get("sent_at")
	b.helper = h.id
	if b.day == Game.day:
		b.sent_at = Game.minute
	var p: Dictionary = Game.crew_plan(b.day).get(b.seed, {})
	for k: String in ["helper", "sent_at"]:
		b.erase(k)
	if was != null:
		b.helper = was
	if sent != null:
		b.sent_at = sent
	if p.is_empty():
		return ["", true]
	if p.cant != "":
		return ["Can't go: %s." % p.cant, true]
	var bits: Array[String] = []
	var back := Game.out_till(h.id) if b.day == Game.day else -1
	if back >= 0:
		bits.append("Out till %s." % Game.time_text(back))
	bits.append("Sets off %s, %s." % [Game.time_text(p.leave), "won't finish in time" if p.over else "done in time"])
	if Game.wants_you(b) > 0.0:
		bits.append("Wants you.")
	bits.append(Game.card_text(h).capitalize() + ".")
	return [" ".join(bits), false]



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


## The paper (design doc, The hub, redesigned): The Weekly Advertiser, picked up off the
## table, a little askew. Three columns of newsprint: filler as grey bars, ads you'd never
## ring faded, and what's worth acting on circled in red pen (faintly if you can't yet).
## Pages: the front page (the week's news and Vince's standing ad), the gardening
## classifieds, situations wanted. The directions move between circles, past a page's edge
## or the shoulders turn it, A rings: the call's a short talk in the portrait box.
func _paper_view(root: Control) -> Control:
	var pages := _paper_page_list()
	_page = clampi(_page, 0, pages.size() - 1)
	var sheet := PanelContainer.new()
	sheet.name = "Sheet"
	var news := StyleBoxFlat.new()
	news.bg_color = NEWSPRINT
	news.border_color = Color("b8ac8c")
	news.set_border_width_all(2)
	news.set_content_margin_all(18)
	sheet.add_theme_stylebox_override("panel", news)
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.rotation = deg_to_rad(-0.5) # picked up off the table
	sheet.resized.connect(func() -> void: sheet.pivot_offset = sheet.size / 2.0)
	root.add_child(sheet)
	var col := UI.vbox(4)
	sheet.add_child(col)
	var mast := _ink("THE WEEKLY ADVERTISER", INK, 44)
	mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(mast)
	var out := Game.day # it came out last Friday, or with the season
	var opened := Game.day_of(Game.year, Game.start_month, 1)
	while Game.date(out).weekday != Game.FRIDAY and out > opened:
		out -= 1
	var dated := _ink("%s        %s        10p" % [Game.date_text(out), {"front": "Front page", "wanted": "Situations wanted"}.get(pages[_page],
		"Classifieds: gardening")], Color("5a4a38"), 16)
	dated.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(dated)
	col.add_child(_rule())
	var body := UI.hbox(18)
	body.name = "Columns"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	var cols: Array[VBoxContainer] = []
	for i in 3:
		var c := UI.vbox(8)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_stretch_ratio = 1.0
		body.add_child(c)
		cols.append(c)
	var seed_from: int = out * 31 + _page # the same filler for the week's page
	match pages[_page]:
		"front":
			_front_page(cols, seed_from)
		"wanted":
			_wanted_page(cols, seed_from)
		_:
			_ads_page(cols, int(pages[_page].trim_prefix("ads:")), seed_from)
	col.add_child(_rule())
	var nav := UI.hbox(14)
	var prev := UI.button("< %s" % Game.key("gear_down"), _turn_page.bind(-1), 18)
	prev.name = "PrevPage"
	prev.disabled = _page == 0
	prev.focus_mode = Control.FOCUS_NONE if prev.disabled else Control.FOCUS_ALL
	nav.add_child(prev)
	var where := _ink("Page %d of %d.   A call takes %d min." % [_page + 1, pages.size(), Game.RING_TIME], Color("5a4a38"), 16)
	where.clip_text = false
	where.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(where)
	var next := UI.button("%s >" % Game.key("gear_up"), _turn_page.bind(1), 18)
	next.name = "NextPage"
	next.disabled = _page >= pages.size() - 1
	next.focus_mode = Control.FOCUS_NONE if next.disabled else Control.FOCUS_ALL
	nav.add_child(next)
	if _call != "": # what the last one you rang said
		var said := _ink("   Last call: " + _call, Color("7a1c14"), 16)
		said.name = "Call"
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(said)
	col.add_child(nav)
	# Up and down stay in a column: the ad above or below, the header at the top, the page's buttons at the foot.
	var foot: Control = next if not next.disabled else prev
	for c: Node in body.get_children():
		var stops: Array = c.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return not b.disabled)
		for i in stops.size():
			var b: Button = stops[i]
			b.focus_neighbor_top = b.get_path_to(stops[i - 1] if i > 0 else find_child("Away", true, false))
			b.focus_neighbor_bottom = b.get_path_to(stops[i + 1] if i < stops.size() - 1 else foot)
	for a: Node in sheet.find_children("*", "Button", true, false):
		if a is PaperAd and a.circle > 0 and not a.disabled:
			return a
	return next if not next.disabled else (prev if not prev.disabled else find_child("Away", true, false))


## The paper's pages: the front, the classifieds six to a page, situations wanted.
func _paper_page_list() -> Array[String]:
	var out: Array[String] = ["front"]
	var n := _paper_ads().size()
	for i in maxi(1, ceili(n / float(PER_PAGE))):
		out.append("ads:%d" % i)
	out.append("wanted")
	return out


## This week's ads still to come (a day gone, its ad's gone).
func _paper_ads() -> Array:
	return Game.paper.filter(func(o: Dictionary) -> bool: return o.day >= Game.day)


func _paper_pages() -> int:
	return _paper_page_list().size()


func _turn_page(by: int) -> void:
	var to := _page + by
	if to < 0 or to >= _paper_pages():
		return
	_page = to
	_build()


## The front page: the week's news (only what the game knows: Game.front_page) across two
## columns, Vince's standing ad and what's inside in the third.
func _front_page(cols: Array[VBoxContainer], seed_from: int) -> void:
	cols[0].size_flags_stretch_ratio = 2.0
	var news := Game.front_page()
	var colours := {"bad": Color("8a2018"), "event": INK, "good": Color("2e6a1e"), "dim": Color("5a4a38")}
	for i in news.size():
		var n: Array = news[i]
		var head := _ink(n[0], colours[n[2]], 34 if i == 0 else 26)
		head.clip_text = false
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cols[0].add_child(head)
		var story := _ink(n[1], INK, 18)
		story.clip_text = false
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if n[2] == "event" and n[1].begins_with("Today"):
			story.name = "News" # today's news (NOTES 216)
		cols[0].add_child(story)
		cols[0].add_child(_filler(seed_from + i, 3))
	cols.pop_at(1).queue_free() # the news takes two
	var side := cols[1]
	var shark := PaperAd.new()
	shark.name = "Vince"
	_ad_look(shark, "CASH LOANS", "No questions asked. Ask for Vince." + (" He has an offer for you." if Game.shark_offer else ""), 2)
	shark.pressed.connect(_ring_vince)
	side.add_child(shark)
	side.add_child(_filler(seed_from + 7, 4))
	var ads_n := _paper_ads().filter(func(o: Dictionary) -> bool: return Game.cant_book(o) == "" and not o.get("refused", false)).size()
	var inside := _ink("INSIDE\n%d ad%s to ring, %d situation%s wanted." % [ads_n, "" if ads_n == 1 else "s", Game.wanted.size(),
		"" if Game.wanted.size() == 1 else "s"], INK, 18)
	inside.clip_text = false
	inside.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(inside)
	side.add_child(_dead_ad(seed_from + 3))
	side.add_child(_filler(seed_from + 9, 5))


## A page of the gardening classifieds: six ads across the columns, filler and faded ads between.
func _ads_page(cols: Array[VBoxContainer], at: int, seed_from: int) -> void:
	var ads := _paper_ads().slice(at * PER_PAGE, (at + 1) * PER_PAGE)
	cols[0].add_child(_ink("GARDENING", INK, 24))
	for i in ads.size():
		var c := cols[i % 3]
		if i < 3 and i > 0:
			c.add_child(_filler(seed_from + i, 2))
		c.add_child(_ad(ads[i]))
	if ads.is_empty():
		cols[0].add_child(_ink("Nothing else in this week's paper.", Color("7a6a50"), 18))
	for i in 3:
		cols[i].add_child(_dead_ad(seed_from + 11 * i))
		cols[i].add_child(_filler(seed_from + 5 + i, 4))


## Situations wanted: who's after work this week, faintly circled till you've a staff room.
func _wanted_page(cols: Array[VBoxContainer], seed_from: int) -> void:
	cols[0].add_child(_ink("SITUATIONS WANTED", INK, 24))
	for i in Game.wanted.size():
		cols[i % 3].add_child(_wanted(Game.wanted[i]))
	if Game.wanted.is_empty():
		cols[0].add_child(_ink("Nobody this week.", Color("7a6a50"), 18))
	for i in 3:
		cols[i].add_child(_filler(seed_from + i, 3))
		cols[i].add_child(_dead_ad(seed_from + 7 * i + 1))


## A classified: the ad's words, circled if you can ring it; booked, refused or out of reach
## says why, uncircled. A rings.
func _ad(o: Dictionary) -> Control:
	var a := PaperAd.new()
	a.name = "Ad"
	a.add_to_group("paper_ad")
	var text: String = Game.ad_text(o)
	var busy := Game.jobs_on(o.day)
	if busy > 0:
		text += " You've %d job%s that day." % [busy, "" if busy == 1 else "s"]
	var why := Game.cant_book(o)
	if o.get("refused", false):
		text += " NO: %s" % o.reply
	elif why != "":
		text += " %s." % why
	_ad_look(a, "", _plain(text), 0 if o.get("refused", false) or why != "" else 2) # the ad's own words lead
	a.disabled = a.circle == 0
	if a.disabled:
		a.focus_mode = Control.FOCUS_NONE # nothing to do there: the cursor passes it by
	a.pressed.connect(_ring_ad.bind(o))
	return a


## A situation wanted: who, how quick and careful (in words and out of ten), the wage. Circled
## faintly if you can't take anyone on (the call says why).
func _wanted(w: Dictionary) -> Control:
	var a := PaperAd.new()
	a.name = "Wanted"
	var pace: String = "Steady rather than quick" if w.pace < 0.65 else ("Reasonably quick" if w.pace < 0.85 else "A quick worker")
	var care: String = "not fussy" if w.care < 0.4 else ("tidy" if w.care < 0.7 else "careful, takes a pride")
	_ad_look(a, "SITUATION WANTED", "%s seeks gardening work. %s (%d/10), %s (%d/10). $%d a week. Ring %s." % [w.name, pace, roundi(w.pace * 10.0), care,
		roundi(w.care * 10.0), w.wage, w.name.split(" ")[0]], 1 if Game.cant_hire() != "" else 2)
	a.pressed.connect(_ring_wanted.bind(w))
	return a


## An ad's words on newsprint, boxed: a heading in capitals, then the rest; `circle`: 0 none,
## 1 faint (can't yet), 2 red pen.
func _ad_look(a: PaperAd, head: String, words: String, circle: int) -> void:
	a.circle = circle
	a.custom_minimum_size.x = 120
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.text = words if head == "" else "%s\n%s" % [head, words]
	a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	a.alignment = HORIZONTAL_ALIGNMENT_LEFT
	a.add_theme_font_size_override("font_size", UI.px(16))
	for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		a.add_theme_color_override(c, INK)
	a.add_theme_color_override("font_disabled_color", Color(INK, 0.6))
	a.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 0.04) if state in ["hover", "focus"] else Color(0, 0, 0, 0)
		box.border_color = Color(INK, 0.5)
		box.set_border_width_all(1)
		box.set_content_margin_all(6)
		a.add_theme_stylebox_override(state, box)


## Text without the paper's colour tags (an ad's words, for a button).
func _plain(t: String) -> String:
	var r := RegEx.new()
	r.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	return r.sub(t, "", true)


## An ad nobody would ring, faded: the paper's texture.
func _dead_ad(n: int) -> Control:
	var l := _ink(DEAD_ADS[posmod(n, DEAD_ADS.size())], Color(INK, 0.5), 15)
	l.clip_text = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = Color(INK, 0.25)
	box.set_border_width_all(1)
	box.set_content_margin_all(6)
	var p := UI.panel(l)
	p.add_theme_stylebox_override("panel", box)
	return p


## Lines of print nobody reads: grey bars.
func _filler(n: int, lines: int) -> Control:
	var f := Control.new()
	f.custom_minimum_size.y = lines * 9.0
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.draw.connect(func() -> void:
		var r := RandomNumberGenerator.new()
		r.seed = n
		for i in lines:
			var w := f.size.x * (r.randf_range(0.55, 1.0) if i < lines - 1 else r.randf_range(0.25, 0.6))
			f.draw_rect(Rect2(0, i * 9.0 + 2.0, w, 4.0), Color("b4b2a9")))
	return f


func _rule() -> Control:
	var r := ColorRect.new()
	r.custom_minimum_size.y = 2
	r.color = Color(INK, 0.6)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Ringing a classified: they pick up, say what it is; you book it or don't. Booking asks
## them (Game.ring: the call's time, and yes or no by your name).
func _ring_ad(o: Dictionary) -> void:
	_dial()
	_talk(o.customer, o.get("look", {}), [_hello(o), "About the lawn: %s, %s to %s. $%d." % [Game.day_word(o.day), Game.time_text(o.from),
		Game.time_text(o.by), o.pay]], [["Book it", func() -> void:
			_call = Game.ring(o)
			_charged = true
			_talk(o.customer, o.get("look", {}), [_call], [["Bye", _hang_up]])], ["Never mind", _hang_up]])


## How a customer picks up, by who they are.
func _hello(o: Dictionary) -> String:
	match o.get("persona", ""):
		"grump":
			return "\"What.\""
		"vicar":
			return "\"St. Swithin's, the vicarage. Bless you for calling.\""
		"toff":
			return "\"%s residence.\"" % o.customer.split(" ")[-1]
	return "\"Hello? %s speaking.\"" % o.customer


## Ringing a situation wanted: who they are; you take them on or don't. With nowhere for staff,
## they say so; with no van, they'd wait on the wage, and say that too.
func _ring_wanted(w: Dictionary) -> void:
	_dial()
	var r := RandomNumberGenerator.new()
	r.seed = int(w.id)
	var look := {"hair_style": r.randi() % 5, "skin": r.randi() % 5, "hair": r.randi() % 6, "shirt": r.randi() % 6}
	var lines: Array[String] = ["\"%s speaking.\"" % w.name.split(" ")[0], "\"Gardening work? I can start Monday. $%d a week.\"" % w.wage]
	var why := Game.cant_hire()
	if why != "":
		lines.append("\"%s\"" % ("Where would I work out of? Ring back when you've a staff room." if Game.staff_room == "" else
			"Sounds like you're full up. Ring back when there's a seat."))
		_talk(w.name, look, lines, [["Not now", _hang_up]])
		return
	if Game.vans == 0:
		lines.append("\"You've a van for me? No? I'll wait about on the wage till you have.\"")
	_talk(w.name, look, lines, [["You're hired", func() -> void:
		_call = Game.hire(w)
		_charged = true
		_talk(w.name, look, [_call], [["Bye", _hang_up]])], ["Not now", _hang_up]])


## Ringing Vince's ad: his offer if it stands, else a word.
func _ring_vince() -> void:
	_dial()
	var lines: Array[String] = ["\"Vince.\""]
	var replies: Array = []
	if Game.shark_offer and Game.premises + 1 < Game.PREMISES.size():
		var nx: Dictionary = Game.PREMISES[Game.premises + 1]
		lines.append("\"You've outgrown that place. I'll front the $%d for %s. Usual terms: my vig, every Friday.\"" % [nx.deposit, nx.name.to_lower()])
		replies = [["Take it", func() -> void:
			var taken := Game.take_shark_offer()
			_talk("Vince", SHARK_LOOK, ["\"Pleasure doing business. See you Friday.\"" if taken else "\"Your stuff won't fit. Sort it out.\""], [["Bye", _hang_up]])],
			["Not now", _hang_up]]
	elif Game.principal > 0:
		lines.append("\"You still owe me $%d. Friday. Don't make me send someone.\"" % Game.principal)
		replies = [["Bye", _hang_up]]
	else:
		lines.append("\"Come back when you're ready to grow.\"")
		replies = [["Bye", _hang_up]]
	_talk("Vince", SHARK_LOOK, lines, replies)


## A call starts: where you rang from (the page, and which of its circled ads), to come
## back to; its time's owed till something you said took it (a booking, a hire).
func _dial() -> void:
	var pages := _paper_page_list()
	_rang_from = pages[clampi(_page, 0, pages.size() - 1)]
	var ads := _circled()
	_rang_at = maxi(0, ads.find(get_viewport().gui_get_focus_owner()))
	_charged = false
	_ringing = true


## The page's ads you can act on, in order.
func _circled() -> Array:
	return find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
		return b is PaperAd and (b as PaperAd).circle > 0 and not (b as Button).disabled and not b.is_queued_for_deletion())


## Put the phone down: the call's time if nothing you said took it; back on the page you
## rang from (not past the classifieds into situations wanted, if a booking took the last
## ad off it), the cursor on the ad you rang or the nearest.
func _hang_up() -> void:
	_close_pick()
	if _ringing and not _charged:
		Game.minute += Game.RING_TIME
	_ringing = false
	var pages := _paper_page_list()
	if _rang_from.begins_with("ads") and _page < pages.size() and pages[_page] == "wanted" and _page > 1:
		_page -= 1
	_build()
	var ads := _circled()
	if not ads.is_empty():
		UI.focus(ads[mini(_rang_at, ads.size() - 1)])


## A talk in the portrait box (the job's: their face, their name, what they say, a word at a
## time; your replies the real choices). Over the paper, the cursor kept in it; B hangs up.
func _talk(who: String, look: Dictionary, lines: Array, replies: Array, back := Callable()) -> void:
	_close_pick()
	_talk_back = back if back.is_valid() else _hang_up
	var row := UI.hbox(18)
	if not look.is_empty():
		var f := Face.new()
		f.custom_minimum_size = Vector2(132, 132)
		f.set_look(look)
		f.talking = true
		row.add_child(f)
	var col := UI.vbox(8)
	col.custom_minimum_size.x = 640
	col.add_child(UI.label(who, 28, UI.GOLD))
	var said := UI.label("\n".join(lines), 20)
	said.name = "Said"
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.visible_ratio = 0.0
	col.add_child(said)
	var tw := create_tween()
	tw.tween_property(said, "visible_ratio", 1.0, 0.03 * said.text.length())
	var answers := UI.hbox(12)
	for r: Array in replies:
		var b := UI.button(r[0], r[1], 20)
		b.name = "Reply"
		answers.add_child(b)
	col.add_child(answers)
	row.add_child(col)
	for c: Control in find_children("*", "BaseButton", true, false): # the talk's the only thing the cursor can be on
		if c.focus_mode != Control.FOCUS_NONE:
			c.set_meta("focus_was", c.focus_mode)
			c.focus_mode = Control.FOCUS_NONE
	_pick = ColorRect.new()
	_pick.name = "Talk"
	(_pick as ColorRect).color = Color(0, 0, 0, 0.45)
	_pick.top_level = true
	_pick.size = get_viewport_rect().size
	add_child(_pick)
	var panel := UI.panel(row)
	panel.name = "TalkBox"
	_pick.add_child(panel)
	panel.position = Vector2(40, 720 - 260)
	panel.custom_minimum_size.x = 1200
	UI.focus(answers.get_child(0))


## The client book on the desk (design doc, The hub, redesigned): inside the cover your name
## and an index of your regulars, each with a dot for their mood; A on one opens their page.
func _book_view(root: Control) -> Control:
	if _client >= 0 and Game.regulars.has(_client):
		return _client_page(root, _client)
	_client = -1
	var side := ScrollContainer.new() # a long list of regulars scrolls, following the cursor
	side.follow_focus = true
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(side)
	var list := UI.vbox(6)
	list.name = "Index"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(list)
	var trend := Game.rep_trend - Game.reputation
	var arrow := "  (rising)" if trend > 3.0 else ("  (sliding)" if trend < -3.0 else "")
	list.add_child(UI.label("Your name: %s%s" % [UI.rep_word(Game.reputation), arrow], 22,
		UI.GOOD if Game.reputation >= 45.0 else (UI.GOLD if Game.reputation >= 20.0 else UI.BAD)))
	list.add_child(UI.label(("Owed the shark: $%d" % Game.principal if Game.principal > 0 else "Free of the shark")
		+ ("   Record: %d" % roundi(Game.record) if Game.record > 0.0 else ""), 20, UI.DIM))
	list.add_child(UI.label("Your regulars (%d)" % Game.regulars.size(), 22))
	if Game.regulars.is_empty():
		list.add_child(UI.label("None yet. A good job from the paper might earn one.", 18, UI.DIM))
	for id: int in Game.regulars:
		var reg: Dictionary = Game.regulars[id]
		var row := UI.hbox(12)
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(14, 14)
		dot.color = _mood_color(reg.mood)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var b := UI.button("%s   %s, %s to %s   $%d" % [reg.job.customer, _every(reg), Game.time_text(reg.job.from), Game.time_text(reg.job.by), reg.rate],
			func() -> void:
				_client = id
				_build(), 18)
		b.name = "Client"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		list.add_child(row)
	for b: Button in list.find_children("*", "Button", true, false):
		return b
	return find_child("Away", true, false)


## A regular's page: their face, how often and when, what they pay, how they feel, what's
## paid up front, the next visit; dropping them. The shoulders turn the pages, B is the index.
func _client_page(root: Control, id: int) -> Control:
	var reg: Dictionary = Game.regulars[id]
	var ids := Game.regulars.keys()
	var at := ids.find(id)
	var top := UI.hbox(14)
	var prev := UI.button("< " + Game.key("gear_down"), _turn_client.bind(-1), 18)
	prev.name = "PrevClient"
	prev.disabled = at <= 0
	top.add_child(prev)
	top.add_child(UI.label("%d of %d" % [at + 1, ids.size()], 18, UI.DIM))
	var next := UI.button(Game.key("gear_up") + " >", _turn_client.bind(1), 18)
	next.name = "NextClient"
	next.disabled = at >= ids.size() - 1
	top.add_child(next)
	var index := UI.button("The index " + Game.key("hop"), func() -> void:
		_client = -1
		_build(), 18)
	index.name = "BookIndex"
	top.add_child(index)
	root.add_child(top)
	var page := UI.hbox(24)
	var face := Face.new()
	face.custom_minimum_size = Vector2(160, 160)
	face.set_look(reg.job.get("look", {}))
	face.expression = "delighted" if reg.mood >= 85.0 else ("happy" if reg.mood >= 70.0 else ("neutral" if reg.mood >= 45.0 else "annoyed"))
	page.add_child(face)
	var col := UI.vbox(6)
	col.add_child(UI.label(reg.job.customer, 30, UI.GOLD))
	var lines: Array[String] = ["How often: %s." % _every(reg), "When: %s to %s." % [Game.time_text(reg.job.from), Game.time_text(reg.job.by)],
		"Pays: $%d a visit." % reg.rate, "Mood: %s." % Game.mood_word(reg.mood), "Visits so far: %d." % reg.get("visits", 0)]
	if reg.get("prepaid", 0) > 0:
		lines.append("Paid up front: %d visit%s still owed." % [reg.prepaid, "" if reg.prepaid == 1 else "s"])
	var nxt := -1
	for d: int in Game.calendar.keys():
		if d >= Game.day and (nxt < 0 or d < nxt) and Game.bookings(d).any(func(b: Dictionary) -> bool: return b.get("regular", -1) == id):
			nxt = d
	lines.append("Next visit: %s." % (Game.date_text(nxt) if nxt >= 0 else "none booked"))
	for l: String in lines:
		col.add_child(UI.label(l, 20))
	var owed := roundi(reg.get("prepaid", 0) * reg.get("prepaid_each", 0.0))
	var drop := UI.button("Drop them" + (" (owe $%d)" % owed if owed > 0 else ""), func() -> void:
		Game.drop(id)
		_client = -1
		_build(), 18)
	drop.name = "Drop"
	var holder := HBoxContainer.new()
	holder.add_child(drop)
	col.add_child(holder)
	page.add_child(col)
	root.add_child(UI.panel(page))
	return next if not next.disabled else index


func _turn_client(by: int) -> void:
	var ids := Game.regulars.keys()
	var at := ids.find(_client) + by
	if at >= 0 and at < ids.size():
		_client = ids[at]
		_build()


## How often a regular wants you, in words.
func _every(reg: Dictionary) -> String:
	var every: String = {7: "weekly", 14: "fortnightly", 28: "four-weekly"}.get(reg.cadence, "every %d days" % reg.cadence)
	if Game.cadence_now(reg) < reg.cadence:
		every += " (more in summer)"
	return every


func _mood_color(m: float) -> Color:
	return UI.GOOD if m >= 70.0 else (UI.GOLD if m >= 45.0 else UI.BAD)


func _save_and_quit() -> void:
	if planner:
		get_parent().get_parent().set("_leaving", true) # the premises: nothing more of theirs
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
	elif _view == "paper" and _pick == null and edge_turns and (c is PaperAd or String(c.name) in ["PrevPage", "NextPage"]): # past the page's edge: turn it
		_turn_page(dir)
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	var leave := find_child("Quit", true, false) as Button
	var day_open := leave != null and _view == "calendar" and not _cal_month
	if _pick and _pick.name == "Talk" and (event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel")): # hang up
		get_viewport().set_input_as_handled()
		_talk_back.call()
	elif _pick and (event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel")): # shut the who-goes list
		var row := _pick_row()
		_close_pick()
		UI.focus(row)
		get_viewport().set_input_as_handled()
	elif _pick and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled() # the list's open: nothing else
	elif planner and (event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")): # put the planner away
		get_viewport().set_input_as_handled()
		closed.emit()
	elif leave and _view == "book" and _client >= 0 and event.is_action_pressed("hop"): # a client's page, back to the index
		get_viewport().set_input_as_handled()
		_client = -1
		_build()
	elif leave and _view == "book" and _client >= 0 and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down")):
		get_viewport().set_input_as_handled()
		_turn_client(1 if event.is_action_pressed("gear_up") else -1)
	elif day_open and event.is_action_pressed("hop"): # the day, up to its month
		get_viewport().set_input_as_handled()
		_to_month()
	elif day_open and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down")): # the day, along
		get_viewport().set_input_as_handled()
		_step_day(1 if event.is_action_pressed("gear_up") else -1)
	elif leave and event.is_action_pressed("pause"):
		UI.focus(leave)
		get_viewport().set_input_as_handled()
	elif leave and event.is_action_pressed("hop") and not (find_child("Away", true, false) as Button).disabled: # away from the desk
		get_viewport().set_input_as_handled() # first: leaving takes the board out of the tree
		_away()
	elif leave and (event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down")):
		var step := 1 if event.is_action_pressed("gear_up") else -1
		if _view == "paper":
			_turn_page(step)
		get_viewport().set_input_as_handled()


## Playtest cheats, debug builds only: [1] adds $500, [2] adds 20 reputation and [4]
## takes 20 off (both reprint the paper), [3] skips to payday. No function keys: the editor owns them.
func _unhandled_key_input(event: InputEvent) -> void:
	if planner or not (OS.is_debug_build() and event is InputEventKey and event.pressed):
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
		Game.day_end.missed = [] # not counted against you
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
	if planner:
		closed.emit()
		return
	Game.place = "home"
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
	_centred(col, "Rent and food: $%d.%s You have $%d." % [Game.living(), " Wages: $%d." % Game.wages() if Game.helpers else "", Game.money], 26, UI.GOOD if Game.money >= due else UI.BAD)
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
			var keep := "$%d rent and food%s" % [Game.living(), " + $%d wages" % Game.wages() if Game.helpers else ""]
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
	_centred(col, "He counts it twice." if r.paid > Game.living() else "Paid up.", 40, UI.GOLD)
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
	var read := _centred_button(col, "Read the paper", _ready)
	if not Game.shark_offer:
		UI.focus(read)
		return
	var nx: Dictionary = Game.PREMISES[Game.premises + 1] # his man has a word anyway
	var not_now := func() -> void:
		_close_pick()
		UI.focus(read)
	_talk("The shark's man", SHARK_LOOK, ["\"You've outgrown that place.\"", "\"Vince'll front the $%d for %s. His usual terms. The offer stands: ring him.\"" % [
		nx.deposit, nx.name.to_lower()]], [["Take it now", func() -> void:
			Game.take_shark_offer()
			_close_pick()
			_ready()], ["Not now", not_now]], not_now)


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


## The day's end (design doc, The hub, redesigned): a card a job in the day's order, yours
## and the crew's together (who, where, the net, a word if something happened; A opens the
## full report), the jobs nobody went to, a helper's raise ask as a card of its own, then a
## card adding it all up: the jobs, what you bought and sold, today, what you have, Friday's
## bill and what it leaves.
func _day_end() -> void:
	var e: Dictionary = Game.day_end
	var col := _screen()
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 8)
	var top := Control.new()
	top.custom_minimum_size.y = 12
	col.add_child(top)
	_centred(col, "DAY'S END", 34, UI.GOLD)
	_centred(col, Game.date_text(e.day), 20, UI.DIM)
	var scroll := ScrollContainer.new() # a busy day scrolls, following the cursor
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	var list := UI.vbox(6)
	list.name = "Cards"
	list.custom_minimum_size.x = CARD_W
	holder.add_child(list)
	var cards := _day_cards(e)
	var jobs_net := 0
	for i in cards.size():
		var c: Dictionary = cards[i]
		jobs_net += c.net
		list.add_child(_day_card(c, i))
	if cards.is_empty():
		list.add_child(UI.label("A free day: no jobs.", 20, UI.DIM))
	var first: Button = null
	for h: Dictionary in Game.helpers: # a raise asked: a card of its own, answered here
		if not h.has("asks"):
			continue
		var row := UI.hbox(12)
		var ask := UI.label("%s asks for $%d a week (now $%d). %s." % [h.name.split(" ")[0], h.asks, h.wage, UI.sentence(Game.card_text(h))], 20, UI.GOLD)
		ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(ask)
		var yes := UI.button("Pay it", func() -> void:
			Game.answer_raise(h.id, true)
			_day_end(), 20)
		yes.name = "PayRaise"
		row.add_child(yes)
		row.add_child(UI.button("No", func() -> void:
			Game.answer_raise(h.id, false)
			_day_end(), 20))
		list.add_child(UI.panel(row))
		if first == null:
			first = yes
	# The sum of it.
	var sum := UI.vbox(2)
	sum.name = "Summary"
	var today: int = e.now - e.was
	_sum_line(sum, "The jobs", jobs_net)
	var rest := today - jobs_net
	for l: Array in e.get("ledger", []):
		_sum_line(sum, l[0], l[1])
		rest -= int(l[1])
	if rest != 0: # fines, court, what the heavies took: whatever else moved the money
		_sum_line(sum, "Everything else", rest)
	_sum_line(sum, "Today", today, true)
	_sum_line(sum, "You have", Game.money, false, false)
	var due := Game.due()
	var bill := "rent and food $%d" % Game.living()
	if not Game.helpers.is_empty():
		bill += ", wages $%d" % Game.wages()
	if Game.principal > 0:
		bill += ", the vig $%d" % Game.vig()
	_sum_line(sum, "%s: %s" % ["Payday" if Game.payday_pending else "Friday", bill], -due)
	_sum_line(sum, "That leaves", Game.money - due, true, false)
	var go := UI.button("Payday" if Game.payday_pending else ("The winter" if Game.winter_pending else "Next day"), func() -> void:
		Game.day_end = {}
		Game.missed.clear()
		_open_card = -1
		_card_at = -1
		Game.save()
		_ready(), 22)
	go.name = "NextDay"
	var right := HBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(go)
	sum.add_child(right)
	list.add_child(UI.panel(sum))
	UI.focus(list.get_child(_card_at) if _card_at >= 0 and _card_at < cards.size() else (first if first else go))


## The day's jobs as cards, in the day's order: yours, the crew's, and those nobody went to.
func _day_cards(e: Dictionary) -> Array:
	var cards: Array = []
	for m: Dictionary in e.mine:
		var how: String = {"fired": "fired", "walked": "drove off", "ko": "knocked out", "nicked": "nicked"}.get(m.outcome, "")
		var lines: Array = []
		if m.has("paid"):
			lines.append(["Paid", "$%d" % m.paid])
			if m.tip > 0:
				lines.append(["Tip", "$%d" % m.tip])
			if m.fuel > 0:
				lines.append(["Fuel and repairs", "-$%d" % m.fuel])
			if m.get("damages", 0) > 0:
				lines.append(["Damages", "-$%d" % m.damages])
			var other: int = m.net - m.paid - m.tip + m.fuel + m.get("damages", 0)
			if absi(other) > 1: # a dollar either way is the rounding
				lines.append(["Fines and the rest", _signed(other)])
		lines.append(["Mood", "%s, %d" % [Game.mood_word(m.mood), roundi(m.mood)]])
		if m.has("rep"):
			lines.append(["Reputation", "%+d" % roundi(m.rep)])
		cards.append({"who": "You", "helper": -1, "customer": m.customer, "at": m.get("at", 0), "net": m.net, "flag": how, "lines": lines})
	cards.append_array(e.get("crew_jobs", []))
	for gone: String in e.missed:
		cards.append({"who": "Nobody", "helper": -2, "customer": gone, "at": 1 << 20, "net": 0, "flag": "missed",
			"lines": [["Nobody went", "they'll remember"]]})
	cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)
	return cards


## A job's card: who, where, a word if something happened, the net; A opens its report.
func _day_card(c: Dictionary, i: int) -> Control:
	var b := Button.new()
	b.name = "Card_%d" % i
	b.custom_minimum_size = Vector2(CARD_W, 0)
	b.clip_contents = true
	var box := UI.vbox(2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_right = -12
	box.offset_top = 6
	b.add_child(box)
	var row := UI.hbox(14)
	var who := UI.label(c.who, 20, UI.BAD if c.helper == -2 else _who_color(c.helper))
	who.custom_minimum_size.x = 90
	row.add_child(who)
	var where := UI.label(c.customer, 20)
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	where.clip_text = true
	row.add_child(where)
	if c.flag != "":
		row.add_child(UI.label(c.flag, 18, UI.BAD if c.flag in ["missed", "couldn't go", "fired", "nicked"] else UI.GOLD))
	var net := UI.label(_signed(c.net) if c.net != 0 else "$0", 20, UI.GOOD if c.net > 0 else (UI.BAD if c.net < 0 else UI.DIM))
	net.custom_minimum_size.x = 80
	net.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(net)
	box.add_child(row)
	var open := i == _open_card
	if open:
		for l: Array in c.lines:
			var r := UI.hbox(10)
			var what := UI.label(l[0], 18, UI.DIM)
			what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(what)
			r.add_child(UI.label(l[1], 18))
			box.add_child(r)
	for n: Control in box.find_children("*", "Control", true, false):
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.custom_minimum_size.y = 40.0 + (22.0 * c.lines.size() + 4.0 if open else 0.0)
	b.pressed.connect(func() -> void:
		_open_card = -1 if open else i
		_card_at = i
		_day_end())
	return b


## A line of the sum: what, and the money (signed, or `plain`), bold for a total.
func _sum_line(box: Control, what: String, money: int, total := false, signed := true) -> void:
	var r := UI.hbox(10)
	var l := UI.label(what, 20 if total else 18, UI.TEXT if total else UI.DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_child(l)
	var m := UI.label(_signed(money) if signed else ("$%d" % money if money >= 0 else "-$%d" % -money), 20 if total else 18,
		UI.GOOD if money > 0 and signed else (UI.BAD if money < 0 else UI.TEXT))
	r.add_child(m)
	if total:
		var line := ColorRect.new()
		line.custom_minimum_size.y = 1
		line.color = UI.PANEL_EDGE
		box.add_child(line)
	box.add_child(r)


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


## A booking's bar on the day's line, 6am to 8pm: its window in who's going's colour, the
## drive before it dashed, a helper's time at it solid; today, the past shaded and now in gold.
## As `axis`, the hours instead.
class DayLine extends Control:
	var axis := false
	var b := {}
	var plan := {}
	var color := Color.WHITE
	var today := false

	func _x(m: int) -> float:
		return clampf(float(m - Game.DAY_START) / (Game.DAY_END - Game.DAY_START), 0.0, 1.0) * size.x

	func _draw() -> void:
		if axis:
			var font := get_theme_default_font()
			for hh in range(6, 21, 2):
				var t: String = Game.time_text(hh * 60)
				var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
				draw_string(font, Vector2(clampf(_x(hh * 60) - w / 2.0, 0.0, size.x - w), 18), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.DIM)
			return
		draw_rect(Rect2(Vector2.ZERO, size), UI.PANEL)
		for hh in range(6, 21, 2):
			draw_line(Vector2(_x(hh * 60), 0), Vector2(_x(hh * 60), size.y), UI.PANEL_EDGE, 1.0)
		var mid := size.y / 2.0
		var at: int = plan.get("at", b.from)
		var leave: int = plan.get("leave", b.from - Game.DRIVE)
		for x in range(int(_x(leave)), int(_x(at)), 6): # the drive, dashed
			draw_line(Vector2(x, mid), Vector2(minf(x + 3.0, _x(at)), mid), UI.TEXT, 2.0)
		draw_rect(Rect2(_x(b.from), mid - 9.0, _x(b.by) - _x(b.from), 18.0), Color(color, 0.45))
		if plan.has("end") and plan.get("cant", "") == "":
			draw_rect(Rect2(_x(at), mid - 9.0, maxf(2.0, _x(plan.end) - _x(at)), 18.0), color)
		if today:
			draw_rect(Rect2(0, 0, _x(Game.minute), size.y), Color(0, 0, 0, 0.35))
			draw_line(Vector2(_x(Game.minute), 0), Vector2(_x(Game.minute), size.y), UI.GOLD, 3.0)
		draw_rect(Rect2(Vector2.ZERO, size), UI.PANEL_EDGE, false, 2.0)


## An ad in the paper: a boxed classified, circled in red pen if it's worth ringing (faintly
## if you can't yet), the circle heavier under the cursor.
class PaperAd extends Button:
	var circle := 0 ## 0 none, 1 faint, 2 red pen

	func _init() -> void:
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func _draw() -> void:
		if circle == 0:
			return
		var r := RandomNumberGenerator.new()
		r.seed = hash(text)
		var c := size / 2.0
		var rad := size / 2.0 * Vector2(1.06, 1.3) + Vector2(4, 4) # round the words, the box's corners poking out
		var start := r.randf_range(0.0, TAU)
		var pts := PackedVector2Array()
		for i in 41: # round once and a bit past, as a pen does
			var t := start + TAU * 1.08 * i / 40.0
			pts.append(c + Vector2(cos(t) * rad.x, sin(t) * rad.y) * (1.0 + r.randf_range(-0.025, 0.025)))
		draw_polyline(pts, Color("c03028", 0.9 if circle == 2 else 0.35), 3.0 if has_focus() else 2.0, true)
