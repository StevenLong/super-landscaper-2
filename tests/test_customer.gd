# Customer mood and pay logic (pure), then the hand-in flow in the real scene.
extends SceneTree

var _main: Node
var _frame := 0


func _initialize() -> void:
	# The Game autoload exists at runtime but its global name isn't known when a -s script compiles.
	var Game: Node = root.get_node("Game")
	var job: Dictionary = Game.default_job() # gardener: flowers are an instant fail at 3
	job.persona = "nature"
	var c := Customer.new(job)
	assert(c.face() == "happy", "a fresh nature lover starts happy, got %s" % c.face())
	c.on_squash("hedgehog")
	assert(c.face() == "horrified", "the nature lover is horrified by a hedgehog")
	assert(c.mood < 60.0, "and it costs mood")
	c.tick(3.0)
	assert(c.face() != "horrified", "reactions wear off")

	var h: Customer = Customer.new(job.merged({"persona": "squirrel_hater"}, true))
	var m0: float = h.mood
	h.on_squash("squirrel")
	assert(h.face() == "laughing" and h.mood > m0, "the squirrel hater enjoys a squashed squirrel")

	var g: Customer = Customer.new(Game.default_job())
	assert(g.on_flowers(1) and not g.fired, "one flower is survivable for the gardener")
	assert(not g.on_flowers(1), "the same flowers are not news twice")
	g.on_flowers(3)
	assert(g.fired, "3 flowers is the gardener's stated instant fail")

	var p: Customer = Customer.new(Game.default_job())
	var mood_before: float = p.mood
	p.tick(p.job.patience + 10.0)
	assert(p.mood < mood_before, "waiting past their patience costs mood")

	var q: Customer = Customer.new(Game.default_job())
	assert(not q.accepts(0.3), "a barely-mowed lawn is sent back")
	assert(q.accepts(0.9), "a well-mowed lawn is accepted")
	var good: Dictionary = q.evaluate(0.95, 0.0)
	var poor: Dictionary = q.evaluate(0.6, 0.0)
	assert(good.paid > poor.paid, "meeting the target pays more")
	assert(good.target_met and not poor.target_met, "target flags")
	q.mood = 90.0
	assert(q.evaluate(0.95, 0.0).tip > 0, "a delighted customer on time with the target met tips")
	q.elapsed = q.job.patience * 3.0
	assert(q.evaluate(0.95, 0.0).tip == 0, "no tip when you're late")
	assert(q.evaluate(0.95, 10.0).net == q.evaluate(0.95, 0.0).net - 10.0, "fuel comes off the net")

	_main = load("res://main.tscn").instantiate()
	_main.hedgehog_every = 9999.0
	_main.squirrel_every = 9999.0
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_main.hand_in()
		assert(not _main.over, "handing in an unmowed lawn gets you sent back")
		var lawn: Lawn = _main.get_node("Lawn")
		for y in range(0, 720, 20):
			lawn.cut_segment(Vector2(0, y), Vector2(1280, y), 20.0)
		_main.hand_in()
		assert(_main.over, "handing in a mowed lawn ends the job")
		assert(root.get_node("Game").last_result.outcome == "paid" and root.get_node("Game").last_result.paid > 0, "and pays")
		assert(paused, "the pay screen pauses the game")
		print("PASS customer")
		quit()
	return false
