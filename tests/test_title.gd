# The title screen's music and sound buttons flip the setting and relabel themselves.
extends SceneTree

var _title: Control
var _frame := 0


func _initialize() -> void:
	_title = load("res://title.tscn").instantiate()
	root.add_child(_title)


func _find(text: String) -> Button:
	for b in _title.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		var sfx: Node = root.get_node("Sfx")
		var was: bool = sfx.music_on
		var b := _find("Music: %s" % ("on" if was else "off"))
		assert(b != null, "the title has a music button showing the setting")
		b.pressed.emit()
		assert(sfx.music_on != was and b.text == "Music: %s" % ("on" if sfx.music_on else "off"), "pressing it flips music and the label")
		b.pressed.emit() # put the player's setting back
		assert(sfx.music_on == was, "and back")
		assert(_find("Sound: %s" % ("on" if sfx.sound_on else "off")) != null, "a sound button too")
		print("PASS title")
		quit()
	return false
