# Stones, mower damage and repair, getting off the mower, the fuel can, the dog,
# and knocking the customer out, all in the real main scene.
extends SceneTree

var m: Node
var mower: CharacterBody2D
var lawn: Lawn
var _frame := 0
var _step := 0
var _wait := 0
var _cut0 := -1.0
var _mood := 0.0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			mower = m.get_node("Mower")
			lawn = m.get_node("Lawn")
			# Mow over a stone: it's gone (flung or broken up) and the mower is hurt.
			mower.global_position = Vector2(640, 500)
			mower.rotation = 0.0
			m.add_stone(Vector2(700, 500))
			Input.action_press("move_forward")
			_wait = 45
		1:
			Input.action_release("move_forward")
			assert(m._stone_near(Vector2(700, 500)) == null, "a mowed-over stone leaves the ground")
			assert(mower.condition < 100.0, "and hurts the mower")
			# What a flung stone can hit.
			var house: Node2D = m.get_node("Scenery/House")
			assert(m._stone_hit_test(m.get_node("Client").position + Vector2(0, -14)) == "customer", "stone hits the customer")
			assert(m._stone_hit_test(house.position + Vector2(55, 80)) == "window", "stone hits a window")
			assert(m._stone_hit_test(house.position + Vector2(95, 80)) == "wall", "stone hits the wall between windows")
			assert(m._stone_hit_test(m.get_node("Truck").position) == "truck", "stone dents the truck")
			assert(m._stone_hit_test(Vector2(-5, 300)) == "gone", "stone over the fence")
			assert(m._stone_hit_test(Vector2(640, 600)) == "", "stone lands on grass")
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, 80)
			var mood: float = m.customer.mood
			m._on_stone_landed(f, "window")
			assert(m.bills >= m.WINDOW_BILL and m.customer.mood < mood, "a broken window costs money and mood")
			f.free()
			# A broken mower cuts nothing; parking at the truck repairs it.
			mower.condition = 0.0
			mower.global_position = Vector2(640, 300)
			_cut0 = lawn.cut_fraction()
			Input.action_press("move_forward")
			_wait = 30
		2:
			Input.action_release("move_forward")
			assert(lawn.cut_fraction() == _cut0, "a broken mower cuts nothing")
			mower.global_position = Vector2(230, 630)
			_wait = 60
		3:
			assert(mower.condition > 10.0 and mower.repaired > 0.0, "the truck repairs the mower (and bills it)")
			# Off the mower: the camera follows you, stones can be carried.
			m.hop_off()
			assert(m.walker != null and not mower.occupied, "hopping off leaves the mower")
			assert(m.cam.get_parent() == m.walker, "the camera follows the player on foot")
			m.walker.global_position = Vector2(500, 400)
			m.add_stone(Vector2(505, 400))
			_wait = 2
		4:
			m.interact()
			assert(m.walker.carrying == "stone", "E picks up a nearby stone")
			m.walker.global_position = Vector2(200, 630)
			_wait = 3
		5:
			assert(m.at_truck(), "walked to the truck")
			var before: int = m.get_node("Stones").get_child_count()
			m.interact()
			assert(m.walker.carrying == "" and m.get_node("Stones").get_child_count() == before, "tossed in the truck, not dropped on the lawn")
			# Fetch the fuel can for a dry mower.
			mower.fuel = 2.0
			m._on_choice("can")
			assert(m.walker.carrying == "jerrycan", "grabbed the can")
			m.walker.global_position = mower.global_position + Vector2(0, 30)
			m.interact()
			assert(mower.fuel == mower.max_fuel, "the can fills the mower")
			# The dog gets out; walk into it and lead it home.
			m.job["dog_name"] = "Biscuit"
			m._release_dog()
			m.dog.position = Vector2(700, 500)
			m.walker.global_position = Vector2(700, 500)
			_wait = 3
		6:
			assert(m.dog.following == m.walker, "the dog follows you once you catch it")
			_mood = m.customer.mood
			m.walker.global_position = m.get_node("Client").position + Vector2(0, 30)
			_wait = 180 # the dog has a way to run
		7:
			assert(not is_instance_valid(m.dog) or m.dog.is_queued_for_deletion(), "the dog went home")
			assert(m.customer.mood > _mood, "and the owner is grateful")
			m.hop_on()
			assert(mower.occupied and m.walker == null and m.cam.get_parent() == mower, "back on the mower")
			# Driving into the customer on the patio knocks them out.
			mower.global_position = m.get_node("Client").position + Vector2(-60, -8)
			mower.rotation = 0.0
			Input.action_press("move_forward")
			_wait = 40
		8:
			Input.action_release("move_forward")
			assert(m.customer.knocked_out, "the mower flattens the customer")
			assert(m.customer.face() == "ko", "their face says so")
			m._on_choice("leave_ko")
			assert(m.over and root.get_node("Game").last_result.outcome == "ko", "leaving afterwards is a knockout result")
			print("PASS hazards")
			quit()
	_step += 1
	return false

