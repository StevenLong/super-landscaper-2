extends Node2D
## One job: builds the garden from Game.job(), runs the customer's mood, and ends
## in a payment, a firing, a knockout, or you driving off; the board then shows the
## rundown. Outside a run (tests, playing this scene directly) it uses the slice's
## hand-made lawn and skips the briefing.

const TreeScript := preload("res://tree.gd")
const BedScript := preload("res://flowerbed.gd")
const HouseScript := preload("res://house.gd")
const WalkerScript := preload("res://walker.gd")
const RockScript := preload("res://rock.gd")

const REPAIR_PRICE := 0.5 ## per condition point repaired
const WINDOW_BILL := 40.0
const DENT_BILL := 20.0
const CAR_BILL := 40.0 ## a dent in the customer's car
const RAM_SPEED := 200.0 ## a bump into the car harder than this is on purpose (a crime); slower, an accident
const RIFLE_RATE := 4.0 ## dollars a second out of a knocked-out customer's pockets
const ROB_REP := 30.0 ## the worst reputation hit in the game
const CAR_SIZE := Vector2(52, 66) ## parked along the drive: 110 long, foreshortened by 0.6 (tools/voxel.py G)
const THROW_MIN := 40.0 ## how far a tap throws
const THROW_MAX := 300.0 ## how far a full wind-up throws
const THROW_FROM := 12.0 ## the stone leaves your hand this far in front (less, the steeper you throw)
const THROW_Z := 12.0 ## and this high
const HEAD := 30.0 ## how tall a person is: a stone lower than this hits them
const TALK := 36.0 ## how close you walk up to the customer (or their door, if they're in) to talk
## Animals you can pick up: "tier" on the crime ladder for throwing one, "hold" seconds
## before it wriggles or bites free. A hedgehog bare-handed stuns you instead (gloves fix it).
const CRITTERS := {"dog": {"tier": 1, "hold": 5.0}, "hedgehog": {"tier": 0, "hold": INF}, "squirrel": {"tier": 0, "hold": 3.0}}
const PRICKLE := 0.35 ## seconds a hedgehog stays in bare hands before the OW
const KO_TIME := 6.0 ## seconds a stoned critter lies out cold
const SLAM := 200.0 ## px/s along the ground: a critter thrown into something this hard is knocked out
const KO_SHARE := 0.4 ## how much a knockout upsets the customer, against a death
## A stone into a critter: thrown by hand it mostly knocks out (else kills, leaving a body);
## flung by the blades it mostly splats (else knocks out). Chances of the first outcome.
const THROWN_KO := 0.8
const FLUNG_SPLAT := 0.75
const DOG_REACH := 26.0 ## how close to the dog you must be to put the lead on
const CRITTER_HIT := 16.0 ## how close a thrown stone must pass to hit a critter (they're small and moving)
const BORDER := 24 ## hedge/fence thickness, drawn just outside the lawn
const FOOTPATH := 40 ## the pavement between the front hedge and the kerb
const ROAD := 150
const BORDER_UP := 29.0 ## how far a hedge or fence rises in the 3/4 view (art/hedge_h.png face)
const GRAVEL := Color(1.0, 0.88, 0.68) ## tints the grey gravel tile for the drive
const TERRACE_FRONT := 64.0 ## a terrace's scrap of front garden, between the house and the road
const NEXT_DOOR := Color(0.72, 0.8, 0.7) ## next door's lawn, a touch duller than the one you mow
const MANOR_BACK := 260.0 ## the manor's back lawn, between the ha-ha and its ridge
const APPROACH_W := 96.0 ## the manor's approach, up the middle from the gates
const TOPIARY_BILL := 60.0 ## a chunk out of a clipped peacock
const CHURCH_BACK := 170.0 ## the church stands this far off the back wall, walled off behind
const PATH_W := 48.0 ## the churchyard path, from the lychgate to the porch
const WINDOW_CONE := deg_to_rad(50.0) ## half the spread a window sees out over
const SIGHT_REACH := 1400.0 ## as far as the highlight reaches

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
var police_left := -1.0 ## seconds until the police arrive once called; below zero, nobody's called
var worst_crime := 0 ## the worst tier on the crime ladder this job (Game.HEAT)

var _next_hedgehog := 3.0
var _next_squirrel := 8.0
var _dog_in := -1.0
var _house: Node2D
var _car: StaticBody2D ## the customer's, up the drive; not every job
var _hose: Hose ## on its tap by the house; not every job
var _notch := Rect2() ## next door's corner of an L plot: not yours, fenced off
var _haha := false ## the manor: its park sides drop into a ditch, nothing to bounce off
var _cone: Node2D ## the ground the window they're at can see, faintly lit
var _cone_pts := PackedVector2Array()
var _cone_x := -1 ## the window it was worked out for
var _carry_seen := "" ## what you're carrying that they've already seen you with
var _out := 0.0 ## seconds the critter in your hands has left out cold (0: awake)
var _known_bodies := {} ## kind -> bodies they've already seen made or carried: not news later
var _shake := 0.0
var _edges: Array[Dictionary] = [] ## where critters come in: {kind, from, to, inward}
var _strips: Array[Dictionary] = [] ## the boundary runs round the property: {kind, rect, inward}
var _tells: Array[Dictionary] = [] ## critters about to come out: {kind, at, grace, left}
var _front: Array[TextureRect] = [] ## the hedge or fence along the road, drawn over the lawn's edge
var _splats: Array[Vector2] = [] ## squashed critters: they stay for the whole job
var _spills: Array = [] ## [position, colour]: petrol browning the lawn, a cut hose's puddle
var _tracks: Array = [] ## red wheel marks: [position, sideways unit, strength 0..1]
var _blood := 0.0 ## px of red trail the mower has left to lay after running something over
var _blood_from := Vector2.ZERO
var _flowers_quiet_until := 0 ## msec: one scream per burst of flowers, not one per flower
var _heat0 := 0.0 ## your record as the job starts: it sets how fast the police come
var _vandal := false ## wrecking things after being fired: trespass, one charge a job
var _siren: AudioStreamPlayer
var _wallet := 0.0 ## what's left in the customer's pockets
var robbed := 0.0 ## what you've lifted from them
var _held := 0.0 ## seconds you've held the animal in your hands

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
	customer.sight = _in_sight
	_cone = Node2D.new()
	_cone.name = "SightCone"
	_cone.z_index = -1
	_cone.draw.connect(func() -> void:
		if _cone_pts.size() > 2:
			_cone.draw_colored_polygon(_cone_pts, Color(1.0, 0.95, 0.6, 0.12)))
	add_child(_cone)
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
	_heat0 = Game.heat
	mower.bumped.connect(_on_mower_bumped)
	if Game.in_run:
		get_tree().paused = true
		var lines: Array = job.brief.duplicate()
		if job.get("dog", false):
			lines.append("(%s the dog likes to escape. Mind them.)" % job.dog_name)
		lines.append_array(["", "Mow the lawn, then walk up and ask to be paid. Your truck's for leaving."])
		if Game.jobs_done == 0:
			lines.append_array(["%s %s at the truck. %s hop off to move" % ["Triggers drive, the stick steers." if Game.pad
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
	var rv := RandomNumberGenerator.new() # later variety draws from its own, so layouts stay put
	rv.seed = job.seed + 2

	var venue: String = job.get("venue", "house")
	_house = HouseScript.new()
	_house.name = "House"
	_house.venue = venue
	_house.garage = 1 if fixed else [-1, 1][r.randi() % 2]
	_house.gap = 0.0 if fixed else [0.0, 0.0, 80.0][rv.randi() % 3]
	var shape: String = job.get("shape", "rect")
	_house.back_patio = shape in ["forward", "terrace"]
	_house.passage = shape == "terrace"
	if _house.passage:
		_house.gap = 0.0
	# Centre the house and garage together: on the back fence, or set forward with a back
	# garden behind. A terrace's house fills the width by its passage, near the road.
	var span: float = _house.GARAGE_W + _house.gap
	var house_y := 0.0
	if shape == "forward":
		house_y = roundf((size.y - _house.size.y) * 0.55)
	elif shape == "terrace":
		house_y = size.y - _house.size.y - TERRACE_FRONT
	_house.position = Vector2(size.x * 0.5 - (_house.size.x + span) * 0.5 + (span if _house.garage < 0 else 0.0), house_y)
	if venue == "mansion": # centred on its approach, the coach house well off to one side
		_house.gap = 200.0
		_house.position = Vector2((size.x - _house.size.x) * 0.5, MANOR_BACK)
	elif venue == "graveyard": # off to one side of its yard, the vestry against the boundary
		_house.gap = 0.0
		_house.position = Vector2(_house.GARAGE_W if _house.garage < 0 else size.x - _house.size.x - _house.GARAGE_W, CHURCH_BACK)
	var wall := StaticBody2D.new() # the house and garage are solid; the patio in front isn't
	for box: Rect2 in [_house.rect(), _house.garage_rect()]:
		if not box.has_area():
			continue # a terrace's passage
		var wall_shape := CollisionShape2D.new()
		wall_shape.shape = RectangleShape2D.new()
		box.size.y = minf(box.size.y, _house.WALL_H) # not the patio
		wall_shape.shape.size = box.size
		wall_shape.position = box.position - _house.position + box.size * 0.5
		wall.add_child(wall_shape)
	_house.add_child(wall)
	$Scenery.add_child(_house)
	$Client.position = _house.patio_point()
	$Client.watch = mower
	$Client.set_look(job.look)
	_house.peek_tex = $Client._tex
	customer.windows = _house.windows()

	# The drive runs from the garage door to the road; its mouth crosses the pavement.
	var drive: Control = $Driveway
	var g: Rect2 = _house.garage_rect()
	var inset := 0.0 if _house.passage else 10.0 # a terrace's passage runs wall to fence, no slivers of lawn
	drive.position = Vector2(g.position.x + inset, g.end.y)
	drive.size = Vector2(g.size.x - inset * 2.0, size.y - g.end.y)
	drive.self_modulate = GRAVEL # warm it so it doesn't read as more road
	if venue == "graveyard": # no drive: a flagstone path from the lychgate on the road to the porch
		drive.position = Vector2(_house.rect().get_center().x - PATH_W * 0.5, _house.rect().end.y)
		drive.size = Vector2(PATH_W, size.y - drive.position.y)
		drive.texture = preload("res://art/paving.png")
		drive.self_modulate = Color.WHITE
	lawn.exits = [Rect2(drive.position.x, size.y - 40, drive.size.x, 40 + BORDER + FOOTPATH)]
	$Truck.position = Vector2(drive.position.x + drive.size.x * 0.5, size.y + BORDER + FOOTPATH + 34)
	# Parked along the kerb: the zone reaches back up the drive mouth to where you pull in.
	$Truck/RefuelZone/Shape.position = Vector2(0, -80)
	($Truck/RefuelZone/Shape.shape as RectangleShape2D).size = Vector2(180, 150)
	if not fixed and venue == "house" and not _house.passage and rv.randf() < 0.5:
		_park_car(Vector2(drive.position.x + drive.size.x * 0.5, g.end.y + 72.0), rv)
	mower.position = truck_spot()
	mower.rotation = -PI / 2.0 # facing up the drive
	$Truck/Trailer.visible = Game.in_run and "rideon" in Game.owned
	_build_street()
	var beyond := preload("res://beyond.gd").new()
	beyond.name = "Beyond"
	add_child(beyond)
	var rb := RandomNumberGenerator.new() # its own, so the garden's layout stays as it was
	rb.seed = job.seed + 1
	beyond.build(size.x, size.y, BORDER, size.y + BORDER + FOOTPATH * 2 + ROAD, BORDER_UP, rb, "park" if venue == "mansion" else shape, house_y)

	var taken: Array[Rect2] = [_house.footprint().grow(50), Rect2(drive.position, drive.size).grow(30)]
	if _house.back_patio:
		var bp: Rect2 = _house.back_patio_rect()
		var paving := TextureRect.new()
		paving.name = "BackPatio"
		paving.texture = preload("res://art/paving.png")
		paving.stretch_mode = TextureRect.STRETCH_TILE
		paving.position = bp.position
		paving.size = bp.size
		paving.z_index = -2
		add_child(paving)
		lawn.exclude_rect(bp)
		taken.append(bp.grow(40))
	if shape == "L":
		# Next door's back corner cuts in on the side away from the garage, level with the
		# house front, leaving a strip of lawn down the house's side.
		var fp: Rect2 = _house.rect()
		var nw := minf(size.x * 0.3, (fp.position.x if _house.garage > 0 else size.x - fp.end.x) - 70.0)
		_notch = Rect2(0.0 if _house.garage > 0 else size.x - nw, 0.0, nw, _house.size.y)
		lawn.holes = [_notch]
		lawn.exclude_rect(_notch)
		taken.append(_notch.grow(20))
		beyond.corner(_notch, NEXT_DOOR)
	if venue == "graveyard":
		# Walled off behind the church and its vestry: no ground there you can't see.
		var fp: Rect2 = _house.rect()
		var v: Rect2 = _house.garage_rect()
		_notch = Rect2(minf(fp.position.x, v.position.x), 0.0, fp.size.x + v.size.x, fp.position.y)
		var pocket := Rect2(v.position.x, fp.position.y, v.size.x, v.position.y - fp.position.y)
		lawn.holes = [_notch, pocket]
		lawn.exclude_rect(_notch)
		lawn.exclude_rect(pocket)
		taken.append(_notch.grow(20))
		beyond.corner(_notch, NEXT_DOOR)
		beyond.corner(pocket, NEXT_DOOR)
	if venue == "mansion":
		var rm := RandomNumberGenerator.new() # its own, so the rest stays put
		rm.seed = job.seed + 7
		_manor(rm, taken, size)
	var trees: Array = []
	var beds: Array = []
	var stones: Array = []
	var ponds: Array = []
	if fixed:
		trees = [[Vector2(1080, 440), 34.0]]
		beds = [Rect2(360, 420, 200, 80)]
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
		if not fixed: # by where it is, so the layout's own draws stay put
			b.shape = ["oval", "kidney", "bean"][int(beds[i].position.x * 7.0 + beds[i].position.y * 13.0) % 3]
		_add_area(b)
		b.trampled.connect(_on_trampled)
		$Scenery.add_child(b)
		b.exclude_from(lawn)
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
	if not fixed:
		var rp := RandomNumberGenerator.new() # its own, so everything above stays put
		rp.seed = job.seed + 4
		var props: Array = job.get("props", []) + (["ball"] if job.get("dog", false) else [])
		for kind: String in props:
			if kind == "hose":
				_lay_hose(rp)
				continue
			var pr := _place(rp, taken, Vector2(14, 14), size)
			if pr.has_area():
				add_stone(pr.get_center(), kind)
		if venue == "graveyard":
			_graves(rp, taken, size)
		for i in job.get("rocks", 0):
			var rr := _place(rp, taken, Vector2(30, 24), size)
			if rr.has_area():
				var rock := RockScript.new()
				rock.position = rr.get_center()
				$Scenery.add_child(rock)
				lawn.exclude_circle(rock.position, rock.radius)
	lawn.exclude_rect(_house.rect())
	lawn.exclude_rect(_house.garage_rect())
	lawn.exclude_rect(Rect2(drive.position, drive.size))
	_build_borders(r, drive)


## The customer's car, parked up the drive nose-in or reversed in: solid, and dents.
func _add_bed(box: Rect2, shape: String, spacing := 16.0) -> Node2D:
	var b: Node2D = BedScript.new()
	b.position = box.position
	b.size = box.size
	b.shape = shape
	b.spacing = spacing
	_add_area(b)
	b.trampled.connect(_on_trampled)
	$Scenery.add_child(b)
	b.exclude_from(lawn)
	return b


## The mansion's loop drive: a gravel ring in front of the house round an island with an
## oval bed of flowers in it. Returns the space it takes.
func _loop_drive(at: Vector2) -> Rect2:
	var outer := Vector2(180, 92)
	var inner := Vector2(118, 52)
	var ring := Node2D.new()
	ring.name = "LoopDrive"
	ring.z_index = -1
	ring.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ring.draw.connect(func() -> void:
		var tex := preload("res://art/gravel.png")
		for i in 40: # quads round the ring (draw_colored_polygon takes no holes)
			var a0 := TAU * i / 40.0
			var a1 := TAU * (i + 1) / 40.0
			var q := PackedVector2Array([at + Vector2(cos(a0), sin(a0)) * outer, at + Vector2(cos(a1), sin(a1)) * outer,
				at + Vector2(cos(a1), sin(a1)) * inner, at + Vector2(cos(a0), sin(a0)) * inner])
			var uv := PackedVector2Array()
			for p in q:
				uv.append(p / tex.get_size())
			ring.draw_colored_polygon(q, GRAVEL, uv, tex))
	$Scenery.add_child(ring)
	lawn.exclude_ring(at, outer, inner)
	_add_bed(Rect2(at - inner + Vector2(26, 16), (inner - Vector2(26, 16)) * 2.0), "oval")
	return Rect2(at - outer, outer * 2.0).grow(10)


## The manor's formal gardens (design doc, Levels): the approach up the middle from the
## gates, the loop drive or a forecourt before the portico, the parterre either side of
## it, clipped topiary in pairs down the approach, and the stable yard by the coach house.
## The skeleton is fixed; the forecourt, the parterre's pattern and the topiary are drawn.
func _manor(r: RandomNumberGenerator, taken: Array[Rect2], size: Vector2i) -> void:
	var cx: float = _house.rect().get_center().x
	var foot: float = _house.rect().end.y
	var top: float # where the approach starts
	if r.randf() < 0.5:
		var at := Vector2(cx, foot + 110.0)
		taken.append(_loop_drive(at))
		top = at.y + 80.0 # tucked under the ring's bottom, so they join
	else:
		var court := Rect2(cx - 300.0, foot, 600.0, 130.0)
		_gravel(court, "Forecourt")
		taken.append(court.grow(20))
		top = court.end.y
		if r.randf() < 0.6:
			_park_car(Vector2(cx + 190.0, court.get_center().y), r)
	var approach := Rect2(cx - APPROACH_W * 0.5, top, APPROACH_W, size.y - top)
	_gravel(approach, "Approach")
	taken.append(approach.grow(20))
	var g: Rect2 = _house.garage_rect()
	var yard := Rect2(g.position.x - 50.0, g.end.y, g.size.x + 100.0, 90.0)
	_gravel(yard, "StableYard")
	taken.append(yard.grow(20))
	# The parterre: box-edged beds either side of the forecourt, one pattern of three.
	var pattern: String = ["quad", "long", "round"][r.randi() % 3]
	for side: float in [-1.0, 1.0]:
		var inner: float = cx + side * 330.0
		var boxes: Array[Rect2] = []
		match pattern:
			"quad":
				for i in 4:
					boxes.append(Rect2(Vector2(inner + side * (i % 2) * 145.0 - (115.0 if side < 0 else 0.0), foot + 40.0 + floori(i / 2.0) * 90.0), Vector2(115, 60)))
			"long":
				for i in 2:
					boxes.append(Rect2(Vector2(inner - (260.0 if side < 0 else 0.0), foot + 40.0 + i * 80.0), Vector2(260, 48)))
			"round":
				boxes.append(Rect2(Vector2(inner - (250.0 if side < 0 else 0.0), foot + 50.0), Vector2(250, 120)))
		for b in boxes:
			var bed := _add_bed(b, "oval" if pattern == "round" else "rect", 14.0)
			bed.box = pattern != "round"
			taken.append(b.grow(24))
	# Topiary in pairs down the approach, one kind a job.
	var kind := r.randi() % 3
	var pairs := r.randi_range(3, 6)
	var y0: float = foot + 280.0
	var step: float = (size.y - 70.0 - y0) / pairs
	for i in pairs:
		for side: float in [-1.0, 1.0]:
			var t := RockScript.new()
			t.name = "Topiary%d" % (i * 2 + (1 if side > 0 else 0))
			t.art = "topiary"
			t.frames = 6
			t.frame = kind
			t.radius = 10.0
			t.height = 40.0 # taller than you
			t.position = Vector2(cx + side * (APPROACH_W * 0.5 + 36.0), y0 + i * step)
			$Scenery.add_child(t)
			lawn.exclude_circle(t.position, t.radius)
			taken.append(Rect2(t.position - Vector2(24, 24), Vector2(48, 48)))


## A flat gravel area (the manor's approach, forecourt, stable yard): walkable, not lawn.
func _gravel(box: Rect2, called: String) -> void:
	var g := TextureRect.new()
	g.name = called
	g.texture = preload("res://art/gravel.png")
	g.stretch_mode = TextureRect.STRETCH_TILE
	g.position = box.position
	g.size = box.size
	g.self_modulate = GRAVEL
	g.z_index = -2
	add_child(g)
	lawn.exclude_rect(box)


## The hose, off a tap on the side of the house away from the garage, wandering out
## across the lawn.
func _lay_hose(rp: RandomNumberGenerator) -> void:
	var h: Rect2 = _house.rect()
	var side := -1.0 if _house.garage > 0 else 1.0
	var tap := Vector2(h.position.x - 3.0 if side < 0.0 else h.end.x + 3.0, h.position.y + _house.WALL_H - 8.0)
	var dir := Vector2(side, 1.0).normalized()
	if _house.back_patio: # the tap's on the back wall, where the garden is
		tap = Vector2(h.position.x + 30.0 if side < 0.0 else h.end.x - 30.0, h.position.y - 3.0)
		dir = Vector2(side * 0.4, -1.0).normalized()
	var path := PackedVector2Array([tap])
	for i in 18:
		dir = dir.rotated(rp.randf_range(-0.5, 0.5))
		path.append(lawn.keep_in(path[-1] + dir * Hose.SEG, 10.0))
	_hose = Hose.new()
	_hose.mower = mower
	_hose.lay(path)
	_hose.mowed.connect(_on_hose_mowed)
	$Scenery.add_child(_hose)


## The churchyard: rows of headstones, solid, some with flowers laid in front, wherever
## nothing else stands.
func _graves(rp: RandomNumberGenerator, taken: Array[Rect2], size: Vector2i) -> void:
	var path_x: float = _house.rect().get_center().x
	for y in range(70, size.y - 70, 88):
		for x in range(70, size.x - 60, 64):
			var old := clampf(absf(x - path_x) / (size.x * 0.6), 0.0, 1.0) # further from the path, older
			var at := Vector2(x + rp.randf_range(-6, 6) * (1.0 + old), y + rp.randf_range(-4, 4) * (1.0 + old))
			var spot := Rect2(at - Vector2(14, 24), Vector2(28, 44))
			if rp.randf() < 0.25 or not taken.all(func(t: Rect2) -> bool: return not t.intersects(spot.grow(6))):
				continue
			var g := RockScript.new()
			g.art = "gravestone"
			g.frames = 2
			g.frame = rp.randi() % 2
			g.radius = 7.0
			g.position = at
			g.rotation = rp.randf_range(-0.25, 0.25) * old * old # leaning, the old ones
			$Scenery.add_child(g)
			lawn.exclude_circle(at, g.radius)
			if rp.randf() < 0.5:
				_add_bed(Rect2(at + Vector2(-12, 8), Vector2(24, 12)), "rect", 8.0)
			taken.append(spot)


func _park_car(at: Vector2, rv: RandomNumberGenerator) -> void:
	_car = StaticBody2D.new()
	_car.name = "Car"
	_car.position = at
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cs.shape.size = CAR_SIZE
	_car.add_child(cs)
	var spr := Sprite2D.new()
	spr.texture = preload("res://art/car.png")
	spr.hframes = 4 # the paints
	spr.vframes = 8
	spr.frame = [6, 2][rv.randi() % 2] * 4 + rv.randi() % 4
	_car.add_child(spr)
	$Scenery.add_child(_car)


func _car_rect() -> Rect2:
	return Rect2(_car.position - CAR_SIZE / 2.0, CAR_SIZE) if _car else Rect2()


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
## the other; the top only has the bits either side of the house (it runs on behind
## the lower garage); the
## bottom leaves a gap where the drive goes out to the road.
func _build_borders(r: RandomNumberGenerator, drive: Control) -> void:
	var w := float(lawn.size_px.x)
	var h := float(lawn.size_px.y)
	var b := float(BORDER)
	var top: String = ["hedge", "fence"][r.randi() % 2]
	# The sides and the road-side run are one boundary, so one style; the back can differ.
	var edge: String = ["hedge", "fence"][r.randi() % 2]
	var road := edge
	if _house.venue == "mansion": # a ha-ha round the park sides, railings along the road
		top = "haha"
		edge = "haha"
		road = "railings"
		_haha = true
	elif _house.venue == "graveyard": # a stone wall all round
		top = "wall"
		edge = "wall"
		road = "wall"
	# name: [kind, outer rect, the lawn-side line critters come in along, inward direction]
	var fp: Rect2 = _house.rect()
	var d0 := drive.position.x
	var d1 := drive.position.x + drive.size.x
	var n := _notch
	var nl := n.has_area() and n.position.x <= 0.0 # next door's corner is on the left
	var nr := n.has_area() and not nl
	var sides := {
		# The back run is one strip the garden's full width, behind the house: where it's
		# taller than the roof's overhang its top shows over the ridge. Critters come in
		# only either side of the house, unless it stands forward with a garden behind.
		"top": [top, Rect2(n.end.x if nl else -b, -b, (w + b - n.end.x) if nl else ((n.position.x + b) if nr else w + 2.0 * b), b), [], Vector2.DOWN],
		"top_l": [top, Rect2(), [Vector2(n.end.x if nl else 0.0, 0), Vector2(fp.position.x, 0)], Vector2.DOWN],
		"top_r": [top, Rect2(), [Vector2(fp.end.x, 0), Vector2(n.position.x if nr else w, 0)], Vector2.DOWN],
		"left": [edge, Rect2(-b, -b, b, h + 2.0 * b), [Vector2(0, n.end.y if nl else 0.0), Vector2(0, h)], Vector2.RIGHT],
		"right": [edge, Rect2(w, -b, b, h + 2.0 * b), [Vector2(w, n.end.y if nr else 0.0), Vector2(w, h)], Vector2.LEFT],
		"bottom_l": [road, Rect2(-b, h, d0 + b, b), [Vector2(0, h), Vector2(d0, h)], Vector2.UP],
		"bottom_r": [road, Rect2(d1, h, w - d1 + b, b), [Vector2(d1, h), Vector2(w, h)], Vector2.UP],
	}
	if fp.position.y > 0.0: # nothing on the back fence: critters come in all along it
		sides.top_l[2] = [Vector2(n.end.x if nl else 0.0, 0), Vector2(n.position.x if nr else w, 0)]
		sides.erase("top_r")
	if n.has_area(): # next door's corner: its fence faces you along two sides (the church's back wall, one)
		var nx := n.end.x if nl else n.position.x
		if _house.venue != "graveyard":
			sides.notch_h = [top, Rect2(n.position.x - (b if nl else 0.0), n.end.y - b, n.size.x + b, b),
				[Vector2(n.position.x, n.end.y), Vector2(n.end.x, n.end.y)], Vector2.DOWN]
		sides.notch_v = [top, Rect2(nx - b if nl else nx, -b, b, n.size.y + b), [Vector2(nx, 0), Vector2(nx, n.end.y)],
			Vector2.RIGHT if nl else Vector2.LEFT]
	var mouth := TextureRect.new() # the drive carries on across the pavement to the road
	mouth.texture = preload("res://art/gravel.png")
	mouth.stretch_mode = TextureRect.STRETCH_TILE
	mouth.position = Vector2(d0, h)
	mouth.size = Vector2(drive.size.x, b + FOOTPATH)
	mouth.self_modulate = GRAVEL
	if _house.venue == "graveyard":
		mouth.texture = drive.texture
		mouth.self_modulate = Color.WHITE
	$Borders.add_child(mouth)
	for key: String in sides:
		var s: Array = sides[key]
		if not s[2].is_empty() and (s[2][0] as Vector2).distance_to(s[2][1]) > 40.0: # too short to come out of
			_edges.append({"kind": s[0], "from": s[2][0], "to": s[2][1], "inward": s[3]})
		if not (s[1] as Rect2).has_area():
			continue # a critter entrance only; the strip is "top"
		_strips.append({"kind": s[0], "rect": s[1], "inward": s[3]})
		var vertical: bool = key in ["left", "right", "notch_v"]
		if s[0] == "haha":
			_add_haha(s[1], vertical)
			continue
		var strip := TextureRect.new()
		var box: Rect2 = s[1]
		if vertical: # seen from above, lifted by its height like everything that stands up
			strip.texture = {"hedge": preload("res://art/hedge_v.png"), "fence": preload("res://art/fence_v.png"),
				"wall": preload("res://art/wall_v.png")}[s[0]]
			var from := -BORDER_UP
			if (key == "left" and nl) or (key == "right" and nr):
				from = n.end.y - BORDER_UP # it starts at next door's corner
			var to := n.end.y - BORDER_UP if key == "notch_v" else h + b - BORDER_UP
			box = Rect2(box.position.x, from, box.size.x, to - from)
		else: # its front face, standing on the run's outer edge (the lawn edge at the top)
			strip.texture = {"hedge": preload("res://art/hedge_h.png"), "fence": preload("res://art/fence_h.png"),
				"railings": preload("res://art/railings_h.png"), "wall": preload("res://art/wall_h.png")}[s[0]]
			var foot := box.end.y if key.begins_with("bottom") else (n.end.y if key == "notch_h" else 0.0)
			box = Rect2(box.position.x, foot - strip.texture.get_height(), box.size.x, strip.texture.get_height())
		strip.stretch_mode = TextureRect.STRETCH_TILE
		strip.position = box.position
		strip.size = box.size
		if key.begins_with("bottom"): # in front of the lawn: drawn over the mower
			strip.z_index = 1
			_front.append(strip)
		$Borders.add_child(strip)
	if _house.venue == "graveyard": # the lychgate over the path's mouth
		var gate := Sprite2D.new()
		gate.texture = preload("res://art/lychgate.png")
		gate.position = Vector2((d0 + d1) * 0.5, h + b + 2.0)
		gate.offset = Vector2(0, -46)
		gate.z_index = 1
		$Borders.add_child(gate)
	if road == "railings": # stone piers at the main gates (shut) and the tradesmen's (open)
		var cx: float = _house.rect().get_center().x
		for x: float in [cx - APPROACH_W * 0.5 - 6.0, cx + APPROACH_W * 0.5 + 6.0, d0 - 6.0, d1 + 6.0]:
			var pier := Sprite2D.new()
			pier.texture = preload("res://art/pier.png")
			pier.position = Vector2(x, h + b + 2.0)
			pier.offset = Vector2(0, -36)
			pier.z_index = 1
			$Borders.add_child(pier)


## A ha-ha along the lawn's edge: a stone coping, then the drop into a shadowed ditch on
## the park side, no fence in the view.
func _add_haha(outer: Rect2, vertical: bool) -> void:
	var d := Node2D.new()
	d.z_index = -1
	var lip := Rect2(outer.end.x - 6.0 if outer.position.x < 0.0 else outer.position.x, outer.position.y, 6.0, outer.size.y) if vertical \
		else Rect2(outer.position.x, outer.end.y - 6.0, outer.size.x, 6.0)
	d.draw.connect(func() -> void:
		d.draw_rect(outer, Color("1f3a1c"))
		var bank := outer.grow_individual(0, 0, 0, -outer.size.y * 0.5) if not vertical else outer
		d.draw_rect(bank, Color("2a4a24"))
		d.draw_rect(lip, Color("b4b4b8"))
		d.draw_rect(Rect2(lip.position, Vector2(lip.size.x, 1) if not vertical else Vector2(1, lip.size.y)), Color("d8d8dc"))
		d.draw_rect(Rect2(lip.end - Vector2(lip.size.x, 1) if not vertical else lip.end - Vector2(1, lip.size.y), Vector2(lip.size.x, 1) if not vertical else Vector2(1, lip.size.y)), Color("74747c")))
	$Borders.add_child(d)


## Can the customer see p from where they are (design doc, The Customer: line of sight)?
## On the patio they turn to face you, so it's a clear line; at a window, a cone out of
## it. Anything taller than a person blocks the view: buildings, the car, the truck, tall
## topiary. Hedges, fences, rocks and headstones don't.
func _in_sight(p: Vector2) -> bool:
	if customer.where == "window":
		var eye := _window_eye()
		if absf(Vector2.DOWN.angle_to(p - eye)) > WINDOW_CONE:
			return false
		return _clear(eye, p)
	return _clear($Client.position, p)


## Where they look out of the window they're at: its sill, out front.
func _window_eye() -> Vector2:
	return _house.position + Vector2(customer.window_x + 15.0, _house.WALL_H + 6.0)


## Nothing taller than a person between a and b (either end's own spot aside).
func _clear(a: Vector2, b: Vector2) -> bool:
	var boxes: Array[Rect2] = [Rect2(_house.position, Vector2(_house.size.x, _house.WALL_H)), _house.garage_rect(),
		_car_rect(), Rect2($Truck.position - Vector2(64, 32), Vector2(128, 64))]
	var tall := $Scenery.get_children().filter(func(t: Node) -> bool: return "height" in t and t.height > HEAD)
	var d := a.distance_to(b)
	var t := 10.0
	while t < d - 14.0:
		var q := a.lerp(b, t / d)
		for r in boxes:
			if r.has_point(q):
				return false
		for o: Node2D in tall:
			if q.distance_to(o.position) < o.radius:
				return false
		t += 6.0
	return true


## The faint patch of ground the window they're at looks out over, so you can tell where
## they can see even with that window off screen.
func _show_cone() -> void:
	var x: int = customer.window_x if customer.where == "window" and not customer.knocked_out else -1
	if x == _cone_x:
		return
	_cone_x = x
	_cone_pts = PackedVector2Array()
	if x >= 0:
		var eye := _window_eye()
		_cone_pts.append(eye)
		var ground := Rect2(Vector2.ZERO, Vector2(lawn.size_px)).grow(BORDER)
		for i in 41:
			var dir := Vector2.DOWN.rotated(lerpf(-WINDOW_CONE, WINDOW_CONE, i / 40.0))
			var reach := 16.0
			while reach < SIGHT_REACH and ground.has_point(eye + dir * reach) and _clear(eye, eye + dir * (reach + 14.0)):
				reach += 12.0
			_cone_pts.append(eye + dir * reach)
	_cone.queue_redraw()


## Carry a body (or worse) into their sight and they react there and then, paid or not
## (design doc: brought into view, it counts at once). Once per thing you pick up.
func _carried_into_view() -> void:
	var what: String = walker.carrying if walker else ""
	if not what.begins_with("body_"):
		_carry_seen = ""
		return
	if _carry_seen == what or not customer.sees(walker.global_position):
		return
	_carry_seen = what
	_mischief(3.0)
	var kind := what.trim_prefix("body_")
	if customer.on_squash(kind, 1.0, walker.global_position):
		_known_bodies[kind] = _known_bodies.get(kind, 0) + 1
		_react()


## Is p inside something a critter (of this kind) can't walk through? Past the boundary,
## next door's, nothing is, but a hedgehog can't climb a wall.
func _blocked(p: Vector2, kind := "") -> bool:
	if Rect2($Truck.position - Vector2(64, 32), Vector2(128, 64)).has_point(p):
		return true
	if not _on_plot(p):
		return kind == "hedgehog" and _strip_at(p).get("kind", "") == "wall"
	if _house.rect().has_point(p) or _house.garage_rect().has_point(p) or _car_rect().has_point(p) or _notch.has_point(p):
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


func add_stone(p: Vector2, kind := "stone") -> Stone:
	var s := Stone.new()
	s.kind = kind
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
	# Winding up a throw, the camera leads halfway to the landing marker so it stays on screen.
	if walker:
		var lead := Vector2(_throw_reach(walker.power) / 2.0, 0.0) if walker.aiming else Vector2.ZERO
		cam.position = cam.position.lerp(lead, minf(1.0, delta * 6.0))
	_lay_track()
	# A canopy fades while you're under it or close, so nothing hides there.
	var me := actor().global_position
	for t in $Scenery.get_children():
		if "canopy" in t:
			t.near = t.crown_rect().grow(20.0).has_point(me) or me.distance_to(t.position) < t.radius + 30.0
	# And the house, from just behind its ridge (a chimney, the manor's roofline).
	var ridge := Rect2(_house.position - Vector2(0, 44), Vector2(_house.size.x, 44)).has_point(me)
	_house.modulate.a = move_toward(_house.modulate.a, 0.45 if ridge else 1.0, delta * 4.0)
	# So does the front hedge or fence while you're behind it.
	for strip in _front:
		var behind := Rect2(strip.position - Vector2(0, 40), strip.size + Vector2(0, 40)).has_point(me)
		strip.modulate.a = move_toward(strip.modulate.a, 0.45 if behind else 1.0, delta * 4.0)


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
	for s: Array in _spills: # a browned patch of lawn, or a puddle
		d.draw_set_transform(s[0], 0.0, Vector2(1.0, 0.6))
		d.draw_circle(Vector2.ZERO, 22.0, s[1])
		d.draw_circle(Vector2(8, 4), 12.0, s[1])
	d.draw_set_transform(Vector2.ZERO)
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
		if customer.nags == 1:
			Sfx.play("sigh", 0.0) # the tip just went
	hud.set_clock(customer.elapsed)
	$HUD/Face.expression = customer.face()
	# Where they are: on the patio, at a window (the house draws them at the glass), or in.
	$Client.visible = customer.where == "patio"
	_house.peek_x = customer.window_x if customer.where == "window" and not customer.knocked_out else -1
	# Greyed while they can't see you (design doc: line of sight), so you know you're unseen.
	$HUD/Face.view = customer.where if customer.sees(actor().global_position) else "inside"
	_show_cone()
	_carried_into_view()
	if customer.fired and settled.is_empty():
		_fired()
	hud.set_hint(_hint())
	_rifle(delta)
	_hold_critter(delta)
	_drag_hose()
	if police_left >= 0.0:
		police_left = maxf(0.0, police_left - delta)
		hud.set_police(police_left)
		_siren.volume_db = lerpf(-6.0, -26.0, police_left / Game.police_time(_heat0)) # louder as they close in
		if police_left <= 0.0:
			_nicked()
			return

	# Running over the customer on their patio. Don't.
	if customer.where == "patio" and not customer.knocked_out and mower.velocity.length() > 40.0 \
			and mower.global_position.distance_to($Client.position + Vector2(0, -10)) < 22.0:
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
	_cross()


func _fired_hint() -> String:
	return "Fired: no pay. Leave from the truck %s when you're done." % Game.key("interact")


## Who the player is right now: the mower, or themselves on foot.
func actor() -> Node2D:
	return walker if walker else mower


func at_truck() -> bool:
	return $Truck/RefuelZone.overlaps_body(actor())


func _hint() -> String:
	if walker:
		if walker.aiming:
			return "Up/down tilt   Let go to throw   %s cancel" % Game.key("hop")
		if walker.carrying == "jerrycan" and walker.global_position.distance_to(mower.global_position) < 44.0:
			return Game.key("interact") + " fill up the mower"
		if walker.carrying == "hose":
			return Game.key("interact") + " let go of the hose"
		if walker.carrying != "":
			return Game.key("interact") + (" toss it in the truck" if at_truck() else " drop it") + "   hold %s throw it" % Game.key("throw")
		var near := _stone_near(walker.global_position)
		if near:
			return Game.key("interact") + " pick up the " + _thing(near.kind)
		if _hose and _hose.nearest(walker.global_position) > 0:
			return Game.key("interact") + " pick up the hose"
		if dog and is_instance_valid(dog) and not dog.limping and not dog.held:
			if dog.following == walker:
				return "Walk %s back to the patio   %s pick them up" % [job.dog_name, Game.key("interact")]
			if walker.global_position.distance_to(dog.position) < DOG_REACH:
				return "%s put %s on the lead" % [Game.key("interact"), job.dog_name]
		if _critter_near(walker.global_position):
			return Game.key("interact") + " pick up the " + _critter_near(walker.global_position).kind
		if _can_rifle():
			if Input.is_action_pressed("interact") and robbed > 0.0:
				return "Rifling... $%d" % floori(robbed)
			return "Hold %s rifle their pockets" % Game.key("interact")
		if near_customer():
			return Game.key("interact") + " talk to " + job.customer
		if at_truck():
			return Game.key("interact") + " truck"
		if walker.global_position.distance_to(mower.global_position) < 44.0:
			return Game.key("interact") + " get back on"
		return _fired_hint() if customer.fired else ""
	if at_truck():
		return Game.key("interact") + " leave   (on foot, walk up to the customer to get paid)"
	return _fired_hint() if customer.fired else ""


func _unhandled_input(event: InputEvent) -> void:
	if over or hud.is_open():
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_0:
		_cheat_win()
	elif event.is_action_pressed("pause"):
		open_pause()
	elif event.is_action_pressed("hop") and walker and walker.aiming:
		walker.cancel_aim()
	elif event.is_action_pressed("hop"):
		if walker == null:
			hop_off()
		elif walker.carrying == "" and walker.global_position.distance_to(mower.global_position) < 44.0:
			hop_on()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("throw") and walker and walker.carrying not in ["", "hose"]:
		walker.aim()


## Let go of a wound-up throw.
func _on_thrown(dir: Vector2, power: float) -> void:
	if walker.carrying == "":
		return
	var f := throw_stone(_throw_from(dir), dir, _throw_speed(power), walker.pitch, walker.carrying)
	f.thrown = true
	f.out = _out
	if CRITTERS.has(walker.carrying):
		_count("animals_thrown")
	walker.carrying = ""
	walker.queue_redraw()
	_count("stones_thrown")
	Sfx.play("ui_move")


## Where a stone leaves your hand, thrown along dir.
func _throw_from(dir: Vector2) -> Vector2:
	return walker.global_position + dir * THROW_FROM * cos(walker.pitch)


## Where a throw at this power (and your aim) goes, stepped exactly as the stone will be:
## [each step's (x, y, height), what it hits first] (FlyingStone.trace).
func _throw_path(power: float) -> Array:
	var dir := Vector2.RIGHT.rotated(walker.rotation)
	var speed := _throw_speed(power)
	return FlyingStone.trace(_throw_from(dir), dir * speed * cos(walker.pitch), THROW_Z, speed * sin(walker.pitch),
		_stone_hit_test.bind(walker.carrying), 1.0 / Engine.physics_ticks_per_second)


## How far from you a throw at this power (and your pitch) lands, if nothing's in the way.
func _throw_reach(power: float) -> float:
	var pitch: float = walker.pitch if walker else 0.5
	return THROW_FROM * cos(pitch) + FlyingStone.reach(_throw_speed(power), pitch, THROW_Z)


## How hard a throw at this power leaves your hand: at 45 degrees it would carry
## THROW_MIN to THROW_MAX.
func _throw_speed(power: float) -> float:
	return sqrt(FlyingStone.GRAVITY * lerpf(THROW_MIN, THROW_MAX, power))


# ---------------------------------------------------------------- on foot

func hop_off() -> void:
	walker = WalkerScript.new()
	var side := Vector2(0, 26).rotated(mower.rotation)
	walker.position = lawn.keep_in(mower.global_position + side, 12.0)
	walker.keep_in = lawn.keep_in.bind(8.0)
	walker.path = _throw_path
	walker.thrown.connect(_on_thrown)
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
	if walker.carrying == "hose": # let go: it lies where you left it
		_hose.grabbed = -1
		walker.carrying = ""
		walker.queue_redraw()
		return
	if walker.carrying == "jerrycan" and walker.global_position.distance_to(mower.global_position) < 44.0:
		mower.add_fuel(mower.max_fuel)
		_count("cans")
		walker.carrying = ""
		walker.queue_redraw()
		Sfx.play("glug", 0.0)
	elif walker.carrying.begins_with("body_") and at_truck(): # in the back, under a tarp
		_count("bodies_hidden")
		Sfx.play("bump")
		walker.carrying = ""
		walker.queue_redraw()
	elif CRITTERS.has(walker.carrying) or walker.carrying.begins_with("body_"): # put it down (and a live one's off)
		_land(walker.global_position + Vector2(14, 0).rotated(walker.rotation), walker.carrying, _out)
		walker.carrying = ""
		walker.queue_redraw()
	elif walker.carrying != "": # set it down, or in the truck
		if not at_truck():
			add_stone(walker.global_position + Vector2(14, 0).rotated(walker.rotation), walker.carrying)
		elif walker.carrying == "stone":
			_count("stones_binned")
		Sfx.play("bump")
		walker.carrying = ""
		walker.queue_redraw()
	else:
		var s := _stone_near(walker.global_position)
		if s:
			s.queue_free()
			if s.kind == "stone":
				_count("stones_picked")
			walker.carrying = s.kind
			walker.queue_redraw()
			Sfx.play("ui_move", 0.0)
		elif _hose and _hose.nearest(walker.global_position) > 0:
			_hose.grabbed = _hose.nearest(walker.global_position)
			walker.carrying = "hose"
			Sfx.play("ui_move", 0.0)
		elif _pick_up_critter():
			pass
		elif near_customer():
			open_customer_menu()
		elif at_truck():
			open_truck_menu()
		elif walker.global_position.distance_to(mower.global_position) < 44.0:
			hop_on()


## Grab a nearby animal. A hedgehog bare-handed: you yelp, drop it, and stand there dazed.
## The dog: the lead goes on first; one on your lead you can pick up.
func _pick_up_critter() -> bool:
	var at := walker.global_position
	if dog and is_instance_valid(dog) and not dog.limping and not dog.held and dog.following != walker and dog.position.distance_to(at) < DOG_REACH:
		dog.lead(walker)
		return true
	if dog and is_instance_valid(dog) and not dog.held and dog.following == walker:
		dog.hold()
		walker.carrying = "dog"
	else:
		var a := _critter_near(at)
		if a == null:
			return false
		a.queue_free() # bare-handed, a hedgehog is in your hands for a moment (_hold_critter)
		walker.carrying = ("body_" if a.body else "") + a.kind
		_out = a.out # knocked out, it stays out in your hands
	_held = 0.0
	walker.queue_redraw()
	Sfx.play("ui_move", 0.0)
	return true


func _critter_near(p: Vector2) -> Animal:
	for a in $Animals.get_children():
		if a is Animal and not a.dead and not a.is_queued_for_deletion() and a.position.distance_to(p) < 20.0 and _on_plot(a.position):
			return a
	return null


## Holding an animal: the dog wriggles free, a squirrel bites; carry the dog to its owner.
func _hold_critter(delta: float) -> void:
	if walker == null or not CRITTERS.has(walker.carrying):
		return
	var kind: String = walker.carrying
	var bare := kind == "hedgehog" and "gloves" not in Game.upgrades
	_out = maxf(0.0, _out - delta)
	if (walker.aiming or _out > 0.0) and not bare: # out cold, it can't bite or wriggle; spines still prick
		return
	_held += delta
	if kind == "dog" and walker.global_position.distance_to(dog.home_point) < 60.0:
		walker.carrying = ""
		walker.queue_redraw()
		dog.let_go(dog.home_point)
		dog.home.emit(dog) # handed back to its owner
		dog.queue_free()
		return
	if _held < (PRICKLE if bare else CRITTERS[kind].hold):
		return
	walker.carrying = ""
	walker.queue_redraw()
	if kind == "squirrel":
		_count("bitten")
		Sfx.play("squeak_squirrel")
		pop_text("OW!", walker.global_position + Vector2(0, -24), Color("f07060"))
	elif bare:
		walker.cancel_aim()
		walker.dazed = 1.5
		_count("prickled")
		Sfx.play("squeak_hedgehog")
		pop_text("OW!", walker.global_position + Vector2(0, -24), Color("f07060"))
	_land(walker.global_position + Vector2(10, 0).rotated(walker.rotation), kind, _out)


## What a small thing's called in a hint.
func _thing(kind: String) -> String:
	return {"jerrycan": "petrol can", "ball": "tennis ball"}.get(kind, kind)


func _stone_near(p: Vector2) -> Stone:
	for s in $Stones.get_children():
		if s is Stone and not s.is_queued_for_deletion() and s.position.distance_to(p) < 18.0 and _on_plot(s.position):
			return s
	return null


# ---------------------------------------------------------------- the truck

func open_pause() -> void:
	get_tree().paused = true
	hud.open("Paused", wants_lines(), [["resume", "Resume"], ["music", "Music: %s" % ("on" if Sfx.music_on else "off")],
		["sound", "Sound: %s" % ("on" if Sfx.sound_on else "off")], ["quit", "Quit to title"]])


func open_truck_menu() -> void:
	get_tree().paused = true
	var buttons := []
	if not settled.is_empty():
		buttons.append(["drive_off", "Drive off"])
	elif customer.knocked_out:
		buttons.append(["leave_ko", "Leave quietly"])
	else:
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
	if police_left >= 0.0:
		lines.append("Sirens. The police are %d seconds out." % ceili(police_left))
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
		"status":
			open_customer_menu(_status_lines())
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
		"nicked":
			_finish_nicked()
		"quit":
			get_tree().paused = false
			Game.in_run = false
			get_tree().change_scene_to_file("res://title.tscn")


## Dragging the hose: it follows your hand, and holds you to its length from the tap.
func _drag_hose() -> void:
	if _hose == null:
		return
	if walker == null or walker.carrying != "hose" or _hose.grabbed < 0:
		if walker and walker.carrying == "hose": # the bit you held got mowed off
			walker.carrying = ""
		_hose.grabbed = -1
		return
	var tap := _hose.points[0]
	walker.global_position = tap + (walker.global_position - tap).limit_length(_hose.reach())
	_hose.hand = walker.global_position


## Through the blades: a cut hose, a puddle where it sprays, and it's theirs.
func _on_hose_mowed(at: Vector2) -> void:
	var k: Dictionary = Stone.KINDS.hose
	_count("hoses_mowed")
	mower.damage(k.damage)
	Sfx.play("splash")
	shake(2.0)
	_burst(at, ["3c9a3a", "1e5a24", "68a0e0"])
	_spills.append([at, k.spill])
	$Decals.queue_redraw()
	_mischief(3.0)
	if customer.on_property(k.theirs, k.mood, at):
		_react()


## Close enough to the customer to talk: on foot, by the patio (their door's there too).
func near_customer() -> bool:
	return walker != null and not customer.knocked_out and walker.global_position.distance_to($Client.position) < TALK


## Walked up to the customer (or knocked, if they're in): ask for your money, or how
## it's going. `lines` is what's just been said.
func open_customer_menu(lines: Array = []) -> void:
	get_tree().paused = true
	if customer.where != "patio": # they answer the door
		customer.come_out()
	var buttons := []
	if settled.is_empty():
		buttons.append(["handin", "Ask to be paid"])
	buttons.append(["status", "How am I doing?"])
	buttons.append(["resume", "Never mind" if settled.is_empty() else "Bye"])
	hud.open(job.customer, lines, buttons, job.look, customer.face())


## Asked how it's going: an honest answer, then what they asked for.
func _status_lines() -> Array:
	return ["\"%s\"" % customer.status_line(), "Mowed: %d%%" % floori(lawn.cut_fraction() * 100.0), ""] + wants_lines()


## What the customer asked for, so you needn't remember it: their words, and plainly
## how they want it done. On the pause menu, and when you ask them.
func wants_lines() -> Array:
	var p: Dictionary = Game.PERSONAS[job.persona]
	var lines: Array = ["%s said:" % job.customer]
	for b: String in job.brief:
		lines.append("   \"%s\"" % b)
	var pace := "quickly" if p.patience < 0.95 else ("no rush" if p.patience > 1.25 else "in good time")
	var finish := "every blade" if job.target >= 0.9 else ("roughly will do" if job.target <= 0.75 else "a tidy job")
	lines.append("Wants it: %s, %s." % [pace, finish])
	if job.get("dog", false):
		lines.append("%s the dog likes to escape." % job.dog_name)
	return lines


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
	open_customer_menu(["\"%s\"" % settled.comment, "They hand over $%d%s." % [settled.paid,
		(" (a $%d tip!)" % settled.tip) if settled.tip > 0 else ""],
		"Drive off from your truck when you like. (They're watching. Behave.)"])


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
	if settled.get("outcome") == "fired" and not _vandal:
		_vandal = true
		_crime(1) # trespass and vandalism
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
	result.heat_up = Game.heat > _heat0
	if robbed > 0.0:
		result.robbed = floori(robbed)
		result.net += result.robbed
		result.rep -= ROB_REP
	result.look = job.look
	result.face = customer.face() if result.outcome != "walked" else "furious"
	if result.outcome != "ko": # out cold, they find nothing
		result.noticed = customer.aftermath(_bodies_in_view(), lawn.cut_fraction() >= 0.999)
		for n: Array in result.noticed:
			result.rep += n[1]
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
		get_tree().change_scene_to_file("res://summary.tscn")
	elif get_tree().current_scene == self: # a lone job (dev play): go again
		get_tree().reload_current_scene()


# ---------------------------------------------------------------- crime

func _can_rifle() -> bool:
	return walker != null and walker.carrying == "" and customer.knocked_out and customer.where == "patio" and _wallet >= 1.0 \
		and walker.global_position.distance_to($Client.position) < 30.0


## Hold interact over a knocked-out customer: their cash trickles out, so every second
## robbing is a second not running. Robbery is its own crime, and a neighbour always sees.
func _rifle(delta: float) -> void:
	if not (_can_rifle() and Input.is_action_pressed("interact")):
		return
	if robbed == 0.0:
		_count("robberies")
		_crime(1)
		if police_left < 0.0:
			_call_police()
	var take := minf(_wallet, RIFLE_RATE * delta)
	_wallet -= take
	if floori(robbed + take) > floori(robbed):
		Sfx.play("ui_move", 0.2)
		if floori(robbed + take) % 5 == 0:
			pop_text("+$5", $Client.position + Vector2(0, -24))
	robbed += take


## A crime on the ladder (Game.HEAT): heat now, and the police called for assault, or
## for anything once your record is bad enough.
func _crime(tier: int, at := Vector2.INF) -> void:
	Game.heat += Game.HEAT[tier]
	worst_crime = maxi(worst_crime, tier)
	hud.pop("WANTED +%d" % Game.HEAT[tier])
	if police_left < 0.0 and customer.sees(at) and (tier >= 2 or _heat0 >= Game.HIGH_HEAT): # no witness, no call
		_call_police()


## Someone's rung the police: a visible countdown with sirens. Drive off before it runs out.
func _call_police() -> void:
	police_left = Game.police_time(_heat0)
	_siren = AudioStreamPlayer.new()
	_siren.bus = "SFX"
	_siren.stream = preload("res://audio/siren.wav")
	_siren.volume_db = -26.0
	add_child(_siren)
	_siren.play()
	hud.banner("POLICE CALLED")


## The police got here first.
func _nicked() -> void:
	over = true
	_siren.stop()
	get_tree().paused = true
	var fine := Game.fine(worst_crime, Game.heat)
	var lines := ["The police caught you at the scene.", "Fine: $%d, on top of the damages." % fine]
	if worst_crime >= 2:
		lines.append("And a night in the cells: you lose your next job.")
	hud.open("NICKED", lines, [["nicked", "Continue"]])


func _finish_nicked() -> void:
	var c := _costs()
	var r := settled.duplicate() if not settled.is_empty() else (customer.ko_result(c) if customer.knocked_out else customer.walked_result(c))
	r.outcome = "nicked"
	r.fine = Game.fine(worst_crime, Game.heat)
	r.cells = worst_crime >= 2
	r.fuel_cost = c
	r.net = r.paid - c - r.fine
	r.rep -= mischief
	r.mischief = mischief
	r.comment = "(Led away in handcuffs.)"
	robbed = 0.0 # and they take back what you lifted
	hud.close()
	_finish(r)


## Ramming the customer's car dents it like a stone, and harder hits cost more. Only a
## ram at speed is a crime: a bump at a crawl is an accident, like a blade-flung stone.
func _on_mower_bumped(what: Object, impact: float) -> void:
	if what is StaticBody2D and "art" in what and what.art == "topiary":
		if what.frame >= 3:
			return # already bitten
		what.frame += 3
		Sfx.play("crunch")
		_burst(what.position + Vector2(0, -24), ["2e6a2c", "4e9448", "6a4a2a"])
		_count("topiary", TOPIARY_BILL)
		bills += TOPIARY_BILL
		pop_text("-$%d" % TOPIARY_BILL, what.position + Vector2(0, -40), Color("f07060"))
		customer.on_property("topiary", -20.0, what.position)
		if impact > RAM_SPEED:
			_crime(1, what.position)
		_react()
		return
	if what != _car or _car == null:
		return
	var bill := roundf(CAR_BILL * maxf(1.0, impact / 150.0))
	Sfx.play("clonk")
	_count("car_dents", bill)
	bills += bill
	pop_text("-$%d" % bill, mower.global_position, Color("f07060"))
	customer.on_stone("car", _car.position)
	if impact > RAM_SPEED:
		_crime(1, _car.position)
	_react()


# ---------------------------------------------------------------- stones

## A small thing under the blades: what happens depends on what it is (Stone.KINDS).
func _on_stone_mowed(s: Stone, m: Node2D) -> void:
	if s.is_queued_for_deletion():
		return
	s.queue_free()
	var k: Dictionary = Stone.KINDS[s.kind]
	_count(s.kind + "s_mowed", k.get("bill", 0.0))
	if k.has("bill"):
		bills += k.bill
		pop_text("-$%d" % k.bill, s.position, Color("f07060"))
	m.damage(k.get("damage", 0.0))
	match k.mowed:
		"fling":
			Sfx.play("clonk" if s.kind == "stone" else "bump")
			shake(3.0)
			if k.get("always", false) or randf() < Stone.LAUNCH_CHANCE:
				var dir := Vector2.RIGHT.rotated(m.rotation + randf_range(-1.1, 1.1))
				throw_stone(s.position, dir, randf_range(380.0, 560.0), randf_range(0.15, 0.4), s.kind, 4.0)
			else: # ground to grit under the blades: show it went somewhere
				_burst(s.position, ["b4b4b8", "7a7a82", "d8d0c0"])
		"shatter":
			Sfx.play("crunch")
			shake(2.0)
			_burst(s.position, k.bits)
		"spill":
			Sfx.play("splash" if s.kind == "hose" else "glug")
			_spills.append([s.position, k.spill])
			$Decals.queue_redraw()
	if s.kind == "ball" and dog and is_instance_valid(dog) and not dog.limping and dog.position.distance_to(s.position) < 200.0:
		dog.grieve() # right in front of it
	if k.has("theirs"):
		_mischief(3.0)
		if customer.on_property(k.theirs, k.mood, s.position):
			_react()


## Bits flying off something mowed to pieces: a one-shot spray in its colours.
func _burst(at: Vector2, colours: Array) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.z_index = 2
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.7
	p.direction = Vector2.UP
	p.spread = 80.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(colours[0]), Color(colours[1])])
	for i in range(2, colours.size()):
		g.add_point(float(i) / colours.size(), Color(colours[i]))
	p.color_initial_ramp = g
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Count something for the job's tally (shown on the board if it isn't zero).
func _count(key: String, cost := 0.0) -> void:
	tally[key] = tally.get(key, 0) + 1
	if cost > 0.0:
		tally_cost[key] = tally_cost.get(key, 0.0) + cost


## Send a stone flying along the ground (flung by blades or thrown by hand).
## Something into the air from `from`, `z0` up, at `speed` tilted `pitch` above the ground.
func throw_stone(from: Vector2, dir: Vector2, speed: float, pitch: float, kind := "stone", z0 := THROW_Z) -> FlyingStone:
	var f := FlyingStone.new()
	f.kind = kind
	f.launch(from, dir, speed, pitch, z0, _stone_hit_test.bind(kind))
	f.landed.connect(_on_stone_landed)
	$Stones.add_child.call_deferred(f)
	return f


## The window a stone at ground p, height z strikes (house.gd windows(), plus UPSTAIRS
## for the floor above), or -1 for bare wall.
func _window_at(p: Vector2, z := 0.0) -> int:
	var x := p.x - _house.position.x
	var up := _up_the_front(p, z)
	var bands: Array = _house.panes()
	for wx: int in _house.windows():
		if x >= wx and x <= wx + 30:
			for i in bands.size():
				if up >= bands[i][0] and up <= bands[i][1]:
					return wx + i * _house.UPSTAIRS
	return -1


## How far up the front of the house a stone at ground p, height z meets it. The bit it
## has gone past the wall's foot this step counts as height too, as it's seen.
func _up_the_front(p: Vector2, z: float) -> float:
	return z + _house.position.y + _house.WALL_H - p.y


## A stone at ground p, height z against the buildings: the front wall (or a window in
## it), the roof sloping back from the wall's top to the ridge, and past the ridge it's
## gone (what's behind can't be seen). The garage is lower and the lawn runs on behind it.
func _building_hit(p: Vector2, z: float) -> String:
	var back: float = _house.position.y + _house.WALL_H - p.y # how far behind the wall's foot
	if back <= 0.0 or p.y < _house.position.y:
		return "" # in front, or out the back in the garden behind
	var up := _up_the_front(p, z)
	var h: Rect2 = _house.rect()
	if p.x >= h.position.x and p.x <= h.end.x:
		if up < _house.WALL_TOP:
			var w := _window_at(p, z)
			return "wall" if w < 0 else ("hole" if w in _house.broken else "window") # a broken pane lets it in
		if back <= _house.ROOF_D:
			return "roof" if z <= _house.WALL_TOP + back else ""
		if z > _house.WALL_TOP + _house.ROOF_D:
			return ""
		var behind := Vector2(p.x, _house.position.y - 10.0) # the back slope: down into the garden behind, or gone
		return "roof" if _house.position.y > 0.0 and lawn.keep_in(behind, 0.0) == behind else "gone"
	if _house.garage_rect().has_point(p) and up < _house.GARAGE_H:
		return "wall"
	return ""


## Is there a fence (or hedge) at p, just outside the lawn? Not across the drive's mouth.
func _fenced(p: Vector2) -> bool:
	for e: Rect2 in lawn.exits:
		if e.grow(4.0).has_point(p):
			return false
	if _haha and p.y < lawn.size_px.y:
		return false # into the ditch
	return p.distance_to(lawn.keep_in(p, 0.0)) <= BORDER # past that, it's over and gone


## What something flying (a stone, or whatever kind) at ground p and height z would hit,
## or "" for nothing. Everything has a height: lob over the fence, the customer, the car.
func _stone_hit_test(p: Vector2, z := 0.0, falling := false, kind := "stone") -> String:
	if Rect2($Truck.position - Vector2(60, 28), Vector2(120, 56)).has_point(p) and z < 60.0:
		return "truck" # parked on the road, just past the garden
	if lawn.keep_in(p, 0.0) != p and z < BORDER_UP and _fenced(p):
		return "fence" # into it; over it, it flies on and comes down next door
	if _car_rect().has_point(p) and z < 36.0:
		return "car"
	var building := _building_hit(p, z)
	if building != "":
		return building
	if customer.where == "patio" and not customer.knocked_out and p.distance_to($Client.position) < 12.0 and z < HEAD:
		return "customer"
	if walker and falling and p.distance_to(walker.global_position) < 8.0 and z < HEAD:
		return "self" # what goes up
	if walker and p.distance_to(mower.global_position) < 18.0 and z < 20.0: # your own mower, parked
		return "mower"
	for a in $Animals.get_children():
		if a is Animal and not a.dead and not a.body and a.position.distance_to(p) < CRITTER_HIT and z < 10.0:
			return "animal"
	if kind != "ball" and dog and is_instance_valid(dog) and not dog.held and dog.position.distance_to(p) < 12.0 and z < 16.0:
		return "dog" # the ball sails past: it's by your feet, waiting for the throw
	for t in $Scenery.get_children():
		if not (t is StaticBody2D and "radius" in t):
			continue
		if not t.has_method("shake"): # a boulder, a headstone, topiary
			if p.distance_to(t.position) < t.radius and z < t.height:
				return "rock"
		elif p.distance_to(t.position) < t.radius and z < -(t.crown_centre().y + t.canopy):
			return "tree" # the trunk
		elif p.distance_to(t.position) < t.canopy * 0.8 and absf(z + t.crown_centre().y) < t.canopy * 0.8:
			return "tree" # up in the leaves
	return "" # a pond is flat: the stone flies over it, see _pond_at on landing


func _on_stone_landed(f: FlyingStone, target: String) -> void:
	var p := f.position
	var alive := CRITTERS.has(f.kind) # a live animal: it lands on its feet, whatever it hit
	var tier := 0 # what hitting this is on the crime ladder, if it was thrown on purpose
	match target:
		"customer":
			Sfx.play("thud")
			_count("customer_hits")
			_mischief(8.0)
			tier = 2 # assault
			if customer.on_stone("customer", p):
				_knock_out() # a crime of its own
				tier = -1
			else:
				_react()
			_drop_bounced(f)
		"window", "hole": # through the glass, or in through a pane already gone: the stone's indoors now
			var w := _window_at(p, f.z)
			if target == "window":
				var bill := WINDOW_BILL * (3.0 if _house.venue == "mansion" else 1.0) # old glass, dear glass
				Sfx.play("glass", 0.0)
				_house.smash(w)
				_count("windows", bill)
				_mischief(5.0)
				bills += bill
				pop_text("-$%d" % bill, p, Color("f07060"))
				shake(4.0)
				tier = 1
			else:
				Sfx.play("thud")
			if customer.where == "window" and customer.window_x == w and not customer.knocked_out:
				_count("customer_hits") # and into them
				tier = 2
				if customer.on_stone("customer", p):
					_knock_out()
					tier = -1
			else:
				customer.on_stone("window" if target == "window" else "wall", p)
			if not customer.knocked_out and (target == "window" or customer.sees(p)):
				_react()
			if alive:
				_drop_bounced(f) # it scrambles back out
		"wall":
			Sfx.play("thud")
			customer.on_stone("wall", p)
			if customer.sees(p): # indoors, a thud is nothing to them
				_react()
			_drop_bounced(f)
		"car":
			Sfx.play("clonk")
			_count("car_dents", CAR_BILL)
			bills += CAR_BILL
			pop_text("-$%d" % CAR_BILL, p, Color("f07060"))
			shake(3.0)
			customer.on_stone("car", p)
			tier = 1
			_react()
			_drop_bounced(f)
		"truck":
			Sfx.play("clonk")
			_count("dents", DENT_BILL)
			bills += DENT_BILL
			pop_text("-$%d" % DENT_BILL, p, Color("f07060"))
			_drop_bounced(f)
		"animal":
			for a in $Animals.get_children():
				if a is Animal and not a.dead and not a.body and a.position.distance_to(p) <= CRITTER_HIT:
					_stone_critter(a, f.thrown)
					break
			if alive:
				_drop_bounced(f)
		"dog":
			Sfx.play("yelp")
			dog.bowl("stone")
			customer.on_stone("dog", p)
			tier = 1
			_react()
			_drop_bounced(f)
		"gone":
			if f.kind == "dog":
				_land(lawn.keep_in(p, 8.0), "dog") # it scrabbles at the fence instead
			elif f.kind.begins_with("body_"):
				_count("bodies_hidden") # next door's problem now
		"fence":
			Sfx.play("thud")
			_drop_bounced(f)
		"roof": # it clatters down the tiles and drops off the gutter
			Sfx.play("clonk")
			customer.on_stone("wall", p)
			if customer.sees(p):
				_react()
			var foot := Vector2(p.x, _house.position.y + _house.WALL_H + 10.0)
			if p.y < _house.position.y + _house.WALL_H - _house.ROOF_D: # the back slope
				foot.y = _house.position.y - 10.0
			get_tree().create_timer(0.5).timeout.connect(_land.bind(foot, f.kind, f.out))
		"self":
			Sfx.play("thud")
			_count("own_head")
			walker.dazed = 1.5
			pop_text("OW!", walker.global_position + Vector2(0, -24), Color("f07060"))
			_land(walker.global_position + Vector2(10, 4), f.kind, f.out)
		"mower":
			Sfx.play("clonk")
			mower.damage(8.0)
			_count("own_goals")
			shake(2.0)
			_drop_bounced(f)
		"tree":
			Sfx.play("thud")
			for t in $Scenery.get_children():
				if t is StaticBody2D and t.has_method("shake") and p.distance_to(t.position) < t.radius + 10.0:
					t.shake() # the canopy sways and drops leaves
					_rustle(t.position + t.crown_centre(), Vector2.DOWN)
			_count("trees_hit")
			_drop_bounced(f) # drops just outside the trunk
		"rock":
			Sfx.play("clonk")
			_drop_bounced(f)
		_:
			var pond := _pond_at(p)
			if pond:
				Sfx.play("splash")
				var fit := pond.splash_fit(p)
				_splash(fit[0], fit[1])
				_count("splashes")
				target = "pond"
				if alive: # it swims for the bank
					_land(pond.position + (p - pond.position).normalized() * Vector2(Pond.RX + 10.0, Pond.RY + 10.0), f.kind, f.out)
				elif f.kind.begins_with("body_"):
					_count("bodies_hidden") # sleeps with the fishes
			else:
				Sfx.play("thud")
				if f.kind.begins_with("body_") and not _on_plot(p):
					_count("bodies_hidden") # next door's problem now
				for b in $Scenery.get_children():
					if b.has_method("flattened_count") and b.rect().has_point(p):
						b._trample(b.to_local(p), 12.0) # flattens a flower or two where it lands
				_land(p, f.kind, f.out)
	if f.thrown and tier >= 0:
		if alive:
			if target == "": # just thrown across the lawn: the animal's own tier
				tier = CRITTERS[f.kind].tier
			elif target not in ["gone", "self"]: # into something: one above the worse of the two, and heat for the method
				tier = mini(2, maxi(tier, CRITTERS[f.kind].tier) + 1)
				Game.heat += 1.0
		if tier > 0:
			_crime(tier, p)


## A stone that struck something solid bounces back off it and lands on the lawn. A critter
## thrown hard into it is knocked out.
func _drop_bounced(f: FlyingStone) -> void:
	if f.thrown and f.kind in ["hedgehog", "squirrel"] and f.velocity.length() > SLAM:
		f.out = maxf(f.out, KO_TIME)
		Sfx.play("squeak_" + f.kind)
		_count("ko_" + f.kind)
	_land(lawn.keep_in(f.position - f.velocity.normalized() * 12.0, 4.0), f.kind, f.out)


## Something thrown or flung comes down on the lawn. A ball, the dog goes after.
func _land(at: Vector2, kind: String, out := 0.0) -> void:
	if kind == "dog":
		if dog and is_instance_valid(dog):
			dog.let_go(lawn.keep_in(at, 8.0)) # over the fence, it scrabbles back
			Sfx.play("yelp")
		return
	if kind.begins_with("body_"):
		(func() -> void: spawn_animal(kind.trim_prefix("body_"), at, at + Vector2.RIGHT).kill()).call_deferred()
		return
	if CRITTERS.has(kind): # on its feet and off, away from you; or still out cold where it lands
		var away := (at - actor().global_position).normalized().rotated(randf_range(-0.6, 0.6))
		(func() -> void:
			var a := spawn_animal(kind, at, at + away * 400.0, 0.4)
			if out > 0.0:
				a.stun(out)).call_deferred()
		return
	(func() -> void:
		var s := add_stone(at, kind)
		if kind == "ball" and dog and is_instance_valid(dog) and _on_plot(at):
			dog.fetch(s, walker if walker else $Client)).call_deferred()


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
	_wallet = job.pay * randf_range(0.2, 0.6)
	_crime(2)
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
	var fp: Rect2 = _house.rect() # it runs about the garden on their side of the house
	dog.lawn_rect = Rect2(0, 0, lawn.size_px.x, fp.position.y - 50.0) if _house.back_patio \
		else Rect2(0, fp.end.y, lawn.size_px.x, lawn.size_px.y - fp.end.y)
	dog.bowled.connect(func(_d: Dog, by: String) -> void:
		_count("dog_bowled")
		Sfx.play("yelp")
		if by == "mower": # a stone's reaction is the stone's (see _on_stone_landed)
			customer.on_dog_hit()
			_mischief(8.0)
			_crime(2, _d.position)
			_react())
	dog.caught.connect(func(d: Dog) -> void:
		Sfx.play("ui_select", 0.0)
		pop_text("On the lead!", d.position + Vector2(0, -10), UI.GOOD))
	dog.dropped_ball.connect(func(at: Vector2) -> void:
		_count("fetches")
		add_stone.call_deferred(at, "ball"))
	dog.home.connect(func(_d: Dog) -> void:
		_count("dog_returned")
		if customer.on_dog_returned(_d.position):
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


## A critter is coming. Most walk in from next door, out of sight (a hedge rustles as they
## push through, _cross); a squirrel up a tree shakes the canopy first.
func _tell(kind: String) -> void:
	if $Animals.get_child_count() + _tells.size() >= max_animals:
		return
	var spot := _spawn_spot(kind)
	if spot.is_empty():
		return
	if spot.grace <= 0.0:
		spawn_animal(kind, spot.at).visited = false # not gone till it has been in
		return
	_tells.append({"kind": kind, "at": spot.at, "grace": spot.grace, "left": TELL})
	_rustle(spot.at, spot.inward)


## Where a critter of this kind comes in: {at, grace, inward, edge}, or {} if it can't.
## Squirrels may climb down a tree. The rest start off the property, back out of sight,
## heading in over `edge`; a hedgehog can't climb a wall.
func _spawn_spot(kind: String) -> Dictionary:
	var trees := $Scenery.get_children().filter(func(t: Node) -> bool: return t is StaticBody2D and t.has_method("shake")) # not rocks, headstones or topiary
	if kind == "squirrel" and not trees.is_empty() and randf() < 0.5:
		var t: Node2D = trees[randi() % trees.size()]
		return {"at": t.position + Vector2.RIGHT.rotated(randf() * TAU) * t.radius * 0.5,
			"grace": 1.0, "inward": Vector2.DOWN} # climbing down out of the canopy
	var want := "hedge" if kind == "hedgehog" else "fence"
	var pool := _edges.filter(func(e: Dictionary) -> bool: return e.kind == want)
	if pool.is_empty():
		pool = _edges.filter(func(e: Dictionary) -> bool: return kind != "hedgehog" or e.kind != "wall")
	if pool.is_empty():
		return {}
	var e: Dictionary = pool[randi() % pool.size()]
	var at := (e.from as Vector2).lerp(e.to, randf_range(0.05, 0.95))
	for i in 10: # not where a building stands against the boundary (a terrace, the church)
		if not _blocked(at + (e.inward as Vector2) * 12.0):
			break
		e = pool[randi() % pool.size()]
		at = (e.from as Vector2).lerp(e.to, randf_range(0.05, 0.95))
	var from := at
	for i in 10: # back out of sight, so it's seen walking in, not popping up
		from = at - (e.inward as Vector2) * (40.0 + 30.0 * i)
		if not _on_screen(from):
			break
	return {"at": from, "grace": 0.0, "inward": e.inward, "edge": at}


## Is p on the property (the lawn, the drive), not out past its boundary?
func _on_plot(p: Vector2) -> bool:
	return lawn.keep_in(p, 0.0) == p


## The boundary run (a hedge, fence, wall...) p is in: {kind, rect, inward}, or {}.
func _strip_at(p: Vector2) -> Dictionary:
	for s: Dictionary in _strips:
		if (s.rect as Rect2).has_point(p):
			return s
	return {}


func _on_screen(p: Vector2, margin := 24.0) -> bool:
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	return view.grow(margin).has_point(p)


## Critters crossing the boundary, either way: a hedge rustles as they push through. One
## that has been in the garden and wandered off out of sight is gone.
func _cross() -> void:
	for a in $Animals.get_children():
		if not (a is Animal) or a.dead or a.body or a.is_queued_for_deletion():
			continue
		var on := _on_plot(a.position)
		if on != a.on_plot:
			a.on_plot = on
			var probe: Vector2 = a.position - a.heading * 6.0 if on else a.position
			var s := _strip_at(probe)
			if s.get("kind", "") == "hedge":
				_rustle(probe, s.inward if on else -s.inward)
			if on:
				a.visited = true
		elif not on and a.visited and not _on_screen(a.position):
			a.queue_free()


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
	var incoming := at == Vector2.INF # from next door (_spawn_spot)
	if incoming:
		var spot := _spawn_spot(kind)
		if spot.is_empty():
			return null
		at = spot.at
		grace = spot.grace
	if toward == Vector2.INF:
		for i in 10:
			toward = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
			if not _blocked(toward):
				break
	var a := Animal.new()
	a.blocked = _blocked.bind(kind)
	a.on_plot = _on_plot(at)
	a.visited = a.on_plot or not incoming # coming in from next door: not gone till it has been in
	a.grace = grace
	a.kind = kind
	a.position = at
	a.heading = (toward - at).normalized()
	a.lawn_rect = r
	a.squashed.connect(_on_squashed)
	$Animals.add_child(a)
	return a


func _on_squashed(a: Animal) -> void:
	if a.body: # a body through the blades: mulch, nothing left to find
		_count("bodies_mulched")
		_burst(a.position, ["a01818", "6a0c0c", "8a6a50"])
		Sfx.play("squash")
		shake(2.0)
		if customer.on_squash(a.kind, 1.0, a.position):
			_react()
		return
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
	_mischief(3.0)
	if customer.on_squash(a.kind, 1.0, a.position):
		_react()


## A stone into a critter (design doc: thrown knocks out, flung splats; either way
## sometimes the other). Killed by a thrown stone, it's a body, not a splat.
func _stone_critter(a: Animal, thrown: bool, roll := randf()) -> void:
	var ko := roll < THROWN_KO if thrown else roll >= FLUNG_SPLAT
	if not ko and not thrown:
		a.squash() # the splat, as ever (_on_squashed)
		return
	Sfx.play("squeak_" + a.kind)
	shake(2.0)
	if ko:
		a.stun(KO_TIME)
		_count("ko_" + a.kind)
		_mischief(1.0)
		if customer.on_squash(a.kind, KO_SHARE, a.position):
			_react()
		return
	a.kill()
	_count("stoned_" + a.kind)
	_mischief(3.0)
	if customer.on_squash(a.kind, 1.0, a.position):
		_known_bodies[a.kind] = _known_bodies.get(a.kind, 0) + 1
		_react()


## Bodies left lying where the customer will see them from the patio, by kind: found after
## you've gone, less any they already saw (a stoning they watched, one you carried past).
func _bodies_in_view() -> Dictionary:
	var out := {}
	for a in $Animals.get_children():
		if a is Animal and a.body and not a.dead and not a.is_queued_for_deletion() and _on_plot(a.position) and _clear($Client.position, a.position):
			out[a.kind] = out.get(a.kind, 0) + 1
	for kind: String in out.keys():
		out[kind] -= _known_bodies.get(kind, 0)
		if out[kind] <= 0:
			out.erase(kind)
	return out


## Bodies of this kind lying on the lawn (not in your hands, not gone over the fence).
func _bodies(kind: String) -> int:
	return $Animals.get_children().filter(func(a: Node) -> bool:
		return a is Animal and a.body and not a.dead and not a.is_queued_for_deletion() and a.kind == kind and _on_plot(a.position)).size()


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
	if customer.on_flowers(total, actor().global_position):
		_mischief(2.0)
		if Time.get_ticks_msec() >= _flowers_quiet_until: # the rep still counts every flower
			_flowers_quiet_until = Time.get_ticks_msec() + 1500
			_react()
