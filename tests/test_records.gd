# Per-stat records: beat your most-in-one-job of something and the rundown calls it a
# personal best (balls fetched) or a personal worst (windows put through). Firsts don't
# count, and the records are saved. What can only happen once a job (the dog walked home)
# is named as an event, never counted or a record.
extends SceneTree


func _initialize() -> void:
	var g := root.get_node("Game")
	g.save_path = "user://test_records.cfg"
	g.new_run(5)
	g.records = {"windows": 1, "fetches": 1, "dog_returned": 1}
	g.record_result({"outcome": "paid", "net": 10, "paid": 10, "rep": 0.0,
		"tally": {"windows": 2, "fetches": 2, "flowers": 9, "dog_returned": 1}})
	var r: Dictionary = g.last_result
	assert("windows" in r.records and "fetches" in r.records, "beat the old records")
	assert(not "dog_returned" in r.records, "a once-a-job event is never a record")
	assert(not "flowers" in r.records, "a first isn't a record")
	var lines: Array = g.tally_lines(r.tally, {}, r.records)
	assert(lines.any(func(l: String) -> bool: return l.begins_with("Windows put through 2 PERSONAL WORST")), "a window record is a worst: %s" % [lines])
	assert(lines.any(func(l: String) -> bool: return l.contains("fetched 2 PERSONAL BEST")), "a ball fetched is a best")
	assert("Walked the dog home" in lines, "the dog walked home is named, not counted: %s" % [lines])
	var cfg := ConfigFile.new()
	cfg.load(g.save_path)
	assert(cfg.get_value("best", "records", {}).get("flowers", 0) == 9, "records are saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.save_path))
	print("PASS records")
	quit()
