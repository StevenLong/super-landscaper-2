# Spawn tells: a critter's hedge, fence or tree rustles for a moment before it comes out.
extends SceneTree

var m: Node
var _frame := 0
var _before := 0
var _at := Vector2.ZERO


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_before = m.get_node("Animals").get_child_count()
		m._next_hedgehog = 0.0
	elif _frame == 4:
		assert(m._tells.size() == 1, "a hedgehog is on its way")
		assert(m.get_node("Animals").get_child_count() == _before, "but not out yet: the hedge rustles first")
		_at = m._tells[0].at
	elif _frame == 4 + int(m.TELL * 60.0) + 5:
		assert(m._tells.is_empty(), "the tell is over")
		var kids: Array = m.get_node("Animals").get_children()
		assert(kids.size() == _before + 1, "and the hedgehog is out")
		assert(kids.back().kind == "hedgehog", "a hedgehog")
		assert((kids.back() as Node2D).position.distance_to(_at) < 30.0, "where the rustle was")
		print("PASS tells")
		quit()
	return false
