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


## Focus a control next frame, if it's still around by then (menus can close fast).
static func focus(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()


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
