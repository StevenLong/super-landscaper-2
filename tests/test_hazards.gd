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
var _thrown: FlyingStone
var _bills0 := 0.0
var _bounced := Vector2.ZERO


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
			var turned: float = mower.rotation
			mower.rotation = -PI / 2.0
			mower._fit_shape()
			var pts: PackedVector2Array = mower.get_node("Shape").shape.points
			assert(is_equal_approx(absf(pts[0].y), mower.body.x * 0.3), "heading north, the mower's footprint is foreshortened")
			mower.rotation = turned
			mower._fit_shape()
			assert(mower.condition < 100.0, "and hurts the mower")
			# What a flung stone can hit.
			var house: Node2D = m.get_node("Scenery/House")
			assert(m._stone_hit_test(m.get_node("Client").position + Vector2(0, -14)) == "customer", "stone hits the customer")
			assert(m._stone_hit_test(house.position + Vector2(55, house.WALL_H - 26.0)) == "window", "stone hits a window")
			assert(m._stone_hit_test(house.position + Vector2(95, house.WALL_H - 26.0)) == "wall", "stone hits the wall between windows")
			assert(m._stone_hit_test(m.get_node("Truck").position) == "truck", "stone dents the truck")
			assert(m._stone_hit_test(Vector2(-5, 300)) == "gone", "stone over the fence")
			assert(m._stone_hit_test(Vector2(640, 600)) == "", "stone lands on grass")
			# A pond is flat: a stone flies over it, and only one landing in it splashes.
			var pond := Pond.new()
			pond.position = Vector2(640, 600) # clear grass, as above
			m.get_node("Scenery").add_child(pond)
			assert(m._stone_hit_test(pond.position) == "", "a stone in the air passes over a pond")
			var kids := m.get_child_count()
			var drop := FlyingStone.new()
			drop.position = pond.position
			m._on_stone_landed(drop, "")
			assert(m._stone_near(pond.position) == null, "a stone landing in a pond sinks")
			assert(m.get_child_count() == kids + 1, "and splashes")
			var mid: Array = pond.splash_fit(pond.position)
			assert(mid[1] == 1.0, "a splash mid-pond is full size")
			var rim: Array = pond.splash_fit(pond.position + Vector2(60, 0)) # on the rim stones
			assert((rim[0] as Vector2).x - pond.position.x + 26.0 * rim[1] <= Pond.WATER_RX, "a splash at the edge keeps its rings on the water")
			drop.free()
			pond.free()
			var f := FlyingStone.new()
			f.position = house.position + Vector2(55, house.WALL_H - 26.0)
			var mood: float = m.customer.mood
			m._on_stone_landed(f, "window")
			assert(m.bills >= m.WINDOW_BILL and m.customer.mood < mood, "a broken window costs money and mood")
			assert(house.broken == [40], "and stays smashed")
			# A stone that hits a wall bounces back off it and lands.
			f.position = house.position + Vector2(95, house.WALL_H - 26.0)
			f.velocity = Vector2.UP * 400.0
			m._on_stone_landed(f, "wall")
			_bounced = f.position + Vector2(0, 12)
			f.free()
			# A broken mower cuts nothing; parking at the truck repairs it.
			mower.condition = 0.0
			mower.global_position = Vector2(640, 420)
			_cut0 = lawn.cut_fraction()
			Input.action_press("move_forward")
			_wait = 30
		2:
			Input.action_release("move_forward")
			assert(m._stone_near(_bounced) != null, "a stone off a wall drops in front of it")
			assert(lawn.cut_fraction() == _cut0, "a broken mower cuts nothing")
			mower.global_position = m.truck_spot()
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
			m.walker.global_position = m.truck_spot()
			_wait = 3
		5:
			assert(m.at_truck(), "walked to the truck")
			# On foot, a stone can hit your own parked mower, and one landing in a bed flattens flowers.
			assert(m._stone_hit_test(mower.global_position) == "mower", "a stone hits your parked mower")
			var cond: float = mower.condition
			var hit := FlyingStone.new()
			hit.position = mower.global_position
			m._on_stone_landed(hit, "mower")
			assert(mower.condition < cond, "and dents it")
			var bed: Node2D = m.get_node("Scenery/Flowerbed")
			var flat0: int = bed.flattened_count()
			hit.position = bed.rect().get_center()
			m._on_stone_landed(hit, "")
			assert(bed.flattened_count() > flat0, "a stone landing in a flower bed flattens flowers")
			var quiet: int = m._flowers_quiet_until
			assert(quiet > Time.get_ticks_msec(), "the customer screamed about the flowers")
			var counted: int = m.customer.flowers_flat
			bed._trample(bed.to_local(bed.rect().position + Vector2(6, 6)), 12.0) # more flowers, straight after
			assert(m.customer.flowers_flat > counted and m._flowers_quiet_until == quiet, "counted, but no second scream straight away")
			hit.free()
			# Throwing: pick up a stone and lob it at a window.
			var house: Node2D = m.get_node("Scenery/House")
			var bills_before: float = m.bills
			var f: FlyingStone = m.throw_stone(house.position + Vector2(55, house.WALL_H + 94.0), Vector2.UP, 460.0, 300.0)
			_thrown = f
			_bills0 = bills_before
			_wait = 30
			_step += 1
			return false
		6:
			assert(not is_instance_valid(_thrown), "the thrown stone landed")
			assert(m.bills > _bills0, "a stone thrown at a window breaks it")
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
		7:
			assert(m.dog.following == m.walker, "the dog follows you once you catch it")
			assert(m._hint().begins_with("Walk Biscuit back"), "and the hint says where to take them")
			_mood = m.customer.mood
			m.walker.global_position = m.get_node("Client").position + Vector2(0, 30)
			_wait = 180 # the dog has a way to run
		8:
			assert(not is_instance_valid(m.dog) or m.dog.is_queued_for_deletion(), "the dog went home")
			assert(m.customer.mood > _mood, "and the owner is grateful")
			m.hop_on()
			assert(mower.occupied and m.walker == null and m.cam.get_parent() == mower, "back on the mower")
			# Driving into the customer on the patio knocks them out.
			mower.global_position = m.get_node("Client").position + Vector2(-60, -8)
			mower.rotation = 0.0
			Input.action_press("move_forward")
			_wait = 40
		9:
			Input.action_release("move_forward")
			assert(m.customer.knocked_out, "the mower flattens the customer")
			assert(m.customer.face() == "ko", "their face says so")
			m._on_choice("leave_ko")
			assert(m.over and root.get_node("Game").last_result.outcome == "ko", "leaving afterwards is a knockout result")
			print("PASS hazards")
			quit()
	_step += 1
	return false

