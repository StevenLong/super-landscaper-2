class_name UI
## Shared look for menus: one theme, plus small builders so screens stay short.

const BG := Color("1c2a1c")
const PANEL := Color("24361f")
const PANEL_EDGE := Color("6a8a4a")
const TEXT := Color("f0ead8")
const DIM := Color("a8b890")
const GOOD := Color("98e070")
const BAD := Color("f07060")
const GOLD := Color("f8d048")


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	t.default_font = ThemeDB.fallback_font
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = PANEL_EDGE
	box.set_border_width_all(3)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(14)
	t.set_stylebox("panel", "PanelContainer", box)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var b := StyleBoxFlat.new()
		b.bg_color = {"normal": Color("3a5a2a"), "hover": Color("4a7a34"), "pressed": Color("2a4a1e"),
			"focus": Color("4a7a34"), "disabled": Color("2c3a28")}[state]
		b.border_color = GOLD if state == "focus" else Color("88aa60")
		b.set_border_width_all(2)
		b.set_content_margin_all(8)
		t.set_stylebox(state, "Button", b)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("708060"))
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PopupMenu", box) # a pick from a list (who goes): a panel, the item under the cursor ringed
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color("4a7a34")
	lit.border_color = GOLD
	lit.set_border_width_all(2)
	t.set_stylebox("hover", "PopupMenu", lit)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_constant("v_separation", "PopupMenu", 12)
	return t


static func label(text: String, size := 20, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px(size))
	l.add_theme_color_override("font_color", color)
	shadow(l)
	return l


## Snap a font size to a whole multiple of the 10px pixel font (never below 2x).
static func px(size: int) -> int:
	return maxi(20, roundi(size / 10.0) * 10)


## A one-pixel-per-scale drop shadow (bitmap fonts can't draw outlines).
static func shadow(c: Control, strength := 2) -> void:
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	c.add_theme_constant_override("shadow_offset_x", strength)
	c.add_theme_constant_override("shadow_offset_y", strength)


static func button(text: String, on_press: Callable, size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", px(size))
	b.pressed.connect(func() -> void: Sfx.play("ui_select", 0.0))
	b.pressed.connect(on_press)
	b.focus_entered.connect(func() -> void: Sfx.play("ui_move", 0.0))
	return b


## A sum to pick, lo to hi in steps: a slider (left/right or the pad, or drag it) and the
## figure beside it. The top end is always exactly hi. on_change(value) as it moves.
static func amount(lo: int, hi: int, step: int, value: int, on_change: Callable) -> HBoxContainer:
	var row := hbox(14)
	var s := HSlider.new()
	s.name = "Amount"
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(360, 32)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := label("$%d" % value, 24, GOLD)
	l.custom_minimum_size.x = 90
	s.value_changed.connect(func(v: float) -> void:
		l.text = "$%d" % roundi(v)
		Sfx.play("ui_move", 0.0)
		on_change.call(roundi(v)))
	row.add_child(s)
	row.add_child(l)
	return row


## Focus a control next frame, if it's still around by then (menus can close fast).
static func focus(c: Control) -> void:
	if c == null:
		return
	var id := c.get_instance_id() # by id: a page rebuilt before the deferred call frees c, and a freed capture errors
	(func() -> void:
		var n := instance_from_id(id) as Control
		if n and n.is_inside_tree():
			n.grab_focus()).call_deferred()


## Left or right (dir -1 or 1) from button c, never up or down a column (NOTES 221): Godot's
## own pick takes a button a pixel that way in a row far below. The nearest button more that
## way than up or down, at most a row's height off c's row (level counts most), or null.
static func row_step(c: BaseButton, dir: int) -> Control:
	var r := c.get_global_rect()
	var best: Control = null
	var best_score := INF
	for o: Node in c.get_tree().current_scene.find_children("*", "BaseButton", true, false):
		var b := o as BaseButton
		var ro := b.get_global_rect()
		var v := ro.get_center() - r.get_center()
		var gap := maxf(0.0, maxf(ro.position.y - r.end.y, r.position.y - ro.end.y))
		if b == c or v.x * dir <= absf(v.y) or gap > r.size.y or b.focus_mode != Control.FOCUS_ALL \
				or not b.is_visible_in_tree():
			continue
		var score := v.x * dir + 4.0 * absf(v.y)
		if score < best_score:
			best = b
			best_score = score
	return best


static func panel(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(child)
	return p


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func rep_word(rep: float) -> String:
	if rep >= 80.0: return "Stellar"
	if rep >= 60.0: return "Good"
	if rep >= 40.0: return "Fair"
	if rep >= 20.0: return "Shaky"
	if rep > 0.0: return "Dire"
	return "Ruined"
