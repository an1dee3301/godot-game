extends Node3D
## Owns the session, menus, waves and practice statistics.

enum State { MENU, PLAYING, PAUSED, GAME_OVER, COMPLETE }
enum Mode { WAVES, STATIC, STRAFING }

const WAVE_COUNTS := [3, 5, 7]
const PRACTICE_DURATION := 60.0
const WAVE_BREAK := 3.0
const HUD_SCRIPT := preload("res://scripts/hud.gd")

var state := State.MENU
var mode := Mode.WAVES
var player: Player
var level: ArenaLevel
var sound_fx: SoundFX
var hud: Control
var world: Node3D
var actors: Node3D
var effects: Node3D
var menu_camera: Camera3D
var bots: Array[Bot] = []
var wave := 0
var elapsed := 0.0
var score := 0
var kills := 0
var shots := 0
var hits := 0
var headshots := 0
var _wave_timer := -1.0
var _respawns: Array[Dictionary] = []
var _bot_serial := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input()
	sound_fx = SoundFX.new()
	add_child(sound_fx)
	world = Node3D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	level = ArenaLevel.new()
	world.add_child(level)
	level.set_sound_fx(sound_fx)
	actors = Node3D.new()
	actors.name = "Actors"
	world.add_child(actors)
	effects = Node3D.new()
	effects.name = "Effects"
	world.add_child(effects)
	player = Player.new()
	player.name = "Player"
	player.sound_fx = sound_fx
	player.effects_root = effects
	world.add_child(player)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.shot_fired.connect(_on_shot_fired)
	player.hit_landed.connect(_on_hit_landed)
	player.interact_prompt_changed.connect(_on_prompt_changed)
	player.reset(level.player_spawn)
	menu_camera = Camera3D.new()
	menu_camera.position = Vector3(17.0, 17.0, 35.0)
	menu_camera.fov = 72.0
	world.add_child(menu_camera)
	menu_camera.look_at(Vector3(0.0, 1.0, -7.0))
	var layer := CanvasLayer.new()
	layer.name = "Interface"
	add_child(layer)
	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	layer.add_child(hud)
	hud.game = self
	hud.start_requested.connect(start_session)
	hud.resume_requested.connect(resume_session)
	hud.restart_requested.connect(restart_session)
	hud.menu_requested.connect(show_menu)
	hud.quit_requested.connect(_quit)
	show_menu()
	if "--waves" in OS.get_cmdline_user_args():
		start_session(Mode.WAVES)
	elif "--practice" in OS.get_cmdline_user_args():
		start_session(Mode.STATIC)
	elif "--strafe" in OS.get_cmdline_user_args():
		start_session(Mode.STRAFING)


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
		if mode != Mode.WAVES:
			if elapsed >= PRACTICE_DURATION:
				_finish(true)
			else:
				_update_practice_respawns(delta)
		elif _wave_timer >= 0.0:
			_wave_timer -= delta
			if _wave_timer <= 0.0:
				_spawn_wave()
		hud.refresh()
	elif state == State.GAME_OVER or state == State.COMPLETE:
		hud.refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause_session()
		elif state == State.PAUSED:
			resume_session()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and state in [State.GAME_OVER, State.COMPLETE]:
		restart_session()
		get_viewport().set_input_as_handled()


func start_session(selected_mode: int = Mode.WAVES) -> void:
	get_tree().paused = false
	mode = selected_mode as Mode
	_clear_session()
	elapsed = 0.0
	score = 0
	kills = 0
	shots = 0
	hits = 0
	headshots = 0
	wave = 0
	_wave_timer = -1.0
	_bot_serial = 0
	level.reset_doors()
	player.reset(level.player_spawn)
	player.infinite_reserve = mode != Mode.WAVES
	player.invulnerable = mode != Mode.WAVES
	player.input_enabled = true
	player.get_camera().current = true
	state = State.PLAYING
	hud.show_game()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spawn_supplies()
	_spawn_barrels()
	if mode == Mode.WAVES:
		_spawn_wave()
	else:
		for index in level.practice_spots.size():
			_spawn_bot(level.practice_spots[index], Bot.Type.STANDARD, index)
		hud.notify("60 SECONDS  /  Aim for the head", 3.0)
	hud.refresh()


func restart_session() -> void:
	start_session(mode)


func pause_session() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	player.input_enabled = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_pause()


func resume_session() -> void:
	if state != State.PAUSED:
		return
	state = State.PLAYING
	get_tree().paused = false
	player.input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_game(false)


func show_menu() -> void:
	get_tree().paused = false
	state = State.MENU
	player.input_enabled = false
	_clear_session()
	menu_camera.current = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_menu()


func accuracy() -> float:
	return 100.0 * float(hits) / float(shots) if shots > 0 else 0.0


func alive_count() -> int:
	return bots.size()


func objective_text() -> String:
	if mode != Mode.WAVES:
		return "STRAFING TARGETS" if mode == Mode.STRAFING else "STATIC TARGETS"
	if _wave_timer >= 0.0:
		return "NEXT WAVE IN %d" % maxi(1, ceili(_wave_timer))
	return "WAVE %d / %d  ·  %d HOSTILES" % [wave, WAVE_COUNTS.size(), bots.size()]


func time_text() -> String:
	var seconds := ceili(maxf(PRACTICE_DURATION - elapsed, 0.0)) if mode != Mode.WAVES else int(elapsed)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func elapsed_text() -> String:
	var seconds := int(minf(elapsed, PRACTICE_DURATION)) if mode != Mode.WAVES else int(elapsed)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _clear_session() -> void:
	bots.clear()
	_respawns.clear()
	_wave_timer = -1.0
	for container in [actors, effects]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()


func _spawn_wave() -> void:
	_wave_timer = -1.0
	wave += 1
	for index in WAVE_COUNTS[wave - 1]:
		var heavy: bool = wave > 1 and index < wave - 1
		_spawn_bot(level.bot_spawns[(index + (wave - 1) * 3) % level.bot_spawns.size()], Bot.Type.HEAVY if heavy else Bot.Type.STANDARD)
	sound_fx.play("wave", -3.0)
	hud.notify("WAVE %d  /  Clear the arena" % wave, 2.5)


func _spawn_bot(location: Vector3, kind: Bot.Type, practice_index := -1) -> Bot:
	var bot := Bot.new()
	_bot_serial += 1
	bot.name = "Bot%d" % _bot_serial
	bot.bot_name = ("HEAVY" if kind == Bot.Type.HEAVY else "BOT") + " %02d" % _bot_serial
	bot.bot_type = kind
	bot.practice_target = mode != Mode.WAVES
	bot.practice_strafe = mode == Mode.STRAFING
	bot.player = player
	bot.sound_fx = sound_fx
	bot.effects_root = effects
	bot.position = location + Vector3.UP * 0.06
	bot.died.connect(_on_bot_died.bind(practice_index))
	actors.add_child(bot)
	bots.append(bot)
	Fx.spawn_beam(effects, bot.global_position)
	return bot


func _spawn_supplies() -> void:
	for kind in [Pickup.Kind.HEALTH, Pickup.Kind.AMMO]:
		var spots: Array[Vector3] = level.health_spots if kind == Pickup.Kind.HEALTH else level.ammo_spots
		for spot in spots:
			var pickup := Pickup.new()
			pickup.kind = kind
			pickup.position = spot
			pickup.sound_fx = sound_fx
			pickup.collected.connect(_on_pickup_collected)
			actors.add_child(pickup)


func _spawn_barrels() -> void:
	for spot in level.barrel_spots:
		var barrel := ExplosiveBarrel.new()
		barrel.position = spot
		barrel.sound_fx = sound_fx
		barrel.effects_root = effects
		actors.add_child(barrel)


func _on_bot_died(bot: Bot, headshot: bool, cause: String, by_player: bool, practice_index: int) -> void:
	bots.erase(bot)
	if state != State.PLAYING:
		return
	if by_player:
		kills += 1
		var points := (250 if bot.bot_type == Bot.Type.HEAVY else 100) + (50 if headshot else 0)
		score += points
		sound_fx.play("kill", -6.0)
		hud.add_kill("%s  /  %s%s  +%d" % [bot.bot_name, cause, " · HEADSHOT" if headshot else "", points])
	if mode != Mode.WAVES:
		_respawns.append({"index": practice_index, "remaining": 1.0})
	elif bots.is_empty():
		if wave >= WAVE_COUNTS.size():
			_finish(true)
		else:
			_wave_timer = WAVE_BREAK
			hud.notify("WAVE CLEAR  /  Reload and find supplies", WAVE_BREAK)


func _update_practice_respawns(delta: float) -> void:
	for index in range(_respawns.size() - 1, -1, -1):
		_respawns[index]["remaining"] -= delta
		if float(_respawns[index]["remaining"]) <= 0.0:
			var slot: int = _respawns[index]["index"]
			_respawns.remove_at(index)
			_spawn_bot(level.practice_spots[slot], Bot.Type.STANDARD, slot)


func _on_shot_fired() -> void:
	shots += 1


func _on_hit_landed(_target: Node, headshot: bool, _killed: bool) -> void:
	hits += 1
	if headshot:
		headshots += 1
	hud.flash_hit(headshot)


func _on_prompt_changed(text: String) -> void:
	if hud:
		hud.set_prompt(text)


func _on_pickup_collected(pickup: Pickup) -> void:
	hud.notify(pickup.get_label(), 1.5)


func _on_player_damaged(_amount: float, source_position: Vector3) -> void:
	if hud:
		hud.flash_damage(source_position)


func _on_player_died() -> void:
	if state == State.PLAYING:
		_finish(false)


func _finish(won: bool) -> void:
	state = State.COMPLETE if won else State.GAME_OVER
	_respawns.clear()
	_wave_timer = -1.0
	player.input_enabled = false
	player.reloading = false
	player.aiming = false
	for bot in bots:
		bot.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sound_fx.play("win" if won else "lose", -3.0)
	# The lethal ray emits hit statistics after the bot's death signal.
	call_deferred("_show_result")


func _show_result() -> void:
	if state == State.GAME_OVER or state == State.COMPLETE:
		hud.show_result(state == State.COMPLETE)


func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()


func _exit_tree() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _register_input() -> void:
	var keys := {
		"move_forward": [KEY_W], "move_back": [KEY_S],
		"move_left": [KEY_A], "move_right": [KEY_D],
		"jump": [KEY_SPACE], "sprint": [KEY_SHIFT],
		"reload": [KEY_R], "interact": [KEY_E],
		"weapon_1": [KEY_1], "weapon_2": [KEY_2],
		"pause": [KEY_ESCAPE], "restart": [KEY_ENTER],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var buttons := {"shoot": MOUSE_BUTTON_LEFT, "aim": MOUSE_BUTTON_RIGHT, "weapon_next": MOUSE_BUTTON_WHEEL_UP, "weapon_prev": MOUSE_BUTTON_WHEEL_DOWN}
	for action in buttons:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
