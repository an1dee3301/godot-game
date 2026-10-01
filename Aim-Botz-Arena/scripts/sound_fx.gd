class_name SoundFX
extends Node
## Procedural sound effects. Every sound is synthesised at startup, so the
## project needs no audio files.

const SAMPLE_RATE := 22050
const POOL_SIZE := 16
const POOL_3D_SIZE := 12

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_index := 0
var _pool_3d_index := 0
var _audio_enabled := true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_audio_enabled = DisplayServer.get_name() != "headless"
	_rng.seed = 2026
	_build_streams()
	for index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	for index in POOL_3D_SIZE:
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.unit_size = 12.0
		player_3d.max_distance = 90.0
		add_child(player_3d)
		_pool_3d.append(player_3d)


func _exit_tree() -> void:
	for player in _pool:
		player.stop()
		player.stream = null
	for player_3d in _pool_3d:
		player_3d.stop()
		player_3d.stream = null


func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)


func play(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _audio_enabled or not _streams.has(sound_name):
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func play_at(sound_name: String, world_position: Vector3, volume_db := 0.0, pitch := 1.0) -> void:
	if not _audio_enabled or not _streams.has(sound_name):
		return
	var player := _pool_3d[_pool_3d_index]
	_pool_3d_index = (_pool_3d_index + 1) % POOL_3D_SIZE
	player.stream = _streams[sound_name]
	player.global_position = world_position
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _build_streams() -> void:
	# Weapons: a filtered noise crack layered over a low thump.
	var rifle := _mix(_synth(0.20, 0.0, 0.0, 0.0, 1.0, 22.0, 0.45), _synth(0.16, 150.0, 55.0, 1.0, 0.0, 20.0, 1.0), 0.0, 0.8)
	_streams["rifle"] = _to_wav(_normalize(rifle, 0.8))
	var pistol := _mix(_synth(0.30, 0.0, 0.0, 0.0, 1.0, 13.0, 0.3), _synth(0.25, 120.0, 40.0, 1.0, 0.0, 12.0, 1.0), 0.0, 1.0)
	_streams["pistol"] = _to_wav(_normalize(pistol, 0.85))
	var bot_shot := _mix(_synth(0.22, 0.0, 0.0, 0.0, 1.0, 18.0, 0.18), _synth(0.18, 130.0, 50.0, 1.0, 0.0, 16.0, 1.0), 0.0, 0.7)
	_streams["bot_shot"] = _to_wav(_normalize(bot_shot, 0.7))
	_streams["dry_fire"] = _to_wav(_normalize(_synth(0.05, 2200.0, 1500.0, 0.6, 0.6, 90.0, 0.7), 0.4))
	_streams["switch"] = _to_wav(_normalize(_click(1400.0, 0.06), 0.4))

	# Reload: magazine out (two clicks) and magazine in + bolt (clack).
	var mag_out := _mix(_click(900.0, 0.07), _click(650.0, 0.08), 0.09, 1.0)
	_streams["reload_out"] = _to_wav(_normalize(mag_out, 0.55))
	var mag_in := _mix(_click(500.0, 0.09), _click(1300.0, 0.05), 0.07, 0.8)
	mag_in = _mix(mag_in, _click(780.0, 0.1), 0.28, 1.0)
	_streams["reload_in"] = _to_wav(_normalize(mag_in, 0.6))

	_streams["footstep"] = _to_wav(_normalize(_synth(0.11, 95.0, 60.0, 0.5, 1.0, 38.0, 0.12), 0.45))
	_streams["land"] = _to_wav(_normalize(_synth(0.18, 80.0, 40.0, 0.8, 1.0, 22.0, 0.1), 0.55))
	_streams["hit"] = _to_wav(_normalize(_synth(0.06, 1500.0, 1300.0, 1.0, 0.1, 55.0, 0.8), 0.45))
	var dink := _mix(_synth(0.38, 2400.0, 2350.0, 1.0, 0.0, 11.0, 1.0), _synth(0.3, 3650.0, 3600.0, 0.6, 0.0, 15.0, 1.0), 0.0, 0.6)
	_streams["headshot"] = _to_wav(_normalize(dink, 0.55))
	_streams["kill"] = _to_wav(_normalize(_synth(0.22, 880.0, 1320.0, 1.0, 0.0, 12.0, 1.0), 0.4))
	_streams["hurt"] = _to_wav(_normalize(_synth(0.26, 170.0, 70.0, 1.0, 0.45, 12.0, 0.2), 0.65))
	_streams["explosion"] = _to_wav(_normalize(_mix(_synth(1.3, 0.0, 0.0, 0.0, 1.0, 3.2, 0.07), _synth(0.9, 70.0, 28.0, 1.0, 0.0, 4.5, 1.0), 0.0, 0.9), 0.95))
	_streams["pickup"] = _to_wav(_normalize(_mix(_synth(0.12, 660.0, 660.0, 1.0, 0.0, 10.0, 1.0), _synth(0.2, 990.0, 1320.0, 1.0, 0.0, 9.0, 1.0), 0.09, 1.0), 0.45))
	_streams["door"] = _to_wav(_normalize(_mix(_synth(0.7, 0.0, 0.0, 0.0, 1.0, 2.8, 0.04), _synth(0.7, 85.0, 70.0, 0.5, 0.0, 3.0, 1.0), 0.0, 1.0), 0.5))
	_streams["wave"] = _to_wav(_normalize(_mix(_synth(0.16, 740.0, 740.0, 1.0, 0.0, 8.0, 1.0), _synth(0.3, 988.0, 988.0, 1.0, 0.0, 7.0, 1.0), 0.18, 1.0), 0.45))
	_streams["spawn"] = _to_wav(_normalize(_synth(0.35, 300.0, 1200.0, 1.0, 0.15, 6.0, 0.5), 0.3))
	_streams["ui"] = _to_wav(_normalize(_click(1900.0, 0.05), 0.3))

	var win := PackedFloat32Array()
	for step in 4:
		var note := 523.25 * pow(2.0, [0, 4, 7, 12][step] / 12.0)
		win = _mix(win, _synth(0.35, note, note, 1.0, 0.0, 6.0, 1.0), step * 0.13, 1.0)
	_streams["win"] = _to_wav(_normalize(win, 0.5))
	var lose := PackedFloat32Array()
	for step in 3:
		var low_note := 392.0 * pow(2.0, [0, -3, -7][step] / 12.0)
		lose = _mix(lose, _synth(0.45, low_note, low_note * 0.97, 1.0, 0.05, 5.0, 1.0), step * 0.22, 1.0)
	_streams["lose"] = _to_wav(_normalize(lose, 0.5))


func _click(frequency: float, duration: float) -> PackedFloat32Array:
	return _synth(duration, frequency, frequency * 0.7, 0.7, 0.8, 70.0, 0.6, 0.001)


## Decaying tone + low-passed noise. `lowpass` is a one-pole filter
## coefficient (1.0 = unfiltered, small = muffled).
func _synth(
	duration: float,
	tone_start: float,
	tone_end: float,
	tone_volume: float,
	noise_volume: float,
	decay: float,
	lowpass: float,
	attack := 0.003
) -> PackedFloat32Array:
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
