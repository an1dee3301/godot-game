class_name SoundFX
extends Node

const SAMPLE_RATE := 22050

var _flap_player: AudioStreamPlayer
var _score_player: AudioStreamPlayer
var _hit_player: AudioStreamPlayer
var _audio_enabled := true


func _ready() -> void:
	_audio_enabled = DisplayServer.get_name() != "headless"
	_flap_player = _make_player(_make_tone(610.0, 350.0, 0.085, 0.24, 0.0))
	_score_player = _make_player(_make_tone(650.0, 1080.0, 0.15, 0.2, 0.0))
	_hit_player = _make_player(_make_tone(175.0, 52.0, 0.25, 0.28, 0.22))


func _exit_tree() -> void:
	for player in [_flap_player, _score_player, _hit_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func play_flap() -> void:
	if _audio_enabled:
		_flap_player.play()


func play_score() -> void:
	if _audio_enabled:
		_score_player.play()


func play_hit() -> void:
	if _audio_enabled:
		_hit_player.play()


func _make_player(audio_stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = audio_stream
	add_child(player)
	return player


func _make_tone(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	volume: float,
	noise_amount: float
) -> AudioStreamWAV:
	var sample_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase := 0.0

	for index in sample_count:
		var progress := float(index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / float(SAMPLE_RATE)
		var attack := minf(progress / 0.06, 1.0)
		var envelope := attack * pow(1.0 - progress, 1.8)
		var harmonic := sin(phase) * 0.78 + sin(phase * 2.0) * 0.22
		var pseudo_noise := sin(float(index) * 12.9898) * sin(float(index) * 0.781)
		var sample := (harmonic * (1.0 - noise_amount) + pseudo_noise * noise_amount) * volume * envelope
		var encoded := clampi(int(sample * 32767.0), -32768, 32767)
		bytes.encode_s16(index * 2, encoded)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = bytes
	return wav
