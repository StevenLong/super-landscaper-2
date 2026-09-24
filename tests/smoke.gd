# Headless smoke test: load the main scene, run it for a few hundred frames, quit.
# Prints PASS on success; run_all.sh treats a missing PASS or any SCRIPT ERROR as failure.
extends SceneTree

const FRAMES := 300
var _frames := 0


func _initialize() -> void:
	var err := change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	if err != OK:
		print("FAIL could not load main scene: ", err)
		quit(1)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= FRAMES:
		print("PASS smoke: main scene ran %d frames" % FRAMES)
		quit(0)
	return false
