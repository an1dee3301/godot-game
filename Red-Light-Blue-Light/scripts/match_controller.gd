class_name MatchController
extends Node
## Server-owned round rules; clients receive roster, phase, light and event RPCs.

signal phase_changed(phase: int)
signal light_changed(light: int)
signal roster_changed()
signal player_eliminated(id: int, reason: String)
signal player_finished(id: int, place: int, time: float)
signal shove_landed(a: int, b: int)
signal shoved(impulse: Vector3)
signal reset_requested()
signal countdown_tick(number: int)

enum Phase { LOBBY, COUNTDOWN, PLAYING, RESULTS }
enum Light { GO, WARN, STOP }
enum Status { WAITING, ALIVE, OUT, FINISHED, SPECTATING }
const ROUND_DURATION := 90.0
var roster: Dictionary = {}
var phase := Phase.LOBBY
var light := Light.GO
var time_left := 0.0
var round_number := 0
var results_duration := 8.0
var countdown_duration := 3.0
var _light_remaining := 0.0
var _grace := 0.0
var _snapshots: Dictionary = {}
var _last_positions: Dictionary = {}
var _position_seen: Dictionary = {}
var _clock_accumulator := 0.0
var _last_tick := -1
var _finish_count := 0
var _cooldowns: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var main: Node3D

func _ready() -> void:
	_rng.randomize()
	main = get_parent() as Node3D

func _sender() -> int:
	var id := multiplayer.get_remote_sender_id()
	return multiplayer.get_unique_id() if id == 0 else id

func add_player(id: int, display_name: String, slot: int, spectating: bool) -> void:
	if not multiplayer.is_server():
		return
	roster[id] = {"name": display_name, "slot": slot, "ready": false, "status": Status.SPECTATING if spectating else Status.WAITING, "place": 0, "time": 0.0, "wins": 0}
	_sync_roster.rpc(roster)

func remove_player(id: int) -> void:
	if not multiplayer.is_server() or not roster.has(id):
		return
	roster.erase(id)
	_snapshots.erase(id)
	_last_positions.erase(id)
	_position_seen.erase(id)
	_cooldowns.erase(id)
	_sync_roster.rpc(roster)
	_check_round_done()

@rpc("any_peer", "call_local", "reliable")
func request_player_ready(ready: bool) -> void:
	if not multiplayer.is_server():
		return
	var id := _sender()
	if phase != Phase.LOBBY or not roster.has(id):
		return
	var entry: Dictionary = roster[id]
	entry["ready"] = ready
	roster[id] = entry
	_sync_roster.rpc(roster)

@rpc("any_peer", "call_local", "reliable")
func request_start() -> void:
	if not multiplayer.is_server() or _sender() != 1 or not can_start():
		return
	_start_countdown()

func can_start() -> bool:
	if phase != Phase.LOBBY or roster.is_empty():
		return false
	for entry in roster.values():
		if not bool(entry["ready"]):
			return false
	return true

func _start_countdown() -> void:
	round_number += 1
	_finish_count = 0
	_cooldowns.clear()
	_last_positions.clear()
	_position_seen.clear()
	for id in roster.keys():
		var entry: Dictionary = roster[id]
		entry["status"] = Status.ALIVE
		entry["place"] = 0
		entry["time"] = 0.0
		roster[id] = entry
	_sync_roster.rpc(roster)
	_reset_positions.rpc()
	_sync_light.rpc(Light.GO)
	_sync_phase.rpc(Phase.COUNTDOWN, countdown_duration, round_number)
	_last_tick = -1

func _start_playing() -> void:
	_sync_phase.rpc(Phase.PLAYING, ROUND_DURATION, round_number)
	force_light(Light.GO, _rng.randf_range(2.0, 5.0))
	_clock_accumulator = 0.0

func force_light(new_light: int, duration: float) -> void:
	if not multiplayer.is_server():
		return
	_light_remaining = duration
	_grace = 0.3 if new_light == Light.STOP else 0.0
	_snapshots.clear()
	_sync_light.rpc(new_light)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if phase == Phase.COUNTDOWN or phase == Phase.PLAYING or phase == Phase.RESULTS:
			time_left = maxf(0.0, time_left - delta)
		if phase == Phase.COUNTDOWN:
			var tick := int(ceil(time_left))
			if tick != _last_tick and tick > 0:
				_last_tick = tick
				countdown_tick.emit(tick)
		return
	if phase == Phase.LOBBY:
		return
	time_left = maxf(0.0, time_left - delta)
	if phase == Phase.COUNTDOWN:
		var tick := int(ceil(time_left))
		if tick != _last_tick and tick > 0:
			_last_tick = tick
			countdown_tick.emit(tick)
		if time_left <= 0.0:
			_start_playing()
		return
	if phase == Phase.RESULTS:
		if time_left <= 0.0:
			_back_to_lobby()
		return
	_clock_accumulator += delta
	if _clock_accumulator >= 1.0:
		_clock_accumulator -= 1.0
		_sync_clock.rpc(time_left)
	_light_remaining -= delta
	for id in roster.keys():
		var tracked := _player(id)
		if tracked != null:
			if _last_positions.has(id) and tracked.sync_position.distance_squared_to(_last_positions[id]) > 0.0001 and (light != Light.STOP or _grace > 0.0):
				_position_seen[id] = true
			_last_positions[id] = tracked.sync_position
	if light == Light.STOP and _grace > 0.0:
		_grace -= delta
		if _grace <= 0.0:
			for id in roster.keys():
				if get_status(id) == Status.ALIVE:
					var runner := _player(id)
					if runner != null:
						_snapshots[id] = runner.sync_position
	if _light_remaining <= 0.0:
		match light:
			Light.GO: force_light(Light.WARN, _rng.randf_range(0.45, 0.8))
			Light.WARN: force_light(Light.STOP, _rng.randf_range(2.0, 4.0))
			Light.STOP: force_light(Light.GO, _rng.randf_range(2.0, 5.0))
	for id in roster.keys():
		if get_status(id) != Status.ALIVE:
			continue
		var runner := _player(id)
		if runner == null:
			continue
		if runner.sync_position.z <= GameLevel.FINISH_Z:
			_finish(id)
		elif light == Light.STOP and _grace <= 0.0:
			if not _snapshots.has(id):
				_snapshots[id] = runner.sync_position
			elif id != 1 and not bool(_position_seen.get(id, false)):
				# A peer's first replicated pose can arrive after the red snapshot.
				if runner.sync_position.distance_squared_to(_snapshots[id]) > 0.0001:
					_snapshots[id] = runner.sync_position
					_position_seen[id] = true
			else:
				# Judge ground-plane travel after a grace window; jumping in place is safe.
				var offset: Vector3 = runner.sync_position - _snapshots[id]
				if Vector2(offset.x, offset.z).length() > 0.4:
					_eliminate(id, "MOVED ON RED")
	if time_left <= 0.0:
		for id in roster.keys():
			if get_status(id) == Status.ALIVE:
				_eliminate(id, "TIME'S UP")
	_check_round_done()

func _finish(id: int) -> void:
	_finish_count += 1
	var elapsed := ROUND_DURATION - time_left
	var entry: Dictionary = roster[id]
	entry["status"] = Status.FINISHED
	entry["place"] = _finish_count
	entry["time"] = elapsed
	roster[id] = entry
	_sync_roster.rpc(roster)
	_announce_finish.rpc(id, _finish_count, elapsed)

func _eliminate(id: int, reason: String) -> void:
	var entry: Dictionary = roster[id]
	entry["status"] = Status.OUT
	roster[id] = entry
	_sync_roster.rpc(roster)
	_announce_elimination.rpc(id, reason)

func _check_round_done() -> void:
	if phase != Phase.PLAYING:
		return
	for entry in roster.values():
		if int(entry["status"]) == Status.ALIVE:
			return
	var ranking := get_ranking()
	if not ranking.is_empty():
		var winner: int = ranking[0]
		if get_status(winner) == Status.FINISHED:
			var entry: Dictionary = roster[winner]
			entry["wins"] = int(entry["wins"]) + 1
			roster[winner] = entry
			_sync_roster.rpc(roster)
	_sync_phase.rpc(Phase.RESULTS, results_duration, round_number)

func _back_to_lobby() -> void:
	_light_remaining = 0.0
	_grace = 0.0
	_snapshots.clear()
	_last_positions.clear()
	_position_seen.clear()
	_clock_accumulator = 0.0
	_cooldowns.clear()
	for id in roster.keys():
		var entry: Dictionary = roster[id]
		entry["ready"] = false
		entry["status"] = Status.WAITING
		roster[id] = entry
	_sync_roster.rpc(roster)
	_reset_positions.rpc()
	_sync_light.rpc(Light.GO)
	_sync_phase.rpc(Phase.LOBBY, 0.0, round_number)

func get_ranking() -> Array:
	var ids := roster.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var x: Dictionary = roster[a]
		var y: Dictionary = roster[b]
		if int(x["status"]) == Status.FINISHED and int(y["status"]) != Status.FINISHED:
			return true
		if int(y["status"]) == Status.FINISHED and int(x["status"]) != Status.FINISHED:
			return false
		if int(x["status"]) == Status.FINISHED:
			return int(x["place"]) < int(y["place"])
		return int(x["slot"]) < int(y["slot"])
	)
	return ids

func get_status(id: int) -> int:
	return int(roster[id]["status"]) if roster.has(id) else Status.SPECTATING

@rpc("any_peer", "call_local", "reliable")
func request_shove(target_id: int) -> void:
	if not multiplayer.is_server() or phase not in [Phase.LOBBY, Phase.PLAYING]:
		return
	var id := _sender()
	if id == target_id or not roster.has(id) or not roster.has(target_id):
		return
	if phase == Phase.PLAYING and (get_status(id) != Status.ALIVE or get_status(target_id) != Status.ALIVE):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < float(_cooldowns.get(id, 0.0)):
		return
	var attacker := _player(id)
	var target := _player(target_id)
	if attacker == null or target == null:
		return
	var offset := target.sync_position - attacker.sync_position
	offset.y = 0.0
	if offset.length() > 3.2 or offset.length() < 0.05:
		return
	_cooldowns[id] = now + 1.2
	_receive_shove.rpc_id(target_id, offset.normalized() * 7.5 + Vector3.UP * 2.5)
	_announce_shove.rpc(id, target_id)
	if phase == Phase.PLAYING and light == Light.STOP and get_status(target_id) == Status.ALIVE:
		_eliminate(target_id, "SHOVED ON RED")
		_check_round_done()

@rpc("authority", "call_local", "reliable")
func _receive_shove(impulse: Vector3) -> void:
	shoved.emit(impulse)

@rpc("authority", "call_local", "reliable")
func _sync_roster(new_roster: Dictionary) -> void:
	roster = new_roster.duplicate(true)
	roster_changed.emit()

@rpc("authority", "call_local", "reliable")
func _sync_phase(new_phase: int, remaining: float, new_round: int) -> void:
	phase = new_phase
	time_left = remaining
	round_number = new_round
	if phase == Phase.COUNTDOWN:
		_last_tick = -1
	phase_changed.emit(phase)

@rpc("authority", "call_local", "reliable")
func _sync_light(new_light: int) -> void:
	light = new_light
	light_changed.emit(light)

@rpc("authority", "call_local", "unreliable")
func _sync_clock(remaining: float) -> void:
	time_left = remaining

@rpc("authority", "call_local", "reliable")
func _announce_elimination(id: int, reason: String) -> void:
	player_eliminated.emit(id, reason)

@rpc("authority", "call_local", "reliable")
func _announce_finish(id: int, place: int, elapsed: float) -> void:
	player_finished.emit(id, place, elapsed)

@rpc("authority", "call_local", "reliable")
func _announce_shove(a: int, b: int) -> void:
	shove_landed.emit(a, b)

@rpc("authority", "call_local", "reliable")
func _reset_positions() -> void:
	reset_requested.emit()

func sync_to_peer(id: int) -> void:
	if not multiplayer.is_server():
		return
	_sync_roster.rpc_id(id, roster)
	_sync_phase.rpc_id(id, phase, time_left, round_number)
	_sync_light.rpc_id(id, light)

func reset_local_state() -> void:
	roster.clear()
	phase = Phase.LOBBY
	light = Light.GO
	time_left = 0.0
	round_number = 0
	_light_remaining = 0.0
	_grace = 0.0
	_snapshots.clear()
	_last_positions.clear()
	_position_seen.clear()
	_clock_accumulator = 0.0
	_last_tick = -1
	_finish_count = 0
	_cooldowns.clear()
	roster_changed.emit()

func _player(id: int) -> RacePlayer:
	return main.get_node_or_null("Players/%d" % id) as RacePlayer
