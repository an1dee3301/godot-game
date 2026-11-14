extends Node
## Original party score, crowd and cartoon cues, all synthesized locally at start-up.
## No external music, samples or generative media service is used.
var muted: bool = false
var beat: float = 0.0
var beat_index: int = 0
var urgent: bool = false
var playing: bool = false
var round_style: int = 0
var _shutting_down: bool = false
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var _music_notes: Dictionary = {}
var _bass_notes: Dictionary = {}
var _chords: Dictionary = {}
var _bus: StringName = &"Master"
# Eight short call-and-response phrases, with space for play sounds.
const PARTY_MELODY: Array[int] = [12,-1,16,19,16,-1,14,-1,12,16,19,-1,21,19,16,-1,17,-1,21,24,21,-1,19,-1,17,16,14,-1,12,-1,-1,-1,14,-1,17,21,19,-1,17,-1,14,17,21,-1,24,21,19,-1,19,-1,23,26,24,-1,23,19,17,-1,14,11,12,-1,-1,-1]
const RATE: int = 22050
const BUS_NAME: StringName = &"Party"
## Each round re-voices the same tune: key, tempo and which layers play.
const ROUND_STYLES: Array[Dictionary] = [
	{"key":0,"step":0.24,"clap":true,"hat":true,"stab":true,"bell":false},
	{"key":-5,"step":0.27,"clap":false,"hat":false,"stab":false,"bell":true},
	{"key":2,"step":0.23,"clap":true,"hat":true,"stab":true,"bell":false},
	{"key":5,"step":0.225,"clap":true,"hat":true,"stab":false,"bell":true},
	{"key":7,"step":0.205,"clap":true,"hat":true,"stab":true,"bell":true}
]
const CUES: Array[String] = ["tick","shove","dive","grab","fall","correct","wrong","gacha","start","emote","jump","land","hit","ready","go","ui_hover","ui_confirm","cheer","aww","drumroll","reveal","fanfare","splash","pop","whoosh"]

func _ready() -> void:
	_prepare_bus()
	for i in 28:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.volume_db = -15.0
		voice.bus = _bus
		add_child(voice)
		voices.append(voice)
	for key in CUES:
		sounds[key] = _make_sound(key)
	sounds["beat"] = _tone(75.0,0.09,"kick")
	sounds["clap"] = _percussion(false)
	sounds["shaker"] = _percussion(true)
	sounds["hat"] = _hat()
	for semitone in 27:
		_music_notes[semitone] = _tone(261.63 * pow(2.0,float(semitone)/12.0),0.19,"marimba")
	for semitone in [0,2,5,7]:
		_bass_notes[semitone] = _tone(130.81 * pow(2.0,float(semitone)/12.0),0.18,"soft")
	# I · IV · ii · V, voiced as soft plucked triads.
	_chords[0] = _chord([0,4,7])
	_chords[5] = _chord([5,9,12])
	_chords[2] = _chord([2,5,9])
	_chords[7] = _chord([7,11,14])

func _prepare_bus() -> void:
	# A little room and a limiter glue the synthesized voices together.
	var index: int = AudioServer.get_bus_index(BUS_NAME)
	if index < 0:
		index = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index,BUS_NAME)
		AudioServer.set_bus_send(index,&"Master")
		var room: AudioEffectReverb = AudioEffectReverb.new()
		room.room_size = 0.42
		room.damping = 0.6
		room.wet = 0.16
		room.dry = 0.92
		room.spread = 0.8
		AudioServer.add_bus_effect(index,room)
		var limiter: AudioEffectLimiter = AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -6.0
		AudioServer.add_bus_effect(index,limiter)
	_bus = BUS_NAME

func set_round(index: int) -> void:
	round_style = clampi(index,0,ROUND_STYLES.size() - 1)

func _process(delta: float) -> void:
	if _shutting_down or not playing or muted:
		return
	beat -= delta
	if beat <= 0.0:
		var style: Dictionary = ROUND_STYLES[round_style]
		var step: float = float(style.step)
		beat += step * (0.8 if urgent else 1.0)
		var pitch: float = pow(2.0,float(style.key) / 12.0)
		var note: int = PARTY_MELODY[beat_index % PARTY_MELODY.size()]
		if note >= 0:
			_play(_music_notes[note],-27.0,pitch)
			if bool(style.bell) and beat_index % 2 == 0: _play(_music_notes[note],-36.0,pitch * 2.0)
		var roots: Array[int] = [0,5,2,7]
		var root: int = roots[floori(float(beat_index) / 8.0) % 4]
		if beat_index % 4 == 0 or beat_index % 8 == 6:
			_play(_bass_notes[root],-28.0,pitch)
		if bool(style.stab) and (beat_index % 8 == 2 or beat_index % 8 == 5):
			_play(_chords[root],-33.0,pitch)
		if beat_index % 4 == 0:
			_play(sounds["beat"],-30.0)
		if urgent and beat_index % 4 == 2: _play(sounds["beat"],-33.0)
		if bool(style.clap) and beat_index % 4 == 2: _play(sounds["clap"],-36.0)
		if bool(style.hat) and beat_index % 2 == 1: _play(sounds["hat"],-41.0)
		elif beat_index % 2 == 1: _play(sounds["shaker"],-40.0)
		beat_index += 1

func toggle_mute() -> void:
	if _shutting_down: return
	muted = not muted
	for voice in voices:
		voice.stream_paused = muted

func play(cue: String) -> void:
	if not _shutting_down and not muted and sounds.has(cue):
		_play(sounds[cue], -19.0 if cue == "cheer" or cue == "drumroll" else -15.0)

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
	_chords.clear()

func _exit_tree() -> void:
	shutdown()

func _play(stream: AudioStreamWAV, db: float, pitch: float = 1.0) -> void:
	if _shutting_down: return
	for voice in voices:
		if not voice.playing:
			voice.stream = stream
			voice.volume_db = db
			voice.pitch_scale = pitch
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
		"correct": return _arpeggio([523.25,659.25,783.99,1046.5],0.075,0.5)
		"wrong": return _tone(110.0, 0.35, "buzz")
		"gacha": return _arpeggio([440.0,554.37,659.25,880.0,1108.73,1318.5],0.07,0.45)
		"start": return _arpeggio([261.63,329.63,392.0,523.25,659.25],0.085,0.6)
		"pop": return _tone(620.0,0.06,"rise")
		"whoosh": return _noise_sweep(0.32,false)
		"splash": return _noise_sweep(0.55,true)
		"cheer": return _crowd(1.5,true)
		"aww": return _crowd(1.0,false)
		"drumroll": return _drumroll(2.4)
		"reveal": return _sting()
		"fanfare": return _fanfare()
		_: return _tone(340.0, 0.16, "rise")

func _stream(samples: PackedFloat32Array, gain: float = 24000.0) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2,int(clampf(samples[i],-1.0,1.0) * gain))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream

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

func _hat() -> AudioStreamWAV:
	var count: int = int(RATE * 0.04)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 99
	var previous: float = 0.0
	for i in count:
		var noise: float = random.randf_range(-1.0,1.0)
		samples[i] = (noise - previous) * 0.6 * exp(-float(i) / RATE * 120.0)
		previous = noise
	return _stream(samples,15000.0)

func _chord(semitones: Array) -> AudioStreamWAV:
	var count: int = int(RATE * 0.22)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / RATE
		var wave: float = 0.0
		for semitone: int in semitones:
			var frequency: float = 261.63 * pow(2.0,float(semitone) / 12.0)
			wave += sin(TAU * frequency * t) + sin(TAU * frequency * 2.0 * t) * 0.3
		samples[i] = wave / 3.9 * minf(t * 160.0,1.0) * exp(-t * 13.0)
	return _stream(samples)

func _arpeggio(frequencies: Array,step: float,tail: float) -> AudioStreamWAV:
	var count: int = int(RATE * (step * frequencies.size() + tail))
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for n in frequencies.size():
		var frequency: float = float(frequencies[n])
		var start: int = int(RATE * step * n)
		for i in range(start,count):
			var t: float = float(i - start) / RATE
			var bell: float = sin(TAU * frequency * t) * 0.8 + sin(TAU * frequency * 2.0 * t) * 0.15 + sin(TAU * frequency * 3.0 * t) * 0.05
			samples[i] += bell * minf(t * 200.0,1.0) * exp(-t * 6.5) * 0.42
	return _stream(samples)

func _noise_sweep(duration: float,wet: bool) -> AudioStreamWAV:
	var count: int = int(RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 808
	var low: float = 0.0
	for i in count:
		var progress: float = float(i) / count
		var t: float = float(i) / RATE
		# A one-pole low-pass whose cutoff opens (whoosh) or closes (splash).
		var cutoff: float = lerpf(0.6,0.05,progress) if wet else 0.08 + sin(progress * PI) * 0.5
		low += (random.randf_range(-1.0,1.0) - low) * cutoff
		var envelope: float = minf(t * 60.0,1.0) * pow(1.0 - progress,1.6 if wet else 1.0) * (1.0 if wet else sin(progress * PI))
		var plop: float = sin(TAU * 190.0 * exp(-t * 9.0) * t) * exp(-t * 14.0) * 0.6 if wet else 0.0
		samples[i] = low * envelope * 0.9 + plop
	return _stream(samples)

func _crowd(duration: float,happy: bool) -> AudioStreamWAV:
	var count: int = int(RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 2024 if happy else 1999
	var low: float = 0.0
	var band: float = 0.0
	# A few "voices": formant-ish tones gliding up for a cheer, down for an aww.
	var voices_hz: Array[float] = [310.0,392.0,466.0,523.0,622.0]
	if not happy: voices_hz = [330.0,392.0,277.0]
	for i in count:
		var progress: float = float(i) / count
		var t: float = float(i) / RATE
		var noise: float = random.randf_range(-1.0,1.0)
		low += (noise - low) * 0.22
		band += (low - band) * 0.5
		var swell: float = minf(t * 7.0,1.0) * pow(1.0 - progress,0.9)
		var flutter: float = 0.72 + 0.28 * sin(t * 37.0 + sin(t * 5.0) * 3.0)
		var sample: float = (low - band * 0.55) * swell * flutter * (0.95 if happy else 0.4)
		for k in voices_hz.size():
			var glide: float = (1.0 + progress * (0.22 + k * 0.03)) if happy else (1.0 - progress * 0.28)
			var vibrato: float = 1.0 + sin(t * (5.5 + k)) * 0.012
			var frequency: float = voices_hz[k] * glide * vibrato
			var tone: float = sin(TAU * frequency * t) + sin(TAU * frequency * 2.0 * t) * 0.35 + sin(TAU * frequency * 3.0 * t) * 0.12
			sample += tone * swell * (0.05 if happy else 0.11)
		samples[i] = sample
	return _stream(samples,22000.0)

func _drumroll(duration: float) -> AudioStreamWAV:
	var count: int = int(RATE * duration)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 31
	var previous: float = 0.0
	var stroke: float = 0.0
	var phase: float = 0.0
	for i in count:
		var progress: float = float(i) / count
		# Strokes speed up from 14 to 30 per second while the roll swells.
		phase += lerpf(14.0,30.0,progress) / RATE
		if phase >= 1.0:
			phase -= 1.0
			stroke = 1.0
		stroke *= 0.9982
		var noise: float = random.randf_range(-1.0,1.0)
		var snap: float = (noise - previous * 0.35)
		previous = noise
		var body: float = sin(TAU * 185.0 * float(i) / RATE) * 0.35
		samples[i] = (snap * 0.55 + body) * stroke * stroke * (0.25 + progress * 0.75) * minf((1.0 - progress) * 40.0,1.0)
	return _stream(samples,20000.0)

func _sting() -> AudioStreamWAV:
	# A bright major hit over a short cymbal wash: the buzzer has gone.
	var count: int = int(RATE * 1.1)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 5
	var previous: float = 0.0
	for i in count:
		var t: float = float(i) / RATE
		var noise: float = random.randf_range(-1.0,1.0)
		var cymbal: float = (noise - previous) * exp(-t * 5.5) * 0.3
		previous = noise
		var hit: float = 0.0
		for frequency: float in [261.63,329.63,392.0,523.25,783.99]:
			hit += sin(TAU * frequency * t) + sin(TAU * frequency * 2.0 * t) * 0.25
		samples[i] = cymbal + hit / 6.3 * minf(t * 220.0,1.0) * exp(-t * 3.6) * 0.7 + sin(TAU * 70.0 * exp(-t * 10.0) * t) * exp(-t * 9.0) * 0.5
	return _stream(samples)

func _fanfare() -> AudioStreamWAV:
	# Ta-ta-ta-TAAA: three pickup notes into a held brassy chord.
	var notes: Array = [[0.0,392.0,0.14],[0.16,392.0,0.14],[0.32,392.0,0.14],[0.48,523.25,1.3],[0.48,659.25,1.3],[0.48,783.99,1.3]]
	var count: int = int(RATE * 1.9)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for note: Array in notes:
		var start: int = int(RATE * float(note[0]))
		var frequency: float = float(note[1])
		var length: float = float(note[2])
		var low: float = 0.0
		for i in range(start,mini(count,start + int(RATE * (length + 0.25)))):
			var t: float = float(i - start) / RATE
			# A band-limited saw through a gentle low-pass reads as brass.
			var saw: float = 0.0
			for harmonic in range(1,7):
				saw += sin(TAU * frequency * harmonic * t) / harmonic
			low += (saw - low) * 0.35
			var envelope: float = minf(t * 45.0,1.0) * (1.0 if t < length else exp(-(t - length) * 16.0)) * (0.82 + 0.18 * sin(t * 34.0))
			samples[i] += low * envelope * 0.2
	return _stream(samples)

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
