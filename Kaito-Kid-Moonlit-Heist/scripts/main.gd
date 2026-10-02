class_name HeistMain
extends Node3D
## Game flow: TITLE -> PLAYING <-> PAUSED -> WON / LOST. Builds the level, player, guards and UI,
## and routes gameplay signals to the HUD and sound. Restart reloads the scene.

enum State { TITLE, PLAYING, PAUSED, WON, LOST }

## Skip the title screen on reload when the player chose Retry / Play again.
static var skip_title := false

var state := State.TITLE
var level: MuseumLevel
var player: PhantomThief
var camera_rig: ThirdPersonCamera
var guards_root: Node3D
var effects_root: Node3D
var sound: SoundFX
var hud: HeistHUD
var menus: HeistMenus

var jewels_stolen := 0
var jewels_total := KK.JEWELS_REQUIRED
var run_time := 0.0
var knockouts := 0
var times_spotted := 0
var alarm_on := false
var _chasing := 0
var _alert_level := 0
var _prompt_hold := 0.0
var _last_prompt := ""


func _ready() -> void:
	KK.ensure_input_actions()
	process_mode = Node.PROCESS_MODE_ALWAYS

	level = MuseumLevel.new()
	level.name = "Level"
	add_child(level)
	level.build()

	effects_root = Node3D.new()
	effects_root.name = "Effects"
	add_child(effects_root)

	player = PhantomThief.new()
	player.name = "Player"
	add_child(player)
	player.global_transform = level.player_spawn()
	player.effects_root = effects_root

	camera_rig = ThirdPersonCamera.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.target = player
	camera_rig.snap_behind_target()
	player.camera_rig = camera_rig

	guards_root = Node3D.new()
	guards_root.name = "Guards"
	add_child(guards_root)
	for route: Dictionary in level.guard_routes():
		spawn_guard(route["kind"], route["points"], route.get("wait", 1.5))

	sound = SoundFX.new()
	sound.name = "SoundFX"
	add_child(sound)

	hud = HeistHUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.setup(level, player)

	menus = HeistMenus.new()
	menus.name = "Menus"
	add_child(menus)
	_load_settings()

	_connect_signals()
	hud.set_health(player.hp, player.max_hp)
	hud.set_smoke(player.smoke_bombs)
	jewels_total = level.jewels().size()
	hud.set_jewels(0, jewels_total)
	hud.set_objective("Steal the jewels  0/%d" % jewels_total)

	for node in [level, player, camera_rig, guards_root, effects_root]:
		node.process_mode = Node.PROCESS_MODE_PAUSABLE

	if skip_title:
		skip_title = false
		start_game()
	else:
		_enter_title()


func spawn_guard(kind: int, points: PackedVector3Array, wait := 1.5) -> Guard:
	var guard := Guard.new()
	guard.name = "%s%d" % ["Inspector" if kind == KK.EnemyKind.INSPECTOR else "Guard", guards_root.get_child_count()]
	guards_root.add_child(guard)
	guard.global_position = points[0]
	guard.setup(kind, points, wait)
	guard.state_changed.connect(_on_guard_state_changed)
	guard.spotted_player.connect(_on_guard_spotted)
	guard.knocked_out.connect(_on_guard_knocked_out)
	guard.attacked.connect(_on_guard_attacked)
	return guard


func _connect_signals() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	player.smoke_changed.connect(func(count: int) -> void: hud.set_smoke(count))
	player.card_fired.connect(func() -> void: sound.play("card_throw", player.global_position))
	player.smoke_thrown.connect(func(pos: Vector3) -> void: sound.play("smoke", pos))
	player.footstep.connect(func(running: bool) -> void:
		sound.play("footstep_run" if running else "footstep", player.global_position))
	player.landed.connect(func() -> void: sound.play("land", player.global_position))
	for jewel: Jewel in level.jewels():
		jewel.stolen.connect(_on_jewel_stolen)
	level.exit_node().escaped.connect(_on_escaped)
	level.laser_tripped.connect(_on_laser_tripped)
	level.lasers_disabled.connect(func() -> void:
		sound.play("laser_off")
		hud.show_banner("Laser grid offline", Color(0.6, 0.9, 1.0)))
	level.camera_spotted.connect(_on_camera_spotted)
	level.pickup_collected.connect(func(kind: String, pos: Vector3) -> void:
		sound.play("pickup_" + kind, pos))
	level.atmosphere().lightning.connect(func(strength: float) -> void:
		sound.thunder(strength)
		hud.show_lightning(strength))
	menus.start_requested.connect(start_game)
	menus.resume_requested.connect(resume_game)
	menus.restart_requested.connect(restart_game)
	menus.menu_requested.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	menus.quit_requested.connect(func() -> void: get_tree().quit())
	menus.settings_changed.connect(_apply_settings)


func _enter_title() -> void:
	state = State.TITLE
	player.controls_enabled = false
	camera_rig.input_enabled = false
	camera_rig.set_showcase(true)
	hud.set_visible_hud(false)
	menus.show_screen("title")
	sound.set_music("title")
	_set_mouse_captured(false)


func start_game() -> void:
	state = State.PLAYING
	get_tree().paused = false
	menus.hide_all()
	camera_rig.set_showcase(false)
	camera_rig.snap_behind_target()
	camera_rig.input_enabled = true
	player.controls_enabled = true
	hud.set_visible_hud(true)
	hud.show_banner("It's showtime.", Color(1.0, 0.95, 0.8), 2.5)
	sound.set_music("sneak")
	_set_mouse_captured(true)


func pause_game() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	get_tree().paused = true
	menus.show_screen("pause")
	_set_mouse_captured(false)


func resume_game() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	menus.hide_all()
	hud.set_prompt("")
	get_tree().paused = false
	_set_mouse_captured(true)


func restart_game() -> void:
	skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause_game()
		elif state == State.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm") and state == State.TITLE:
		start_game()
	elif event.is_action_pressed("restart") and state in [State.WON, State.LOST, State.PAUSED]:
		restart_game()
	elif event is InputEventMouseButton and event.pressed and state == State.PLAYING \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_set_mouse_captured(true)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	run_time += delta
	hud.set_timer(run_time)
	var focus := player.get_focus_interactable()
	if focus:
		_last_prompt = focus.get_prompt()
		_prompt_hold = 0.12
	else:
		_prompt_hold = maxf(0.0, _prompt_hold - delta)
	hud.set_prompt(_last_prompt if _prompt_hold > 0.0 else "")


func _set_mouse_captured(captured: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


# --- Objective ---------------------------------------------------------------

func _on_jewel_stolen(jewel: Jewel) -> void:
	jewels_stolen += 1
	sound.play("jewel_steal", jewel.global_position)
	hud.set_jewels(jewels_stolen, jewels_total)
	if jewels_stolen >= jewels_total:
		_trigger_alarm()
	else:
		hud.set_objective("Steal the jewels  %d/%d" % [jewels_stolen, jewels_total])
		hud.show_banner("%s stolen  (%d/%d)" % [jewel.jewel_name, jewels_stolen, jewels_total], jewel.gem_color)


func _trigger_alarm() -> void:
	alarm_on = true
	level.exit_node().unlock()
	level.atmosphere().set_alarm(true)
	for guard: Guard in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		guard.speed_mult = KK.ALARM_SPEED_MULT
	sound.play("exit_unlock")
	sound.set_music("escape")
	hud.set_objective("Escape! Reach the glider on the balcony")
	hud.show_banner("ALARM! All jewels taken - fly from the balcony!", Color(1.0, 0.35, 0.3), 3.5)


func _on_escaped() -> void:
	if state != State.PLAYING:
		return
	state = State.WON
	player.controls_enabled = false
	camera_rig.input_enabled = false
	sound.set_music("win")
	sound.play("win")
	var best := _load_best_time()
	var new_best := best < 0.0 or run_time < best
	if new_best:
		_save_best_time(run_time)
	_end_screen("win", {"best_time": run_time if new_best else best, "new_best": new_best})


func _on_player_died() -> void:
	if state != State.PLAYING:
		return
	state = State.LOST
	camera_rig.input_enabled = false
	sound.set_music("lose")
	sound.play("lose")
	_end_screen("game_over", {"cause": "Caught by the museum police"})


func _end_screen(screen: String, extra: Dictionary) -> void:
	hud.set_prompt("")
	var data := {
		"time": run_time,
		"jewels": jewels_stolen,
		"jewels_total": jewels_total,
		"knockouts": knockouts,
		"spotted": times_spotted,
	}
	data.merge(extra)
	_set_mouse_captured(false)
	# Let the death / escape moment play before the screen appears.
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		menus.show_screen(screen, data)


# --- Player / enemies ----------------------------------------------------------

func _on_player_health_changed(hp: float, max_hp: float) -> void:
	hud.set_health(hp, max_hp)


func _on_player_damaged(_amount: float) -> void:
	hud.flash_damage()
	camera_rig.shake(0.35)
	sound.play("hit_player", player.global_position)


func _on_guard_spotted(guard: Guard) -> void:
	times_spotted += 1
	sound.play("guard_alert", guard.global_position)
	if guard.kind == KK.EnemyKind.INSPECTOR:
		hud.show_banner("\"KAITO KID! Get him!\"", Color(1.0, 0.8, 0.4), 2.0)


func _on_guard_knocked_out(guard: Guard) -> void:
	knockouts += 1
	sound.play("guard_down", guard.global_position)


func _on_guard_attacked(guard: Guard, _hit: bool) -> void:
	sound.play("baton_swing", guard.global_position)


func _on_guard_state_changed(guard: Guard, _old: int, new_state: int) -> void:
	if new_state == Guard.State.SUSPICIOUS:
		sound.play("guard_huh", guard.global_position)
	elif new_state == Guard.State.STUNNED:
		sound.play("card_hit", guard.global_position)
	_refresh_alert_level()


func _refresh_alert_level() -> void:
	var level_now := 0
	for guard: Guard in get_tree().get_nodes_in_group(KK.GROUP_GUARDS):
		match guard.state:
			Guard.State.CHASE, Guard.State.ATTACK:
				level_now = 2
			Guard.State.SUSPICIOUS, Guard.State.SEARCH:
				level_now = maxi(level_now, 1)
	if level_now == _alert_level:
		return
	_alert_level = level_now
	hud.set_alert(level_now)
	if state == State.PLAYING and not alarm_on:
		sound.set_music(["sneak", "alert", "chase"][level_now])


func _on_laser_tripped(pos: Vector3) -> void:
	sound.play("laser_trip", pos)
	hud.show_banner("Laser tripped!", Color(1.0, 0.3, 0.3), 1.5)


func _on_camera_spotted(pos: Vector3) -> void:
	sound.play("camera_alert", pos)
	hud.show_banner("Security camera spotted you!", Color(1.0, 0.5, 0.3), 1.8)


func _load_best_time() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(KK.SAVE_PATH) != OK:
		return -1.0
	return float(cfg.get_value("records", "best_time", -1.0))


func _save_best_time(seconds: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(KK.SAVE_PATH)
	cfg.set_value("records", "best_time", seconds)
	cfg.save(KK.SAVE_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(KK.SAVE_PATH) == OK:
		var values := {}
		for key in menus.settings:
			values[key] = cfg.get_value("settings", key, menus.settings[key])
		menus.set_settings(values)
	_apply_settings(menus.settings, false)


func _apply_settings(values: Dictionary, save: bool = true) -> void:
	if sound.has_method("set_volume"):
		for pair in [["Master", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"]]:
			sound.set_volume(pair[0], clampf(float(values[pair[1]]), 0.0, 1.0))
	if "sensitivity" in camera_rig:
		camera_rig.set("sensitivity", 0.0025 * clampf(float(values["mouse_sensitivity"]), 0.25, 2.5))
	if "invert_y" in camera_rig:
		camera_rig.set("invert_y", bool(values["invert_y"]))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(values["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED)
	if save:
		var cfg := ConfigFile.new()
		cfg.load(KK.SAVE_PATH)
		for key in values:
			cfg.set_value("settings", key, values[key])
		cfg.save(KK.SAVE_PATH)
