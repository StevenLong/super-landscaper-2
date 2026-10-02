extends Control
## Packing the truck before a job (design doc, Mowers and Equipment: inventory Tetris).
## The cab always holds the push mower; the bed and the trailer are grids. A cursor moves
## over the grids and the tray of kit not on the truck: pick up, turn, drop. Starts as
## you left it last time; "Drive to the job" when done.

const CELL := 64
const BED_AT := Vector2(60, 240)
const TRAILER_AT := Vector2(380, 240)
const TRAY_AT := Vector2(760, 240)
const ROW_H := 44
const COLOURS := {"petrol": Color("c0503a"), "rideon": Color("d8a030"), "can": Color("b02828"), "robot": Color("5e9e4a")}

var zone := "bed" ## where the cursor is: "bed", "trailer" or "tray"
var cell := Vector2i.ZERO ## the cursor's cell in a grid
var row := 0 ## the cursor's row in the tray (the last is "Drive to the job")
var held := {} ## what's in your hands: {kind, turned, from (the packed entry it came from, or empty)}
var _say := "" ## a word on what just happened


func _ready() -> void:
	theme = UI.theme()
	Sfx.music("music_menu")
	var job := Game.next_job if not Game.next_job.is_empty() else Game.today()
	var head := UI.vbox(6)
	head.position = Vector2(40, 24)
	head.add_child(UI.label("PACKING THE TRUCK", 40, UI.GOLD))
	var ad := RichTextLabel.new()
	ad.bbcode_enabled = true
	ad.fit_content = true
	ad.custom_minimum_size.x = 1180
	ad.add_theme_color_override("default_color", Color("2a2420"))
	ad.add_theme_font_size_override("normal_font_size", UI.px(18))
	ad.text = "Community service: %s's churchyard." % job.customer if job.has("service") else Game.ad_text(job)
	var paper := StyleBoxFlat.new() # the ad you answered, on newsprint
	paper.bg_color = Color("e8e0c8")
	paper.set_content_margin_all(8)
	ad.add_theme_stylebox_override("normal", paper)
	head.add_child(ad)
	add_child(head)
	queue_redraw()


func _grids() -> Array[String]:
	var out: Array[String] = ["bed"]
	if "trailer" in Game.upgrades:
		out.append("trailer")
	return out


func _tray() -> Array[String]:
	var out := Game.unpacked()
	if not held.is_empty() and held.kind != "can": # in your hands, not at home
		out.erase(held.kind)
	out.append("go")
	return out


func _origin(grid: String) -> Vector2:
	return BED_AT if grid == "bed" else TRAILER_AT


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	var view := get_viewport() # before act(): driving off leaves the tree at once
	if event is InputEventMouseButton and event.pressed:
		_click(event.position, event.button_index)
	elif event.is_action_pressed("ui_left"):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed("ui_right"):
		_move(Vector2i.RIGHT)
	elif event.is_action_pressed("ui_up"):
		_move(Vector2i.UP)
	elif event.is_action_pressed("ui_down"):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		act()
	elif event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel"):
		if held.is_empty():
			send_home()
		else:
			put_back()
	elif event.is_action_pressed("pause"): # Start or [P] (Esc is put back, above): off from anywhere
		drive()
	elif (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y):
		turn()
	else:
		return
	view.set_input_as_handled()
	queue_redraw()


## Step the cursor; off a grid's side it crosses to the next grid or the tray. Empty-
## handed on a packed item, the item is one stop: the step leaves from its far edge.
func _move(d: Vector2i) -> void:
	Sfx.play("ui_move", 0.0)
	var zones: Array[String] = _grids()
	zones.append("tray")
	var p := Game.packed_at(zone, cell) if zone != "tray" and held.is_empty() else {}
	if not p.is_empty():
		var f := Game.footprint(p.kind, p.turned)
		cell = Vector2i(clampi(cell.x, p.at.x, p.at.x + f.x - 1) if d.x == 0 else (p.at.x + f.x - 1 if d.x > 0 else p.at.x),
			clampi(cell.y, p.at.y, p.at.y + f.y - 1) if d.y == 0 else (p.at.y + f.y - 1 if d.y > 0 else p.at.y))
	if zone == "tray":
		if d.y != 0:
			row = clampi(row + d.y, 0, _tray().size() - 1)
		elif d.x < 0:
			zone = zones[-2]
			cell = Vector2i(Game.GRIDS[zone].x - 1, mini(cell.y, Game.GRIDS[zone].y - 1))
		return
	var g: Vector2i = Game.GRIDS[zone]
	var next := cell + d
	if next.x < 0 or next.x >= g.x:
		var i := zones.find(zone) + d.x
		if i < 0:
			return
		zone = zones[i]
		if zone != "tray":
			var ng: Vector2i = Game.GRIDS[zone]
			cell = Vector2i(0 if d.x > 0 else ng.x - 1, mini(cell.y, ng.y - 1))
		return
	cell = Vector2i(next.x, clampi(next.y, 0, g.y - 1))


## Pick up, drop, or (on the tray) take kit out or drive off.
func act() -> void:
	if zone == "tray":
		row = mini(row, _tray().size() - 1) # the list shrinks while you hold something from it
		var what: String = _tray()[row]
		if what == "go":
			drive()
		elif held.is_empty():
			held = {"kind": what, "turned": false, "from": {}}
			Sfx.play("ui_select", 0.0)
		else: # back in the tray: unpacked
			_say = "%s left at home." % Game.kit_name(held.kind)
			held = {}
		return
	if held.is_empty():
		var p := Game.packed_at(zone, cell)
		if not p.is_empty():
			Game.packed.erase(p)
			held = {"kind": p.kind, "turned": p.turned, "from": p}
			Sfx.play("ui_select", 0.0)
		return
	var at := _drop_at()
	if Game.fits(held.kind, zone, at, held.turned):
		Game.packed.append({"kind": held.kind, "grid": zone, "at": at, "turned": held.turned})
		held = {}
		_say = ""
		Sfx.play("ui_select", 0.0)
	else:
		_say = "Won't fit there." if not (held.kind == "rideon" and zone == "bed") else "A ride-on only goes on the trailer."


## Where the held item's corner lands: the cursor, pulled back so it stays on the grid.
func _drop_at() -> Vector2i:
	var g: Vector2i = Game.GRIDS[zone]
	var f := Game.footprint(held.kind, held.turned)
	return Vector2i(clampi(cell.x, 0, maxi(0, g.x - f.x)), clampi(cell.y, 0, maxi(0, g.y - f.y)))


func turn() -> void:
	if not held.is_empty():
		held.turned = not held.turned
		Sfx.play("ui_move", 0.0)


## Empty-handed on a packed item: it comes off the truck, straight home.
func send_home() -> void:
	var p := Game.packed_at(zone, cell) if zone != "tray" and held.is_empty() else {}
	if not p.is_empty():
		Game.packed.erase(p)
		_say = "%s left at home." % Game.kit_name(p.kind)
		Sfx.play("ui_select", 0.0)


## Put what's in your hands back where it came from (or back in the tray).
func put_back() -> void:
	if held.is_empty():
		return
	if not held.from.is_empty():
		Game.packed.append(held.from)
	held = {}


func drive() -> void:
	put_back()
	Game.start_job()
	get_tree().change_scene_to_file("res://main.tscn")


func _click(at: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		turn()
		return
	for grid in _grids():
		var local := (at - _origin(grid)) / CELL
		var g: Vector2i = Game.GRIDS[grid]
		if local.x >= 0.0 and local.y >= 0.0 and local.x < g.x and local.y < g.y:
			zone = grid
			cell = Vector2i(local)
			act()
			return
	var r := floori((at.y - TRAY_AT.y) / ROW_H)
	if at.x >= TRAY_AT.x and r >= 0 and r < _tray().size():
		zone = "tray"
		row = r
		act()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.BG)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(BED_AT.x, BED_AT.y - 52), "Cab: the push mower, always.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.DIM)
	for grid in ["bed", "trailer"]:
		var o := _origin(grid)
		draw_string(font, o + Vector2(0, -16), "Truck bed" if grid == "bed" else "Trailer", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.GOLD)
		if grid not in _grids():
			draw_string(font, o + Vector2(0, 30), "(no trailer: the shop sells one)", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.DIM)
			continue
		var g: Vector2i = Game.GRIDS[grid]
		draw_rect(Rect2(o, Vector2(g) * CELL), UI.PANEL)
		for y in g.y:
			for x in g.x:
				draw_rect(Rect2(o + Vector2(x, y) * CELL, Vector2(CELL, CELL)), UI.PANEL_EDGE, false, 1.0)
		for p: Dictionary in Game.packed:
			if p.grid == grid:
				_item(o + Vector2(p.at) * CELL, p.kind, p.turned, COLOURS[p.kind])
	# The tray: kit left at home, then the way out.
	draw_string(font, TRAY_AT + Vector2(0, -16), "Left at home", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.GOLD)
	var tray := _tray()
	for i in tray.size():
		var r := Rect2(TRAY_AT + Vector2(0, i * ROW_H), Vector2(440, ROW_H - 6))
		var go: bool = tray[i] == "go"
		draw_rect(r, Color("3a5a30") if go else UI.PANEL)
		var text := "DRIVE TO THE JOB" if go else Game.kit_name(tray[i]) + ("  (as many as fit)" if tray[i] == "can" else "")
		draw_string(font, r.position + Vector2(12, 27), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.TEXT)
		if zone == "tray" and row == i:
			draw_rect(r, UI.GOLD, false, 3.0)
	# The cursor, with whatever you're holding.
	if zone != "tray":
		var o := _origin(zone)
		if held.is_empty(): # round the whole item it's on, or the one cell
			var p := Game.packed_at(zone, cell)
			var box := Rect2(o + Vector2(p.at) * CELL, Vector2(Game.footprint(p.kind, p.turned)) * CELL) if not p.is_empty() 				else Rect2(o + Vector2(cell) * CELL, Vector2(CELL, CELL))
			draw_rect(box, UI.GOLD, false, 3.0)
		else:
			var at := _drop_at()
			var ok := Game.fits(held.kind, zone, at, held.turned)
			_item(o + Vector2(at) * CELL, held.kind, held.turned, (UI.GOOD if ok else UI.BAD) * Color(1, 1, 1, 0.8))
	elif not held.is_empty():
		_item(TRAY_AT + Vector2(460, row * ROW_H), held.kind, held.turned, COLOURS[held.kind] * Color(1, 1, 1, 0.8))
	var keys := "Move: arrows/stick   %s pick up / drop   %s turn   %s put back / send home   %s drive" % [
		Game.key("interact"), "(Y)" if Game.pad else "[R]", Game.key("hop"), "(Start)" if Game.pad else "[P]"]
	draw_string(font, Vector2(60, 680), keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.DIM)
	if _say != "":
		draw_string(font, Vector2(60, 640), _say, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.BAD)


func _item(at: Vector2, kind: String, turned: bool, colour: Color) -> void:
	var box := Vector2(Game.footprint(kind, turned)) * CELL
	var r := Rect2(at + Vector2(3, 3), box - Vector2(6, 6))
	draw_rect(r, colour)
	draw_rect(r, Color(0, 0, 0, 0.5), false, 2.0)
	var label: String = {"petrol": "PETROL", "rideon": "RIDE-ON", "can": "CAN", "robot": "ROBOT"}[kind]
	draw_string(ThemeDB.fallback_font, r.position + Vector2(6, 22), label, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 8, 20, UI.TEXT)
