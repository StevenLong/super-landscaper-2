extends Node2D
## Title-screen attract mode: a petrol mower mows the lawn in neat lanes, leaving
## stripes, and starts again on fresh grass when it's done.

const LANE := 26.0
const SPEED := 260.0

var lawn: Lawn
var _mower: Sprite2D
var _lane := 0
var _dir := 1.0
var _stride := 0.0


func _ready() -> void:
	lawn = Lawn.new()
	lawn.size_px = Vector2i(1280, 720)
	add_child(lawn)
	_mower = Sprite2D.new()
	_mower.texture = preload("res://art/mower_petrol.png")
	_mower.hframes = 3
	_mower.scale = Vector2(2, 2)
	add_child(_mower)
	_start()


func _start() -> void:
	lawn.setup()
	_lane = 0
	_dir = 1.0
	_mower.position = Vector2(-60, LANE)


func _process(delta: float) -> void:
	var before := _mower.position
	_mower.position.x += _dir * SPEED * delta
	_mower.rotation = 0.0 if _dir > 0.0 else PI
	lawn.cut_segment(before, _mower.position, 34.0)
	_stride += SPEED * delta
	if _stride > 14.0:
		_stride = 0.0
		_mower.frame = 1 - _mower.frame
	if (_dir > 0.0 and _mower.position.x > 1340.0) or (_dir < 0.0 and _mower.position.x < -60.0):
		_lane += 1
		_dir = -_dir
		_mower.position.y = LANE + _lane * LANE * 2.0
		if _mower.position.y > 720.0 + LANE:
			_start()
