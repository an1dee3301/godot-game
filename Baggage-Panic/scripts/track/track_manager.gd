class_name TrackManager
extends Node3D
## Spawns segments ahead of the player and frees them once behind. OWNER: agent B.

signal segment_spawned(segment: TrackSegment)
signal segment_recycled(segment_type: String)

var player: Node3D
var difficulty: Difficulty
var destination_provider: Callable
var spawned_history: Array[String] = []
var recycled_count := 0

var _rng := RandomNumberGenerator.new()
var _segments: Array[TrackSegment] = []
var _next_z := 0.0
var _index := 0
var _active := false
var _belt_offset := 0.0

func begin(new_player: Node3D, new_difficulty: Difficulty, seed_value: int, new_destination_provider: Callable) -> void:
	reset_track()
	player = new_player
	difficulty = new_difficulty
	destination_provider = new_destination_provider
	_rng.seed = seed_value
	_active = true
	_spawn_to_horizon()

func reset_track() -> void:
	_active = false
	for segment in _segments:
		if is_instance_valid(segment):
			remove_child(segment)
			segment.free()
	_segments.clear()
	spawned_history.clear()
	recycled_count = 0
	_index = 0
	_next_z = 0.0
	_belt_offset = 0.0

func active_segments() -> Array[TrackSegment]:
	return _segments.duplicate()

func _physics_process(_delta: float) -> void:
	if not _active or not is_instance_valid(player):
		return
	_spawn_to_horizon()
	while not _segments.is_empty() and _segments[0].end_z() > player.global_position.z + BP.DESPAWN_BEHIND:
		var segment: TrackSegment = _segments.pop_front()
		recycled_count += 1
		segment_recycled.emit(segment.segment_type)
		segment.queue_free()

func _process(delta: float) -> void:
	if not _active:
		return
	var speed := 12.0
	if is_instance_valid(player):
		var property_value: Variant = player.get("forward_speed")
		if property_value is float or property_value is int:
			speed = float(property_value)
	_belt_offset = fposmod(_belt_offset + delta * speed * 0.25, 1.0)
	var rubber := TrackProps.material("belt_rubber", Color(0.065, 0.075, 0.082), 0.05)
	rubber.uv1_offset = Vector3(0, _belt_offset, 0)

func _spawn_to_horizon() -> void:
	if not is_instance_valid(player):
		return
	while _segments.is_empty() or _segments.back().end_z() > player.global_position.z - BP.SPAWN_AHEAD:
		var type := "start"
		if _index >= BP.SAFE_START_SEGMENTS:
			if (_index + 1) % BP.CHECKPOINT_EVERY == 0:
				type = "checkpoint"
			else:
				type = SegmentLibrary.pick_type(_rng, difficulty, spawned_history)
		var destination := "LAX"
		if destination_provider.is_valid():
			destination = str(destination_provider.call())
		var ctx := {"difficulty": difficulty, "rng": _rng, "destination": destination, "index": _index, "safe": _index < BP.SAFE_START_SEGMENTS}
		var segment := SegmentLibrary.build(type, ctx)
		segment.position.z = _next_z
		add_child(segment)
		_segments.append(segment)
		spawned_history.append(type)
		_index += 1
		_next_z -= segment.length
		segment_spawned.emit(segment)
