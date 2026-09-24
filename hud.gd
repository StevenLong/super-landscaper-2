extends CanvasLayer
## Job HUD: coverage, clock, fuel, the customer's face, and the modal panels
## (briefing, truck menu, pay screen, pause). Runs while the game is paused.

signal choice(id: String)

var _panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_clock(seconds: float) -> void:
	$Clock.text = "%d:%02d" % [floori(seconds / 60.0), int(seconds) % 60]


func set_hint(text: String) -> void:
	$Hint.text = text
	$Hint.visible = text != ""


func say(line: String) -> void:
	$Speech.text = "\"%s\"" % line
	$Speech.visible = line != ""
	$Speech.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property($Speech, "modulate:a", 0.0, 0.6)


func is_open() -> bool:
	return _panel != null


func close() -> void:
	if _panel:
		_panel.queue_free()
		_panel = null


## A centred modal panel: a title, body lines, and one button per [id, label].
## The first button takes focus so keyboard/pad works.
func open(title: String, lines: Array, buttons: Array, face_look := {}, face_expr := "") -> void:
	close()
	_panel = PanelContainer.new()
	_panel.theme = UI.theme()
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	if not face_look.is_empty():
		var f := Face.new()
		f.custom_minimum_size = Vector2(132, 132)
		f.set_look(face_look)
		f.expression = face_expr
		row.add_child(f)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	col.add_child(UI.label(title, 30, UI.GOLD))
	for l in lines:
		col.add_child(UI.label(str(l), 20))
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	col.add_child(btns)
	var first: Button = null
	for b: Array in buttons:
		var btn := UI.button(b[1], func() -> void: choice.emit(b[0]))
		btns.add_child(btn)
		if first == null:
			first = btn
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	if first:
		first.call_deferred("grab_focus")
