# The road-side hedge or fence fades only while you're behind it, in its own height (the dev,
# 2026-10-04: it faded with the mower well clear above it, 40 out).
extends SceneTree

var g: Node
var m: Node
var _frame := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.reputation = 55.0
	g.current_job = g.make_job(18)
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	var strip: TextureRect = m._front[0]
	var x: float = strip.position.x + strip.size.x * 0.5
	if _frame == 5:
		paused = false
		m.mower.global_position = Vector2(x, strip.position.y - 30.0) # clear above it
	elif _frame == 40:
		assert(strip.modulate.a > 0.99, "30 above the fence: not faded (%.2f)" % strip.modulate.a)
		m.mower.global_position = Vector2(x, strip.position.y + 12.0) # behind it
	elif _frame == 80:
		assert(strip.modulate.a < 0.6, "behind it: faded (%.2f)" % strip.modulate.a)
		print("PASS front")
		quit()
	return false
