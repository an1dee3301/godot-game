extends SceneTree


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	_assert(packed_scene != null, "main scene loads")
	var game := packed_scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var bird := game.get_node_or_null("Bird") as CharacterBody3D
	var pipes := game.get_node_or_null("Pipes") as Node3D
	var camera := game.get_node_or_null("Camera") as Camera3D
	game.set("_best_score", 999)
	(game.get("_rng") as RandomNumberGenerator).seed = 12345
	_assert(bird != null, "bird is created")
	_assert(pipes != null, "pipe container is created")
	_assert(camera != null and camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "chase camera uses perspective")
	_assert(camera.position.z > bird.position.z, "chase camera starts behind the bird")
	_assert(game.get_node_or_null("FakeSkyBackdrop") != null, "fake sky backdrop is created")
	_assert(game.get_node_or_null("SpeedBlurLayer/RadialSpeedBlur") != null, "speed blur overlay is created")
	_assert(pipes.get_child_count() == 0, "ready state starts without pipes")

	_send_click(Vector2(640.0, 360.0))
	await process_frame
	await physics_frame
	_assert(pipes.get_child_count() == 1, "first flap starts the run and spawns a pipe")
	_assert(bird.velocity.y > 0.0, "first flap gives the bird upward velocity")

	var first_pipe := pipes.get_child(0) as Node3D
	_assert(first_pipe.position.z < bird.position.z, "first pipe starts ahead on negative Z")
	_assert(is_zero_approx(first_pipe.position.x), "pipe stays centered on the chase lane")
	var starting_pipe_z := first_pipe.position.z
	for frame in 4:
		await physics_frame
	_assert(first_pipe.position.z > starting_pipe_z, "pipe travels toward the bird on positive Z")
	_assert(is_zero_approx(first_pipe.position.x), "moving pipe does not drift sideways")
	var gap_center := float(first_pipe.get("_gap_center"))
	bird.call("reset_bird", Vector3(bird.position.x, gap_center, bird.position.z))
	await physics_frame
	await physics_frame
	first_pipe.position.z = bird.position.z
	for frame in 30:
		await physics_frame
		if int(game.get("_score")) == 1:
			break
	_assert(int(game.get("_score")) == 1, "passing a score gate increments the score once")
	first_pipe.call("_on_score_gate_body_entered", bird)
	_assert(int(game.get("_score")) == 1, "score gate cannot score twice")
	_assert(float(game.get("_blur_strength")) > 0.0015, "racing blur ramps up during flight")
	_assert(camera.fov > 69.0, "chase camera widens its FOV at speed")

	bird.call("start_flying")
	bird.position.y = -3.0
	await physics_frame
	await process_frame
	_assert(int(game.get("_state")) == 2, "touching the world boundary ends the run")
	var frozen_pipe_z := first_pipe.position.z

	for frame in 35:
		await physics_frame
	_assert(is_equal_approx(bird.position.y, -2.64), "dead bird rests on the ground")
	_assert(is_equal_approx(first_pipe.position.z, frozen_pipe_z), "pipes freeze after game over")
	var restart_button := game.get("_restart_button") as Button
	var restart_rect := restart_button.get_global_rect()
	_send_click(restart_rect.position + restart_rect.size * 0.5)
	await process_frame
	await physics_frame
	_assert(int(game.get("_state")) == 1, "flap restarts after game over")
	_assert(int(game.get("_score")) == 0, "restart resets the score")
	_assert(bird.velocity.y > 0.0, "restart includes a fresh flap")
	_assert(pipes.get_child_count() == 1 and (pipes.get_child(0) as Node3D).position.z < 0.0, "restart creates one fresh pipe ahead")

	game.queue_free()
	call_deferred("_finish_success")


func _finish_success() -> void:
	await process_frame
	await process_frame
	await process_frame
	print("GAMEPLAY_SMOKE_TEST: PASS")
	quit(0)


func _send_click(click_position: Vector2) -> void:
	var pressed := InputEventMouseButton.new()
	pressed.button_index = MOUSE_BUTTON_LEFT
	pressed.position = click_position
	pressed.global_position = click_position
	pressed.pressed = true
	Input.parse_input_event(pressed)
	var released := InputEventMouseButton.new()
	released.button_index = MOUSE_BUTTON_LEFT
	released.position = click_position
	released.global_position = click_position
	released.pressed = false
	Input.parse_input_event(released)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("GAMEPLAY_SMOKE_TEST failed: %s" % message)
	quit(1)
