extends SceneTree
# FPS probe for the job scene: times frames 60 to 360 of main.tscn (job level 3) and how
# long each frame spends between pre- and post-draw (render plus present). If "present" is
# most of the frame, the cost is outside the game. EMPTY=1 skips the scene for a baseline.
# Not a test. Needs a window: "$GODOT" --path . -s tools/fps.gd [--disable-vsync]
var f := 0
var t0 := 0
var t_pre := 0
var draw := 0


func _initialize() -> void:
	RenderingServer.frame_pre_draw.connect(func(): t_pre = Time.get_ticks_usec())
	RenderingServer.frame_post_draw.connect(func(): if f > 60: draw += Time.get_ticks_usec() - t_pre)


func _process(_d: float) -> bool:
	f += 1
	if f == 1 and OS.get_environment("EMPTY") != "1":
		var game := root.get_node("Game")
		game.current_job = game.make_job(3)
		root.add_child(load("res://main.tscn").instantiate())
		paused = false
	elif f == 60:
		t0 = Time.get_ticks_usec()
	elif f == 360:
		var ms := (Time.get_ticks_usec() - t0) / 300000.0
		print("FPS %.1f (frame %.2f ms, render+present %.2f ms) on %s" % [1000.0 / ms, ms, draw / 300000.0, RenderingServer.get_video_adapter_name()])
		quit()
	return false
