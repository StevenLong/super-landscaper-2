# Small fixes from the session-2 play checks: one-shot sounds never loop, font cells
# are a blank pixel apart, WASD drives menus, the truck doesn't refill stamina, the
# corner face ducks out of the player's way, and the [0] cheat ends a job at the top.
extends SceneTree

var _main: Node
var _mower: CharacterBody2D
var _frame := 0


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


## Checks that need the autoloads ready (their _ready hasn't run yet in _initialize).
func _static_checks() -> void:
	# glug.wav loops for the truck; played one-shot it must stop (it used to glug forever).
	var sfx: Node = root.get_node("Sfx")
	sfx.play("glug")
	var looping := 0
	for p: AudioStreamPlayer in sfx._pool:
		if p.playing and (p.stream as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED:
			looping += 1
	assert(looping == 0, "a one-shot glug must not loop")
	var glug: AudioStreamWAV = load("res://audio/glug.wav")
	assert(glug.loop_mode != AudioStreamWAV.LOOP_DISABLED, "the truck's glug still loops")

	# The gap between font cells is blank, so scaling can't pull a g tail over a w.
	var img := (load("res://art/font.png") as Texture2D).get_image()
	img.decompress()
	for i in 95:
		var gx := (i % PixelFont.COLS) * (PixelFont.CW + PixelFont.GAP)
		@warning_ignore("integer_division")
		var gy := (i / PixelFont.COLS) * (PixelFont.CH + PixelFont.GAP)
		for y in PixelFont.CH + 1:
			assert(gx + PixelFont.CW >= img.get_width() or img.get_pixel(gx + PixelFont.CW, gy + y).a < 0.5, "gap column inked at glyph %d" % i)
		for x in PixelFont.CW:
			assert(gy + PixelFont.CH >= img.get_height() or img.get_pixel(gx + x, gy + PixelFont.CH).a < 0.5, "gap row inked at glyph %d" % i)

	for pair: Array in [["ui_up", KEY_W], ["ui_down", KEY_S], ["ui_left", KEY_A], ["ui_right", KEY_D]]:
		var k := InputEventKey.new()
		k.physical_keycode = pair[1]
		assert(InputMap.action_has_event(pair[0], k), "%s should answer to WASD" % pair[0])


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_static_checks()
	elif _frame == 2:
		_mower = _main.get_node("Mower")
		_mower.power = "stamina"
		_mower.regen = 0.0 # so only the truck could raise it
		_mower.fuel = 10.0
		_mower.global_position = Vector2(230, 630) # beside the truck, as in test_fuel
	elif _frame == 62:
		assert(absf(_mower.fuel - 10.0) < 0.01, "the truck must not refill stamina, got %f" % _mower.fuel)
		# The corner face ducks to the bottom right while the player is up near it.
		_mower.global_position = Vector2(_main.lawn.size_px.x - 20, 20)
	elif _frame == 100:
		var face: Control = _main.get_node("HUD/Face")
		assert(face.position.y == _main.FACE_BOTTOM, "the face should duck out of the player's way, y %f" % face.position.y)
		_mower.global_position = Vector2(_main.lawn.size_px) / 2.0
	elif _frame == 140:
		assert(_main.get_node("HUD/Face").position.y == _main.FACE_TOP, "and come back once they leave")
		_main.hud.close()
		paused = false
		_main._cheat_win()
		assert(_main.over, "the [0] cheat ends the job")
		var r: Dictionary = root.get_node("Game").last_result
		assert(r.outcome == "paid" and r.mood == 100.0 and r.tip > 0, "the [0] cheat is a delighted, tipped job: %s" % r)
		print("PASS polish")
		quit()
	return false
