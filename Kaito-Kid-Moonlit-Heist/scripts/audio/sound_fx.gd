class_name SoundFX
extends Node
## Procedural 22.05 kHz sound stage for effects, weather, and adaptive jazz.

const RATE := 22050
const FADE := 1.5
const NAMES := ["footstep", "footstep_run", "land", "card_throw", "card_hit", "card_stick",
	"smoke", "guard_huh", "guard_alert", "whistle", "baton_swing", "hit_player",
	"guard_down", "jewel_steal", "laser_trip", "laser_off", "camera_alert",
	"pickup_rose", "pickup_smoke", "exit_unlock", "ui_click", "win", "lose"]
const MODES := ["title", "sneak", "alert", "chase", "escape", "win", "lose"]

var _headless := false
var _sounds: Dictionary = {}
var _scores: Dictionary = {}
var _thunder: Array[AudioStreamWAV] = []
var _two_d: Array[AudioStreamPlayer] = []
var _three_d: Array[AudioStreamPlayer3D] = []
var _decks: Array[AudioStreamPlayer] = []
var _ambience: AudioStreamPlayer
var _cursor_2d := 0
var _cursor_3d := 0
var _deck := -1
var _mode := ""
var _fade_time := FADE
var _rng := RandomNumberGenerator.new()
var _wave_sine := PackedFloat32Array()
var _wave_rhodes := PackedFloat32Array()
var _wave_brass := PackedFloat32Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	if _headless:
		return
	_rng.randomize()
	_build_waves()
	for name: String in NAMES:
		_sounds[name] = _effect(name)
	for variant in range(3):
		_thunder.append(_storm_crack(variant))
	for mode: String in MODES:
		_scores[mode] = _score(mode)
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "Effect2D%d" % i
		player.volume_db = -5.0
		add_child(player)
		_two_d.append(player)
	for i in range(12):
		var player := AudioStreamPlayer3D.new()
		player.name = "Effect3D%d" % i
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		player.unit_size = 6.0
		player.max_distance = 45.0
		add_child(player)
		_three_d.append(player)
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.volume_db = -80.0
		add_child(player)
		_decks.append(player)
	_ambience = AudioStreamPlayer.new()
	_ambience.name = "RainWind"
	_ambience.stream = _weather_loop()
	_ambience.volume_db = -17.0
	add_child(_ambience)
	_ambience.play()


func _process(delta: float) -> void:
	if _headless or _deck < 0 or _fade_time >= FADE:
		return
	_fade_time = minf(FADE, _fade_time + delta)
	var amount := _fade_time / FADE
	_decks[_deck].volume_db = linear_to_db(maxf(0.0001, amount)) - 15.0
	_decks[1 - _deck].volume_db = linear_to_db(maxf(0.0001, 1.0 - amount)) - 15.0
	if _fade_time >= FADE:
		_decks[1 - _deck].stop()


## Play a known sound in 2D, or at a world position in 3D.
func play(sound_name: String, at: Vector3 = Vector3.INF) -> void:
	if _headless or not _sounds.has(sound_name):
		return
	var pitch := 1.0
	if sound_name in ["footstep", "footstep_run", "land"]:
		pitch = _rng.randf_range(0.92, 1.09)
	elif sound_name in ["card_throw", "card_hit"]:
		pitch = _rng.randf_range(0.96, 1.05)
	if at == Vector3.INF:
		var p := _two_d[_cursor_2d]
		_cursor_2d = (_cursor_2d + 1) % _two_d.size()
		p.stop()
		p.stream = _sounds[sound_name]
		p.volume_db = -5.0
		p.pitch_scale = pitch
		p.play()
	else:
		var p := _three_d[_cursor_3d]
		_cursor_3d = (_cursor_3d + 1) % _three_d.size()
		p.stop()
		p.global_position = at
		p.stream = _sounds[sound_name]
		p.pitch_scale = pitch
		p.play()


## Returns true for every effect in the public sound list, including headless.
func has_sound(sound_name: String) -> bool:
	return NAMES.has(sound_name)


## Crossfade the procedural score to a named mode.
func set_music(mode: String) -> void:
	if _headless or not _scores.has(mode) or mode == _mode:
		return
	_mode = mode
	_deck = 1 - _deck if _deck >= 0 else 0
	var p := _decks[_deck]
	p.stop()
	p.stream = _scores[mode]
	p.volume_db = -80.0
	p.play()
	_fade_time = 0.0


## Delay a random thunder variant after a flash; strength controls its level.
func thunder(strength: float) -> void:
	if _headless:
		return
	_thunder_after(_rng.randf_range(0.3, 1.5), _rng.randi_range(0, 2), clampf(strength, 0.0, 1.0))


func _thunder_after(delay: float, variant: int, strength: float) -> void:
	await get_tree().create_timer(delay, true).timeout
	if not is_inside_tree():
		return
	var p := _two_d[_cursor_2d]
	_cursor_2d = (_cursor_2d + 1) % _two_d.size()
	p.stop()
	p.stream = _thunder[variant]
	p.pitch_scale = _rng.randf_range(0.9, 1.05)
	p.volume_db = linear_to_db(maxf(0.04, strength)) - 4.0
	p.play()


func _build_waves() -> void:
	_wave_sine.resize(2048)
	_wave_rhodes.resize(2048)
	_wave_brass.resize(2048)
	for i in range(2048):
		var x := TAU * float(i) / 2048.0
		_wave_sine[i] = sin(x)
		_wave_rhodes[i] = sin(x) * 0.77 + sin(2.0 * x) * 0.17 + sin(3.0 * x) * 0.06
		_wave_brass[i] = sin(x) * 0.49 + sin(2.0 * x) * 0.25 + sin(3.0 * x) * 0.16 + sin(4.0 * x) * 0.1


func _buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(maxi(1, roundi(seconds * RATE)))
	return b


func _wav(b: PackedFloat32Array, looped: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(b.size() * 2)
	for i in range(b.size()):
		var sample := clampi(roundi(b[i] * 32767.0), -32768, 32767) & 65535
		data[2 * i] = sample & 255
		data[2 * i + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = b.size()
	return stream


func _tone(b: PackedFloat32Array, start: float, duration: float, from_hz: float, to_hz: float, volume: float, voice: int = 0, decay: float = 2.0) -> void:
	var first := maxi(0, roundi(start * RATE))
	var count := mini(roundi(duration * RATE), b.size() - first)
	if count <= 0:
		return
	var table := _wave_sine if voice == 0 else _wave_rhodes if voice == 1 else _wave_brass
	var phase := 0.0
	for i in range(count):
		var x := float(i) / count
		phase = fmod(phase + lerpf(from_hz, to_hz, x) * 2048.0 / RATE, 2048.0)
		var env := minf(1.0, x * 85.0) * pow(1.0 - x, decay)
		b[first + i] += table[int(phase)] * env * volume


func _pad(b: PackedFloat32Array, start: float, duration: float, hz: float, volume: float) -> void:
	var first := maxi(0, roundi(start * RATE))
	var count := mini(roundi(duration * RATE), b.size() - first)
	var phase := 0.0
	for i in range(count):
		var x := float(i) / count
		phase = fmod(phase + hz * 2048.0 / RATE, 2048.0)
		b[first + i] += _wave_rhodes[int(phase)] * volume * minf(1.0, x * 8.0) * minf(1.0, (1.0 - x) * 8.0)


func _noise(b: PackedFloat32Array, start: float, duration: float, volume: float, cutoff: float, decay: float, seed: int) -> void:
	var first := maxi(0, roundi(start * RATE))
	var count := mini(roundi(duration * RATE), b.size() - first)
	var state := seed | 1
	var low := 0.0
	for i in range(count):
		state = (state * 1664525 + 1013904223) & 2147483647
		low += (float(state) / 1073741824.0 - 1.0 - low) * cutoff
		var x := float(i) / count
		b[first + i] += low * volume * minf(1.0, x * 130.0) * pow(1.0 - x, decay)


func _chord(b: PackedFloat32Array, start: float, duration: float, root: float, intervals: Array[int], volume: float, voice: int = 1) -> void:
	for interval: int in intervals:
		var hz := root * pow(2.0, float(interval) / 12.0)
		_tone(b, start, duration, hz, hz, volume, voice, 1.3)


func _effect(name: String) -> AudioStreamWAV:
	var length := 0.55
	if name in ["footstep", "footstep_run", "pickup_smoke", "ui_click"]:
		length = 0.18
	elif name in ["land", "card_hit", "card_stick", "baton_swing"]:
		length = 0.34
	elif name in ["guard_alert", "whistle", "hit_player", "laser_trip"]:
		length = 0.85
	elif name in ["guard_down", "jewel_steal", "exit_unlock", "win", "lose"]:
		length = 2.2
	var b := _buffer(length)
	match name:
		"footstep":
			_noise(b, 0.0, 0.1, 0.3, 0.13, 4.0, 11)
			_tone(b, 0.0, 0.1, 170.0, 95.0, 0.13, 1, 4.0)
			_noise(b, 0.05, 0.07, 0.14, 0.35, 5.0, 17)
		"footstep_run":
			_noise(b, 0.0, 0.15, 0.56, 0.16, 3.0, 13)
			_tone(b, 0.0, 0.15, 135.0, 65.0, 0.29, 1, 3.0)
		"land":
			_noise(b, 0.0, 0.27, 0.55, 0.09, 3.0, 51)
			_tone(b, 0.0, 0.27, 110.0, 45.0, 0.43, 1, 2.4)
		"card_throw":
			_noise(b, 0.0, 0.28, 0.36, 0.55, 0.8, 37)
			_tone(b, 0.08, 0.24, 390.0, 1160.0, 0.18)
			_noise(b, 0.25, 0.055, 0.4, 0.9, 3.0, 81)
		"card_hit":
			_noise(b, 0.0, 0.2, 0.55, 0.28, 3.0, 89)
			_tone(b, 0.0, 0.21, 250.0, 75.0, 0.43, 2, 3.0)
		"card_stick":
			_tone(b, 0.0, 0.25, 210.0, 70.0, 0.48, 1, 3.0)
			_noise(b, 0.0, 0.14, 0.33, 0.13, 3.0, 91)
		"smoke":
			_tone(b, 0.0, 0.18, 220.0, 55.0, 0.55, 1, 3.0)
			_noise(b, 0.02, 0.5, 0.45, 0.4, 0.75, 93)
		"guard_huh":
			_tone(b, 0.0, 0.28, 150.0, 230.0, 0.32, 2, 1.5)
			_tone(b, 0.09, 0.34, 540.0, 720.0, 0.14, 1, 1.8)
		"guard_alert":
			_chord(b, 0.0, 0.51, 349.23, [0, 7, 12], 0.26, 2)
			_tone(b, 0.0, 0.5, 880.0, 820.0, 0.31, 2, 0.8)
			_noise(b, 0.0, 0.09, 0.34, 0.7, 4.0, 111)
		"whistle":
			for i in range(8):
				var hz := 1570.0 if i % 2 == 0 else 1820.0
				_tone(b, i * 0.085, 0.13, hz, hz + 90.0, 0.18, 0, 0.55)
		"baton_swing":
			_noise(b, 0.0, 0.27, 0.4, 0.36, 0.7, 115)
			_tone(b, 0.0, 0.24, 130.0, 510.0, 0.13)
		"hit_player":
			_tone(b, 0.0, 0.35, 135.0, 48.0, 0.58, 1, 2.8)
			_noise(b, 0.0, 0.3, 0.54, 0.11, 2.6, 119)
			_tone(b, 0.14, 0.45, 165.0, 93.0, 0.23, 2, 1.4)
		"guard_down":
			_tone(b, 0.0, 0.42, 175.0, 52.0, 0.55, 1, 2.5)
			_noise(b, 0.0, 0.35, 0.48, 0.1, 2.0, 121)
			for i in range(6):
				var hz := 880.0 * pow(2.0, float([0, 3, 7, 12, 7, 3][i]) / 12.0)
				_tone(b, 0.4 + i * 0.21, 0.38, hz, hz * 0.92, 0.12, 1)
		"jewel_steal":
			for i in range(8):
				var hz := 523.25 * pow(2.0, float([0, 3, 7, 10, 12, 15, 19, 24][i]) / 12.0)
				_tone(b, 0.1 + i * 0.16, 0.55, hz, hz, 0.17, 1)
				_noise(b, 0.11 + i * 0.16, 0.04, 0.13, 0.83, 2.0, 130 + i)
			_chord(b, 1.3, 0.85, 523.25, [0, 3, 7, 10], 0.12)
		"laser_trip":
			_tone(b, 0.0, 0.42, 1720.0, 220.0, 0.38, 2)
			_noise(b, 0.0, 0.2, 0.34, 0.75, 1.0, 139)
			_tone(b, 0.32, 0.48, 660.0, 840.0, 0.2, 0, 0.8)
		"laser_off":
			_tone(b, 0.0, 0.53, 1030.0, 95.0, 0.35, 1, 0.8)
			_noise(b, 0.0, 0.5, 0.13, 0.24, 1.3, 141)
		"camera_alert":
			_tone(b, 0.0, 0.14, 1080.0, 1080.0, 0.35, 0, 0.5)
			_tone(b, 0.23, 0.14, 1270.0, 1270.0, 0.35, 0, 0.5)
		"pickup_rose":
			_tone(b, 0.0, 0.48, 783.99, 783.99, 0.25, 1)
			_tone(b, 0.11, 0.38, 1174.66, 1174.66, 0.21, 1)
		"pickup_smoke":
			_tone(b, 0.0, 0.12, 430.0, 240.0, 0.24, 1, 3.0)
			_noise(b, 0.0, 0.08, 0.15, 0.54, 4.0, 151)
		"exit_unlock":
			_chord(b, 0.0, 1.6, 261.63, [0, 4, 7, 11, 14], 0.19, 2)
			for i in range(4):
				var hz := 523.25 * pow(2.0, float([0, 4, 7, 12][i]) / 12.0)
				_tone(b, i * 0.2, 0.62, hz, hz, 0.16, 1)
			_tone(b, 0.8, 1.3, 500.0, 940.0, 0.13, 0, 0.3)
		"ui_click":
			_tone(b, 0.0, 0.08, 930.0, 540.0, 0.24, 1, 3.0)
			_noise(b, 0.0, 0.035, 0.1, 0.7, 3.0, 153)
		"win":
			for i in range(6):
				var hz: float = [392.0, 493.88, 587.33, 783.99, 880.0, 1046.5][i]
				_tone(b, i * 0.24, 0.44, hz, hz, 0.24, 2, 1.25)
			_chord(b, 1.42, 0.77, 523.25, [0, 4, 7, 11], 0.19, 2)
		"lose":
			for i in range(4):
				var hz: float = [392.0, 329.63, 261.63, 196.0][i]
				_tone(b, i * 0.4, 0.62, hz, hz * 0.78, 0.27, 2, 0.9)
	return _wav(b)


func _storm_crack(variant: int) -> AudioStreamWAV:
	var length: float = [3.5, 4.5, 5.7][variant]
	var b := _buffer(length)
	var state := 271 + variant * 103
	var brown := 0.0
	var low := 0.0
	for i in range(b.size()):
		state = (state * 1664525 + 1013904223) & 2147483647
		var white := float(state) / 1073741824.0 - 1.0
		brown = clampf(brown + white * 0.018, -1.0, 1.0) * 0.998
		low += (white - low) * 0.025
		var t := float(i) / RATE
		var env := minf(1.0, t * 7.0) * pow(maxf(0.0, 1.0 - t / length), 1.2)
		b[i] = (brown * 0.42 + low * 0.26) * (0.65 + 0.35 * sin(t * 5.3 + variant)) * env
	_noise(b, 0.0, 0.12, 0.88, 0.92, 1.8, 239 + variant)
	_noise(b, 0.1 + variant * 0.12, 0.48, 0.47, 0.23, 1.4, 249 + variant)
	return _wav(b)


func _weather_loop() -> AudioStreamWAV:
	var b := _buffer(8.0)
	var state := 991
	var rain := 0.0
	var wind := 0.0
	for i in range(b.size()):
		state = (state * 1664525 + 1013904223) & 2147483647
		var white := float(state) / 1073741824.0 - 1.0
		rain += (white - rain) * 0.36
		wind += (white - wind) * 0.014
		var t := float(i) / RATE
		var gust := 0.5 + 0.23 * sin(TAU * t / 8.0) + 0.18 * sin(TAU * t * 3.0 / 8.0)
		b[i] = rain * 0.15 + wind * gust * 0.3
	for drop in range(145):
		var t := float((drop * 631 + drop * drop * 97) % 8000) / 1000.0
		_tone(b, t, 0.018, 1100.0 + float(drop % 9) * 115.0, 500.0, 0.014, 1, 3.0)
	_noise(b, 2.1, 3.7, 0.035, 0.016, 1.0, 1007)
	var seam := roundi(0.12 * RATE)
	for i in range(seam):
		b[b.size() - seam + i] = lerpf(b[b.size() - seam + i], b[i], float(i) / seam)
	return _wav(b, true)


func _score(mode: String) -> AudioStreamWAV:
	var driving := mode in ["chase", "escape"]
	var beat := 60.0 / (154.0 if driving else 122.0)
	var b := _buffer(8.0 * 4.0 * beat)
	var roots: Array[float] = [73.42, 73.42, 58.27, 58.27, 65.41, 65.41, 55.0, 65.41]
	if mode == "win":
		roots = [65.41, 65.41, 73.42, 73.42, 87.31, 87.31, 65.41, 65.41]
	elif mode == "lose":
		roots = [73.42, 65.41, 58.27, 55.0, 55.0, 55.0, 55.0, 55.0]
	for bar in range(8):
		if mode == "lose" and bar >= 2:
			continue
		var start := bar * 4.0 * beat
		var root := roots[bar]
		var chord_notes: Array[int] = [0, 3, 7, 10]
		if bar % 4 >= 2:
			chord_notes = [0, 4, 7, 11]
		if mode == "lose":
			_tone(b, start, beat * 3.6, root * 4.0, root * 3.2, 0.14, 2, 0.7)
			continue
		if mode in ["title", "win"]:
			_chord(b, start, beat * 1.25, root * 4.0, chord_notes, 0.044)
			_chord(b, start + beat * 2.5, beat * 0.9, root * 4.0, chord_notes, 0.033)
		elif driving:
			_chord(b, start + beat * 1.5, beat * 0.45, root * 4.0, chord_notes, 0.036, 2)
			_chord(b, start + beat * 3.5, beat * 0.43, root * 4.0, chord_notes, 0.036, 2)
		elif mode == "alert":
			for semitone: int in chord_notes:
				_pad(b, start, beat * 3.95, root * 4.0 * pow(2.0, float(semitone) / 12.0), 0.015)
		for pulse in range(4):
			var time := start + pulse * beat
			var bass_hz := root * pow(2.0, float([0, 7, 10, 7][pulse]) / 12.0)
			_tone(b, time, beat * (0.83 if driving else 0.68), bass_hz, bass_hz * 0.995, 0.13 if driving else 0.1, 1, 1.4)
			if driving:
				_tone(b, time + beat * 0.5, beat * 0.35, bass_hz, bass_hz, 0.052, 1)
			elif pulse == 1 or pulse == 3:
				var note := root * (8.0 if mode in ["title", "win"] else 4.0) * pow(2.0, float([3, 7][int(pulse / 2)]) / 12.0)
				_tone(b, time + beat * 0.53, beat * 0.43, note, note, 0.033, 1)
		for eighth in range(8):
			var hat_time := start + (eighth + (0.12 if eighth % 2 else 0.0)) * beat * 0.5
			_noise(b, hat_time, 0.055, 0.033 if driving else 0.021, 0.66, 2.5, bar * 17 + eighth * 31 + 1901)
		if driving or mode in ["title", "win"]:
			for backbeat in [1, 3]:
				_noise(b, start + backbeat * beat, 0.12, 0.09 if driving else 0.044, 0.27, 1.5, bar * 67 + backbeat * 13 + 2301)
		if mode == "escape":
			for half in range(2):
				_tone(b, start + half * beat * 2.0, beat * 1.85, 440.0 if half == 0 else 760.0, 760.0 if half == 0 else 440.0, 0.048, 0, 0.1)
	if mode == "win":
		_chord(b, 7.0 * 4.0 * beat, beat * 3.8, 261.63, [0, 4, 7, 11], 0.045, 2)
	return _wav(b, true)
