# Seen versus evidence: indoors the customer sees nothing, and what they missed is judged
# by what's left when they come out; noise brings them out at once; a window sees it all,
# and a stone through their window hits them. No witness, no police call.
extends SceneTree

var m: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	var job: Dictionary = root.get_node("Game").default_job()
	var c := Customer.new(job)
	c.where = "inside"
	var mood := c.mood
	assert(not c.sees() and not c.on_squash("hedgehog") and c.mood == mood, "indoors, a squashed hedgehog goes unseen")
	assert(not c.on_flowers(1) and c.mood == mood, "and so do flowers")
	assert(not c.on_stone("wall") and c.where == "inside", "a thud on the wall doesn't bring them out")
	assert(c.come_out() and c.mood < mood and c.face() == "horrified", "out on the patio, the evidence lands")
	assert(c.last_line.contains("the hedgehog") and c.last_line.contains("my flowers"), "itemised: %s" % c.last_line)
	assert(not c.come_out(), "and only once")

	c = Customer.new(job)
	c.where = "inside"
	mood = c.mood
	c.on_stone("window")
	assert(c.where == "patio" and c.mood < mood, "breaking glass brings them straight out, and they see it")

	c = Customer.new(job.merged({"persona": "squirrel_hater"}, true))
	c.where = "inside"
	c.on_squash("squirrel")
	c.come_out()
	assert(c.face() == "laughing", "the squirrel hater is delighted to find one flattened")

	c = Customer.new(job.merged({"indoors": 1.0}, true))
	c.tick(36.0)
	assert(c.where != "patio", "a stay-at-home customer goes in when their stint on the patio ends")

	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			m.customer.where = "window"
			m.customer.window_x = 40
			_wait = 2
		1:
			var house: Node2D = m.get_node("Scenery/House")
			assert(not m.get_node("Client").visible and house.peek_x == 40, "at a window: off the patio, their head at the glass")
			assert(m.get_node("HUD/Face").view == "window", "the portrait shows the pane")
			assert(m._stone_hit_test(m.get_node("Client").position + Vector2(0, -14)) != "customer", "nobody on the patio to hit")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			f.thrown = true
			var mood: float = m.customer.mood
			m._on_stone_landed(f, "window")
			f.free()
			assert(m.tally.get("customer_hits", 0) == 1 and m.customer.mood <= mood - 35.0, "a stone through their window hits them")
			# No witness, no police call, even at high heat. (Wake them if that stone knocked them out.)
			m.customer.knocked_out = false
			m.customer.where = "inside"
			m._heat0 = 5.0
			m.police_left = -1.0
			m._crime(1)
			assert(m.police_left < 0.0, "unseen, nobody calls the police")
			m.customer.where = "patio"
			m._crime(1)
			assert(m.police_left > 0.0, "seen at high heat, they do")
			print("PASS seen")
			quit()
	_step += 1
	return false
