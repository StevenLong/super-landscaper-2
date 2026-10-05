extends SceneTree
# Screenshots of your own places for eyeballing their layout (hub.gd): the lock-up you start
# in, the unit (a staff corner, two helpers, vans and mowers), the warehouse (a breakroom),
# something picked up to move, a helper's card, the phone's card, the planner, and the shop.
# Not a test. Needs a window:
# SHOT_DIR=<dir> "$GODOT" --path . --fixed-fps 60 -s tools/shot_hub.gd
var f := 0
var g: Node
var out := OS.get_environment("SHOT_DIR")


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://shot_best.cfg"
	g.start_month = 6
	g.new_run(11)
	g.money = 20000
	g.buy("petrol")
	g.mark_mine("petrol", true)
	g.place = "home"
	g.spot = "desk"
	change_scene_to_file("res://hub.tscn")


func _process(_d: float) -> bool:
	f += 1
	var h := current_scene
	if f == 20:
		_shot("hub_lockup")
		g.move_to(1)
		g.buy("rideon")
		g.buy("staff")
		g.buy("van")
		g.buy("van")
		g.wanted.assign([{"id": 76, "name": "Derek Hedges", "pace": 0.8, "care": 0.4, "wage": 470, "rep": 50.0},
			{"id": 77, "name": "Agnes Crumb", "pace": 0.7, "care": 0.5, "wage": 380, "rep": 50.0}])
		g.hire(g.wanted[0])
		g.hire(g.wanted[0])
		g.spot = "truck"
		change_scene_to_file("res://hub.tscn")
	if f == 40:
		_shot("hub_unit")
		h.use("talk to")
	if f == 44:
		_shot("hub_helper_card")
		h._close_card()
		h.use("look at the van")
		h._card.find_child("Card", true, false)
		for b: Button in h._card.find_children("*", "Button", true, false):
			if b.text == "Move it":
				b.pressed.emit()
	if f == 48:
		_shot("hub_carrying")
		h._end_carry(true)
	if f == 56:
		h._phone_card()
	if f == 60:
		_shot("hub_phone")
		h._close_card()
		h._planner()
	if f == 66:
		_shot("hub_planner")
		g.money = 20000
		g.move_to(2)
		g.buy("staff")
		g.spot = "desk"
		change_scene_to_file("res://hub.tscn")
	if f == 86:
		_shot("hub_warehouse")
		g.place = "shop"
		g.spot = "door"
		change_scene_to_file("res://hub.tscn")
	if f == 100:
		_shot("hub_shop")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
		quit()
	return false


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
