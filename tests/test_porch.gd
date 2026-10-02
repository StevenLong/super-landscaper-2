# Running the customer over on their patio: only their feet count. Driving through the
# space their body stands up over (behind them, up the screen) is no knockout.
extends SceneTree

var m: Node
var _frame := 0


func _initialize() -> void:
	var g := root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	var feet: Vector2 = m.get_node("Client").position
	m.customer.where = "patio"
	if _frame < 40: # up through their body, never their feet
		m.mower.global_position = feet + Vector2(0, -20)
		m.mower.velocity = Vector2(120, 0)
		return false
	if _frame == 40:
		assert(not m.customer.knocked_out, "behind their feet, through their body: nothing")
	if _frame < 50:
		m.mower.global_position = feet + Vector2(0, 4)
		m.mower.velocity = Vector2(120, 0)
		return false
	assert(m.customer.knocked_out, "onto their feet: out cold")
	print("PASS porch")
	quit()
	return false
