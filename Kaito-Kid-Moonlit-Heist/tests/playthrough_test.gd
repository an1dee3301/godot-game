extends SceneTree
## Long-run museum traversal and menu lifecycle check.
## Run: Godot --headless --path . --fixed-fps 60 --disable-vsync -s res://tests/playthrough_test.gd

const MAIN_SCENE := "res://scenes/main.tscn"
const SOAK_FRAMES := 60 * 180
var failures: Array[String] = []
var checks := 0
var main: HeistMain
var _saved := PackedByteArray()
var _had_save := false
var _guard_positions: Dictionary = {}
var _guard_still: Dictionary = {}
var _guard_failed: Dictionary = {}
var _runtime_frames := 0
var _minimum_y := INF


func _initialize() -> void:
	_had_save = FileAccess.file_exists(KK.SAVE_PATH)
	if _had_save:
		_saved = FileAccess.get_file_as_bytes(KK.SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	main = _spawn()
	await _frames(8)
	if main.level.exit_node() == null or main.level.jewels().size() != KK.JEWELS_REQUIRED:
		_check(false, "level built all jewels and the exit")
		_finish()
		return
	var baseline := _count_nodes(main)
	for repeat in 5:
		_check(main.menus.is_showing("title"), "title visible on cycle %d" % repeat)
		main.start_game()
		await _frames(3)
		_check(main.state == HeistMain.State.PLAYING and main.hud.visible, "title to play")
		main.pause_game()
		await _frames(2)
		_check(paused and main.menus.is_showing("pause"), "pause freezes scene")
		main.menus.show_screen("settings")
		await _frames(2)
		_check(main.menus.is_showing("settings"), "settings visible")
		main.menus.show_screen("pause")
		main.resume_game()
		await _frames(3)
		_check(not paused and main.state == HeistMain.State.PLAYING, "resume")
		main.restart_game()
		await _frames(10)
		main = current_scene as HeistMain
		_check(main != null and main.state == HeistMain.State.PLAYING, "restart cycle %d" % repeat)
		_check(abs(_count_nodes(main) - baseline) < 20, "restart node count stable")
		# Recreate through the public menu signal path; wait for queued nodes to leave.
		main.menus.menu_requested.emit()
		await _frames(10)
		main = current_scene as HeistMain
		_check(main != null and main.state == HeistMain.State.TITLE, "main menu reload")
		_check(abs(_count_nodes(main) - baseline) < 20, "scene node count stable")
	main.start_game()
	main.player.use_scripted_input = true
	main.player.max_hp = 100000.0
	main.player.hp = main.player.max_hp
	await _frames(8)
	var map: RID = main.get_world_3d().navigation_map
	var spawn: Vector3 = main.player.global_position
	for route: Dictionary in main.level.guard_routes():
		for point: Vector3 in route["points"]:
			_check(_reachable(map, spawn, point), "guard route point reachable")
	var targets: Array[Vector3] = []
	for jewel: Jewel in main.level.jewels():
		targets.append(jewel.global_position)
		_check(_reachable_near(map, spawn, jewel.global_position), "jewel reachable: %s" % jewel.jewel_name)
	var fuse := _find_fuse()
	_check(fuse != null, "fuse exists")
	if fuse != null:
		_check(_reachable_near(map, spawn, fuse.global_position), "fuse reachable")
	var fuse_approach := Vector3.ZERO
	if fuse != null:
		fuse_approach = fuse.global_position + fuse.global_basis.z * 1.2
		fuse_approach.y = 0.0
	var exit_pos: Vector3 = main.level.exit_node().global_position - main.level.exit_node().global_basis.z * 2.2
	_check(_reachable_near(map, spawn, exit_pos), "exit reachable")
	# Run the long patrol soak before the theft triggers a permanent alarm.
	for i in SOAK_FRAMES:
		await physics_frame
		_sample_runtime(map)
	_check(_runtime_frames >= SOAK_FRAMES, "three simulated minutes completed")
	# Isolate level reachability after the live guard soak; patrol bodies can close a 2 m service lane.
	for guard: Guard in get_nodes_in_group(KK.GROUP_GUARDS):
		guard.process_mode = Node.PROCESS_MODE_DISABLED
		guard.collision_layer = 0
		guard.remove_from_group(KK.GROUP_GUARDS)
	# Walk through every gallery, using the baked navmesh for steering.
	var walked := 0
	for target in targets.slice(0, 4):
		if walked >= SOAK_FRAMES or main.state != HeistMain.State.PLAYING:
			break
		walked += await _walk_to(map, target, 1.55, 2100)
		_check(main.player.fire_card(), "card fired during route")
		if main.player.smoke_bombs > 0:
			_check(main.player.throw_smoke(), "smoke thrown during route")
		for jewel: Jewel in main.level.jewels():
			if not jewel.is_stolen and main.player.global_position.distance_to(jewel.global_position) < 2.8:
				_face(jewel.interact_position())
				main.player.try_interact()
	if fuse != null:
		walked += await _walk_to(map, fuse_approach, 0.35, 3200)
		_check(main.player.global_position.distance_to(fuse.global_position) < 2.8, "walked to fuse")
		_face(fuse.interact_position())
		main.player.try_interact()
		_check(not fuse.can_interact(main.player), "fuse switched off through interaction")
	# Return through the service door; the vault's east wall has no walkable opening.
	for waypoint: Vector3 in [Vector3(40, 0, -4), Vector3(34, 0, -4),
			Vector3(16, 0, -4), Vector3(0, 0, -20)]:
		walked += await _walk_to(map, waypoint, 1.0, 1100)
	walked += await _walk_to(map, targets[4], 1.55, 1500)
	_face((main.level.jewels()[4] as Jewel).interact_position())
	main.player.try_interact()
	# Finish traversal and objective even if guards caused temporary detours.
	for jewel: Jewel in main.level.jewels():
		if not jewel.is_stolen:
			walked += await _walk_to(map, jewel.global_position, 1.55, 2100)
			_face(jewel.interact_position())
			main.player.try_interact()
		_check(jewel.is_stolen, "stole %s through interaction" % jewel.jewel_name)
	_check(main.jewels_stolen == main.jewels_total, "all jewels collected")
	_check(main.alarm_on and not main.level.exit_node().locked, "alarm unlocks exit")
	if fuse != null:
		_check(not fuse.can_interact(main.player), "fuse disabled")
	for i in 60 * 8:
		await physics_frame
		_sample_runtime(map)
	walked += await _walk_to(map, exit_pos, 0.8, 2400)
	for i in 120:
		await physics_frame
		if main.state == HeistMain.State.WON:
			break
	_check(main.state == HeistMain.State.WON, "balcony escape wins")
	_check(_minimum_y > -1.0, "player never fell below y=-1 (minimum %.2f)" % _minimum_y)
	await create_timer(1.6, true, false, true).timeout
	_check(main.menus.is_showing("win"), "win menu appears")
	_check(is_equal_approx(Engine.time_scale, 1.0), "time scale restored after escape")
	_finish()


func _walk_to(map: RID, destination: Vector3, radius: float, limit: int) -> int:
	var frames := 0
	var path := NavigationServer3D.map_get_path(map, main.player.global_position, destination, true)
	var waypoint := _nearest_path_index(path, main.player.global_position)
	while frames < limit and main.state == HeistMain.State.PLAYING:
		var here := main.player.global_position
		if Vector2(here.x - destination.x, here.z - destination.z).length() < radius:
			break
		while waypoint < path.size() - 1 and Vector2(here.x - path[waypoint].x, here.z - path[waypoint].z).length() < 0.8:
			waypoint += 1
		if path.is_empty():
			break
		var goal: Vector3 = path[waypoint]
		var desired := Vector3(goal.x - here.x, 0, goal.z - here.z).normalized()
		var local := Basis(Vector3.UP, -main.camera_rig.get_yaw()) * desired
		main.player.scripted_input = Vector2(local.x, -local.z)
		await physics_frame
		frames += 1
		_sample_runtime(map)
		if frames % 120 == 0:
			path = NavigationServer3D.map_get_path(map, main.player.global_position, destination, true)
			waypoint = _nearest_path_index(path, main.player.global_position)
	main.player.scripted_input = Vector2.ZERO
	print("WALK ", destination, " -> ", main.player.global_position, " in ", frames)
	return frames


func _nearest_path_index(path: PackedVector3Array, position: Vector3) -> int:
	if path.is_empty():
		return 0
	if Vector2(path[0].x - position.x, path[0].z - position.z).length() < 2.0:
		return 0
	var best := 0
	var best_distance := INF
	for i in path.size():
		var offset := Vector2(path[i].x - position.x, path[i].z - position.z)
		if offset.length_squared() < best_distance:
			best_distance = offset.length_squared()
			best = i
	return best


func _sample_runtime(map: RID) -> void:
	_runtime_frames += 1
	_minimum_y = minf(_minimum_y, main.player.global_position.y)
	if _runtime_frames % 30 != 0:
		return
	var game_visible := main.state == HeistMain.State.PLAYING and not main.menus.is_showing("pause")
	_check(game_visible, "HUD/menu state at frame %d" % _runtime_frames)
	for node in get_nodes_in_group(KK.GROUP_GUARDS):
		var guard := node as Guard
		if guard == null or guard.state == Guard.State.DOWN:
			continue
		var nearest := NavigationServer3D.map_get_closest_point(map, guard.global_position)
		_check(guard.global_position.distance_to(nearest) < 1.5, "guard on navmesh at frame %d" % _runtime_frames)
		var id := guard.get_instance_id()
		var last: Vector3 = _guard_positions.get(id, guard.global_position)
		var pathing := guard.state in [Guard.State.PATROL, Guard.State.CHASE, Guard.State.RETURN]
		if guard.state == Guard.State.CHASE and guard.global_position.distance_to(main.player.global_position) < 3.0:
			pathing = false
		var desired: Vector3 = guard.nav_agent.velocity
		if pathing and desired.length_squared() > 0.2 and not guard.nav_agent.is_navigation_finished() \
				and guard.global_position.distance_to(last) < 0.08:
			_guard_still[id] = float(_guard_still.get(id, 0.0)) + 0.5
		else:
			_guard_still[id] = 0.0
		if float(_guard_still[id]) > 6.0 and not _guard_failed.has(id):
			_guard_failed[id] = true
			var distance := guard.global_position.distance_to(main.player.global_position)
			_check(false, "pathing guard moves within 6s (%s, %s, player %.1fm)" % [guard.name, guard.state_name(), distance])
		_guard_positions[id] = guard.global_position


func _reachable(map: RID, from: Vector3, to: Vector3) -> bool:
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	return path.size() >= 2 and Vector2(path[path.size() - 1].x - to.x, path[path.size() - 1].z - to.z).length() < 1.0


func _reachable_near(map: RID, from: Vector3, to: Vector3) -> bool:
	for offset in [Vector3(2, 0, 0), Vector3(-2, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, -2)]:
		if _reachable(map, from, to + offset):
			return true
	return false


func _find_fuse() -> FuseBox:
	for node in get_nodes_in_group(KK.GROUP_INTERACTABLE):
		if node is FuseBox:
			return node
	return null


func _face(target: Vector3) -> void:
	var to_target := target - main.player.global_position
	to_target.y = 0.0
	if to_target.length_squared() > 0.01:
		main.player.rotation.y = atan2(-to_target.x, -to_target.z)


func _spawn() -> HeistMain:
	var scene := load(MAIN_SCENE) as PackedScene
	var result := scene.instantiate() as HeistMain
	root.add_child(result)
	current_scene = result
	return result


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL ", label)


func _finish() -> void:
	if _had_save:
		FileAccess.open(KK.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved)
	elif FileAccess.file_exists(KK.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(KK.SAVE_PATH))
	print("%d checks, %d failed" % [checks, failures.size()])
	for failure in failures:
		print("  - ", failure)
	quit(1 if not failures.is_empty() else 0)
