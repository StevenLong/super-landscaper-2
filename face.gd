class_name Face
extends Control
## The customer's portrait: art/faces.png drawn in key colours, palette-swapped for
## this customer's skin, hair and shirt. Shakes briefly when the expression changes.

## The sheet has each of these, then each again mid-word (mouth moved) for talking.
const FRAMES := ["delighted", "happy", "neutral", "annoyed", "furious", "horrified", "laughing", "fired", "hurt", "ko", "watch"]
const CELL := 40

const SKINS := [["f8d0a8", "e8b088", "c08060"], ["f0c090", "d09868", "a06840"], ["d8a070", "b07848", "805030"],
	["a87050", "885030", "603820"], ["704830", "583420", "3e2414"]]
const HAIRS := [["484050", "282430", "141018"], ["a07040", "704820", "4a2c14"], ["f8e080", "d8b048", "a07c28"],
	["e88848", "c05828", "883818"], ["c8c8c8", "989898", "686868"], ["f8f8f0", "d8d8d0", "a8a8a0"]]
const SHIRTS := [["4878c8", "305090"], ["c84848", "903030"], ["48a058", "307040"], ["e8c048", "b08828"],
	["9058b8", "683888"], ["e8e8e0", "b0b0a8"]]

@export var pixel_scale := 3

var expression := "neutral":
	set(v):
		if v != expression:
			_shake = 0.35
		expression = v
		queue_redraw()

var talking := false: ## flaps the mouth between the two frames
	set(v):
		talking = v
		_mouth_open = false
		queue_redraw()

var view := "patio": ## where they are (Customer.where): greyed indoors, behind glass at a window
	set(v):
		if v != view:
			view = v
			queue_redraw()

var _tex: Texture2D
var _style := 0
var _shake := 0.0
var _mouth_open := false
var _flap := 0.0


func set_look(look: Dictionary) -> void:
	_style = look.hair_style
	_tex = ImageTexture.create_from_image(swapped("res://art/faces.png", look, Rect2i(0, _style * CELL, CELL * FRAMES.size() * 2, CELL)))
	queue_redraw()


## A copy of a key-coloured sheet with this customer's skin, hair and shirt swapped in
## (only within region, to keep it quick). Shared with the standing sprite.
static func swapped(path: String, look: Dictionary, region := Rect2i()) -> Image:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	if not region.has_area():
		region = Rect2i(Vector2i.ZERO, img.get_size())
	var skin: Array = SKINS[look.skin % SKINS.size()]
	var hair: Array = HAIRS[look.hair % HAIRS.size()]
	var shirt: Array = SHIRTS[look.shirt % SHIRTS.size()]
	var angry := skin.map(func(h: String) -> Color: return Color(h).lerp(Color("e03028"), 0.45))
	var swap := {
		Color8(255, 1, 1): Color(skin[0]), Color8(254, 2, 2): Color(skin[1]), Color8(253, 3, 3): Color(skin[2]),
		Color8(255, 1, 255): angry[0], Color8(254, 2, 254): angry[1], Color8(253, 3, 253): angry[2],
		Color8(1, 255, 1): Color(hair[0]), Color8(2, 254, 2): Color(hair[1]), Color8(3, 253, 3): Color(hair[2]),
		Color8(1, 1, 255): Color(shirt[0]), Color8(2, 2, 254): Color(shirt[1]),
	}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and swap.has(Color8(c.r8, c.g8, c.b8)):
				img.set_pixel(x, y, swap[Color8(c.r8, c.g8, c.b8)])
	return img


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake -= delta
		queue_redraw()
	if talking:
		_flap -= delta
		if _flap <= 0.0:
			_flap = 0.15
			_mouth_open = not _mouth_open
			queue_redraw()


func _draw() -> void:
	var s := float(CELL * pixel_scale)
	var box := Rect2(Vector2.ZERO, Vector2(s, s) + Vector2(12, 12))
	draw_rect(box, Color("1c1420"))
	draw_rect(box.grow(-2), Color("5a4a6a"), false, 2.0)
	draw_rect(Rect2(6, 6, s, s), Color("2a4a70"))
	if _tex == null:
		return
	var jitter := Vector2(randf_range(-2, 2), randf_range(-2, 2)) if _shake > 0.0 else Vector2.ZERO
	var i := FRAMES.find(expression) + (FRAMES.size() if _mouth_open else 0)
	var tint := Color(0.4, 0.4, 0.45) if view == "inside" else Color.WHITE # can't see you, you can't see them
	draw_texture_rect_region(_tex, Rect2(Vector2(6, 6) + jitter, Vector2(s, s)),
		Rect2(i * CELL, _style * CELL, CELL, CELL), tint)
	if view == "window": # a pane of glass between you: a sheen and the glazing bars
		var pane := Rect2(6, 6, s, s)
		draw_rect(pane, Color(0.7, 0.85, 1.0, 0.18))
		draw_line(Vector2(6 + s / 2.0, 6), Vector2(6 + s / 2.0, 6 + s), Color("e8e0d0"), 4.0)
		draw_line(Vector2(6, 6 + s / 2.0), Vector2(6 + s, 6 + s / 2.0), Color("e8e0d0"), 4.0)
		draw_rect(pane, Color("e8e0d0"), false, 4.0)
