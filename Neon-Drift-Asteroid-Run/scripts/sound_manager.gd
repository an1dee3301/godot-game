extends Node

const MIX_RATE := 22050

var sounds: Dictionary = {}
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sounds["shoot"] = _make_sound(620.0, 330.0, 0.085, 0.03, false)
	sounds["hit_small"] = _make_sound(260.0, 120.0, 0.11, 0.18, true)
	sounds["hit_large"] = _make_sound(145.0, 55.0, 0.21, 0.42, true)
	sounds["ship_down"] = _make_sound(190.0, 38.0, 0.42, 0.62, true)
	sounds["wave"] = _make_sound(360.0, 760.0, 0.28, 0.02, false)
	sounds["extra_life"] = _make_sound(520.0, 1040.0, 0.35, 0.01, false)


func play_sound(sound_name: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	if muted or not sounds.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			child.queue_free()


func _exit_tree() -> void:
	stop_all()
	sounds.clear()


func _make_sound(start_frequency: float, end_frequency: float, duration: float, noise_amount: float, square_wave: bool) -> AudioStreamWAV:
	var frame_count := int(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(start_frequency * 1000.0 + end_frequency * 17.0)

	for i in range(frame_count):
		var progress := float(i) / float(maxi(frame_count - 1, 1))
		var time := float(i) / float(MIX_RATE)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		var phase_value := sin(TAU * frequency * time)
		if square_wave:
			phase_value = 1.0 if phase_value >= 0.0 else -1.0
		var noise := local_rng.randf_range(-1.0, 1.0) * noise_amount
		var envelope := pow(1.0 - progress, 1.8) * minf(progress * 28.0, 1.0)
		var sample := int(clampf((phase_value * (1.0 - noise_amount) + noise) * envelope * 0.34, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample)

	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = MIX_RATE
	wave.stereo = false
	wave.data = bytes
	return wave
