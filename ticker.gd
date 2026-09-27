class_name Ticker
extends Control
## One line of text scrolling right to left for ever, for more than fits in `width`.
## Text that fits just sits still.

const SPEED := 60.0 ## px a second
const GAP := "      "

var text := ""
var _label: Label


func _init(line: String, font_size: int, color: Color, width: float) -> void:
	text = line
	clip_contents = true
	custom_minimum_size = Vector2(width, font_size + 8)
	_label = UI.label(line + GAP + line + GAP, font_size, color) # twice over, so it loops without a seam
	add_child(_label)


func _process(delta: float) -> void:
	var loop := _label.size.x / 2.0
	if loop <= 0.0 or _label.text == text:
		return
	if loop <= size.x: # it fits: no need to scroll
		_label.text = text
		_label.position.x = 0.0
		return
	_label.position.x -= SPEED * delta
	if _label.position.x <= -loop:
		_label.position.x += loop
