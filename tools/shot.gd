extends SceneTree
# Screenshots of the default job for eyeballing art: at the truck (trailer on), by the
# house (one window smashed), by the tree, behind the front hedge, and the whole garden. Not a test. Needs a window:
# SHOT_DIR=<dir> "$GODOT" --path . --fixed-fps 60 -s tools/shot.gd
var f := 0
var out := OS.get_environment("SHOT_DIR")
func _initialize() -> void:
	change_scene_to_file("res://main.tscn")
func _process(_d: float) -> bool:
	f += 1
	var m := current_scene
	if f == 20:
		paused = false
		m.get_node("HUD").visible = true
		m.get_node("Truck/Trailer").visible = true
	if f == 40:
		root.get_texture().get_image().save_png(out + "/truck.png")
		m.mower.position = Vector2(560, 400)
		m.get_node("Scenery/House").smash(120)
	if f == 70:
		root.get_texture().get_image().save_png(out + "/house.png")
		m.mower.position = Vector2(1000, 420)
	if f == 100:
		root.get_texture().get_image().save_png(out + "/tree.png")
		m.mower.position = Vector2(300, 700)
	if f == 130:
		root.get_texture().get_image().save_png(out + "/edge.png")
		m.cam.zoom = Vector2(0.5, 0.5)
		m.set_process(false)
		m.mower.position = Vector2(640, 420)
	if f == 160:
		root.get_texture().get_image().save_png(out + "/whole.png")
		quit()
	return false
