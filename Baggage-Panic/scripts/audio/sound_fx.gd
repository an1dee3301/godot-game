class_name SoundFX
extends Node
## Procedural 22.05 kHz mono synth and pooled playback.

const SAMPLE_RATE := 22050
const POOL_SIZE := 8

var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _flap_players: Array[AudioStreamPlayer] = []
var _flap_cursor := 0
var _last_flap_msec := 0
var _music_player: AudioStreamPlayer
var _next_player := 0
var _headless := false
var _music_intensity := 0.0


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	_build_sounds()
	if _headless:
		return
	for _index in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)
	for _index in 3:
		var flap_player := AudioStreamPlayer.new()
		flap_player.volume_db = -25.0
		flap_player.stream = _sounds["flap"]
		add_child(flap_player)
		_flap_players.append(flap_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -22.0
	_music_player.stream = _make_music()
	add_child(_music_player)


func has_sound(sound_name: String) -> bool:
	return _sounds.has(sound_name)


func play(sound_name: String) -> void:
	if _headless or not _sounds.has(sound_name) or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = _sounds[sound_name]
	player.pitch_scale = 1.0
	player.play()


func play_flap() -> void:
	if _headless or _flap_players.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - _last_flap_msec < 28:
		return
	_last_flap_msec = now
	var player := _flap_players[_flap_cursor]
	_flap_cursor = (_flap_cursor + 1) % _flap_players.size()
	player.pitch_scale = randf_range(0.92, 1.09)
	player.play()


func start_music() -> void:
	if _music_player != null and not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()


func set_music_intensity(amount: float) -> void:
	_music_intensity = clampf(amount, 0.0, 1.0)
	if _music_player != null:
		_music_player.pitch_scale = 1.0 + _music_intensity * 0.17


func _build_sounds() -> void:
	_sounds["jump"] = _tone([360.0, 750.0], 0.25, "sine", 0.6)
	_sounds["slide"] = _tone([680.0, 120.0], 0.22, "noise", 0.48)
	_sounds["lane"] = _tone([310.0, 240.0], 0.10, "square", 0.34)
	_sounds["tag"] = _tone([880.0, 1320.0], 0.20, "sine", 0.48)
	_sounds["passport"] = _notes([880.0, 1175.0], 0.14, "sine", 0.52)
	_sounds["shield_get"] = _tone([390.0, 1050.0], 0.37, "sine", 0.49)
	_sounds["shield_break"] = _tone([1500.0, 170.0], 0.38, "noise", 0.52)
	_sounds["boost"] = _notes([523.25, 659.25, 783.99, 1046.5], 0.10, "square", 0.30)
	_sounds["hit"] = _tone([130.0, 55.0], 0.23, "noise", 0.62)
	_sounds["death"] = _death_sound()
	_sounds["checkpoint"] = _notes([783.99, 587.33, 880.0, 659.25], 0.17, "sine", 0.5)
	_sounds["route_ok"] = _notes([659.25, 783.99, 1046.5], 0.13, "sine", 0.5)
	_sounds["route_bad"] = _notes([220.0, 185.0], 0.22, "square", 0.5)
	_sounds["click"] = _tone([710.0, 410.0], 0.055, "square", 0.26)
	_sounds["flap"] = _flap_tick()
	_sounds["level_up"] = _notes([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.11, "sine", 0.48)


func _tone(frequencies: Array[float], duration: float, timbre: String, volume: float) -> AudioStreamWAV:
	var count := maxi(1, roundi(duration * SAMPLE_RATE))
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var phase := 0.0
	for index in range(count):
		var progress := float(index) / float(count)
		var frequency := lerpf(frequencies[0], frequencies[1], progress)
		phase += frequency / SAMPLE_RATE
		var envelope := minf(1.0, progress * 60.0) * pow(1.0 - progress, 1.7)
		var value := _wave(phase, timbre, index) * envelope * volume
		_write_sample(samples, index, value)
	return _wav(samples)


func _notes(frequencies: Array[float], note_duration: float, timbre: String, volume: float) -> AudioStreamWAV:
	var samples_per_note := maxi(1, roundi(note_duration * SAMPLE_RATE))
	var samples := PackedByteArray()
	samples.resize(frequencies.size() * samples_per_note * 2)
	for note in range(frequencies.size()):
		var phase := 0.0
		for index in range(samples_per_note):
			var progress := float(index) / float(samples_per_note)
			phase += frequencies[note] / SAMPLE_RATE
			var envelope := minf(1.0, progress * 40.0) * pow(1.0 - progress, 1.5)
			_write_sample(samples, note * samples_per_note + index, _wave(phase, timbre, index) * envelope * volume)
	return _wav(samples)


func _death_sound() -> AudioStreamWAV:
	var crash := _tone([950.0, 60.0], 0.18, "noise", 0.7)
	var trombone := _notes([440.0, 349.2, 293.7, 196.0, 146.8], 0.23, "saw", 0.55)
	var samples := crash.data
	samples.append_array(trombone.data)
	return _wav(samples)


func _flap_tick() -> AudioStreamWAV:
	var count := roundi(0.031 * SAMPLE_RATE)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for index in count:
		var progress := float(index) / float(count)
		var noise := _wave(0.0, "noise", index) * pow(1.0 - progress, 5.0) * 0.55
		var click := (1.0 if index < 18 else -0.5 if index < 31 else 0.0) * 0.24
		_write_sample(samples, index, noise + click)
	return _wav(samples)


func _make_music() -> AudioStreamWAV:
	var beat_length := 0.25
	var beats := 16
	var count := roundi(beat_length * beats * SAMPLE_RATE)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	var bass: Array[float] = [110.0, 0.0, 110.0, 0.0, 146.83, 0.0, 146.83, 0.0, 130.81, 0.0, 130.81, 0.0, 164.81, 0.0, 196.0, 0.0]
	var arp: Array[float] = [440.0, 523.25, 659.25, 523.25, 587.33, 698.46, 880.0, 698.46, 523.25, 659.25, 783.99, 659.25, 659.25, 783.99, 987.77, 783.99]
	for index in range(count):
		var time := float(index) / SAMPLE_RATE
		var step := mini(beats - 1, int(time / beat_length))
		var local := fmod(time, beat_length) / beat_length
		var bass_value := 0.0
		if bass[step] > 0.0:
			bass_value = sin(TAU * bass[step] * time) * pow(1.0 - local, 2.0) * 0.32
		var arp_value := sin(TAU * arp[step] * time) * pow(1.0 - local, 2.6) * 0.15
		var tick := (1.0 if fmod(time, beat_length * 2.0) < 0.012 else 0.0) * 0.055
		_write_sample(samples, index, bass_value + arp_value + tick)
	var stream := _wav(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream


func _wave(phase: float, timbre: String, index: int) -> float:
	match timbre:
		"square": return 0.65 if fmod(phase, 1.0) < 0.5 else -0.65
		"saw": return fmod(phase, 1.0) * 2.0 - 1.0
		"noise":
			var noise := sin(float(index * 127 + 17) * 78.233) * 43758.5453
			return ((noise - floorf(noise)) * 2.0 - 1.0) * 0.7
	return sin(TAU * phase)


func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var signed := clampi(roundi(value * 32767.0), -32768, 32767)
	var unsigned := signed & 0xffff
	data[index * 2] = unsigned & 0xff
	data[index * 2 + 1] = (unsigned >> 8) & 0xff


func _wav(samples: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
