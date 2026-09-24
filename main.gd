extends Node2D
## One job: builds the garden from Game.job(), runs the customer's mood, and ends
## in a pay screen, a firing, a knockout, or you driving off. Outside a run (tests,
## playing this scene directly) it uses the slice's hand-made lawn and skips the
## briefing.

const TreeScript := preload("res://tree.gd")
const BedScript := preload("res://flowerbed.gd")
const HouseScript := preload("res://house.gd")
const WalkerScript := preload("res://walker.gd")

const WINDOWS := [40, 120, 290, 370] ## x of each window in the house art (30 wide, y 69..93)
const REPAIR_PRICE := 0.5 ## per condition point repaired
const WINDOW_BILL := 40.0
const DENT_BILL := 20.0

@export var hedgehog_every := 7.0 ## seconds between hedgehogs, roughly
@export var squirrel_every := 13.0
@export var max_animals := 5

var job: Dictionary
var customer: Customer
var hits := {}
var over := false
var bills := 0.0 ## broken windows, dented truck
var walker: CharacterBody2D = null ## the player on foot, or null while mowing
var dog: Dog = null
var pay_result := {} ## set once paid: you can still hang about (and misbehave)
var mischief := 0.0 ## reputation owed for what you did after being paid

var _next_hedgehog := 3.0
var _next_squirrel := 8.0
var _dog_in := -1.0
var _house: Node2D
var _shake := 0.0

@onready var lawn: Lawn = $Lawn
@onready var mower: CharacterBody2D = $Mower
@onready var hud: CanvasLayer = $HUD
@onready var cam: Camera2D = $Mower/Camera


func _ready() -> void:
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

	# Keep the camera inside the lawn so nothing beyond its edge is ever shown.
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = lawn.size_px.x
	cam.limit_bottom = lawn.size_px.y

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
		lines.append_array(["", "Mow the lawn. Hand in at your truck when you're happy.",
			"[F] hop off to move stones, fetch fuel, or catch a dog."])
		hud.open(job.customer, lines, [["start", "Let's go"]], job.look, "neutral")


## Lay out the garden: house along the top, driveway and truck bottom-left, then
## trees, flowerbeds and stones. The default job keeps the slice's hand-placed layout.
func _build_layout() -> void:
	var size: Vector2i = job.size
	lawn.size_px = size
	lawn.setup()
	var fixed: bool = job.get("fixed_layout", false)

	_house = HouseScript.new()
	_house.name = "House"
	_house.position = Vector2(size.x * 0.5 - _house.size.x * 0.5, 0)
	var wall := StaticBody2D.new() # the house itself is solid; the patio in front isn't
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(_house.size.x, 106)
	wall_shape.position = Vector2(_house.size.x * 0.5, 53)
	wall.add_child(wall_shape)
	_house.add_child(wall)
	$Scenery.add_child(_house)
	$Client.position = _house.patio_point()
	$Client.watch = mower
	$Client.set_look(job.look)

	var drive: Control = $Driveway
	drive.position = Vector2(0, size.y - 180)
	$Truck.position = Vector2(110, size.y - 90)
	mower.position = Vector2(230, size.y - 90)
	$Truck/Trailer.visible = Game.in_run and "rideon" in Game.owned

	var taken: Array[Rect2] = [_house.rect().grow(50), Rect2(drive.position, drive.size).grow(70)]
	var trees: Array = []
	var beds: Array = []
	var stones: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = job.seed
	if fixed:
		trees = [[Vector2(900, 420), 34.0]]
		beds = [Rect2(360, 300, 200, 80)]
	else:
		for i in job.beds:
			var br := _place(r, taken, Vector2(r.randf_range(140, 240), r.randf_range(64, 96)), size)
			if br.has_area():
				beds.append(br)
		for i in job.trees:
			var rad: float = [26.0, 34.0, 42.0][r.randi() % 3] # matches the canopy art sizes
			var tr := _place(r, taken, Vector2(rad, rad) * 2.0, size)
			if tr.has_area():
				trees.append([tr.get_center(), rad])
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
		t.radius = trees[i][1]
		t.variant = i
		var cs := CollisionShape2D.new()
		cs.name = "Shape"
		t.add_child(cs)
		$Scenery.add_child(t)
		lawn.exclude_circle(t.position, t.radius)
	for p: Vector2 in stones:
		add_stone(p)
	lawn.exclude_rect(_house.rect())
	lawn.exclude_rect(Rect2(drive.position, drive.size))


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
	_shake = maxf(0.0, _shake - delta * 18.0)
	cam.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))


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
	if customer.fired and pay_result.is_empty():
		_finish(customer.fired_result(_costs()))
		return
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
		spawn_animal("hedgehog")
	if _next_squirrel <= 0.0:
		_next_squirrel = squirrel_every * randf_range(0.6, 1.4)
		spawn_animal("squirrel")


## Who the player is right now: the mower, or themselves on foot.
func actor() -> Node2D:
	return walker if walker else mower


func at_truck() -> bool:
	return $Truck/RefuelZone.overlaps_body(actor())


func _hint() -> String:
	if walker:
		match walker.carrying:
			"stone":
				return "[E] toss it in the truck" if at_truck() else "[E] drop the stone"
			"jerrycan":
				return "[E] fill up the mower" if walker.global_position.distance_to(mower.global_position) < 44.0 else "Take the can to the mower"
		if _stone_near(walker.global_position):
			return "[E] pick up the stone"
		if at_truck():
			return "[E] truck"
		if walker.global_position.distance_to(mower.global_position) < 44.0:
			return "[F] get back on"
		return ""
	return "[E] talk to the customer / leave" if at_truck() else ""


func _unhandled_input(event: InputEvent) -> void:
	if over or hud.is_open():
		return
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		hud.open("Paused", [], [["resume", "Resume"], ["quit", "Quit to title"]])
	elif event.is_action_pressed("hop"):
		if walker == null:
			hop_off()
		elif walker.carrying == "" and walker.global_position.distance_to(mower.global_position) < 44.0:
			hop_on()
	elif event.is_action_pressed("interact"):
		interact()


# ---------------------------------------------------------------- on foot

func hop_off() -> void:
	walker = WalkerScript.new()
	var side := Vector2(0, 26).rotated(mower.rotation)
	walker.position = (mower.global_position + side).clamp(Vector2(12, 12), Vector2(lawn.size_px) - Vector2(12, 12))
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
			Sfx.play("bump")
			walker.carrying = ""
			walker.queue_redraw()
		"jerrycan":
			if walker.global_position.distance_to(mower.global_position) < 44.0:
				mower.add_fuel(mower.max_fuel)
				walker.carrying = ""
				walker.queue_redraw()
				Sfx.play("glug", 0.0)
		_:
			var s := _stone_near(walker.global_position)
			if s:
				s.queue_free()
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

func open_truck_menu() -> void:
	get_tree().paused = true
	var buttons := []
	if not pay_result.is_empty():
		buttons.append(["leave_paid", "Drive off"])
	elif customer.knocked_out:
		buttons.append(["leave_ko", "Leave quietly"])
	else:
		buttons.append(["handin", "Ask to be paid"])
		buttons.append(["leave", "Drive off (no pay)"])
	if walker and walker.carrying == "" and mower.power == "fuel":
		buttons.append(["can", "Grab the fuel can"])
	buttons.append(["resume", "Keep going"])
	var lines := ["Mowed: %d%%" % floori(lawn.cut_fraction() * 100.0),
		"Mower condition: %d%%" % roundi(mower.condition)]
	if customer.knocked_out:
		lines.append("The customer is out cold on the patio.")
	hud.open("At the truck", lines, buttons)


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
		"leave_paid":
			_leave_paid()
		"hang":
			hud.close()
			get_tree().paused = false
		"can":
			walker.carrying = "jerrycan"
			walker.queue_redraw()
			hud.close()
			get_tree().paused = false
		"continue":
			get_tree().paused = false
			if Game.in_run:
				get_tree().change_scene_to_file("res://board.tscn")
			else:
				get_tree().reload_current_scene()
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
		_react()
		hud.close()
		get_tree().paused = false
		return
	pay_result = customer.evaluate(cov, _costs())
	customer.paid = true
	Sfx.play("cash", 0.0)
	pop_text("+$%d" % pay_result.paid, $Client.position + Vector2(0, -40))
	if Game.in_run and pay_result.mood >= 60.0:
		Sfx.play("voice_happy")
	get_tree().paused = true
	hud.open("Paid!", ["\"%s\"" % pay_result.comment, "", "They hand over $%d." % pay_result.paid,
		"You can drive off now, or hang about.", "(They're watching. Behave.)"],
		[["leave_paid", "Drive off"], ["hang", "Hang about"]], job.look, customer.face())


## Leave after being paid. Anything you got up to afterwards comes off your reputation.
func _leave_paid() -> void:
	var r := pay_result.duplicate()
	r.fuel_cost = _costs()
	r.net = r.paid - r.fuel_cost
	r.rep -= mischief
	r.mischief = mischief
	if mischief > 0.0:
		r.comment = "And don't come back!"
	_finish(r)


## Wreck something after being paid and it lands on your reputation, not your pay.
func _mischief(points: float) -> void:
	if customer.paid:
		mischief += points
		pop_text("Rep -%d" % roundi(points), $Client.position + Vector2(0, -40), Color("f07060"))


func _costs() -> float:
	var fuel_price: float = Game.mower_spec().fuel_price if Game.in_run else 0.25
	return mower.fuel_used * fuel_price + mower.repaired * REPAIR_PRICE + bills


func _finish(result: Dictionary) -> void:
	over = true
	get_tree().paused = true
	Game.record_result(result)
	Sfx.music("")
	match result.outcome:
		"paid":
			if result.get("mischief", 0.0) > 0.0:
				Sfx.play("voice_angry")
		"fired":
			Sfx.play("fired", 0.0)
			Sfx.play("voice_angry")
		"walked":
			Sfx.play("voice_angry")
	var lines := []
	match result.outcome:
		"fired":
			lines = ["\"%s\"" % result.comment, "", "No pay.", "Reputation took a big hit."]
		"walked":
			lines = ["\"%s\"" % result.comment, "", "You drove off without being paid.", "Word gets around."]
		"ko":
			lines = [result.comment, "", "No pay. But nobody saw a thing... probably.",
				"(Your wanted level went up.)"]
		_:
			lines = ["\"%s\"" % result.comment, "",
				"Mowed: %d%%" % floori(result.coverage * 100.0),
				"Time: %d:%02d" % [floori(result.elapsed / 60.0), int(result.elapsed) % 60],
				"Paid: $%d%s" % [result.paid, ("  (includes $%d tip!)" % result.tip) if result.tip > 0 else ""]]
			if result.get("mischief", 0.0) > 0.0:
				lines.append("Mischief after payment: reputation -%d" % roundi(result.mischief))
	if result.fuel_cost > 0.0:
		lines.append("Costs: -$%d  (fuel, repairs%s)" % [roundi(result.fuel_cost), ", damages" if bills > 0.0 else ""])
	if Game.in_run:
		lines.append("")
		lines.append("Money: $%d    Reputation: %s" % [Game.money, UI.rep_word(Game.reputation)])
	var title: String = {"fired": "FIRED!", "walked": "You left", "ko": "Well, that happened"}.get(result.outcome, "Job done")
	hud.open(title, lines, [["continue", "Continue"]], job.look, customer.face() if result.outcome != "walked" else "furious")


# ---------------------------------------------------------------- stones

func _on_stone_mowed(s: Stone, m: Node2D) -> void:
	if s.is_queued_for_deletion():
		return
	s.queue_free()
	m.damage(12.0)
	Sfx.play("clonk")
	shake(3.0)
	if randf() < Stone.LAUNCH_CHANCE:
		var f := FlyingStone.new()
		var dir := Vector2.RIGHT.rotated(m.rotation + randf_range(-1.1, 1.1))
		f.launch(s.position, dir, randf_range(380.0, 560.0), randf_range(140.0, 380.0), _stone_hit_test)
		f.landed.connect(_on_stone_landed)
		$Stones.add_child.call_deferred(f)


## What a flying stone at p would hit, or "" for nothing.
func _stone_hit_test(p: Vector2) -> String:
	if not Rect2(Vector2.ZERO, Vector2(lawn.size_px)).has_point(p):
		return "gone"
	if not customer.knocked_out and p.distance_to($Client.position + Vector2(0, -14)) < 11.0:
		return "customer"
	var h: Rect2 = _house.rect()
	if h.has_point(p) and p.y < h.position.y + 106.0:
		var lx := p.x - h.position.x
		for wx: int in WINDOWS:
			if lx >= wx and lx <= wx + 30 and p.y > h.position.y + 60.0:
				return "window"
		return "wall"
	if Rect2($Truck.position - Vector2(60, 28), Vector2(120, 56)).has_point(p):
		return "truck"
	for a in $Animals.get_children():
		if a is Animal and not a.dead and a.position.distance_to(p) < 10.0:
			return "animal"
	if dog and is_instance_valid(dog) and dog.position.distance_to(p) < 12.0:
		return "dog"
	for t in $Scenery.get_children():
		if t is StaticBody2D and "radius" in t and p.distance_to(t.position) < t.radius:
			return "tree"
	return ""


func _on_stone_landed(f: FlyingStone, target: String) -> void:
	var p := f.position
	match target:
		"customer":
			Sfx.play("thud")
			_mischief(8.0)
			if customer.on_stone("customer"):
				_knock_out()
			else:
				_react()
		"window":
			Sfx.play("glass", 0.0)
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
			bills += DENT_BILL
			pop_text("-$%d" % DENT_BILL, p, Color("f07060"))
		"animal":
			for a in $Animals.get_children():
				if a is Animal and not a.dead and a.position.distance_to(p) < 12.0:
					a.squash()
					break
		"dog":
			Sfx.play("yelp")
			dog.bowl()
			customer.on_stone("dog")
			_react()
		"gone":
			pass # over the fence and into next door's garden
		_:
			Sfx.play("thud")
			add_stone.call_deferred(p)


func _knock_out() -> void:
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
		Sfx.play("yelp")
		customer.on_dog_hit()
		_mischief(8.0)
		_react())
	dog.home.connect(func(_d: Dog) -> void:
		customer.on_dog_returned()
		_react())
	$Animals.add_child(dog)
	customer.last_line = "Oh no, %s's got out!" % job.dog_name
	hud.say(customer.last_line)
	$Client.react()
	Sfx.play("voice_horrified")


# ---------------------------------------------------------------- wildlife

## Spawn an animal just outside a random lawn edge, heading for a random point
## on the lawn so it crosses it.
func spawn_animal(kind: String, at := Vector2.INF, toward := Vector2.INF) -> Animal:
	if $Animals.get_child_count() >= max_animals and at == Vector2.INF:
		return null
	var r := Rect2(Vector2.ZERO, Vector2(lawn.size_px))
	if at == Vector2.INF:
		match randi() % 4:
			0: at = Vector2(randf_range(r.position.x, r.end.x), r.position.y - 20)
			1: at = Vector2(randf_range(r.position.x, r.end.x), r.end.y + 20)
			2: at = Vector2(r.position.x - 20, randf_range(r.position.y, r.end.y))
			_: at = Vector2(r.end.x + 20, randf_range(r.position.y, r.end.y))
	if toward == Vector2.INF:
		toward = Vector2(randf_range(r.position.x, r.end.x), randf_range(r.position.y, r.end.y))
	var a := Animal.new()
	a.kind = kind
	a.position = at
	a.heading = (toward - at).normalized()
	a.lawn_rect = r
	a.squashed.connect(_on_squashed)
	$Animals.add_child(a)
	return a


func _on_squashed(a: Animal) -> void:
	hits[a.kind] = hits.get(a.kind, 0) + 1
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
		_react()
