extends CanvasLayer
## Job HUD: coverage, clock, fuel, the customer's face, and the modal panels
## (briefing, truck menu, pause). Runs while the game is paused.

signal choice(id: String)

const SPEECH_W := 360.0

var _panel: PanelContainer
var _say_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.05, 0.09, 0.85)
	box.border_color = Color("5a4a6a")
	box.set_border_width_all(2)
	box.set_content_margin_all(8)
	$Speech.add_theme_stylebox_override("normal", box)


## Speech hangs under the portrait, or above it while the portrait is ducked at the bottom.
func _process(_delta: float) -> void:
	var f: Control = $Face
	var s: Label = $Speech
	s.size = Vector2(SPEECH_W, 0.0) # the height grows back to fit the wrapped line
	s.position.x = f.position.x + f.size.x - SPEECH_W
	s.position.y = f.position.y + f.size.y + 6.0 if f.position.y < 300.0 else f.position.y - s.size.y - 6.0


func set_clock(seconds: float) -> void:
	$Clock.text = "%d:%02d" % [floori(seconds / 60.0), int(seconds) % 60]


func set_hint(text: String) -> void:
	$Hint.text = text
	$Hint.visible = text != ""


## The customer says a line under their portrait, a word at a time, then it fades.
func say(line: String) -> void:
	var s: Label = $Speech
	if _say_tween:
		_say_tween.kill() # a new line replaces the old one, fade and all
	s.visible = line != ""
	if line == "":
		return
	s.text = "\"%s\"" % line
	s.modulate.a = 1.0
	s.visible_characters = 0
	_say_tween = create_tween()
	var shown := 0
	for word in s.text.split(" "):
		shown = mini(shown + word.length() + 1, s.text.length())
		_say_tween.tween_callback(s.set.bind("visible_characters", shown))
		_say_tween.tween_interval(0.12)
	_say_tween.tween_interval(2.2)
	_say_tween.tween_property(s, "modulate:a", 0.0, 0.6)


## A rep hit popping beside the portrait, seen even when the customer is off screen.
func pop(text: String, color := UI.BAD) -> void:
	var f: Control = $Face
	var l := UI.label(text, 30, color)
	var y := f.position.y + f.size.y * 0.5 - 20.0
	for c in get_children():
		if c.has_meta("pop"):
			y = maxf(y, c.position.y + 32.0) # below any still floating, so they never overlap
	l.set_meta("pop", true)
	add_child(l)
	l.position = Vector2(f.position.x - l.get_minimum_size().x - 12.0, y)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40.0, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(l.queue_free)


## A big game-over style line for a moment, above the player (who is always mid-screen).
## Play carries on.
func banner(text: String) -> void:
	var l := UI.label(text, 80, UI.BAD)
	UI.shadow(l, 6)
	add_child(l)
	var view := get_viewport().get_visible_rect().size
	l.position = Vector2((view.x - l.get_minimum_size().x) / 2.0, view.y * 0.22)
	l.pivot_offset = l.get_minimum_size() / 2.0
	l.scale = Vector2(2.5, 2.5)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


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
		UI.focus(first)
