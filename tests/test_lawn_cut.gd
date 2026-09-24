# Lawn cut-grid logic: counting, no double counting, edges, full coverage.
extends SceneTree


func _initialize() -> void:
	var lawn: Lawn = load("res://lawn.gd").new()
	lawn.setup()
	assert(lawn.cut_fraction() == 0.0, "fresh lawn should be uncut")

	lawn.cut_segment(Vector2(100, 100), Vector2(100, 100), 20.0)
	var once := lawn.cut_fraction()
	assert(once > 0.0, "a stamp should cut something")
	lawn.cut_segment(Vector2(100, 100), Vector2(100, 100), 20.0)
	assert(lawn.cut_fraction() == once, "recutting the same spot must not double count")

	# A stroke cuts a continuous strip even when moved far in one step.
	lawn.cut_segment(Vector2(200, 300), Vector2(1000, 300), 20.0)
	var strip := lawn.cut_fraction() - once
	# 800px long x ~40px wide, in 4px cells: about 200 x 10 = 2000 cells of 57600.
	assert(strip > 1900.0 / 57600.0 and strip < 2300.0 / 57600.0, "strip area off: %f" % strip)

	# Stamping partly off the lawn is clipped, not a crash.
	lawn.cut_segment(Vector2(-10, -10), Vector2(-10, -10), 30.0)

	# Sweeping every row cuts everything.
	for y in range(0, 720, 20):
		lawn.cut_segment(Vector2(0, y), Vector2(1280, y), 20.0)
	assert(lawn.cut_fraction() == 1.0, "full sweep should reach 100%%, got %f" % lawn.cut_fraction())

	# Excluded cells leave the total: cells already cut inside the rect stop counting,
	# and the rest of the lawn can still reach 100%.
	var lawn2: Lawn = load("res://lawn.gd").new()
	lawn2.setup()
	lawn2.cut_segment(Vector2(40, 40), Vector2(40, 40), 20.0)
	lawn2.exclude_rect(Rect2(0, 0, 200, 200))
	assert(lawn2.cut_fraction() == 0.0, "cut cells inside an excluded rect should stop counting")
	for y in range(0, 720, 20):
		lawn2.cut_segment(Vector2(0, y), Vector2(1280, y), 20.0)
	assert(lawn2.cut_fraction() == 1.0, "excluded cells must not block 100%%, got %f" % lawn2.cut_fraction())

	lawn.free()
	lawn2.free()
	print("PASS lawn cut grid")
	quit()
