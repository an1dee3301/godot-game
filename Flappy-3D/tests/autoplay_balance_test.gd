extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("main scene loads")
		return
	var game := packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set("_best_score", 9999)
	(game.get("_rng") as RandomNumberGenerator).seed = 24680
	game.call("_request_flap")

	var bird := game.get_node("Bird") as CharacterBody3D
	var pipes := game.get_node("Pipes") as Node3D
	var target_y := 2.45
	for frame in 1000:
		await physics_frame
		if int(game.get("_state")) != 1:
			_fail("autopilot survives long enough to prove the opening balance (frame=%d score=%d target=%.2f bird=%s velocity=%s)" % [frame, int(game.get("_score")), target_y, bird.position, bird.velocity])
			return
		if int(game.get("_score")) >= 3:
			game.queue_free()
			call_deferred("_finish_success")
			return

		target_y = 2.45
		var nearest_distance := INF
		for child in pipes.get_children():
			var pair := child as Node3D
			var distance := bird.global_position.z - pair.global_position.z
			if distance > -2.0 and distance < nearest_distance:
				nearest_distance = distance
				target_y = float(pair.get("_gap_center"))

		var predicted_y := bird.position.y + bird.velocity.y * 0.12
		if predicted_y < target_y - 1.08 and bird.velocity.y < 0.2:
			game.call("_do_flap")

	_fail("autopilot scores three points within the test window")


func _finish_success() -> void:
	await process_frame
	await process_frame
	await process_frame
	print("AUTOPLAY_BALANCE_TEST: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("AUTOPLAY_BALANCE_TEST failed: %s" % message)
	quit(1)
