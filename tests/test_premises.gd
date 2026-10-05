# Your premises (design doc, The hub, redesigned; NOTES 249): the lock-up you start in holds
# the truck, the push mower and about one more; no room is no sale, and "as things stand"
# when shifting would make room; things set down by hand where they're clear (never on the
# truck's bay), turned or not; selling one keeps the others where they stood; moving up
# costs a deposit and rent on Friday's bill, never down; hiring needs a staff room, its seats
# the cap, a breakroom in the warehouse; the shark offers the next deposit once you're
# free of him and outgrown the place (no room for another petrol mower, or from the unit
# up another van), and taking it moves you; old saves land in premises their things
# fit, a staff room if they've a crew.
extends SceneTree

var g: Node


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	g.money = 50000
	assert(g.premises == 0 and g.floor_size() == Vector2i(11, 5) and g.living() == g.LIVING, "a lock-up, rent and food as ever")
	assert(g.cant_hire() != "" and g.cant_buy("staff") == "No room for one here", "no staff in a lock-up")
	assert(g.buy("petrol"), "a petrol mower fits")
	assert(g.cant_buy("rideon") == "No room" and not g.buy("rideon"), "a ride-on doesn't: no room, no sale")
	_placed_apart()

	# Set down by hand: where it's clear, never on the bay; turned.
	var petrol := {"kind": "petrol", "n": 0}
	var push := {"kind": "push", "n": 0}
	assert(not g.put_down(petrol, g.bay().position, false), "not on the truck's bay")
	assert(not g.put_down(petrol, g.spots[g.spot_key(push)].at, false), "not on the push mower")
	assert(not g.put_down(petrol, Vector2i(-1, 0), false), "not off the floor")
	assert(g.put_down(petrol, Vector2i(0, 0), true) and g.spots[g.spot_key(petrol)] == {"at": Vector2i.ZERO, "turned": true},
		"turned on its side, where it's clear")
	_placed_apart()

	# Moving up: never down, the deposit, the rent.
	assert(g.cant_move(0) == "No", "never down")
	var money: int = g.money
	assert(g.move_to(1) and g.premises == 1 and g.money == money - g.PREMISES[1].deposit, "the unit, the deposit paid")
	assert(g.living() == g.LIVING + g.PREMISES[1].rent and g.due() >= g.living(), "and its rent on Friday's bill")
	_placed_apart()
	# Room as things stand: a floor with room in all, but not in one piece where it's wanted.
	assert(g.buy("rideon") and g.buy("van"), "a ride-on and a van fit the unit")
	g.spots = {}
	var n := 0
	while g.cant_buy("petrol") == "":
		g.buy("petrol")
		n += 1
		assert(n < 30, "the unit fills")
	_placed_apart()
	var why: String = g.cant_buy("van")
	assert(why == "No room" or why.begins_with("No space as things stand"), "full up: %s" % why)
	# Sold from its card: the rest stay where they stood.
	var count: int = g.total("petrol")
	var last: Dictionary = g.spots["petrol:%d" % (count - 1)].duplicate()
	g.sell_at("petrol", 0)
	assert(g.total("petrol") == count - 1 and g.spots["petrol:%d" % (count - 2)] == last and not g.spots.has("petrol:%d" % (count - 1)),
		"one sold: the others keep their places")
	_placed_apart()
	for i in g.total("petrol"):
		g.sell("petrol")

	# Hiring needs a staff room, its seats the cap.
	assert(g.cant_hire().begins_with("nowhere") and g.hire({"id": 1, "name": "A B", "pace": 0.7, "care": 0.5, "wage": 80}) == "" and g.helpers.is_empty(),
		"no staff room: nobody taken on")
	assert(g.staff_next() == "corner" and g.buy("staff") and g.staff_room == "corner" and g.seats() == 2, "a staff corner: two seats")
	_placed_apart()
	for i in 2:
		g.hire({"id": 10 + i, "name": "C D", "pace": 0.7, "care": 0.5, "wage": 80})
	assert(g.helpers.size() == 2 and g.cant_hire().begins_with("the staff room's full"), "two taken on, then full")
	assert(g.staff_next() == "" and g.cant_buy("staff") == "You've got one", "the unit takes a corner, no more")
	assert(g.move_to(2) and g.staff_room == "corner" and g.staff_next() == "breakroom", "it comes with you; the warehouse takes a breakroom")
	assert(g.buy("staff") and g.staff_room == "breakroom" and g.seats() == 6 and g.cant_hire() == "", "a breakroom: six seats")
	_placed_apart()

	# The shark's offer: free of him, and full up, his man offers the next deposit; taking it moves you.
	g.new_run(7)
	g.money = 5000
	g.principal = 0
	g.buy("petrol")
	assert(g.outgrown(), "the lock-up's full: no room for another petrol mower")
	g.payday_pending = true
	g.settle_payday()
	assert(g.shark_offer, "his man has a word")
	money = g.money
	assert(g.take_shark_offer() and g.premises == 1 and g.principal == g.PREMISES[1].deposit and g.money == money and not g.shark_offer,
		"taken: the unit, on his money, owed at his vig")
	g.principal = 1000
	g.payday_pending = true
	g.money = 5000
	g.settle_payday()
	assert(not g.shark_offer, "owing him: no offer")

	# The winter's keep pays the rent too.
	g.money = 100000
	var cost: Dictionary = g.settle_winter()
	assert(cost.cost == g.living() * g.WINTER_WEEKS, "the winter: rent and food, the unit's rent with it")

	# An old save: the smallest premises its things fit, a staff room for its crew.
	g.save()
	var f := FileAccess.open(g.business_path(), FileAccess.READ)
	var state: Dictionary = f.get_var()
	f.close()
	for k: String in ["premises", "staff_room", "spots", "shark_offer"]:
		state.erase(k)
	state.yard_rows = 12
	state.vans = 1
	state.helpers = [{"id": 5, "name": "E F", "pace": 0.7, "care": 0.5, "wage": 80, "jobs": 0, "happy": 70.0}]
	f = FileAccess.open(g.business_path(), FileAccess.WRITE)
	f.store_var(state)
	f.close()
	g.load_business()
	assert(g.premises == 1 and g.staff_room == "corner" and g.yard_layout().over.is_empty(), "an old save with a van and a helper: the unit, a staff corner")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
	print("PASS premises")
	quit()


## Everything on the floor, off the bay, nothing on top of anything.
func _placed_apart() -> void:
	var lay: Dictionary = g.yard_layout()
	assert(lay.over.is_empty(), "everything placed: %s" % [lay.over])
	for a: Dictionary in lay.placed:
		var ra := Rect2i(a.at, a.size)
		assert(Rect2i(Vector2i.ZERO, g.floor_size()).encloses(ra) and not ra.intersects(g.bay()), "%s on the floor, off the bay" % a.item.kind)
		for b: Dictionary in lay.placed:
			assert(a == b or not ra.intersects(Rect2i(b.at, b.size)), "nothing on top of anything")
