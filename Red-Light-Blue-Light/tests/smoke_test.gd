extends SceneTree
## Two ENet peers in one process, each inside an isolated SubViewport.

const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []
var host_view: SubViewport
var client_view: SubViewport
var third_view: SubViewport
var host: RaceMain
var client: RaceMain
var third: RaceMain
var port := int(OS.get_environment("RLBL_TEST_PORT")) if OS.get_environment("RLBL_TEST_PORT") != "" else 17777

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	host_view = _viewport("HostView")
	client_view = _viewport("ClientView")
	await _frames(3)
	_check(host.menu.visible and client.menu.visible, "menu shown on launch")
	_check(InputMap.has_action("move_forward") and InputMap.has_action("shove") and InputMap.has_action("ready"), "input actions exist")
	host.host_game("Host", port)
	await _frames(10)
	client.join_game("127.0.0.1", "Client", port)
	await _frames(75)
	_check(host.connected and client.connected, "host and client connected")
	_check(host.players.get_child_count() == 2 and client.players.get_child_count() == 2, "both peers see two spawned players")
	var client_id := client.multiplayer.get_unique_id()
	var host_local := host.players.get_node_or_null("1") as RacePlayer
	var client_local := client.players.get_node_or_null(str(client_id)) as RacePlayer
	var client_host := client.players.get_node_or_null("1") as RacePlayer
	var host_client := host.players.get_node_or_null(str(client_id)) as RacePlayer
	if host_local == null or client_local == null or client_host == null or host_client == null:
		_finish()
		return
	_check(host_local.is_local and client_local.is_local and not client_host.is_local and not host_client.is_local, "local ownership and remote input isolation")
	_check(host_local.get_node("Sync").get_multiplayer_authority() == 1 and client_local.get_node("Sync").get_multiplayer_authority() == client_id, "synchronizer authority follows owning peer")
	_check(host_local.camera != null and host_local.camera.current and client_local.camera != null and client_local.camera.current, "each peer owns its current camera")
	_check(host_local.controls_enabled and client_local.controls_enabled, "lobby runners can move behind closed gate")
	_check(not client.hud._start_button.visible and host.hud._start_button.visible, "start button belongs to host only")
	client.match_controller.request_start.rpc_id(1)
	await _frames(8)
	_check(host.match_controller.phase == MatchController.Phase.LOBBY, "client cannot start round")
	host.match_controller.request_player_ready(true)
	client.match_controller.request_player_ready.rpc_id(1, true)
	await _frames(12)
	_check(host.match_controller.can_start(), "ready roster allows host start")
	host.match_controller.request_start()
	await _frames(8)
	_check(host.match_controller.phase == MatchController.Phase.COUNTDOWN and client.match_controller.phase == MatchController.Phase.COUNTDOWN, "countdown reaches both peers")
	host.match_controller.time_left = 0.02
	await _frames(10)
	_check(host.match_controller.phase == MatchController.Phase.PLAYING and client.match_controller.phase == MatchController.Phase.PLAYING, "playing reaches both peers")
	_check(host.level.gate.collision_layer == 0 and client.level.gate.collision_layer == 0, "start gate opens on both peers")
	_check(host.match_controller.light == client.match_controller.light, "light state agrees")
	third_view = _viewport("ThirdView")
	third = third_view.get_child(0) as RaceMain
	third.join_game("127.0.0.1", "   Host   ", port)
	await _frames(75)
	var third_id := third.multiplayer.get_unique_id()
	_check(third.connected and third.players.get_child_count() == 3 and host.players.get_child_count() == 3 and client.players.get_child_count() == 3, "late join sees all three player nodes")
	_check(third.match_controller.phase == MatchController.Phase.PLAYING and third.match_controller.light == host.match_controller.light and third.match_controller.roster.size() == 3, "late join receives match state and roster")
	_check(host.match_controller.get_status(third_id) == MatchController.Status.SPECTATING and not (third.players.get_node(str(third_id)) as RacePlayer).controls_enabled, "late join spectates current round")
	_check(str(host.match_controller.roster[third_id]["name"]) == "Host (2)", "duplicate name gets numeric suffix")
	var client_before := client_local.global_position
	var host_before := client_host.global_position
	host_local.use_test_input = true
	host_local.test_input = Vector2(0, -1)
	await _frames(32)
	host_local.test_input = Vector2.ZERO
	await _frames(15)
	_check(client_host.global_position.distance_to(host_before) > 0.7, "host movement reaches client remote copy")
	_check(client_local.global_position.distance_to(client_before) < 0.2, "client local player does not inherit host input")
	_check(absf(client_host.sync_yaw - host_local.sync_yaw) < 0.1, "model yaw syncs")
	host.match_controller.force_light(MatchController.Light.STOP, 10.0)
	await _frames(28)
	client_local.use_test_input = true
	client_local.test_input = Vector2(0, -1)
	await _frames(24)
	client_local.test_input = Vector2.ZERO
	await _frames(10)
	_check(host.match_controller.get_status(client_id) == MatchController.Status.OUT and client.match_controller.get_status(client_id) == MatchController.Status.OUT, "red-light movement eliminates client on both rosters")
	_check(not client_local.controls_enabled, "eliminated client loses controls")
	host_local.global_position = Vector3(0, 0.1, GameLevel.FINISH_Z - 2)
	host_local.sync_position = host_local.global_position
	await _frames(12)
	_check(host.match_controller.get_status(1) == MatchController.Status.FINISHED and client.match_controller.get_status(1) == MatchController.Status.FINISHED, "finish and place reach both peers")
	_check(int(host.match_controller.roster[1]["place"]) == 1, "host places first")
	_check(host.match_controller.phase == MatchController.Phase.RESULTS and client.match_controller.phase == MatchController.Phase.RESULTS, "round ends in results")
	_check(int(host.match_controller.roster[1]["wins"]) == 1 and int(client.match_controller.roster[1]["wins"]) == 1, "winner receives a win on both peers")
	host.match_controller.time_left = 0.02
	await _frames(15)
	_check(host.match_controller.phase == MatchController.Phase.LOBBY and client.match_controller.phase == MatchController.Phase.LOBBY, "results return to lobby")
	_check(host.match_controller.get_status(1) == MatchController.Status.WAITING and host.match_controller.get_status(client_id) == MatchController.Status.WAITING, "lobby resets statuses")
	_check(host.match_controller.get_status(third_id) == MatchController.Status.WAITING, "late join can play next round")
	_check(host_local.global_position.z > GameLevel.START_Z and client_local.global_position.z > GameLevel.START_Z, "owners respawn behind start gate")
	client_local.global_position = host_local.global_position + Vector3(2, 0, 0)
	client_local.sync_position = client_local.global_position
	await _frames(12)
	var speed_before := client_local.velocity.length()
	var shove_count := [0]
	host.match_controller.shove_landed.connect(func(_a: int, _b: int) -> void: shove_count[0] += 1)
	host.match_controller.request_shove(client_id)
	await _frames(8)
	_check(client_local.velocity.length() > speed_before + 0.3 or client_local.global_position.distance_to(host_local.global_position) > 2.3, "shove impulse reaches target owner")
	var first_shoves: int = shove_count[0]
	host.match_controller.request_shove(client_id)
	await _frames(4)
	_check(shove_count[0] == first_shoves, "shove cooldown rejects immediate second shove")
	var third_local := third.players.get_node(str(third_id)) as RacePlayer
	third_local.global_position = Vector3(25, 0, GameLevel.START_Z + 5)
	third_local.sync_position = third_local.global_position
	await _frames(12)
	host.match_controller.request_shove(third_id)
	await _frames(5)
	_check(shove_count[0] == first_shoves, "shove rejects distant target")
	third.leave_game()
	await _frames(20)
	client.leave_game()
	await _frames(25)
	_check(host.match_controller.roster.size() == 1 and host.players.get_child_count() == 1, "client disconnect despawns on host")
	_check(client.menu.visible and client.players.get_child_count() == 0, "client returns to clean menu")
	host.leave_game()
	await _frames(8)
	host.host_game("   ", port)
	await _frames(12)
	_check(host.connected and host.players.get_child_count() == 1 and str(host.match_controller.roster[1]["name"]) == "Player 1", "same instance rehosts with clean roster and empty name fallback")
	_check(host.match_controller.round_number == 0 and host.match_controller.phase == MatchController.Phase.LOBBY, "rehost resets round state")
	client.join_game("127.0.0.1", "ABCDEFGHIJKLMNOPQRST", port)
	await _frames(60)
	var second_client_id := client.multiplayer.get_unique_id()
	_check(str(host.match_controller.roster[second_client_id]["name"]) == "ABCDEFGHIJKLMNOP", "long name is trimmed to sixteen characters")
	client.match_controller.request_player_ready.rpc_id(1, true)
	host.match_controller.request_player_ready(true)
	await _frames(8)
	host.match_controller.request_start()
	host.match_controller.time_left = 0.02
	await _frames(15)
	_check(host.match_controller.phase == MatchController.Phase.PLAYING, "rehost starts another round")
	host.match_controller._eliminate(1, "TEST")
	client.leave_game()
	await _frames(20)
	_check(host.match_controller.phase == MatchController.Phase.RESULTS, "last alive racer disconnect ends round")
	client.join_game("127.0.0.1", "Reconnect", port)
	await _frames(55)
	host.leave_game("Host ended game")
	await _frames(25)
	_check(client.menu.visible and not client.connected and client.players.get_child_count() == 0, "host departure returns client to clean menu")
	_check(client.menu._status.text == "Server disconnected", "host departure shows disconnect message")
	_finish()

func _viewport(view_name: String) -> SubViewport:
	var view := SubViewport.new()
	view.name = view_name
	view.size = Vector2i(1280, 720)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	set_multiplayer(SceneMultiplayer.new(), view.get_path())
	var game := MAIN.instantiate() as RaceMain
	view.add_child(game)
	if view_name == "HostView":
		host_view = view
		host = game
	elif view_name == "ClientView":
		client_view = view
		client = game
	else:
		third_view = view
		third = game
	return view

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: " + description)
	else:
		failures.append(description)
		push_error("FAIL: " + description)

func _finish() -> void:
	if host != null:
		host.leave_game()
	if client != null:
		client.leave_game()
	if third != null:
		third.leave_game()
	if failures.is_empty():
		print("RED_LIGHT_BLUE_LIGHT_SMOKE_TEST: PASS")
		quit(0)
	else:
		print("RED_LIGHT_BLUE_LIGHT_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)
