extends Node3D
## One shared board, one fixed camera, offline couch play or authoritative ENet rooms.
const ArenaScript = preload("res://scripts/arena.gd")
const HudScript = preload("res://scripts/hud.gd")
const SoundScript = preload("res://scripts/sound_fx.gd")
const NetworkScript = preload("res://scripts/network_session.gd")
const FeedbackScript = preload("res://scripts/party_feedback.gd")

var arena: Node3D
var hud: CanvasLayer
var sfx: Node
var camera: Camera3D
var rounds: Node
var network: Node
var feedback: Node3D
var paused: bool = false
var camera_home: Vector3 = Vector3(0,16,24)
var _countdown_number: int = 0
var _score_memory: Dictionary = {}
var shake_enabled: bool = true
var _shake: float = 0.0
var _shake_clock: float = 0.0
var _view_offset: Vector2 = Vector2(0.0,0.5)
var _view_size: float = 17.0
var _drumroll_started: bool = false
var _last_kick: Vector2 = Vector2.ZERO
var _heights: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	arena = ArenaScript.new()
	arena.name = "PartyShowground"
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(arena)
	camera = Camera3D.new()
	camera.name = "SharedPartyCamera"
	camera.position = camera_home
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 17.0
	camera.fov = 40.0
	camera.far = 180.0
	camera.near = 0.2
	add_child(camera)
	camera.look_at(Vector3(0,0,-0.6))
	camera.current = true
	camera.v_offset = 0.5
	feedback = FeedbackScript.new()
	feedback.name = "PartyFeedback"
	feedback.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(feedback)
	sfx = SoundScript.new()
	sfx.name = "PartySound"
	sfx.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(sfx)
	hud = HudScript.new()
	hud.name = "PartyInterface"
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	rounds = $RoundManager
	rounds.process_mode = Node.PROCESS_MODE_PAUSABLE
	rounds.configure(arena,hud,sfx)
	rounds.state_changed.connect(_present_phase)
	for actor in rounds.contestants:
		actor.feedback_requested.connect(_actor_feedback)
		_score_memory[actor.contestant_id] = actor.score
	network = NetworkScript.new()
	network.name = "NetworkSession"
	add_child(network)
	network.configure(rounds,hud)
	hud.start_requested.connect(_start)
	hud.restart_requested.connect(_restart)
	hud.quit_to_menu_requested.connect(_menu)
	hud.mute_requested.connect(_toggle_mute)
	hud.ui_sound_requested.connect(sfx.play)
	hud.pause_requested.connect(_toggle_pause)
	hud.shake_toggled.connect(func(enabled: bool) -> void: shake_enabled = enabled)
	hud.help_overlay.visibility_changed.connect(_help_visibility_changed)
	if hud.has_signal("host_requested"): hud.host_requested.connect(_host_room)
	if hud.has_signal("join_requested"): hud.join_requested.connect(_join_room)
	if hud.has_signal("ready_requested"): hud.ready_requested.connect(network.set_ready)
	if hud.has_signal("network_start_requested"): hud.network_start_requested.connect(network.start_match)
	if hud.has_signal("leave_room_requested"): hud.leave_room_requested.connect(_menu)
	network.lobby_changed.connect(_on_lobby_changed)
	network.status_changed.connect(_on_network_status)
	network.match_started.connect(_on_network_match_started)
	network.session_closed.connect(_on_session_closed)
	Input.joy_connection_changed.connect(_gamepad_connection_changed)
	_showcase_cast(true)
	if "--autostart" in OS.get_cmdline_user_args(): _start(1)

func _process(_delta: float) -> void:
	if not is_instance_valid(rounds): return
	if hud.has_method("set_local_player"): hud.set_local_player(rounds.local_contestant_index)
	var count: int = ceili(rounds.time_left) if rounds.state == rounds.State.INTRO and rounds.time_left <= 3.0 else 0
	hud.show_countdown(count)
	if count > 0 and count != _countdown_number: sfx.play("ready")
	_countdown_number = count
	if arena.has_method("set_pressure"):
		arena.set_pressure(clampf((3.0-rounds.time_left)/3.0,0.0,1.0) if rounds.state == rounds.State.QUESTION else 0.0)
	var closing: bool = rounds.state == rounds.State.QUESTION and rounds.time_left <= 2.4
	if closing and not _drumroll_started: sfx.play("drumroll")
	_drumroll_started = closing
	_update_camera(_delta)
	_watch_splashes()

func _watch_splashes() -> void:
	# Whoever drops through a trapdoor lands in the slop below.
	for actor in rounds.contestants:
		var height: float = actor.global_position.y
		var before: float = float(_heights.get(actor.contestant_id,height))
		_heights[actor.contestant_id] = height
		if before > -5.2 and height <= -5.2 and rounds.state != rounds.State.MENU and absf(actor.global_position.x) < 7.2 and absf(actor.global_position.z) < 7.2:
			arena.stage_show.splash(actor.global_position,Color("c9a4ff"))
			sfx.play("splash")
			add_shake(0.28)

func _update_camera(delta: float) -> void:
	# The shared camera never moves: framing eases through lens offsets, and impact
	# shake is a few centimetres of the same offsets. Its transform stays fixed.
	var blend: float = 1.0 - exp(-delta * 5.0)
	camera.size = lerpf(camera.size,_view_size,blend)
	_shake = maxf(0.0,_shake - delta * 2.6)
	_shake_clock += delta
	var kick: Vector2 = Vector2.ZERO
	if shake_enabled and _shake > 0.0 and not get_tree().paused:
		var power: float = _shake * _shake * 0.34
		kick = Vector2(sin(_shake_clock * 71.0) + sin(_shake_clock * 43.0),cos(_shake_clock * 59.0) + sin(_shake_clock * 37.0)) * power * 0.5
	camera.h_offset = lerpf(camera.h_offset - _last_kick.x,_view_offset.x,blend) + kick.x
	camera.v_offset = lerpf(camera.v_offset - _last_kick.y,_view_offset.y,blend) + kick.y
	_last_kick = kick

func add_shake(amount: float) -> void:
	_shake = clampf(maxf(_shake,amount),0.0,1.0)

func _showcase_cast(enabled: bool) -> void:
	# The title screen presents the four authored mascots as a cast, on the set.
	for i in rounds.contestants.size():
		var actor: RigidBody3D = rounds.contestants[i]
		actor.set_showcase(enabled)
		actor.visible = not enabled or i < 4
		if enabled:
			actor.controls_enabled = false
			actor.bot_moving = false
			actor.freeze = true
			actor.collision_mask = 0
			actor.linear_velocity = Vector3.ZERO
			actor.angular_velocity = Vector3.ZERO
			actor._teleport_pending = false
			actor.position = Vector3(2.0 + (i % 2) * 3.2,1.35,-0.2 + (i / 2) * 4.4)
			actor.rotation = Vector3.ZERO
			actor.scale = Vector3.ONE * 1.5
		else:
			actor.scale = Vector3.ONE
			actor.freeze = actor.network_replica
			actor.collision_mask = 0 if actor.network_replica else 7

func _present_phase(phase: int) -> void:
	if hud.has_method("set_local_player"): hud.set_local_player(rounds.local_contestant_index)
	match phase:
		rounds.State.MENU:
			arena.quiz_screen.show_title()
			arena.stage_show.set_mode("idle")
		rounds.State.INTRO:
			_frame_camera(false)
			_showcase_cast(false)
			feedback.clear()
			arena.stage_show.set_mode("intro")
			arena.stage_show.cheer(0.8)
			sfx.set_round(rounds.round_index)
			sfx.play("cheer")
			if camera.size < 20.5: camera.size = 21.4
			for actor in rounds.contestants: _score_memory[actor.contestant_id] = actor.score
			arena.quiz_screen.show_round(rounds.round_index + 1,rounds.ROUNDS[rounds.round_index].title,rounds.ROUNDS[rounds.round_index].rule)
		rounds.State.QUESTION:
			sfx.play("go")
			arena.stage_show.set_mode("question")
			arena.quiz_screen.show_question(str(rounds.current_question.get("prompt","")),rounds.current_question.get("answers",[]))
		rounds.State.REVEAL:
			add_shake(0.75)
			var survivors: int = 0
			for actor in rounds.contestants:
				if actor.active: survivors += 1
			sfx.play("reveal")
			sfx.play("cheer" if survivors > 0 else "aww")
			arena.stage_show.cheer(1.2 if survivors > 0 else 0.5)
			if rounds.current_question.has("correct"):
				var correct: int = int(rounds.current_question.correct)
				arena.quiz_screen.reveal(correct,str(rounds.current_question.answers[correct]))
				arena.stage_show.set_mode("reveal",arena.tile_centers[correct],arena.COLORS[correct])
				if survivors > 0: arena.stage_show.cannons(arena.COLORS[correct])
			for actor in rounds.contestants:
				var points: int = actor.score - int(_score_memory.get(actor.contestant_id,actor.score))
				if points != 0:
					feedback.popup_score(actor.global_position,points,actor.tint)
					actor.notify_scored(points)
				if not actor.active and not actor.spectator: actor.notify_eliminated()
				_score_memory[actor.contestant_id] = actor.score
		rounds.State.GACHA:
			arena.quiz_screen.show_intermission()
			arena.stage_show.set_mode("gacha")
			var entries: Array = []
			for actor in rounds.contestants:
				if not actor.perk.is_empty():
					entries.append({"id":actor.contestant_id,"name":actor.display_name,"perk":actor.perk,"tint":actor.tint})
			hud.update_gacha_entries(entries)
		rounds.State.RESULTS:
			arena.stage_show.set_mode("results")
			arena.stage_show.cheer(1.3)
			sfx.play("fanfare")
			sfx.play("cheer")
			add_shake(0.5)
			var best: int = 0
			for actor in rounds.contestants: best = maxi(best,actor.score)
			for actor in rounds.contestants:
				if actor.score == best: actor.celebrate(30.0)
			for actor in rounds.contestants:
				if actor.score == best:
					arena.quiz_screen.show_winner(actor.display_name.replace(" · YOU",""))
					break

func _actor_feedback(actor: RigidBody3D, event: String, intensity: float) -> void:
	if rounds.state == rounds.State.MENU: return
	feedback.emit_event(actor.global_position,actor.tint,event,intensity)
	# Existing action cues belong to RoundManager; these contact cues are local.
	if event == "land" and intensity > 0.7: sfx.play("land")
	elif event == "jump": sfx.play("jump")
	elif event == "hit" and intensity > 0.8:
		sfx.play("hit")
		add_shake(0.22 + intensity * 0.16)
		arena.stage_show.cheer(0.55)


func _start(humans: int) -> void:
	if network.active: network.close_session()
	_set_paused(false)
	_frame_camera(false)
	if hud.has_method("set_network_role"): hud.set_network_role(false,false)
	rounds.start_match(humans)
	var player_name: String = hud._name_input.text.strip_edges().left(18)
	if not player_name.is_empty():
		var actor: RigidBody3D = rounds.contestants[0]
		actor.setup(0,"%s · YOU" % player_name,actor.tint,0)
		hud.update_scores(rounds.contestants)

func _restart() -> void:
	_set_paused(false)
	if network.active:
		network.restart_match()
	else:
		_start(rounds.human_count)

func _menu() -> void:
	_set_paused(false)
	if network.active: network.close_session()
	rounds.return_to_menu()
	arena.quiz_screen.show_title()
	_showcase_cast(true)
	if hud.has_method("set_network_role"): hud.set_network_role(false,false)
	_frame_camera(true)

func _frame_camera(menu_view: bool) -> void:
	# Every participant receives the same stage framing; no local follow cameras.
	_view_size = 17.0 if menu_view else 19.5
	_view_offset = Vector2(0.0,0.5 if menu_view else 4.35)

func _host_room(player_name: String, port: int = 24816) -> void:
	_set_paused(false)
	var error: Error = network.host_room(player_name,port)
	if error != OK and hud.has_method("show_connection_error"):
		hud.show_connection_error("Could not open this room. Check the port and try again.")

func _join_room(address: String, player_name: String, port: int = 24816) -> void:
	_set_paused(false)
	var error: Error = network.join_room(address,player_name,port)
	if error == OK:
		if hud.has_method("show_lobby"): hud.show_lobby([],false,"Connecting to the host…")
	elif hud.has_method("show_connection_error"):
		hud.show_connection_error("Could not connect. Enter the host's IP address and port.")

func _on_lobby_changed(players: Array, hosting: bool) -> void:
	if hud.has_method("set_network_role"): hud.set_network_role(true,hosting)
	if hud.has_method("show_lobby"): hud.show_lobby(players,hosting,str(network.get("_status")))
	_frame_camera(false)

func _on_network_status(message: String) -> void:
	if hud.has_method("set_network_status"): hud.set_network_status(message)

func _on_network_match_started() -> void:
	_set_paused(false)
	if hud.has_method("set_network_role"): hud.set_network_role(true,network.is_host)
	hud.show_game()
	_frame_camera(false)

func _on_session_closed(reason: String) -> void:
	paused = false
	get_tree().paused = false
	hud.show_pause(false)
	if hud.has_method("set_network_role"): hud.set_network_role(false,false)
	if not reason.is_empty() and hud.has_method("show_connection_error"):
		hud.show_connection_error(reason)
	_frame_camera(true)
	_showcase_cast(true)

func _unhandled_input(event: InputEvent) -> void:
	var pause_key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P)
	var pause_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if pause_key or pause_pad:
		if hud.help_overlay.visible: hud.help_overlay.hide()
		else: _toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		_toggle_mute()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if rounds.state == rounds.State.MENU or rounds.state == rounds.State.RESULTS: return
	_set_paused(not paused)

func _set_paused(value: bool) -> void:
	paused = value
	var online: bool = is_instance_valid(network) and network.active
	get_tree().paused = value and not online
	if online:
		network.input_blocked = value
		for actor in rounds.contestants:
			if actor.network_local: actor.local_input_blocked = value
	if is_instance_valid(hud): hud.show_pause(value)

func _help_visibility_changed() -> void:
	if rounds.state == rounds.State.MENU or rounds.state == rounds.State.RESULTS: return
	var online: bool = is_instance_valid(network) and network.active
	var blocked: bool = hud.help_overlay.visible or hud.pause_overlay.visible
	paused = blocked
	get_tree().paused = blocked and not online
	if online:
		network.input_blocked = blocked
		for actor in rounds.contestants:
			if actor.network_local: actor.local_input_blocked = blocked

func _gamepad_connection_changed(_device: int, _connected: bool) -> void:
	if rounds.state != rounds.State.MENU: rounds._configure_gamepads()

func _toggle_mute() -> void:
	sfx.toggle_mute()
	hud.set_muted(sfx.muted)
