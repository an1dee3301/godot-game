extends SceneTree
## Headless end-to-end checks: menu -> run -> pickups -> shield -> route gates -> game over -> restart.
## Run: Godot --headless --path . -s res://tests/smoke_test.gd

const MAIN := preload("res://scenes/main.tscn")
var failures: Array[String] = []
var main: RunnerMain


var _saved_scores: PackedByteArray = PackedByteArray()


func _initialize() -> void:
	# Keep the player's real high score untouched by test runs.
	if FileAccess.file_exists(BP.SAVE_PATH):
		_saved_scores = FileAccess.get_file_as_bytes(BP.SAVE_PATH)
	call_deferred("_run")


func _restore_save() -> void:
	if _saved_scores.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BP.SAVE_PATH))
	else:
		FileAccess.open(BP.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved_scores)


func _run() -> void:
	main = MAIN.instantiate() as RunnerMain
	root.add_child(main)
	await _frames(5)

	# Start state
	_check(main.state == RunnerMain.State.MENU, "starts in MENU")
	_check(main.menus.is_showing("start"), "start screen visible")
	_check(InputMap.has_action("jump") and InputMap.has_action("slide") and InputMap.has_action("move_left"), "input actions registered")
	for child_name in ["Environment", "Track", "Player", "Camera", "PowerUps", "SoundFX", "HUD", "Menus"]:
		_check(main.get_node_or_null(child_name) != null, "child %s exists" % child_name)

	main.start_run()
	await _frames(3)
	_check(main.state == RunnerMain.State.PLAYING, "PLAYING after start_run")
	_check(not main.menus.is_showing("start"), "start screen hidden")
	_check(main.track.active_segments().size() >= 3, "track built ahead")
	_check(main.player.anim != null and main.player.anim.has_animation("run") and main.player.anim.has_animation("jump"), "run/jump animations exist")

	# Forward movement
	var z0 := main.player.global_position.z
	await _frames(30)
	_check(main.player.global_position.z < z0 - 3.0, "player auto-moves forward (-Z)")
	_check(main.distance > 3.0 and main.score > 0, "distance and score increase")
	_check(main.player.anim.current_animation == "run", "run animation playing (got %s)" % main.player.anim.current_animation)

	# Lane switching
	_check(main.player.move_lane(-1), "move_lane left accepted")
	await _frames(20)
	_check(main.player.lane == 0 and absf(main.player.global_position.x - BP.lane_x(0)) < 0.3, "moved to left belt")
	main.player.move_lane(1)
	await _frames(20)

	# Jump / slide
	_check(main.player.jump(), "jump accepted")
	var peak := 0.0
	var saw_jump_anim := false
	for i in 30:
		await physics_frame
		peak = maxf(peak, main.player.global_position.y)
		saw_jump_anim = saw_jump_anim or main.player.anim.current_animation == "jump"
	_check(peak >= 1.8, "jump reaches >= 1.8 m (got %.2f)" % peak)
	_check(saw_jump_anim, "jump animation played")
	await _frames(30)
	_check(main.player.is_grounded(), "landed after jump")
	_check(main.player.slide() and main.player.is_sliding, "slide accepted")
	await _frames(60)
	_check(not main.player.is_sliding, "slide ends")

	# Collectibles
	var tag := _make_pickup(Pickup.Type.TAG)
	var before_score := main.score
	var before_tags := main.tags
	main.player.pickup_collected.emit(tag)
	await _frames(2)
	_check(main.tags == before_tags + 1 and main.score >= before_score + 10, "tag adds count and score")
	_check(main.weight > 0.0, "tags add weight")

	# Checkpoint clears weight
	var checkpoint := TrackTrigger.new()
	checkpoint.kind = "checkpoint"
	main.add_child(checkpoint)
	main.player.trigger_entered.emit(checkpoint)
	await _frames(2)
	_check(is_zero_approx(main.weight), "checkpoint clears weight")

	# Wrong destination gates
	var dest := main.destination
	var ok_before := main.routes_ok
	var good := TrackTrigger.new()
	good.kind = "route"
	good.data = {"code": dest, "lane": 0}
	main.add_child(good)
	main.player.trigger_entered.emit(good)
	await _frames(2)
	_check(main.routes_ok == ok_before + 1, "correct route counted")
	_check(main.destination != dest, "new destination after fork")
	var bad := TrackTrigger.new()
	bad.kind = "route"
	bad.data = {"code": "???", "lane": 2}
	main.add_child(bad)
	main.player.trigger_entered.emit(bad)
	await _frames(2)
	_check(main.routes_bad == 1, "wrong route counted")

	# Boost
	main.player.pickup_collected.emit(_make_pickup(Pickup.Type.PRIORITY))
	await _frames(2)
	_check(main.power_ups.is_boosting() and main.power_ups.score_multiplier() > 1.0, "priority boost active")

	# Shield absorbs one hit
	main.player.pickup_collected.emit(_make_pickup(Pickup.Type.FRAGILE))
	await _frames(2)
	_check(main.power_ups.shield_active, "fragile shield active")
	var hazard := Hazard.new()
	hazard.display_name = "Test Suitcase"
	main.add_child(hazard)
	main.player.hazard_hit.emit(hazard)
	await _frames(2)
	_check(main.state == RunnerMain.State.PLAYING, "shield absorbed hit")
	_check(not main.power_ups.shield_active and not hazard.lethal, "shield consumed and hazard disabled")

	# Track lifecycle: run a while, segments recycle, variety appears
	main.player.set_collision_mask_value(1, true)
	var start_recycled := main.track.recycled_count
	main.player.hitbox.monitoring = false  # invulnerable for the long run
	for i in 600:
		main.player.global_position.y = maxf(main.player.global_position.y, 0.0)
		await physics_frame
	_check(main.track.recycled_count > start_recycled, "old segments recycled (%d)" % main.track.recycled_count)
	_check(main.track.active_segments().size() < 20, "segment count bounded (%d)" % main.track.active_segments().size())
	var types := {}
	for t in main.track.spawned_history:
		types[t] = true
	_check(types.size() >= 5, "at least 5 segment variations spawned (%s)" % str(types.keys()))
	_check(main.difficulty.base_speed() > 12.0, "difficulty speeds up over distance")

	# Pause
	main.toggle_pause()
	await _frames(2)
	_check(main.state == RunnerMain.State.PAUSED and paused and main.menus.is_showing("pause"), "pause works")
	main.toggle_pause()
	await _frames(2)
	_check(main.state == RunnerMain.State.PLAYING and not paused, "resume works")

	# Game over
	main.player.hitbox.monitoring = true
	var lethal := Hazard.new()
	lethal.display_name = "Giant Suitcase"
	main.add_child(lethal)
	main.player.hazard_hit.emit(lethal)
	await _frames(2)
	_check(main.state == RunnerMain.State.GAME_OVER, "hazard causes game over")
	_check(not main.player.alive, "player dead")
	await _seconds(1.6)
	_check(main.menus.is_showing("game_over"), "game over screen shown")
	_check(main.high_score >= main.score, "high score updated")

	# Restart
	main.restart()
	await _frames(5)
	_check(main.state == RunnerMain.State.PLAYING and main.score < 50 and main.player.alive, "restart resets the run")
	_check(not main.menus.is_showing("game_over"), "game over hidden after restart")
	_check(main.player.global_position.z > -10.0, "player back at start")

	# Falling into a gap ends the run
	main.player.fell.emit()
	await _frames(2)
	_check(main.state == RunnerMain.State.GAME_OVER, "falling causes game over")

	_finish()


func _make_pickup(type: Pickup.Type) -> Pickup:
	var pickup := Pickup.new()
	pickup.type = type
	main.add_child(pickup)
	return pickup


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _seconds(time: float) -> void:
	await create_timer(time, true).timeout


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  PASS ", label)
	else:
		print("  FAIL ", label)
		failures.append(label)


func _finish() -> void:
	paused = false
	if failures.is_empty():
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED: ", failures.size(), " failure(s)")
		for failure in failures:
			print("   - ", failure)
	_restore_save()
	quit(0 if failures.is_empty() else 1)
