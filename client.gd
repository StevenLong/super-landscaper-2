extends Node2D
## The customer standing on their patio, watching. Turns to face the mower (8
## facings) and throws their arms up when they react. Palette-swapped to match their
## portrait.

var watch: Node2D
var _hop := 0.0
var _tex: Texture2D
var _out := false
var _toward := PI / 2.0 ## facing out over the garden until there's a mower to watch


func set_look(look: Dictionary) -> void:
	_tex = ImageTexture.create_from_image(Face.swapped("res://art/client.png", look))
	queue_redraw()


func react() -> void:
	if not _out:
		_hop = 0.8


func knock_out() -> void:
	_out = true
	_hop = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_hop = maxf(0.0, _hop - delta)
	queue_redraw()


func _draw() -> void:
	if _tex == null:
		return
	var y := -absf(sin(_hop * 16.0)) * 5.0 if _hop > 0.0 else 0.0
	if not _out and watch != null and is_instance_valid(watch):
		_toward = (watch.global_position - global_position).angle() # knocked out, they lie as they fell
	var frame := 2 if _out else (1 if _hop > 0.0 else 0)
	Facing.draw(self, _tex, 3, frame, _toward, Vector2(0, y))
