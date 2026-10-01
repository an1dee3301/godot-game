class_name SoundFX
extends Node
## Procedural cues and an original doll melody, generated without audio assets.

const SAMPLE_RATE := 22050
const POOL_SIZE := 16

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _loop_player: AudioStreamPlayer
var _audio_enabled := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 17813
	_build_streams()
	_audio_enabled = DisplayServer.get_name() != "headless"
	if not _audio_enabled:
		return
	for index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_loop_player = AudioStreamPlayer.new()
	add_child(_loop_player)


func _exit_tree() -> void:
	stop_loop()
	for player in _pool:
		player.stop()
		player.stream = null


func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)


func play(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _audio_enabled or not has_sound(sound_name):
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	player.stop()
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = maxf(pitch, 0.01)
	player.play()


func play_loop(sound_name: String) -> void:
	if not _audio_enabled or not has_sound(sound_name) or _loop_player == null:
		return
	var stream: AudioStreamWAV = _streams[sound_name]
	if stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		return
	if _loop_player.playing and _loop_player.stream == stream:
		return
	_loop_player.stop()
	_loop_player.stream = stream
	_loop_player.volume_db = -10.0
	_loop_player.play()


func stop_loop() -> void:
	if _loop_player != null:
		_loop_player.stop()
		_loop_player.stream = null


func _build_streams() -> void:
	_store("beep", _synth(0.16, 660.0, 660.0, 1.0, 0.0, 17.0, 1.0), 0.34)
	_store("go", _mix(_synth(0.2, 880.0, 880.0, 1.0, 0.0, 13.0, 1.0), _synth(0.24, 1320.0, 1320.0, 0.7, 0.0, 12.0, 1.0), 0.09, 1.0), 0.5)
	_store("blue", _mix(_synth(0.42, 587.33, 587.33, 1.0, 0.0, 6.0, 1.0), _synth(0.5, 880.0, 880.0, 1.0, 0.0, 5.5, 1.0), 0.16, 1.0), 0.55)
	_store("warn", _mix(_click(1300.0, 0.09), _click(780.0, 0.11), 0.14, 0.9), 0.5)
	var red := _mix(_synth(0.7, 155.0, 115.0, 1.0, 0.0, 2.8, 1.0), _synth(0.65, 162.0, 122.0, 0.75, 0.1, 3.0, 0.3), 0.0, 1.0)
	_store("red", red, 0.62)
	var zap := _mix(_synth(0.31, 1900.0, 95.0, 1.0, 0.22, 12.0, 0.6), _synth(0.3, 90.0, 42.0, 0.8, 0.5, 13.0, 0.16), 0.1, 0.85)
	_store("zap", zap, 0.65)
	var finish := PackedFloat32Array()
	for index in 4:
		var note: float = [523.25, 659.25, 783.99, 1046.5][index]
		finish = _mix(finish, _synth(0.5, note, note, 1.0, 0.0, 5.0, 1.0), index * 0.15, 1.0)
	_store("finish", finish, 0.57)
	var shove := _mix(_synth(0.25, 540.0, 115.0, 0.3, 1.0, 13.0, 0.18), _synth(0.26, 110.0, 50.0, 1.0, 0.25, 15.0, 0.12), 0.11, 1.0)
	_store("shove", shove, 0.53)
	_store("step", _synth(0.11, 105.0, 65.0, 0.35, 0.9, 36.0, 0.1), 0.22)
	_store("join", _mix(_synth(0.14, 440.0, 660.0, 1.0, 0.0, 17.0, 1.0), _synth(0.16, 880.0, 880.0, 0.7, 0.0, 14.0, 1.0), 0.1, 1.0), 0.4)
	_store("leave", _mix(_synth(0.14, 660.0, 550.0, 1.0, 0.0, 15.0, 1.0), _synth(0.2, 392.0, 330.0, 0.8, 0.0, 12.0, 1.0), 0.1, 1.0), 0.38)
	_store("ui", _click(1600.0, 0.055), 0.27)
	var win := PackedFloat32Array()
	for index in 5:
		var note: float = [523.25, 659.25, 783.99, 987.77, 1046.5][index]
		win = _mix(win, _synth(0.48, note, note, 1.0, 0.0, 4.5, 1.0), index * 0.17, 1.0)
	_store("win", win, 0.6)
	_store("land", _synth(0.22, 95.0, 42.0, 0.8, 0.8, 17.0, 0.11), 0.49)

	var melody := PackedFloat32Array()
	melody.resize(int(2.5 * SAMPLE_RATE))
	var notes: Array[float] = [587.33, 739.99, 659.25, 493.88, 554.37]
	for index in notes.size():
		var note := _synth(0.38, notes[index], notes[index], 1.0, 0.0, 7.0, 1.0, 0.015)
		melody = _mix(melody, note, index * 0.42, 1.0)
		melody = _mix(melody, _synth(0.26, notes[index] * 2.0, notes[index] * 2.0, 0.18, 0.0, 10.0, 1.0), index * 0.42, 1.0)
	var loop_stream := _to_wav(_normalize(melody, 0.37))
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_streams["melody"] = loop_stream


func _store(sound_name: String, samples: PackedFloat32Array, peak: float) -> void:
	_streams[sound_name] = _to_wav(_normalize(samples, peak))


func _click(frequency: float, duration: float) -> PackedFloat32Array:
	return _synth(duration, frequency, frequency * 0.65, 0.65, 0.8, 60.0, 0.65, 0.001)


func _synth(duration: float, tone_start: float, tone_end: float, tone_volume: float, noise_volume: float, decay: float, lowpass: float, attack := 0.003) -> PackedFloat32Array:
	var count := int(duration * SAMPLE_RATE)
	var output := PackedFloat32Array()
	output.resize(count)
	var phase := 0.0
	var filtered := 0.0
	var noise_gain := 1.0 / sqrt(maxf(lowpass / (2.0 - lowpass), 0.0005))
	for index in count:
		var time := float(index) / SAMPLE_RATE
		var progress := float(index) / float(count)
		phase += TAU * lerpf(tone_start, tone_end, progress) / SAMPLE_RATE
		filtered += (_rng.randf_range(-1.0, 1.0) - filtered) * lowpass
		var envelope := minf(time / attack, 1.0) * exp(-decay * time)
		output[index] = (sin(phase) * tone_volume + filtered * noise_gain * 0.35 * noise_volume) * envelope
	return output


func _mix(base: PackedFloat32Array, layer: PackedFloat32Array, offset_seconds: float, gain: float) -> PackedFloat32Array:
	var offset := int(offset_seconds * SAMPLE_RATE)
	var output := base.duplicate()
	if output.size() < offset + layer.size():
		output.resize(offset + layer.size())
	for index in layer.size():
		output[offset + index] += layer[index] * gain
	return output


func _normalize(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var highest := 0.0001
	for sample in samples:
		highest = maxf(highest, absf(sample))
	var output := samples.duplicate()
	for index in output.size():
		output[index] = output[index] / highest * peak
	return output


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, clampi(int(samples[index] * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = bytes
	return wav
