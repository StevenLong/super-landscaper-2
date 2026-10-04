# The clock face in the job's HUD (NOTES 215): shown on a booked job, its hand at the time of
# day (partway round the window if you turned up late), red once you're past the window;
# hidden on a job with no window, the time text back in its place.
extends SceneTree

var m: Node


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)


func _process(_delta: float) -> bool:
	var hud: Node = m.hud
	var job := {"from": 600, "by": 720}
	hud.set_clock(60.0 / _mps(), job) # an hour late
	assert(hud._dial.visible and hud._dial_at == Vector3(660, 600, 720), "an hour into a 10 to 12 window: %s" % [hud._dial_at])
	assert(is_equal_approx(hud._angle(660), hud._angle(0) + TAU * 11.0 / 12.0), "the hand at eleven")
	assert(hud.get_node("Clock").text.begins_with("11"), "the time too: " + hud.get_node("Clock").text)
	var x: float = hud.get_node("Clock").position.x
	hud.set_clock(30.0, {})
	assert(not hud._dial.visible and hud.get_node("Clock").position.x < x, "no window, no face, the time where it was")
	print("PASS dial")
	quit()
	return true


func _mps() -> float:
	return root.get_node("Game").MPS
