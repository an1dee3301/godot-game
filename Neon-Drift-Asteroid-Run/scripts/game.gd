extends Node2D

enum GameState {
	TITLE,
	PLAYING,
	RESPAWNING,
	BETWEEN_WAVES,
	GAME_OVER
}

const StarfieldScript = preload("res://scripts/starfield.gd")
const PlayerScript = preload("res://scripts/player.gd")
const AsteroidScript = preload("res://scripts/asteroid.gd")
const BulletScript = preload("res://scripts/bullet.gd")
const ExplosionScript = preload("res://scripts/explosion.gd")
const FloatingTextScript = preload("res://scripts/floating_text.gd")
const HudScript = preload("res://scripts/hud.gd")
const SoundManagerScript = preload("res://scripts/sound_manager.gd")

const SAVE_PATH := "user://asteroids.cfg"
const MAX_BULLETS := 5
const EXTRA_LIFE_STEP := 10000

var state := GameState.TITLE
var paused := false
var score := 0
var best_score := 0
var lives := 3
var wave := 0
var next_extra_life := EXTRA_LIFE_STEP
var wave_timer := 0.0
var respawn_timer := 0.0
var combo_timer := 0.0
var combo_hits := 0
var combo_multiplier := 1
var shake_time := 0.0
var shake_strength := 0.0

var rng := RandomNumberGenerator.new()
var background
var world: Node2D
var entities: Node2D
var effects: Node2D
var ship
var hud
var sound_fx
var asteroids: Array = []
var bullets: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_configure_input()
	_build_scene_tree()
	_load_best_score()
	_prepare_title_screen()


func _build_scene_tree() -> void:
	background = StarfieldScript.new()
	background.name = "Starfield"
	background.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(background)

	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	entities = Node2D.new()
	entities.name = "Entities"
	world.add_child(entities)

	effects = Node2D.new()
	effects.name = "Effects"
	world.add_child(effects)

	sound_fx = SoundManagerScript.new()
	sound_fx.name = "SoundManager"
	add_child(sound_fx)

	hud = HudScript.new()
	hud.name = "HUD"
	add_child(hud)


func _process(delta: float) -> void:
	_update_background_motion()
	if paused:
		return

	_update_screen_shake(delta)
	_update_combo(delta)

	match state:
		GameState.PLAYING:
			_check_collisions()
			if asteroids.is_empty():
				_begin_wave_break()
		GameState.RESPAWNING:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				if _center_is_safe():
					_spawn_ship(1.9)
					state = GameState.PLAYING
				else:
					respawn_timer = 0.3
		GameState.BETWEEN_WAVES:
			wave_timer -= delta
			if wave_timer <= 0.0:
				_start_next_wave()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("pause"):
		if state != GameState.TITLE and state != GameState.GAME_OVER:
			_toggle_pause()
			get_viewport().set_input_as_handled()
		return

	if paused:
		return

	if state == GameState.TITLE and event.is_action_pressed("start_game"):
		start_new_game()
		get_viewport().set_input_as_handled()
	elif state == GameState.GAME_OVER and (event.is_action_pressed("start_game") or event.is_action_pressed("restart")):
		start_new_game()
		get_viewport().set_input_as_handled()


func start_new_game() -> void:
	get_tree().paused = false
	paused = false
	_clear_world()
	score = 0
	lives = 3
	wave = 0
	next_extra_life = EXTRA_LIFE_STEP
	combo_timer = 0.0
	combo_hits = 0
	combo_multiplier = 1
	shake_time = 0.0
	world.position = Vector2.ZERO
	hud.show_gameplay()
	_spawn_ship(2.25)
	_start_next_wave()


func _prepare_title_screen() -> void:
	get_tree().paused = false
	paused = false
	_clear_world()
	state = GameState.TITLE
	hud.show_title(best_score)
	for i in range(7):
		_spawn_asteroid(rng.randi_range(1, 3))


func _start_next_wave() -> void:
	_clear_bullets()
	wave += 1
	state = GameState.PLAYING
	var asteroid_count := mini(3 + wave, 12)
	for i in range(asteroid_count):
		_spawn_asteroid(3)
	hud.update_hud(score, best_score, wave, lives, combo_multiplier)
	hud.show_banner("WAVE %02d" % wave, Color(0.42, 0.97, 1.0), 1.25)
	sound_fx.play_sound("wave", -12.0, minf(1.0 + float(wave - 1) * 0.025, 1.25))


func _begin_wave_break() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.BETWEEN_WAVES
	wave_timer = 1.65
	_reset_combo()
	hud.show_banner("SECTOR CLEAR", Color(0.5, 1.0, 0.72), 1.4)


func _spawn_ship(protection_time: float) -> void:
	if is_instance_valid(ship):
		ship.queue_free()
	ship = PlayerScript.new()
	ship.name = "PlayerShip"
	entities.add_child(ship)
	ship.setup(get_viewport_rect().size * 0.5, protection_time)
	ship.fired.connect(_on_ship_fired)


func _spawn_asteroid(level: int, requested_position: Vector2 = Vector2(-10000, -10000), requested_velocity: Vector2 = Vector2.ZERO):
	var spawn_position := requested_position
	if spawn_position.x < -9000.0:
		spawn_position = _safe_edge_position()

	var asteroid_velocity := requested_velocity
	if asteroid_velocity.length_squared() < 0.01:
		var speed_range := _speed_range_for_level(level)
		var wave_speed := minf(1.0 + 0.08 * float(maxi(wave - 1, 0)), 1.6)
		var speed := rng.randf_range(speed_range.x, speed_range.y) * wave_speed
		asteroid_velocity = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * speed

	var asteroid := AsteroidScript.new()
	asteroid.name = "Asteroid_%d" % (asteroids.size() + 1)
	entities.add_child(asteroid)
	asteroid.setup(level, spawn_position, asteroid_velocity, rng.randi())
	asteroids.append(asteroid)
	return asteroid


func _safe_edge_position() -> Vector2:
	var view_size := get_viewport_rect().size
	var candidate := Vector2.ZERO
	for attempt in range(14):
		match rng.randi_range(0, 3):
			0:
				candidate = Vector2(rng.randf_range(20.0, view_size.x - 20.0), 24.0)
			1:
				candidate = Vector2(view_size.x - 24.0, rng.randf_range(20.0, view_size.y - 20.0))
			2:
				candidate = Vector2(rng.randf_range(20.0, view_size.x - 20.0), view_size.y - 24.0)
			_:
				candidate = Vector2(24.0, rng.randf_range(20.0, view_size.y - 20.0))

		if not is_instance_valid(ship) or _toroidal_distance(candidate, ship.position) > 230.0:
			break
	return candidate


func _speed_range_for_level(level: int) -> Vector2:
	match level:
		3:
			return Vector2(70.0, 110.0)
		2:
			return Vector2(105.0, 155.0)
		_:
			return Vector2(150.0, 215.0)


func _on_ship_fired(origin: Vector2, direction: Vector2, inherited_velocity: Vector2) -> void:
	if state != GameState.PLAYING or bullets.size() >= MAX_BULLETS:
		return
	var bullet := BulletScript.new()
	bullet.name = "Pulse_%d" % (bullets.size() + 1)
	entities.add_child(bullet)
	bullet.setup(origin, direction, inherited_velocity)
	bullet.expired.connect(_on_bullet_expired)
	bullets.append(bullet)
	sound_fx.play_sound("shoot", -13.0, rng.randf_range(0.96, 1.05))


func _on_bullet_expired(bullet: Node) -> void:
	bullets.erase(bullet)


func _check_collisions() -> void:
	var bullet_snapshot := bullets.duplicate()
	for bullet in bullet_snapshot:
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			continue
		for asteroid in asteroids.duplicate():
			if not is_instance_valid(asteroid) or asteroid.is_queued_for_deletion():
				continue
			if _toroidal_distance(bullet.position, asteroid.position) <= bullet.radius + asteroid.radius * 0.86:
				bullets.erase(bullet)
				bullet.queue_free()
				_destroy_asteroid(asteroid, true)
				break

	if not is_instance_valid(ship) or ship.is_protected():
		return
	for asteroid in asteroids.duplicate():
		if not is_instance_valid(asteroid) or asteroid.is_queued_for_deletion():
			continue
		if _toroidal_distance(ship.position, asteroid.position) <= 13.0 + asteroid.radius * 0.82:
			_destroy_ship(asteroid)
			break


func _destroy_asteroid(asteroid, award_points: bool) -> void:
	if not is_instance_valid(asteroid) or not asteroids.has(asteroid):
		return

	var asteroid_position: Vector2 = asteroid.position
	var asteroid_velocity: Vector2 = asteroid.velocity
	var asteroid_level: int = asteroid.size_level
	var asteroid_points: int = asteroid.points
	var asteroid_color: Color = asteroid.accent
	asteroids.erase(asteroid)
	asteroid.queue_free()

	_spawn_explosion(asteroid_position, asteroid_color, 11 + asteroid_level * 5, 105.0 + asteroid_level * 26.0)
	if asteroid_level == 3:
		_add_screen_shake(0.09, 4.5)

	if award_points:
		_register_hit(asteroid_points, asteroid_position)
		if asteroid_level > 1:
			_spawn_fragments(asteroid_level - 1, asteroid_position, asteroid_velocity)

	var sound_name := "hit_large" if asteroid_level >= 2 else "hit_small"
	sound_fx.play_sound(sound_name, -11.0, rng.randf_range(0.9, 1.1))


func _spawn_fragments(child_level: int, spawn_position: Vector2, parent_velocity: Vector2) -> void:
	var speed_range := _speed_range_for_level(child_level)
	var base_angle := parent_velocity.angle()
	for side in [-1.0, 1.0]:
		var angle: float = base_angle + float(side) * rng.randf_range(0.52, 0.78)
		var fragment_speed := rng.randf_range(speed_range.x, speed_range.y)
		var fragment_velocity := Vector2.RIGHT.rotated(angle) * fragment_speed + parent_velocity * 0.22
		_spawn_asteroid(child_level, spawn_position, fragment_velocity)


func _register_hit(base_points: int, hit_position: Vector2) -> void:
	if combo_timer > 0.0:
		combo_hits += 1
	else:
		combo_hits = 1
	combo_timer = 1.3
	combo_multiplier = mini(1 + int((combo_hits - 1) / 4.0), 4)

	var awarded := base_points * combo_multiplier
	score += awarded
	best_score = maxi(best_score, score)
	_spawn_floating_text(hit_position, "+%d" % awarded, Color(1.0, 0.78, 0.42))

	while score >= next_extra_life:
		lives += 1
		next_extra_life += EXTRA_LIFE_STEP
		hud.show_banner("EXTRA SHIP", Color(0.5, 1.0, 0.72), 1.6)
		sound_fx.play_sound("extra_life", -8.0)

	hud.update_hud(score, best_score, wave, lives, combo_multiplier)


func _destroy_ship(colliding_asteroid) -> void:
	if not is_instance_valid(ship):
		return
	var death_position: Vector2 = ship.position
	var collision_color: Color = colliding_asteroid.accent
	asteroids.erase(colliding_asteroid)
	colliding_asteroid.queue_free()
	_spawn_explosion(colliding_asteroid.position, collision_color, 16, 155.0)
	_spawn_explosion(death_position, Color(0.42, 0.97, 1.0), 28, 245.0)
	ship.queue_free()
	ship = null
	lives -= 1
	_reset_combo()
	_add_screen_shake(0.28, 11.0)
	sound_fx.play_sound("ship_down", -5.0)
	hud.update_hud(score, best_score, wave, lives, combo_multiplier)

	if lives <= 0:
		_end_game()
	else:
		state = GameState.RESPAWNING
		respawn_timer = 1.15
		hud.show_banner("SHIP LOST", Color(1.0, 0.5, 0.38), 1.0)


func _end_game() -> void:
	state = GameState.GAME_OVER
	_clear_bullets()
	_save_best_score()
	hud.show_game_over(score, best_score, wave)


func _center_is_safe() -> bool:
	var center := get_viewport_rect().size * 0.5
	for asteroid in asteroids:
		if is_instance_valid(asteroid) and _toroidal_distance(center, asteroid.position) < asteroid.radius + 115.0:
			return false
	return true


func _toroidal_distance(first: Vector2, second: Vector2) -> float:
	var view_size := get_viewport_rect().size
	var delta := (first - second).abs()
	delta.x = minf(delta.x, view_size.x - delta.x)
	delta.y = minf(delta.y, view_size.y - delta.y)
	return delta.length()


func _spawn_explosion(spawn_position: Vector2, color: Color, particle_count: int, power: float) -> void:
	var explosion := ExplosionScript.new()
	effects.add_child(explosion)
	explosion.setup(spawn_position, color, particle_count, power)


func _spawn_floating_text(spawn_position: Vector2, message: String, color: Color) -> void:
	var floating_text := FloatingTextScript.new()
	effects.add_child(floating_text)
	floating_text.setup(spawn_position, message, color)


func _update_combo(delta: float) -> void:
	if combo_timer <= 0.0:
		return
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		_reset_combo()


func _reset_combo() -> void:
	combo_timer = 0.0
	combo_hits = 0
	combo_multiplier = 1
	if is_instance_valid(hud):
		hud.update_hud(score, best_score, wave, lives, combo_multiplier)


func _add_screen_shake(duration: float, strength: float) -> void:
	shake_time = maxf(shake_time, duration)
	shake_strength = maxf(shake_strength, strength)


func _update_screen_shake(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = maxf(shake_time - delta, 0.0)
		var fade := clampf(shake_time / 0.28, 0.0, 1.0)
		world.position = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake_strength * fade
	else:
		world.position = world.position.lerp(Vector2.ZERO, minf(delta * 20.0, 1.0))
		shake_strength = 0.0


func _update_background_motion() -> void:
	if is_instance_valid(ship):
		background.set_ship_motion(ship.velocity)
	else:
		background.set_ship_motion(Vector2.ZERO)


func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		world.position = Vector2.ZERO
	hud.set_paused(paused)


func _clear_bullets() -> void:
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	bullets.clear()


func _clear_world() -> void:
	if not is_instance_valid(entities) or not is_instance_valid(effects):
		return
	for child in entities.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	asteroids.clear()
	bullets.clear()
	ship = null


func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("scores", "best", 0))


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "best", best_score)
	config.save(SAVE_PATH)


func _configure_input() -> void:
	_register_action("rotate_left", [KEY_A, KEY_LEFT])
	_register_action("rotate_right", [KEY_D, KEY_RIGHT])
	_register_action("thrust", [KEY_W, KEY_UP])
	_register_action("fire", [KEY_SPACE])
	_register_action("pause", [KEY_P, KEY_ESCAPE])
	_register_action("start_game", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_register_action("restart", [KEY_R])


func _register_action(action_name: StringName, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var already_registered := false
		for existing_event in InputMap.action_get_events(action_name):
			if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
				already_registered = true
				break
		if already_registered:
			continue
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(action_name, key_event)
