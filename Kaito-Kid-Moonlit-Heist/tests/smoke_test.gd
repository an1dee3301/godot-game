extends SceneTree
## Headless acceptance checks mirroring the assignment's T1-T9:
## movement, patrol, detection, navigation around an obstacle, ranged-honest attack, escape/return,
## objective + win, HP 0 -> game over -> retry, and the extensions (cards, smoke, lasers, cameras).
## Run: Godot --headless --path . -s res://tests/smoke_test.gd

const MAIN_SCENE := "res://scenes/main.tscn"
var failures: Array[String] = []
var checks := 0
var main: HeistMain
var _saved := PackedByteArray()


func _initialize() -> void:
	if FileAccess.file_exists(KK.SAVE_PATH):
		_saved = FileAccess.get_file_as_bytes(KK.SAVE_PATH)
	call_deferred("_run")


func _run() -> void:
	main = _spawn_main()
	await _frames(10)

	# --- Boot ---
	_check(main.state == HeistMain.State.TITLE, "boots to TITLE")
	_check(main.menus.is_showing("title"), "title screen visible")
	for action in ["move_forward", "sprint", "crouch", "fire", "smoke", "interact", "pause"]:
		_check(InputMap.has_action(action), "input action %s" % action)
	for child in ["Level", "Player", "CameraRig", "Guards", "Effects", "SoundFX", "HUD", "Menus"]:
		_check(main.get_node_or_null(child) != null, "child %s exists" % child)
	_check(main.level.jewels().size() == KK.JEWELS_REQUIRED, "level has %d jewels" % KK.JEWELS_REQUIRED)
	_check(main.level.guard_routes().size() >= 4, "level defines >= 4 guard routes")
	var kinds := {}
	for g: Guard in _guards():
		kinds[g.kind] = true
	_check(kinds.size() == 2, "both enemy kinds present")
	_check(main.level.navigation_region != null and main.level.navigation_region.navigation_mesh.get_polygon_count() > 0, "navmesh baked")
	_check(main.player.anim != null, "player has AnimationPlayer")
	for a in ["idle", "walk", "run", "throw", "hurt", "death"]:
		_check(main.player.anim != null and main.player.anim.has_animation(a), "player anim %s" % a)

	main.start_game()
	await _frames(5)
	_check(main.state == HeistMain.State.PLAYING, "PLAYING after start")
	_check(not main.menus.is_showing("title"), "title hidden")

	# --- T1 movement ---
	var p := main.player
	var start := p.global_position
	p.use_scripted_input = true
	p.scripted_input = Vector2(0, 1)
	await _physics(45)
	p.scripted_input = Vector2.ZERO
	await _physics(15)
	_check(p.global_position.distance_to(start) > 2.0, "T1 player walks (moved %.2f m)" % p.global_position.distance_to(start))
	_check(p.is_on_floor(), "T1 player grounded")

	# --- T2 patrol ---
	await _physics(30)
	var g0: Guard = _guards()[0]
	var pos0 := g0.global_position
	await _physics(180)
	_check(g0.global_position.distance_to(pos0) > 1.0 or g0.state == Guard.State.PATROL, "T2 guard patrols (moved %.2f m, state %s)" % [g0.global_position.distance_to(pos0), g0.state_name()])
	_check(g0.state == Guard.State.PATROL, "T2 guard still PATROL while player hidden in lobby (got %s)" % g0.state_name())

	# Isolate a single test guard from now on.
	for g: Guard in _guards():
		g.process_mode = Node.PROCESS_MODE_DISABLED
		g.remove_from_group(KK.GROUP_GUARDS)
		g.visible = false
	var tp: Dictionary = main.level.test_points()
	for key in ["open_a", "obstacle_a", "obstacle_b", "far", "lobby"]:
		_check(tp.has(key), "test point %s" % key)
	if failures.size() > 0 and not tp.has("open_a"):
		_finish()
		return

	# --- T3 detection ---
	var open_a: Vector3 = tp["open_a"]
	var guard := main.spawn_guard(KK.EnemyKind.GUARD, PackedVector3Array([open_a, open_a + Vector3(4, 0, 0)]), 3.0)
	await _physics(20)
	var fwd := -guard.global_basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	_place_player(guard.global_position + fwd * 6.0)
	var saw_suspicious := false
	var reached_chase := false
	for i in 240:
		await physics_frame
		saw_suspicious = saw_suspicious or guard.state == Guard.State.SUSPICIOUS
		if guard.state in [Guard.State.CHASE, Guard.State.ATTACK]:
			reached_chase = true
			break
	_check(reached_chase, "T3 guard detects player in view cone -> CHASE (state %s, awareness %.2f)" % [guard.state_name(), guard.awareness])

	# --- T5 attack honesty + damage ---
	p.hp = p.max_hp
	_place_player(guard.global_position + fwd * 1.2)
	var hp0 := p.hp
	for i in 240:
		await physics_frame
		if p.hp < hp0:
			break
	_check(p.hp < hp0, "T5 guard attack in range reduces HP (%.0f -> %.0f)" % [hp0, p.hp])
	p.heal(1000)

	# --- T6 escape -> search -> return/patrol ---
	_place_player(tp["far"])
	guard.blind(4.0)
	var saw_search := false
	var recovered := false
	for i in 60 * 30:
		await physics_frame
		saw_search = saw_search or guard.state == Guard.State.SEARCH
		if guard.state in [Guard.State.RETURN, Guard.State.PATROL] and saw_search:
			recovered = true
			break
	_check(saw_search, "T6 guard searches last known position after losing the player")
	_check(recovered, "T6 guard returns to patrol (state %s)" % guard.state_name())

	# --- T4 navigation around an obstacle ---
	var a: Vector3 = tp["obstacle_a"]
	var b: Vector3 = tp["obstacle_b"]
	var w3d := main.get_world_3d()
	_check(not KK.has_line_of_sight(w3d, a + Vector3.UP, b + Vector3.UP), "T4 obstacle blocks the straight line")
	guard.global_position = a
	guard.velocity = Vector3.ZERO
	_place_player(b)
	p.max_hp = 100000.0
	p.hp = p.max_hp
	await _physics(2)
	guard.receive_alert(b)
	var reached := false
	for i in 60 * 15:
		await physics_frame
		if guard.global_position.distance_to(p.global_position) < 2.6:
			reached = true
			break
	_check(reached, "T4 guard navigates around obstacle to the player (dist %.1f)" % guard.global_position.distance_to(p.global_position))

	# --- Extensions: cards, smoke ---
	p.max_hp = KK.PLAYER_MAX_HP
	p.hp = p.max_hp
	var fx_before := main.effects_root.get_child_count()
	_check(p.fire_card(), "card gun fires")
	_check(not p.fire_card(), "card gun respects cooldown")
	await _physics(2)
	_check(main.effects_root.get_child_count() > fx_before, "card projectile spawned")
	var bombs := p.smoke_bombs
	_check(p.throw_smoke(), "smoke bomb thrown")
	await _physics(5)
	_check(p.smoke_bombs == bombs - 1, "smoke count decremented")
	_check(SmokeCloud.point_in_smoke(self, p.global_position), "player stands in smoke")
	_check(p.visibility_factor() < 0.1, "smoke hides the player (visibility %.2f)" % p.visibility_factor())

	# Card hits defeat a guard
	var ko_count := main.knockouts
	for i in int(guard.stats["max_hp"]):
		guard.take_card_hit(guard.global_position + Vector3(0, 1, 2))
		await _physics(3)
	_check(guard.state == Guard.State.DOWN, "guard knocked out by cards (state %s)" % guard.state_name())
	_check(main.knockouts == ko_count + 1, "knockout counted")

	# Hearing: a card-impact noise makes a calm guard investigate
	var g2 := main.spawn_guard(KK.EnemyKind.GUARD, PackedVector3Array([open_a, open_a + Vector3(4, 0, 0)]), 3.0)
	_place_player(tp["far"])
	await _physics(20)
	KK.emit_noise(self, g2.global_position + Vector3(3, 0, 3), KK.NOISE_CARD_IMPACT)
	await _physics(5)
	_check(g2.state == Guard.State.SUSPICIOUS, "noise makes guard SUSPICIOUS (got %s)" % g2.state_name())

	# Lasers + fuse box
	var fuse: Node = null
	for n in get_nodes_in_group(KK.GROUP_INTERACTABLE):
		if n is FuseBox:
			fuse = n
	_check(fuse != null, "fuse box exists")
	if fuse:
		var grids := _all(main.level, "LaserGrid")
		_check(grids.size() > 0 and grids.all(func(l: LaserGrid) -> bool: return l.active), "laser grids start active")
		fuse.interact(p)
		await _physics(5)
		_check(grids.all(func(l: LaserGrid) -> bool: return not l.active), "fuse box disables lasers")
	_check(_all(main.level, "SecurityCamera").size() >= 2, "security cameras placed")
	_check(_all(main.level, "HeistPickup").size() >= 4, "pickups placed")

	# --- T7 objective + win ---
	_check(main.level.exit_node().locked, "exit locked before jewels")
	var i_j := 0
	for jewel: Jewel in main.level.jewels():
		jewel.steal()
		i_j += 1
		await _physics(2)
		_check(main.jewels_stolen == i_j, "jewel counter %d/5" % i_j)
	_check(main.alarm_on and not main.level.exit_node().locked, "all jewels -> alarm + exit unlocked")
	var exit := main.level.exit_node()
	await _physics(60)
	_place_player(exit.global_position - exit.global_basis.z * 2.5)
	for i in 120:
		await physics_frame
		if main.state == HeistMain.State.WON:
			break
	_check(main.state == HeistMain.State.WON, "T7 reaching the glider wins (state %d)" % main.state)
	await _seconds(1.8)
	_check(main.menus.is_showing("win"), "win screen shown")

	# --- T8 failure + retry ---
	root.remove_child(main)
	main.queue_free()
	main = _spawn_main()
	await _frames(5)
	main.start_game()
	await _frames(5)
	main.player.take_damage(1000.0)
	await _frames(3)
	_check(main.player.is_dead and main.state == HeistMain.State.LOST, "T8 HP 0 -> LOST")
	await _seconds(1.8)
	_check(main.menus.is_showing("game_over"), "game over screen shown")
	main.restart_game()
	await _frames(10)
	var fresh := current_scene as HeistMain
	_check(fresh != null and fresh != main, "retry reloads the scene")
	if fresh:
		await _frames(5)
		_check(fresh.state == HeistMain.State.PLAYING, "retry skips title and starts playing")
		_check(fresh.player.hp == fresh.player.max_hp, "retry restores HP")
	_finish()


func _spawn_main() -> HeistMain:
	var m := (load(MAIN_SCENE) as PackedScene).instantiate() as HeistMain
	root.add_child(m)
	current_scene = m
	return m


func _place_player(pos: Vector3) -> void:
	main.player.global_position = pos
	main.player.velocity = Vector3.ZERO


func _guards() -> Array:
	return get_nodes_in_group(KK.GROUP_GUARDS)


func _all(node: Node, cls: String) -> Array:
	var out := []
	for n in node.find_children("*", "", true, false):
		var s: Script = n.get_script()
		if s and s.get_global_name() == cls:
			out.append(n)
	return out


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("  PASS  ", label)
	else:
		print("  FAIL  ", label)
		failures.append(label)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _seconds(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _finish() -> void:
	if _saved.is_empty():
		if FileAccess.file_exists(KK.SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(KK.SAVE_PATH))
	else:
		FileAccess.open(KK.SAVE_PATH, FileAccess.WRITE).store_buffer(_saved)
	print("\n%d checks, %d failed" % [checks, failures.size()])
	for f in failures:
		print("  - ", f)
	quit(1 if failures.size() > 0 else 0)
