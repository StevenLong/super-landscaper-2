class_name Facing
## Things that turn (mowers, the player on foot, critters) are drawn upright from an
## 8-facing sheet (tools/voxel.py): a row per facing, 0 east, 2 south, 4 west, 6 north.


## Which facing row an angle points at.
static func of(angle: float) -> int:
	return posmod(roundi(angle / (PI / 4.0)), 8)


## Draw one cell of a sheet with `frames` columns, centred on at.
static func draw(ci: CanvasItem, tex: Texture2D, frames: int, frame: int, angle: float, at := Vector2.ZERO) -> void:
	var cell := Vector2(tex.get_width() / float(frames), tex.get_height() / 8.0)
	ci.draw_texture_rect_region(tex, Rect2(at - cell / 2.0, cell), Rect2(Vector2(frame, of(angle)) * cell, cell))
