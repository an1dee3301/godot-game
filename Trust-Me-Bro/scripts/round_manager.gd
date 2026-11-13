extends Node
## The only owner of match state. The same quiz mutates one reusable stage.
signal state_changed(new_state: int)
signal question_started(round_index: int, question_index: int)
signal match_finished

enum State { MENU, INTRO, QUESTION, REVEAL, GACHA, RESULTS }

@export_group("Live demo · pacing")
@export_range(1, 5, 1) var questions_per_round: int = 2
@export var question_seconds: float = 12.0
@export var finale_seconds: float = 5.0
@export var introduction_seconds: float = 7.0
@export var reveal_seconds: float = 3.8
@export var gacha_seconds: float = 5.0
@export_group("Live demo · chaos")
@export var shove_force: float = 8.5
@export var ice_friction: float = 0.04
@export var sweeper_force: float = 7.0
@export var conveyor_strength: float = 3.0
@export_range(0.0, 0.2, 0.005) var safe_zone_shrink_rate: float = 0.016
@export var bot_accuracy: float = 0.7
const CONTESTANT_COUNT: int = 8

const ContestantScript = preload("res://scripts/contestant.gd")
const CubeScript = preload("res://scripts/answer_cube.gd")
const QuizBank = preload("res://scripts/quiz_bank.gd")
const COLORS: Array[Color] = [Color("ff6b61"), Color("6daaff"), Color("87eed0"), Color("ffe17c"), Color("be9bff"), Color("ff9ed1"), Color("fca66c"), Color("a4d8f0")]
const NAMES: Array[String] = ["YOU", "BIG BRAIN", "NO THOUGHTS", "TRUST ISSUES", "CHAOS GREMLIN", "PROBABLY RIGHT", "THE INTERN", "BAD INFLUENCE"]
const ROUNDS: Array[Dictionary] = [
	{"title": "CROWD CONTROL", "rule": "Stand on the right answer. Crowded pads shrink. Make room. Aggressively."},
	{"title": "LIGHTS OUT", "rule": "Memorize A / B / C / D. Three seconds of light, then trust your torch."},
	{"title": "GRAB A BRAIN", "rule": "The floor stays! Grab a cube with the right letter. E / O / Y to grab or steal."},
	{"title": "SLIP & PANIC", "rule": "Same quiz. Zero grip. Jump the sweeper, or become a bowling ball."},
	{"title": "FINAL ANSWER", "rule": "Five seconds. Belts pull inward. Pads get smaller after every question."}
]

var network_session: Node = null
var client_mode: bool = false
var local_contestant_index: int = 0
var network_roster: Array = []
var _network_props: Dictionary = {}
var _network_clouds: Dictionary = {}
var _network_banner: Dictionary = {"visible": false, "title": "", "subtitle": "", "color": Color.WHITE}
var _network_flash: Dictionary = {"serial": 0, "text": "", "color": Color.WHITE}
var _network_last_flash: int = 0
var _network_question_key: String = ""
var _network_banner_key: String = ""
var _network_private_hint: int = -1
var _network_results_shown: bool = false
var _network_audio_tick: int = -1

var state: State = State.MENU
var arena: Node3D
var hud: CanvasLayer
var sfx: Node
var contestants: Array = []
var cubes: Array = []
var junk: Array = []
var deck: Array[Dictionary] = []
var current_question: Dictionary = {}
var round_index: int = 0
var question_index: int = 0
var deck_cursor: int = 0
var time_left: float = 0.0
var question_duration: float = 12.0
var elapsed: float = 0.0
var human_count: int = 1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pad_scales: Array[float] = [1.0, 1.0, 1.0, 1.0]
var bot_choices: Dictionary = {}
var bot_offsets: Dictionary = {}
var pending_respawns: Array[Dictionary] = []
var round_scores: Dictionary = {}
var crown: Node3D = null
var crown_spawned: bool = false
var swapped: bool = false
var last_tick: int = -1
var ai_timer: float = 0.0
var sweep_cooldowns: Dictionary = {}
var nerd_id: int = -1
var toast_timer: float = 0.0
var global_clock: float = 0.0
var gacha_summary: String = ""

func configure(stage: Node3D, interface_layer: CanvasLayer, audio: Node) -> void:
	arena = stage
	hud = interface_layer
	sfx = audio
	rng.randomize()
	deck = QuizBank.make_deck(rng)
	for i in CONTESTANT_COUNT:
		var actor: RigidBody3D = ContestantScript.new()
		actor.setup(i, NAMES[i % NAMES.size()], COLORS[i % COLORS.size()], -1)
		arena.add_child(actor)
		contestants.append(actor)
		actor.action_requested.connect(_on_action)
		actor.fell.connect(_on_fell)
		actor.respawn(_spawn_position(i), false)
		actor.controls_enabled = true
		actor.bot_target = arena.tile_centers[i % 4]
		actor.bot_moving = true
	hud.show_menu()

func start_match(humans: int = 1) -> void:
	client_mode = false
	local_contestant_index = 0
	network_roster.clear()
	_network_results_shown = false
	_network_audio_tick = -1
	_network_flash = {"serial":0,"text":"","color":Color.WHITE}
	for actor in contestants:
		if actor.has_method("configure_network"): actor.configure_network(0,0,false)
	arena.set_physics_process(true)
	human_count = clampi(humans, 1, 4)
	pending_respawns.clear()
	_clear_props()
	deck = QuizBank.make_deck(rng)
	deck_cursor = 0
	nerd_id = -1
	round_index = 0
	question_index = 0
	for i in contestants.size():
		var actor: RigidBody3D = contestants[i]
		actor.score = 0
		actor.set_perk("")
		actor.shove_cooldown = 0.0
		actor.human_slot = i if i < human_count else -1
		actor.is_bot = i >= human_count
		actor.display_name = ("P%d · YOU" % (i + 1)) if i < human_count else NAMES[i]
		actor.setup(i, actor.display_name, COLORS[i], actor.human_slot)
	_configure_gamepads()
	hud.show_game()
	sfx.playing = true
	sfx.play("start")
	_begin_round()

func return_to_menu() -> void:
	client_mode = false
	local_contestant_index = 0
	network_roster.clear()
	_network_question_key = ""
	_network_banner_key = ""
	_network_results_shown = false
	for actor in contestants:
		if actor.has_method("configure_network"): actor.configure_network(0,0,false)
	arena.set_physics_process(true)
	_change_state(State.MENU, 0.0)
	_clear_props()
	pending_respawns.clear()
	arena.reset_round(0)
	sfx.urgent = false
	sfx.playing = false
	for i in contestants.size():
		var actor: RigidBody3D = contestants[i]
		actor.is_bot = true
		actor.set_perk("")
		actor.ice = false
		actor.conveyor = false
		actor.flashlight.visible = false
		actor.has_crown = false
		actor.respawn(_spawn_position(i), false)
		actor.controls_enabled = true
		actor.bot_target = arena.tile_centers[i % 4]
		actor.bot_moving = true
	hud.show_menu()

func _change_state(next: State, duration: float) -> void:
	state = next
	time_left = duration
	elapsed = 0.0
	state_changed.emit(state)

func _begin_round() -> void:
	_clear_props()
	pending_respawns.clear()
	arena.reset_round(round_index)
	arena.set_friction(ice_friction if round_index == 3 else 0.8)
	arena.set_sweeper(round_index == 3)
	arena.set_conveyor(round_index == 4)
	pad_scales = [1.0, 1.0, 1.0, 1.0]
	question_index = 0
	for i in contestants.size():
		var actor: RigidBody3D = contestants[i]
		actor.has_crown = false
		actor.respawn(_spawn_position(i), false)
		actor.controls_enabled = false
		actor.flashlight.visible = false
		actor.ice = round_index == 3
		actor.conveyor = round_index == 4
		if actor.physics_material_override:
			actor.physics_material_override.friction = ice_friction if actor.ice else 0.65
		round_scores[actor.contestant_id] = 0
	hud.update_round(round_index, ROUNDS[round_index].title, ROUNDS[round_index].rule)
	hud.update_scores(contestants)
	hud.set_spectator(false)
	hud.set_status("EVERYONE IS BACK. TRUST NO ONE.")
	hud.set_perk(_human_perk_text())
	_show_banner("ROUND %02d  /  %s" % [round_index + 1, ROUNDS[round_index].title], ROUNDS[round_index].rule, COLORS[round_index % 4])
	_change_state(State.INTRO, introduction_seconds)

func _begin_question() -> void:
	_clear_props()
	arena.restore_tiles()
	arena.set_labels_visible(true)
	arena.set_blackout(false)
	for actor in contestants: actor.flashlight.visible = false
	if round_index == 4:
		arena.set_finale_step(question_index + 1)
	elif round_index == 0:
		pad_scales = [1.0, 1.0, 1.0, 1.0]
		for i in 4: arena.set_tile_scale(i, 1.0)
	current_question = deck[deck_cursor % deck.size()]
	deck_cursor += 1
	question_duration = finale_seconds if round_index == 4 else question_seconds
	if round_index == 2: question_duration += 2.0
	crown_spawned = false
	swapped = false
	last_tick = -1
	bot_choices.clear()
	bot_offsets.clear()
	sweep_cooldowns.clear()
	for actor in contestants:
		actor.controls_enabled = true
		actor.bot_moving = actor.active
		var knows: bool = rng.randf() < bot_accuracy or actor.perk == "nerd"
		bot_choices[actor.contestant_id] = int(current_question.correct) if knows else rng.randi_range(0,3)
		bot_offsets[actor.contestant_id] = Vector3(rng.randf_range(-1.7,1.7),0,rng.randf_range(-1.7,1.7))
		if actor.active and arena.get_tile_at(actor.global_position) < 0:
			actor.respawn(_spawn_position(actor.contestant_id), false)
	if round_index == 2: _spawn_answer_cubes()
	_hide_banner()
	hud.update_question(current_question.prompt, current_question.answers, question_index + 1, questions_per_round)
	_update_question_metadata(false)
	hud.set_status("GRAB THE RIGHT CUBE · E / O / Y" if round_index == 2 else "STAND ON YOUR ANSWER BEFORE THE BUZZER")
	hud.set_perk(_human_perk_text())
	_change_state(State.QUESTION, question_duration)
	question_started.emit(round_index, question_index)

func _physics_process(delta: float) -> void:
	if client_mode: return
	if not is_instance_valid(arena): return
	global_clock += delta
	_update_respawns(delta)
	if state == State.MENU:
		_menu_bots(delta)
		return
	if state == State.RESULTS: return
	time_left = maxf(0.0, time_left - delta)
	elapsed += delta
	if state == State.QUESTION:
		hud.update_timer(time_left, question_duration)
		_update_question(delta)
		if time_left <= 0.0: _reveal()
	elif time_left <= 0.0:
		match state:
			State.INTRO: _begin_question()
			State.REVEAL: _after_reveal()
			State.GACHA: _begin_round()
	if is_instance_valid(crown):
		crown.rotation.y += delta * 1.8
		crown.position.y = 1.6 + sin(global_clock * 3.0) * 0.16

func _update_question(delta: float) -> void:
	if round_index == 1 and elapsed >= 3.0 and not arena.blackout:
		arena.set_blackout(true)
		for actor in contestants: actor.flashlight.visible = actor.active
		arena.set_labels_visible(false)
		_flash_message("LIGHTS OUT. HOPE YOU REMEMBERED.", COLORS[1])
	if round_index == 0:
		var counts: Array[int] = [0,0,0,0]
		for actor in contestants:
			if not actor.active or actor.global_position.y > 1.3: continue
			var tile: int = arena.get_tile_at(actor.global_position)
			if tile >= 0: counts[tile] += 1
		for i in 4:
			pad_scales[i] = maxf(0.46, pad_scales[i] - counts[i] * safe_zone_shrink_rate * delta)
			arena.set_tile_scale(i, pad_scales[i])
	if round_index == 3: _update_sweeper(delta)
	if round_index == 4:
		for actor in contestants:
			if not actor.active: continue
			var pull: Vector3 = -actor.global_position
			pull.y = 0.0
			actor.apply_central_force(pull.normalized() * conveyor_strength * actor.mass)
	if elapsed > question_duration * 0.45 and not crown_spawned:
		_spawn_crown()
	if is_instance_valid(crown):
		for actor in contestants:
			if actor.active and actor.global_position.distance_to(crown.global_position) < 1.45:
				actor.has_crown = true
				crown.queue_free()
				crown = null
				sfx.play("grab")
				_flash_message("%s TOOK THE CURSED CROWN · DOUBLE OR NOTHING" % actor.display_name, COLORS[3])
				break
	if time_left <= 1.0 and not swapped:
		swapped = true
		_execute_swappers()
	var tick: int = int(ceil(time_left))
	if tick <= 5 and tick != last_tick:
		last_tick = tick
		sfx.play("tick")
	sfx.urgent = time_left < 4.0
	ai_timer -= delta
	if ai_timer <= 0.0:
		ai_timer = 0.25
		_update_bots()
	if Input.is_key_pressed(KEY_TAB) or _any_peek_button():
		for actor in contestants:
			if not actor.is_bot and actor.perk == "nerd" and actor.active and (network_session == null or not network_session.active or actor.contestant_id == local_contestant_index):
				hud.set_perk("P%d SECRET: %s IS CORRECT. DON'T TELL THEM." % [actor.human_slot + 1, "ABCD"[int(current_question.correct)]])
	else:
		hud.set_perk(_human_perk_text())

func _reveal() -> void:
	sfx.urgent = false
	arena.set_blackout(false)
	for actor in contestants: actor.flashlight.visible = false
	arena.set_labels_visible(true)
	var correct: int = int(current_question.correct)
	if round_index != 2: arena.open_wrong_tiles(correct)
	arena.set_answer_highlight(correct)
	_update_question_metadata(true)
	hud.reveal_answer(correct)
	var survivors: int = 0
	for actor in contestants:
		if not actor.active: continue
		var qualified: bool = false
		if round_index == 2:
			qualified = is_instance_valid(actor.held_cube) and actor.held_cube.answer_index == correct and actor.global_position.y > -0.2
		else:
			qualified = arena.get_tile_at(actor.global_position) == correct and actor.global_position.y > -0.2
		if qualified:
			survivors += 1
			var points: int = (100 + round_index * 25) * (2 if actor.has_crown else 1)
			actor.score += points
			round_scores[actor.contestant_id] = int(round_scores.get(actor.contestant_id, 0)) + points
			actor.bot_moving = false
			arena.spawn_confetti(actor.global_position + Vector3.UP, actor.tint)
		else:
			_eliminate(actor)
	var answer: String = str(current_question.answers[correct])
	var explanation: String = str(current_question.get("explanation",""))
	var reveal_note: String = explanation if not explanation.is_empty() else ("Friendship is temporary. Points are forever." if survivors > 0 else "Nobody knew. Everybody suffered.")
	_show_banner("%s  ·  %s" % ["ABCD"[correct], answer.to_upper()], "%d STILL STANDING. %s" % [survivors,reveal_note], COLORS[correct])
	hud.update_scores(contestants)
	hud.set_status(explanation if not explanation.is_empty() else "CORRECT ANSWER: %s  ·  %s" % ["ABCD"[correct],answer])
	sfx.play("correct" if contestants[local_contestant_index].active else "wrong")
	_change_state(State.REVEAL, reveal_seconds)

func _after_reveal() -> void:
	question_index += 1
	var alive: int = 0
	for actor in contestants:
		if actor.active: alive += 1
	if question_index < questions_per_round and alive > 0 and not (round_index == 2 and alive <= 1):
		_begin_question()
		return
	if round_index >= 4:
		_finish_match()
		return
	round_index += 1
	_roll_gacha()

func _roll_gacha() -> void:
	hud.set_question_visible(false)
	_clear_props()
	arena.restore_tiles()
	for actor in contestants:
		actor.controls_enabled = false
		actor.bot_moving = false
		actor.set_perk("")
	var shuffled: Array = contestants.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi_range(0,i)
		var saved: Variant = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = saved
	nerd_id = shuffled[0].contestant_id
	shuffled[0].set_perk("nerd")
	shuffled[1].set_perk("heavy")
	shuffled[2].set_perk("pinball")
	var trailing: Array = contestants.duplicate()
	trailing.sort_custom(func(a: Variant, b: Variant) -> bool: return a.score < b.score)
	# The trailing eligible contestant gets an automatic last-second rescue.
	for actor in trailing:
		if actor.perk == "":
			actor.set_perk("swapper")
			break
	gacha_summary = "%s: NERD GLASSES\n%s: HEAVY BOOTS    /    %s: PINBALL CURSE\nThe lowest eligible score gets a last-second swap." % [shuffled[0].display_name, shuffled[1].display_name, shuffled[2].display_name]
	_show_banner("LUCKY SLOP!", gacha_summary, COLORS[3])
	hud.set_perk(_human_perk_text())
	sfx.play("gacha")
	_change_state(State.GACHA, gacha_seconds)

func _finish_match() -> void:
	_change_state(State.RESULTS, 0.0)
	for actor in contestants:
		actor.controls_enabled = false
		actor.bot_moving = false
	arena.set_blackout(false)
	for actor in contestants: actor.flashlight.visible = false
	arena.set_sweeper(false)
	arena.set_conveyor(false)
	sfx.play("start")
	_hide_banner()
	hud.show_results(contestants)
	for i in 12:
		arena.spawn_confetti(Vector3(rng.randf_range(-6,6),3,rng.randf_range(-6,6)),COLORS[i % COLORS.size()])
	match_finished.emit()

func _eliminate(actor: RigidBody3D) -> void:
	if not actor.active: return
	actor.active = false
	actor.controls_enabled = false
	actor.bot_moving = false
	if is_instance_valid(actor.held_cube): actor.held_cube.drop(Vector3(0,3,0))
	if actor.has_crown:
		actor.score = 0
		actor.has_crown = false
		_flash_message("THE CROWN CLAIMED %s'S ENTIRE SCORE." % actor.display_name, COLORS[0])
	actor.apply_central_impulse(Vector3(rng.randf_range(-1.0,1.0),-2.0,rng.randf_range(-1.0,1.0)))
	pending_respawns.append({"actor": actor, "time": 1.1})
	if not actor.is_bot:
		sfx.play("fall")
		hud.set_status("BALCONY REVENGE · SHOVE TO TOSS JUNK. BACK NEXT ROUND.")
		if actor.contestant_id == local_contestant_index: hud.set_spectator(true)

func _on_fell(actor: RigidBody3D) -> void:
	if client_mode: return
	if state == State.MENU:
		actor.respawn(_spawn_position(actor.contestant_id),false)
	elif actor.active and (state == State.QUESTION or state == State.REVEAL):
		_eliminate(actor)
	elif actor.spectator:
		actor.respawn(Vector3(-5.0 + actor.contestant_id * 1.3,2.5,-10.0),true)

func _update_respawns(delta: float) -> void:
	for i in range(pending_respawns.size() - 1,-1,-1):
		pending_respawns[i].time -= delta
		if pending_respawns[i].time <= 0.0:
			var actor: RigidBody3D = pending_respawns[i].actor
			actor.respawn(Vector3(-5.0 + actor.contestant_id * 1.3,2.5,-10.0),true)
			actor.active = false
			actor.controls_enabled = state == State.QUESTION or state == State.REVEAL
			pending_respawns.remove_at(i)

func _on_action(actor: RigidBody3D, action: String) -> void:
	if client_mode: return
	if state != State.QUESTION and state != State.MENU and state != State.REVEAL: return
	if actor.spectator:
		if action == "shove" or action == "junk": _throw_junk(actor)
		return
	if not actor.active: return
	match action:
		"shove": _shove(actor)
		"dive":
			actor.perform_dive()
			sfx.play("dive")
		"emote":
			actor.perform_emote()
			sfx.play("emote")
			var tile: int = arena.get_tile_at(actor.global_position)
			if state == State.QUESTION: _flash_message("%s SAYS: '%s IS SAFE. TRUST ME, BRO!'" % [actor.display_name,"ABCD"[maxi(tile,0)]],actor.tint)
		"grab":
			if round_index == 2: _grab_cube(actor)

func _shove(actor: RigidBody3D) -> void:
	actor.perform_shove()
	var hit: bool = false
	for other in contestants:
		if other == actor or not other.active: continue
		var diff: Vector3 = other.global_position - actor.global_position
		if diff.length() > 2.15: continue
		diff.y = 0.0
		var direction: Vector3 = diff.normalized()
		if actor.aim_direction().dot(direction) < -0.3: continue
		other.apply_knockback((direction + Vector3.UP * 0.36) * shove_force)
		if is_instance_valid(other.held_cube): other.held_cube.drop(direction * 4.0 + Vector3.UP * 3.0)
		hit = true
	if hit:
		arena.spawn_confetti(actor.global_position + actor.aim_direction(),Color("fff6df"))
		sfx.play("shove")
	else: sfx.play("emote")

func _grab_cube(actor: RigidBody3D) -> void:
	if is_instance_valid(actor.held_cube):
		actor.held_cube.drop(actor.aim_direction() * 5.0 + Vector3.UP * 2.0)
		return
	var nearest: RigidBody3D = null
	var distance: float = 2.2
	for cube in cubes:
		if not is_instance_valid(cube): continue
		var d: float = actor.global_position.distance_to(cube.global_position)
		if d < distance:
			nearest = cube
			distance = d
	if nearest:
		nearest.take(actor)
		sfx.play("grab")

func _spawn_answer_cubes() -> void:
	var alive: int = 0
	for actor in contestants:
		if actor.active: alive += 1
	for i in maxi(0, alive - 1):
		var cube: RigidBody3D = CubeScript.new()
		cube.answer_index = int(current_question.correct) if i < maxi(1, floori(float(alive) / 3.0)) else (int(current_question.correct) + i) % 4
		arena.add_child(cube)
		cube.global_position = Vector3(cos(i * TAU / maxf(alive - 1,1)) * 4.0,4.0 + i * 0.55,sin(i * TAU / maxf(alive - 1,1)) * 4.0)
		cube.angular_velocity = Vector3(rng.randf(),rng.randf(),rng.randf()) * 2.0
		cubes.append(cube)

func _throw_junk(actor: RigidBody3D) -> void:
	# Cap physical clutter even if all eight balcony contestants throw.
	junk = junk.filter(func(item: Variant) -> bool: return is_instance_valid(item))
	if junk.size() >= 24: return
	var prop: RigidBody3D = CubeScript.new()
	prop.is_junk = true
	prop.smoke = rng.randf() < 0.3
	arena.add_child(prop)
	prop.global_position = actor.global_position + Vector3(0,1.0,0.7)
	var target: Vector3 = arena.tile_centers[rng.randi_range(0,3)] + Vector3(rng.randf_range(-2,2),0,rng.randf_range(-2,2))
	var travel: float = 1.25
	var velocity: Vector3 = (target - prop.global_position) / travel
	velocity.y += 0.5 * 19.0 * travel
	prop.linear_velocity = velocity
	prop.angular_velocity = Vector3(4,5,2)
	junk.append(prop)
	sfx.play("shove")

func _spawn_crown() -> void:
	crown_spawned = true
	crown = Node3D.new()
	arena.add_child(crown)
	crown.position = Vector3(0,1.6,0)
	var packed: PackedScene = load("res://assets/props/crown.glb")
	var visual: Node3D = packed.instantiate() as Node3D
	crown.add_child(visual)
	var label: Label3D = Label3D.new()
	label.text = "2× OR NOTHING"
	label.font_size = 32
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.0
	label.modulate = Color("ffe17c")
	crown.add_child(label)

func _execute_swappers() -> void:
	for actor in contestants:
		if actor.perk != "swapper" or not actor.active: continue
		var eligible: Array = contestants.filter(func(other: Variant) -> bool: return other != actor and other.active)
		if eligible.is_empty(): continue
		var target: RigidBody3D = eligible[rng.randi_range(0,eligible.size()-1)]
		var saved: Vector3 = actor.global_position
		actor.global_position = target.global_position + Vector3.UP * 0.2
		target.global_position = saved + Vector3.UP * 0.2
		actor.reset_physics_interpolation()
		target.reset_physics_interpolation()
		actor.linear_velocity = Vector3.ZERO
		target.linear_velocity = Vector3.ZERO
		actor.set_perk("")
		_flash_message("LAST-SECOND SWAP! %s ↔ %s" % [actor.display_name,target.display_name],COLORS[2])
		sfx.play("gacha")

func _update_sweeper(delta: float) -> void:
	var direction: Vector3 = Vector3(cos(arena.sweeper_angle),0,sin(arena.sweeper_angle))
	for actor in contestants:
		var id: int = actor.contestant_id
		sweep_cooldowns[id] = maxf(0.0, float(sweep_cooldowns.get(id,0.0)) - delta)
		if not actor.active or actor.global_position.y > 1.65 or actor.global_position.y < 0.0: continue
		var flat: Vector3 = actor.global_position * Vector3(1,0,1)
		var along: float = flat.dot(direction)
		var distance: float = (flat - direction * along).length()
		if distance < 0.75 and absf(along) < 7.0 and float(sweep_cooldowns[id]) <= 0.0:
			var tangent: Vector3 = Vector3(-direction.z,0,direction.x) * signf(along)
			actor.apply_knockback(tangent * sweeper_force + Vector3.UP * 2.8)
			sweep_cooldowns[id] = 1.0
			sfx.play("shove")

func _update_bots() -> void:
	var nerd: RigidBody3D = null
	if nerd_id >= 0: nerd = contestants[nerd_id]
	for actor in contestants:
		if not actor.is_bot: continue
		if actor.spectator:
			if rng.randf() < 0.045: _throw_junk(actor)
			continue
		if not actor.active: continue
		actor.bot_moving = true
		var choice: int = int(bot_choices.get(actor.contestant_id,0))
		var target: Vector3 = arena.tile_centers[choice] + bot_offsets.get(actor.contestant_id,Vector3.ZERO)
		if round_index == 2:
			if is_instance_valid(actor.held_cube):
				target = arena.tile_centers[(actor.contestant_id + 1) % 4]
			else:
				var closest: float = 1000.0
				for cube in cubes:
					if not is_instance_valid(cube) or cube.answer_index != choice: continue
					var d: float = actor.global_position.distance_to(cube.global_position)
					if d < closest:
						closest = d
						target = cube.global_position
				if closest < 2.0: _grab_cube(actor)
		elif is_instance_valid(nerd) and nerd.active and actor.perk != "nerd" and actor.contestant_id % 3 == 0 and time_left < 4.0:
			target = nerd.global_position + bot_offsets[actor.contestant_id] * 0.5
		elif actor.perk == "nerd" and time_left > 4.0:
			# Fake out the followers, then commit with enough time to cross the stage.
			target = arena.tile_centers[(choice + 1) % 4]
		if time_left < 3.0 and round_index != 2:
			target = arena.tile_centers[choice] + bot_offsets[actor.contestant_id] * 0.25
		if is_instance_valid(crown) and actor.contestant_id % 4 == 2 and time_left > 3.0:
			target = crown.global_position
		target.y = actor.global_position.y
		actor.bot_target = target
		if round_index == 4 and (absf(actor.global_position.x) < 2.25 or absf(actor.global_position.z) < 2.25):
			actor.request_jump()
		if round_index == 3 and rng.randf() < 0.13:
			actor.request_jump()
		if actor.global_position.distance_to(target) < 0.5: actor.bot_moving = false
		if rng.randf() < 0.07 and actor.shove_cooldown <= 0.0:
			_shove(actor)
			actor.shove_cooldown = 1.2
		if rng.randf() < 0.012: actor.perform_emote()

func _menu_bots(delta: float) -> void:
	ai_timer -= delta
	if ai_timer > 0.0: return
	ai_timer = 2.0
	for actor in contestants:
		if rng.randf() < 0.45:
			actor.bot_target = arena.tile_centers[rng.randi_range(0,3)] + Vector3(rng.randf_range(-1.3,1.3),0,rng.randf_range(-1.3,1.3))
			actor.bot_moving = true

func _human_perk_text() -> String:
	var details: Array[String] = []
	for actor in contestants:
		if actor.is_bot or actor.perk == "": continue
		if network_session != null and network_session.active and actor.contestant_id != local_contestant_index: continue
		var description: String = ""
		match actor.perk:
			"nerd": description = "NERD GLASSES · hold TAB / SELECT to peek"
			"heavy": description = "HEAVY BOOTS · twice the mass"
			"pinball": description = "PINBALL CURSE · extra bouncy"
			"swapper": description = "SWAPPER · auto fires at 1 second"
		details.append("P%d: %s" % [actor.contestant_id + 1 if network_session != null and network_session.active else actor.human_slot + 1,description])
	return "  /  ".join(details) if not details.is_empty() else "NO PERKS YET. BAD LUCK IS COMING."

func _any_peek_button() -> bool:
	for device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(device,JOY_BUTTON_BACK): return true
	return false

func _spawn_position(index: int) -> Vector3:
	var center: Vector3 = arena.tile_centers[index % 4]
	return center + Vector3(-0.9 if index < 4 else 0.9,1.1,0.0)

func _clear_props() -> void:
	for actor in contestants:
		if is_instance_valid(actor.held_cube): actor.held_cube.drop()
	for cube in cubes:
		if is_instance_valid(cube): cube.queue_free()
	for prop in junk:
		if is_instance_valid(prop): prop.queue_free()
	cubes.clear()
	junk.clear()
	if is_instance_valid(crown): crown.queue_free()
	crown = null
	_network_props.clear()
	for cloud in _network_clouds.values():
		if is_instance_valid(cloud): cloud.queue_free()
	_network_clouds.clear()

func _configure_gamepads() -> void:
	# Keep both keyboard sets usable. Assign available pads from the last human
	# backwards, allowing two keyboard friends plus two pads to fill four slots.
	var devices: Array[int] = Input.get_connected_joypads()
	var input_slots: int = 1 if network_session != null and network_session.active else mini(human_count,4)
	var pad_count: int = mini(devices.size(), input_slots)
	var first_slot: int = input_slots - pad_count
	var actions: Array[String] = ["left", "right", "up", "down", "jump", "shove", "dive", "emote", "grab"]
	var buttons: Array[int] = [-1,-1,-1,-1,JOY_BUTTON_A,JOY_BUTTON_X,JOY_BUTTON_B,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_Y]
	for slot in input_slots:
		for i in actions.size():
			var action: StringName = StringName("bro_p%d_%s" % [slot,actions[i]])
			for event in InputMap.action_get_events(action):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					InputMap.action_erase_event(action,event)
			if slot < first_slot: continue
			var device: int = devices[slot - first_slot]
			if i < 4:
				var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
				motion.device = device
				motion.axis = JOY_AXIS_LEFT_X if i < 2 else JOY_AXIS_LEFT_Y
				motion.axis_value = -1.0 if i == 0 or i == 2 else 1.0
				InputMap.action_add_event(action,motion)
			else:
				var button: InputEventJoypadButton = InputEventJoypadButton.new()
				button.device = device
				button.button_index = buttons[i] as JoyButton
				InputMap.action_add_event(action,button)

func _show_banner(title: String, subtitle: String, color: Color = Color("87eed0")) -> void:
	_network_banner = {"visible":true,"title":title,"subtitle":subtitle,"color":color}
	hud.show_banner(title,subtitle,color)

func _hide_banner() -> void:
	_network_banner.visible = false
	hud.hide_banner()

func _flash_message(message: String, color: Color = Color("fff6df")) -> void:
	_network_flash = {"serial":int(_network_flash.serial) + 1,"text":message,"color":color}
	hud.flash_message(message,color)

func _update_question_metadata(revealed: bool) -> void:
	if hud.has_method("update_question_metadata"):
		hud.update_question_metadata(str(current_question.get("category","Mixed bag")),str(current_question.get("difficulty","Easy")),str(current_question.get("explanation","")) if revealed else "")

func start_network_match(roster: Array, peer_id: int = 1, replica: bool = false) -> void:
	start_match(1)
	network_roster = roster.duplicate(true)
	client_mode = replica
	human_count = roster.size()
	local_contestant_index = 0
	_network_question_key = ""
	_network_banner_key = ""
	_network_last_flash = 0
	_network_results_shown = false
	for i in contestants.size():
		var actor: Node = contestants[i]
		var owner_id: int = 0
		var actor_name: String = NAMES[i]
		for player in roster:
			if int(player.slot) == i:
				owner_id = int(player.id)
				actor_name = str(player.name)
				if owner_id == peer_id: local_contestant_index = i
		actor.display_name = actor_name
		actor.setup(i,actor_name,COLORS[i],0 if owner_id == peer_id else -1)
		actor.configure_network(owner_id,peer_id,replica)
		# setup derives bot state from the local keyboard slot; ownership is definitive.
		actor.is_bot = owner_id == 0
		actor.controls_enabled = false
	arena.set_physics_process(not replica)
	_configure_gamepads()

func end_network_mode() -> void:
	client_mode = false
	_network_private_hint = -1
	return_to_menu()

func make_network_snapshot(for_peer_id: int) -> Dictionary:
	var public_question: Dictionary = {}
	var revealed: bool = state == State.REVEAL or state == State.GACHA or state == State.RESULTS
	if not current_question.is_empty():
		for key in ["id","category","difficulty","prompt","answers"]:
			if current_question.has(key): public_question[key] = current_question[key]
		if revealed:
			public_question.correct = current_question.get("correct",-1)
			public_question.explanation = current_question.get("explanation","")
	var cast: Array = []
	var private_hint: int = -1
	var for_actor: int = 0
	for actor in contestants:
		var actor_owner: int = int(actor.network_owner)
		if actor_owner == for_peer_id:
			for_actor = actor.contestant_id
			if actor.perk == "nerd" and actor.active and state == State.QUESTION:
				private_hint = int(current_question.get("correct",-1))
		var emote: Node = actor.get("_emote_label")
		cast.append({"id":actor.contestant_id,"name":actor.display_name,"tint":actor.tint,"owner":actor_owner,"position":actor.global_position,"rotation":actor.rotation,"velocity":actor.linear_velocity,"facing":actor.facing,"active":actor.active,"spectator":actor.spectator,"score":actor.score,"perk":actor.perk,"crown":actor.has_crown,"controls_enabled":actor.controls_enabled,"is_bot":actor.is_bot,"flashlight":actor.flashlight.visible,"dive_left":float(actor.get("_dive_left")),"emote_left":float(actor.get("_emote_left")),"shove_left":float(actor.get("_shove_left")),"emote_text":str(emote.text) if emote != null else ""})
	var props: Array = []
	for prop in cubes + junk:
		if not is_instance_valid(prop): continue
		var holder_id: int = prop.holder.contestant_id if is_instance_valid(prop.holder) else -1
		props.append({"id":prop.get_instance_id(),"answer":prop.answer_index,"junk":prop.is_junk,"smoke":prop.smoke,"position":prop.global_position,"rotation":prop.rotation,"holder":holder_id})
	var clouds: Array = []
	for child in arena.get_children():
		if child.has_meta("party_smoke"):
			clouds.append({"id":child.get_instance_id(),"position":child.global_position,"scale":child.scale,"transparency":child.transparency})
	var crown_state: Dictionary = {"visible":is_instance_valid(crown)}
	if is_instance_valid(crown):
		crown_state.position = crown.global_position
		crown_state.rotation = crown.rotation
	var arena_state: Dictionary = arena.get_network_state() if arena.has_method("get_network_state") else {}
	return {"state":int(state),"round":round_index,"question_index":question_index,"questions_per_round":questions_per_round,"time_left":time_left,"duration":question_duration,"elapsed":elapsed,"clock":global_clock,"question":public_question,"actors":cast,"props":props,"clouds":clouds,"crown":crown_state,"arena":arena_state,"banner":_network_banner.duplicate(true),"flash":_network_flash.duplicate(true),"private_hint":private_hint,"local_actor":for_actor,"gacha":gacha_summary}

func apply_network_snapshot(data: Dictionary) -> void:
	if not client_mode: return
	var previous_state: int = int(state)
	state = int(data.get("state",State.MENU)) as State
	round_index = clampi(int(data.get("round",0)),0,4)
	question_index = int(data.get("question_index",0))
	questions_per_round = int(data.get("questions_per_round",2))
	time_left = float(data.get("time_left",0.0))
	question_duration = float(data.get("duration",12.0))
	elapsed = float(data.get("elapsed",0.0))
	global_clock = float(data.get("clock",0.0))
	local_contestant_index = clampi(int(data.get("local_actor",0)),0,contestants.size()-1)
	current_question = data.get("question",{}).duplicate(true)
	_network_private_hint = int(data.get("private_hint",-1))
	gacha_summary = str(data.get("gacha",""))
	var cast: Array = data.get("actors",[])
	for entry in cast:
		var index: int = int(entry.get("id",-1))
		if index >= 0 and index < contestants.size():
			contestants[index].apply_network_snapshot(entry)
			contestants[index].held_cube = null
	if arena.has_method("apply_network_state"): arena.apply_network_state(data.get("arena",{}))
	_update_network_props(data.get("props",[]))
	_update_network_clouds(data.get("clouds",[]))
	var crown_state: Dictionary = data.get("crown",{})
	if bool(crown_state.get("visible",false)):
		if not is_instance_valid(crown): _spawn_crown()
		crown.global_position = crown_state.get("position",Vector3(0,1.6,0))
		crown.rotation = crown_state.get("rotation",Vector3.ZERO)
	elif is_instance_valid(crown):
		crown.queue_free()
		crown = null
	var question_key: String = "%d:%d:%s" % [round_index,question_index,str(current_question.get("id",current_question.get("prompt","")))]
	if question_key != _network_question_key:
		_network_question_key = question_key
		hud.update_round(round_index,ROUNDS[round_index].title,ROUNDS[round_index].rule)
		if current_question.has("prompt"):
			hud.update_question(str(current_question.prompt),current_question.answers,question_index+1,questions_per_round)
	if state == State.QUESTION or state == State.REVEAL:
		hud.set_question_visible(true)
	else:
		hud.set_question_visible(false)
	_update_question_metadata(state == State.REVEAL)
	if state == State.REVEAL and current_question.has("correct"): hud.reveal_answer(int(current_question.correct))
	hud.update_timer(time_left,question_duration)
	hud.update_scores(contestants)
	var local_actor: Node = contestants[local_contestant_index]
	hud.set_spectator(local_actor.spectator)
	hud.set_perk(_network_perk_text())
	if local_actor.spectator:
		hud.set_status("BALCONY REVENGE · SHOVE TO THROW JUNK · BACK NEXT ROUND")
	elif state == State.QUESTION:
		hud.set_status("GRAB THE CORRECT CUBE · E / Y" if round_index == 2 else "PICK YOUR ANSWER · SAME STAGE, EVERY SCREEN")
	var banner_data: Dictionary = data.get("banner",{})
	var banner_key: String = "%s:%s:%s" % [str(banner_data.get("visible",false)),str(banner_data.get("title","")),str(banner_data.get("subtitle",""))]
	if banner_key != _network_banner_key:
		_network_banner_key = banner_key
		if bool(banner_data.get("visible",false)):
			hud.show_banner(str(banner_data.get("title","")),str(banner_data.get("subtitle","")),banner_data.get("color",Color.WHITE))
		else: hud.hide_banner()
	var flash: Dictionary = data.get("flash",{})
	if int(flash.get("serial",0)) > _network_last_flash:
		_network_last_flash = int(flash.serial)
		hud.flash_message(str(flash.get("text","")),flash.get("color",Color.WHITE))
	if state == State.RESULTS and not _network_results_shown:
		_network_results_shown = true
		hud.show_results(contestants)
	sfx.urgent = state == State.QUESTION and time_left < 4.0
	if state == State.QUESTION:
		var tick: int = int(ceil(time_left))
		if tick <= 5 and tick != _network_audio_tick:
			_network_audio_tick = tick
			sfx.play("tick")
	if previous_state != int(state):
		_network_audio_tick = -1
		match state:
			State.INTRO: sfx.play("start")
			State.REVEAL: sfx.play("correct" if local_actor.active else "wrong")
			State.GACHA: sfx.play("gacha")
			State.RESULTS: sfx.play("start")
		state_changed.emit(state)

func _update_network_props(entries: Array) -> void:
	var seen: Dictionary = {}
	var next_cubes: Array = []
	var next_junk: Array = []
	for entry in entries:
		var prop_id: int = int(entry.get("id",0))
		seen[prop_id] = true
		var prop: RigidBody3D = _network_props.get(prop_id)
		if not is_instance_valid(prop):
			prop = CubeScript.new()
			prop.answer_index = clampi(int(entry.get("answer",0)),0,3)
			prop.is_junk = bool(entry.get("junk",false))
			prop.smoke = bool(entry.get("smoke",false))
			prop.network_replica = true
			arena.add_child(prop)
			prop.configure_network_replica()
			_network_props[prop_id] = prop
		prop.apply_network_snapshot(entry)
		var holder_id: int = int(entry.get("holder",-1))
		prop.holder = contestants[holder_id] if holder_id >= 0 and holder_id < contestants.size() else null
		if is_instance_valid(prop.holder): prop.holder.held_cube = prop
		if prop.is_junk: next_junk.append(prop)
		else: next_cubes.append(prop)
	for prop_id in _network_props.keys():
		if not seen.has(prop_id):
			var old_prop: Node = _network_props[prop_id]
			if is_instance_valid(old_prop): old_prop.queue_free()
			_network_props.erase(prop_id)
	cubes = next_cubes
	junk = next_junk

func _network_perk_text() -> String:
	var actor: Node = contestants[local_contestant_index]
	if actor.perk == "nerd":
		if _network_private_hint >= 0 and (Input.is_key_pressed(KEY_TAB) or _any_peek_button()):
			return "YOUR SECRET: %s IS CORRECT · YOUR FRIENDS CAN'T SEE THIS" % "ABCD"[_network_private_hint]
		return "NERD GLASSES · HOLD TAB / SELECT FOR YOUR PRIVATE HINT"
	return _human_perk_text()

func _update_network_clouds(entries: Array) -> void:
	var seen: Dictionary = {}
	for entry in entries:
		var cloud_id: int = int(entry.get("id",0))
		seen[cloud_id] = true
		var cloud: MeshInstance3D = _network_clouds.get(cloud_id)
		if not is_instance_valid(cloud):
			cloud = MeshInstance3D.new()
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = 1.6
			sphere.height = 2.2
			cloud.mesh = sphere
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = Color(0.55,0.44,0.7,0.64)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cloud.material_override = material
			arena.add_child(cloud)
			_network_clouds[cloud_id] = cloud
		cloud.global_position = entry.get("position",Vector3.ZERO)
		cloud.scale = entry.get("scale",Vector3.ONE)
		cloud.transparency = float(entry.get("transparency",0.0))
	for cloud_id in _network_clouds.keys():
		if not seen.has(cloud_id):
			var cloud: Node = _network_clouds[cloud_id]
			if is_instance_valid(cloud): cloud.queue_free()
			_network_clouds.erase(cloud_id)
