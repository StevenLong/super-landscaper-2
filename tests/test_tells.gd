# Critters come in from next door (NOTES 138): out of sight past the boundary, walking in;
# a hedge rustles as one pushes through it, either way; one that has been in the garden
# and wanders back out of sight is gone. A squirrel up a tree still shakes it first.
extends SceneTree

var m: Node
var _frame := 0
var _h: Animal
var _rustles := 0
var _step := 0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _rustling() -> int: # _rustle's nodes: drawn leaves, z 3, on the main scene
	return m.get_children().filter(func(c: Node) -> bool: return c is Node2D and c.z_index == 3 and c.get_script() == null and c.get_child_count() == 0).size()


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	if _frame == 2:
		for e: Dictionary in m._edges:
			e.kind = "hedge" # a hedge all round, so the crossing rustles
		for s: Dictionary in m._strips:
			s.kind = "hedge"
		m._next_hedgehog = 0.0
	elif _frame == 5:
		assert(m._tells.is_empty(), "no tell to wait out: it's already on its way")
		var kids: Array = m.get_node("Animals").get_children()
		assert(kids.size() == 1 and kids[0].kind == "hedgehog", "a hedgehog, got %s" % [kids])
		_h = kids[0]
		assert(not m._on_plot(_h.position) and not _h.on_plot and not _h.visited, "out past the boundary, coming in")
		_rustles = _rustling()
	elif _frame > 5 and _step == 0:
		assert(_frame < 900 and is_instance_valid(_h), "it walks in, got %s" % [str(_h.position) if is_instance_valid(_h) else "freed"])
		if _h.on_plot:
			assert(_h.visited, "it's been in the garden now")
			assert(_rustling() > _rustles, "the hedge rustled as it pushed through")
			_h.heading = (_h.position - m.lawn.size_px * 0.5).normalized() # off it goes, the way it came
			_h.speed = 400.0
			_h.blocked = func(_p: Vector2) -> bool: return false
			_step = 1
			_frame = 1000
	elif _step == 1:
		assert(_frame < 1400, "it never left, at %s" % [str(_h.position) if is_instance_valid(_h) else ""])
		if not is_instance_valid(_h):
			print("PASS tells")
			quit()
	return false
