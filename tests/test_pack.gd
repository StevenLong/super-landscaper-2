# Packing the truck (design doc, Mowers and Equipment): kit is rectangles of cells in the
# bed and the trailer grids, turned to fit; a ride-on only on the trailer, which comes
# with it; new kit packs itself; sold kit leaves the truck. The packing screen's cursor
# picks up, turns, drops and puts back; the job starts on the best mower packed, with the
# cans that were packed.
extends SceneTree

var g: Node
var _frame := 0
var _step := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	assert(g.packed.is_empty() and g.unpacked() == ["can"], "a new business: the push mower in the cab, cans to pack")
	# Shapes and fits.
	assert(g.footprint("petrol", true) == Vector2i(3, 2), "turned on its side")
	assert(g.fits("petrol", "bed", Vector2i(2, 0), false) and not g.fits("petrol", "bed", Vector2i(3, 0), false), "2 x 3 in a 4 x 3 bed: only where it fits")
	assert(not g.fits("can", "trailer", Vector2i.ZERO, false), "no trailer, nothing on it")
	g.money = 2000
	g.premises = 1 # room for a ride-on
	assert(g.buy("petrol") and g.packed_has("petrol"), "a new mower packs itself")
	assert(g.fits("can", "bed", Vector2i(2, 0), false) and not g.fits("can", "bed", Vector2i(0, 0), false), "the mower's cells are taken")
	assert(g.buy("rideon") and "trailer" in g.upgrades, "a ride-on brings a trailer")
	var ride: Dictionary = g.packed.filter(func(p: Dictionary) -> bool: return p.kind == "rideon")[0]
	assert(ride.grid == "trailer" and ride.at == Vector2i.ZERO, "and fills it")
	assert(not g.fits("rideon", "bed", Vector2i.ZERO, false), "a ride-on only goes on the trailer")
	for i in 6:
		g.pack_first("can")
	assert(g.cans_packed() == 6 and not g.pack_first("can"), "the bed's other six cells take six cans, and no more")
	g.sell("trailer")
	assert(not g.packed_has("rideon") and "rideon" in g.unpacked(), "sell the trailer and the ride-on stays home")
	g.sell("petrol")
	assert(not g.packed_has("petrol"), "sold kit leaves the truck")
	g.packed.assign([])
	g.buy("petrol")
	g.upgrades.erase("trailer")
	g.calendar[g.day] = [g.make_job(3)]
	change_scene_to_file("res://pack.tscn")


func game_lost() -> bool:
	return "petrol" not in g.owned and not g.packed_has("petrol")


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame % 10 != 0:
		return false
	var s := current_scene
	match _step:
		0:
			assert(s.name == "Pack", "the packing screen")
			# Lift the petrol mower from the bed's corner, turn it, and drop it lower down.
			s.zone = "bed"
			s.cell = Vector2i.ZERO
			s.act()
			assert(s.held.kind == "petrol" and not g.packed_has("petrol"), "picked up")
			s.turn()
			s.cell = Vector2i(3, 2) # pulled back onto the grid: (1, 1)
			s.act()
			var p: Dictionary = g.packed[0]
			assert(p.turned and p.at == Vector2i(1, 1) and s.held.is_empty(), "turned and dropped where it fits")
			s.cell = Vector2i(1, 1)
			s._move(Vector2i.RIGHT)
			assert(s.zone == "tray", "on a packed item it's one stop: right from its left edge goes past it, off the bed")
			# A can from the tray, dropped on the mower: won't fit; put back, it's gone.
			s.zone = "tray"
			s.row = s._tray().find("can")
			s.act()
			assert(s.held.kind == "can", "a can from the tray")
			s.zone = "bed"
			s.cell = Vector2i(2, 2)
			s.act()
			assert(not s.held.is_empty() and s._say == "Won't fit there.", "not on top of the mower")
			s.cell = Vector2i(0, 0)
			s.act()
			assert(g.cans_packed() == 1, "into the corner")
			# Empty-handed, put back on a packed item: straight off the truck, home.
			s.put_back()
			assert(g.cans_packed() == 1, "put_back alone (driving off calls it) never unpacks")
			s.send_home()
			assert(g.cans_packed() == 0 and s.held.is_empty() and s._say == "Petrol can left at home.", "off the truck, home: %s" % s._say)
			s.zone = "tray" # and on again, for the drive below
			s.row = s._tray().find("can")
			s.act()
			s.zone = "bed"
			s.act()
			assert(g.cans_packed() == 1, "back in the corner")
			# Moving right off the bed with no trailer reaches the tray; the last row drives.
			s.cell = Vector2i(3, 0)
			s._move(Vector2i.RIGHT)
			assert(s.zone == "tray", "on to the tray")
			s.row = s._tray().size() - 1
			var go := InputEventAction.new() # through input, not act(): driving off used to crash there
			go.action = "ui_accept"
			go.pressed = true
			root.push_input(go)
		1:
			assert(current_scene.name == "Main", "off to the job")
			assert(g.equipped == "petrol" and current_scene.mower.sprite_kind == "petrol", "on the best mower packed")
			assert(current_scene.cans == 1, "with the one can packed")
			current_scene._on_choice("start")
			current_scene.hop_off()
			# The truck's reach is its painted bay: small, from the drive's end to the truck, and
			# where the mower parks is in it.
			var t: Node2D = current_scene.get_node("Truck")
			var shape: CollisionShape2D = t.get_node("RefuelZone/Shape")
			var size: Vector2 = (shape.shape as RectangleShape2D).size
			var bay := Rect2(t.position + shape.position - size / 2.0, size)
			assert(size.x <= 110.0 and size.y <= 70.0 and bay.has_point(current_scene.truck_spot()), "a small bay round where you park: %s" % bay)
			current_scene.mower.position = Vector2(200, 200) # well away, so a can isn't poured into it
			current_scene.walker.global_position = current_scene.get_node("Truck").position + Vector2(0, -60)
			current_scene.open_truck_menu()
			current_scene._on_choice("can")
			assert(current_scene.cans == 0 and current_scene.walker.carrying == "jerrycan", "take it out")
		2:
			var m := current_scene
			m.interact() # toss it back
			assert(m.cans == 1, "and back on the truck")
			# Swap at the truck: the push mower out, the petrol one recalled with its fuel.
			m.mower.fuel = 10.0
			m.take_out("push")
			assert(m.walker == null and m.mower.sprite_kind == "push" and m.mower.position == m.truck_spot(), "on the push mower at the kerb")
			m.take_out("petrol")
			assert(m.mower.sprite_kind == "petrol" and m.mower.fuel == 10.0, "the petrol mower back, as full as it was")
			# The police called, the mower out on the lawn, you on foot at the truck: it stays.
			m._call_police()
			m.mower.position = Vector2(400, 300)
			m.hop_off()
			m.walker.global_position = m.get_node("Truck").position + Vector2(0, -60)
		3:
			current_scene._on_choice("leave")
			assert(game_lost(), "fled: the petrol mower left on the lawn is gone")
			assert(g.last_result.left_behind == "Petrol mower", "and the summary says so")
			print("PASS pack")
			quit()
	_step += 1
	return false
