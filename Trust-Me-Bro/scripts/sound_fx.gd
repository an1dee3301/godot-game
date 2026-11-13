extends Node
## Original plucky party score and cartoon cues synthesized locally.
## No external music or generative media service is used.
var muted: bool = false
var beat: float = 0.0
var beat_index: int = 0
var urgent: bool = false
var playing: bool = false
var _shutting_down: bool = false
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var _music_notes: Dictionary = {}
var _bass_notes: Dictionary = {}
# Eight short call-and-response phrases, with space for play sounds.
const PARTY_MELODY: Array[int] = [12,-1,16,19,16,-1,14,-1,12,16,19,-1,21,19,16,-1,17,-1,21,24,21,-1,19,-1,17,16,14,-1,12,-1,-1,-1,14,-1,17,21,19,-1,17,-1,14,17,21,-1,24,21,19,-1,19,-1,23,26,24,-1,23,19,17,-1,14,11,12,-1,-1,-1]
const RATE: int = 22050

func _ready() -> void:
	for i in 24:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.volume_db = -15.0
		add_child(voice)
		voices.append(voice)
	for key in ["tick", "shove", "dive", "grab", "fall", "correct", "wrong", "gacha", "start", "emote", "jump", "land", "hit", "ready", "go", "ui_hover", "ui_confirm"]:
		sounds[key] = _make_sound(key)
	sounds["beat"] = _tone(75.0,0.09,"kick")
	sounds["clap"] = _percussion(false)
	sounds["shaker"] = _percussion(true)
	for semitone in 27:
		_music_notes[semitone] = _tone(261.63 * pow(2.0,float(semitone)/12.0),0.19,"marimba")
	for semitone in [0,2,5,7]:
		_bass_notes[semitone] = _tone(130.81 * pow(2.0,float(semitone)/12.0),0.18,"soft")

func _process(delta: float) -> void:
	if _shutting_down or not playing or muted:
		return
	beat -= delta
	if beat <= 0.0:
		beat += 0.19 if urgent else 0.24
		var note: int = PARTY_MELODY[beat_index % PARTY_MELODY.size()]
		if note >= 0: _play(_music_notes[note],-28.0)
		if beat_index % 4 == 0 or beat_index % 8 == 6:
			var roots: Array[int] = [0,5,2,7]
			_play(_bass_notes[roots[floori(float(beat_index) / 8.0) % 4]],-29.0)
		if beat_index % 4 == 0:
			_play(sounds["beat"],-31.0)
		if beat_index % 4 == 2: _play(sounds["clap"],-37.0)
		if beat_index % 2 == 1: _play(sounds["shaker"],-40.0)
		beat_index += 1

func toggle_mute() -> void:
	if _shutting_down: return
	muted = not muted
	for voice in voices:
		voice.stream_paused = muted

func play(cue: String) -> void:
	if not _shutting_down and not muted and sounds.has(cue):
		_play(sounds[cue], -15.0)

func shutdown() -> void:
	# Focus, countdown and contact signals may arrive while a scene is closing.
	# Latch shutdown before releasing voices so those callbacks cannot restart one.
	_shutting_down = true
	playing = false
	set_process(false)
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	sounds.clear()
	_music_notes.clear()
	_bass_notes.clear()

func _exit_tree() -> void:
	shutdown()

func _play(stream: AudioStreamWAV, db: float) -> void:
	if _shutting_down: return
	for voice in voices:
		if not voice.playing:
			voice.stream = stream
			voice.volume_db = db
			voice.play()
			return

func _make_sound(cue: String) -> AudioStreamWAV:
	match cue:
		"ui_hover": return _tone(740.0,0.035,"marimba")
		"ui_confirm": return _tone(659.25,0.15,"rise")
		"ready": return _tone(523.25,0.15,"marimba")
		"go": return _tone(1046.5,0.27,"chord")
		"land": return _tone(82.4,0.09,"kick")
		"hit": return _tone(130.8,0.08,"buzz")
		"jump": return _tone(330.0,0.13,"rise")
		"tick": return _tone(880.0, 0.07, "soft")
		"shove": return _tone(170.0, 0.17, "drop")
		"dive": return _tone(420.0, 0.28, "drop")
		"grab": return _tone(660.0, 0.12, "rise")
		"fall": return _tone(500.0, 0.7, "drop")
		"correct": return _tone(523.25, 0.65, "chord")
		"wrong": return _tone(110.0, 0.35, "buzz")
		"gacha": return _tone(440.0, 0.7, "rise")
		"start": return _tone(261.6, 0.9, "chord")
		_: return _tone(340.0, 0.16, "rise")

func _percussion(shaker: bool) -> AudioStreamWAV:
	var duration: float = 0.055 if shaker else 0.12
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(int(RATE * duration) * 2)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 4321
	var previous: float = 0.0
	for i in int(RATE * duration):
		var t: float = float(i) / RATE
		var noise: float = random.randf_range(-1.0,1.0)
		var high: float = (noise - previous) * 0.5
		previous = noise
		var envelope: float = exp(-t * (85.0 if shaker else 35.0))
		var flams: float = 0.5 + 0.5 * absf(sin(t * 690.0))
		bytes.encode_s16(i * 2,int(clampf(high * envelope * flams,-1.0,1.0) * 16000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream

func _tone(frequency: float, duration: float, style: String) -> AudioStreamWAV:
	var samples: int = int(RATE * duration)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples * 2)
	for i in samples:
		var t: float = float(i) / RATE
		var progress: float = t / duration
		var envelope: float = minf(t * 110.0, 1.0) * pow(1.0 - progress, 2.0)
		var freq: float = frequency
		if style == "drop": freq *= maxf(0.15, 1.0 - progress * 0.85)
		if style == "rise": freq *= 1.0 + floor(progress * 5.0) * 0.25
		if style == "kick": freq *= exp(-t * 14.0)
		var wave: float = sin(TAU * freq * t)
		if style == "marimba": wave = (wave * 0.8 + sin(TAU * freq * 3.0 * t) * 0.15 + sin(TAU * freq * 7.0 * t) * 0.05) * exp(-t * 10.0)
		if style == "chord":
			wave = (sin(TAU * freq * t) + sin(TAU * freq * 1.25 * t) + sin(TAU * freq * 1.5 * t)) / 3.0
		if style == "buzz": wave = wave * 0.6 + sin(TAU * freq * 1.07 * t) * 0.4
		bytes.encode_s16(i * 2, int(clampf(wave * envelope, -1.0, 1.0) * 24000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
