extends SceneTree
# Screenshots of your own places for eyeballing their layout (hub.gd): the office, the yard
# with a van, a helper and kit on its floor and one with no van stood by, their cards, the shop
# and a card of its stock.
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
	g.money = 3000
	g.buy("petrol")
	g.buy("rideon")
	g.buy("robot")
	g.buy("van")
	g.hire(g.wanted[0])
	g.buy("crew_petrol")
	g.set_kit(g.helpers[0].id, "petrol")
	g.buy("van")
	g.wanted.append({"id": 77, "name": "Agnes Crumb", "pace": 0.7, "care": 0.5, "wage": 80, "rep": 50.0})
	g.hire(g.wanted[-1]) # no van left: she waits in the yard
	g.place = "office"
	g.spot = "desk"
	change_scene_to_file("res://hub.tscn")
func _process(_d: float) -> bool:
	f += 1
	var h := current_scene
	if f == 20:
		root.get_texture().get_image().save_png(out + "/hub_office.png")
		g.place = "yard"
		g.spot = "office_door"
		change_scene_to_file("res://hub.tscn")
	if f == 40:
		root.get_texture().get_image().save_png(out + "/hub_yard.png")
		h.use("look in")
	if f == 46:
		root.get_texture().get_image().save_png(out + "/hub_van_card.png")
		h._close_card()
		h.use("talk to")
	if f == 50:
		root.get_texture().get_image().save_png(out + "/hub_standing_card.png")
		g.place = "shop"
		g.spot = "door"
		change_scene_to_file("res://hub.tscn")
	if f == 66:
		root.get_texture().get_image().save_png(out + "/hub_shop.png")
		h.use("look at the ride-on")
	if f == 72:
		root.get_texture().get_image().save_png(out + "/hub_shop_card.png")
		quit()
	return false
