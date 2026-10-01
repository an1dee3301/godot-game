extends SceneTree
## Integration checks against the actual scene, physics and session controller.

var game
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_check(game.state == game.State.MENU and paused, "launch opens the main menu")
	_check(game.hud._overlay.visible and not game.hud._game_ui.visible, "menu is visible")
	for action in ["move_forward", "move_back", "move_left", "move_right", "jump", "sprint", "shoot", "aim", "reload", "interact", "pause", "weapon_1", "weapon_2", "weapon_next", "weapon_prev"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "input binding: " + action)
	game.start_session(game.Mode.WAVES)
	await _frames(8)
	_check(game.wave == 1 and game.alive_count() == 3, "first wave has three live enemies")
	_check(not paused and game.player.input_enabled, "starting enables the controller")
	_check(game.player.is_on_floor(), "player stands on the raised platform")
	_check(game.level.nav_region.navigation_mesh.get_polygon_count() > 0, "arena navigation mesh is baked")
	_check(get_nodes_in_group("pickups").size() == 8, "health and ammo pickups are spawned")
	_check(game.sound_fx.has_sound("rifle") and game.sound_fx.has_sound("reload_in"), "procedural weapon and reload sounds exist")
	game.player.invulnerable = true

	var start: Vector3 = game.player.global_position
	Input.action_press("move_forward")
	await _frames(12)
	Input.action_release("move_forward")
	_check(game.player.global_position.z < start.z - 0.25, "W moves the player forward")
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _frames(12)
	_check(game.player.sprinting and Vector2(game.player.velocity.x, game.player.velocity.z).length() > Player.WALK_SPEED, "sprint increases movement speed")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	game.player.reset(game.level.player_spawn)
	await _frames(8)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	_check(game.player.velocity.y > 0.0, "jump applies upward velocity")
	await _frames(55)
	_check(game.player.is_on_floor(), "gravity returns the player to the platform")

	game.player.switch_weapon(1)
	await _frames(30)
	_check(game.player.get_weapon_name() == "DESERT EAGLE", "weapon switching selects the pistol")
	var weapon: Player.Weapon = game.player.get_weapon()
	weapon.mag = 0
	var reserve_before := weapon.reserve
	_check(not game.player.try_fire(), "an empty magazine cannot fire")
	_check(game.player.reloading, "empty trigger starts a reload")
	game.pause_session()
	var elapsed_before: float = game.elapsed
	var reload_before: float = game.player.get_reload_progress()
	await create_timer(0.1, true).timeout
	_check(game.state == game.State.PAUSED and paused, "pause freezes the world")
	_check(is_equal_approx(game.elapsed, elapsed_before) and is_equal_approx(game.player.get_reload_progress(), reload_before), "pause freezes the timer and reload")
	game.resume_session()
	await _frames(130)
	_check(weapon.mag == weapon.mag_size and weapon.reserve == reserve_before - weapon.mag_size, "reload transfers reserve rounds into the magazine")
	_check(not game.player.reloading, "reload completes")

	# Test actual raycast damage and headshot accounting in a clear lane.
	for enemy in game.bots:
		enemy.set_physics_process(false)
	game.player.reset(Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 24)))
	game.player.input_enabled = false
	var target: Bot = game.bots[0]
	target.global_position = Vector3(0, 0.05, 20)
	await _frames(8)
	game.player.aiming = true
	game.player.get_camera().look_at(target.get_head_position())
	game.player._rng.seed = 10
	_check(game.player.try_fire(), "loaded rifle fires a hitscan shot")
	_check(not target.is_alive(), "rifle headshot kills a standard bot")
	_check(game.kills == 1 and game.headshots == 1 and game.shots == 1 and game.hits == 1, "a headshot updates kill, shot and accuracy statistics")
	_check(game.score == 150 and is_equal_approx(game.accuracy(), 100.0), "headshot awards score and accuracy")
	_check(game.hud._ammo.text != "", "HUD displays ammo")

	# Supplies only disappear when they actually help the player.
	game.player.invulnerable = false
	game.player.take_damage(30, game.player.global_position, false, game.bots[0])
	var health_pickup: Pickup
	var ammo_pickup: Pickup
	for pickup in get_nodes_in_group("pickups"):
		if pickup.kind == Pickup.Kind.HEALTH:
			health_pickup = pickup
		else:
			ammo_pickup = pickup
	_check(health_pickup.try_collect(game.player) and game.player.health == Player.MAX_HEALTH, "health pickup heals a wounded player")
	_check(not health_pickup.try_collect(game.player), "consumed pickup cannot be collected twice")
	game.player.get_weapon().reserve = 0
	_check(ammo_pickup.try_collect(game.player) and game.player.get_weapon().reserve > 0, "ammo pickup replenishes reserve ammunition")
	var door: SlidingDoor = game.level.doors[0]
	door.interact(game.player)
	_check(door.is_open, "interacting opens the bunker door")
	await _frames(45)
	_check(door.position.distance_to(door._closed_position) > 2.0, "door physically slides open")
	door.reset()
	await _frames(2)
	_check(not door.is_open and door.position == door._closed_position, "door reset restores its closed position")

	# Kill the remaining enemies to check real wave progression and victory.
	game.player.invulnerable = true
	while game.state == game.State.PLAYING:
		for enemy in game.bots.duplicate():
			if game.wave == 3 and game.bots.size() == 1:
				game.player.reset(Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 24)))
				enemy.set_physics_process(false)
				enemy.global_position = Vector3(0, 0.05, 20)
				await _frames(8)
				game.player.aiming = true
				game.player.get_camera().look_at(enemy.get_head_position())
				_check(game.player.try_fire(), "the final mission enemy is defeated by a real shot")
			else:
				enemy.take_damage(1000, enemy.get_head_position(), false, game.player)
		if game.state == game.State.COMPLETE:
			break
		game._wave_timer = 0.01
		await _frames(2)
		if game.wave > 1 and not game.bots.is_empty():
			_check(game.bots[0].bot_type == Bot.Type.HEAVY and game.bots[0].health == 250.0, "later waves include heavy enemies")
	await process_frame
	_check(game.state == game.State.COMPLETE and game.wave == 3 and game.kills == 15, "clearing all three waves wins the mission")
	_check(game.hud._title.text == "MISSION COMPLETE", "victory screen appears")
	_check(game.shots == 2 and game.hits == 2 and game.headshots == 2, "the final lethal shot is included in result statistics")
	var summary: Label = game.hud._menu_box.get_child(3)
	_check("SHOTS  2" in summary.text and "HEAD HITS  2" in summary.text, "result screen includes final shot statistics")

	game.restart_session()
	await _frames(3)
	_check(game.wave == 1 and game.kills == 0 and game.score == 0 and game.player.health == 100, "restart clears the previous session")
	game.player.take_damage(200, game.player.global_position, false, game.bots[0])
	await process_frame
	_check(game.state == game.State.GAME_OVER and not game.player.alive, "zero player health ends the mission")
	_check(game.hud._title.text == "GAME OVER", "game over screen appears")
	# Restart during the death animation: old tweens must not move the new camera.
	game.restart_session()
	game.player.invulnerable = true
	await _frames(50)
	_check(is_equal_approx(game.player._head.position.y, Player.EYE_HEIGHT), "restart cancels the previous death camera animation")

	game.start_session(game.Mode.STATIC)
	await _frames(4)
	_check(game.bots.size() == 15 and game.player.invulnerable and game.player.infinite_reserve, "practice starts with fifteen safe targets")
	var slot: Vector3 = game.bots[0].global_position
	game.bots[0].take_damage(1000, game.bots[0].get_head_position(), true, game.player)
	_check(game.bots.size() == 14, "killed practice target is removed from the live list")
	await _frames(70)
	_check(game.bots.size() == 15, "practice target respawns")
	_check(game.bots[-1].global_position.distance_to(slot) < 0.2, "practice target respawns in its original slot")
	game.elapsed = 59.99
	await _frames(3)
	_check(game.state == game.State.COMPLETE and game.hud._title.text == "PRACTICE COMPLETE", "practice timer ends the session")
	game.start_session(game.Mode.STRAFING)
	await _frames(4)
	var strafe_start: Array[Vector3] = []
	for enemy in game.bots:
		strafe_start.append(enemy.global_position)
	await _frames(40)
	var moved := false
	for index in game.bots.size():
		moved = moved or game.bots[index].global_position.distance_to(strafe_start[index]) > 0.2
	_check(moved, "strafing targets move")
	game.bots[0].take_damage(1000, game.bots[0].get_head_position(), false, game.player)
	game.show_menu()
	game.start_session(game.Mode.WAVES)
	game.player.invulnerable = true
	await _frames(70)
	_check(game.bots.size() == 3, "practice respawn cannot leak into a new wave mission")

	# Navigation and enemy combat in a clear ground-level lane.
	game.player.reset(Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 24)))
	game.player.input_enabled = false
	game.player.invulnerable = false
	var attacker: Bot = game.bots[0]
	attacker.global_position = Vector3(0, 0.05, 20)
	attacker._accuracy = 1.0
	attacker._damage = 10
	attacker._rng.seed = 22
	await _frames(200)
	_check(attacker.state == Bot.BotState.ATTACK, "bot detects and attacks a nearby player")
	_check(game.player.health < 100, "bot hitscan fire damages the player")
	var path := NavigationServer3D.map_get_path(game.level.nav_region.get_navigation_map(), Vector3(-24, 0, -35), game.level.player_spawn.origin, true)
	_check(path.size() > 2 and path[-1].distance_to(game.level.player_spawn.origin) < 2, "navigation routes from an enemy spawn onto the platform")

	paused = false
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("AIM_BOTZ_SMOKE_TEST: PASS (controller, hitscan, reload, pause, pickups, doors, waves, results, practice, navigation and enemy combat)")
		quit(0)
	else:
		for failure in failures:
			push_error("AIM_BOTZ_SMOKE_TEST: " + failure)
		quit(1)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
