extends Node2D
## Your own places between jobs (design doc, The hub): the office, the yard and the shop in
## town, walked round on foot in the job's 3/4 view. Tangible things live here and say what
## they are when you're by them; interact and a card says the rest (or the desk opens the
## paper things: the calendar, the paper, the client book). Walking costs no time; the drive
## to the shop and back does. Game.place says where you are, Game.spot where you stand.
## Anything waiting to be read (the day's end, payday, court...) is the desk's, first.

const WalkerScript := preload("res://walker.gd")
const CELL := Vector2(20, 12) ## a yard cell as drawn: the truck's packing cell, its depth seen 3/4
const REACH := 14.0 ## how far past a thing's footprint you can use it
const WALL := Color("b8a47a")
const WALL_DARK := Color("8a7650")
const TAG := Color("f8e8c0")

var walker: CharacterBody2D
var cam: Camera2D
var _world: Node2D ## y-sorted: you and the things
var _things: Array[Dictionary] = [] ## {node, rect (ground footprint), hint, act}
var _bounds := Rect2() ## where you can walk
var _hint: Label
var _card: Control = null
var _layer: CanvasLayer
var _leaving := false ## an act's taken you somewhere else: don't lay this place out again
static var _stood := Vector2.INF ## where you stood when a card's act laid the place out again


func _ready() -> void:
	if not Game.day_end.is_empty() or not Game.blackout.is_empty() or Game.today().has("court") \
			or Game.today().has("jail") or Game.payday_pending or Game.winter_pending: # a day inside: at the desk, calling it a day
		Game.place = "office"
		Game.spot = "desk"
		get_tree().change_scene_to_file.call_deferred("res://board.tscn") # the desk has it to read
		return
	Sfx.music("music_menu")
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	match Game.place:
		"yard":
			_yard()
		"shop":
			_shop()
		_:
			_office()
	_layer = CanvasLayer.new()
	add_child(_layer)
	var top := UI.label("", 20, UI.GOLD)
	top.name = "Where"
	top.position = Vector2(20, 14)
	top.text = "%s   %s   %s   $%d" % [{"office": "The office", "yard": "The yard", "shop": "The mower shop"}[Game.place],
		Game.date_text(), Game.time_text(Game.minute), Game.money]
	UI.shadow(top, 2)
	_layer.add_child(top)
	_hint = UI.label("", 20)
	_hint.name = "Hint"
	_hint.position = Vector2(20, 680)
	UI.shadow(_hint, 2)
	_layer.add_child(_hint)


## Lay out a room: its floor (a tiled texture), the back wall, and where you can walk.
func _room(floor_rect: Rect2, tile: Texture2D, wall_h: float) -> void:
	var dark := ColorRect.new() # beyond the room
	dark.color = UI.BG
	dark.position = floor_rect.position - Vector2(2000, 2000)
	dark.size = floor_rect.size + Vector2(4000, 4000)
	dark.z_index = -20
	add_child(dark)
	var ground := Node2D.new()
	ground.z_index = -10
	ground.draw.connect(func() -> void:
		ground.draw_texture_rect(tile, floor_rect, true)
		if wall_h > 0.0:
			var w := Rect2(floor_rect.position - Vector2(0, wall_h), Vector2(floor_rect.size.x, wall_h))
			ground.draw_rect(w, WALL)
			ground.draw_rect(Rect2(w.position, Vector2(w.size.x, 4)), WALL_DARK)
			ground.draw_rect(Rect2(w.position + Vector2(0, w.size.y - 6), Vector2(w.size.x, 6)), WALL_DARK)
			ground.draw_rect(Rect2(w.position + Vector2(0, w.size.y * 0.45), Vector2(w.size.x, 2)), WALL_DARK))
	add_child(ground)
	_bounds = floor_rect.grow(-8.0)


## Put a thing in the place: drawn standing on `foot` (its sprite's bottom centre there,
## or `paint` called with the node), taking up `ground` (a size, centred on foot, reaching
## back from it); `hint` what interacting does, `act` doing it. Solid unless said.
func _thing(foot: Vector2, ground: Vector2, hint: String, act: Callable, tex: Texture2D = null, paint: Callable = Callable(), solid := true) -> Node2D:
	var n := Node2D.new()
	n.position = foot
	if tex:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = Vector2(-tex.get_width() / 2.0, -tex.get_height())
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
		_things.append({"node": n, "rect": rect, "hint": hint, "act": act})
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


# ---------------------------------------------------------------- the office

func _office() -> void:
	var floor_rect := Rect2(0, 0, 400, 200)
	_room(floor_rect, preload("res://art/floorboards.png"), 90.0)
	# The desk space: the corkboard calendar on the wall, the desk under it.
	var cork := Sprite2D.new()
	cork.texture = preload("res://art/corkboard.png")
	cork.position = Vector2(150, -48)
	cork.z_index = -5
	add_child(cork)
	_thing(Vector2(150, 56), Vector2(80, 26), "use the desk (the calendar, the paper, the phone, the client book)", _to_desk,
		preload("res://art/desk.png"))
	var door := Sprite2D.new() # out to the yard, in the back wall
	door.texture = preload("res://art/door.png")
	door.position = Vector2(340, -28)
	door.z_index = -5
	add_child(door)
	_thing(Vector2(340, 8), Vector2(34, 8), "go out to the yard", _go_to.bind("yard", "office_door"), null, Callable(), false)
	_spawn(Vector2(150, 80) if Game.spot == "desk" else Vector2(340, 30), Vector2(200, 60))


func _to_desk() -> void:
	_leaving = true
	Game.place = "office"
	Game.spot = "desk"
	get_tree().change_scene_to_file("res://board.tscn")


## Walk through a door to another place (`spot`: where you come in).
func _go_to(where: String, from: String) -> void:
	_leaving = true
	Game.place = where
	Game.spot = from
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- the yard

## The yard's floor, at the origin: everything you keep, placed for you (Game.yard_layout).
func _yard() -> void:
	var wide := Game.YARD_W * CELL.x
	var depth := Game.yard_rows * CELL.y
	var floor_rect := Rect2(-90, -10, wide + 310, depth + 180)
	_room(floor_rect, preload("res://art/gravel.png"), 0.0)
	var lines := Node2D.new() # the storage floor, painted out
	lines.z_index = -9
	lines.draw.connect(func() -> void:
		lines.draw_rect(Rect2(0, 0, wide, depth), Color(1, 1, 1, 0.06))
		for i in Game.YARD_W + 1:
			lines.draw_line(Vector2(i * CELL.x, 0), Vector2(i * CELL.x, depth), Color(1, 1, 1, 0.08), 1.0)
		for i in Game.yard_rows + 1:
			lines.draw_line(Vector2(0, i * CELL.y), Vector2(wide, i * CELL.y), Color(1, 1, 1, 0.08), 1.0)
		lines.draw_rect(Rect2(0, 0, wide, depth), Color("f8e070", 0.5), false, 2.0))
	add_child(lines)
	# The office's back door, in its wall along the top.
	var wall := Node2D.new()
	wall.z_index = -8
	wall.draw.connect(func() -> void:
		wall.draw_rect(Rect2(floor_rect.position.x, -70, floor_rect.size.x, 60), Color("84402a"))
		wall.draw_rect(Rect2(floor_rect.position.x, -16, floor_rect.size.x, 6), Color("5e2c1e")))
	add_child(wall)
	var door := Sprite2D.new()
	door.texture = preload("res://art/door.png")
	door.position = Vector2(wide + 60, -38)
	door.z_index = -7
	add_child(door)
	_thing(Vector2(wide + 60, -2), Vector2(34, 8), "go into the office", _go_to.bind("office", "yard_door"), null, Callable(), false)
	var lay := Game.yard_layout()
	for p: Dictionary in lay.placed:
		_yard_item(p.item, Vector2(p.at) * CELL, Vector2(p.size) * CELL)
	var x := 0.0 # what's got no room, stood about below the floor
	for it: Dictionary in lay.over:
		var sz := Vector2(Game.FOOT[it.kind]) * CELL
		_yard_item(it, Vector2(x, depth + 50), sz) # no room for it: over the edge, till it's sold
		x += sz.x + 10.0
	# Your truck by the gate; the signpost for more yard.
	var truck_at := Vector2(wide + 120, depth + 30)
	_thing(truck_at, Vector2(120, 34), "get in your truck", _truck_card, preload("res://art/truck.png"))
	var sign_at := Vector2(-45, depth)
	var sp := _thing(sign_at, Vector2(20, 8), "read the sign (more yard)", _yard_sign, preload("res://art/signpost.png"))
	_tag(sp, "More yard $%d" % Game.price_of("yard"), Vector2(0, -62))
	_spawn(truck_at + Vector2(-10, 30) if Game.spot == "truck" else Vector2(wide + 60, 14))


## A van, a mower or a robot on the yard's floor, its sprite standing in its cells.
func _yard_item(it: Dictionary, at: Vector2, sz: Vector2) -> void:
	var foot := at + Vector2(sz.x / 2.0, sz.y)
	var hint := ""
	var tex: Texture2D = null
	var paint := Callable()
	match it.kind:
		"van":
			var h: Dictionary = Game.helpers[it.n] if it.n < Game.helpers.size() else {}
			hint = "look in %s van" % (h.name.split(" ")[0] + "'s" if not h.is_empty() else "the empty")
			tex = preload("res://art/van.png")
		"robot":
			hint = "look at the robot mower"
			paint = func(on: Node2D) -> void: Robot.draw(on, Vector2(0, -10))
		_:
			hint = "look at %s %s" % ["the crew's" if it.get("crew", false) else "your", Game.MOWERS[it.kind].name.to_lower()]
			var sheet: Texture2D = load("res://art/mower_%s.png" % it.kind)
			var trailer: Texture2D = preload("res://art/trailer.png") if it.kind == "rideon" else null
			paint = func(on: Node2D) -> void:
				if trailer:
					on.draw_texture(trailer, Vector2(-trailer.get_width() / 2.0, -trailer.get_height() + 4))
				Facing.draw(on, sheet, 3, 2, 0.0, Vector2(0, -24.0 if trailer else -12.0))
	var n := _thing(foot - Vector2(0, 1), Vector2(sz.x - 4, sz.y - 2), hint, _yard_card.bind(it), tex, paint)
	if it.kind == "van":
		var h: Dictionary = Game.helpers[it.n] if it.n < Game.helpers.size() else {}
		_tag(n, h.name.split(" ")[0] + (" !" if h.has("asks") else "") if not h.is_empty() else "empty", Vector2(0, -108),
			UI.GOLD if h.has("asks") else TAG)
	elif it.get("crew", false):
		var who := Game.helpers.filter(func(h: Dictionary) -> bool: return h.kit == it.kind)
		_tag(n, "crew" + (": " + who[0].name.split(" ")[0] if it.kind == "rideon" and it.n < who.size() else ""), Vector2(0, -44))


## The card for something in the yard: what it is, and what you can do with it.
func _yard_card(it: Dictionary) -> void:
	var lines: Array[String] = []
	var acts: Array = []
	var title := ""
	match it.kind:
		"van":
			var h: Dictionary = Game.helpers[it.n] if it.n < Game.helpers.size() else {}
			if h.is_empty():
				title = "An empty van"
				lines.append("Nobody's in it. Ring a situation wanted in the paper to hire someone.")
			else:
				title = h.name
				lines.append("%s. $%d a week, %d job%s done." % [Game.card_text(h).capitalize(), h.wage, h.jobs, "" if h.jobs == 1 else "s"])
				lines.append("Mows with: %s%s." % [Game.MOWERS[h.kit].name.to_lower(), " (in the van)" if h.kit == "petrol" else (" (on its trailer in the yard)" if h.kit == "rideon" else "")])
				if h.has("asks"):
					lines.append("Asking $%d a week." % h.asks)
					acts.append(["Pay it", func() -> void: Game.answer_raise(h.id, true)])
					acts.append(["Say no", func() -> void: Game.answer_raise(h.id, false)])
				if h.kit != "push":
					var free: bool = Game.yard_room(h.kit) or h.kit == "rideon"
					acts.append(["Take the %s back" % Game.MOWERS[h.kit].name.to_lower() if free else "No room in the yard for their mower",
						func() -> void: Game.set_kit(h.id, "push"), not free])
				acts.append(["Let %s go" % h.name.split(" ")[0], func() -> void: Game.let_go(h.id)])
			lines.append("Takes %s in the yard." % _cells("van"))
			acts.append(["Sell the van, $%d%s" % [Game.resale("van"), "" if h.is_empty() else " (%s goes too)" % h.name.split(" ")[0]], func() -> void:
				if not h.is_empty():
					Game.let_go(h.id) # this van's helper, not the last hired
				Game.sell("van")])
		"robot":
			title = Game.ROBOT.name
			lines.append(Game.ROBOT.blurb + " You pack it in the truck's bed, or the trailer.")
			lines.append("Takes %s in the yard." % _cells("robot"))
			if "trailer" not in Game.upgrades:
				_upgrade(acts, "trailer")
			acts.append(["Sell it, $%d" % Game.resale("robot"), func() -> void: Game.sell("robot")])
		_:
			var m: Dictionary = Game.MOWERS[it.kind]
			if it.get("crew", false):
				title = "The crew's " + m.name.to_lower()
				var on := Game.helpers.filter(func(h: Dictionary) -> bool: return h.kit == it.kind)
				lines.append(m.blurb + " A helper on it mows quicker.")
				if it.kind == "rideon" and it.n < on.size():
					lines.append("%s has it." % on[it.n].name.split(" ")[0])
				else:
					for h: Dictionary in Game.helpers:
						if h.kit != it.kind:
							acts.append(["Give it to %s" % h.name.split(" ")[0], func() -> void: Game.set_kit(h.id, it.kind)])
				acts.append(["Sell it, $%d" % Game.resale("crew_" + it.kind), func() -> void: Game.sell("crew_" + it.kind)])
			else:
				title = "Your " + m.name.to_lower()
				lines.append(m.blurb + (" It rides in the cab." if it.kind == "push" else " Packed in the truck before each job."))
				for u: String in ["tank", "blades"] + (["gear3", "gear4"] if it.kind == "rideon" else []):
					_upgrade(acts, u)
				if it.kind != "push":
					acts.append(["Sell it, $%d" % Game.resale(it.kind), func() -> void: Game.sell(it.kind)])
			lines.append("Takes %s in the yard." % _cells(it.kind))
	_open_card(title, lines, acts)


## An upgrade to buy from a card: what it does, and its price (or why not).
func _upgrade(acts: Array, u: String) -> void:
	var why := Game.cant_buy(u)
	if why == "You've got it":
		return
	acts.append(["%s, $%d: %s" % [Game.UPGRADES[u].name, Game.UPGRADES[u].price, Game.UPGRADES[u].blurb] + ("" if why == "" else " (%s)" % why.to_lower()),
		func() -> void: Game.buy(u), why != ""])


func _cells(kind: String) -> String:
	var f: Vector2i = Game.FOOT[kind]
	return "%d by %d" % [f.x, f.y]


## The signpost: more yard, for a price.
func _yard_sign() -> void:
	var why := Game.cant_buy("yard")
	_open_card("More yard", ["The plot next door: %d more rows of %d. Everything you keep takes room: vans, mowers, robots." % [Game.YARD_MORE, Game.YARD_W],
		"Your yard: %d by %d." % [Game.YARD_W, Game.yard_rows]],
		[["Buy it, $%d" % Game.price_of("yard") + ("" if why == "" else " (%s)" % why.to_lower()), func() -> void: Game.buy("yard"), why != ""]])


## Your truck: today's jobs you can still reach (packing first, then off), or the shop.
func _truck_card() -> void:
	var acts: Array = []
	var lines: Array[String] = []
	for b: Dictionary in Game.jobs_today():
		if Game.can_go(b):
			acts.append(["Go to %s: there at %s" % [b.customer, Game.time_text(Game.arrival(b))], go.bind(b)])
		else:
			lines.append("Too late for %s." % b.customer)
	if Game.jobs_today().is_empty():
		lines.append("Nothing for you today. Call it a day at the desk.")
	var shut := Game.minute + Game.DRIVE >= Game.DAY_END
	acts.append(["Drive to the mower shop, +%d min" % Game.DRIVE if not shut else "The shop's shut", drive_to_shop, shut])
	_open_card("Your truck", lines, acts)


## Off to a job: packing first (pack.gd), then the job.
func go(b: Dictionary) -> void:
	_leaving = true
	Game.next_job = b
	Game.place = "yard"
	Game.spot = "truck"
	get_tree().change_scene_to_file("res://pack.tscn")


func drive_to_shop() -> void:
	_leaving = true
	Game.minute += Game.DRIVE
	Game.place = "shop"
	Game.spot = "door"
	Game.save()
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- the shop

## The mower shop in town: what's for sale stood about with its price over it; interact for
## the card. The counter has the small things; the door, your truck home.
func _shop() -> void:
	var floor_rect := Rect2(0, 0, 520, 230)
	_room(floor_rect, preload("res://art/paving.png"), 80.0)
	var shelf := Sprite2D.new()
	shelf.texture = preload("res://art/shelf.png")
	shelf.position = Vector2(70, -40)
	shelf.z_index = -5
	add_child(shelf)
	var shelf2 := Sprite2D.new()
	shelf2.texture = preload("res://art/shelf.png")
	shelf2.position = Vector2(170, -40)
	shelf2.z_index = -5
	add_child(shelf2)
	var counter := _thing(Vector2(120, 110), Vector2(92, 18), "look at the counter (gloves, a trailer)", _counter_card, preload("res://art/counter.png"))
	_tag(counter, "Gloves $%d   Trailer $%d" % [Game.UPGRADES.gloves.price, Game.UPGRADES.trailer.price], Vector2(0, -70))
	var stock := [["petrol", Vector2(270, 90)], ["rideon", Vector2(360, 100)], ["robot", Vector2(450, 90)], ["van", Vector2(330, 200)]]
	for s: Array in stock:
		_stock(s[0], s[1])
	var door := Sprite2D.new()
	door.texture = preload("res://art/door.png")
	door.position = Vector2(480, -28)
	door.z_index = -5
	add_child(door)
	_thing(Vector2(480, 8), Vector2(34, 8), "drive home, +%d min" % Game.DRIVE, drive_home, null, Callable(), false)
	_spawn(Vector2(480, 30), Vector2(260, 70))


func _stock(kind: String, foot: Vector2) -> void:
	var n: Node2D
	var price: int = Game.VAN.price if kind == "van" else (Game.ROBOT.price if kind == "robot" else Game.MOWERS[kind].price)
	if kind == "van":
		n = _thing(foot, Vector2(130, 30), "look at the van", _stock_card.bind(kind), preload("res://art/van.png"))
		_tag(n, "VAN $%d" % price, Vector2(0, -118))
		return
	if kind == "robot":
		n = _thing(foot, Vector2(24, 14), "look at the robot mower", _stock_card.bind(kind), null, func(c: Node2D) -> void: Robot.draw(c, Vector2(0, -10)))
	else:
		var sheet: Texture2D = load("res://art/mower_%s.png" % kind)
		n = _thing(foot, Vector2(44 if kind == "rideon" else 30, 20), "look at the %s" % Game.MOWERS[kind].name.to_lower(), _stock_card.bind(kind), null,
			func(c: Node2D) -> void: Facing.draw(c, sheet, 3, 2, PI * 0.75, Vector2(0, -14.0)))
	_tag(n, "$%d" % price, Vector2(0, -52))


## A thing for sale: what it is, how it compares with yours, the room it takes, and buying
## it (for you, or once you've one, another for the crew).
func _stock_card(kind: String) -> void:
	var lines: Array[String] = []
	var acts: Array = []
	var title := ""
	if kind == "van":
		title = Game.VAN.name
		lines.append(Game.VAN.blurb + " You've %d." % Game.vans)
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
			lines.append("You've got one. Another would be the crew's.")
			_buy(acts, "crew_" + kind, "Buy one for the crew")
		else:
			_buy(acts, kind, "Buy it")
			if not Game.helpers.is_empty():
				_buy(acts, "crew_" + kind, "Buy one for the crew")
	lines.append("Takes %s in your yard." % _cells(kind))
	_open_card(title, lines, acts)


func _buy(acts: Array, item: String, label: String) -> void:
	var why := Game.cant_buy(item)
	acts.append(["%s, $%d%s" % [label, Game.price_of(item), "" if why == "" else " (%s)" % why.to_lower()], func() -> void: Game.buy(item), why != ""])


func _counter_card() -> void:
	var acts: Array = []
	for u: String in ["gloves", "trailer"]:
		_upgrade(acts, u)
	_open_card("The counter", ["Gloves and trailers. Mower upgrades are fitted at home: see your mowers in the yard."] if not acts.is_empty()
		else ["Nothing else you need. Mower upgrades are fitted at home: see your mowers in the yard."], acts)


func drive_home() -> void:
	_leaving = true
	Game.minute += Game.DRIVE
	Game.place = "yard"
	Game.spot = "truck"
	Game.save()
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- walking about

func _physics_process(_delta: float) -> void:
	if walker == null or _card:
		return
	var t := _target()
	_hint.text = (Game.key("interact") + " " + t.hint) if not t.is_empty() else ""
	for th: Dictionary in _things: # stood behind something tall (a van): see through it
		var n: Node2D = th.node
		var spr := n.get_child(0) as Sprite2D
		if spr:
			var behind := walker.position.y < n.position.y and Rect2(n.position + spr.position, spr.texture.get_size()).has_point(walker.position)
			n.modulate.a = 0.45 if behind else 1.0


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
	if event.is_action_pressed("interact"):
		use()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_open_card("Paused", [], [["Save and quit", func() -> void:
			_leaving = true
			Game.save()
			Game.in_run = false
			get_tree().change_scene_to_file("res://title.tscn")]])
		get_viewport().set_input_as_handled()


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
			if not _leaving: # what's changed shows: the place again, you where you stood
				_stood = walker.position
				_leaving = true
				get_tree().reload_current_scene(), 20)
		b.disabled = a.size() > 2 and a[2]
		box.add_child(b)
		if first == null and not b.disabled:
			first = b
	var back := UI.button("Back (%s)" % Game.key("hop"), _close_card, 20)
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
