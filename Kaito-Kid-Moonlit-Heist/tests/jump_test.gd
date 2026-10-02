extends SceneTree
## Headless jump regression suite. Run with --fixed-fps 60 -s res://tests/jump_test.gd.

var main: HeistMain
var player: PhantomThief
var failures: Array[String] = []
var checks := 0
var trace: FileAccess
var frame := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	trace = FileAccess.open("/tmp/kaito_jump_frames.log", FileAccess.WRITE)
	main = load("res://scenes/main.tscn").instantiate() as HeistMain
	root.add_child(main)
	current_scene = main
	await _ticks(5, "boot")
	main.start_game()
	player = main.player
	player.use_scripted_input = true
	for guard: Guard in get_nodes_in_group(KK.GROUP_GUARDS):
		guard.process_mode = Node.PROCESS_MODE_DISABLED
		guard.collision_layer = 0
	await _ticks(8, "start")
	_check(player.is_on_floor(), "starts grounded")

	await _reset(Vector3(0, 0, 28))
	var standing := await _jump_cycle("standing", Vector2.ZERO)
	_check(standing["apex"] >= 1.1 and standing["apex"] <= 1.4, "standing apex %.2f m" % standing["apex"])
	_check(standing["launches"] == 1 and standing["landed"], "standing jump launches once and lands")
	_check(standing["recovered"], "standing animation recovers within 0.5 s")
	await _flat_floor("standing flat floor")

	await _reset(Vector3(0, 0, 28))
	Input.action_press("sprint")
	player.scripted_input = Vector2(0, 1)
	await _ticks(15, "runup")
	var running := await _jump_cycle("running", Vector2(0, 1))
	Input.action_release("sprint")
	_check(running["apex"] >= 1.1 and running["apex"] <= 1.4, "running apex %.2f m" % running["apex"])
	_check(running["landed"] and running["recovered"], "running jump lands and resumes locomotion")
	_check(absf(running["apex"] - standing["apex"]) < 0.15, "running and standing apex match")

	await _reset(Vector3(0, 0, 28))
	Input.action_press("crouch")
	await _ticks(5, "crouch")
	var crouched := await _jump_cycle("crouch jump", Vector2.ZERO)
	_check(crouched["launches"] == 1 and crouched["landed"], "crouch jump stands and lands")
	Input.action_release("crouch")

	await _reset(Vector3(0, 0, 28))
	Input.action_press("jump")
	await _ticks(1, "spam launch")
	Input.action_release("jump")
	var spam_launches := 1
	var buffered := false
	for i in 95:
		if i % 8 == 0:
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		await _ticks(1, "spam")
		if player.velocity.y > 4.5 and i > 5:
			spam_launches += 1
			buffered = true
			break
	Input.action_release("jump")
	_check(spam_launches <= 2, "spam never produces an airborne double jump")
	_check(buffered, "buffered jump fires on landing")
	await _ticks(95, "buffer recovery")
	_check(player.is_on_floor() and player.anim.current_animation in ["idle", "walk", "run"], "buffered jump recovers")

	# Use the real sculpture-to-clock vent, whose lintel is only 1.05 m high.
	await _reset(Vector3(-20.4, 0, -7.4))
	Input.action_press("crouch")
	player.scripted_input = Vector2(0, 1)
	await _ticks(17, "vent entry")
	player.scripted_input = Vector2.ZERO
	_check(player.global_position.z < -7.85 and player.global_position.z > -8.3, "crouched capsule enters the real vent")
	var vent_y := player.global_position.y
	Input.action_press("jump")
	await _ticks(1, "vent jump")
	Input.action_release("jump")
	await _ticks(35, "vent blocked jump")
	_check(player.global_position.y - vent_y < 0.08 and player.is_on_floor(), "vent ceiling blocks jump cleanly")
	_check(player.anim.current_animation in ["crouch_idle", "crouch_walk"], "vent does not trap jump animation")
	Input.action_release("crouch")
	await _ticks(6, "vent stand check")
	_check(player.is_crouching(), "vent prevents standing into lintel")
	var low_ceiling := _box(Vector3(-7, 2.1, 13), Vector3(3.0, 0.2, 3.0))
	await _reset(Vector3(-7, 0, 13))
	var ceiling_jump := await _jump_cycle("low ceiling", Vector2.ZERO)
	_check(ceiling_jump["apex"] < 0.25 and ceiling_jump["landed"], "low ceiling stops lift and player lands")
	_check(ceiling_jump["recovered"], "low ceiling does not trap jump animation")
	low_ceiling.queue_free()

	# Collision fixtures match the scale of a museum wall and display plinth.
	var wall := _box(Vector3(3, 1.5, 27), Vector3(0.4, 3.0, 4.0))
	await _reset(Vector3(1.6, 0, 27))
	player.scripted_input = Vector2(1, 0)
	var against_wall := await _jump_cycle("wall", Vector2(1, 0))
	_check(against_wall["landed"] and player.global_position.x < 2.5, "wall jump lands without clipping through wall")
	wall.queue_free()

	var prop := _box(Vector3(-5.0, 0.13, 13), Vector3(1.8, 0.26, 1.8))
	await _reset(Vector3(-7.0, 0, 13))
	player.scripted_input = Vector2(1, 0)
	await _ticks(38, "step onto prop")
	_check(player.global_position.x > -6.0 and player.is_on_floor(), "steps over 0.26 m prop edge")
	_check(absf(player.global_position.y - 0.26) < 0.12, "feet settle on prop")
	prop.queue_free()

	var landing_prop := _box(Vector3(-5.0, 0.45, 13), Vector3(2.0, 0.9, 2.0))
	await _reset(Vector3(-7.0, 0, 13))
	Input.action_press("jump")
	await _ticks(1, "prop launch")
	Input.action_release("jump")
	player.scripted_input = Vector2(1, 0)
	await _ticks(46, "prop landing")
	player.scripted_input = Vector2.ZERO
	_check(player.is_on_floor() and player.global_position.y > 0.8, "lands on raised prop")
	await _ticks(30, "prop animation recovery")
	_check(player.anim.current_animation in ["idle", "walk", "run"], "prop landing animation recovers")
	landing_prop.queue_free()

	var ledge := _box(Vector3(-5.0, 0.5, 13), Vector3(2.0, 1.0, 2.0))
	await _reset(Vector3(-5.0, 1.0, 13))
	player.scripted_input = Vector2(1, 0)
	var left_ledge := false
	for i in 45:
		await _ticks(1, "walk off ledge")
		if not player.is_on_floor():
			left_ledge = true
			break
	_check(left_ledge, "walks off ledge")
	await _ticks(3, "coyote delay")
	Input.action_press("jump")
	await _ticks(1, "coyote jump")
	Input.action_release("jump")
	_check(player.velocity.y > 4.0, "coyote jump works after leaving ledge")
	await _ticks(95, "coyote recovery")
	_check(player.is_on_floor(), "coyote jump lands")
	ledge.queue_free()

	await _reset(Vector3(0, 0, 28))
	_check(player.throw_smoke(), "throw begins")
	var thrown := await _jump_cycle("throw jump", Vector2.ZERO)
	_check(thrown["landed"], "jump during throw lands")
	await _reset(Vector3(0, 0, 28))
	player.take_damage(5.0)
	Input.action_press("jump")
	await _ticks(1, "hurt jump")
	Input.action_release("jump")
	_check(player.velocity.y < 4.0, "jump during hurt is ignored")
	await _ticks(35, "hurt recovery")
	player.take_damage(1000.0)
	Input.action_press("jump")
	await _ticks(1, "dead jump")
	Input.action_release("jump")
	_check(player.is_dead and player.anim.current_animation == "death", "jump while dead is ignored")

	if trace != null:
		trace.close()
	print("%d checks, %d failed; frame trace: /tmp/kaito_jump_frames.log" % [checks, failures.size()])
	for failure: String in failures:
		print("  FAIL  ", failure)
	quit(1 if failures.size() > 0 else 0)


func _jump_cycle(label: String, motion: Vector2) -> Dictionary:
	player.scripted_input = motion
	var start_y := player.global_position.y
	var apex := 0.0
	var launches := 0
	var airborne := false
	var landed := false
	var recovered := false
	Input.action_press("jump")
	for i in 105:
		await _ticks(1, label)
		if i == 0:
			Input.action_release("jump")
		apex = maxf(apex, player.global_position.y - start_y)
		if player.velocity.y > 4.5 and not airborne:
			launches += 1
		if not player.is_on_floor():
			airborne = true
		if airborne and player.is_on_floor():
			landed = true
			if i < 100:
				await _ticks(30, label + " recovery")
			recovered = player.anim.current_animation in ["idle", "walk", "run", "crouch_idle", "crouch_walk"]
			break
	player.scripted_input = Vector2.ZERO
	return {"apex": apex, "launches": launches, "landed": landed, "recovered": recovered}


func _reset(position: Vector3) -> void:
	player.scripted_input = Vector2.ZERO
	Input.action_release("jump")
	Input.action_release("crouch")
	Input.action_release("sprint")
	player.global_position = position
	player.velocity = Vector3.ZERO
	await _ticks(5, "reset")


func _flat_floor(label: String) -> void:
	var flickers := 0
	for i in 45:
		await _ticks(1, label)
		if not player.is_on_floor():
			flickers += 1
	_check(flickers == 0, "%s has no floor flicker" % label)


func _box(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = KK.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	main.add_child(body)
	body.global_position = center
	return body


func _ticks(count: int, label: String) -> void:
	for i in count:
		await process_frame
		frame += 1
		if player != null and trace != null:
			trace.store_line("%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%s,%s" % [label, frame,
				player.global_position.x, player.global_position.y, player.global_position.z,
				player.velocity.x, player.velocity.y, str(player.is_on_floor()), player.anim.current_animation])


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("  PASS  ", label)
	else:
		failures.append(label)
		print("  FAIL  ", label)
