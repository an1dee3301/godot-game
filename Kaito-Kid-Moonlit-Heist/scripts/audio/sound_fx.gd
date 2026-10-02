class_name SoundFX
extends Node
## Sample-based audio: CC0 recordings (see assets/audio/CREDITS.md) with pooled 2D/3D playback,
## per-sound variation, a museum reverb on effects, an indoor-muffled rain bed, thunder synced to
## lightning and crossfading music tracks per game mode.

const DIR := "res://assets/audio/"
const MUSIC_FADE := 1.6

## name -> [files, volume dB, min pitch, max pitch]
const SFX := {
	"footstep": [["footstep_concrete_000", "footstep_concrete_001", "footstep_concrete_002", "footstep_concrete_003", "footstep_concrete_004"], -14.0, 0.92, 1.08],
	"footstep_run": [["footstep_concrete_000", "footstep_concrete_001", "footstep_concrete_002", "footstep_concrete_003", "footstep_concrete_004"], -8.0, 0.95, 1.12],
	"land": [["impactSoft_medium_000", "impactSoft_medium_001", "impactSoft_medium_002"], -6.0, 0.9, 1.0],
	"card_throw": [["drawKnife1", "drawKnife2", "drawKnife3"], -7.0, 1.25, 1.45],
	"card_hit": [["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_002"], -4.0, 1.0, 1.15],
	"card_stick": [["knifeSlice", "knifeSlice2"], -9.0, 1.1, 1.3],
	"smoke": [["cloth2", "cloth4"], -2.0, 0.55, 0.65],
	"guard_huh": [["question_001", "question_002"], -10.0, 0.85, 0.95],
	"guard_alert": [["impactBell_heavy_000"], -6.0, 1.35, 1.4],
	"baton_swing": [["cloth1", "cloth3"], -6.0, 1.3, 1.5],
	"hit_player": [["impactPunch_heavy_000", "impactPunch_heavy_001", "impactPunch_heavy_002"], -3.0, 0.9, 1.05],
	"guard_down": [["dropLeather"], -2.0, 0.7, 0.8],
	"jewel_steal": [["glass_001", "glass_002", "glass_003", "glass_004", "glass_005", "glass_006"], -6.0, 0.95, 1.05],
	"laser_trip": [["error_001", "error_002", "error_003"], -6.0, 0.95, 1.0],
	"laser_off": [["minimize_001", "minimize_002"], -6.0, 0.8, 0.85],
	"camera_alert": [["error_004"], -7.0, 1.2, 1.25],
	"pickup_rose": [["pluck_001", "pluck_002"], -6.0, 1.0, 1.1],
	"pickup_smoke": [["handleSmallLeather"], -5.0, 1.0, 1.1],
	"exit_unlock": [["doorOpen_1"], -3.0, 0.8, 0.85],
	"ui_click": [["click_001", "click_002", "click_003"], -9.0, 1.0, 1.05],
	"win": [["confirmation_004"], -4.0, 1.0, 1.0],
	"lose": [["error_004"], -4.0, 0.7, 0.7],
	"whistle": [[], -8.0, 1.0, 1.0],
}
## Extra one-shot layers played with a sound (name -> [file, volume dB, pitch]).
const LAYERS := {
	"guard_down": ["impactSoft_medium_002", -4.0, 0.7],
	"exit_unlock": ["metalLatch", -4.0, 1.0],
	"jewel_steal": ["confirmation_002", -12.0, 1.2],
	"guard_alert": ["impactPunch_medium_001", -10.0, 0.7],
}
const MUSIC := {
	"title": "title_jazz", "win": "title_jazz",
	"sneak": "sneak_on_patrol", "alert": "alert_night_prowler",
	"chase": "chase_high_alert", "escape": "escape_closing_in",
}
## Linear volume per mode (music tracks were normalised to similar loudness).
const MUSIC_LEVEL := {"title": 0.8, "win": 0.85, "sneak": 0.55, "alert": 0.6, "chase": 0.7, "escape": 0.75}

var _headless := false
var _streams: Dictionary = {}
var _two_d: Array[AudioStreamPlayer] = []
var _three_d: Array[AudioStreamPlayer3D] = []
var _music: Dictionary = {}          ## track name -> AudioStreamPlayer
var _music_target: Dictionary = {}   ## track name -> linear target volume
var _rain: AudioStreamPlayer
var _thunder: Array[AudioStream] = []
var _cursor_2d := 0
var _cursor_3d := 0
var _mode := ""
var _last_step_ms := -1000
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_setup_buses()
	if _headless:
		return
	_rng.randomize()
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_two_d.append(p)
	for i in 16:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.unit_size = 7.0
		p3.max_distance = 45.0
		p3.attenuation_filter_cutoff_hz = 6000.0
		p3.attenuation_filter_db = -10.0
		add_child(p3)
		_three_d.append(p3)
	for mode: String in MUSIC:
		var track: String = MUSIC[mode]
		if _music.has(track):
			continue
		var mp := AudioStreamPlayer.new()
		mp.bus = "Music"
		mp.stream = _load(DIR + "music/" + track + ".mp3", true)
		mp.volume_db = -80.0
		add_child(mp)
		_music[track] = mp
		_music_target[track] = 0.0
	_rain = AudioStreamPlayer.new()
	_rain.bus = "Ambience"
	_rain.stream = _load(DIR + "ambience/rain_loop.mp3", true)
	_rain.volume_db = -6.0
	add_child(_rain)
	_rain.play()
	for i in range(1, 6):
		_thunder.append(_load(DIR + "ambience/thunder_%d.mp3" % i, false))
	_streams["whistle"] = _make_whistle()


func _setup_buses() -> void:
	for bus_name in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), "Master")
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = -1.0
		AudioServer.add_bus_effect(master, limiter)
	var sfx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.65
		reverb.damping = 0.55
		reverb.spread = 0.8
		reverb.wet = 0.14
		reverb.dry = 1.0
		AudioServer.add_bus_effect(sfx, reverb)
	var amb := AudioServer.get_bus_index("Ambience")
	if AudioServer.get_bus_effect_count(amb) == 0:
		# We're indoors: the storm is heard through walls and windows.
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 2600.0
		AudioServer.add_bus_effect(amb, lowpass)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -3.0)


func _process(delta: float) -> void:
	if _headless:
		return
	for track: String in _music:
		var p: AudioStreamPlayer = _music[track]
		var current := db_to_linear(p.volume_db)
		var goal: float = _music_target[track]
		var next := move_toward(current, goal, delta / MUSIC_FADE)
		p.volume_db = linear_to_db(maxf(next, 0.0001))
		if goal > 0.0 and not p.playing:
			p.play()
		elif goal == 0.0 and next <= 0.001 and p.playing:
			p.stop()


## Set a named bus volume using a 0..1 linear control value.
func set_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, clampf(linear, 0.0, 1.0))))


## Play a known sound in 2D, or at a world position in 3D.
func play(sound_name: String, at: Vector3 = Vector3.INF) -> void:
	if _headless or not SFX.has(sound_name):
		return
	if sound_name in ["footstep", "footstep_run"]:
		var now := Time.get_ticks_msec()
		if now - _last_step_ms < 120:
			return
		_last_step_ms = now
	var def: Array = SFX[sound_name]
	var stream := _pick(sound_name, def[0])
	if stream == null:
		return
	var volume: float = def[1] + _rng.randf_range(-1.5, 1.0)
	if sound_name == "footstep":
		var player_node := get_parent().get_node_or_null("Player")
		if player_node and player_node.has_method("is_crouching") and player_node.is_crouching():
			volume -= 8.0
	_emit(stream, volume, _rng.randf_range(def[2], def[3]), at)
	if LAYERS.has(sound_name):
		var layer: Array = LAYERS[sound_name]
		_emit(_load(DIR + "sfx/" + layer[0] + ".ogg", false), layer[1], layer[2], at)


func has_sound(sound_name: String) -> bool:
	return SFX.has(sound_name)


## Crossfade to the track for a game mode. "lose" fades music out.
func set_music(mode: String) -> void:
	if _headless or mode == _mode:
		return
	_mode = mode
	var wanted: String = MUSIC.get(mode, "")
	for track: String in _music_target:
		_music_target[track] = MUSIC_LEVEL.get(mode, 0.6) if track == wanted else 0.0
	if wanted != "" and mode in ["title", "win"]:
		(_music[wanted] as AudioStreamPlayer).play()   # restart the theme from the top


## Thunder after a lightning flash: distance delay, louder for stronger flashes.
func thunder(strength: float) -> void:
	if _headless or _thunder.is_empty():
		return
	var s := clampf(strength, 0.0, 1.0)
	await get_tree().create_timer(lerpf(1.6, 0.25, s), true).timeout
	if not is_inside_tree():
		return
	var p := _next_2d()
	p.bus = "Ambience"
	p.stream = _thunder[_rng.randi() % _thunder.size()]
	p.volume_db = lerpf(-10.0, 1.0, s)
	p.pitch_scale = _rng.randf_range(0.9, 1.05)
	p.play()


func _emit(stream: AudioStream, volume: float, pitch: float, at: Vector3) -> void:
	if stream == null:
		return
	if at == Vector3.INF:
		var p := _next_2d()
		p.bus = "SFX"
		p.stream = stream
		p.volume_db = volume
		p.pitch_scale = pitch
		p.play()
	else:
		var p3 := _three_d[_cursor_3d]
		_cursor_3d = (_cursor_3d + 1) % _three_d.size()
		p3.stop()
		p3.global_position = at
		p3.stream = stream
		p3.volume_db = volume + 4.0
		p3.pitch_scale = pitch
		p3.play()


func _next_2d() -> AudioStreamPlayer:
	var p := _two_d[_cursor_2d]
	_cursor_2d = (_cursor_2d + 1) % _two_d.size()
	p.stop()
	return p


func _pick(sound_name: String, files: Array) -> AudioStream:
	if files.is_empty():
		return _streams.get(sound_name)
	return _load(DIR + "sfx/" + files[_rng.randi() % files.size()] + ".ogg", false)


func _load(path: String, looped: bool) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var stream := load(path) as AudioStream
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = looped
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = looped
	_streams[path] = stream
	return stream


## Police whistle: two detuned whistle tones with a fast trill, synthesised once.
func _make_whistle() -> AudioStreamWAV:
	var rate := 44100
	var n := int(rate * 0.75)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / rate
		var trill := 0.5 + 0.5 * sin(TAU * 28.0 * t)
		var hz := lerpf(2650.0, 3050.0, trill)
		phase += TAU * hz / rate
		var env := minf(t / 0.02, 1.0) * clampf((0.75 - t) / 0.08, 0.0, 1.0)
		var breath := (_rng.randf() * 2.0 - 1.0) * 0.08
		var v := (sin(phase) * 0.55 + sin(phase * 2.0) * 0.08 + breath) * env * 0.6
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
