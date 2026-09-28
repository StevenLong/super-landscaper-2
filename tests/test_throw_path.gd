# The aiming line tells the truth (NOTES 113): for throws at the house front at several
# tilts and powers, what the traced path says it hits first is what the stone hits, and
# where. Before, the ring sat where it would land if nothing were in the way.
extends SceneTree

var m: Node


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	m.hedgehog_every = 9999.0
	m.squirrel_every = 9999.0
	root.add_child(m)
	_run.call_deferred()


func _run() -> void:
	await physics_frame
	await physics_frame
	m.hop_off()
	var h: Node2D = m._house
	var foot: float = h.position.y + h.WALL_H
	var seen := {}
	for pitch: float in [0.2, 0.5, 0.8, 1.1]:
		for power: float in [0.5, 0.8, 1.0]:
			m.walker.global_position = Vector2(h.position.x + h.windows()[1] + 15.0, foot + 70.0)
			m.walker.rotation = -PI / 2.0
			m.walker.pitch = pitch
			m.walker.carrying = "stone"
			await physics_frame
			var said: Array = m._throw_path(power)
			var end: Vector3 = (said[0] as PackedVector3Array)[-1]
			var got := [] # [target, position, height] from the real flight
			m._on_thrown(Vector2.RIGHT.rotated(m.walker.rotation), power)
			await process_frame
			var f: FlyingStone = m.get_node("Stones").get_children().filter(func(s: Node) -> bool: return s is FlyingStone)[0]
			f.landed.connect(func(s: FlyingStone, target: String) -> void: got.assign([target, s.position, s.z]))
			for i in 400:
				if not got.is_empty():
					break
				await physics_frame
			var want: String = "" if said[1] == "ground" else said[1]
			assert(got[0] == want, "pitch %.1f power %.1f: traced %s, hit %s" % [pitch, power, want, got[0]])
			assert((got[1] as Vector2).distance_to(Vector2(end.x, end.y)) < 1.0 and absf(got[2] - end.z) < 1.0,
				"and at the traced spot: %s vs %s" % [got, end])
			seen[want] = true
			for s in m.get_node("Stones").get_children(): # clear what landed
				s.free()
			m.walker.dazed = 0.0
	assert(seen.has("wall") and seen.has("window"), "the sweep hit both wall and window: %s" % [seen.keys()])
	print("PASS throw path (%s)" % [seen.keys()])
	quit()
