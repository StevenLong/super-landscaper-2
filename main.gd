extends Node2D
## One job: builds the garden from Game.job(), runs the customer's mood, and ends
## in a pay screen, a firing, or you driving off. Outside a run (tests, playing
## this scene directly) it uses the slice's hand-made lawn and skips the briefing.

const TreeScript := preload("res://tree.gd")
const BedScript := preload("res://flowerbed.gd")
const HouseScript := preload("res://house.gd")

@export var hedgehog_every := 7.0 ## seconds between hedgehogs, roughly
@export var squirrel_every := 13.0
@export var max_animals := 5

var job: Dictionary
var customer: Customer
var hits := {}
var over := false

var _next_hedgehog := 3.0
var _next_squirrel := 8.0
var _at_truck := false

@onready var lawn: Lawn = $Lawn
@onready var mower: CharacterBody2D = $Mower
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	job = Game.job()
	customer = Customer.new(job)
	hedgehog_every = job.get("hedgehog_every", hedgehog_every)
	squirrel_every = job.get("squirrel_every", squirrel_every)
	if Game.in_run:
		mower.apply_spec(Game.mower_spec())
	_build_layout()

	lawn.cut_changed.connect(func(f: float) -> void:
		$HUD/Percent.text = "%d%%" % floori(f * 100.0)
		customer.on_progress(f))
	mower.fuel_changed.connect(func(f: float) -> void: $HUD/Fuel.value = f)
	$HUD/Fuel.stamina = mower.power == "stamina"
	$HUD/Face.set_look(job.look)
	hud.choice.connect(_on_choice)
	$Truck/RefuelZone.body_entered.connect(func(b: Node2D) -> void: if b == mower: _at_truck = true)
	$Truck/RefuelZone.body_exited.connect(func(b: Node2D) -> void: if b == mower: _at_truck = false)

	# Keep the camera inside the lawn so nothing beyond its edge is ever shown.
	var cam: Camera2D = $Mower/Camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = lawn.size_px.x
	cam.limit_bottom = lawn.size_px.y

	if Game.in_run:
		get_tree().paused = true
		hud.open(job.customer, job.brief + ["", "Mow the lawn. Hand in at your truck when you're happy."],
			[["start", "Let's go"]], job.look, "neutral")


## Lay out the garden: house along the top, driveway and truck bottom-left, then
## trees and flowerbeds. The default job keeps the slice's hand-placed layout.
func _build_layout() -> void:
	var size: Vector2i = job.size
	lawn.size_px = size
	lawn.setup()
	var fixed: bool = job.get("fixed_layout", false)

	var house: Node2D = HouseScript.new()
	house.name = "House"
	house.position = Vector2(size.x * 0.5 - house.size.x * 0.5, 0)
	$Scenery.add_child(house)
	$Client.position = house.patio_point()
	$Client.watch = mower
	$Client.set_look(job.look)

	var drive: Control = $Driveway
	drive.position = Vector2(0, size.y - 180)
	$Truck.position = Vector2(110, size.y - 90)
	mower.position = Vector2(230, size.y - 90)
	$Truck/Trailer.visible = Game.in_run and "rideon" in Game.owned

	var taken: Array[Rect2] = [house.rect().grow(50), Rect2(drive.position, drive.size).grow(70)]
	var trees: Array = []
	var beds: Array = []
	if fixed:
		trees = [[Vector2(900, 420), 34.0]]
		beds = [Rect2(360, 300, 200, 80)]
	else:
		var r := RandomNumberGenerator.new()
		r.seed = job.seed
		for i in job.beds:
			var br := _place(r, taken, Vector2(r.randf_range(140, 240), r.randf_range(64, 96)), size)
			if br.has_area():
				beds.append(br)
		for i in job.trees:
			var rad: float = [26.0, 34.0, 42.0][r.randi() % 3] # matches the canopy art sizes
			var tr := _place(r, taken, Vector2(rad, rad) * 2.0, size)
			if tr.has_area():
				trees.append([tr.get_center(), rad])

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
	lawn.exclude_rect(house.rect())
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


func _physics_process(delta: float) -> void:
	if over:
		return
	customer.tick(delta)
	hud.set_clock(customer.elapsed)
	$HUD/Face.expression = customer.face()
	if customer.fired:
		_finish(customer.fired_result(_fuel_cost()))
		return
	hud.set_hint("[E] Talk to the customer / leave" if _at_truck else "")

	_next_hedgehog -= delta
	_next_squirrel -= delta
	if _next_hedgehog <= 0.0:
		_next_hedgehog = hedgehog_every * randf_range(0.6, 1.4)
		spawn_animal("hedgehog")
	if _next_squirrel <= 0.0:
		_next_squirrel = squirrel_every * randf_range(0.6, 1.4)
		spawn_animal("squirrel")


func _unhandled_input(event: InputEvent) -> void:
	if over or hud.is_open():
		return
	if event.is_action_pressed("interact") and _at_truck:
		open_truck_menu()
	elif event.is_action_pressed("pause"):
		get_tree().paused = true
		hud.open("Paused", [], [["resume", "Resume"], ["quit", "Quit to title"]])


func open_truck_menu() -> void:
	get_tree().paused = true
	hud.open("At the truck", ["Mowed: %d%%" % floori(lawn.cut_fraction() * 100.0)],
		[["handin", "Ask to be paid"], ["leave", "Drive off (no pay)"], ["resume", "Keep mowing"]])


func _on_choice(id: String) -> void:
	match id:
		"start", "resume":
			hud.close()
			get_tree().paused = false
		"handin":
			hand_in()
		"leave":
			_finish(customer.walked_result(_fuel_cost()))
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
		hud.say(customer.last_line)
		$Client.react()
		hud.close()
		get_tree().paused = false
		return
	_finish(customer.evaluate(cov, _fuel_cost()))


func _finish(result: Dictionary) -> void:
	over = true
	get_tree().paused = true
	Game.record_result(result)
	var lines := []
	match result.outcome:
		"fired":
			lines = ["\"%s\"" % result.comment, "", "No pay.", "Reputation took a big hit."]
		"walked":
			lines = ["\"%s\"" % result.comment, "", "You drove off without being paid.", "Word gets around."]
		_:
			lines = ["\"%s\"" % result.comment, "",
				"Mowed: %d%%" % floori(result.coverage * 100.0),
				"Time: %d:%02d" % [floori(result.elapsed / 60.0), int(result.elapsed) % 60],
				"Paid: $%d%s" % [result.paid, ("  (includes $%d tip!)" % result.tip) if result.tip > 0 else ""]]
	if result.fuel_cost > 0.0:
		lines.append("Fuel: -$%d" % roundi(result.fuel_cost))
	if Game.in_run:
		lines.append("")
		lines.append("Money: $%d    Reputation: %s" % [Game.money, _rep_word(Game.reputation)])
	var title: String = {"fired": "FIRED!", "walked": "You left"}.get(result.outcome, "Job done")
	hud.open(title, lines, [["continue", "Continue"]], job.look, customer.face() if result.outcome != "walked" else "furious")


func _rep_word(rep: float) -> String:
	if rep >= 80.0: return "Stellar"
	if rep >= 60.0: return "Good"
	if rep >= 40.0: return "Fair"
	if rep >= 20.0: return "Shaky"
	return "Dire"


func _fuel_cost() -> float:
	var price: float = Game.mower_spec().fuel_price if Game.in_run else 0.25
	return mower.fuel_used * price


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
	customer.on_squash(a.kind)
	hud.say(customer.last_line)
	$Client.react()


func _on_trampled(_flat: int, _total: int) -> void:
	var total := 0
	for b in $Scenery.get_children():
		if b.has_method("flattened_count"):
			total += b.flattened_count()
	if customer.on_flowers(total):
		hud.say(customer.last_line)
		$Client.react()
