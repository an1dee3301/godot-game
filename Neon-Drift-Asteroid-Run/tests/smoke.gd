extends SceneTree

var game
var failures: Array[String] = []


func _initialize() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run_checks")


func _run_checks() -> void:
	await process_frame
	_check(game.state == game.GameState.TITLE, "Game should open on the title screen")
	_check(game.asteroids.size() == 7, "Title screen should have drifting asteroids")

	# Audio playback is not part of this logic test and can outlive an immediate headless quit.
	game.sound_fx.muted = true
	game.start_new_game()
	await process_frame
	_check(game.state == game.GameState.PLAYING, "Starting should enter the playing state")
	_check(game.wave == 1, "A new run should begin on wave one")
	_check(game.lives == 3, "A new run should begin with three ships")
	_check(game.asteroids.size() == 4, "Wave one should spawn four large asteroids")
	_check(is_instance_valid(game.ship), "The player ship should spawn")

	var first_asteroid = game.asteroids[0]
	_check(first_asteroid.size_level == 3, "Wave asteroids should begin at large size")
	_check(first_asteroid.radius > 40.0, "Large asteroid collision radius should be initialized")

	game._destroy_asteroid(first_asteroid, true)
	_check(game.score == 20, "Destroying a large asteroid should award 20 base points")
	_check(game.asteroids.size() == 5, "A destroyed large asteroid should split into two fragments")
	var medium_count := 0
	for asteroid in game.asteroids:
		if asteroid.size_level == 2:
			medium_count += 1
	_check(medium_count == 2, "A large asteroid should create two medium asteroids")
	_check(game._toroidal_distance(Vector2(2, 100), Vector2(1150, 100)) < 5.0, "Collision distance should wrap across screen edges")
	_check(InputMap.has_action("fire") and InputMap.has_action("pause"), "Required input actions should be registered")

	if failures.is_empty():
		print("SMOKE TEST PASSED: title, start, wave, splitting, scoring, wrapping, and input are valid.")
		await _clean_exit(0)
	else:
		for failure in failures:
			push_error("SMOKE TEST FAILED: " + failure)
		await _clean_exit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _clean_exit(exit_code: int) -> void:
	game.sound_fx.stop_all()
	await process_frame
	game.queue_free()
	await process_frame
	quit(exit_code)
