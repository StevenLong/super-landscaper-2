extends Node2D
## One job: builds the garden from Game.job(), runs the customer's mood, and ends
## in a payment, a firing, a knockout, or you driving off; the board then shows the
## rundown. Outside a run (tests, playing this scene directly) it uses the slice's
## hand-made lawn and skips the briefing.

const TreeScript := preload("res://tree.gd")
const BedScript := preload("res://flowerbed.gd")
const HouseScript := preload("res://house.gd")
const WalkerScript := preload("res://walker.gd")

const WINDOWS := [40, 120, 290, 370] ## x of each window in the house art (30 wide, y 69..93)
const REPAIR_PRICE := 0.5 ## per condition point repaired
const WINDOW_BILL := 40.0
const DENT_BILL := 20.0
const CRITTER_HIT := 16.0 ## how close a thrown stone must pass to hit a critter (they're small and moving)
const BORDER := 24 ## hedge/fence thickness, drawn just outside the lawn
const FOOTPATH := 40 ## the pavement between the front hedge and the kerb
const ROAD := 150
const GRAVEL := Color(1.0, 0.88, 0.68) ## tints the grey gravel tile for the drive

@export var hedgehog_every := 7.0 ## seconds between hedgehogs, roughly
@export var squirrel_every := 13.0
@export var max_animals := 5

var job: Dictionary
var customer: Customer
var tally := {} ## everything countable this job, key -> count (Game.TALLY names them)
var tally_cost := {} ## key -> dollars those cost you
var over := false
var bills := 0.0 ## broken windows, dented truck
var walker: CharacterBody2D = null ## the player on foot, or null while mowing
var dog: Dog = null
var settled := {} ## the job's outcome once paid or fired; you stay until you drive off
var mischief := 0.0 ## reputation owed for what you did after it was settled

var _next_hedgehog := 3.0
var _next_squirrel := 8.0
var _dog_in := -1.0
var _house: Node2D
var _shake := 0.0
var _edges: Array[Dictionary] = [] ## where critters come in: {kind, from, to, inward}
var _tells: Array[Dictionary] = [] ## critters about to come out: {kind, at, grace, left}
var _splats: Array[Vector2] = [] ## squashed critters: they stay for the whole job
var _tracks: Array = [] ## red wheel marks: [position, sideways unit, strength 0..1]
var _blood := 0.0 ## px of red trail the mower has left to lay after running something over
var _blood_from := Vector2.ZERO
var _flowers_quiet_until := 0 ## msec: one scream per burst of flowers, not one per flower

@onready var lawn: Lawn = $Lawn
@onready var mower: CharacterBody2D = $Mower
@onready var hud: CanvasLayer = $HUD
@onready var cam: Camera2D = $Mower/Camera


func _ready() -> void:
	$Decals.draw.connect(_draw_decals)
	job = Game.job()
	customer = Customer.new(job)
	hedgehog_every = job.get("hedgehog_every", hedgehog_every)
	squirrel_every = job.get("squirrel_every", squirrel_every)
	if Game.in_run:
		mower.apply_spec(Game.mower_spec())
	_build_layout()
	if job.get("dog", false):
		_dog_in = randf_range(15.0, 35.0)

	lawn.cut_changed.connect(func(f: float) -> void:
		$HUD/Percent.text = "%d%%" % floori(f * 100.0)
		customer.on_progress(f))
	mower.fuel_changed.connect(func(f: float) -> void: $HUD/Fuel.value = f)
	mower.condition_changed.connect(func(f: float) -> void: $HUD/Condition.value = f)
	$HUD/Fuel.stamina = mower.power == "stamina"
	$HUD/Face.set_look(job.look)
	hud.choice.connect(_on_choice)

	Sfx.music("music_mowing")
	if Game.arrested_on_arrival():
		Game.run_over_reason = "arrested"
		get_tree().paused = true
		hud.open("ARRESTED", ["The police were waiting on the patio.", "Someone recognised your mower.", "",
			"That's the end of your landscaping career."], [["continue", "Continue"]], job.look, "neutral")
		over = true
	elif Game.in_run:
		get_tree().paused = true
		var lines: Array = job.brief.duplicate()
		if job.get("dog", false):
			lines.append("(%s the dog likes to escape. Mind them.)" % job.dog_name)
		lines.append_array(["", "Mow the lawn. Hand in at your truck when you're happy."])
		if Game.jobs_done == 0:
			lines.append_array(["%s %s at the truck. %s hop off to move" % ["Stick drives and turns." if Game.pad
				else "W/S drive, A/D turn.", Game.key("interact"), Game.key("hop")],
				"stones, fetch fuel or catch a dog. Hold %s to look around. %s pause." % [Game.key("look"), Game.key("pause")]])
		hud.open(job.customer, lines, [["start", "Let's go"]], job.look, "neutral")


## Lay out the garden: house along the top with a garage on one side, the drive from
## the garage down to the road, the truck at the kerb, then trees, flowerbeds and
## stones. The default job keeps the slice's hand-placed layout.
func _build_layout() -> void:
	var size: Vector2i = job.size
	lawn.size_px = size
	lawn.setup()
	var fixed: bool = job.get("fixed_layout", false)
	var r := RandomNumberGenerator.new()
	r.seed = job.seed

	_house = HouseScript.new()
	_house.name = "House"
	_house.garage = 1 if fixed else [-1, 1][r.randi() % 2]
	# Centre the house and garage together.
	_house.position = Vector2(size.x * 0.5 - (_house.size.x + _house.GARAGE_W) * 0.5 + (_house.GARAGE_W if _house.garage < 0 else 0.0), 0)
	var wall := StaticBody2D.new() # the house and garage are solid; the patio in front isn't
	for box: Rect2 in [_house.rect(), _house.garage_rect()]:
		var wall_shape := CollisionShape2D.new()
		wall_shape.shape = RectangleShape2D.new()
		wall_shape.shape.size = Vector2(box.size.x, _house.WALL_H)
		wall_shape.position = box.position - _house.position + Vector2(box.size.x, _house.WALL_H) * 0.5
		wall.add_child(wall_shape)
	_house.add_child(wall)
	$Scenery.add_child(_house)
	$Client.position = _house.patio_point()
	$Client.watch = mower
	$Client.set_look(job.look)

	# The drive runs from the garage door to the road; its mouth crosses the pavement.
	var drive: Control = $Driveway
	var g: Rect2 = _house.garage_rect()
	drive.position = Vector2(g.position.x + 10, _house.WALL_H)
	drive.size = Vector2(g.size.x - 20, size.y - _house.WALL_H)
	drive.self_modulate = GRAVEL # warm it so it doesn't read as more road
	lawn.exits = [Rect2(drive.position.x, size.y - 40, drive.size.x, 40 + BORDER + FOOTPATH)]
	$Truck.position = Vector2(drive.position.x + drive.size.x * 0.5, size.y + BORDER + FOOTPATH + 34)
	# Parked along the kerb: the zone reaches back up the drive mouth to where you pull in.
	$Truck/RefuelZone/Shape.position = Vector2(0, -80)
	($Truck/RefuelZone/Shape.shape as RectangleShape2D).size = Vector2(180, 150)
	mower.position = truck_spot()
	mower.rotation = -PI / 2.0 # facing up the drive
	$Truck/Trailer.visible = Game.in_run and "rideon" in Game.owned
	_build_street()

	var taken: Array[Rect2] = [_house.footprint().grow(50), Rect2(drive.position, drive.size).grow(30)]
	var trees: Array = []
	var beds: Array = []
	var stones: Array = []
	var ponds: Array = []
	if fixed:
		trees = [[Vector2(1080, 440), 34.0]]
		beds = [Rect2(360, 300, 200, 80)]
	else:
		for i in job.get("ponds", 0):
			var pr := _place(r, taken, Vector2(Pond.RX, Pond.RY) * 2.0, size)
			if pr.has_area():
				ponds.append(pr.get_center())
		for i in job.beds:
			var br := _place(r, taken, Vector2(r.randf_range(140, 240), r.randf_range(64, 96)), size)
			if br.has_area():
				beds.append(br)
		for i in job.trees:
			var rad: float = [34.0, 42.0, 50.0][r.randi() % 3] # canopy radius: matches the art sizes
			# Room for the canopy and the trunk under it; the trunk's base sits low in the box.
			var spot := _place(r, taken, Vector2(rad * 2.0, rad * 3.0), size)
			if spot.has_area():
				trees.append([spot.get_center() + Vector2(0, rad), rad])
		for i in job.get("stones", 0):
			var sr := _place(r, taken, Vector2(12, 12), size)
			if sr.has_area():
				stones.append(sr.get_center())

	for i in beds.size():
		var b: Node2D = BedScript.new()
		b.name = "Flowerbed" if i == 0 else "Flowerbed%d" % (i + 1)
		b.position = beds[i].position
		b.size = beds[i].size
		_add_area(b)
		b.trampled.connect(_on_trampled)
		$Scenery.add_child(b)
		lawn.exclude_rect(beds[i])
	for i in trees.size():
		var t: StaticBody2D = TreeScript.new()
		t.name = "Tree" if i == 0 else "Tree%d" % (i + 1)
		t.position = trees[i][0]
		t.canopy = trees[i][1]
		t.variant = i
		var cs := CollisionShape2D.new()
		cs.name = "Shape"
		t.add_child(cs)
		$Scenery.add_child(t)
		lawn.exclude_circle(t.position, t.radius)
	for p: Vector2 in ponds:
		var pond := Pond.new()
		pond.position = p
		$Scenery.add_child(pond)
		lawn.exclude_ellipse(p, Pond.RX, Pond.RY)
	for p: Vector2 in stones:
		add_stone(p)
	lawn.exclude_rect(_house.rect())
	lawn.exclude_rect(_house.garage_rect())
	lawn.exclude_rect(Rect2(drive.position, drive.size))
	_build_borders(r, drive)


## Where to pull up in front of the truck: the drive's mouth, on the pavement.
func truck_spot() -> Vector2:
	var d: Control = $Driveway
	return Vector2(d.position.x + d.size.x * 0.5, lawn.size_px.y + 16.0)


## The world past the garden, seen but not reachable: next door's lawns all round,
## and to the south the pavement, the kerb and the road the truck is parked on.
func _build_street() -> void:
	var w := float(lawn.size_px.x)
	var h := float(lawn.size_px.y)
	var world: Node2D = $World
	world.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	world.draw.connect(func() -> void:
		var far := 1200.0 # past anything the zoomed-out camera can show
		var across := Rect2(-far, 0, w + far * 2.0, 0)
		# Next door's lawns, a touch duller than the one you're mowing.
		world.draw_texture_rect(preload("res://art/grass_light.png"), Rect2(-far, -far, w + far * 2.0, h + far * 2.0), true, Color(0.72, 0.8, 0.7))
		var path_y := h + BORDER
		var road_y := path_y + FOOTPATH
		world.draw_texture_rect(preload("res://art/paving.png"), Rect2(across.position.x, path_y, across.size.x, FOOTPATH), true)
		world.draw_texture_rect(preload("res://art/asphalt.png"), Rect2(across.position.x, road_y, across.size.x, ROAD), true)
		world.draw_texture_rect(preload("res://art/paving.png"), Rect2(across.position.x, road_y + ROAD, across.size.x, FOOTPATH), true)
		for y: float in [road_y, road_y + ROAD - 3.0]: # kerbs
			world.draw_rect(Rect2(across.position.x, y, across.size.x, 3.0), Color("a8a8b0"))
		var x := -far
		while x < w + far: # the centre line
			world.draw_rect(Rect2(x, road_y + ROAD * 0.5 - 1.5, 24.0, 3.0), Color("e8e4d0"))
			x += 56.0)


## Hedges and fences round the property, just outside the lawn. Each side is one or
## the other; the top only has the bits either side of the house and garage; the
## bottom leaves a gap where the drive goes out to the road.
func _build_borders(r: RandomNumberGenerator, drive: Control) -> void:
	var w := float(lawn.size_px.x)
	var h := float(lawn.size_px.y)
	var b := float(BORDER)
	var top: String = ["hedge", "fence"][r.randi() % 2]
	# name: [kind, outer rect, the lawn-side line critters come in along, inward direction]
	var fp: Rect2 = _house.footprint()
	var front: String = ["hedge", "fence"][r.randi() % 2]
	var d0 := drive.position.x
	var d1 := drive.position.x + drive.size.x
	var sides := {
		"top_l": [top, Rect2(-b, -b, fp.position.x + b, b), [Vector2(0, 0), Vector2(fp.position.x, 0)], Vector2.DOWN],
		"top_r": [top, Rect2(fp.end.x, -b, w - fp.end.x + b, b), [Vector2(fp.end.x, 0), Vector2(w, 0)], Vector2.DOWN],
		"left": [["hedge", "fence"][r.randi() % 2], Rect2(-b, -b, b, h + 2.0 * b), [Vector2(0, 0), Vector2(0, h)], Vector2.RIGHT],
		"right": [["hedge", "fence"][r.randi() % 2], Rect2(w, -b, b, h + 2.0 * b), [Vector2(w, 0), Vector2(w, h)], Vector2.LEFT],
		"bottom_l": [front, Rect2(-b, h, d0 + b, b), [Vector2(0, h), Vector2(d0, h)], Vector2.UP],
		"bottom_r": [front, Rect2(d1, h, w - d1 + b, b), [Vector2(d1, h), Vector2(w, h)], Vector2.UP],
	}
	var mouth := TextureRect.new() # the drive carries on across the pavement to the road
	mouth.texture = preload("res://art/gravel.png")
	mouth.stretch_mode = TextureRect.STRETCH_TILE
	mouth.position = Vector2(d0, h)
	mouth.size = Vector2(drive.size.x, b + FOOTPATH)
	mouth.self_modulate = GRAVEL
	$Borders.add_child(mouth)
	for key: String in sides:
		var s: Array = sides[key]
		var vertical: bool = key == "left" or key == "right"
		var strip := TextureRect.new()
		if s[0] == "hedge":
			strip.texture = preload("res://art/hedge.png")
		else:
			strip.texture = preload("res://art/fence_v.png") if vertical else preload("res://art/fence_h.png")
		strip.stretch_mode = TextureRect.STRETCH_TILE
		strip.position = (s[1] as Rect2).position
		strip.size = (s[1] as Rect2).size
		$Borders.add_child(strip)
		if (s[2][0] as Vector2).distance_to(s[2][1]) > 40.0: # too short to come out of
			_edges.append({"kind": s[0], "from": s[2][0], "to": s[2][1], "inward": s[3]})


## Is p inside something a critter can't walk through?
func _blocked(p: Vector2) -> bool:
	if _house.footprint().has_point(p):
		return true
	if Rect2($Truck.position - Vector2(64, 32), Vector2(128, 64)).has_point(p):
		return true
	for t in $Scenery.get_children():
		if t is Pond and t.contains(p):
			return true
		if t is StaticBody2D and "radius" in t and p.distance_to(t.position) < t.radius + 4.0:
			return true
	return false


func _add_area(bed: Node2D) -> void:
	var a := Area2D.new()
	a.name = "Area"
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	a.add_child(cs)
	bed.add_child(a)


## A random rect of the given size on the lawn that avoids everything already placed.
func _place(r: RandomNumberGenerator, taken: Array[Rect2], sz: Vector2, lawn_size: Vector2i) -> Rect2:
	for attempt in 40:
		var p := Vector2(r.randf_range(40, lawn_size.x - sz.x - 40), r.randf_range(40, lawn_size.y - sz.y - 40))
		var rect := Rect2(p, sz)
		if taken.all(func(t: Rect2) -> bool: return not t.intersects(rect.grow(60))):
			taken.append(rect)
			return rect
	return Rect2()


func add_stone(p: Vector2) -> Stone:
	var s := Stone.new()
	s.position = p
	s.mowed_over.connect(_on_stone_mowed)
	$Stones.add_child(s)
	return s


# ---------------------------------------------------------------- the loop

func _process(delta: float) -> void:
	# Hold [Tab] to pull the camera back and see more of the garden.
	var want := 1.0 if Input.is_action_pressed("look") and not get_tree().paused else 2.0
	cam.zoom = cam.zoom.lerp(Vector2(want, want), minf(1.0, delta * 8.0))
	_shake = maxf(0.0, _shake - delta * 18.0)
	cam.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_lay_track()
	# A canopy fades while you're under it or close, so nothing hides there.
	var me := actor().global_position
	for t in $Scenery.get_children():
		if "canopy" in t:
			t.near = t.crown_rect().grow(20.0).has_point(me) or me.distance_to(t.position) < t.radius + 30.0


const TRAIL := 140.0 ## how far the mower trails red after running a critter over


## After a squash the mower lays fading red wheel marks for a short way.
func _lay_track() -> void:
	var moved := mower.global_position.distance_to(_blood_from)
	if _blood <= 0.0 or moved < 3.0:
		return
	_blood -= moved
	_blood_from = mower.global_position
	_tracks.append([_blood_from, Vector2.DOWN.rotated(mower.rotation), clampf(_blood / TRAIL, 0.0, 1.0)])
	$Decals.queue_redraw()


func _draw_decals() -> void:
	var d: Node2D = $Decals
	var splat := preload("res://art/splat.png")
	for p in _splats:
		d.draw_texture(splat, p - splat.get_size() / 2.0)
	for t: Array in _tracks:
		var c := Color(0.55, 0.04, 0.04, 0.85 * t[2])
		for side: float in [-7.0, 7.0]:
			d.draw_rect(Rect2(t[0] + t[1] * side - Vector2(1.5, 1.5), Vector2(3, 3)), c)


## A camera shake of the given strength in pixels, decaying fast.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Floating text in the world, rising and fading: bills, thanks, that sort of thing.
func pop_text(text: String, at: Vector2, color := Color("f8d048")) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	UI.shadow(l, 1)
	l.position = at - Vector2(30, 20)
	l.z_index = 5
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 30.0, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(l.queue_free)


func _physics_process(delta: float) -> void:
	if over:
		return
	var nag := customer.tick(delta)
	if nag != "":
		_react()
	hud.set_clock(customer.elapsed)
	$HUD/Face.expression = customer.face()
	if customer.fired and settled.is_empty():
		_fired()
	hud.set_hint(_hint())

	# Running over the customer on their patio. Don't.
	if not customer.knocked_out and mower.velocity.length() > 40.0 \
			and mower.global_position.distance_to($Client.position + Vector2(0, -10)) < 22.0:
		Game.heat += 1.0
		_knock_out()

	if _dog_in > 0.0:
		_dog_in -= delta
		if _dog_in <= 0.0 and not customer.knocked_out:
			_release_dog()

	_next_hedgehog -= delta
	_next_squirrel -= delta
	if _next_hedgehog <= 0.0:
		_next_hedgehog = hedgehog_every * randf_range(0.6, 1.4)
		_tell("hedgehog")
	if _next_squirrel <= 0.0:
		_next_squirrel = squirrel_every * randf_range(0.6, 1.4)
		_tell("squirrel")
	for t: Dictionary in _tells.duplicate():
		t.left -= delta
		if t.left <= 0.0:
			_tells.erase(t)
			spawn_animal(t.kind, t.at, Vector2.INF, t.grace)


func _fired_hint() -> String:
	return "Fired: no pay. Leave from the truck %s when you're done." % Game.key("interact")


## Who the player is right now: the mower, or themselves on foot.
func actor() -> Node2D:
	return walker if walker else mower


func at_truck() -> bool:
	return $Truck/RefuelZone.overlaps_body(actor())


func _hint() -> String:
	if walker:
		match walker.carrying:
			"stone":
				return Game.key("interact") + (" toss it in the truck" if at_truck() else " drop it") + "   %s throw it" % Game.key("throw")
			"jerrycan":
				return Game.key("interact") + " fill up the mower" if walker.global_position.distance_to(mower.global_position) < 44.0 else "Take the can to the mower"
		if _stone_near(walker.global_position):
			return Game.key("interact") + " pick up the stone"
		if dog and is_instance_valid(dog):
			if dog.following == walker:
				return "Walk %s back to the patio" % job.dog_name
			if not dog.limping and walker.global_position.distance_to(dog.position) < 80.0:
				return "Walk into %s to put them on the lead" % job.dog_name
		if at_truck():
			return Game.key("interact") + " truck"
		if walker.global_position.distance_to(mower.global_position) < 44.0:
			return Game.key("hop") + " get back on"
		return _fired_hint() if customer.fired else ""
	if at_truck():
		return Game.key("interact") + " talk to the customer / leave"
	return _fired_hint() if customer.fired else ""


func _unhandled_input(event: InputEvent) -> void:
	if over or hud.is_open():
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_0:
		_cheat_win()
	elif event.is_action_pressed("pause"):
		open_pause()
	elif event.is_action_pressed("hop"):
		if walker == null:
			hop_off()
		elif walker.carrying == "" and walker.global_position.distance_to(mower.global_position) < 44.0:
			hop_on()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("throw") and walker and walker.carrying == "stone":
		walker.carrying = ""
		walker.queue_redraw()
		var dir := Vector2.RIGHT.rotated(walker.rotation)
		throw_stone(walker.global_position + dir * 12.0, dir, 460.0, 260.0)
		_count("stones_thrown")
		Sfx.play("ui_move")


# ---------------------------------------------------------------- on foot

func hop_off() -> void:
	walker = WalkerScript.new()
	var side := Vector2(0, 26).rotated(mower.rotation)
	walker.position = lawn.keep_in(mower.global_position + side, 12.0)
	walker.keep_in = lawn.keep_in.bind(8.0)
	add_child(walker)
	mower.occupied = false
	cam.reparent(walker, false)
	$Client.watch = walker


func hop_on() -> void:
	cam.reparent(mower, false)
	walker.queue_free()
	walker = null
	mower.occupied = true
	$Client.watch = mower


func interact() -> void:
	if walker == null:
		if at_truck():
			open_truck_menu()
		return
	match walker.carrying:
		"stone":
			if not at_truck():
				add_stone(walker.global_position + Vector2(14, 0).rotated(walker.rotation))
			else:
				_count("stones_binned")
			Sfx.play("bump")
			walker.carrying = ""
			walker.queue_redraw()
		"jerrycan":
			if walker.global_position.distance_to(mower.global_position) < 44.0:
				mower.add_fuel(mower.max_fuel)
				_count("cans")
				walker.carrying = ""
				walker.queue_redraw()
				Sfx.play("glug", 0.0)
		_:
			var s := _stone_near(walker.global_position)
			if s:
				s.queue_free()
				_count("stones_picked")
				walker.carrying = "stone"
				walker.queue_redraw()
				Sfx.play("ui_move", 0.0)
			elif at_truck():
				open_truck_menu()


func _stone_near(p: Vector2) -> Stone:
	for s in $Stones.get_children():
		if s is Stone and not s.is_queued_for_deletion() and s.position.distance_to(p) < 18.0:
			return s
	return null


# ---------------------------------------------------------------- the truck

func open_pause() -> void:
	get_tree().paused = true
	hud.open("Paused", [], [["resume", "Resume"], ["music", "Music: %s" % ("on" if Sfx.music_on else "off")],
		["sound", "Sound: %s" % ("on" if Sfx.sound_on else "off")], ["quit", "Quit to title"]])


func open_truck_menu() -> void:
	get_tree().paused = true
	var buttons := []
	if not settled.is_empty():
		buttons.append(["drive_off", "Drive off"])
	elif customer.knocked_out:
		buttons.append(["leave_ko", "Leave quietly"])
	else:
		buttons.append(["handin", "Ask to be paid"])
		buttons.append(["leave", "Drive off (no pay)"])
	if walker and walker.carrying == "" and mower.power == "fuel":
		buttons.append(["can", "Grab the fuel can"])
	buttons.append(["resume", "Keep going"])
	var lines := []
	if settled.get("outcome") == "paid":
		lines = ["\"%s\"" % settled.comment, "They handed over $%d%s." % [settled.paid,
			(" (a $%d tip!)" % settled.tip) if settled.tip > 0 else ""],
			"Drive off when you like. (They're watching. Behave.)", ""]
	elif settled.get("outcome") == "fired":
		lines = ["\"%s\"" % settled.comment, "No pay, and word will get around.",
			"Drive off when you like. Anything else you wreck costs you more.", ""]
	lines += ["Mowed: %d%%" % floori(lawn.cut_fraction() * 100.0),
		"Mower condition: %d%%" % roundi(mower.condition)]
	if customer.knocked_out:
		lines.append("The customer is out cold on the patio.")
	if settled.is_empty():
		hud.open("At the truck", lines, buttons)
	else:
		hud.open("Paid" if settled.outcome == "paid" else "Fired", lines, buttons, job.look, customer.face())


func _on_choice(id: String) -> void:
	match id:
		"start", "resume":
			hud.close()
			get_tree().paused = false
		"handin":
			hand_in()
		"leave":
			_finish(customer.walked_result(_costs()))
		"leave_ko":
			_finish(customer.ko_result(_costs()))
		"drive_off":
			_drive_off()
		"music", "sound":
			Sfx.toggle(id)
			open_pause()
		"can":
			walker.carrying = "jerrycan"
			walker.queue_redraw()
			hud.close()
			get_tree().paused = false
		"continue": # after ARRESTED: the board shows the run is over
			get_tree().paused = false
			get_tree().change_scene_to_file("res://board.tscn")
		"quit":
			get_tree().paused = false
			Game.in_run = false
			get_tree().change_scene_to_file("res://title.tscn")


## Ask for payment. Too little done and they send you back out, annoyed.
func hand_in() -> void:
	var cov := lawn.cut_fraction()
	if not customer.accepts(cov):
		customer.mood -= 10.0
		customer.last_line = "You call that finished? Get back out there!"
		_count("sent_back")
		_react()
		hud.close()
		get_tree().paused = false
		return
	settled = customer.evaluate(cov, _costs())
	customer.paid = true
	Sfx.play("cash", 0.0)
	pop_text("+$%d" % settled.paid, $Client.position + Vector2(0, -40))
	if Game.in_run and settled.mood >= 60.0:
		Sfx.play("voice_happy")
	open_truck_menu()


## Playtest cheat, debug builds only: [0] ends the job as well as it can go (whole
## lawn, delighted, on time: top pay and rep), to see the high end without grinding.
func _cheat_win() -> void:
	if not settled.is_empty() or customer.knocked_out:
		return
	customer.mood = 100.0
	customer.elapsed = 0.0
	settled = customer.evaluate(1.0, _costs())
	customer.paid = true
	_drive_off()


## Fired: no pay, and the rep hit is booked, but you're not thrown out. Leaving is
## your call, from the truck, and anything you wreck on the way costs you more.
func _fired() -> void:
	settled = customer.fired_result(_costs())
	Sfx.play("fired", 0.0)
	hud.say(customer.fire_line)
	hud.banner("YOU'RE FIRED")
	hud.pop("Rep %d" % roundi(settled.rep))
	pop_text("FIRED!", $Client.position + Vector2(0, -40), Color("f07060"))
	shake(4.0)


## Leave once paid or fired. Anything you got up to since comes off your reputation.
func _drive_off() -> void:
	var r := settled.duplicate()
	r.fuel_cost = _costs()
	r.net = r.paid - r.fuel_cost
	r.rep -= mischief
	r.mischief = mischief
	if mischief > 0.0:
		r.comment = "And don't come back!"
	_finish(r)


## Wreck something once paid or fired and it lands on your reputation, not your pay.
func _mischief(points: float) -> void:
	if not settled.is_empty():
		mischief += points
		pop_text("Rep -%d" % roundi(points), $Client.position + Vector2(0, -40), Color("f07060"))
		hud.pop("Rep -%d" % roundi(points))


func _costs() -> float:
	var fuel_price: float = Game.mower_spec().fuel_price if Game.in_run else 0.25
	return mower.fuel_used * fuel_price + mower.repaired * REPAIR_PRICE + bills


## The job is over: record it and head back to the board, which shows the rundown.
func _finish(result: Dictionary) -> void:
	over = true
	var flat := 0
	for b in $Scenery.get_children():
		if b.has_method("flattened_count"):
			flat += b.flattened_count()
	if flat > 0:
		tally["flowers"] = flat
	result.tally = tally
	result.tally_cost = tally_cost
	get_tree().paused = true
	result.customer = job.get("customer", "")
	result.look = job.look
	result.face = customer.face() if result.outcome != "walked" else "furious"
	Game.record_result(result)
	Sfx.music("")
	match result.outcome:
		"paid":
			if result.get("mischief", 0.0) > 0.0:
				Sfx.play("voice_angry")
		"walked":
			Sfx.play("voice_angry")
	get_tree().paused = false
	if Game.in_run:
		get_tree().change_scene_to_file("res://board.tscn")
	elif get_tree().current_scene == self: # a lone job (dev play): go again
		get_tree().reload_current_scene()


# ---------------------------------------------------------------- stones

func _on_stone_mowed(s: Stone, m: Node2D) -> void:
	if s.is_queued_for_deletion():
		return
	s.queue_free()
	_count("stones_mowed")
	m.damage(12.0)
	Sfx.play("clonk")
	shake(3.0)
	if randf() < Stone.LAUNCH_CHANCE:
		var dir := Vector2.RIGHT.rotated(m.rotation + randf_range(-1.1, 1.1))
		throw_stone(s.position, dir, randf_range(380.0, 560.0), randf_range(140.0, 380.0))


## Count something for the job's tally (shown on the board if it isn't zero).
func _count(key: String, cost := 0.0) -> void:
	tally[key] = tally.get(key, 0) + 1
	if cost > 0.0:
		tally_cost[key] = tally_cost.get(key, 0.0) + cost


## Send a stone flying along the ground (flung by blades or thrown by hand).
func throw_stone(from: Vector2, dir: Vector2, speed: float, distance: float) -> FlyingStone:
	var f := FlyingStone.new()
	f.launch(from, dir, speed, distance, _stone_hit_test)
	f.landed.connect(_on_stone_landed)
	$Stones.add_child.call_deferred(f)
	return f


## The x of the house window at p (see WINDOWS), or -1.
func _window_at(p: Vector2) -> int:
	var h: Rect2 = _house.rect()
	for wx: int in WINDOWS:
		if p.x - h.position.x >= wx and p.x - h.position.x <= wx + 30 and p.y > h.position.y + 60.0:
			return wx
	return -1


## What a flying stone at p would hit, or "" for nothing.
func _stone_hit_test(p: Vector2) -> String:
	if Rect2($Truck.position - Vector2(60, 28), Vector2(120, 56)).has_point(p):
		return "truck" # parked on the road, just past the garden
	if lawn.keep_in(p, 0.0) != p:
		return "gone" # over the fence
	if _house.garage_rect().has_point(p):
		return "wall"
	if not customer.knocked_out and p.distance_to($Client.position + Vector2(0, -14)) < 11.0:
		return "customer"
	var h: Rect2 = _house.rect()
	if h.has_point(p) and p.y < h.position.y + 106.0:
		return "window" if _window_at(p) >= 0 else "wall"
	if walker and p.distance_to(mower.global_position) < 18.0: # your own mower, parked
		return "mower"
	for a in $Animals.get_children():
		if a is Animal and not a.dead and a.position.distance_to(p) < CRITTER_HIT:
			return "animal"
	if dog and is_instance_valid(dog) and dog.position.distance_to(p) < 12.0:
		return "dog"
	for t in $Scenery.get_children():
		if t is StaticBody2D and "radius" in t and p.distance_to(t.position) < t.radius:
			return "tree"
	return "" # a pond is flat: the stone flies over it, see _pond_at on landing


func _on_stone_landed(f: FlyingStone, target: String) -> void:
	var p := f.position
	match target:
		"customer":
			Sfx.play("thud")
			_count("customer_hits")
			_mischief(8.0)
			if customer.on_stone("customer"):
				_knock_out()
			else:
				_react()
		"window":
			Sfx.play("glass", 0.0)
			_house.smash(_window_at(p))
			_count("windows", WINDOW_BILL)
			_mischief(5.0)
			bills += WINDOW_BILL
			pop_text("-$%d" % WINDOW_BILL, p, Color("f07060"))
			shake(4.0)
			customer.on_stone("window")
			_react()
		"wall":
			Sfx.play("thud")
			customer.on_stone("wall")
			_react()
		"truck":
			Sfx.play("clonk")
			_count("dents", DENT_BILL)
			bills += DENT_BILL
			pop_text("-$%d" % DENT_BILL, p, Color("f07060"))
		"animal":
			for a in $Animals.get_children():
				if a is Animal and not a.dead and a.position.distance_to(p) <= CRITTER_HIT:
					a.squash()
					break
		"dog":
			Sfx.play("yelp")
			dog.bowl()
			customer.on_stone("dog")
			_react()
		"gone":
			pass # over the fence and into next door's garden
		"mower":
			Sfx.play("clonk")
			mower.damage(8.0)
			_count("own_goals")
			shake(2.0)
			add_stone.call_deferred(p)
		"tree":
			Sfx.play("thud")
			for t in $Scenery.get_children():
				if t is StaticBody2D and t.has_method("shake") and p.distance_to(t.position) < t.radius + 10.0:
					t.shake() # the canopy sways and drops leaves
					_rustle(t.position + t.crown_centre(), Vector2.DOWN)
			_count("trees_hit")
			add_stone.call_deferred(p - f.velocity.normalized() * 8.0) # drops just outside the trunk
		_:
			var pond := _pond_at(p)
			if pond:
				Sfx.play("splash")
				var fit := pond.splash_fit(p)
				_splash(fit[0], fit[1])
				_count("splashes")
			else:
				Sfx.play("thud")
				for b in $Scenery.get_children():
					if b.has_method("flattened_count") and b.rect().has_point(p):
						b._trample(b.to_local(p), 12.0) # flattens a flower or two where it lands
				add_stone.call_deferred(p)


func _pond_at(p: Vector2) -> Pond:
	for t in $Scenery.get_children():
		if t is Pond and t.contains(p):
			return t
	return null


## Rings spreading on the water and a few drops thrown up, gone in under a second.
## Size shrinks near the edge so the rings stay on the water.
func _splash(p: Vector2, size := 1.0) -> void:
	var s := Node2D.new()
	s.position = p
	s.scale = Vector2(size, size)
	s.z_index = 1
	var k := [0.0]
	s.draw.connect(func() -> void:
		var t: float = k[0]
		var c := Color(0.85, 0.95, 1.0, 1.0 - t)
		s.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		if t < 0.15:
			s.draw_circle(Vector2.ZERO, 6.0, c)
		s.draw_arc(Vector2.ZERO, 4.0 + t * 22.0, 0.0, TAU, 24, c, 2.0)
		if t > 0.2:
			s.draw_arc(Vector2.ZERO, (t - 0.2) * 18.0, 0.0, TAU, 20, c, 2.0)
		s.draw_set_transform(Vector2.ZERO)
		if t < 0.7:
			for i in 7:
				var spread := (i - 3) * 7.0 * t
				var lift := (30.0 - absf(i - 3) * 6.0) * sin(t / 0.7 * PI)
				s.draw_rect(Rect2(spread - 1.5, -lift - 1.5, 3, 3), c))
	add_child(s)
	var tw := s.create_tween()
	tw.tween_method(func(v: float) -> void:
		k[0] = v
		s.queue_redraw(), 0.0, 1.0, 0.7)
	tw.tween_callback(s.queue_free)


func _knock_out() -> void:
	_count("knockouts")
	customer.knock_out()
	$Client.knock_out()
	Sfx.play("thud")
	shake(6.0)
	hud.say("(Out cold.)")


# ---------------------------------------------------------------- the dog

func _release_dog() -> void:
	dog = Dog.new()
	dog.position = $Client.position + Vector2(0, 16)
	dog.home_point = $Client.position
	dog.lawn_rect = Rect2(Vector2(0, _house.size.y), Vector2(lawn.size_px) - Vector2(0, _house.size.y))
	dog.bowled.connect(func(_d: Dog) -> void:
		_count("dog_bowled")
		Sfx.play("yelp")
		customer.on_dog_hit()
		_mischief(8.0)
		_react())
	dog.caught.connect(func(d: Dog) -> void:
		Sfx.play("ui_select", 0.0)
		pop_text("On the lead!", d.position + Vector2(0, -10), UI.GOOD))
	dog.home.connect(func(_d: Dog) -> void:
		_count("dog_returned")
		customer.on_dog_returned()
		_react())
	$Animals.add_child(dog)
	customer.last_line = "Oh no, %s's got out!" % job.dog_name
	hud.say(customer.last_line)
	$Client.react()
	Sfx.play("voice_horrified")


# ---------------------------------------------------------------- wildlife

## Spawn an animal and send it across the lawn. Hedgehogs push out of a hedge (or
## under the fence if there's no hedge); squirrels drop out of a tree or hop the
## fence. Nothing comes from behind the house.
const TELL := 0.9 ## seconds of rustling before a critter comes out


## A critter is coming: the hedge, fence or tree it's in rustles and drops leaves first.
func _tell(kind: String) -> void:
	if $Animals.get_child_count() + _tells.size() >= max_animals:
		return
	var spot := _spawn_spot(kind)
	_tells.append({"kind": kind, "at": spot.at, "grace": spot.grace, "left": TELL})
	_rustle(spot.at, spot.inward)


## Where a critter of this kind comes in: {at, grace}. Squirrels may climb down a tree.
func _spawn_spot(kind: String) -> Dictionary:
	var trees := $Scenery.get_children().filter(func(t: Node) -> bool: return t is StaticBody2D and "radius" in t)
	if kind == "squirrel" and not trees.is_empty() and randf() < 0.5:
		var t: Node2D = trees[randi() % trees.size()]
		return {"at": t.position + Vector2.RIGHT.rotated(randf() * TAU) * t.radius * 0.5,
			"grace": 1.0, "inward": Vector2.DOWN} # climbing down out of the canopy
	var want := "hedge" if kind == "hedgehog" else "fence"
	var pool := _edges.filter(func(e: Dictionary) -> bool: return e.kind == want)
	if pool.is_empty():
		pool = _edges
	var e: Dictionary = pool[randi() % pool.size()]
	return {"at": (e.from as Vector2).lerp(e.to, randf_range(0.05, 0.95)) - (e.inward as Vector2) * 10.0,
		"grace": 0.0, "inward": e.inward}


## The spot jiggles and a few leaves are shaken loose onto the lawn (along inward),
## gone as the critter appears.
func _rustle(p: Vector2, inward := Vector2.DOWN) -> void:
	var r := Node2D.new()
	r.position = p
	r.z_index = 3
	var k := [0.0]
	var leaves: Array[Vector3] = [] # sideways offset, distance thrown, flutter phase
	for i in 7:
		leaves.append(Vector3(randf_range(-14, 14), randf_range(16, 34), randf() * TAU))
	var side := inward.orthogonal()
	r.draw.connect(func() -> void:
		var t: float = k[0]
		var fade := clampf(1.0 - (t - TELL) * 2.0, 0.0, 1.0)
		if t < TELL:
			var j := Vector2(sin(t * 55.0), cos(t * 47.0)) * 2.0 # the tuft shaking
			r.draw_circle(j + side * -5.0, 6.0, Color("2e6428"))
			r.draw_circle(j * -1.0 + side * 5.0, 6.0, Color("4a8a38"))
			r.draw_circle(j + inward * 3.0, 5.0, Color("5e9e40"))
		for i in leaves.size():
			var l := leaves[i]
			var out := minf(t / TELL, 1.0)
			var at := side * (l.x + sin(t * 8.0 + l.z) * 5.0) + inward * l.y * out
			var c := Color("9ad050") if i % 2 == 0 else Color("d8b848")
			r.draw_rect(Rect2(at - Vector2(2, 1.5), Vector2(4, 3)), Color(c, fade)))
	add_child(r)
	var tw := r.create_tween()
	tw.tween_method(func(v: float) -> void:
		k[0] = v
		r.queue_redraw(), 0.0, TELL + 0.5, TELL + 0.5)
	tw.tween_callback(r.queue_free)


func spawn_animal(kind: String, at := Vector2.INF, toward := Vector2.INF, grace := 0.0) -> Animal:
	if $Animals.get_child_count() >= max_animals and at == Vector2.INF:
		return null
	var r := Rect2(Vector2.ZERO, Vector2(lawn.size_px))
	if at == Vector2.INF:
		var spot := _spawn_spot(kind)
		at = spot.at
		grace = spot.grace
	if toward == Vector2.INF:
		for i in 10:
			toward = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not _blocked(toward):
				break
	var a := Animal.new()
	a.blocked = _blocked
	a.grace = grace
	a.kind = kind
	a.position = at
	a.heading = (toward - at).normalized()
	a.lawn_rect = r
	a.squashed.connect(_on_squashed)
	$Animals.add_child(a)
	return a


func _on_squashed(a: Animal) -> void:
	_splats.append(a.position)
	if a.position.distance_to(mower.global_position) < 40.0: # run over, not stoned
		_count("squashed_" + a.kind)
		_blood = TRAIL
		_blood_from = mower.global_position
	else:
		_count("stoned_" + a.kind)
	$Decals.queue_redraw()
	Sfx.play("squash")
	shake(3.0)
	Sfx.play("squeak_" + a.kind)
	customer.on_squash(a.kind)
	_mischief(3.0)
	_react()


## The customer's visible reaction: speech, a hop on the patio, and their voice.
func _react() -> void:
	hud.say(customer.last_line)
	if customer.knocked_out:
		return
	$Client.react()
	var f := customer.face()
	Sfx.play({"laughing": "voice_laugh", "horrified": "voice_horrified", "delighted": "voice_happy",
		"happy": "voice_happy", "hurt": "voice_horrified"}.get(f, "voice_angry"))


func _on_trampled(_flat: int, _total: int) -> void:
	var total := 0
	for b in $Scenery.get_children():
		if b.has_method("flattened_count"):
			total += b.flattened_count()
	Sfx.play("crunch")
	if customer.on_flowers(total):
		_mischief(2.0)
		if Time.get_ticks_msec() >= _flowers_quiet_until: # the rep still counts every flower
			_flowers_quiet_until = Time.get_ticks_msec() + 1500
			_react()
