extends Node3D
## Game flow: main menu -> mission (3 waves of bots) or Aim Botz practice ->
## Mission Complete / Game Over -> restart. Owns score, timer and stats.

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

const SAVE_PATH := "user://aim_botz_arena.cfg"
const WAVES := [
	{"standard": 3, "heavy": 0},
	{"standard": 4, "heavy": 1},
	{"standard": 5, "heavy": 2},
]
const PRACTICE_DURATION := 60.0
const FIRST_WAVE_DELAY := 3.0
const WAVE_BREAK := 5.0
const SPAWN_INTERVAL := 0.7
const PRACTICE_RESPAWN := 1.0
const BOT_NAMES := [
	"Ivan", "Rock", "Wolf", "Cliffe", "Hank", "Vitaliy", "Shark", "Brett", "Moe",
	"Kurt", "Elmer", "Gabe", "Quintin", "Jon", "Ringo", "Stan", "Yanni", "Xander",
]

var state := GameState.MENU
var practice := false
var world: Node3D
var level: ArenaLevel
var player: Player
var bots_root: Node3D
var props_root: Node3D
var effects_root: Node3D
var sound_fx: SoundFX
var hud: GameHUD
var menus: GameMenus
var menu_camera: Camera3D

var wave_index := -1
var alive_bots := 0
var kills := 0
var headshots := 0
var shots := 0
var hits := 0
var score := 0
var elapsed := 0.0
var best_score := 0
var sensitivity := 1.0

var _pending_practice: Array[Dictionary] = []
var _pending_spawns: Array[int] = []
var _spawn_timer := 0.0
var _wave_break_timer := 0.0
var _end_timer := 0.0
var _end_victory := false
var _end_stats := ""
var _practice_strafe := false
var _menu_orbit := 0.0
var _name_index := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_setup_input_map()
	_load_settings()

	sound_fx = SoundFX.new()
	sound_fx.name = "SoundFX"
	add_child(sound_fx)

	world = Node3D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	level = ArenaLevel.new()
	level.name = "Level"
	world.add_child(level)
	level.set_sound_fx(sound_fx)
	props_root = _container("Props")
	bots_root = _container("Bots")
	effects_root = _container("Effects")

	player = Player.new()
	player.name = "Player"
	player.sound_fx = sound_fx
	player.effects_root = effects_root
	player.mouse_sensitivity = sensitivity
	world.add_child(player)
	player.reset(level.player_spawn)
	player.shot_fired.connect(_on_player_shot)
	player.hit_landed.connect(_on_player_hit)
	player.died.connect(_on_player_died)

	menu_camera = Camera3D.new()
	menu_camera.name = "MenuCamera"
	menu_camera.fov = 70.0
	world.add_child(menu_camera)

	hud = GameHUD.new()
	hud.name = "HUD"
	hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hud)
	hud.setup(player, level)

	menus = GameMenus.new()
	menus.name = "Menus"
	add_child(menus)
	menus.start_requested.connect(start_game)
	menus.resume_requested.connect(resume)
	menus.restart_requested.connect(restart_game)
	menus.main_menu_requested.connect(go_to_menu)
	menus.quit_requested.connect(func() -> void: get_tree().quit())
	menus.sensitivity_changed.connect(_on_sensitivity_changed)
	menus.set_sensitivity(sensitivity)
	menus.set_best_score(best_score)

	go_to_menu()
	if "--waves" in OS.get_cmdline_user_args():
		start_game(false)
	elif "--practice" in OS.get_cmdline_user_args():
		start_game(true)
	elif "--strafe" in OS.get_cmdline_user_args():
		start_game(true)
		set_practice_strafe(true)


# --- State transitions -----------------------------------------------------------

func start_game(practice_mode: bool) -> void:
	_clear_run()
	practice = practice_mode
	state = GameState.PLAYING
	get_tree().paused = false
	kills = 0
	headshots = 0
	shots = 0
	hits = 0
	score = 0
	elapsed = 0.0
	wave_index = -1
	alive_bots = 0
	_pending_spawns.clear()
	_end_timer = 0.0
	_practice_strafe = false

	player.infinite_reserve = practice
	player.invulnerable = practice
	player.input_enabled = true
	player.get_camera().current = true
	hud.reset()
	hud.visible = true
	hud.set_health(player.health, Player.MAX_HEALTH)
	player.reset(level.player_spawn)
	menus.hide_all()
	sound_fx.play("ui")
	_capture_mouse(true)

	if practice:
		for spot in level.practice_spots:
			_spawn_bot(Bot.Type.STANDARD, spot, true)
		hud.show_banner("AIM PRACTICE", "60 seconds - B toggles strafing - Esc pauses", 3.0)
	else:
		_spawn_props()
		_wave_break_timer = FIRST_WAVE_DELAY
		hud.show_banner("GET READY", "Eliminate every bot across %d waves" % WAVES.size(), FIRST_WAVE_DELAY)
	_refresh_hud()


func go_to_menu() -> void:
	_clear_run()
	state = GameState.MENU
	get_tree().paused = false
	player.input_enabled = false
	player.reset(level.player_spawn)
	hud.visible = false
	menu_camera.current = true
	menus.set_best_score(best_score)
	menus.show_main_menu()
	_capture_mouse(false)


func pause() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.PAUSED
	get_tree().paused = true
	menus.show_pause()
	_capture_mouse(false)


func resume() -> void:
	if state != GameState.PAUSED:
		return
	state = GameState.PLAYING
	get_tree().paused = false
	menus.hide_all()
	_capture_mouse(true)


func restart_game() -> void:
	var strafe := _practice_strafe
	start_game(practice)
	if practice:
		set_practice_strafe(strafe)


func set_practice_strafe(enabled: bool) -> void:
	_practice_strafe = enabled
	for node in bots_root.get_children():
		(node as Bot).practice_strafe = enabled


func _finish(victory: bool) -> void:
	state = GameState.VICTORY if victory else GameState.GAME_OVER
	player.input_enabled = false
	player.reloading = false
	player.aiming = false
	_pending_practice.clear()
	for bot in bots_root.get_children():
		bot.set_physics_process(false)
	# A bot's death signal precedes the lethal ray's hit signal.
	# Build the result after both signals so the final shot counts.
	call_deferred("_prepare_result", victory)


func _prepare_result(victory: bool) -> void:
	if state != GameState.VICTORY and state != GameState.GAME_OVER:
		return
	var accuracy := _accuracy()
	var lines: Array[String] = []
	if victory and not practice:
		var time_bonus := maxi(0, 3000 - int(elapsed) * 10)
		var accuracy_bonus := int(accuracy * 20.0)
		score += time_bonus + accuracy_bonus
		lines.append("Time  %s   (+%d time bonus)" % [GameHUD.format_time(elapsed), time_bonus])
		lines.append("Accuracy  %d%%   (+%d accuracy bonus)" % [int(accuracy), accuracy_bonus])
	else:
		lines.append("Session time  %s" % GameHUD.format_time(elapsed))
		lines.append("Shots  %d     Accuracy  %.1f%%" % [shots, accuracy])
	lines.append("Kills  %d     Headshots  %d (%d%%)" % [kills, headshots, _headshot_rate()])
	lines.append("")
	if victory and not practice and score > best_score:
		best_score = score
		_save_settings()
		lines.append("FINAL SCORE  %d   - NEW BEST!" % score)
	else:
		lines.append("FINAL SCORE  %d%s" % [score, "   (best %d)" % best_score if not practice else ""])
	hud.set_score(score)
	sound_fx.play("win" if victory else "lose")
	_end_timer = 1.4 if not victory else 0.8
	_end_victory = victory
	_end_stats = "\n".join(lines)


# --- Frame update -----------------------------------------------------------------

func _process(delta: float) -> void:
	match state:
		GameState.MENU:
			_orbit_menu_camera(delta)
		GameState.PLAYING:
			_update_playing(delta)
		GameState.GAME_OVER, GameState.VICTORY:
			if _end_timer > 0.0:
				_end_timer -= delta
				if _end_timer <= 0.0:
					hud.show_banner("", "", 0.0)
					menus.show_end(_end_victory, _end_stats, practice)
					_capture_mouse(false)


func _update_playing(delta: float) -> void:
	elapsed += delta
	hud.set_time(maxf(PRACTICE_DURATION - elapsed, 0.0) if practice else elapsed)
	if practice:
		if elapsed >= PRACTICE_DURATION:
			elapsed = PRACTICE_DURATION
			_finish(true)
		else:
			_update_practice_respawns(delta)
		return
	if _wave_break_timer > 0.0:
		_wave_break_timer -= delta
		if _wave_break_timer <= 0.0:
			_begin_wave(wave_index + 1)
		return
	if not _pending_spawns.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = SPAWN_INTERVAL
			var bot_type: int = _pending_spawns.pop_front()
			_spawn_bot(bot_type, _pick_spawn_point(), false)
			_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == GameState.PLAYING:
			pause()
		elif state == GameState.PAUSED:
			resume()
		get_viewport().set_input_as_handled()
	elif state == GameState.PLAYING and event.is_action_pressed("toggle_strafe") and practice:
		set_practice_strafe(not _practice_strafe)
		hud.show_banner("", "Strafing bots %s" % ("ON" if _practice_strafe else "OFF"), 1.2)
	elif state == GameState.PLAYING and event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_capture_mouse(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == GameState.PLAYING:
		pause()


# --- Waves and bots ---------------------------------------------------------------

func _begin_wave(index: int) -> void:
	wave_index = index
	var config: Dictionary = WAVES[index]
	_pending_spawns.clear()
	for count in int(config["standard"]):
		_pending_spawns.append(Bot.Type.STANDARD)
	for count in int(config["heavy"]):
		_pending_spawns.append(Bot.Type.HEAVY)
	_pending_spawns.shuffle()
	_spawn_timer = 0.0
	hud.show_banner("WAVE %d / %d" % [index + 1, WAVES.size()], "%d bots incoming" % _pending_spawns.size(), 2.5)
	sound_fx.play("wave")
	_refresh_hud()


func _spawn_bot(bot_type: int, spot: Vector3, practice_target: bool) -> Bot:
	var bot := Bot.new()
	bot.bot_type = bot_type
	bot.bot_name = "BOT %s" % BOT_NAMES[_name_index % BOT_NAMES.size()]
	_name_index += 1
	bot.practice_target = practice_target
	bot.practice_strafe = _practice_strafe
	bot.player = player
	bot.sound_fx = sound_fx
	bot.effects_root = effects_root
	bot.position = spot + Vector3.UP * 0.05
	bot.set_meta("spot", spot)
	bot.died.connect(_on_bot_died)
	bots_root.add_child(bot)
	alive_bots += 1
	if not practice_target:
		Fx.spawn_beam(effects_root, spot)
		sound_fx.play_at("spawn", spot, -4.0)
	return bot


func _pick_spawn_point() -> Vector3:
	var candidates: Array[Vector3] = []
	for spot in level.bot_spawns:
		if spot.distance_to(player.global_position) < 20.0:
			continue
		var occupied := false
		for node in bots_root.get_children():
			if (node as Node3D).global_position.distance_to(spot) < 2.0:
				occupied = true
				break
		if not occupied:
			candidates.append(spot)
	if candidates.is_empty():
		return level.bot_spawns[_rng.randi() % level.bot_spawns.size()]
	return candidates[_rng.randi() % candidates.size()]


func _on_bot_died(bot: Bot, headshot: bool, cause: String, by_player: bool) -> void:
	alive_bots = maxi(alive_bots - 1, 0)
	var heavy := bot.bot_type == Bot.Type.HEAVY
	if by_player:
		kills += 1
		var points := 250 if heavy else 100
		if headshot:
			headshots += 1
			points += points / 2
		if cause == "EXPLOSION":
			points += 50
		score += points
		sound_fx.play("kill", -6.0)
		hud.add_kill(bot.bot_name, cause, headshot, heavy)
	if practice:
		var spot: Vector3 = bot.get_meta("spot")
		_pending_practice.append({"spot": spot, "remaining": PRACTICE_RESPAWN})
	elif state == GameState.PLAYING and alive_bots == 0 and _pending_spawns.is_empty() and _wave_break_timer <= 0.0:
		if wave_index >= WAVES.size() - 1:
			hud.show_banner("MISSION COMPLETE", "All bots eliminated", 2.0)
			_finish(true)
		else:
			_wave_break_timer = WAVE_BREAK
			hud.show_banner("WAVE %d CLEARED" % (wave_index + 1), "Next wave in %d seconds - grab health and ammo" % int(WAVE_BREAK), WAVE_BREAK - 0.5)
	_refresh_hud()


func _update_practice_respawns(delta: float) -> void:
	for index in range(_pending_practice.size() - 1, -1, -1):
		_pending_practice[index]["remaining"] -= delta
		if float(_pending_practice[index]["remaining"]) <= 0.0:
			var spot: Vector3 = _pending_practice[index]["spot"]
			_pending_practice.remove_at(index)
			_spawn_bot(Bot.Type.STANDARD, spot, true)


func _on_player_shot() -> void:
	shots += 1
	_refresh_stats()


func _on_player_hit(_target: Node, _headshot: bool, _killed: bool) -> void:
	hits += 1
	_refresh_stats()


func _on_player_died() -> void:
	if state == GameState.PLAYING:
		hud.show_banner("YOU DIED", "", 1.4)
		_finish(false)


# --- Helpers ----------------------------------------------------------------------

func _spawn_props() -> void:
	for spot in level.health_spots:
		_spawn_pickup(Pickup.Kind.HEALTH, spot)
	for spot in level.ammo_spots:
		_spawn_pickup(Pickup.Kind.AMMO, spot)
	for spot in level.barrel_spots:
		var barrel := ExplosiveBarrel.new()
		barrel.sound_fx = sound_fx
		barrel.effects_root = effects_root
		barrel.position = spot
		props_root.add_child(barrel)


func _spawn_pickup(kind: int, spot: Vector3) -> void:
	var pickup := Pickup.new()
	pickup.kind = kind
	pickup.sound_fx = sound_fx
	pickup.position = spot
	pickup.collected.connect(func(item: Pickup) -> void: hud.show_pickup(item.get_label()))
	props_root.add_child(pickup)


func _clear_run() -> void:
	_pending_practice.clear()
	_pending_spawns.clear()
	_end_timer = 0.0
	for container in [bots_root, props_root, effects_root]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	level.reset_doors()
	alive_bots = 0


func _refresh_hud() -> void:
	hud.set_score(score)
	if practice:
		hud.set_objective("AIM PRACTICE  -  %d KILLS" % kills)
	elif wave_index < 0:
		hud.set_objective("GET READY")
	else:
		hud.set_objective("WAVE %d / %d   -   ENEMIES LEFT %d" % [wave_index + 1, WAVES.size(), alive_bots + _pending_spawns.size()])
	_refresh_stats()


func _refresh_stats() -> void:
	hud.set_stats("Kills %d   HS %d%%   Acc %d%%" % [kills, _headshot_rate(), int(_accuracy())])


func _accuracy() -> float:
	return 0.0 if shots == 0 else float(hits) / float(shots) * 100.0


func _headshot_rate() -> int:
	return 0 if kills == 0 else int(float(headshots) / float(kills) * 100.0)


func _orbit_menu_camera(delta: float) -> void:
	_menu_orbit += delta * 0.08
	menu_camera.position = Vector3(sin(_menu_orbit) * 34.0, 16.0, cos(_menu_orbit) * 34.0)
	menu_camera.look_at(Vector3(0.0, 1.5, -4.0))


func _capture_mouse(captured: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


func _container(container_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = container_name
	world.add_child(node)
	return node


func _on_sensitivity_changed(value: float) -> void:
	sensitivity = value
	player.mouse_sensitivity = value
	_save_settings()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		sensitivity = float(config.get_value("settings", "sensitivity", 1.0))
		best_score = int(config.get_value("records", "best_score", 0))


func _save_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return  # Automated test runs must not overwrite the player's records.
	var config := ConfigFile.new()
	config.set_value("settings", "sensitivity", sensitivity)
	config.set_value("records", "best_score", best_score)
	config.save(SAVE_PATH)


func _setup_input_map() -> void:
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("jump", [KEY_SPACE])
	_bind_keys("sprint", [KEY_SHIFT])
	_bind_keys("reload", [KEY_R])
	_bind_keys("interact", [KEY_E])
	_bind_keys("weapon_1", [KEY_1])
	_bind_keys("weapon_2", [KEY_2])
	_bind_keys("weapon_next", [KEY_Q])
	_bind_keys("pause", [KEY_ESCAPE, KEY_P])
	_bind_keys("toggle_strafe", [KEY_B])
	_bind_mouse("shoot", MOUSE_BUTTON_LEFT)
	_bind_mouse("aim", MOUSE_BUTTON_RIGHT)
	_bind_mouse("weapon_next", MOUSE_BUTTON_WHEEL_DOWN)
	_bind_mouse("weapon_prev", MOUSE_BUTTON_WHEEL_UP)


func _bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _bind_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _exit_tree() -> void:
	get_tree().paused = false
	_capture_mouse(false)
