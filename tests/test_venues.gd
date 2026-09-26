# Venues by reputation band: high reputation brings mansions (the toff, a loop drive,
# dear windows and urns), low brings the churchyard (the vicar, headstones, flowers on
# the graves, no car). Ordinary suburban jobs never get a venue's customer.
extends SceneTree

var g: Node
var _step := 0
var _wait := 0
var m: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"


func _find(rep: float, venue: String) -> Dictionary:
	g.reputation = rep
	for s in range(1, 400):
		var j: Dictionary = g.make_job(s)
		if j.get("venue", "house") == venue:
			return j
	return {}


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			g.reputation = 50.0
			for s in range(1, 100):
				var j: Dictionary = g.make_job(s)
				assert(not j.has("venue") and j.persona in g.SUBURBAN, "a middling reputation gets suburban gardens only")
			var mansion := _find(90.0, "mansion")
			assert(mansion.persona == "toff" and mansion.props.has("urn"), "a top-band mansion: the toff, urns on the lawn")
			assert(_find(10.0, "mansion").is_empty(), "no mansions at the bottom")
			assert(g.ad_text(mansion).contains("Country estate"), "the ad says so")
			g.current_job = mansion
			m = load("res://main.tscn").instantiate()
			m.hedgehog_every = 9999.0
			m.squirrel_every = 9999.0
			root.add_child(m)
			_wait = 2
		1:
			var house: Node2D = m.get_node("Scenery/House")
			assert(house.venue == "mansion" and house.windows().size() == 6, "the mansion's building")
			assert(m.get_node_or_null("Scenery/LoopDrive") != null, "a loop drive")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			var bills: float = m.bills
			m._on_stone_landed(f, "window")
			f.free()
			assert(m.bills == bills + m.WINDOW_BILL * 3.0, "a mansion window costs three times as much")
			var urn: Stone = m.add_stone(Vector2(900, 900), "urn")
			bills = m.bills
			m._on_stone_mowed(urn, m.mower)
			assert(m.bills == bills + Stone.KINDS.urn.bill, "a mowed urn is billed")
			m.queue_free()
			var yard := _find(10.0, "graveyard")
			assert(yard.persona == "vicar" and not yard.dog, "a bottom-band churchyard: the vicar, no dog")
			g.current_job = yard
			m = load("res://main.tscn").instantiate()
			m.hedgehog_every = 9999.0
			m.squirrel_every = 9999.0
			root.add_child(m)
			_wait = 2
		2:
			var graves: Array = m.get_node("Scenery").get_children().filter(func(n: Node) -> bool: return "art" in n and n.art == "gravestone")
			assert(graves.size() > 5, "rows of headstones")
			assert(m._stone_hit_test(graves[0].position) == "rock", "solid: stones bounce off them")
			assert(m._car == null, "nobody parks at the church")
			assert(m.get_node("Scenery/House").venue == "graveyard", "the church stands where the house would")
			g.current_job = {}
			print("PASS venues")
			quit()
	_step += 1
	return false
