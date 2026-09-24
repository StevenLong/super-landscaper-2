class_name PixelFont
## Builds a crisp bitmap FontFile from art/font.png (tools/make_font.py): 16x6 cells
## of 6x10 pixels (1px apart) for ASCII 32-126, glyph body in rows 1-7, baseline under row 8.
## Proportional: each glyph advances by its inked width plus one pixel.

const CW := 6
const CH := 10
const COLS := 16
const GAP := 1 ## blank pixels between cells, so scaling never samples a neighbour
const ASCENT := 8


static func make() -> FontFile:
	var img := (load("res://art/font.png") as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var f := FontFile.new()
	var sz := Vector2i(CH, 0)
	f.fixed_size = CH
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.set_texture_image(0, sz, 0, img)
	f.set_cache_ascent(0, CH, ASCENT)
	f.set_cache_descent(0, CH, CH - ASCENT)
	for code in range(32, 127):
		var i := code - 32
		@warning_ignore("integer_division") # whole cells: dropping the remainder is the point
		var cell := Rect2i((i % COLS) * (CW + GAP), (i / COLS) * (CH + GAP), CW, CH)
		var width := 0
		for x in CW:
			for y in CH:
				if img.get_pixel(cell.position.x + x, cell.position.y + y).a > 0.5:
					width = x + 1
		var advance := 4 if code == 32 else width + 1
		f.set_glyph_advance(0, CH, code, Vector2(advance, 0))
		f.set_glyph_offset(0, sz, code, Vector2(0, -ASCENT))
		f.set_glyph_size(0, sz, code, Vector2(CW, CH))
		f.set_glyph_uv_rect(0, sz, code, Rect2(cell))
		f.set_glyph_texture_idx(0, sz, code, 0)
	return f
