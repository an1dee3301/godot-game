class_name RunnerMain
extends Node3D
## Game flow: menu -> run -> game over -> restart. Owns all systems. OWNER: agent C.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var state := State.MENU
var score := 0
var tags := 0
var weight := 0.0
var destination := "LAX"
var routes_ok := 0
var routes_bad := 0
var high_score := 0
var death_cause := ""
var distance := 0.0
var run_time := 0.0
var level := 1

var _score_exact := 0.0
var _last_distance := 0.0
var _game_over_token := 0

var difficulty: Difficulty
var power_ups: PowerUps
var environment: AirportEnvironment
var track: TrackManager
var player: SuitcasePlayer
var camera: FollowCamera
var hud: RunnerHUD
var menus: RunnerMenus
var sfx: SoundFX
var fx: RunnerFX


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	BP.ensure_input_actions()
	difficulty = Difficulty.new()
	environment = AirportEnvironment.new()
	environment.name = "Environment"
	add_child(environment)
	track = TrackManager.new()
	track.name = "Track"
	add_child(track)
	player = SuitcasePlayer.new()
	player.name = "Player"
	add_child(player)
	camera = FollowCamera.new()
	camera.name = "Camera"
	camera.target = player
	add_child(camera)
	fx = RunnerFX.new()
	fx.name = "Effects"
	add_child(fx)
	power_ups = PowerUps.new()
	power_ups.name = "PowerUps"
	add_child(power_ups)
	sfx = SoundFX.new()
	sfx.name = "SoundFX"
	add_child(sfx)
	hud = RunnerHUD.new()
	hud.name = "HUD"
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.flap_sound = sfx.play_flap
	menus = RunnerMenus.new()
	menus.name = "Menus"
	menus.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menus)
	menus.flap_sound = sfx.play_flap
	player.pickup_collected.connect(_on_pickup_collected)
	player.hazard_hit.connect(_on_hazard_hit)
	player.trigger_entered.connect(_on_trigger_entered)
	player.fell.connect(_on_fell)
	player.jumped.connect(func() -> void: sfx.play("jump"))
	player.slid.connect(func() -> void: sfx.play("slide"))
	player.lane_changed.connect(func(_lane: int) -> void: sfx.play("lane"))
	player.jumped.connect(_on_jump_visual)
	player.slid.connect(_on_slide_visual)
	player.lane_changed.connect(_on_lane_visual)
	player.landed.connect(_on_landing_visual)
	power_ups.shield_changed.connect(_on_shield_changed)
	power_ups.boost_changed.connect(_on_boost_changed)
	menus.start_requested.connect(start_run)
	menus.restart_requested.connect(restart)
	menus.resume_requested.connect(toggle_pause)
	menus.menu_requested.connect(go_to_menu)
	menus.quit_requested.connect(func() -> void: get_tree().quit())
	high_score = SaveData.load_high_score()
	player.reset_player()
	track.begin(player, difficulty, randi(), func() -> String: return destination)
	camera.snap_to_target()
	camera.showcase = true
	hud.show_hud(false)
	menus.show_start(high_score)
	sfx.start_music()


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	run_time += delta
	distance = player.distance_travelled()
	difficulty.update(distance, run_time)
	var new_level := difficulty.level()
	if new_level > level:
		level = new_level
		hud.flash_message("LEVEL %d — BELT SPEED UP" % level)
		sfx.play("level_up")
		fx.level_up(player.global_position)
	var speed := difficulty.base_speed() * (1.0 - 0.3 * weight) * power_ups.speed_multiplier()
	player.set_forward_speed(speed)
	_score_exact += maxf(0.0, distance - _last_distance) * power_ups.score_multiplier()
	_last_distance = distance
	score = maxi(0, int(floorf(_score_exact)))
	power_ups.tick(delta)
	hud.update_stats(score, distance, tags, power_ups.score_multiplier(), speed, level)
	hud.set_boost(power_ups.boost_time_left, PowerUps.BOOST_DURATION)
	environment.follow(player.global_position.z)
	environment.set_intensity(difficulty.t())
	camera.set_speed_feel(1.0 if power_ups.is_boosting() else difficulty.t() * 0.5)
	sfx.set_music_intensity(difficulty.t())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if state == State.PLAYING or state == State.PAUSED:
			toggle_pause()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("start") and not event.is_echo():
		if state == State.MENU:
			start_run()
			get_viewport().set_input_as_handled()
		elif state == State.GAME_OVER:
			restart()
			get_viewport().set_input_as_handled()


func start_run() -> void:
	_game_over_token += 1
	get_tree().paused = false
	state = State.MENU
	score = 0
	_score_exact = 0.0
	tags = 0
	weight = 0.0
	distance = 0.0
	_last_distance = 0.0
	run_time = 0.0
	level = 1
	routes_ok = 0
	routes_bad = 0
	death_cause = ""
	destination = _random_destination("")
	difficulty.reset()
	power_ups.reset()
	track.reset_track()
	player.reset_player()
	player.set_weight_visual(0.0)
	player.set_shield_visual(false)
	player.set_boost_visual(false)
	track.begin(player, difficulty, randi(), func() -> String: return destination)
	camera.showcase = false
	camera.snap_to_target()
	camera.fov = 70.0
	player.set_forward_speed(difficulty.base_speed())
	player.start_running()
	menus.hide_all()
	hud.show_hud(true)
	hud.set_destination(destination)
	hud.set_weight(0.0)
	hud.set_shield(false)
	hud.set_boost(0.0, PowerUps.BOOST_DURATION)
	hud.update_stats(0, 0.0, 0, 1.0, difficulty.base_speed(), 1)
	state = State.PLAYING

func end_run(cause: String) -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	death_cause = cause
	player.stop_running()
	player.play_death()
	fx.death(player.global_position)
	camera.shake(0.6, 0.5)
	sfx.play("death")
	var new_best := SaveData.submit_score(score)
	high_score = maxi(high_score, score)
	_game_over_token += 1
	var token := _game_over_token
	await get_tree().create_timer(1.0).timeout
	if token != _game_over_token or state != State.GAME_OVER:
		return
	menus.show_game_over({
		"score": score, "distance": distance, "tags": tags,
		"best": high_score, "new_best": new_best, "cause": death_cause,
		"level": level, "routes_ok": routes_ok, "routes_bad": routes_bad,
	})

func restart() -> void:
	start_run()

func toggle_pause() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		menus.show_pause()
	elif state == State.PAUSED:
		get_tree().paused = false
		state = State.PLAYING
		menus.hide_all()

func go_to_menu() -> void:
	_game_over_token += 1
	get_tree().paused = false
	state = State.MENU
	player.stop_running()
	power_ups.reset()
	difficulty.reset()
	track.reset_track()
	player.reset_player()
	track.begin(player, difficulty, randi(), func() -> String: return destination)
	camera.snap_to_target()
	camera.showcase = true
	environment.follow(0.0)
	environment.set_intensity(0.0)
	hud.show_hud(false)
	menus.show_start(high_score)


func _on_pickup_collected(pickup: Pickup) -> void:
	if state != State.PLAYING or pickup.collected or pickup.get_meta("_claimed", false):
		return
	pickup.set_meta("_claimed", true)
	pickup.call_deferred("collect")
	fx.pickup(pickup.global_position, pickup.type)
	_score_exact += pickup.value() * power_ups.score_multiplier()
	score = maxi(0, int(floorf(_score_exact)))
	weight = clampf(weight + pickup.weight(), 0.0, 1.0)
	player.set_weight_visual(weight)
	hud.set_weight(weight)
	match pickup.type:
		Pickup.Type.TAG:
			tags += 1
			sfx.play("tag")
		Pickup.Type.PASSPORT:
			sfx.play("passport")
		Pickup.Type.PRIORITY:
			power_ups.give_boost()
			hud.flash_message("PRIORITY BOOST x2!", Color(1.0, 0.83, 0.22))
			sfx.play("boost")
		Pickup.Type.FRAGILE:
			power_ups.give_shield()
			hud.flash_message("FRAGILE SHIELD!", Color(0.38, 0.9, 1.0))
			sfx.play("shield_get")


func _on_hazard_hit(hazard: Hazard) -> void:
	if state != State.PLAYING or hazard.get_meta("_absorbed", false):
		return
	if power_ups.consume_shield():
		hazard.set_meta("_absorbed", true)
		hazard.call_deferred("disable")
		player.play_hit()
		camera.shake(0.4, 0.3)
		sfx.play("shield_break")
		fx.shield_break(player.global_position)
		hud.flash_message("SHIELD BROKEN", Color(1.0, 0.35, 0.3))
	else:
		end_run("Hit a " + hazard.display_name)


func _on_fell() -> void:
	end_run("Fell through broken rollers")


func _on_trigger_entered(trigger: TrackTrigger) -> void:
	if state != State.PLAYING or trigger.fired:
		return
	trigger.fired = true
	match trigger.kind:
		"checkpoint":
			var bonus := roundi(weight * 500.0)
			_score_exact += bonus
			score = maxi(0, int(floorf(_score_exact)))
			weight = 0.0
			player.set_weight_visual(weight)
			hud.set_weight(weight)
			hud.flash_message("CHECKPOINT +%d — WEIGHT CLEARED" % bonus)
			sfx.play("checkpoint")
			fx.checkpoint(player.global_position)
		"route":
			if str(trigger.data.get("code", "")) == destination:
				routes_ok += 1
				_score_exact += 150.0
				hud.flash_message("ON ROUTE +150", Color(0.45, 1.0, 0.58))
				sfx.play("route_ok")
				fx.route(player.global_position, true)
			else:
				routes_bad += 1
				_score_exact = floorf(_score_exact * 0.9)
				weight = clampf(weight + 0.25, 0.0, 1.0)
				player.set_weight_visual(weight)
				hud.set_weight(weight)
				hud.flash_message("MISROUTED", Color(1.0, 0.42, 0.32))
				sfx.play("route_bad")
				fx.route(player.global_position, false)
			score = maxi(0, int(floorf(_score_exact)))
			destination = _random_destination(destination)
			hud.set_destination(destination)


func _on_shield_changed(active: bool) -> void:
	player.set_shield_visual(active)
	hud.set_shield(active)


func _on_boost_changed(active: bool) -> void:
	player.set_boost_visual(active)
	hud.set_boost(power_ups.boost_time_left, PowerUps.BOOST_DURATION)


func _random_destination(exclude: String) -> String:
	var candidate := exclude
	while candidate == exclude:
		candidate = BP.DESTINATIONS[randi_range(0, BP.DESTINATIONS.size() - 1)]
	return candidate


func _on_jump_visual() -> void:
	fx.burst(player.global_position + Vector3.UP * 0.2, Color("a4f5ff"), 16, 2.8)


func _on_slide_visual() -> void:
	fx.burst(player.global_position + Vector3.UP * 0.1, Color("ffc36f"), 15, 2.5)


func _on_lane_visual(new_lane: int) -> void:
	fx.burst(player.global_position + Vector3.UP * 0.3, Color("72e9ff"), 12, 2.4)
	camera.lane_nudge(1 if BP.lane_x(new_lane) > player.global_position.x else -1)


func _on_landing_visual() -> void:
	fx.burst(player.global_position + Vector3.UP * 0.1, Color("c8eaf1"), 18, 2.5)
	camera.land_bump()
