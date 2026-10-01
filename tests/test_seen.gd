# Seen versus evidence (design doc, The Customer): during the job they only know what they
# see happen, in their line of sight; stepping outside finds nothing; noise brings them out
# and they know. After you've gone they notice what's theirs, and bodies left in view.
# A window sees a cone out of it; a stone through it hits them. No witness, no police call.
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
	assert(not c.on_flowers(3) and c.mood == mood, "and so do flowers")
	assert(not c.on_property("gnome", -15.0) and c.mood == mood, "and a wrecked gnome")
	assert(not c.on_stone("wall") and c.where == "inside", "a thud on the wall doesn't bring them out")
	c.come_out()
	assert(c.where == "patio" and c.mood == mood, "stepping out, they find nothing")
	var found := c.aftermath({}, true)
	assert(found.size() == 3, "after you've gone: %s" % [found])
	assert(found[0][0] == "Their gnome, ruined" and found[0][1] == -3.0, "their gnome, a fifth of its mood in reputation")
	assert(found[1][0] == "3 of their flowers flattened" and found[1][1] < 0.0, "their flowers")
	assert(found[2][0] == "Every blade cut" and found[2][1] > 0.0, "and the good news too")
	assert(not c.on_flowers(3, Vector2.ZERO), "the same flowers aren't news twice")

	c = Customer.new(job)
	c.where = "inside"
	mood = c.mood
	c.on_stone("window")
	assert(c.where == "patio" and c.mood < mood, "breaking glass brings them straight out, and they know")

	c = Customer.new(job)
	c.sight = func(p: Vector2) -> bool: return p.x < 100.0
	assert(c.sees(Vector2(50, 0)) and not c.sees(Vector2(500, 0)), "on the patio, only what's in their line of sight")
	assert(not c.on_squash("hedgehog", 1.0, Vector2(500, 0)), "out of sight, a squash goes unseen")

	c = Customer.new(job.merged({"persona": "squirrel_hater"}, true))
	found = c.aftermath({"squirrel": 2}, false)
	assert(found[0][0] == "2 dead squirrels on the lawn" and found[0][1] > 0.0, "the squirrel hater is pleased to find them")

	c = Customer.new(job.merged({"indoors": 1.0}, true))
	c.tick(36.0)
	assert(c.where != "patio", "a stay-at-home customer goes in when their stint on the patio ends")
	# Indoors they walk to a window, past the others, unseen till they're at it.
	c.where = "inside"
	c._stroll(370, "window")
	c.tick(1.0)
	assert(c.where == "inside" and not c.sees() and c.stroll_x() > c.door_x and c.stroll_x() < 370.0, "on the way, glimpsed between the door and the window")
	c.tick(5.0)
	assert(c.where == "window" and c.window_x == 370 and c.stroll_x() < 0.0, "then at the window")

	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	var house: Node2D = m.get_node("Scenery/House")
	var hidden: Vector2 = house.position + Vector2(500, 60) # behind the garage, past the house
	var open: Vector2 = house.position + Vector2(220, 520) # out on the front lawn
	match _step:
		0:
			assert(m._in_sight(open) and not m._in_sight(hidden), "from the patio: the front lawn, not round the back of the house")
			m.hud.close()
			m.get_tree().paused = false
			m.mower.global_position = hidden
			_wait = 2
		1:
			assert(not m.get_node("HUD/Face").seen and m.get_node("HUD/Face").view == "patio", "out of their sight: unseen, still on the patio")
			m.mower.global_position = open
			m.customer.where = "window"
			m.customer.window_x = 40
			_wait = 70 # they walk in through the door first
		2:
			assert(not m.get_node("Client").visible and house.peek_x == 40, "at a window: off the patio, their head at the glass")
			assert(m.get_node("HUD/Face").view == "window", "the portrait shows the pane")
			var eye: Vector2 = m._window_eye()
			assert(m._in_sight(eye + Vector2(0, 200)) and not m._in_sight(eye + Vector2(600, 40)), "a window sees a cone out in front, not off to the side")
			assert(m._cone_pts.size() > 3, "and the ground it sees is lit, faintly")
			assert(m._stone_hit_test(m.get_node("Client").position + Vector2(0, -14)) != "customer", "nobody on the patio to hit")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			f.thrown = true
			var mood: float = m.customer.mood
			m._on_stone_landed(f, "window")
			f.free()
			assert(m.tally.get("customer_hits", 0) == 1 and m.customer.mood <= mood - 35.0, "a stone through their window hits them")
			# No witness, no police call, even with a long record. (Wake them if that stone knocked them out.)
			m.customer.knocked_out = false
			m.customer.where = "inside"
			m._record0 = 5.0
			m.police_left = -1.0
			m._crime(1)
			assert(m.police_left < 0.0, "unseen, nobody calls the police")
			m.customer.where = "patio"
			m._crime(1, hidden)
			assert(m.police_left < 0.0, "nor out of their sight")
			m._crime(1, open)
			assert(m.police_left > 0.0, "seen with a long record, they do")
			print("PASS seen")
			quit()
	_step += 1
	return false
