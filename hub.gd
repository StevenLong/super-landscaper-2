extends Node2D
## Your own places between jobs (design doc, The hub, redesigned): your premises (the office
## and the floor, one building) and the shop in town, walked round on foot in the job's 3/4
## view. Tangible things live here and say what they are when you're by them; interact and a
## card says the rest (or a fitting opens its paper thing: the corkboard's calendar, the
## desk's client book, the paper). Walking costs no time; the drive to the shop and back
## does. Game.place says where you are ("home" or "shop"), Game.spot where you stand.
## Anything waiting to be read (the day's end, payday, court...) is the desk's, first.

const WalkerScript := preload("res://walker.gd")
const CELL := Vector2(20, 12) ## a floor cell as drawn: the truck's packing cell, its depth seen 3/4
const OFFICE_W := [120.0, 170.0, 220.0] ## the office's end of the building, by premises
const WALKWAY := 44.0 ## floor in front of the cells, to walk along
const REACH := 14.0 ## how far past a thing's footprint you can use it
const WALL := Color("b8a47a")
const WALL_DARK := Color("8a7650")
const TAG := Color("f8e8c0")
const ROOFS := Color("2c2e34") ## outside: the roofs round about

var walker: CharacterBody2D
var cam: Camera2D
var _world: Node2D ## y-sorted: you and the things
var _things: Array[Dictionary] = [] ## {node, rect (ground footprint), hint, act}
var _bounds := Rect2() ## where you can walk
var _hint: Label
var _card: Control = null
var _layer: CanvasLayer
var _leaving := false ## an act's taken you somewhere else: don't lay this place out again
var _floor_at := Vector2.ZERO ## the floor's cells start here
var _carry := {} ## what you've picked up to set down elsewhere: {item, turned}
var _ghost: Node2D ## where it'd go
var _item_nodes := {} ## each thing on the floor's node, by its spot key
var _doors: Array[Node2D] = [] ## doors that swing as you come up to them
var _roller: Node2D ## the roller door over the truck's bay: up as you come to the truck
var _idle := 0.0 ## till a helper in the staff room shifts about
static var _stood := Vector2.INF ## where you stood when a card's act laid the place out again


func _ready() -> void:
	if not Game.day_end.is_empty() or not Game.blackout.is_empty() or Game.today().has("court") \
			or Game.today().has("jail") or Game.payday_pending or Game.winter_pending: # a day inside: at the desk, calling it a day
		Game.place = "home"
		Game.spot = "corkboard"
		get_tree().change_scene_to_file.call_deferred("res://board.tscn") # the desk has it to read
		return
	Sfx.music("music_menu")
	Game.advance_crew() # whoever's due off has gone, van, mower and all
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	if Game.place == "shop":
		_shop()
	else:
		_premises()
	_layer = CanvasLayer.new()
	add_child(_layer)
	var top := UI.label("", 20, UI.GOLD)
	top.name = "Where"
	top.position = Vector2(20, 14)
	top.text = "%s   %s   %s   $%d" % ["The mower shop" if Game.place == "shop" else Game.PREMISES[Game.premises].name,
		Game.date_text(), Game.time_text(Game.minute), Game.money]
	UI.shadow(top, 2)
	_layer.add_child(top)
	_hint = UI.label("", 20)
	_hint.name = "Hint"
	_hint.position = Vector2(20, 680)
	UI.shadow(_hint, 2)
	_layer.add_child(_hint)


## Lay out a room: what's outside it (roofs behind and beside, the pavement and the road in
## front), its floor (a tiled texture), the back wall with its windows (`windows`: their
## middles) and strip lights, the side walls, a low front wall cut away to see in, and
## where you can walk.
func _room(floor_rect: Rect2, tile: Texture2D, wall_h: float, windows: Array = []) -> void:
	var out := Node2D.new() # outside
	out.z_index = -20
	var street := floor_rect.end.y + 12.0
	out.draw.connect(func() -> void:
		var wide := Rect2(floor_rect.position.x - 900, floor_rect.position.y - wall_h - 600, floor_rect.size.x + 1800, 600 + wall_h + floor_rect.size.y + 12)
		out.draw_rect(wide, ROOFS)
		for i in range(0, int(wide.size.x), 46): # the roofs' ridges, round about
			out.draw_line(Vector2(wide.position.x + i, wide.position.y), Vector2(wide.position.x + i, wide.end.y), ROOFS.lightened(0.04), 1.0)
		out.draw_texture_rect(preload("res://art/paving.png"), Rect2(wide.position.x, street, wide.size.x, 40), true) # the pavement
		out.draw_rect(Rect2(wide.position.x, street + 40, wide.size.x, 4), Color("8a8a84")) # the kerb
		out.draw_texture_rect(preload("res://art/asphalt.png"), Rect2(wide.position.x, street + 44, wide.size.x, 120), true) # the road
		for x in range(int(wide.position.x), int(wide.end.x), 60):
			out.draw_rect(Rect2(x, street + 102, 30, 3), Color("e8e0c0")))
	add_child(out)
	var ground := Node2D.new()
	ground.z_index = -10
	ground.draw.connect(func() -> void:
		ground.draw_texture_rect(tile, floor_rect, true)
		if wall_h > 0.0:
			var w := Rect2(floor_rect.position - Vector2(0, wall_h), Vector2(floor_rect.size.x, wall_h))
			ground.draw_rect(w, WALL)
			ground.draw_rect(Rect2(w.position, Vector2(w.size.x, 4)), WALL_DARK)
			ground.draw_rect(Rect2(w.position + Vector2(0, w.size.y - 6), Vector2(w.size.x, 6)), WALL_DARK)
			ground.draw_rect(Rect2(w.position + Vector2(0, w.size.y * 0.45), Vector2(w.size.x, 2)), WALL_DARK)
			for x: float in windows: # windows onto outside
				var g := Rect2(x - 17, w.position.y + 14, 34, 24)
				ground.draw_rect(g.grow(3), WALL_DARK)
				ground.draw_rect(g, Color("8fb8d8"))
				ground.draw_rect(Rect2(g.position, Vector2(g.size.x, 8)), Color("b8d4e8"))
				ground.draw_line(g.position + Vector2(6, g.size.y), g.position + Vector2(20, 0), Color(1, 1, 1, 0.5), 2.0) # a glint
				ground.draw_rect(Rect2(g.position.x + 16, g.position.y, 2, g.size.y), WALL_DARK)
			for x in range(int(floor_rect.position.x) + 50, int(floor_rect.end.x) - 30, 140): # strip lights
				ground.draw_rect(Rect2(x - 20, w.position.y + 6, 40, 5), Color(1, 1, 0.85, 0.18))
				ground.draw_rect(Rect2(x - 16, w.position.y + 7, 32, 3), Color("f4f4e8")))
	add_child(ground)
	var sides := Node2D.new() # the side walls and the low front one, in front of what's in the room
	sides.z_index = 8
	sides.draw.connect(func() -> void:
		for x: float in [floor_rect.position.x - 12, floor_rect.end.x]:
			sides.draw_rect(Rect2(x, floor_rect.position.y - wall_h, 12, floor_rect.size.y + wall_h + 12), WALL_DARK)
			sides.draw_rect(Rect2(x + 2, floor_rect.position.y - wall_h, 8, floor_rect.size.y + wall_h + 12), WALL.darkened(0.15))
		var front := Rect2(floor_rect.position.x - 12, floor_rect.end.y, floor_rect.size.x + 24, 12)
		sides.draw_rect(front, WALL_DARK)
		sides.draw_rect(Rect2(front.position, Vector2(front.size.x, 5)), WALL.darkened(0.1)))
	add_child(sides)
	_bounds = floor_rect.grow(-8.0)


## A door in the back wall at `x`: it swings open as you come up to it.
func _door(x: float) -> void:
	var d := Node2D.new()
	d.position = Vector2(x, -4)
	d.z_index = -5
	d.set_meta("open", 0.0)
	var tex := preload("res://art/door.png")
	d.draw.connect(func() -> void:
		var w := tex.get_width()
		var h := tex.get_height()
		var o: float = d.get_meta("open")
		d.draw_rect(Rect2(-w / 2.0, -h, w, h), Color("1a1814")) # the doorway
		d.draw_texture_rect(tex, Rect2(-w / 2.0, -h, w * (1.0 - 0.8 * o), h), false, Color(1, 1, 1).darkened(0.35 * o))) # swung on its hinge
	add_child(d)
	_doors.append(d)


## Put a thing in the place: drawn standing on `foot` (its sprite's bottom centre there,
## or `paint` called with the node), taking up `ground` (a size, centred on foot, reaching
## back from it); `hint` what interacting does, `act` doing it. Solid unless said.
func _thing(foot: Vector2, ground: Vector2, hint: String, act: Callable, tex: Texture2D = null, paint: Callable = Callable(), solid := true, centred := false) -> Node2D:
	var n := Node2D.new()
	n.position = foot
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = centred # a voxel still: its middle on the ground at the ground's middle
		s.position = Vector2(0, -ground.y / 2.0) if centred else Vector2(-tex.get_width() / 2.0, -tex.get_height())
		n.add_child(s)
	if paint.is_valid():
		n.draw.connect(paint.bind(n))
	var rect := Rect2(foot - Vector2(ground.x / 2.0, ground.y), ground)
	if solid:
		var body := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = ground
		cs.shape = shape
		cs.position = Vector2(0, -ground.y / 2.0)
		body.add_child(cs)
		n.add_child(body)
	_world.add_child(n)
	if hint != "":
		_things.append({"node": n, "rect": rect, "hint": hint, "act": act, "solid": solid})
	return n


## A small tag over a thing, in the world: a price, a name.
func _tag(on: Node2D, text: String, at: Vector2, color := TAG) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	UI.shadow(l, 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(120, 12)
	l.position = at - Vector2(60, 0)
	l.z_index = 20
	on.add_child(l)
	return l


## You, on foot, at `at`, the camera on you (or, `fixed`, on the room's middle).
func _spawn(at: Vector2, fixed: Variant = null) -> void:
	if _stood != Vector2.INF: # laid out again after a card: where you were
		at = _stood
		_stood = Vector2.INF
	walker = WalkerScript.new()
	walker.position = at
	walker.keep_in = func(p: Vector2) -> Vector2: return p.clamp(_bounds.position, _bounds.end)
	_world.add_child(walker)
	if fixed is Vector2:
		cam.position = fixed
		add_child(cam)
	else:
		walker.add_child(cam)
		cam.limit_left = int(_bounds.position.x - 80)
		cam.limit_right = int(_bounds.end.x + 80)
		cam.limit_top = int(_bounds.position.y - 160)
		cam.limit_bottom = int(_bounds.end.y + 60)
	cam.make_current()


# ---------------------------------------------------------------- your premises

## Your premises (design doc, The hub, redesigned): one building, the office at its left end
## (the corkboard's calendar, the desk's client book, the phone and the paper, the filing
## cabinet once there's staff, the street door from the unit up), the floor to its right
## with everything you own where you put it, and the truck's bay by the roller door.
func _premises() -> void:
	var ow: float = OFFICE_W[Game.premises]
	var fl := Vector2(Game.floor_size()) * CELL
	_floor_at = Vector2(ow, 0)
	var room := Rect2(0, 0, ow + fl.x, fl.y + WALKWAY)
	var bay_px := Rect2(_floor_at + Vector2(Game.bay().position) * CELL, Vector2(Game.bay().size) * CELL)
	var windows: Array = []
	for x in range(int(ow + 160), int(bay_px.position.x) - 30, 120): # windows along the floor's wall, clear of the pegboard and the roller door
		windows.append(float(x))
	if Game.premises > 0:
		windows.append(ow * 0.86)
	_room(room, preload("res://art/paving.png"), 70.0, windows)
	var ground := Node2D.new() # the office's floorboards, its partition, the floor's cells, the bay
	ground.z_index = -9
	var boards := preload("res://art/floorboards.png")
	var bay := Rect2(_floor_at + Vector2(Game.bay().position) * CELL, Vector2(Game.bay().size) * CELL)
	ground.draw.connect(func() -> void:
		ground.draw_texture_rect(boards, Rect2(0, 0, ow, room.size.y), true)
		if Game.premises > 0: # a partition: the office walled off from the floor
			ground.draw_rect(Rect2(ow - 3, 0, 3, room.size.y - 24), WALL_DARK)
		for i in Game.floor_size().x + 1:
			ground.draw_line(_floor_at + Vector2(i * CELL.x, 0), _floor_at + Vector2(i * CELL.x, fl.y), Color(1, 1, 1, 0.13), 1.0)
		for i in Game.floor_size().y + 1:
			ground.draw_line(_floor_at + Vector2(0, i * CELL.y), _floor_at + Vector2(fl.x, i * CELL.y), Color(1, 1, 1, 0.13), 1.0)
		ground.draw_rect(bay, Color("f8e070", 0.5), false, 2.0)
		ground.draw_rect(Rect2(bay.position.x + 4, bay.end.y - 8, bay.size.x - 8, 3), Color("f8e070", 0.35))
		var r := RandomNumberGenerator.new() # oil where things have stood
		r.seed = Game.premises * 7 + 3
		for i in 3 + Game.premises * 3:
			var c := _floor_at + Vector2(r.randf_range(0.1, 0.9) * fl.x, r.randf_range(0.15, 0.95) * fl.y)
			ground.draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
			ground.draw_circle(Vector2.ZERO, r.randf_range(5.0, 11.0), Color(0.05, 0.05, 0.06, 0.28))
			ground.draw_set_transform(Vector2.ZERO)
		ground.draw_set_transform(Vector2.ZERO)
		_pegboard(ground, Rect2(ow + 14, -56, minf(110.0, bay.position.x - ow - 40), 30)))
	add_child(ground)
	_roller = Node2D.new() # the roller door, in the back wall over the bay: up as you come to the truck
	_roller.z_index = -8
	_roller.set_meta("open", 0.0)
	_roller.draw.connect(func() -> void:
		var r := Rect2(bay.position.x + 8, -58, bay.size.x - 16, 56)
		var o: float = _roller.get_meta("open")
		_roller.draw_rect(r, Color("b8c8d0")) # daylight, outside
		var shut := Rect2(r.position, Vector2(r.size.x, r.size.y * (1.0 - 0.85 * o)))
		_roller.draw_rect(shut, Color("8c8c84"))
		for y in range(int(shut.position.y) + 4, int(shut.end.y), 5):
			_roller.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("6c6c66"), 1.0)
		_roller.draw_rect(r, Color("4c4c48"), false, 2.0))
	add_child(_roller)
	# The office's fittings.
	var cork := Sprite2D.new()
	cork.texture = preload("res://art/corkboard.png")
	cork.position = Vector2(ow * 0.3, -40)
	cork.scale = Vector2(0.7, 0.7)
	cork.z_index = -5
	add_child(cork)
	_thing(Vector2(ow * 0.3, 4), Vector2(50, 6), "read the calendar on the corkboard", _to_board.bind("corkboard"), null, Callable(), false)
	_thing(Vector2(ow * 0.3, 30), Vector2(76, 22), "sit at the desk (the client book)", _to_board.bind("desk"), preload("res://art/desk.png"), Callable(), true, true)
	var phone_at := Vector2(ow * 0.86, 24)
	_thing(phone_at, Vector2(26, 14), "use the phone (the paper, ringing round)", _phone_card, preload("res://art/phone_table.png"), Callable(), true, true)
	if Game.staff_room != "":
		_thing(Vector2(ow * 0.3 + 54, 24), Vector2(22, 14), "open the filing cabinet (your staff)", _cabinet_card, preload("res://art/cabinet.png"), Callable(), true, true)
	if Game.premises > 0: # a bigger office: shelving, and a rug to stand on
		_thing(Vector2(ow * 0.22, room.size.y - 26), Vector2(64, 12), "", Callable(), preload("res://art/shelving.png"), Callable(), true, true)
		var rug := Node2D.new()
		rug.z_index = -8
		rug.draw.connect(func() -> void:
			var r := Rect2(ow * 0.18, 64, ow * 0.6, minf(70.0, room.size.y - 120))
			rug.draw_rect(r, Color("6a2a2a"))
			rug.draw_rect(r.grow(-5), Color("8a3a30"), false, 2.0)
			rug.draw_rect(r.grow(-12), Color("a85840"), false, 1.0))
		add_child(rug)
	if Game.PREMISES[Game.premises].street:
		_door(ow * 0.62)
		_thing(Vector2(ow * 0.62, 8), Vector2(30, 8), "lock up and go home (end the day)", _end_day_card, null, Callable(), false)
	# The floor: everything where it stands, the truck in its bay.
	var lay := Game.yard_layout()
	for p: Dictionary in lay.placed:
		if not _out(p.item): # out with the crew: its room stands empty till it's back
			_yard_item(p.item, _floor_at + Vector2(p.at) * CELL, Vector2(p.size) * CELL, p.turned)
	var x := 0.0 # what's got no room, stood about past the floor's front
	for it: Dictionary in lay.over:
		if _out(it):
			continue
		var sz := Vector2(Game.foot(it.kind)) * CELL
		_yard_item(it, _floor_at + Vector2(x, fl.y + WALKWAY + 40), sz, false) # no room for it: outside, till it's sold
		x += sz.x + 10.0
	var truck_at := Vector2(bay.get_center().x, bay.end.y - 4)
	_thing(truck_at, Vector2(bay.size.x - 12, bay.size.y - 8), "get in your truck", _truck_card, preload("res://art/truck_parked.png"), Callable(), true, true)
	_standing()
	_mark_covering()
	var at: Vector2 = {"truck": truck_at + Vector2(-10, 26), "phone": phone_at + Vector2(0, 22), "paper": phone_at + Vector2(0, 22), "door": Vector2(ow * 0.62, 24)}.get(Game.spot, Vector2(ow * 0.3, 60))
	_spawn(at)
	_ghost = Node2D.new() # what you're carrying, set down where it'd go
	_ghost.z_index = 30
	_ghost.draw.connect(_draw_ghost)
	add_child(_ghost)


## A pegboard of tools on the wall, if there's room for one.
func _pegboard(on: Node2D, peg: Rect2) -> void:
	if peg.size.x <= 30:
		return
	on.draw_rect(peg, Color("c8a878"))
	on.draw_rect(peg, WALL_DARK, false, 2.0)
	for i in range(int(peg.size.x / 22)):
		var t := peg.position + Vector2(8 + i * 22, 5)
		match i % 3:
			0: # a hammer
				on.draw_rect(Rect2(t + Vector2(3, 4), Vector2(2, 16)), Color("7c522e"))
				on.draw_rect(Rect2(t, Vector2(8, 5)), Color("54545e"))
			1: # a saw
				on.draw_rect(Rect2(t + Vector2(0, 2), Vector2(6, 18)), Color("a8a8b4"))
				on.draw_rect(Rect2(t + Vector2(-1, 0), Vector2(8, 4)), Color("a82a22"))
			_: # a spanner
				on.draw_rect(Rect2(t + Vector2(2, 2), Vector2(3, 17)), Color("7a7a86"))
				on.draw_rect(Rect2(t, Vector2(7, 4)), Color("7a7a86"))


## To one of the office's paper things (Game.spot says which: the board opens on it).
func _to_board(which: String) -> void:
	_leaving = true
	Game.place = "home"
	Game.spot = which
	get_tree().change_scene_to_file("res://board.tscn")


## Whether a van or a mower on the floor is out with the crew now: the last of its kind
## not marked yours (the crew never take those).
func _out(it: Dictionary) -> bool:
	if it.kind == "van":
		return it.n >= Game.vans - Game.out_now("van")
	if Game.HELP_SECS.has(it.kind):
		return it.n >= Game.total(it.kind) - Game.out_now(it.kind)
	return false


## A thing on the floor, its sprite standing in its cells (the staff room: its partition,
## furniture and whoever's in).
func _yard_item(it: Dictionary, at: Vector2, sz: Vector2, turned: bool) -> void:
	var foot := at + Vector2(sz.x / 2.0, sz.y)
	var hint := ""
	var tex: Texture2D = null
	var paint := Callable()
	var solid := true
	var centred := false
	if it.kind.begins_with("staff_"):
		hint = "look at the %s" % Game.kit_name(it.kind).to_lower()
		solid = false
		var furniture: Array = [[preload("res://art/sofa.png"), Vector2(0.3, 0.3)], [preload("res://art/vending.png"), Vector2(0.88, 0.25)],
			[preload("res://art/cooler.png"), Vector2(0.68, 0.25)]]
		if it.kind == "staff_breakroom":
			furniture.append([preload("res://art/arcade.png"), Vector2(0.52, 0.25)])
		paint = func(on: Node2D) -> void:
			var r := Rect2(-sz.x / 2.0, -sz.y, sz.x, sz.y)
			on.draw_rect(r, Color("5a5070", 0.45)) # a carpet
			on.draw_rect(Rect2(r.position.x, r.position.y - 16, r.size.x, 16), Color("c8c0b0", 0.85)) # the partition's back, behind it all
			on.draw_rect(Rect2(r.position.x - 3, r.position.y - 16, 3, r.size.y + 16), Color("a8a090")) # and its ends
			on.draw_rect(Rect2(r.end.x, r.position.y - 16, 3, r.size.y + 16), Color("a8a090"))
			for f: Array in furniture: # along its back, each still's middle on the ground there
				var t: Texture2D = f[0]
				on.draw_texture(t, r.position + r.size * (f[1] as Vector2) - t.get_size() / 2.0)
	else:
		match it.kind:
			"van":
				hint = "look at the van"
				tex = preload("res://art/van.png")
				centred = true
			"robot":
				hint = "look at the robot mower"
				paint = func(on: Node2D) -> void: Robot.draw(on, Vector2(0, -10))
			_:
				hint = "look at %s %s" % ["your" if it.get("mine", false) else "the", Game.MOWERS[it.kind].name.to_lower()]
				var sheet: Texture2D = load("res://art/mower_%s.png" % it.kind)
				var trailer: Texture2D = preload("res://art/trailer.png") if it.kind == "rideon" else null
				paint = func(on: Node2D) -> void:
					if trailer:
						on.draw_texture(trailer, Vector2(-trailer.get_width() / 2.0, -trailer.get_height() + 4))
					Facing.draw(on, sheet, 3, 2, PI / 2.0 if turned else 0.0, Vector2(0, -24.0 if trailer else -12.0))
	var n := _thing(foot - Vector2(0, 1), Vector2(sz.x - 4, sz.y - 2), hint, _yard_card.bind(it), tex, paint, solid, centred)
	n.z_index = -6 if it.kind.begins_with("staff_") else 0
	_item_nodes[Game.spot_key(it)] = n
	if it.get("mine", false):
		_tag(n, "yours", Vector2(0, -44))


## The card for something on the floor: what it is, and what you can do with it.
func _yard_card(it: Dictionary) -> void:
	var lines: Array[String] = []
	var acts: Array = []
	var title := ""
	if it.kind.begins_with("staff_"):
		title = Game.kit_name(it.kind)
		lines.append("Where your staff wait when they're in: %d seats, %d taken." % [Game.seats(), Game.helpers.size()])
		if Game.staff_next() != "":
			lines.append("A breakroom would seat %d: ring a builder from the phone." % Game.STAFF.breakroom.seats)
	else:
		match it.kind:
			"van":
				title = Game.VAN.name
				lines.append("A helper takes a free one when they set off for a job.")
				lines.append("You've %d%s." % [Game.vans, ", %d out now" % Game.out_now("van") if Game.out_now("van") > 0 else ""])
				acts.append(["Sell it, $%d" % Game.resale("van"), func() -> void: Game.sell_at("van", it.n)])
			"robot":
				title = Game.ROBOT.name
				lines.append(Game.ROBOT.blurb + " You pack it in the truck's bed, or the trailer.")
				if "trailer" not in Game.upgrades:
					_upgrade(acts, "trailer")
				acts.append(["Sell it, $%d" % Game.resale("robot"), func() -> void: Game.sell_at("robot", it.n)])
			_:
				var m: Dictionary = Game.MOWERS[it.kind]
				title = ("Your " if it.mine else "A ") + m.name.to_lower()
				lines.append(m.blurb + (" It rides in the cab." if it.kind == "push" else " Packed in the truck before each job."))
				lines.append("Marked yours: the crew never take it." if it.mine else "The crew take it if it's the best free when they set off.")
				acts.append(["Let the crew use it" if it.mine else "Mark it yours", func() -> void: Game.mark_mine(it.kind, not it.mine, it.n)])
				for u: String in ["tank", "blades"] + (["gear3", "gear4"] if it.kind == "rideon" else []):
					_upgrade(acts, u)
				if it.kind != "push":
					acts.append(["Sell it, $%d" % Game.resale(it.kind), func() -> void: Game.sell_at(it.kind, it.n)])
	acts.push_front(["Move it", _start_carry.bind(it), false, "stay"])
	lines.append("Takes %s of your floor." % _cells(it.kind))
	_open_card(title, lines, acts)


## The phone, with the paper beside it: read the paper (the ads, situations wanted and
## Vince's are rung from it), or ring the estate agent for bigger premises, a builder for a
## staff room.
func _phone_card() -> void:
	var p: Dictionary = Game.PREMISES[Game.premises]
	var lines: Array[String] = ["You're in %s: %d by %d, $%d a week on top of rent and food." % [p.name.to_lower(), p.w, p.d, p.rent]]
	var acts: Array = [["Read the paper", _to_board.bind("paper")]]
	if Game.premises + 1 < Game.PREMISES.size():
		var nx: Dictionary = Game.PREMISES[Game.premises + 1]
		var why := Game.cant_move(Game.premises + 1)
		acts.append(["Ring the estate agent: %s, %d by %d, $%d down, $%d a week%s" % [nx.name.to_lower(), nx.w, nx.d, nx.deposit, nx.rent,
			"" if why == "" else " (%s)" % why.to_lower()], func() -> void:
				Game.move_to(Game.premises + 1)
				Game.spot = "phone", why != ""])
	if Game.staff_next() != "":
		var why := Game.cant_buy("staff")
		acts.append(["Ring a builder: a %s seating %d, $%d%s" % [Game.kit_name("staff").to_lower(), Game.STAFF[Game.staff_next()].seats, Game.price_of("staff"),
			"" if why == "" else " (%s)" % why.to_lower()], func() -> void: Game.buy("staff"), why != ""])
	elif Game.staff_room == "":
		lines.append("No room for staff here: hiring needs a staff room, and those need a bigger place.")
	_open_card("The phone", lines, acts)


## The filing cabinet: your staff, each to their card.
func _cabinet_card() -> void:
	var acts: Array = []
	for h: Dictionary in Game.helpers:
		var back := Game.out_till(h.id)
		acts.append(["%s: %s, $%d a week%s" % [h.name, Game.card_text(h), h.wage, ", out till %s" % Game.time_text(back) if back >= 0 else ""],
			_standing_card.bind(h), false, "stay"])
	var lines: Array[String] = ["%d of %d seats." % [Game.helpers.size(), Game.seats()]]
	if Game.helpers.is_empty():
		lines.append("Nobody yet: ring a situation wanted in the paper.")
	_open_card("The filing cabinet", lines, acts)


## A helper on their card: how good, their wage, a raise they've asked for, today.
func _helper_lines(h: Dictionary, lines: Array[String], acts: Array) -> void:
	lines.append("%s. $%d a week, %d job%s done." % [UI.sentence(Game.card_text(h)), h.wage, h.jobs, "" if h.jobs == 1 else "s"])
	if h.has("asks"):
		lines.append("Asking $%d a week." % h.asks)
		acts.append(["Pay it", func() -> void: Game.answer_raise(h.id, true)])
		acts.append(["Say no", func() -> void: Game.answer_raise(h.id, false)])
	var plan := Game.crew_plan()
	var today: Array[String] = []
	for b: Dictionary in Game.help_on(h.id):
		var p: Dictionary = plan.get(b.seed, {})
		today.append("%s at %s" % [b.customer, Game.time_text(b.from)] + (" (%s)" % p.cant if p.get("cant", "") != "" else ""))
	for c: Dictionary in Game.crew_cant:
		if c.helper == h.id:
			today.append("%s (couldn't go: %s)" % [c.customer, c.why])
	lines.append("Today: " + (", ".join(today) if today else "nothing. Send them on the calendar."))
	if Game.vans == 0:
		lines.append("No van: they can't go out to jobs. Buy one at the shop.")


## The crew who aren't out on a job: in the staff room if there's one, else by the desk.
func _standing() -> void:
	var room := Rect2()
	for th: Dictionary in _things:
		if (th.hint as String).begins_with("look at the staff") or (th.hint as String).begins_with("look at the breakroom"):
			room = th.rect
	var i := 0
	for h: Dictionary in Game.helpers:
		if Game.out_till(h.id) >= 0:
			continue
		var sheet := preload("res://art/walker.png")
		var per := maxi(1, floori((room.size.x - 16.0) / 36.0)) # to a row, as many as the room's wide enough for
		var at := (room.position + Vector2(16.0 + (i % per) * 36.0, room.size.y * 0.55 + floorf(float(i) / per) * 22.0)) if room.size != Vector2.ZERO \
			else Vector2(20.0 + i * 36.0, 70.0)
		var reads := i % 3 == 1 # a magazine
		i += 1
		var n := _thing(at, Vector2(12, 6), "talk to %s" % h.name.split(" ")[0], _standing_card.bind(h), null,
			func(on: Node2D) -> void:
				Facing.draw(on, sheet, 2, 0, on.get_meta("facing", PI / 2.0), Vector2(0, -14))
				if reads:
					on.draw_rect(Rect2(-5, -19, 10, 7), Color("ece4cc"))
					on.draw_rect(Rect2(-4, -18, 3, 2), Color("c03028")), false)
		n.set_meta("facing", [PI / 2.0, PI * 0.25, PI * 0.75][i % 3])
		n.set_meta("helper", true)
		n.self_modulate = Color("b8d0ff") # not you: a helper (ponytail: your own sprite tinted, till the crew have their own)
		_tag(n, h.name.split(" ")[0] + (" !" if h.has("asks") else ""), Vector2(0, -40), UI.GOLD if h.has("asks") else TAG)


func _standing_card(h: Dictionary) -> void:
	var lines: Array[String] = []
	var acts: Array = []
	_helper_lines(h, lines, acts)
	var why := Game.cant_let_go(h.id)
	acts.append(["Let %s go%s" % [h.name.split(" ")[0], " (%s)" % why if why != "" else ""], func() -> void: Game.let_go(h.id), why != ""])
	_open_card(h.name, lines, acts)


## An upgrade to buy from a card: what it does, and its price (or why not).
func _upgrade(acts: Array, u: String) -> void:
	var why := Game.cant_buy(u)
	if why == "You've got it":
		return
	acts.append(["%s, $%d: %s" % [Game.UPGRADES[u].name, Game.UPGRADES[u].price, Game.UPGRADES[u].blurb] + ("" if why == "" else " (%s)" % why.to_lower()),
		func() -> void: Game.buy(u), why != ""])


func _cells(kind: String) -> String:
	var f := Game.foot(kind)
	return "%d by %d" % [f.x, f.y]


## Pick a thing up: its footprint follows you, green where it'd go and red where not.
## A sets it down, the throw button turns it, B puts it back.
func _start_carry(it: Dictionary) -> void:
	_close_card()
	var sp: Dictionary = Game.spots.get(Game.spot_key(it), {})
	_carry = {"item": it, "turned": sp.get("turned", false)}
	var n: Node2D = _item_nodes.get(Game.spot_key(it))
	if n:
		n.visible = false


## Where what you're carrying would go: the cells under you, a step ahead.
func _carry_cell() -> Vector2i:
	var size := Vector2(Game.foot(_carry.item.kind, _carry.turned))
	var dir := Vector2.RIGHT.rotated(walker.rotation)
	var half := size * CELL / 2.0
	var ahead := walker.position + dir * (12.0 + absf(dir.x) * half.x + absf(dir.y) * half.y) # its near edge a step ahead
	return Vector2i(((ahead - _floor_at) / CELL - size / 2.0).round())


func _draw_ghost() -> void:
	if _carry.is_empty():
		return
	var cell := _carry_cell()
	var ok: bool = Game.put_down(_carry.item, cell, _carry.turned, false)
	var r := Rect2(_floor_at + Vector2(cell) * CELL, Vector2(Game.foot(_carry.item.kind, _carry.turned)) * CELL)
	_ghost.draw_rect(r, Color(UI.GOOD if ok else UI.BAD, 0.35))
	_ghost.draw_rect(r, UI.GOOD if ok else UI.BAD, false, 2.0)


## Off the floor, one way or another: set down where it'd go, or (`back`) where it was.
func _end_carry(back: bool) -> void:
	if not back and not Game.put_down(_carry.item, _carry_cell(), _carry.turned):
		return
	var r := Rect2(_floor_at + Vector2(_carry_cell()) * CELL, Vector2(Game.foot(_carry.item.kind, _carry.turned)) * CELL).grow(10.0)
	_carry = {}
	_stood = walker.position if back or not r.has_point(walker.position) else Vector2(walker.position.x, r.end.y) # never inside what you set down
	_leaving = true
	get_tree().reload_current_scene()


## The day's done when you say: if there's still something of yours you could reach, a check first.
func _end_day_card() -> void:
	var left := Game.jobs_today().filter(func(b: Dictionary) -> bool: return Game.can_go(b))
	if left.is_empty():
		_end_day()
		return
	_open_card("End the day?", ["It's %s. %s%s still yours to do, and you could get there." % [Game.time_text(Game.minute), left[0].customer,
		" and %d more are" % (left.size() - 1) if left.size() > 1 else " is"]], [["End the day", _end_day]])


func _end_day() -> void:
	_leaving = true
	Game.end_day()
	Game.place = "home"
	Game.spot = "corkboard" # the morning's at the corkboard: the day's end to read, then the day to plan
	get_tree().change_scene_to_file("res://board.tscn")


## Your truck: today's jobs you can still reach (packing first, then off), the shop, or home for the night.
func _truck_card() -> void:
	var acts: Array = []
	var lines: Array[String] = []
	for b: Dictionary in Game.jobs_today():
		if Game.can_go(b):
			acts.append(["Go to %s: there at %s" % [b.customer, Game.time_text(Game.arrival(b))], go.bind(b)])
		else:
			lines.append("Too late for %s." % b.customer)
	if Game.jobs_today().is_empty():
		lines.append("Nothing for you today.")
	var shut := Game.minute + Game.DRIVE >= Game.DAY_END
	acts.append(["Drive to the mower shop, +%d min" % Game.DRIVE if not shut else "The shop's shut", drive_to_shop, shut])
	acts.append(["Drive home for the night (end the day)", _end_day_card, false, "stay"])
	_open_card("Your truck", lines, acts)


## Off to a job: packing first (pack.gd), then the job.
func go(b: Dictionary) -> void:
	_leaving = true
	Game.next_job = b
	Game.place = "home"
	Game.spot = "truck"
	get_tree().change_scene_to_file("res://pack.tscn")


func drive_to_shop() -> void:
	_leaving = true
	Game.minute += Game.DRIVE
	Game.place = "shop"
	Game.spot = "door"
	Game.save()
	get_tree().reload_current_scene()


## The planner (Start, design doc, The hub, redesigned): today's plan to look at, ending the
## day, saving and quitting. The board's day, read-only, over the place.
func _planner() -> void:
	_close_card()
	var b: Control = load("res://board.tscn").instantiate()
	b.planner = true
	b.closed.connect(_close_card)
	b.end_day_asked.connect(_end_day_card)
	_card = b
	_layer.add_child(b)
	_hint.text = ""
	if walker:
		walker.set_physics_process(false)
		walker.velocity = Vector2.ZERO


# ---------------------------------------------------------------- the shop

## The mower shop in town: what's for sale stood about with its price over it; interact for
## the card. The counter has the small things; the door, your truck home.
func _shop() -> void:
	var floor_rect := Rect2(0, 0, 520, 230)
	_room(floor_rect, preload("res://art/paving.png"), 80.0)
	for x: float in [70.0, 170.0]: # shelving along the back wall
		_thing(Vector2(x, 14), Vector2(64, 12), "", Callable(), preload("res://art/shelving.png"), Callable(), true, true)
	var counter := _thing(Vector2(120, 110), Vector2(92, 18), "look at the counter (gloves, a trailer)", _counter_card, preload("res://art/counter.png"))
	_tag(counter, "Gloves $%d   Trailer $%d" % [Game.UPGRADES.gloves.price, Game.UPGRADES.trailer.price], Vector2(0, -70))
	var stock := [["petrol", Vector2(270, 90)], ["rideon", Vector2(360, 100)], ["robot", Vector2(450, 90)], ["van", Vector2(330, 222)]]
	for s: Array in stock:
		_stock(s[0], s[1])
	_door(480.0)
	_thing(Vector2(480, 8), Vector2(34, 8), "drive home, +%d min" % Game.DRIVE, drive_home, null, Callable(), false)
	_spawn(Vector2(480, 30), Vector2(260, 70))


func _stock(kind: String, foot: Vector2) -> void:
	var n: Node2D
	var price: int = Game.VAN.price if kind == "van" else (Game.ROBOT.price if kind == "robot" else Game.MOWERS[kind].price)
	if kind == "van":
		n = _thing(foot, Vector2(150, 44), "look at the van", _stock_card.bind(kind), preload("res://art/van.png"), Callable(), true, true)
		_tag(n, "VAN $%d" % price, Vector2(0, -96))
		return
	if kind == "robot":
		n = _thing(foot, Vector2(24, 14), "look at the robot mower", _stock_card.bind(kind), null, func(c: Node2D) -> void: Robot.draw(c, Vector2(0, -10)))
	else:
		var sheet: Texture2D = load("res://art/mower_%s.png" % kind)
		n = _thing(foot, Vector2(44 if kind == "rideon" else 30, 20), "look at the %s" % Game.MOWERS[kind].name.to_lower(), _stock_card.bind(kind), null,
			func(c: Node2D) -> void: Facing.draw(c, sheet, 3, 2, PI * 0.75, Vector2(0, -14.0)))
	_tag(n, "$%d" % price, Vector2(0, -52))


## A thing for sale: what it is, how it compares with yours, the room it takes, and buying it.
func _stock_card(kind: String) -> void:
	var lines: Array[String] = []
	var acts: Array = []
	var title := ""
	if kind == "van":
		title = Game.VAN.name
		lines.append(Game.VAN.blurb + " You've %d. A push mower comes with it." % Game.vans)
		_buy(acts, "van", "Buy it")
	elif kind == "robot":
		title = Game.ROBOT.name
		lines.append(Game.ROBOT.blurb + " You've %d." % Game.robots)
		_buy(acts, "robot", "Buy it")
	else:
		var m: Dictionary = Game.MOWERS[kind]
		title = m.name
		lines.append(m.blurb)
		var best: Dictionary = Game.MOWERS.push # the best you own, to set it against
		for k: String in Game.owned:
			if Game.MOWERS[k].price > best.price:
				best = Game.MOWERS[k]
		if kind not in Game.owned:
			lines.append("Against your %s: top speed %d to %d, cut %d to %d wide." % [best.name.to_lower(), roundi(best.max_speed), roundi(m.max_speed),
				roundi(best.cut_radius * 2.0), roundi(m.cut_radius * 2.0)])
		if kind == "rideon" and "trailer" not in Game.upgrades:
			lines.append("Comes with a trailer to tow it.")
		if kind in Game.owned:
			lines.append("You've %d. Another goes in with them: you or the crew take whichever's free." % Game.total(kind))
		_buy(acts, kind, "Buy it" if kind not in Game.owned else "Buy another")
	lines.append("Takes %s of your floor." % _cells(kind))
	_open_card(title, lines, acts)


func _buy(acts: Array, item: String, label: String) -> void:
	var why := Game.cant_buy(item)
	acts.append(["%s, $%d%s" % [label, Game.price_of(item), "" if why == "" else " (%s)" % why.to_lower()], func() -> void: Game.buy(item), why != ""])


func _counter_card() -> void:
	var acts: Array = []
	for u: String in ["gloves", "trailer"]:
		_upgrade(acts, u)
	# a ternary of two literals comes out untyped, so the choice goes inside the one literal
	_open_card("The counter", [("Gloves and trailers." if not acts.is_empty() else "Nothing else you need.")
		+ " Mower upgrades are fitted at home: see your mowers on your floor."], acts)


func drive_home() -> void:
	_leaving = true
	Game.minute += Game.DRIVE
	Game.place = "home"
	Game.spot = "truck"
	Game.save()
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- walking about

func _physics_process(delta: float) -> void:
	if walker == null:
		return
	for d: Node2D in _doors + ([_roller] if _roller else []):
		var near := walker.position.distance_to(d.position + (Vector2(0, 20) if d != _roller else Vector2(0, 40))) < (40.0 if d != _roller else 140.0)
		if d == _roller:
			near = walker.position.distance_to(_target_of("get in your truck")) < 90.0
		var o: float = move_toward(d.get_meta("open"), 1.0 if near else 0.0, delta * 3.0)
		if o != d.get_meta("open"):
			d.set_meta("open", o)
			d.queue_redraw()
	_idle -= delta
	if _idle <= 0.0: # someone in the staff room shifts about
		_idle = randf_range(1.5, 3.5)
		var crew: Array = _things.filter(func(x: Dictionary) -> bool: return (x.node as Node2D).has_meta("helper"))
		if not crew.is_empty():
			var who: Node2D = crew.pick_random().node
			who.set_meta("facing", randf_range(0.0, TAU))
			who.queue_redraw()
	if _card:
		return
	if not _carry.is_empty():
		_hint.text = "%s set it down   %s%s put it back" % [Game.key("interact"), "" if _carry.item.kind == "van" else Game.key("throw") + " turn it   ", Game.key("hop")]
		_ghost.queue_redraw()
		return
	var t := _target()
	_hint.text = (Game.key("interact") + " " + t.hint) if not t.is_empty() else ("%s your planner" % Game.key("pause") if Game.place != "shop" else "")
	for th: Dictionary in _things: # stood behind something tall (a van): see through it
		var n: Node2D = th.node
		if _covers(n, walker.position) or th.get("covering", false):
			n.modulate.a = 0.45
		else:
			n.modulate.a = 1.0


## Whether a thing's sprite stands in front of a point on the ground behind it (a van is
## drawn far taller than the floor it takes).
func _covers(n: Node2D, at: Vector2) -> bool:
	var spr := n.get_child(0) as Sprite2D if n.get_child_count() > 0 else null
	if spr == null:
		return false
	var top_left := n.position + spr.position - (spr.texture.get_size() / 2.0 if spr.centered else Vector2.ZERO)
	return at.y < n.position.y and Rect2(top_left, spr.texture.get_size()).has_point(at)


## Mark what would hide kit stood behind it: it stays see-through (NOTES 236). A van
## behind a van is left be: its roof and its tag show, as in any car park, and fading
## every van in a row smeared them all (tried, 2026-10-04).
func _mark_covering() -> void:
	for th: Dictionary in _things:
		for other: Dictionary in _things:
			if other != th and other.solid and not (other.hint as String).begins_with("look at the van") 					and _covers(th.node, (other.node as Node2D).position + Vector2(0, -6)):
				th.covering = true


## Where a thing stands, by its hint (or far away, if it isn't here).
func _target_of(hint: String) -> Vector2:
	for t: Dictionary in _things:
		if t.hint == hint:
			return (t.node as Node2D).position
	return Vector2.INF


## What you'd use: the thing in front of you, else the nearest you're by.
func _target() -> Dictionary:
	var ahead := walker.global_position + Vector2.RIGHT.rotated(walker.rotation) * 12.0
	var best := {}
	var best_d := INF
	for t: Dictionary in _things:
		var r: Rect2 = (t.rect as Rect2).grow(REACH)
		if r.has_point(ahead) or r.has_point(walker.global_position):
			var d := (t.rect as Rect2).get_center().distance_to(ahead)
			if d < best_d:
				best = t
				best_d = d
	return best


## Use what you're by (tests call it by its hint, too).
func use(hint_start := "") -> void:
	var t := _target()
	if hint_start != "":
		for th: Dictionary in _things:
			if (th.hint as String).begins_with(hint_start):
				t = th
				break
	if not t.is_empty():
		(t.act as Callable).call()


func _unhandled_input(event: InputEvent) -> void:
	if _card:
		if event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_close_card()
			get_viewport().set_input_as_handled()
		return
	if not _carry.is_empty():
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_end_carry(false)
		elif event.is_action_pressed("throw") and _carry.item.kind != "van":
			_carry.turned = not _carry.turned
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("hop") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_end_carry(true)
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled() # first: a door or the desk takes this place out of the tree
		use()
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_planner()


# ---------------------------------------------------------------- cards

## A card over the place: a title, lines, and buttons, each [text, do, disabled?]. Doing one
## shuts the card and lays the place out again (what's changed shows).
func _open_card(title: String, lines: Array[String], acts: Array) -> void:
	_close_card()
	var box := UI.vbox(10)
	box.add_child(UI.label(title, 30, UI.GOLD))
	for l: String in lines:
		var lab := UI.label(l, 20)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size.x = 640
		box.add_child(lab)
	var first: Button = null
	for a: Array in acts:
		var b := UI.button(a[0], func() -> void:
			(a[1] as Callable).call()
			Game.save()
			if a.size() > 3 and a[3] == "stay": # the act's own: another card, or something picked up
				return
			if not _leaving: # what's changed shows: the place again, you where you stood
				_stood = walker.position
				_leaving = true
				get_tree().reload_current_scene(), 20)
		b.disabled = a.size() > 2 and a[2]
		box.add_child(b)
		if first == null and not b.disabled:
			first = b
	var back := UI.button("Back " + Game.key("hop"), _close_card, 20)
	back.name = "CardBack"
	box.add_child(back)
	var p := UI.panel(box)
	p.name = "Card"
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.add_child(p)
	centre.theme = UI.theme()
	_card = centre
	_layer.add_child(centre)
	UI.focus(first if first else back)
	_hint.text = ""
	if walker:
		walker.set_physics_process(false) # the stick's for the card's buttons now
		walker.velocity = Vector2.ZERO


func _close_card() -> void:
	if _card:
		_card.queue_free()
		_card = null
	if walker:
		walker.set_physics_process(true)
