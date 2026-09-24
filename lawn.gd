class_name Lawn
extends Sprite2D
## The mowable lawn as a grid of cells: uncut, cut (light or dark stripe), or
## excluded (not lawn: driveway, tree, flowerbed, house). The grid is a low-res
## mask image scaled up by cell_px; lawn.gdshader turns it into grass textures.
## Like a real lawn, a cell's stripe is set by the direction it was last mowed in.
## Positions passed in are lawn-space pixels (the lawn sits at the origin).

signal cut_changed(fraction: float)

const UNCUT := 0
const CUT := 1 ## light stripe
const EXCLUDED := 2
const CUT_DARK := 3

const MASK := {UNCUT: Color(0, 0, 0), CUT: Color(0.5, 0, 0), CUT_DARK: Color(1, 0, 0), EXCLUDED: Color(0, 0, 0)}

@export var size_px := Vector2i(1280, 720)
@export var cell_px := 4

var _img: Image
var _tex: ImageTexture
var _grid := PackedByteArray()
var _cut := 0
var _total := 0


func _ready() -> void:
	setup()


func setup() -> void:
	var cells := size_px / cell_px
	_img = Image.create(cells.x, cells.y, false, Image.FORMAT_RGB8)
	_img.fill(MASK[UNCUT])
	_grid.resize(cells.x * cells.y)
	_grid.fill(UNCUT)
	_total = cells.x * cells.y
	_cut = 0
	_tex = ImageTexture.create_from_image(_img)
	texture = _tex
	centered = false
	scale = Vector2(cell_px, cell_px)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://lawn.gdshader")
	mat.set_shader_parameter("long_tex", preload("res://art/grass_long.png"))
	mat.set_shader_parameter("light_tex", preload("res://art/grass_light.png"))
	mat.set_shader_parameter("dark_tex", preload("res://art/grass_dark.png"))
	mat.set_shader_parameter("lawn_px", Vector2(size_px))
	material = mat


func cut_fraction() -> float:
	return float(_cut) / _total


func is_cut_at(p: Vector2) -> bool:
	var v := _cell(p)
	return v == CUT or v == CUT_DARK


func _cell(p: Vector2) -> int:
	var x := floori(p.x / cell_px)
	var y := floori(p.y / cell_px)
	if x < 0 or y < 0 or x >= _img.get_width() or y >= _img.get_height():
		return EXCLUDED
	return _grid[y * _img.get_width() + x]


## Remove a lawn-space rect from the mowable area. Excluded cells never count
## toward the total; whatever sits there draws itself.
func exclude_rect(rect: Rect2) -> void:
	_exclude_where(rect, func(_p: Vector2) -> bool: return true)


## Remove a lawn-space circle (a cell counts if its centre is inside).
func exclude_circle(center: Vector2, radius: float) -> void:
	var bounds := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	_exclude_where(bounds, func(p: Vector2) -> bool: return p.distance_squared_to(center) <= radius * radius)


func _exclude_where(bounds: Rect2, inside: Callable) -> void:
	var w := _img.get_width()
	var h := _img.get_height()
	for y in range(maxi(0, floori(bounds.position.y / cell_px)), mini(h, ceili(bounds.end.y / cell_px))):
		for x in range(maxi(0, floori(bounds.position.x / cell_px)), mini(w, ceili(bounds.end.x / cell_px))):
			var i := y * w + x
			if _grid[i] == EXCLUDED or not inside.call(Vector2(x + 0.5, y + 0.5) * cell_px):
				continue
			if _grid[i] == CUT or _grid[i] == CUT_DARK:
				_cut -= 1
			_grid[i] = EXCLUDED
			_total -= 1
	cut_changed.emit(cut_fraction())


## Cut a stroke of the given radius from one point to another, stamping circles
## every cell along it so fast movement leaves no gaps. Moving up or right mows a
## light stripe, down or left a dark one; a standing stamp keeps existing stripes.
func cut_segment(from: Vector2, to: Vector2, radius: float) -> void:
	var d := to - from
	var stripe := -1
	if d.length_squared() > 0.01:
		if absf(d.y) >= absf(d.x):
			stripe = CUT if d.y < 0.0 else CUT_DARK
		else:
			stripe = CUT if d.x > 0.0 else CUT_DARK
	var steps := maxi(1, ceili(d.length() / cell_px))
	var counted := _cut
	var changed := false
	for i in steps + 1:
		changed = _cut_circle(from.lerp(to, float(i) / steps), radius, stripe) or changed
	if changed:
		_tex.update(_img)
	if _cut != counted:
		cut_changed.emit(cut_fraction())


func _cut_circle(center: Vector2, radius: float, stripe: int) -> bool:
	var c := center / cell_px
	var r := radius / cell_px
	var w := _img.get_width()
	var h := _img.get_height()
	var changed := false
	for y in range(maxi(0, floori(c.y - r)), mini(h, ceili(c.y + r))):
		for x in range(maxi(0, floori(c.x - r)), mini(w, ceili(c.x + r))):
			var i := y * w + x
			var v := _grid[i]
			if v == EXCLUDED or Vector2(x + 0.5, y + 0.5).distance_squared_to(c) > r * r:
				continue
			if v == UNCUT:
				_cut += 1
				v = CUT if stripe < 0 else stripe
			elif stripe >= 0 and v != stripe:
				v = stripe
			else:
				continue
			_grid[i] = v
			_img.set_pixel(x, y, MASK[v])
			changed = true
	return changed
