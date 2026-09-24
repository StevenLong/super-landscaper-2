extends Node
## Sound (autoload "Sfx"): one-shot effects from a small player pool, and a music
## track that crossfades. Files live in audio/, made by tools/make_audio.py.

const VOLUME := { ## per-sound trims in dB, so the synth levels sit together
	"squeak_hedgehog": -10.0, "squeak_squirrel": -12.0, "fired": -6.0, "fuel_low": -8.0,
	"ui_move": -14.0, "ui_select": -10.0, "bump": -6.0, "crunch": -4.0,
	"voice_happy": -8.0, "voice_laugh": -8.0, "voice_angry": -6.0, "voice_horrified": -6.0,
	"clonk": -6.0, "thud": -4.0, "glass": -4.0, "yelp": -8.0, "glug": -8.0,
}

var music_db := -12.0

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func play(sound: String, pitch_jitter := 0.08) -> void:
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _pool[0]
	p.stream = load("res://audio/%s.wav" % sound)
	p.volume_db = VOLUME.get(sound, 0.0)
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	var tw := create_tween()
	if _music.playing:
		tw.tween_property(_music, "volume_db", -40.0, 0.4)
	tw.tween_callback(func() -> void:
		if track == "":
			_music.stop()
			return
		_music.stream = load("res://audio/%s.wav" % track)
		_music.volume_db = -40.0
		_music.play())
	if track != "":
		tw.tween_property(_music, "volume_db", music_db, 0.6)
