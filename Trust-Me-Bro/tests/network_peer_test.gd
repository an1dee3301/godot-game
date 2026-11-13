extends SceneTree
## A real ENet peer launched by run_network_test.py. Both roles use the game scene.
var game: Node
var session: Node
var manager: Node
var role: String = "host"
var room_port: int = 25387
var report_path: String = "/tmp/trust-network-peer.json"
var checks: int = 0
var failures: Array[String] = []
var deadline: int = 0
var started: bool = false
var movement_started: bool = false
var movement_released: bool = false
var movement_time: float = 0.0
var question_seen: int = 0
var rounds_seen: Array[int] = []
var remote_start_x: float = 0.0
var remote_moved: bool = false
var scored: bool = false
var snapshot_privacy: bool = false
var disconnected: bool = false
var completed: bool = false
var snapshots_at_results: int = 0
var replay_started: bool = false
var saw_results: bool = false
var results_wait: float = 0.0
var client_owner: int = 0
var initial_camera: Transform3D
var report: Dictionary = {}
var close_reason: String = ""
var saw_smoke: bool = false
var saw_held_cube: bool = false
var saw_private_hint: bool = false
var tv_rounds_seen: Array[int] = []
var tv_question_private: bool = true

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--network-test-role="): role = argument.get_slice("=",1)
		elif argument.begins_with("--network-test-port="): room_port = int(argument.get_slice("=",1))
		elif argument.begins_with("--network-test-report="): report_path = argument.get_slice("=",1)
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error("NETWORK " + role + ": " + message)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	game = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	manager = game.get_node("RoundManager")
	session = game.get_node_or_null("NetworkSession")
	if session == null:
		session = load("res://scripts/network_session.gd").new()
		session.name = "NetworkSession"
		game.add_child(session)
		session.configure(manager,game.hud)
	initial_camera = game.camera.transform
	deadline = Time.get_ticks_msec() + (16000 if role == "late" or role == "failure" else 42000)
	manager.question_started.connect(_on_question)
	session.session_closed.connect(_on_closed)
	if role == "host":
		manager.questions_per_round = 1
		manager.question_seconds = 2.6
		manager.finale_seconds = 2.6
		manager.introduction_seconds = 0.18
		manager.reveal_seconds = 0.55
		manager.gacha_seconds = 0.18
		manager.safe_zone_shrink_rate = 0.0
		manager.sweeper_force = 0.0
		manager.conveyor_strength = 0.0
		manager.bot_accuracy = 0.8
		check(session.host_room("Test Host",room_port) == OK,"Host should create an ENet room")
	else:
		check(session.join_room("127.0.0.1","Test Friend",room_port) == OK,"Client should create an ENet connection")
	while not completed and Time.get_ticks_msec() < deadline:
		await physics_frame
		if role == "host": _host_tick()
		else: _client_tick()
	if not completed: check(false,"Peer should finish before timeout")
	if role == "host":
		check(rounds_seen == [0,1,2,3,4],"Host should play all five rules over the network")
		check(remote_moved,"Client input should move the host's authoritative remote character")
		check(snapshot_privacy,"Public question packets should withhold the correct answer while the nerd receives only their private hint")
		check(scored,"Network human should earn authoritative points")
		check(disconnected,"A departed client should be replaced by a bot")
		check(session.received_input_packets > 15,"Host should validate real client movement packets")
		check(not manager.client_mode,"Host should own the simulation")
	elif role == "late":
		check(close_reason.contains("already started"),"Late joining should show a clear already-started explanation")
		check(not session.active,"Rejected late join should close the network peer")
		check(manager.state == manager.State.MENU,"Rejected late join should restore the playable menu")
	elif role == "failure":
		check(not close_reason.is_empty(),"An unreachable host should provide a connection failure explanation")
		check(not session.active,"A failed join should close the network peer")
		check(manager.state == manager.State.MENU,"A failed join should restore the playable menu")
	else:
		check(snapshots_at_results > 30,"Client should receive a continuous stream of snapshots")
		check(scored,"Client should see the host's replicated score")
		check(rounds_seen == [0,1,2,3,4],"Client should see all five round rules")
		check(movement_started and movement_released,"Client should dispatch and release real input actions")
		check(snapshot_privacy,"Client should not receive a public correct answer before the buzzer")
		check(saw_private_hint,"The remote nerd should receive their own private answer hint")
		check(saw_smoke,"Smoke bomb impact clouds should replicate to clients")
		check(saw_held_cube,"Held correct answer cubes should replicate with their remote owner")
		check(game.camera.transform == initial_camera,"Networking must preserve the shared fixed camera")
		check(tv_rounds_seen == [0,1,2,3,4],"Client's physical TV must display the replicated prompt and all four choices in every round")
		check(tv_question_private and not tv_rounds_seen.is_empty(),"Client's public TV must not reveal a correct answer or reveal colors before the buzzer")
	report = {"role":role,"checks":checks,"failures":failures,"rounds":rounds_seen,"input_packets":session.received_input_packets,"snapshots":snapshots_at_results,"remote_moved":remote_moved,"scored":scored}
	var file: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	if session.active: session.close_session()
	for voice in game.sfx.voices:
		voice.stop()
		voice.stream = null
	game.sfx.playing = false
	await create_timer(1.8).timeout
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	print("NETWORK ",role," TEST: ",checks," checks, ",failures.size()," failures")
	quit(1 if not failures.is_empty() else 0)

func _host_tick() -> void:
	if not started and session.players.size() == 2:
		var ready: bool = true
		for player in session.players: ready = ready and bool(player.ready)
		if ready:
			started = true
			client_owner = int(session.players[1].id)
			session.start_match()
			print("NETWORK_MATCH_STARTED")
	if not session.in_match: return
	if manager.state == manager.State.QUESTION:
		if not rounds_seen.has(manager.round_index): rounds_seen.append(manager.round_index)
		var actor: Node = manager.contestants[1]
		if manager.round_index == 0 and actor.global_position.x > remote_start_x + 0.25: remote_moved = true
		if manager.time_left < 0.45:
			for i in 2:
				var human: Node = manager.contestants[i]
				if not human.active: continue
				var pos: Vector3 = manager.arena.tile_centers[int(manager.current_question.correct)] + Vector3(-1.0 if i == 0 else 1.0,1.0,0)
				human.respawn(pos,false)
				if manager.round_index == 2:
					for cube in manager.cubes:
						if cube.answer_index == int(manager.current_question.correct) and (not is_instance_valid(cube.holder) or cube.holder == human):
							cube.take(human)
							break
		if manager.round_index == 0:
			var client_packet: Dictionary = manager.make_network_snapshot(client_owner)
			var host_packet: Dictionary = manager.make_network_snapshot(1)
			snapshot_privacy = not client_packet.question.has("correct") and not host_packet.question.has("correct") and int(client_packet.private_hint) == int(manager.current_question.correct) and int(host_packet.private_hint) == -1
		if actor.score > 0: scored = true
	if manager.contestants[1].score > 0: scored = true
	if manager.state == manager.State.RESULTS and not replay_started:
		results_wait += 1.0 / 60.0
		if results_wait > 0.35:
			replay_started = true
			session.restart_match()
			check(manager.contestants[1].score == 0,"Host replay should reset all network player scores")
	if replay_started and manager.contestants[1].is_bot:
		disconnected = true
		completed = true

func _client_tick() -> void:
	if role == "late" or role == "failure": return
	if not session.active:
		if not completed: check(false,"Client should stay connected through the match")
		completed = true
		return
	if not session.in_match:
		if session.players.size() == 2: session.set_ready(true)
		return
	if not rounds_seen.has(manager.round_index): rounds_seen.append(manager.round_index)
	if not manager._network_clouds.is_empty(): saw_smoke = true
	if manager.round_index == 2 and is_instance_valid(manager.contestants[session.local_actor_index].held_cube): saw_held_cube = true
	if manager.round_index == 0 and manager._network_private_hint >= 0: saw_private_hint = true
	if manager.state == manager.State.QUESTION:
		var screen: Node3D = game.arena.quiz_screen
		var tv_matches: bool = screen._question.text == str(manager.current_question.get("prompt",""))
		var choices: Array = manager.current_question.get("answers",[])
		for i: int in 4:
			tv_matches = tv_matches and choices.size() == 4 and screen._answers[i].text == str(choices[i]) and screen._letters[i].text == "ABCD"[i]
			var material: StandardMaterial3D = screen._plates[i].material_override as StandardMaterial3D
			tv_question_private = tv_question_private and screen._answers[i].modulate == screen.INK and material.albedo_color == screen.COLORS[i]
		if tv_matches and not tv_rounds_seen.has(manager.round_index): tv_rounds_seen.append(manager.round_index)
		tv_question_private = tv_question_private and not manager.current_question.has("correct") and not screen._key.begins_with("answer:")
		if manager.round_index == 0 and not movement_started:
			movement_started = true
			movement_time = 0.0
			Input.action_press("bro_p0_right")
		if movement_started and not movement_released:
			movement_time += 1.0 / 60.0
			if movement_time > 0.3:
				Input.action_release("bro_p0_right")
				movement_released = true
		if not manager.current_question.has("correct"): snapshot_privacy = true
	if manager.contestants[session.local_actor_index].score > 0: scored = true
	if manager.state == manager.State.RESULTS and not saw_results:
		saw_results = true
		snapshots_at_results = session.received_snapshots
		check(manager.client_mode,"Client must render snapshots without simulating match rules")
		check(manager.contestants[session.local_actor_index].network_replica,"Client contestant bodies should be frozen replicas")
	if saw_results and manager.state == manager.State.INTRO:
		check(manager.contestants[session.local_actor_index].score == 0,"Host replay should reset replicated client scores")
		check(manager.round_index == 0,"Host replay should return every peer to round one")
		session.close_session()
		completed = true

func _on_question(_round_number: int, _question: int) -> void:
	if role != "host": return
	question_seen += 1
	for actor in manager.contestants:
		if actor.contestant_id >= 2:
			actor.controls_enabled = false
			actor.is_bot = false
	if manager.round_index == 0:
		remote_start_x = manager.contestants[1].global_position.x
		manager.contestants[1].set_perk("nerd")
		# Trigger the real impact handler; the cloud must appear on another process.
		var smoke: RigidBody3D = load("res://scripts/answer_cube.gd").new()
		smoke.is_junk = true
		smoke.smoke = true
		manager.arena.add_child(smoke)
		smoke.global_position = manager.contestants[1].global_position + Vector3.UP
		manager.junk.append(smoke)
		smoke._on_body_entered(manager.contestants[1])

func _on_closed(reason: String) -> void:
	close_reason = reason
	if role == "late" or role == "failure": completed = true
