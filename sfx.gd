extends Node
## Sound (autoload "Sfx"): one-shot effects from a small player pool, and a music
## track that crossfades. Files live in audio/, made by tools/make_audio.py.

const VOLUME := { ## per-sound trims in dB, so the synth levels sit together
	"squeak_hedgehog": -10.0, "squeak_squirrel": -12.0, "fired": -6.0, "fuel_low": -8.0,
	"ui_move": -14.0, "ui_select": -10.0, "bump": -6.0, "crunch": -4.0,
	"voice_happy": -8.0, "voice_laugh": -8.0, "voice_angry": -6.0, "voice_horrified": -6.0,
	"clonk": -6.0, "thud": -4.0, "glass": -4.0, "yelp": -8.0, "glug": -8.0, "splash": -6.0,
}

var music_db := -12.0
var music_on := true
var sound_on := true

const SETTINGS := "user://settings.cfg"

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Two buses so music and sound can be muted separately. Every non-music player
	# in the game (pool, engines, the truck's glug) sits on "SFX".
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		music_on = cfg.get_value("audio", "music", true)
		sound_on = cfg.get_value("audio", "sound", true)
	_apply()


## Flip music or sound on/off, and remember it.
func toggle(which: String) -> void:
	if which == "music":
		music_on = not music_on
	else:
		sound_on = not sound_on
	_apply()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sound", sound_on)
	cfg.save(SETTINGS)


func _apply() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not music_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not sound_on)


func play(sound: String, pitch_jitter := 0.08) -> void:
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _pool[0]
	var s: AudioStreamWAV = load("res://audio/%s.wav" % sound)
	if s.loop_mode != AudioStreamWAV.LOOP_DISABLED: # glug loops for the truck; a one-shot plays it once
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	p.stream = s
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
