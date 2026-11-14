extends Node
## ENet room transport. The host owns physics, quiz order, actions and scores.
## Clients send bounded input intent and receive compact Variant snapshots.
signal lobby_changed(players: Array, is_host: bool)
signal status_changed(message: String)
signal match_started
signal session_closed(reason: String)

const DEFAULT_PORT: int = 24816
const MAX_PLAYERS: int = 8
const PROTOCOL_VERSION: int = 1
const SNAPSHOT_INTERVAL: float = 0.05
const INPUT_INTERVAL: float = 1.0 / 30.0
const SNAPSHOT_CHUNK_BYTES: int = 900
const ALLOWED_ACTIONS: Array[String] = ["jump", "shove", "dive", "emote", "grab"]

var active: bool = false
var is_host: bool = false
var in_match: bool = false
var local_peer_id: int = 0
var local_actor_index: int = 0
var input_blocked: bool = false
var players: Array = []
var port: int = DEFAULT_PORT
var received_snapshots: int = 0
var received_input_packets: int = 0
var rejected_input_packets: int = 0

var rounds: Node
var hud: CanvasLayer
var _peer: ENetMultiplayerPeer
var _player_name: String = "Player"
var _snapshot_clock: float = 0.0
var _input_clock: float = 0.0
var _join_clock: float = 0.0
var _connected: bool = false
var _closing: bool = false
var _starting: bool = false
var _sequence: int = 0
var _match_epoch: int = 0
var _input_sequence: int = 0
var _last_snapshot_sequence: int = -1
var _snapshot_assemblies: Dictionary = {}
var _last_input_sequence: Dictionary = {}
var _last_input_time: Dictionary = {}
var _rate_limits: Dictionary = {}
var _remote_peek: Dictionary = {}
var _roster: Array = []
var _status: String = ""

func configure(match_rules: Node, interface_layer: CanvasLayer) -> void:
	rounds = match_rules
	hud = interface_layer
	rounds.network_session = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	rounds.state_changed.connect(_on_match_state_changed)

func host_room(player_name: String, requested_port: int = DEFAULT_PORT) -> Error:
	if requested_port < 1024 or requested_port > 65535:
		_set_status("Choose a port between 1024 and 65535.")
		return ERR_INVALID_PARAMETER
	close_session()
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_server(requested_port, MAX_PLAYERS - 1, 3)
	if error != OK:
		_peer = null
		_set_status("Could not host on port %d. Another room may already be using it." % requested_port)
		return error
	multiplayer.multiplayer_peer = _peer
	active = true
	is_host = true
	_connected = true
	local_peer_id = 1
	local_actor_index = 0
	port = requested_port
	_player_name = _clean_name(player_name)
	players = [{"id": 1, "name": _player_name, "slot": 0, "ready": true}]
	_set_status("Room open · %s:%d · Friends join using this computer's address." % [_lan_address(),port])
	_broadcast_lobby()
	return OK

func join_room(address: String, player_name: String, requested_port: int = DEFAULT_PORT) -> Error:
	var target: String = address.strip_edges()
	if target.count(":") == 1:
		var parts: PackedStringArray = target.split(":")
		if parts[1].is_valid_int():
			requested_port = parts[1].to_int()
			target = parts[0]
	if target.is_empty() or requested_port < 1024 or requested_port > 65535:
		_set_status("Enter the host's address and a port between 1024 and 65535.")
		return ERR_INVALID_PARAMETER
	close_session()
	_peer = ENetMultiplayerPeer.new()
	var error: Error = _peer.create_client(target, requested_port, 3)
	if error != OK:
		_peer = null
		_set_status("Could not join that address. Check the host and port.")
		return error
	multiplayer.multiplayer_peer = _peer
	active = true
	is_host = false
	in_match = false
	_connected = false
	_join_clock = 0.0
	port = requested_port
	_player_name = _clean_name(player_name)
	_set_status("Connecting to %s:%d…" % [target,requested_port])
	return OK

func set_ready(value: bool) -> void:
	if not active or in_match: return
	if is_host:
		_set_player_ready(1,value)
	elif _connected:
		_request_ready.rpc_id(1,value)

func start_match() -> void:
	if not active or not is_host or in_match: return
	for player in players:
		if not bool(player.ready):
			_set_status("Waiting for every friend to press READY.")
			return
	_start_network_game()

func restart_match() -> void:
	if not active: return
	if not is_host:
		_set_status("The host starts the next party.")
		return
	if not in_match or rounds.state != rounds.State.RESULTS: return
	_start_network_game()

func close_session(reason: String = "") -> void:
	if _closing: return
	var was_active: bool = active
	_closing = true
	active = false
	_connected = false
	in_match = false
	input_blocked = false
	if _peer != null: _peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_peer = null
	is_host = false
	local_peer_id = 0
	local_actor_index = 0
	players.clear()
	_roster.clear()
	_last_input_sequence.clear()
	_last_input_time.clear()
	_rate_limits.clear()
	_remote_peek.clear()
	_snapshot_clock = 0.0
	_input_clock = 0.0
	_sequence = 0
	_match_epoch = 0
	_input_sequence = 0
	_last_snapshot_sequence = -1
	_snapshot_assemblies.clear()
	received_snapshots = 0
	if was_active and is_instance_valid(rounds): rounds.end_network_mode()
	_closing = false
	if was_active:
		if not reason.is_empty(): _set_status(reason)
		session_closed.emit(reason)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(rounds): return
	if not is_host and not _connected:
		_join_clock += delta
		if _join_clock >= 10.0:
			close_session("Connection timed out. Check that the host is waiting in its room and the address is correct.")
		return
	if not in_match: return
	if is_host:
		for peer_id in _last_input_time:
			if Time.get_ticks_msec() - int(_last_input_time[peer_id]) > 600:
				var actor: Node = _actor_for_peer(int(peer_id))
				if actor != null: actor.apply_network_input(Vector2.ZERO)
		_snapshot_clock += delta
		if _snapshot_clock >= SNAPSHOT_INTERVAL:
			_snapshot_clock = fmod(_snapshot_clock,SNAPSHOT_INTERVAL)
			_send_snapshots(false)
	else:
		_input_clock += delta
		if _input_clock >= INPUT_INTERVAL:
			_input_clock = fmod(_input_clock,INPUT_INTERVAL)
			_send_local_input()

func _on_peer_connected(peer_id: int) -> void:
	if not active or not is_host: return
	if in_match:
		_reject_peer(peer_id,"This party has already started. Join the host's next room.")

func _on_peer_disconnected(peer_id: int) -> void:
	if not active or not is_host: return
	_last_input_sequence.erase(peer_id)
	_last_input_time.erase(peer_id)
	_remote_peek.erase(peer_id)
	var leaving_name: String = "A friend"
	var admitted: bool = false
	for i in range(players.size() - 1,-1,-1):
		if int(players[i].id) == peer_id:
			admitted = true
			leaving_name = str(players[i].name)
			players.remove_at(i)
	if not admitted: return
	if in_match:
		var actor: Node = _actor_for_peer(peer_id)
		if actor != null:
			actor.configure_network(0,1,false)
			actor.is_bot = true
			actor.display_name = "%s BOT" % leaving_name.left(12)
			actor.bot_moving = actor.active
			actor.bot_target = rounds.arena.tile_centers[actor.contestant_id % 4]
		for entry in _roster:
			if int(entry.id) == peer_id: entry.id = 0
		_set_status("%s left. A bot took their place." % leaving_name)
		_send_snapshots(true)
	else:
		_compact_slots()
		_broadcast_lobby()

func _on_connected() -> void:
	if not active or is_host: return
	_connected = true
	local_peer_id = multiplayer.get_unique_id()
	_request_join.rpc_id(1,_player_name,PROTOCOL_VERSION)
	_set_status("Connected. Waiting for your seat in the room…")

func _on_connection_failed() -> void:
	if active and not is_host: close_session("Could not reach the host. Check the address, port and local network.")

func _on_server_disconnected() -> void:
	if active and not is_host: close_session("The host closed the room. You can host or join another party.")

@rpc("any_peer","call_remote","reliable",0)
func _request_join(player_name: String, protocol: int) -> void:
	if not active or not is_host: return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 1 or not _accept_rate(sender,"join",4): return
	if protocol != PROTOCOL_VERSION:
		_reject_peer(sender,"Game versions do not match. Use the same game build as the host.")
		return
	if in_match:
		_reject_peer(sender,"This party has already started. Join the host's next room.")
		return
	for player in players:
		if int(player.id) == sender: return
	if players.size() >= MAX_PLAYERS:
		_reject_peer(sender,"This room is full. Up to eight friends can play.")
		return
	players.append({"id":sender,"name":_clean_name(player_name),"slot":players.size(),"ready":false})
	_set_status("%d / 8 friends · %s:%d · READY, then the host starts." % [players.size(),_lan_address(),port])
	_broadcast_lobby()

@rpc("any_peer","call_remote","reliable",0)
func _request_ready(value: bool) -> void:
	if not active or not is_host or in_match: return
	var sender: int = multiplayer.get_remote_sender_id()
	if not _accept_rate(sender,"ready",8): return
	_set_player_ready(sender,value)

@rpc("authority","call_remote","reliable",0)
func _receive_lobby(roster: Array, room_status: String) -> void:
	if not active or is_host: return
	players = roster.duplicate(true)
	for player in players:
		if int(player.id) == local_peer_id: local_actor_index = int(player.slot)
	_set_status(room_status)
	lobby_changed.emit(players.duplicate(true),false)

@rpc("authority","call_remote","reliable",0)
func _join_rejected(message: String) -> void:
	if active and not is_host: close_session(message)

func _reject_peer(peer_id: int, message: String) -> void:
	_join_rejected.rpc_id(peer_id,message)
	var timer: SceneTreeTimer = get_tree().create_timer(0.35,true)
	timer.timeout.connect(func() -> void:
		if active and is_host and _peer != null and multiplayer.get_peers().has(peer_id): _peer.disconnect_peer(peer_id)
	)

func _set_player_ready(peer_id: int, value: bool) -> void:
	for player in players:
		if int(player.id) == peer_id:
			player.ready = value
			_broadcast_lobby()
			return

func _compact_slots() -> void:
	for i in players.size(): players[i].slot = i

func _broadcast_lobby() -> void:
	if not active or not is_host: return
	_receive_lobby.rpc(players,_status)
	lobby_changed.emit(players.duplicate(true),true)

func _start_network_game() -> void:
	_starting = true
	in_match = true
	_roster = players.duplicate(true)
	_match_epoch += 1
	_begin_match.rpc(_roster,_match_epoch)
	rounds.start_network_match(_roster,1,false)
	local_actor_index = 0
	_snapshot_clock = 0.0
	_starting = false
	_set_status("Shared stage · host-authoritative party · %d friends" % players.size())
	match_started.emit()
	_send_snapshots(true)

@rpc("authority","call_remote","reliable",0)
func _begin_match(roster: Array, epoch: int) -> void:
	if not active or is_host: return
	_roster = roster.duplicate(true)
	_match_epoch = epoch
	in_match = true
	_last_snapshot_sequence = -1
	_snapshot_assemblies.clear()
	received_snapshots = 0
	for player in roster:
		if int(player.id) == local_peer_id: local_actor_index = int(player.slot)
	rounds.start_network_match(roster,local_peer_id,true)
	match_started.emit()

func _on_match_state_changed(_next: int) -> void:
	if active and is_host and in_match and not _starting:
		call_deferred("_send_snapshots",true)

func _send_snapshots(reliable: bool) -> void:
	if not active or not is_host or not in_match: return
	_sequence += 1
	for player in players:
		var peer_id: int = int(player.id)
		if peer_id == 1: continue
		var data: Dictionary = rounds.make_network_snapshot(peer_id)
		data.sequence = _sequence
		data.epoch = _match_epoch
		if reliable:
			_receive_phase.rpc_id(peer_id,data)
		else:
			# Avoid IP fragmentation: unreliable snapshots are compressed binary
			# Variants, explicitly split below the transport MTU, never JSON.
			var packed: PackedByteArray = var_to_bytes(data).compress(FileAccess.COMPRESSION_GZIP)
			var parts: int = ceili(float(packed.size()) / SNAPSHOT_CHUNK_BYTES)
			for part in parts:
				_receive_snapshot_chunk.rpc_id(peer_id,_sequence,part,parts,packed.slice(part * SNAPSHOT_CHUNK_BYTES,mini((part+1) * SNAPSHOT_CHUNK_BYTES,packed.size())))

@rpc("authority","call_remote","reliable",0)
func _receive_phase(data: Dictionary) -> void:
	_apply_snapshot(data)

@rpc("authority","call_remote","unreliable_ordered",1)
func _receive_snapshot_chunk(sequence: int, index: int, count: int, payload: PackedByteArray) -> void:
	if not active or is_host or not in_match or sequence <= _last_snapshot_sequence: return
	if count < 1 or count > 32 or index < 0 or index >= count or payload.size() > SNAPSHOT_CHUNK_BYTES: return
	if not _snapshot_assemblies.has(sequence):
		_snapshot_assemblies[sequence] = {"parts":{},"count":count}
	var assembly: Dictionary = _snapshot_assemblies[sequence]
	if int(assembly.count) != count: return
	assembly.parts[index] = payload
	if assembly.parts.size() == count:
		var combined: PackedByteArray = PackedByteArray()
		for part in count: combined.append_array(assembly.parts[part])
		_snapshot_assemblies.erase(sequence)
		var unpacked: PackedByteArray = combined.decompress_dynamic(262144,FileAccess.COMPRESSION_GZIP)
		if unpacked.is_empty(): return
		var decoded: Variant = bytes_to_var(unpacked)
		if decoded is Dictionary: _apply_snapshot(decoded)
	# Losing one fragment drops that sample; the next complete snapshot heals it.
	for old_sequence in _snapshot_assemblies.keys():
		if int(old_sequence) < sequence - 3 or int(old_sequence) <= _last_snapshot_sequence:
			_snapshot_assemblies.erase(old_sequence)

func _apply_snapshot(data: Dictionary) -> void:
	if not active or is_host or not in_match: return
	if int(data.get("epoch",-1)) != _match_epoch: return
	var sequence: int = int(data.get("sequence",-1))
	if sequence <= _last_snapshot_sequence: return
	_last_snapshot_sequence = sequence
	received_snapshots += 1
	rounds.apply_network_snapshot(data)

func _send_local_input() -> void:
	if not _connected or local_actor_index < 0 or local_actor_index >= rounds.contestants.size(): return
	var actor: Node = rounds.contestants[local_actor_index]
	var intent: Dictionary = actor.get_network_input()
	var move: Vector2 = intent.get("move",Vector2.ZERO)
	var actions: Array = intent.get("actions",[])
	if input_blocked:
		move = Vector2.ZERO
		actions = []
	_input_sequence += 1
	_submit_movement.rpc_id(1,move,_input_sequence,bool(intent.get("peek",false)) and not input_blocked)
	if not actions.is_empty():
		_submit_actions.rpc_id(1,actions.slice(0,5))

@rpc("any_peer","call_remote","unreliable_ordered",2)
func _submit_movement(move: Vector2, sequence: int, peek: bool) -> void:
	if not active or not is_host or not in_match: return
	var sender: int = multiplayer.get_remote_sender_id()
	var actor: Node = _actor_for_peer(sender)
	if actor == null or not move.is_finite() or not _accept_rate(sender,"move",75):
		rejected_input_packets += 1
		return
	if sequence <= int(_last_input_sequence.get(sender,-1)):
		rejected_input_packets += 1
		return
	_last_input_sequence[sender] = sequence
	_last_input_time[sender] = Time.get_ticks_msec()
	_remote_peek[sender] = peek
	actor.apply_network_input(move.limit_length(1.0))
	received_input_packets += 1

@rpc("any_peer","call_remote","reliable",0)
func _submit_actions(actions: Array) -> void:
	if not active or not is_host or not in_match or actions.size() > 5: return
	var sender: int = multiplayer.get_remote_sender_id()
	var actor: Node = _actor_for_peer(sender)
	if actor == null or not _accept_rate(sender,"actions",15): return
	for value in actions:
		if not value is String: continue
		var action: String = value
		if ALLOWED_ACTIONS.has(action): actor.apply_network_action(action)

func _actor_for_peer(peer_id: int) -> Node:
	if peer_id <= 1: return null
	for actor in rounds.contestants:
		if int(actor.network_owner) == peer_id: return actor
	return null

func _accept_rate(peer_id: int, bucket: String, maximum: int) -> bool:
	var key: String = "%d:%s" % [peer_id,bucket]
	var now: int = Time.get_ticks_msec()
	var record: Dictionary = _rate_limits.get(key,{"start":now,"count":0})
	if now - int(record.start) >= 1000: record = {"start":now,"count":0}
	record.count = int(record.count) + 1
	_rate_limits[key] = record
	return int(record.count) <= maximum

func _clean_name(value: String) -> String:
	var cleaned: String = value.strip_edges().replace("\n","").replace("\r","").replace("\t","")
	cleaned = cleaned.left(18)
	return cleaned if not cleaned.is_empty() else "Party Pal"

func _lan_address() -> String:
	for address in IP.get_local_addresses():
		if address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172."):
			return address
	return "127.0.0.1"

func _set_status(message: String) -> void:
	_status = message
	status_changed.emit(message)
