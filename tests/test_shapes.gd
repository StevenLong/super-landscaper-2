# Plot shapes by neighbourhood (design doc, Levels): terraces at the bottom of the
# ladder (the house at the road end, a passage down its side, a long garden behind),
# semis in the middle (the house set forward, a back garden, the patio out the back),
# an L at the top (next door's back corner cut in, fenced off, not yours).
extends SceneTree

var g: Node
var m: Node
var _step := 0
var _wait := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"


func _find(rep: float, shape: String) -> Dictionary:
	g.reputation = rep
	for s in range(1, 400):
		var j: Dictionary = g.make_job(s)
		if j.get("shape", "rect") == shape and not j.has("venue"):
			return j
	return {}


func _open(job: Dictionary) -> void:
	g.current_job = job
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	_wait = 2


func _physics_process(_delta: float) -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			assert(not _find(50.0, "rect").is_empty(), "a plain rectangle still turns up")
			assert(_find(50.0, "terrace").is_empty() and _find(50.0, "L").is_empty(), "the middle band gets semis")
			var t := _find(20.0, "terrace")
			assert(t.size == g.TERRACE and g.ad_text(t).contains("terraced"), "the bottom band: a long thin terrace, and the ad says so")
			_open(t)
		1:
			var house: Node2D = m._house
			var h := float(m.lawn.size_px.y)
			assert(house.rect().end.y == h - m.TERRACE_FRONT, "the terrace's house is at the road end")
			assert(house.footprint().position.x >= 0.0 and house.footprint().end.x <= m.lawn.size_px.x, "the house and its passage fill the width")
			var drive: Control = m.get_node("Driveway")
			assert(drive.position.y == house.position.y and drive.position.y + drive.size.y == h, "the passage runs from the back garden to the road")
			assert(drive.size.x == house.GARAGE_W, "wall to fence")
			assert(m._car == null, "no car in the passage")
			var mid := drive.position + drive.size * 0.5
			assert(m.lawn.keep_in(mid, 8.0) == mid and not m._blocked(mid), "you can get down the passage")
			assert(m.get_node("Client").position.y < house.position.y, "the patio's out the back, where the garden is")
			for i in 60:
				var spot: Dictionary = m._spawn_spot("hedgehog")
				assert(not house.rect().grow(4.0).has_point(spot.at + spot.inward * 20.0), "critters never come out of the house's side wall")
			assert(m._stone_hit_test(Vector2(house.rect().get_center().x, house.position.y - 20.0)) == "", "the garden behind the house is open ground")
			m.queue_free()
			_open(_find(50.0, "forward"))
		2:
			var house: Node2D = m._house
			assert(house.position.y > 150.0, "the semi stands forward, with a back garden")
			assert(m.get_node("Client").position.y < house.position.y, "the patio's out the back")
			assert(m.get_node_or_null("BackPatio") != null, "on paving")
			var back: Array = m._edges.filter(func(e: Dictionary) -> bool: return e.from.y == 0.0 and e.to.y == 0.0)
			assert(back.size() == 1 and back[0].from.x == 0.0 and back[0].to.x == m.lawn.size_px.x, "critters come in all along the back fence")
			# A lob onto the back slope of the roof rolls off into the back garden.
			var f := FlyingStone.new()
			f.kind = "stone"
			var top := Vector2(house.rect().get_center().x, house.position.y + 40.0)
			assert(m._stone_hit_test(top, 10.0) == "roof", "the back slope of the roof")
			f.position = top
			m._on_stone_landed(f, "roof")
			f.free()
			_wait = 45
		3:
			var house: Node2D = m._house
			var behind: Array = m.get_node("Stones").get_children().filter(func(s: Node) -> bool:
				return s is Stone and s.position.y < house.position.y and absf(s.position.x - house.rect().get_center().x) < 2.0)
			assert(behind.size() == 1, "and drops into the back garden")
			m.queue_free()
			_open(_find(85.0, "L"))
		4:
			var n: Rect2 = m._notch
			assert(n.has_area() and n.position.y == 0.0, "the top band: next door's back corner cut in")
			var inside := n.get_center()
			assert(not n.has_point(m.lawn.keep_in(inside, 8.0)), "you're kept out of it")
			assert(m._blocked(inside), "so are critters")
			assert(m._stone_hit_test(inside) == "gone" and m._stone_hit_test(inside, 40.0) == "gone", "a stone that lands in it is next door's")
			var edge := Vector2(inside.x, n.end.y - 4.0)
			assert(m._stone_hit_test(edge, 5.0) == "fence", "a low one hits their fence")
			var before: float = m.lawn.cut_fraction()
			m.lawn.cut_segment(inside, inside + Vector2(1, 0), 30.0)
			assert(m.lawn.cut_fraction() == before, "none of it is lawn to mow")
			for c: Node in m.get_node("Scenery").get_children() + m.get_node("Stones").get_children():
				assert(not n.has_point((c as Node2D).position), "nothing of yours stands in it")
			var fences: Array = m._edges.filter(func(e: Dictionary) -> bool: return e.from.y == n.end.y and e.to.y == n.end.y)
			assert(fences.size() == 1, "critters can come over their fence")
			g.current_job = {}
			print("PASS shapes")
			quit()
	_step += 1
	return false
