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


func _initialize() -> void:
	_had_save = FileAccess.file_exists(KK.SAVE_PATH)
	if _had_save:
		_saved = FileAccess.get_file_as_bytes(KK.SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	main = _spawn()
	await _frames(8)
	var baseline := _count_nodes(main)
	for repeat in 3:
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
	var exit_pos: Vector3 = main.level.exit_node().global_position + Vector3(0, 0, -2.2)
	_check(_reachable_near(map, spawn, exit_pos), "exit reachable")
	# Walk through every gallery, using the baked navmesh for steering.
	var walked := 0
	for target in targets.slice(0, 4):
		if walked >= SOAK_FRAMES or main.state != HeistMain.State.PLAYING:
			break
		walked += await _walk_to(map, target, 2.2, mini(900, SOAK_FRAMES - walked))
		if walked % 480 < 30:
			main.player.fire_card()
			main.player.throw_smoke()
		for jewel: Jewel in main.level.jewels():
			if not jewel.is_stolen and main.player.global_position.distance_to(jewel.global_position) < 2.8:
				main.player.try_interact()
				if not jewel.is_stolen:
					jewel.interact(main.player)
	if fuse != null:
		walked += await _walk_to(map, Vector3(10.4, 0, -20.0), 0.9, 1200)
		_check(main.player.global_position.distance_to(fuse.global_position) < 2.8, "walked to fuse")
		main.player.try_interact()
		if fuse.can_interact(main.player) and main.player.global_position.distance_to(fuse.global_position) < 2.8:
			fuse.interact(main.player)
	walked += await _walk_to(map, targets[4], 2.2, 1500)
	main.player.try_interact()
	if main.player.global_position.distance_to(targets[4]) < 2.8 and not (main.level.jewels()[4] as Jewel).is_stolen:
		(main.level.jewels()[4] as Jewel).interact(main.player)
	# Finish traversal and objective even if guards caused temporary detours.
	for jewel: Jewel in main.level.jewels():
		if not jewel.is_stolen:
			walked += await _walk_to(map, jewel.global_position, 2.2, 900)
			main.player.try_interact()
			if not jewel.is_stolen and main.player.global_position.distance_to(jewel.global_position) < 2.8:
				jewel.interact(main.player)
	_check(main.jewels_stolen == main.jewels_total, "all jewels collected")
	_check(main.alarm_on and not main.level.exit_node().locked, "alarm unlocks exit")
	if fuse != null:
		_check(not fuse.can_interact(main.player), "fuse disabled")
	while walked < SOAK_FRAMES and main.state == HeistMain.State.PLAYING:
		main.player.scripted_input = Vector2.ZERO
		await physics_frame
		walked += 1
		if walked % 150 == 0:
			_check_runtime(map, walked)
	walked += await _walk_to(map, Vector3(10, 0, -20), 1.4, 1500)
	walked += await _walk_to(map, Vector3(0, 0, -24), 1.4, 1500)
	walked += await _walk_to(map, exit_pos, 1.0, 1500)
	for i in 120:
		await physics_frame
		if main.state == HeistMain.State.WON:
			break
	_check(main.state == HeistMain.State.WON, "balcony escape wins")
	await create_timer(1.6, true, false, true).timeout
	_check(main.menus.is_showing("win"), "win menu appears")
	_finish()


func _walk_to(map: RID, destination: Vector3, radius: float, limit: int) -> int:
	var frames := 0
	var path := NavigationServer3D.map_get_path(map, main.player.global_position, destination, true)
	var waypoint := 0
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
		if frames % 120 == 0:
			_check_runtime(map, frames)
			path = NavigationServer3D.map_get_path(map, main.player.global_position, destination, true)
			waypoint = 0
	main.player.scripted_input = Vector2.ZERO
	print("WALK ", destination, " -> ", main.player.global_position, " in ", frames)
	return frames


func _check_runtime(map: RID, frame: int) -> void:
	_check(main.player.global_position.y > -1.0, "player above floor at frame %d" % frame)
	_check(main.state == HeistMain.State.PLAYING and not main.menus.is_showing("pause"), "HUD/menu state at frame %d" % frame)
	for node in get_nodes_in_group(KK.GROUP_GUARDS):
		var guard := node as Guard
		if guard == null or guard.state == Guard.State.DOWN:
			continue
		var nearest := NavigationServer3D.map_get_closest_point(map, guard.global_position)
		_check(guard.global_position.distance_to(nearest) < 1.5, "guard on navmesh at frame %d" % frame)
		var id := guard.get_instance_id()
		var last: Vector3 = _guard_positions.get(id, guard.global_position)
		if guard.state in [Guard.State.CHASE, Guard.State.RETURN, Guard.State.SEARCH] and not guard.nav_agent.is_navigation_finished() and guard.global_position.distance_to(last) < 0.2:
			_guard_still[id] = float(_guard_still.get(id, 0.0)) + 2.5
		else:
			_guard_still[id] = 0.0
		_check(float(_guard_still[id]) <= 6.0, "pathing guard moves within 6s")
		_guard_positions[id] = guard.global_position
	_check(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) < 0.2, "physics frame time sane")


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
