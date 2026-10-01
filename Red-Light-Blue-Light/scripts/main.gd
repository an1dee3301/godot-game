class_name RaceMain
extends Node3D
## Connection lifecycle and local presentation; Match owns all authoritative rules.

const MAX_PLAYERS := 8
const PLAYER_SCENE := preload("res://scenes/player.tscn")
var sound_fx: SoundFX
var level: GameLevel
var players: Node3D
var spawner: MultiplayerSpawner
var match_controller: MatchController
var menu_camera: Camera3D
var hud: RaceHUD
var menu: RaceMenu
var player_name := "Player"
var server_address := "127.0.0.1"
var server_port := 7777
var connected := false
var hosting := false
var _orbit := 0.0

func _ready() -> void:
	_setup_input_map()
	sound_fx = SoundFX.new()
	sound_fx.name = "SoundFX"
	add_child(sound_fx)
	level = GameLevel.new()
	level.name = "Level"
	add_child(level)
	players = Node3D.new()
	players.name = "Players"
	add_child(players)
	spawner = MultiplayerSpawner.new()
	spawner.name = "PlayerSpawner"
	spawner.spawn_path = NodePath("../Players")
	spawner.spawn_function = _spawn_player
	add_child(spawner)
	match_controller = MatchController.new()
	match_controller.name = "Match"
	add_child(match_controller)
	menu_camera = Camera3D.new()
	menu_camera.name = "MenuCamera"
	menu_camera.fov = 70
	add_child(menu_camera)
	hud = RaceHUD.new()
	hud.name = "HUD"
	add_child(hud)
	menu = RaceMenu.new()
	menu.name = "Menu"
	add_child(menu)
	menu.host_requested.connect(host_game)
	menu.join_requested.connect(join_game)
	menu.quit_requested.connect(func() -> void: get_tree().quit())
	hud.ready_requested.connect(_toggle_ready)
	hud.start_requested.connect(_request_start)
	hud.leave_requested.connect(leave_game)
	match_controller.phase_changed.connect(_on_phase)
	match_controller.light_changed.connect(_on_light)
	match_controller.roster_changed.connect(_on_roster)
	match_controller.player_eliminated.connect(_on_elimination)
	match_controller.player_finished.connect(_on_finish)
	match_controller.shove_landed.connect(_on_shove)
	match_controller.shoved.connect(_on_shoved)
	match_controller.reset_requested.connect(_on_reset)
	match_controller.countdown_tick.connect(func(_tick: int) -> void: sound_fx.play("beep"))
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	menu.visible = true
	hud.visible = false
	menu_camera.current = true
	_command_line()

func _process(delta: float) -> void:
	if menu.visible:
		_orbit += delta * 0.12
		menu_camera.position = Vector3(sin(_orbit) * 26, 12, 32 + cos(_orbit) * 5)
		menu_camera.look_at(Vector3(0, 3, -8))
	if connected:
		hud.refresh(match_controller, _local_player(), hosting, server_address, server_port)

func host_game(name_text: String = "Player", port: int = 7777) -> void:
	if connected:
		return
	player_name = name_text
	server_port = port
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK:
		menu.set_status("Host failed: %s" % error_string(error))
		return
	multiplayer.multiplayer_peer = peer
	hosting = true
	connected = true
	_show_game()
	_add_player(1, player_name)

func join_game(address: String = "127.0.0.1", name_text: String = "Player", port: int = 7777) -> void:
	if connected:
		return
	player_name = name_text
	server_address = address.strip_edges()
	server_port = port
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(server_address, port)
	if error != OK:
		menu.set_status("Join failed: %s" % error_string(error))
		return
	multiplayer.multiplayer_peer = peer
	menu.set_status("Connecting to %s:%d..." % [server_address, port])

func _on_connected() -> void:
	connected = true
	hosting = false
	_show_game()
	register_player.rpc_id(1, player_name)

@rpc("any_peer", "call_remote", "reliable")
func register_player(requested_name: String) -> void:
	if not multiplayer.is_server():
		return
	_add_player(multiplayer.get_remote_sender_id(), requested_name)

func _add_player(id: int, requested_name: String) -> void:
	if not multiplayer.is_server() or id <= 0 or match_controller.roster.has(id):
		return
	var slot := -1
	for i in MAX_PLAYERS:
		var taken := false
		for entry in match_controller.roster.values():
			if int(entry["slot"]) == i:
				taken = true
		if not taken:
			slot = i
			break
	if slot < 0:
		if id != 1:
			multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	var clean := requested_name.strip_edges().substr(0, 16)
	if clean.is_empty():
		clean = "Player %d" % id
	var base_name := clean
	var suffix := 2
	while _name_taken(clean):
		var ending := " (%d)" % suffix
		clean = base_name.substr(0, 16 - ending.length()) + ending
		suffix += 1
	var spectating := match_controller.phase != MatchController.Phase.LOBBY
	match_controller.add_player(id, clean, slot, spectating)
	spawner.spawn({"id": id, "name": clean, "slot": slot})
	if id != 1:
		match_controller.sync_to_peer(id)
	call_deferred("_update_local_controls")

func _name_taken(candidate: String) -> bool:
	for entry in match_controller.roster.values():
		if str(entry["name"]).nocasecmp_to(candidate) == 0:
			return true
	return false

func _spawn_player(data: Variant) -> Node:
	var info: Dictionary = data
	var runner := PLAYER_SCENE.instantiate() as RacePlayer
	runner.setup(int(info["id"]), str(info["name"]), int(info["slot"]), level.spawn_point(int(info["slot"])))
	call_deferred("_update_local_controls")
	return runner

func _on_peer_disconnected(id: int) -> void:
	_play_optional("leave")
	if not multiplayer.is_server():
		return
	var runner := players.get_node_or_null(str(id))
	if runner != null:
		runner.queue_free()
	match_controller.remove_player(id)

func _on_peer_connected(_id: int) -> void:
	_play_optional("join")

func _on_connection_failed() -> void:
	leave_game("Connection failed")

func _on_server_disconnected() -> void:
	_play_optional("leave")
	leave_game("Server disconnected")

func leave_game(message: String = "Left game") -> void:
	if not connected and multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		menu.set_status(message)
		return
	connected = false
	hosting = false
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for child in players.get_children():
		players.remove_child(child)
		child.queue_free()
	match_controller.roster.clear()
	match_controller.reset_local_state()
	if sound_fx.has_method("stop_loop"):
		sound_fx.call("stop_loop")
	level.set_gate_closed(true)
	level.doll.set_light(MatchController.Light.GO)
	hud.visible = false
	menu.visible = true
	menu_camera.current = true
	menu.set_status(message)
	_capture_mouse(false)

func _show_game() -> void:
	menu.visible = false
	hud.visible = true
	_capture_mouse(true)
	_update_local_controls()

func _on_phase(_phase: int) -> void:
	level.set_gate_closed(match_controller.phase == MatchController.Phase.LOBBY or match_controller.phase == MatchController.Phase.COUNTDOWN)
	_update_local_controls()
	hud.on_phase(match_controller)
	if match_controller.phase == MatchController.Phase.PLAYING:
		sound_fx.play("blue")
		_play_optional("go")
	_update_melody()

func _on_light(new_light: int) -> void:
	level.doll.set_light(new_light)
	sound_fx.play("blue" if new_light == MatchController.Light.GO else "warn" if new_light == MatchController.Light.WARN else "red")
	_update_melody()

func _play_optional(kind: String) -> void:
	if sound_fx.has_method("has_sound") and bool(sound_fx.call("has_sound", kind)):
		sound_fx.play(kind)

func _update_melody() -> void:
	if match_controller.phase == MatchController.Phase.PLAYING and match_controller.light == MatchController.Light.GO and sound_fx.has_method("play_loop"):
		if sound_fx.has_method("has_sound") and bool(sound_fx.call("has_sound", "melody")):
			sound_fx.call("play_loop", "melody")
	elif sound_fx.has_method("stop_loop"):
		sound_fx.call("stop_loop")

func _on_roster() -> void:
	_update_local_controls()
	for id in match_controller.roster.keys():
		var runner := players.get_node_or_null(str(id)) as RacePlayer
		if runner != null:
			runner.set_eliminated(match_controller.get_status(id) == MatchController.Status.OUT)

func _update_local_controls() -> void:
	var runner := _local_player()
	if runner == null:
		return
	var status := match_controller.get_status(multiplayer.get_unique_id())
	runner.controls_enabled = connected and (match_controller.phase == MatchController.Phase.LOBBY and status == MatchController.Status.WAITING or match_controller.phase == MatchController.Phase.PLAYING and status in [MatchController.Status.ALIVE, MatchController.Status.FINISHED])
	if runner.camera != null and connected:
		runner.camera.current = true

func _on_elimination(id: int, reason: String) -> void:
	var runner := players.get_node_or_null(str(id)) as RacePlayer
	if runner != null:
		runner.set_eliminated(true)
		level.doll.fire_beam(runner.global_position + Vector3.UP)
	sound_fx.play("zap")
	if id == multiplayer.get_unique_id():
		hud.announce("ELIMINATED", reason)
	_update_local_controls()

func _on_finish(id: int, place: int, elapsed: float) -> void:
	sound_fx.play("finish")
	if id == multiplayer.get_unique_id():
		hud.announce("FINISHED %s!" % RaceHUD.ordinal(place), "%.1f seconds" % elapsed)
		if place == 1:
			_play_optional("win")
	_update_local_controls()

func _on_shove(a: int, _b: int) -> void:
	var runner := players.get_node_or_null(str(a)) as RacePlayer
	if runner != null:
		runner.play_shove()
	sound_fx.play("shove")

func _on_shoved(impulse: Vector3) -> void:
	var runner := _local_player()
	if runner != null:
		runner.apply_shove(impulse)

func _on_reset() -> void:
	var runner := _local_player()
	if runner != null:
		runner.reset_to_spawn(level.spawn_point(runner.slot))
	for child in players.get_children():
		(child as RacePlayer).set_eliminated(false)

func _toggle_ready() -> void:
	var id := multiplayer.get_unique_id()
	if match_controller.roster.has(id):
		var ready := not bool(match_controller.roster[id]["ready"])
		if hosting:
			match_controller.request_player_ready(ready)
		else:
			match_controller.request_player_ready.rpc_id(1, ready)

func _request_start() -> void:
	if hosting:
		match_controller.request_start()

func _try_shove() -> void:
	if not connected:
		return
	var self_player := _local_player()
	if self_player == null:
		return
	var nearest_id := 0
	var nearest_distance := 3.2
	for child in players.get_children():
		var runner := child as RacePlayer
		if runner == self_player:
			continue
		var delta := runner.global_position - self_player.global_position
		delta.y = 0
		if delta.length() < nearest_distance:
			nearest_id = runner.player_id
			nearest_distance = delta.length()
	if nearest_id > 0:
		if hosting:
			match_controller.request_shove(nearest_id)
		else:
			match_controller.request_shove.rpc_id(1, nearest_id)

func _unhandled_input(event: InputEvent) -> void:
	if not connected:
		return
	if event.is_action_pressed("release_mouse"):
		_capture_mouse(false)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)
	elif event.is_action_pressed("ready"):
		_toggle_ready()
	elif event.is_action_pressed("start_match") and hosting:
		_request_start()
	elif event.is_action_pressed("shove"):
		_try_shove()

func _local_player() -> RacePlayer:
	return players.get_node_or_null(str(multiplayer.get_unique_id())) as RacePlayer

func _capture_mouse(value: bool) -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

func _command_line() -> void:
	var args := OS.get_cmdline_user_args()
	var address := "127.0.0.1"
	var want_host := false
	var want_join := false
	for arg in args:
		if arg == "--host": want_host = true
		elif arg == "--join": want_join = true
		elif arg.begins_with("--join="):
			want_join = true
			address = arg.trim_prefix("--join=")
		elif arg.begins_with("--name="): player_name = arg.trim_prefix("--name=")
		elif arg.begins_with("--port="): server_port = int(arg.trim_prefix("--port="))
	if want_host:
		host_game(player_name, server_port)
	elif want_join:
		join_game(address, player_name, server_port)

func _setup_input_map() -> void:
	_bind("move_forward", [KEY_W, KEY_UP])
	_bind("move_back", [KEY_S, KEY_DOWN])
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_SPACE])
	_bind("sprint", [KEY_SHIFT])
	_bind("ready", [KEY_R])
	_bind("start_match", [KEY_ENTER])
	_bind("shove", [KEY_F])
	_bind("release_mouse", [KEY_ESCAPE])
	if not InputMap.has_action("shove"):
		InputMap.add_action("shove")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("shove", click)

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
