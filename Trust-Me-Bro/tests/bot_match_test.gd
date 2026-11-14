extends SceneTree
## Real-physics soak: all eight contestants think, run, fall, grab, and score.
## Run with Godot --headless --path Trust-Me-Bro --script res://tests/bot_match_test.gd
var failures: int = 0
var checks: int = 0
var game: Node3D
var manager: Node
var visited_rounds: Array[int] = []
var visited_questions: int = 0
var finished_count: int = 0
var finite_physics: bool = true
var unique_respawns: bool = true
var valid_competition_flags: bool = true
var max_junk_count: int = 0
var max_cube_count: int = 0
var old_time_scale: float = 1.0
var old_tick_rate: int = 60

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("BOT MATCH: " + message)

func _run() -> void:
	old_time_scale = Engine.time_scale
	old_tick_rate = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 6.0
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	manager = game.get_node("RoundManager")
	manager.rng.seed = 734501
	manager.questions_per_round = 2
	manager.question_seconds = 4.0
	manager.finale_seconds = 3.0
	manager.introduction_seconds = 0.12
	manager.reveal_seconds = 1.3
	manager.gacha_seconds = 0.12
	manager.bot_accuracy = 0.8
	manager.question_started.connect(_on_question)
	manager.match_finished.connect(_on_finished)
	game._start(1)
	for actor in manager.contestants:
		actor.is_bot = true
	var start_deadline: int = Time.get_ticks_msec() + 2000
	while manager.state != manager.State.QUESTION and Time.get_ticks_msec() < start_deadline:
		await process_frame
	check(manager.state == manager.State.QUESTION, "The real scene should start its first question")
	await _check_pause_and_help()
	var deadline: int = Time.get_ticks_msec() + 20000
	while manager.state != manager.State.RESULTS and Time.get_ticks_msec() < deadline:
		_sample_invariants()
		await process_frame
	check(manager.state == manager.State.RESULTS, "Unassisted bot physics should finish a complete match")
	check(visited_rounds == [0, 1, 2, 3, 4], "Unassisted bots should visit all five round rules")
	check(visited_questions >= 5 and visited_questions <= 10, "Every round should ask questions within its configured limit")
	check(finished_count == 1, "The bot match should finish exactly once")
	var total_score: int = 0
	var all_unfrozen: bool = true
	for actor in manager.contestants:
		total_score += actor.score
		all_unfrozen = all_unfrozen and not actor.freeze
	check(total_score > 0, "Real bots should earn points without test teleports or frozen bodies")
	check(all_unfrozen, "The soak must keep all contestants under real physics")
	check(finite_physics, "All live physics positions and velocities should remain finite")
	check(unique_respawns, "A falling contestant must never queue duplicate balcony respawns")
	check(valid_competition_flags, "Balcony spectators must stay outside active scoring")
	check(max_junk_count <= 24 and max_cube_count <= 7, "Physics props should respect the junk and cube caps")
	# Let any final fall complete its already-scheduled balcony transition.
	await create_timer(1.3).timeout
	check(manager.pending_respawns.is_empty(), "Results should finish any pending balcony returns")
	game.hud.help_overlay.show()
	game._restart()
	check(not game.hud.help_overlay.visible and not paused, "Starting replay with help open should close help and resume the scene")
	var clean_restart: bool = true
	for actor in manager.contestants:
		clean_restart = clean_restart and actor.active and not actor.spectator and actor.score == 0 and actor.perk.is_empty() and not actor.has_crown and not actor.ice and not actor.conveyor
	check(manager.state == manager.State.INTRO and manager.round_index == 0, "Replay should begin round one")
	check(clean_restart, "Replay should clear every score, perk, crown, spectator flag, and old round effect")
	check(not manager.arena.blackout and not manager.arena.sweeper_active and not manager.arena.conveyor_active, "Replay should clear blackout, sweeper, and finale hazards")
	game._menu()
	check(not paused and manager.state == manager.State.MENU, "Menu return should leave the scene unpaused")
	print("BOT MATCH: %d questions, %d total points, peak %d junk / %d cubes" % [visited_questions, total_score, max_junk_count, max_cube_count])
	manager.set_physics_process(false)
	manager.sfx.playing = false
	for voice in manager.sfx.voices:
		voice.stop()
		voice.stream = null
	await create_timer(0.12, true, false, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = old_time_scale
	Engine.physics_ticks_per_second = old_tick_rate
	print("BOT MATCH TEST: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _check_pause_and_help() -> void:
	game._toggle_pause()
	var paused_time: float = manager.time_left
	var paused_position: Vector3 = manager.contestants[0].global_position
	check(paused and game.hud.pause_overlay.visible, "Pause should suspend the scene and show the pause overlay")
	await create_timer(0.06, true, false, true).timeout
	check(is_equal_approx(manager.time_left, paused_time) and manager.contestants[0].global_position.is_equal_approx(paused_position), "Pause should freeze both quiz countdown and contestant physics")
	game._toggle_pause()
	check(not paused and not game.hud.pause_overlay.visible, "Resume should restore the live scene")
	game.hud.help_overlay.show()
	await process_frame
	var help_time: float = manager.time_left
	check(paused and game.paused, "Opening the help sheet during play should pause the match")
	await create_timer(0.06, true, false, true).timeout
	check(is_equal_approx(manager.time_left, help_time), "The help sheet should freeze the quiz countdown")
	game.hud.help_overlay.hide()
	await process_frame
	check(not paused and not game.paused, "Closing the help sheet should resume the match")

func _on_question(round_number: int, _question_number: int) -> void:
	visited_questions += 1
	if not visited_rounds.has(round_number): visited_rounds.append(round_number)

func _on_finished() -> void:
	finished_count += 1

func _sample_invariants() -> void:
	max_junk_count = maxi(max_junk_count, manager.junk.size())
	max_cube_count = maxi(max_cube_count, manager.cubes.size())
	var pending_ids: Dictionary = {}
	for entry in manager.pending_respawns:
		var id: int = entry.actor.contestant_id
		if pending_ids.has(id): unique_respawns = false
		pending_ids[id] = true
	for actor in manager.contestants:
		finite_physics = finite_physics and actor.global_position.is_finite() and actor.linear_velocity.is_finite()
		valid_competition_flags = valid_competition_flags and not (actor.active and actor.spectator)
