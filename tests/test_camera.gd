# The camera starts on you (NOTES 155): under the job's opening briefing (the game paused)
# it shows the mower at the truck, not where the mower stood in the scene file.
extends SceneTree

var m: Node
var _wait := 3


func _initialize() -> void:
	var g: Node = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(2) # this seed's first ad parks the truck far from the scene file's spot
	var ad: Dictionary = g.paper[0]
	g.book(ad)
	g.day = ad.day
	g.start_job(ad)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)


func _process(_delta: float) -> bool:
	_wait -= 1
	if _wait == 0:
		assert(paused and m.hud.is_open(), "the briefing's up, the game paused")
		var off: float = m.cam.get_screen_center_position().distance_to(m.mower.global_position)
		assert(off < 120.0, "the camera's on the mower under the briefing (%d px off)" % off)
		print("PASS camera")
		quit()
	return false
