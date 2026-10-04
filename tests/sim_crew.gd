# Hired help probe (not part of run_all; NOTES 209): what a fully booked helper brings in a
# week against the wage they'd ask, by your name, kit and pace. Back-to-back jobs from a
# paper at that name, 12 hours a day at 0.85 fill, 7 days, each netted by Game.help_job.
# The design's target: about twice the wage. sim_season's SIM_CREW shows a bot's real use.
#   "$GODOT" --headless --path . -s tests/sim_crew.gd
extends SceneTree
func _initialize() -> void:
	var g: Node = root.get_node("Game")
	g.save_path = "user://sim_crew.cfg"
	g.new_run(3)
	for rep in [30.0, 50.0, 70.0, 90.0]:
		g.reputation = rep
		for kit in ["push", "petrol", "rideon"]:
			for pace in [0.6, 1.0]:
				var h := {"pace": pace, "care": 0.6, "kit": kit}
				var week := 0.0
				var jobs := 0
				var s := 1
				for d in 7:
					var t := 0.0
					while true:
						var j: Dictionary = g.make_job(s * 7919 + d, clampf(rep + [-25.0, -12.0, 0.0, 0.0, 12.0, 25.0][s % 6], 0.0, 100.0))
						s += 1
						j.from = 480
						j.by = 1200
						var r: Dictionary = g.help_job(j, h, 0.0)
						if t + 30.0 + r.minutes > 720.0 * 0.85:
							break
						t += 30.0 + r.minutes
						week += r.net
						jobs += 1
				print("rep %d %-6s pace %.1f: $%d a week, %d jobs, wage now $%d" % [rep, kit, pace, week, jobs, g.wage_for(h)])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.business_path()))
	quit()
