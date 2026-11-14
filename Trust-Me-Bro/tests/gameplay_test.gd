extends SceneTree
## Run: Godot --headless --path Trust-Me-Bro --script res://tests/gameplay_test.gd
## Exercises the actual scene, physics actors, round rules, and timed match flow.
var failures: int = 0
var checks: int = 0
var game: Node3D
var manager: Node
var visited_rounds: Array[int] = []
var timed_question_count: int = 0
var finished_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("GAMEPLAY: " + message)

func frames(count: int = 2) -> void:
	for i in count:
		await physics_frame
	await process_frame

func place_actor(actor: RigidBody3D, pos: Vector3, competing: bool = true) -> void:
	actor.freeze = true
	actor._teleport_pending = false
	actor.global_transform = Transform3D(Basis.IDENTITY, pos)
	actor.linear_velocity = Vector3.ZERO
	actor.angular_velocity = Vector3.ZERO
	actor.active = competing
	actor.spectator = false
	actor.bot_moving = false
	actor.controls_enabled = true
	actor.has_crown = false
	actor.reset_physics_interpolation()

func prepare_case(round_number: int, correct: int = 0) -> void:
	manager.set_physics_process(false)
	manager.start_match(1)
	manager.round_index = round_number
	manager._begin_round()
	var questions: Array[Dictionary] = [{"prompt": "TEST: choose the first option.", "answers": ["Correct", "Wrong", "Also wrong", "Still wrong"], "correct": correct}]
	manager.deck = questions
	manager.deck_cursor = 0
	manager._begin_question()
	manager.pending_respawns.clear()
	for i in manager.contestants.size():
		var actor: RigidBody3D = manager.contestants[i]
		place_actor(actor, manager.arena.tile_centers[i % 4] + Vector3(0.0, 1.0, 0.0))
		actor.set_perk("")
		actor.score = 0

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		check(false, "Main scene must load")
		quit(1)
		return
	game = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await frames(4)
	manager = game.get_node("RoundManager")
	manager.set_physics_process(false)
	check(manager.contestants.size() == 8, "The studio should populate eight contestants")
	check(manager.state == manager.State.MENU, "The scene should open on the menu")
	await _check_scoring_and_balcony()
	await _check_physical_fall()
	await _check_controls()
	await _check_cube_round()
	await _check_actions_and_spectator()
	await _check_gacha_and_swap()
	await _check_blackout()
	await _check_natural_match()
	manager.return_to_menu()
	check(manager.state == manager.State.MENU, "Results should return to the main menu")
	check(manager.cubes.is_empty() and manager.junk.is_empty(), "Returning to menu should clear match props")
	manager.start_match(2)
	manager.set_physics_process(false)
	check(manager.state == manager.State.INTRO and manager.round_index == 0, "Restart should begin round one")
	check(manager.contestants[0].human_slot == 0 and manager.contestants[1].human_slot == 1, "Two-player start should bind two separate control slots")
	var reset_scores: bool = true
	for actor in manager.contestants:
		reset_scores = reset_scores and actor.score == 0 and actor.active and not actor.spectator
	check(reset_scores, "Restart should restore all contestants with zero scores")
	# Drain active audio playback before disposing the standalone scene.
	manager.sfx.shutdown()
	# Reproduce a late countdown callback during shutdown; it must stay silent.
	manager.sfx.play("ready")
	var silent_after_shutdown: bool = true
	for voice in manager.sfx.voices:
		silent_after_shutdown = silent_after_shutdown and not voice.playing and voice.stream == null
	check(silent_after_shutdown, "Audio shutdown must release every voice and reject late countdown cues")
	await create_timer(0.12).timeout
	game.queue_free()
	await process_frame
	await process_frame
	print("GAMEPLAY TEST: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _check_scoring_and_balcony() -> void:
	prepare_case(0, 0)
	var survivor: RigidBody3D = manager.contestants[0]
	var loser: RigidBody3D = manager.contestants[1]
	survivor.score = 50
	survivor.has_crown = true
	loser.score = 325
	loser.has_crown = true
	place_actor(survivor, manager.arena.tile_centers[0] + Vector3.UP)
	survivor.has_crown = true
	place_actor(loser, manager.arena.tile_centers[1] + Vector3.UP)
	loser.has_crown = true
	manager._reveal()
	check(manager.state == manager.State.REVEAL, "Buzzer should enter answer reveal")
	check(survivor.active and survivor.score == 250, "Correct crowned contestant should receive double the 100-point award")
	check(not loser.active and loser.score == 0, "A wrong answer with the cursed crown should wipe the entire score")
	check(manager.pending_respawns.size() >= 1, "Eliminated contestants should queue for the balcony")
	manager._update_respawns(1.2)
	loser.freeze = false
	await frames(3)
	check(loser.spectator and not loser.active and loser.global_position.z < -9.0, "Eliminated contestants should return on the revenge balcony")
	manager._begin_round()
	check(loser.active and not loser.spectator, "The next round should restore eliminated contestants")

func _check_physical_fall() -> void:
	prepare_case(0, 0)
	var actor: RigidBody3D = manager.contestants[0]
	actor.freeze = false
	actor.has_crown = true
	actor.score = 600
	actor.respawn(Vector3(14.0, -5.8, 14.0), false)
	actor.has_crown = true
	await frames(20)
	check(not actor.active, "A real physics fall must eliminate the contestant")
	check(actor.score == 0, "A real physics fall while crowned must wipe the score")
	check(manager.pending_respawns.size() == 1, "A real fall should queue exactly one balcony return")
	manager._update_respawns(1.2)
	await frames(3)
	check(actor.spectator and actor.global_position.z < -9.0, "A fallen physics actor should reappear on the balcony")

func _check_controls() -> void:
	prepare_case(0, 0)
	var actor: RigidBody3D = manager.contestants[0]
	for other in manager.contestants:
		if other != actor:
			place_actor(other, Vector3(40.0 + other.contestant_id * 2.0, 2.0, 40.0))
	actor.freeze = false
	actor.respawn(manager.arena.tile_centers[0] + Vector3.UP, false)
	await frames(15)
	var start_x: float = actor.global_position.x
	Input.action_press(actor._prefix + "right")
	await frames(12)
	Input.action_release(actor._prefix + "right")
	check(actor.global_position.x > start_x + 0.3, "The bound movement action should move a real human rigidbody")
	var jump_event: InputEventAction = InputEventAction.new()
	jump_event.action = StringName(actor._prefix + "jump")
	jump_event.pressed = true
	Input.parse_input_event(jump_event)
	await frames(3)
	check(actor.linear_velocity.y > 1.5, "A dispatched jump action should launch the grounded human")
	jump_event.pressed = false
	Input.parse_input_event(jump_event)

func _check_cube_round() -> void:
	prepare_case(2, 0)
	check(manager.cubes.size() == manager.contestants.size() - 1, "Musical cubes should spawn exactly one fewer cube than active contestants")
	var correct_cube: RigidBody3D = null
	var wrong_cube: RigidBody3D = null
	for cube in manager.cubes:
		if cube.answer_index == 0 and correct_cube == null:
			correct_cube = cube
		elif cube.answer_index != 0 and wrong_cube == null:
			wrong_cube = cube
	check(correct_cube != null and wrong_cube != null, "Cube round should offer both correct and wrong letter cubes")
	if correct_cube == null or wrong_cube == null:
		return
	var winner: RigidBody3D = manager.contestants[0]
	var wrong_holder: RigidBody3D = manager.contestants[1]
	correct_cube.take(winner)
	wrong_cube.take(wrong_holder)
	manager._reveal()
	check(winner.active and winner.score == 150, "Holding the correct cube should qualify independently of floor position")
	check(not wrong_holder.active and wrong_holder.score == 0, "Holding the wrong cube should eliminate the contestant")
	check(not manager.contestants[2].active, "An empty-handed contestant must lose the cube round")
	check(manager.arena.get_tile_at(manager.arena.tile_centers[1] + Vector3.UP) == 1, "Cube round must keep all four floor pads solid")
	manager._after_reveal()
	check(manager.state == manager.State.GACHA and manager.round_index == 3, "A last surviving cube holder should advance the round instead of receiving an impossible zero-cube question")

func _check_actions_and_spectator() -> void:
	prepare_case(0, 0)
	var actor: RigidBody3D = manager.contestants[0]
	manager._on_action(actor, "dive")
	check(actor._dive_left > 0.0, "Dive action should trigger a physical dive")
	manager._on_action(actor, "emote")
	check(actor._emote_left > 0.0, "Emote action should animate the contestant")
	manager._eliminate(actor)
	manager._update_respawns(1.2)
	actor.freeze = false
	await frames(3)
	var before: int = manager.junk.size()
	actor.shove_cooldown = 0.0
	var event: InputEventAction = InputEventAction.new()
	event.action = StringName(actor._prefix + "shove")
	event.pressed = true
	actor._unhandled_input(event)
	check(manager.junk.size() == before + 1, "An eliminated human should use their shove button to toss balcony junk")

func _check_gacha_and_swap() -> void:
	prepare_case(0, 0)
	manager.rng.seed = 44217
	manager._roll_gacha()
	var perk_counts: Dictionary = {}
	for actor in manager.contestants:
		perk_counts[actor.perk] = int(perk_counts.get(actor.perk, 0)) + 1
	check(int(perk_counts.get("nerd", 0)) == 1 and int(perk_counts.get("heavy", 0)) == 1 and int(perk_counts.get("pinball", 0)) == 1 and int(perk_counts.get("swapper", 0)) == 1, "Gacha should assign one nerd, one heavy, one pinball, and one trailing-player swapper")
	var heavy_actor: RigidBody3D = null
	for actor in manager.contestants:
		if actor.perk == "heavy": heavy_actor = actor
	check(heavy_actor != null and heavy_actor.mass > 1.9, "Heavy boots should change the real rigidbody mass")
	var swapper: RigidBody3D = manager.contestants[0]
	var target: RigidBody3D = manager.contestants[1]
	for actor in manager.contestants:
		actor.active = false
		actor.spectator = false
		actor.set_perk("")
	place_actor(swapper, Vector3(-3.4, 1.0, -3.4))
	place_actor(target, Vector3(3.4, 1.0, 3.4))
	swapper.set_perk("swapper")
	var old_swapper: Vector3 = swapper.global_position
	var old_target: Vector3 = target.global_position
	manager._execute_swappers()
	check(swapper.global_position.distance_to(old_target) < 0.5 and target.global_position.distance_to(old_swapper) < 0.5, "Swapper should exchange two live players' positions")
	check(swapper.perk.is_empty(), "A swapper should be consumed after one use")

func _check_blackout() -> void:
	prepare_case(1, 0)
	manager.elapsed = 3.05
	manager._update_question(0.016)
	check(manager.arena.blackout, "Round two should black out after three seconds")
	check(manager.contestants[0].flashlight.visible, "Blackout must enable the contestant's flashlight")
	manager._reveal()
	check(not manager.arena.blackout and not manager.contestants[0].flashlight.visible, "Answer reveal should restore stadium lights and disable flashlights")

func _on_timed_question(round_number: int, _question_number: int) -> void:
	timed_question_count += 1
	if not visited_rounds.has(round_number): visited_rounds.append(round_number)
	# A stationary correct contestant keeps two questions alive per round while
	# all state transitions and timers advance through the actual game loop.
	for actor in manager.contestants:
		if actor.active:
			place_actor(actor, manager.arena.tile_centers[int(manager.current_question.correct)] + Vector3(-1.0 + actor.contestant_id * 0.2, 1.0, 0.0))
	if round_number == 2:
		for cube in manager.cubes:
			if cube.answer_index == int(manager.current_question.correct):
				cube.take(manager.contestants[0])
				break

func _on_match_finished() -> void:
	finished_count += 1

func _check_natural_match() -> void:
	manager.questions_per_round = 2
	manager.question_seconds = 0.12
	manager.finale_seconds = 0.12
	manager.introduction_seconds = 0.06
	manager.reveal_seconds = 0.08
	manager.gacha_seconds = 0.06
	manager.safe_zone_shrink_rate = 0.0
	manager.question_started.connect(_on_timed_question)
	manager.match_finished.connect(_on_match_finished)
	manager.set_physics_process(true)
	manager.start_match(1)
	var deadline: int = Time.get_ticks_msec() + 12000
	while manager.state != manager.State.RESULTS and Time.get_ticks_msec() < deadline:
		await physics_frame
	manager.set_physics_process(false)
	check(manager.state == manager.State.RESULTS, "An accelerated timed match should reach final results")
	check(visited_rounds == [0,1,2,3,4], "The natural match should visit all five round rules in order")
	check(timed_question_count == 9, "The natural match should ask two questions per round and finish the cube round once a lone holder wins")
	check(finished_count == 1, "A completed match should emit match_finished exactly once")
	check(manager.contestants[0].score > 0, "The completed match should retain earned points")
	check(not manager.arena.blackout and not manager.arena.sweeper_active and not manager.arena.conveyor_active, "Results should shut down arena hazards")
	manager.question_started.disconnect(_on_timed_question)
	manager.match_finished.disconnect(_on_match_finished)
