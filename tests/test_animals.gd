# Animals in the real main scene: they cross the lawn, a moving mower squashes them
# and the hit is counted, and a stopped mower turns them back instead.
extends SceneTree

var _main: Node
var _mower: CharacterBody2D
var _frame := 0
var _walker: Animal
var _victim: Animal
var _bouncer: Animal
var _walker_start: Vector2


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	_main.hedgehog_every = 9999.0 # no random spawns; the test places its own
	_main.squirrel_every = 9999.0
	root.add_child(_main)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_mower = _main.get_node("Mower")
		_mower.global_position = Vector2(640, 600)
		_walker = _main.spawn_animal("hedgehog", Vector2(100, 100), Vector2(1200, 100))
		_walker_start = _walker.global_position
		# A hedgehog walking into a stopped mower's side.
		_bouncer = _main.spawn_animal("hedgehog", Vector2(640, 560), Vector2(640, 700))
	elif _frame == 90:
		assert(_walker.global_position.x > _walker_start.x + 40.0, "hedgehogs should walk across the lawn")
		assert(not _bouncer.dead, "a stopped mower must not squash anything")
		assert(_bouncer.heading.y < 0.0, "a hedgehog meeting a stopped mower should turn back")
		# Drive at a hedgehog.
		_mower.global_position = Vector2(300, 400)
		_mower.rotation = 0.0
		_victim = _main.spawn_animal("hedgehog", Vector2(420, 400), Vector2(420, 401))
		_victim.speed = 0.0
		Input.action_press("move_forward")
	elif _frame == 180:
		Input.action_release("move_forward")
		assert(_victim.dead, "a moving mower should squash a hedgehog")
		assert(_main.hits.get("hedgehog", 0) == 1, "the squash should be counted once")
		print("PASS animals")
		quit()
	return false
