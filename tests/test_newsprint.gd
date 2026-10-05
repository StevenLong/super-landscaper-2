# Ink on newsprint has no drop shadow (NOTES 218): on a day with news, every Label on a
# scrap of newsprint in the paper, the headline included, draws unshadowed.
extends SceneTree

var g: Node
var _frame := 0


func _initialize() -> void:
	g = root.get_node("Game")
	g.save_path = "user://test_best.cfg"
	g.new_run(7)
	var d: int = g.day
	while g.day_event(d) == "":
		d += 1
		assert(d < g.day + 400, "some day has news")
	g.day = d
	change_scene_to_file("res://board.tscn")


func _on_paper(n: Node) -> bool:
	var p := n.get_parent()
	while p:
		if p is PanelContainer:
			var sb := (p as PanelContainer).get_theme_stylebox("panel")
			if sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color == Color("e8e0c8"):
				return true
		p = p.get_parent()
	return false


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		current_scene._show("paper")
	if _frame < 10:
		return false
	var news: Label = current_scene.find_child("News", true, false)
	assert(news != null and _on_paper(news), "today's headline on newsprint")
	var inked := current_scene.find_children("*", "Label", true, false).filter(_on_paper)
	for l: Label in inked:
		assert(l.get_theme_color("font_shadow_color").a == 0.0, "no shadow on newsprint: %s" % l.text)
	print("PASS newsprint: %d labels on paper, none shadowed" % inked.size())
	quit()
	return true
