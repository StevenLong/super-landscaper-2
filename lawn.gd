class_name Lawn
extends Sprite2D
## The mowable lawn as a grid of cells. Each cell is cut or uncut; the grid is drawn
## as a low-res image scaled up by cell_px. Positions passed in are lawn-space pixels
## (global position minus the lawn's global position).

signal cut_changed(fraction: float)

@export var size_px := Vector2i(1280, 720)
@export var cell_px := 4
@export var uncut_color := Color(0.2, 0.42, 0.14)
@export var cut_color := Color(0.42, 0.66, 0.28)

var _img: Image
var _tex: ImageTexture
var _grid := PackedByteArray()
var _cut := 0
var _total := 0


func _ready() -> void:
	setup()


func setup() -> void:
	var w := size_px.x / cell_px
	var h := size_px.y / cell_px
	_img = Image.create(w, h, false, Image.FORMAT_RGB8)
	_img.fill(uncut_color)
	_grid.resize(w * h)
	_grid.fill(0)
	_total = w * h
	_cut = 0
	_tex = ImageTexture.create_from_image(_img)
	texture = _tex
	centered = false
	scale = Vector2(cell_px, cell_px)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func cut_fraction() -> float:
	return float(_cut) / _total


## Cut a stroke of the given radius from one point to another, stamping circles
## every cell along it so fast movement leaves no gaps.
func cut_segment(from: Vector2, to: Vector2, radius: float) -> void:
	var steps := maxi(1, ceili(from.distance_to(to) / cell_px))
	var changed := false
	for i in steps + 1:
		changed = _cut_circle(from.lerp(to, float(i) / steps), radius) or changed
	if changed:
		_tex.update(_img)
		cut_changed.emit(cut_fraction())


func _cut_circle(center: Vector2, radius: float) -> bool:
	var c := center / cell_px
	var r := radius / cell_px
	var w := _img.get_width()
	var h := _img.get_height()
	var changed := false
	for y in range(maxi(0, floori(c.y - r)), mini(h, ceili(c.y + r))):
		for x in range(maxi(0, floori(c.x - r)), mini(w, ceili(c.x + r))):
			var i := y * w + x
			if _grid[i] or Vector2(x + 0.5, y + 0.5).distance_squared_to(c) > r * r:
				continue
			_grid[i] = 1
			_cut += 1
			_img.set_pixel(x, y, cut_color)
			changed = true
	return changed
