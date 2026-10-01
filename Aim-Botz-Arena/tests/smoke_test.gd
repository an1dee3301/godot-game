extends SceneTree
## Headless gameplay smoke test:
##   godot --headless --path . -s tests/smoke_test.gd

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	var game := packed.instantiate()
	root.add_child(game)
	await _frames(3)

	var level := game.get("level") as ArenaLevel
	var player := game.get("player") as Player
	_check(level != null and player != null, "level and player are created")
	_check(int(game.get("state")) == 0, "game starts in the main menu")
	_check(level.nav_region.navigation_mesh.get_polygon_count() > 0, "navigation mesh is baked")
	_check(level.doors.size() >= 1, "level has a sliding door")
	_check(level.radar_rects.size() > 20, "level has obstacles for the radar")

	# --- Mission start -------------------------------------------------------
	game.call("start_game", false)
	await _frames(2)
	_check(int(game.get("state")) == 1, "mission switches to PLAYING")
	_check(player.get_camera().current, "player camera is active")
	_check(player.global_position.y > 2.5, "player spawns on the raised platform")
	_check(game.get_tree().get_nodes_in_group("pickups").size() == 8, "health and ammo pickups spawned")
	game.set("_wave_break_timer", 0.01)
	await _physics(60)
	_check(int(game.get("wave_index")) == 0, "first wave begins")
	await _physics(240)
	var bots := game.get_tree().get_nodes_in_group("bots")
	_check(bots.size() == 3, "wave 1 spawns 3 bots (got %d)" % bots.size())

	# --- Bots approach the player --------------------------------------------
	var bot := bots[0] as Bot
	var start_distance := bot.global_position.distance_to(player.global_position)
	player.invulnerable = true
	await _physics(180)
	var later_distance := bot.global_position.distance_to(player.global_position)
	_check(later_distance < start_distance - 2.0, "bot approaches the player (%.1f -> %.1f)" % [start_distance, later_distance])

	# --- Bots damage the player ------------------------------------------------
	player.invulnerable = false
	var health_before := player.health
	bot.call("_shoot")
	for attempt in 40:
		bot.call("_shoot")
	_check(player.health < health_before, "bot gunfire damages the player")

	# --- Shooting, ammo and headshots ---------------------------------------------
	var weapon := player.get_weapon()
	weapon.base_spread = 0.0
	for node in bots:
		(node as Bot).set_physics_process(false)
	# Place the targets in clear view of the platform.
	bot.global_position = Vector3(0.0, 0.0, 2.0)
	(bots[1] as Bot).global_position = Vector3(3.0, 0.0, 0.0)
	var mag_before := weapon.mag
	_aim_at(player, bot.get_head_position())
	await _physics(1)
	player.set("_bloom", 0.0)
	_check(player.try_fire(), "player can fire")
	_check(weapon.mag == mag_before - 1, "firing uses a bullet")
	await _physics(2)
	_check(not bot.is_alive(), "AK headshot kills a standard bot in one shot")
	_check(int(game.get("kills")) == 1 and int(game.get("headshots")) == 1, "kill and headshot are counted")
	_check(int(game.get("score")) == 150, "headshot kill is worth 150 points")

	var second := bots[1] as Bot
	_aim_at(player, second.global_position + Vector3.UP * 0.9)
	await _physics(30)
	player.set("_bloom", 0.0)
	player.try_fire()
	await _physics(2)
	_check(second.health == second.max_health - 30.0, "body shot deals 30 damage (health %.0f)" % second.health)

	# --- Empty magazine and reload ----------------------------------------------------
	weapon.mag = 0
	player.set("_fire_cooldown", 0.0)
	var reserve_before := weapon.reserve
	player.try_fire()
	_check(player.reloading, "an empty magazine triggers a reload")
	await _physics(int(weapon.reload_time * 60.0) + 10)
	_check(weapon.mag == weapon.mag_size and weapon.reserve == reserve_before - weapon.mag_size, "reload refills the magazine from reserve")

	# --- Weapon switching -------------------------------------------------------------
	player.switch_weapon(1)
	_check(player.get_weapon_name() == "DESERT EAGLE", "player can switch to the pistol")
	player.switch_weapon(0)

	# --- Pickups ----------------------------------------------------------------------
	player.health = 50.0
	var health_pickup: Pickup
	for node in game.get_tree().get_nodes_in_group("pickups"):
		if (node as Pickup).kind == Pickup.Kind.HEALTH:
			health_pickup = node
			break
	_check(health_pickup.try_collect(player) and player.health == 90.0, "health pickup heals 40")
	_check(not health_pickup.try_collect(player), "used pickup is unavailable until it respawns")

	# --- Door --------------------------------------------------------------------------
	var door := level.doors[0]
	door.reset()
	door.interact(player)
	await _physics(45)
	_check(door.is_open and door.position.z > 4.0, "door slides open (z %.2f)" % door.position.z)
	door.interact(player)
	_check(not door.is_open, "door closes again")

	# --- Explosive barrel --------------------------------------------------------------
	var barrel := game.get_tree().get_nodes_in_group("damageable").filter(func(n: Node) -> bool: return n is ExplosiveBarrel)[0] as ExplosiveBarrel
	barrel.take_damage(100.0, barrel.global_position, false, player)
	await _physics(20)
	_check(not is_instance_valid(barrel), "shot barrel explodes")

	# --- Win condition --------------------------------------------------------------------
	player.invulnerable = true
	for wave in 3:
		for node in game.get_tree().get_nodes_in_group("bots"):
			if (node as Bot).is_alive():
				(node as Bot).take_damage(1000.0, (node as Bot).global_position, false, player)
		await _physics(5)
		if int(game.get("state")) == 4:
			break
		game.set("_wave_break_timer", 0.01)
		game.set("_spawn_timer", 0.0)
		await _physics(10)
		while not (game.get("_pending_spawns") as Array).is_empty():
			game.set("_spawn_timer", 0.0)
			await _physics(2)
		await _physics(5)
	for node in game.get_tree().get_nodes_in_group("bots"):
		if (node as Bot).is_alive():
			(node as Bot).take_damage(1000.0, (node as Bot).global_position, false, player)
	await _physics(5)
	_check(int(game.get("state")) == 4, "clearing all waves wins the mission (state %d)" % int(game.get("state")))
	await create_timer(1.2).timeout
	var menus := game.get("menus") as GameMenus
	_check(menus.is_any_visible(), "end screen is shown")

	# --- Restart and game over ------------------------------------------------------------
	game.call("start_game", false)
	await _frames(2)
	_check(int(game.get("state")) == 1 and player.health == Player.MAX_HEALTH and int(game.get("score")) == 0, "restart resets the run")
	_check(game.get_tree().get_nodes_in_group("bots").is_empty(), "restart clears bots")
	player.take_damage(500.0, Vector3.ZERO, false, null)
	await _frames(2)
	_check(not player.alive and int(game.get("state")) == 3, "player at 0 HP triggers GAME OVER")

	# --- Practice mode ----------------------------------------------------------------------
	game.call("start_game", true)
	await _physics(5)
	var practice_bots := game.get_tree().get_nodes_in_group("bots")
	_check(practice_bots.size() == level.practice_spots.size(), "practice spawns a full grid of bots")
	var target := practice_bots[0] as Bot
	target.take_damage(1000.0, target.global_position, true, player)
	await _physics(80)
	var alive_count := 0
	for node in game.get_tree().get_nodes_in_group("bots"):
		if (node as Bot).is_alive():
			alive_count += 1
	_check(alive_count == level.practice_spots.size(), "practice bot respawns after a kill")

	game.call("go_to_menu")
	await _frames(2)
	_check(int(game.get("state")) == 0, "can return to the main menu")

	game.queue_free()
	await _frames(3)
	if _failures == 0:
		print("SMOKE_TEST: PASS")
		quit(0)
	else:
		print("SMOKE_TEST: %d FAILURE(S)" % _failures)
		quit(1)


func _aim_at(player: Player, point: Vector3) -> void:
	var eye := player.get_eye_position()
	var direction := point - eye
	player.rotation.y = atan2(-direction.x, -direction.z)
	var flat := Vector2(direction.x, direction.z).length()
	player.get_node("Head").rotation.x = atan2(direction.y, flat)
	player.get_camera().rotation = Vector3.ZERO
	player.set("_recoil_pitch", 0.0)
	player.set("_recoil_yaw", 0.0)
	player.set("_shake", 0.0)


func _frames(count: int) -> void:
	for index in count:
		await process_frame


func _physics(count: int) -> void:
	for index in count:
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok   ", message)
	else:
		_failures += 1
		push_error("SMOKE_TEST failed: %s" % message)
		print("  FAIL ", message)
