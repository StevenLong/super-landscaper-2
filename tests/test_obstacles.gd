# Tree and flowerbed in the real main scene: the tree blocks the mower, the flowerbed
# does not but gets flattened, neither counts as lawn, and 100% is reachable with the
# mower's real edge margin and cut radius.
extends SceneTree

var _main: Node
var _mower: CharacterBody2D
var _lawn: Lawn
var _tree: Node2D
var _bed: Node2D
var _frame := 0
var _trampled_signals := 0


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_mower = _main.get_node("Mower")
		_lawn = _main.get_node("Lawn")
		_tree = _main.get_node("Tree")
		_bed = _main.get_node("Flowerbed")
		_bed.trampled.connect(func(_n: int, _t: int) -> void: _trampled_signals += 1)

		# Neither obstacle counts as lawn.
		var f0 := _lawn.cut_fraction()
		_lawn.cut_segment(_tree.global_position, _tree.global_position, _tree.radius * 0.9)
		_lawn.cut_segment(_bed.rect().get_center(), _bed.rect().get_center(), 20.0)
		assert(_lawn.cut_fraction() == f0, "tree and flowerbed cells must not count as lawn")

		# Drive head-on at the tree from its left.
		_mower.global_position = _tree.global_position - Vector2(150, 0)
		_mower.rotation = 0.0
		Input.action_press("move_forward")
	elif _frame == 120:
		Input.action_release("move_forward")
		var gap: float = _tree.global_position.x - _mower.global_position.x
		assert(gap > _tree.radius, "the tree should block the mower, gap %f" % gap)
		assert(gap < _tree.radius + 40.0, "the mower should have reached the tree, gap %f" % gap)

		# Park on the flowerbed.
		_mower.global_position = _bed.rect().get_center()
	elif _frame == 125:
		assert(_bed.flattened_count() > 0, "driving onto the flowerbed should flatten flowers")
		assert(_trampled_signals > 0, "the flowerbed should report trampling")
		_mower.global_position = Vector2(640, 100)
	elif _frame == 130:
		# Every lawn cell is reachable: sweep rows at the mower's clamped extremes.
		var m: float = _mower.edge_margin
		var r: float = _mower.cut_radius
		var ys: Array = range(int(m), int(_lawn.size_px.y - m), 20)
		ys.append(_lawn.size_px.y - m)
		for y: float in ys:
			_lawn.cut_segment(Vector2(m, y), Vector2(_lawn.size_px.x - m, y), r)
		assert(_lawn.cut_fraction() == 1.0, "100%% should be reachable within the edge margin, got %f" % _lawn.cut_fraction())
		print("PASS obstacles")
		quit()
	return false
