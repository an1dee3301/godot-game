class_name Guard
extends CharacterBody3D
## Museum officer AI. Every state owns its movement and its exit condition.

enum State { PATROL, SUSPICIOUS, CHASE, ATTACK, SEARCH, RETURN, STUNNED, DOWN }

signal state_changed(guard: Guard, old_state: int, new_state: int)
signal spotted_player(guard: Guard)
signal knocked_out(guard: Guard)
signal attacked(guard: Guard, hit: bool)

var kind: int = KK.EnemyKind.GUARD
var stats: Dictionary = {}
var state: int = State.PATROL
var awareness := 0.0
var hp := 3
var speed_mult := 1.0
var last_known_position := Vector3.ZERO
var nav_agent: NavigationAgent3D
var anim: AnimationPlayer
var debug_label := false

var _route := PackedVector3Array()
var _route_index := 0
var _wait_time := 1.5
var _state_time := 0.0
var _wait_left := 0.0
var _look_left := 0.0
var _investigation_scanning := false
var _blind_left := 0.0
var _stun_left := 0.0
var _lose_left := 0.0
var _search_left := 0.0
var _retarget_left := 0.0
var _stuck_left := 0.0
var _last_move_pos := Vector3.ZERO
var _investigate_point := Vector3.ZERO
var _target := Vector3.ZERO
var _alert_origin := Vector3.ZERO
var _nav_ready := false
var _saw_player := false
var _attack_landed := false
var _desired_velocity := Vector3.ZERO
var _model: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _icon: Label3D
var _awareness_bar: Label3D
var _debug_text: Label3D
var _cone: MeshInstance3D
var _cone_mesh: ImmediateMesh
var _cone_mat: StandardMaterial3D
var _flashlight: SpotLight3D
var _attack_glint: OmniLight3D
var _stars: Node3D
var _sleep_bubbles: Node3D
var _icon_text := ""
var _cone_tick := 0.0
static var _loft_cache: Dictionary = {}


## Configure a guard after it has entered the scene tree.
func setup(enemy_kind: int, patrol_points: PackedVector3Array, wait_time := 1.5) -> void:
	kind = enemy_kind
	stats = KK.ENEMY_STATS[kind]
	hp = int(stats["max_hp"])
	_route = patrol_points
	_wait_time = maxf(0.0, wait_time)
	collision_layer = KK.LAYER_ENEMY
	collision_mask = KK.LAYER_WORLD | KK.LAYER_GLASS | KK.LAYER_PLAYER
	floor_snap_length = 0.18
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 if kind == KK.EnemyKind.GUARD else 0.46
	capsule.height = 1.8 if kind == KK.EnemyKind.GUARD else 2.05
	var shape := CollisionShape3D.new()
	shape.position.y = capsule.height * 0.5
	shape.shape = capsule
	add_child(shape)
	_nav_ready = false
	nav_agent = NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	nav_agent.radius = capsule.radius + 0.05
	nav_agent.path_desired_distance = 0.55
	nav_agent.target_desired_distance = 0.7
	nav_agent.avoidance_enabled = true
	nav_agent.neighbor_distance = 2.4
	nav_agent.max_neighbors = 8
	nav_agent.time_horizon_agents = 0.8
	nav_agent.velocity_computed.connect(_on_safe_velocity)
	add_child(nav_agent)
	_build_model()
	_build_cone()
	_build_icons()
	_build_animations()
	add_to_group(KK.GROUP_GUARDS)
	_last_move_pos = global_position
	# The map synchronizes after the level's navigation region enters the tree.
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if stats.is_empty() or state == State.DOWN:
		return
	_state_time += delta
	_blind_left = maxf(0.0, _blind_left - delta)
	_retarget_left -= delta
	_cone_tick -= delta
	if not _nav_ready:
		_nav_ready = NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) > 0
		if not _nav_ready:
			return
		_set_target(_route[0] if not _route.is_empty() else global_position)
	_update_perception(delta)
	# A finished or absent player is never a combat target.
	if not _player_alive() and state in [State.CHASE, State.ATTACK, State.SEARCH]:
		set_state(State.RETURN)
	match state:
		State.PATROL:
			_state_patrol(delta)
		State.SUSPICIOUS:
			_state_suspicious(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.SEARCH:
			_state_search(delta)
		State.RETURN:
			_state_return(delta)
		State.STUNNED:
			_state_stunned(delta)
		State.DOWN:
			_state_down(delta)
	if state not in [State.STUNNED, State.DOWN] and _nav_ready:
		_update_stuck(delta)
	if _cone_tick <= 0.0:
		_cone_tick = 0.1
		_update_cone()
	_update_icon()
	_debug_text.visible = debug_label
	if debug_label:
		_debug_text.text = "%s  %d%%" % [state_name(), roundi(awareness * 100.0)]


func _state_patrol(delta: float) -> void:
	if _wait_time <= 0.0 and _arrived():
		_route_index = (_route_index + 1) % maxi(1, _route.size())
		_set_target(_route[_route_index] if not _route.is_empty() else global_position)
	if _wait_left > 0.0:
		_wait_left -= delta
		_stop()
		_play("look_around")
		if _wait_left <= 0.0:
			_route_index = (_route_index + 1) % maxi(1, _route.size())
			_set_target(_route[_route_index] if not _route.is_empty() else global_position)
		return
	if _arrived():
		# A route point starts a deliberate scan before moving to the next point.
		_wait_left = _wait_time
		_stop()
		_play("look_around")
	else:
		_path_move(float(stats["patrol_speed"]) * speed_mult, delta)
		_play("walk")


func _state_suspicious(delta: float) -> void:
	if not _arrived() and not _investigation_scanning:
		_path_move(float(stats["patrol_speed"]) * 0.72 * speed_mult, delta)
		_play("walk")
	else:
		# At the stimulus, search visually for two seconds, then abandon it.
		if not _investigation_scanning:
			_investigation_scanning = true
			_look_left = 2.0
		_stop()
		_look_left -= delta
		_play("look_around")
		if _look_left <= 0.0:
			set_state(State.RETURN)


func _state_chase(delta: float) -> void:
	if _saw_player:
		_lose_left = float(stats["lose_time"])
		var player := KK.get_player(get_tree())
		if player != null and _retarget_left <= 0.0:
			_retarget_left = 0.2
			_set_target(player.global_position)
	else:
		_lose_left -= delta
		if _lose_left <= 0.0:
			# We lost sight for the full grace period: search the last sighting.
			set_state(State.SEARCH)
			return
	if _can_attack_now():
		# The swing has its own state so damage cannot happen while chasing.
		set_state(State.ATTACK)
		return
	_path_move(float(stats["chase_speed"]) * speed_mult, delta)
	_play("run")


func _state_attack(delta: float) -> void:
	_stop()
	var player := KK.get_player(get_tree())
	if not _player_alive():
		set_state(State.RETURN)
		return
	_face_point(player.global_position, delta, 12.0)
	var windup := float(stats["attack_windup"])
	if not _attack_landed and _state_time >= windup:
		_attack_landed = true
		var hit := _attack_hit_valid(player)
		if hit:
			player.take_damage(float(stats["attack_damage"]), self)
		attacked.emit(self, hit)
	if _state_time >= windup + float(stats["attack_cooldown"]):
		# Even a missed swing must finish its cooldown before pursuit resumes.
		set_state(State.CHASE)


func _state_search(delta: float) -> void:
	_search_left -= delta
	if not _arrived():
		_path_move(float(stats["patrol_speed"]) * speed_mult, delta)
		_play("walk")
	else:
		_stop()
		_play("look_around")
	if _search_left <= 0.0:
		# A full search with no reacquisition returns to the route.
		set_state(State.RETURN)


func _state_return(delta: float) -> void:
	awareness = maxf(0.0, awareness - delta * 0.5)
	if _arrived():
		# Resume the normal route at whichever waypoint was closest.
		set_state(State.PATROL)
		return
	_path_move(float(stats["patrol_speed"]) * speed_mult, delta)
	_play("walk")


func _state_stunned(delta: float) -> void:
	_stop()
	_stun_left -= delta
	if _stun_left <= 0.0:
		# A card reveals its shooter, so recovery starts an alerted pursuit.
		last_known_position = _alert_origin
		set_state(State.CHASE if _player_alive() else State.RETURN)


func _state_down(_delta: float) -> void:
	_stop()


func _update_perception(delta: float) -> void:
	_saw_player = can_see_player()
	if _saw_player:
		var player := KK.get_player(get_tree())
		last_known_position = player.global_position
		var distance := global_position.distance_to(player.global_position)
		var close_factor := lerpf(2.5, 1.0, clampf((distance - 3.0) / maxf(0.1, float(stats["view_distance"]) - 3.0), 0.0, 1.0))
		awareness = minf(1.0, awareness + delta * close_factor * player.visibility_factor() / float(stats["detect_time"]))
	else:
		awareness = maxf(0.0, awareness - delta * 0.35)
	if awareness >= 1.0 and state not in [State.CHASE, State.ATTACK, State.STUNNED, State.DOWN]:
		# Full visual confirmation broadcasts the sighting to nearby guards.
		set_state(State.CHASE)
	elif awareness >= 0.35 and state in [State.PATROL, State.RETURN]:
		# Partial sight is investigation, not an immediate pursuit.
		_investigate_point = last_known_position
		set_state(State.SUSPICIOUS)
	elif _saw_player and state == State.SEARCH and awareness >= 0.35:
		set_state(State.CHASE)


## Noise prompts an investigation, including a card impacting behind a wall.
func hear_noise(pos: Vector3, radius: float) -> void:
	if stats.is_empty() or state in [State.DOWN, State.STUNNED, State.CHASE, State.ATTACK]:
		return
	if global_position.distance_to(pos) > radius * float(stats["hearing_mult"]):
		return
	_investigate_point = pos
	last_known_position = pos
	if state == State.SUSPICIOUS:
		_look_left = 0.0
		_investigation_scanning = false
		_set_target(pos)
	else:
		set_state(State.SUSPICIOUS)


## A confirmed sighting from another guard starts a chase without rebroadcasting.
func receive_alert(player_pos: Vector3) -> void:
	if stats.is_empty() or state == State.DOWN or not _player_alive():
		return
	last_known_position = player_pos
	awareness = 1.0
	if state == State.STUNNED:
		_alert_origin = player_pos
		return
	if state != State.CHASE and state != State.ATTACK:
		set_state(State.CHASE, false)
	else:
		_set_target(player_pos)


## Cards cost one health and either stun or permanently knock out the guard.
func take_card_hit(from: Vector3) -> void:
	if state == State.DOWN or stats.is_empty():
		return
	hp -= 1
	if hp <= 0:
		set_state(State.DOWN)
		knocked_out.emit(self)
	else:
		_alert_origin = from
		stun(float(stats["stun_time"]))


## Smoke suppresses vision while leaving hearing intact.
func blind(seconds: float) -> void:
	if state != State.DOWN:
		_blind_left = maxf(_blind_left, seconds)


## Pause the AI for a duration; repeated stuns extend it.
func stun(seconds: float) -> void:
	if state == State.DOWN:
		return
	_stun_left = maxf(_stun_left, seconds)
	if state != State.STUNNED:
		set_state(State.STUNNED)


## Vision requires range, facing, world-only line of sight, and a visible player.
func can_see_player() -> bool:
	if stats.is_empty() or state in [State.DOWN, State.STUNNED] or _blind_left > 0.0 or not _player_alive():
		return false
	var player := KK.get_player(get_tree())
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	if offset.length_squared() > pow(float(stats["view_distance"]), 2.0):
		return false
	if offset.length_squared() > 0.001:
		var forward := -global_transform.basis.z.normalized()
		if forward.dot(offset.normalized()) < cos(deg_to_rad(float(stats["view_angle_deg"]) * 0.5)):
			return false
	if player.visibility_factor() <= 0.0:
		return false
	return KK.has_line_of_sight(get_world_3d(), global_position + Vector3.UP * 1.6, player.aim_point())


## Transition through exit and entry hooks. Optional broadcast avoids alert echoes.
func set_state(new_state: int, broadcast := true) -> void:
	if new_state == state or state == State.DOWN:
		return
	var old_state := state
	_exit_state(old_state)
	state = new_state
	_state_time = 0.0
	_enter_state(new_state, old_state, broadcast)
	state_changed.emit(self, old_state, new_state)


func _exit_state(old_state: int) -> void:
	if old_state == State.ATTACK and _attack_glint != null:
		_attack_glint.visible = false
	if old_state == State.STUNNED and _stars != null:
		_stars.visible = false


func _enter_state(new_state: int, old_state: int, broadcast: bool) -> void:
	match new_state:
		State.PATROL:
			_wait_left = 0.0
			_set_target(_route[_route_index] if not _route.is_empty() else global_position)
		State.SUSPICIOUS:
			_look_left = 0.0
			_investigation_scanning = false
			_set_target(_investigate_point)
		State.CHASE:
			_lose_left = float(stats["lose_time"])
			_retarget_left = 0.0
			_set_target(last_known_position)
			if old_state not in [State.CHASE, State.ATTACK] and broadcast and _player_alive():
				spotted_player.emit(self)
				KK.alert_guards(get_tree(), global_position, float(stats["alert_radius"]), last_known_position, self)
		State.ATTACK:
			_attack_landed = false
			_attack_glint.visible = true
			_play("attack", true)
		State.SEARCH:
			_search_left = float(stats["search_time"])
			_set_target(last_known_position)
		State.RETURN:
			_route_index = _nearest_route_index()
			_set_target(_route[_route_index] if not _route.is_empty() else global_position)
		State.STUNNED:
			_stop()
			_stars.visible = true
			_play("stunned", true)
		State.DOWN:
			_stop()
			_stars.visible = false
			_sleep_bubbles.visible = true
			collision_layer = 0
			collision_mask = 0
			nav_agent.avoidance_enabled = false
			_play("down", true)
			awareness = 0.0
	_update_cone_color()
	_update_icon(true)


## Human-readable current state.
func state_name() -> String:
	return State.keys()[state]


## Compact data for debug HUDs and tests.
func debug_info() -> Dictionary:
	return {"state": state_name(), "awareness": awareness, "target": _target}


func _player_alive() -> bool:
	var player := KK.get_player(get_tree())
	return player != null and is_instance_valid(player) and not player.is_dead


func _set_target(pos: Vector3) -> void:
	_target = pos
	if _nav_ready:
		nav_agent.target_position = pos


func _arrived() -> bool:
	return global_position.distance_to(_target) < 0.8 or (_nav_ready and nav_agent.is_navigation_finished())


func _nearest_route_index() -> int:
	var best := 0
	var distance := INF
	for i in _route.size():
		var d := global_position.distance_squared_to(_route[i])
		if d < distance:
			distance = d
			best = i
	return best


func _path_move(speed: float, delta: float) -> void:
	if not _nav_ready or _arrived():
		_stop()
		return
	var next := nav_agent.get_next_path_position()
	var direction := next - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		_stop()
		return
	_desired_velocity = direction.normalized() * speed
	nav_agent.velocity = _desired_velocity
	_face_point(next, delta, 9.0)


func _on_safe_velocity(safe_velocity: Vector3) -> void:
	if state in [State.DOWN, State.STUNNED, State.ATTACK] or _desired_velocity == Vector3.ZERO:
		return
	velocity = safe_velocity
	velocity.y = -0.1
	move_and_slide()


func _stop() -> void:
	_desired_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	if nav_agent != null and nav_agent.avoidance_enabled:
		nav_agent.velocity = Vector3.ZERO


func _face_point(pos: Vector3, delta: float, rate: float) -> void:
	var flat := pos - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.01:
		return
	var target_yaw := atan2(-flat.x, -flat.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta * rate))


func _update_stuck(delta: float) -> void:
	if _desired_velocity.length_squared() < 0.2:
		_stuck_left = 0.0
		_last_move_pos = global_position
		return
	if global_position.distance_squared_to(_last_move_pos) > 0.04:
		_stuck_left = 0.0
		_last_move_pos = global_position
	else:
		_stuck_left += delta
	if _stuck_left >= 2.0:
		_stuck_left = 0.0
		_last_move_pos = global_position
		if state == State.PATROL and not _route.is_empty():
			_route_index = (_route_index + 1) % _route.size()
			_set_target(_route[_route_index])
		else:
			_set_target(_target + Vector3(0.01, 0.0, 0.01))


func _can_attack_now() -> bool:
	if not _player_alive():
		return false
	var player := KK.get_player(get_tree())
	return global_position.distance_to(player.global_position) <= float(stats["attack_range"]) and KK.has_line_of_sight(get_world_3d(), global_position + Vector3.UP * 1.35, player.aim_point())


func _attack_hit_valid(player: Node3D) -> bool:
	if not _player_alive():
		return false
	var offset := player.global_position - global_position
	offset.y = 0.0
	if offset.length() > float(stats["attack_range"]) * 1.15:
		return false
	if -global_transform.basis.z.dot(offset.normalized()) < cos(deg_to_rad(35.0)):
		return false
	return KK.has_line_of_sight(get_world_3d(), global_position + Vector3.UP * 1.35, player.aim_point())


func _play(name: String, restart := false) -> void:
	if anim.current_animation != name or restart:
		anim.play(name)


func _part(parent: Node3D, part_name: String, mesh: Mesh, material: Material, position: Vector3, scale_value: Vector3 = Vector3.ONE) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = position
	parent.add_child(pivot)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.scale = scale_value
	pivot.add_child(visual)
	return pivot


func _loft(profile: PackedFloat32Array, sides: int = 16) -> ArrayMesh:
	# Each ring is (height, x radius, z radius, x centre, z centre).
	# Varying rings make one continuous anatomical surface rather than stacked primitives.
	var cache_key: String = str(profile) + "/" + str(sides)
	if _loft_cache.has(cache_key):
		return _loft_cache[cache_key] as ArrayMesh
	var mesh := ArrayMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: int = profile.size() / 5
	for j in rings - 1:
		for i in sides:
			var a: float = TAU * float(i) / float(sides)
			var b: float = TAU * float(i + 1) / float(sides)
			var p0 := Vector3(profile[j * 5 + 3] + cos(a) * profile[j * 5 + 1], profile[j * 5], profile[j * 5 + 4] + sin(a) * profile[j * 5 + 2])
			var p1 := Vector3(profile[(j + 1) * 5 + 3] + cos(a) * profile[(j + 1) * 5 + 1], profile[(j + 1) * 5], profile[(j + 1) * 5 + 4] + sin(a) * profile[(j + 1) * 5 + 2])
			var p2 := Vector3(profile[(j + 1) * 5 + 3] + cos(b) * profile[(j + 1) * 5 + 1], profile[(j + 1) * 5], profile[(j + 1) * 5 + 4] + sin(b) * profile[(j + 1) * 5 + 2])
			var p3 := Vector3(profile[j * 5 + 3] + cos(b) * profile[j * 5 + 1], profile[j * 5], profile[j * 5 + 4] + sin(b) * profile[j * 5 + 2])
			if profile[5] > profile[0]:
				surface.add_vertex(p0)
				surface.add_vertex(p1)
				surface.add_vertex(p2)
				surface.add_vertex(p0)
				surface.add_vertex(p2)
				surface.add_vertex(p3)
			else:
				surface.add_vertex(p0)
				surface.add_vertex(p2)
				surface.add_vertex(p1)
				surface.add_vertex(p0)
				surface.add_vertex(p3)
				surface.add_vertex(p2)
	# Small end rings close naturally without visible flat box edges.
	surface.index()
	surface.generate_normals()
	surface.commit(mesh)
	_loft_cache[cache_key] = mesh
	return mesh


func _loft_part(parent: Node3D, part_name: String, profile: PackedFloat32Array, material: Material, position: Vector3 = Vector3.ZERO) -> Node3D:
	return _part(parent, part_name, _loft(profile), material, position)


func _ellipsoid(parent: Node3D, part_name: String, material: Material, position: Vector3, size: Vector3) -> Node3D:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 12
	return _part(parent, part_name, sphere, material, position, size)


func _cylinder(parent: Node3D, part_name: String, material: Material, position: Vector3, top: float, bottom: float, height: float) -> Node3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 24
	return _part(parent, part_name, shape, material, position)


func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Model"
	_model.scale = Vector3.ONE * (1.13 if kind == KK.EnemyKind.INSPECTOR else 1.0)
	add_child(_model)
	var inspector: bool = kind == KK.EnemyKind.INSPECTOR
	var cloth := KK.standard_material(Color(0.27, 0.34, 0.52) if not inspector else Color(0.47, 0.34, 0.23), 0.88)
	var trousers := KK.standard_material(Color(0.11, 0.17, 0.30) if not inspector else Color(0.24, 0.19, 0.15), 0.9)
	var shirt := KK.standard_material(Color(0.68, 0.75, 0.80) if not inspector else Color(0.80, 0.74, 0.62), 0.9)
	var leather := KK.standard_material(Color(0.055, 0.065, 0.09) if not inspector else Color(0.16, 0.105, 0.065), 0.68)
	var skin := KK.standard_material(Color(0.84, 0.62, 0.46), 0.86)
	var gold := KK.standard_material(Color(0.95, 0.72, 0.26), 0.34, 0.45)
	var ink := KK.standard_material(Color(0.022, 0.029, 0.045), 0.7)
	var red := KK.standard_material(Color(0.74, 0.07, 0.085), 0.68)
	# Torso is a single shoulder/chest/waist/hip loft. A narrower front shirt
	# panel sits inside the jacket opening and follows the chest taper.
	_loft_part(_model, "Torso", PackedFloat32Array([
		0.82, .205, .13, 0, 0, .92, .245, .15, 0, 0,
		1.10, .225, .145, 0, 0, 1.31, .275, .165, 0, 0,
		1.53, .315, .17, 0, 0, 1.66, .255, .14, 0, 0,
		1.70, .10, .10, 0, 0]), cloth)
	_loft_part(_model, "Shirt", PackedFloat32Array([
		1.13, .115, .028, 0, -.148, 1.37, .13, .03, 0, -.17,
		1.59, .125, .027, 0, -.155, 1.68, .06, .02, 0, -.12]), shirt)
	_cylinder(_model, "Neck", skin, Vector3(0, 1.72, 0), .077, .09, .19)
	# A shaped face includes the cranium, tapered jaw, nose and ears.
	_head = _loft_part(_model, "Head", PackedFloat32Array([
		-.23, .07, .095, 0, -.012, -.17, .135, .13, 0, 0,
		-.06, .165, .16, 0, 0, .085, .17, .17, 0, 0,
		.19, .145, .145, 0, .01, .255, .025, .04, 0, .01]), skin, Vector3(0, 1.91, 0))
	_ellipsoid(_head, "Nose", skin, Vector3(0, -.045, -.174), Vector3(.041, .055, .067))
	for side in [-1.0, 1.0]:
		_ellipsoid(_head, "Ear", skin, Vector3(side * .172, -.045, .002), Vector3(.038, .068, .039))
		_ellipsoid(_head, "EyeWhite", shirt, Vector3(side * .071, .045, -.151), Vector3(.036, .022, .012))
		_ellipsoid(_head, "Pupil", ink, Vector3(side * .071, .044, -.164), Vector3(.014, .019, .009))
		var brow := _ellipsoid(_head, "Brow", ink, Vector3(side * .073, .091, -.153), Vector3(.052, .012, .013))
		brow.rotation.z = side * -.09
	if inspector:
		for side in [-1.0, 1.0]:
			var whisker := _ellipsoid(_head, "Moustache", ink, Vector3(side * .071, -.105, -.164), Vector3(.077, .027, .026))
			whisker.rotation.z = side * .2
		# Fedora crown and softly downturned brim.
		_cylinder(_head, "FedoraCrown", leather, Vector3(0, .285, 0), .145, .19, .21)
		_cylinder(_head, "FedoraBrim", leather, Vector3(0, .18, -.015), .275, .265, .028)
		_loft_part(_model, "CoatTail", PackedFloat32Array([
		.65, .32, .20, 0, .018, .72, .33, .205, 0, .015,
		.95, .25, .16, 0, 0, 1.10, .23, .15, 0, 0]), cloth)
		_loft_part(_model, "Tie", PackedFloat32Array([
		1.12, .015, .009, 0, -.184, 1.40, .047, .012, 0, -.199,
		1.57, .038, .012, 0, -.19]), red)
	else:
		_cylinder(_head, "PeakedCrown", leather, Vector3(0, .278, .017), .15, .192, .185)
		var peak := _ellipsoid(_head, "CapPeak", leather, Vector3(0, .205, -.152), Vector3(.234, .017, .15))
		peak.rotation.x = -.1
		_ellipsoid(_head, "CapBadge", gold, Vector3(0, .292, -.188), Vector3(.047, .059, .015))
	# Arms and legs use continuously tapered ring sections with an elbow/knee.
	# Their pivots preserve the existing named animation tracks.
	for side in [-1.0, 1.0]:
		var arm_name: String = "LeftArm" if side < 0.0 else "RightArm"
		var arm := _loft_part(_model, arm_name, PackedFloat32Array([
		-.55, .058, .06, 0, -.045, -.48, .071, .075, 0, -.035,
		-.31, .084, .084, 0, -.015, -.25, .082, .083, 0, 0,
		-.12, .105, .105, 0, .005, .02, .132, .124, 0, 0,
		.09, .07, .08, 0, 0]), cloth, Vector3(side * .34, 1.56, 0))
		if side < 0.0:
			_left_arm = arm
		else:
			_right_arm = arm
		_ellipsoid(arm, "Hand", skin, Vector3(0, -.565, -.047), Vector3(.066, .105, .064))
		_ellipsoid(arm, "Thumb", skin, Vector3(-side * .07, -.55, -.08), Vector3(.035, .061, .038))
		var leg_name: String = "LeftLeg" if side < 0.0 else "RightLeg"
		var leg := _loft_part(_model, leg_name, PackedFloat32Array([
		-.76, .073, .078, 0, -.008, -.69, .087, .091, 0, -.01,
		-.48, .097, .105, 0, .004, -.39, .081, .095, 0, .01,
		-.23, .105, .12, 0, 0, -.06, .137, .134, 0, 0,
		.055, .075, .075, 0, 0]), trousers, Vector3(side * .137, .85, 0))
		_loft_part(leg, "Shoe", PackedFloat32Array([
		-.80, .07, .17, 0, -.065, -.765, .11, .205, 0, -.062,
		-.68, .105, .175, 0, -.047, -.65, .045, .09, 0, -.012]), leather)
	# Belt, pouches, lapels and cuffs are rounded tailoring details.
	_cylinder(_model, "WaistBelt", leather, Vector3(0, .965, 0), .236, .233, .065)
	_ellipsoid(_model, "Buckle", gold, Vector3(0, .965, -.161), Vector3(.055, .04, .018))
	for side in [-1.0, 1.0]:
		_ellipsoid(_model, "BeltPouch", leather, Vector3(side * .208, .95, -.035), Vector3(.065, .077, .095))
		var lapel := _ellipsoid(_model, "Lapel", shirt if not inspector else leather, Vector3(side * .126, 1.49, -.15), Vector3(.055, .19, .025))
		lapel.rotation.z = side * .25
	if not inspector:
		var baton := _cylinder(_right_arm, "Baton", leather, Vector3(0, -.69, -.085), .028, .034, .48)
		baton.rotation.x = -.35
		_cylinder(_left_arm, "Flashlight", leather, Vector3(0, -.67, -.11), .055, .038, .21)
		_ellipsoid(_left_arm, "FlashlightLens", gold, Vector3(0, -.78, -.12), Vector3(.048, .018, .048))
		_flashlight = SpotLight3D.new()
		_flashlight.name = "FlashlightBeam"
		_flashlight.position = Vector3(0, -.76, -.14)
		_flashlight.rotation_degrees = Vector3(-72, 0, 0)
		_flashlight.light_color = Color(1.0, .79, .52)
		_flashlight.light_energy = 2.5
		_flashlight.light_volumetric_fog_energy = 1.5
		_flashlight.spot_range = minf(10.0, float(stats["view_distance"]))
		_flashlight.spot_angle = 26.0
		_flashlight.shadow_enabled = false
		_left_arm.add_child(_flashlight)
	else:
		var horn := _cylinder(_left_arm, "Megaphone", gold, Vector3(0, -.68, -.13), .15, .055, .30)
		horn.rotation.x = -PI * .48
		_cylinder(_left_arm, "MegaphoneRim", leather, Vector3(0, -.69, -.34), .16, .16, .025)
	var fill := OmniLight3D.new()
	fill.name = "SilhouetteFill"
	fill.position = Vector3(0, 1.28, .4)
	fill.light_color = Color(.57, .72, 1.0) if not inspector else Color(1.0, .76, .49)
	fill.light_energy = .32
	fill.omni_range = 2.1
	fill.shadow_enabled = false
	_model.add_child(fill)
	_attack_glint = OmniLight3D.new()
	_attack_glint.position = Vector3(.4, 1.5, -.3)
	_attack_glint.light_color = Color(1.0, .12, .07)
	_attack_glint.light_energy = 2.0
	_attack_glint.omni_range = 1.3
	_attack_glint.shadow_enabled = false
	_attack_glint.visible = false
	_model.add_child(_attack_glint)


func _build_cone() -> void:
	_cone_mesh = ImmediateMesh.new()
	_cone_mat = StandardMaterial3D.new()
	_cone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cone_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_cone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cone_mat.vertex_color_use_as_albedo = true
	_cone = MeshInstance3D.new()
	_cone.name = "VisionCone"
	_cone.mesh = _cone_mesh
	_cone.material_override = _cone_mat
	add_child(_cone)
	_update_cone_color()


func _update_cone_color() -> void:
	if _cone == null:
		return
	_cone.visible = state not in [State.STUNNED, State.DOWN]
	# Vertex alpha is used for the soft falloff in _update_cone.
	var color := Color(.54, .77, 1.0)
	if kind == KK.EnemyKind.INSPECTOR:
		color = Color(1.0, .68, .29)
	match state:
		State.SUSPICIOUS, State.SEARCH:
			color = Color(1.0, .78, .24)
		State.CHASE, State.ATTACK:
			color = Color(1.0, .25, .18)
	_cone_mat.albedo_color = color


func _cone_vertex(point: Vector3, color: Color, opacity: float) -> void:
	_cone_mesh.surface_set_color(Color(color.r, color.g, color.b, opacity))
	_cone_mesh.surface_add_vertex(point)


func _update_cone() -> void:
	if _cone == null or not _cone.visible:
		return
	_cone_mesh.clear_surfaces()
	var half := deg_to_rad(float(stats["view_angle_deg"]) * .5)
	var view_range: float = float(stats["view_distance"])
	var ray_origin := global_position + Vector3.UP * .9
	var space := get_world_3d().direct_space_state
	var distance_samples := PackedFloat32Array()
	var sample_count := 32
	for i in sample_count + 1:
		var angle := lerpf(-half, half, float(i) / float(sample_count))
		var direction := Vector3(-sin(angle), 0, -cos(angle))
		var world_direction := global_transform.basis * direction
		var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + world_direction * view_range, KK.LAYER_WORLD)
		var result: Dictionary = space.intersect_ray(query)
		distance_samples.append(view_range if result.is_empty() else maxf(0.0, ray_origin.distance_to(result["position"]) - .08))
	var tint: Color = _cone_mat.albedo_color
	var base_alpha := .085 if state in [State.PATROL, State.RETURN] else .15
	if kind == KK.EnemyKind.INSPECTOR:
		base_alpha += .015
	_cone_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _cone_mat)
	for i in sample_count:
		var left_angle := lerpf(-half, half, float(i) / float(sample_count))
		var right_angle := lerpf(-half, half, float(i + 1) / float(sample_count))
		var left_direction := Vector3(-sin(left_angle), 0, -cos(left_angle))
		var right_direction := Vector3(-sin(right_angle), 0, -cos(right_angle))
		for step in 6:
			var t0 := float(step) / 6.0
			var t1 := float(step + 1) / 6.0
			var a := Vector3.UP * .035 + left_direction * distance_samples[i] * t0
			var b := Vector3.UP * .035 + right_direction * distance_samples[i + 1] * t0
			var c := Vector3.UP * .035 + right_direction * distance_samples[i + 1] * t1
			var d := Vector3.UP * .035 + left_direction * distance_samples[i] * t1
			var edge0 := pow(clampf(sin(PI * float(i) / float(sample_count)), 0.0, 1.0), .7)
			var edge1 := pow(clampf(sin(PI * float(i + 1) / float(sample_count)), 0.0, 1.0), .7)
			var near0 := smoothstep(0.0, .13, t0)
			var near1 := smoothstep(0.0, .13, t1)
			var fade0 := 1.0 - smoothstep(.55, 1.0, t0)
			var fade1 := 1.0 - smoothstep(.55, 1.0, t1)
			_cone_vertex(a, tint, base_alpha * near0 * fade0 * edge0)
			_cone_vertex(b, tint, base_alpha * near0 * fade0 * edge1)
			_cone_vertex(c, tint, base_alpha * near1 * fade1 * edge1)
			_cone_vertex(a, tint, base_alpha * near0 * fade0 * edge0)
			_cone_vertex(c, tint, base_alpha * near1 * fade1 * edge1)
			_cone_vertex(d, tint, base_alpha * near1 * fade1 * edge0)
	_cone_mesh.surface_end()


func _build_icons() -> void:
	_stars = Node3D.new()
	_stars.name = "DizzyStars"
	_stars.position.y = 2.38
	_stars.visible = false
	add_child(_stars)
	for i in 3:
		var star := Label3D.new()
		star.text = "✦"
		star.position = Vector3(cos(float(i) * TAU / 3.0) * 0.34, 0.06 * float(i % 2), sin(float(i) * TAU / 3.0) * 0.34)
		star.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		star.no_depth_test = true
		star.font_size = 36
		star.pixel_size = 0.003
		star.modulate = Color(1.0, 0.85, 0.2)
		_stars.add_child(star)
	_sleep_bubbles = Node3D.new()
	_sleep_bubbles.name = "SleepBubbles"
	_sleep_bubbles.visible = false
	add_child(_sleep_bubbles)
	for i in 3:
		var bubble := Label3D.new()
		bubble.text = "z"
		bubble.position = Vector3(0.18 + float(i) * 0.12, 1.55 + float(i) * 0.18, -0.15)
		bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bubble.no_depth_test = true
		bubble.font_size = 30 + i * 7
		bubble.pixel_size = 0.003
		bubble.modulate = Color(0.7, 0.86, 1.0, 0.8)
		_sleep_bubbles.add_child(bubble)
		var bubble_tween := create_tween().set_loops()
		bubble_tween.tween_property(bubble, "position:y", bubble.position.y + 0.13, 1.2 + float(i) * 0.2)
		bubble_tween.tween_property(bubble, "position:y", bubble.position.y, 1.2 + float(i) * 0.2)
	_icon = Label3D.new()
	_icon.name = "AlertIcon"
	_icon.position = Vector3(0, 2.55, 0)
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.no_depth_test = true
	_icon.outline_size = 10
	_icon.outline_modulate = Color(.015, .025, .065)
	_icon.font_size = 56
	_icon.pixel_size = 0.003
	_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_icon)
	_awareness_bar = Label3D.new()
	_awareness_bar.name = "AwarenessBar"
	_awareness_bar.position = Vector3(0, 2.37, 0)
	_awareness_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_awareness_bar.no_depth_test = true
	_awareness_bar.font_size = 22
	_awareness_bar.pixel_size = .003
	_awareness_bar.outline_size = 8
	_awareness_bar.outline_modulate = Color(.015, .025, .065)
	_awareness_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_awareness_bar)
	_debug_text = Label3D.new()
	_debug_text.name = "DebugState"
	_debug_text.position = Vector3(0, 2.85, 0)
	_debug_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_debug_text.no_depth_test = true
	_debug_text.font_size = 30
	_debug_text.pixel_size = 0.003
	_debug_text.modulate = Color(1, 1, 1)
	_debug_text.visible = false
	add_child(_debug_text)
	_update_icon(true)


func _update_icon(force := false) -> void:
	if _icon == null:
		return
	var next_text := ""
	var color := Color(1.0, 0.85, 0.15)
	match state:
		State.SUSPICIOUS, State.SEARCH:
			next_text = "?"
		State.CHASE, State.ATTACK:
			next_text = "!"
			color = Color(1.0, 0.19, 0.12)
		State.STUNNED:
			next_text = "★"
			color = Color(1.0, 0.83, 0.2)
		State.DOWN:
			next_text = "Zzz"
			color = Color(0.7, 0.85, 1.0)
	if next_text == "?":
		color.a = clampf((awareness - 0.25) / 0.75, 0.35, 1.0)
	_icon.modulate = color
	_awareness_bar.visible = state in [State.SUSPICIOUS, State.SEARCH, State.CHASE, State.ATTACK]
	if _awareness_bar.visible:
		var filled: int = clampi(ceili(awareness * 8.0), 0, 8)
		_awareness_bar.text = "▰".repeat(filled) + "▱".repeat(8 - filled)
		_awareness_bar.modulate = color
	if force or next_text != _icon_text:
		_icon_text = next_text
		_icon.text = next_text
		_icon.visible = not next_text.is_empty()
		if _icon.visible:
			_icon.scale = Vector3.ONE * 1.45
			var tween := create_tween()
			tween.tween_property(_icon, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animation(name: String, length: float, loop: bool) -> Animation:
	var resource := Animation.new()
	resource.length = length
	resource.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var library: AnimationLibrary = anim.get_animation_library("")
	library.add_animation(name, resource)
	return resource


func _key(animation: Animation, path: String, times: PackedFloat32Array, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(path))
	animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		animation.track_insert_key(track, times[i], values[i])


func _build_animations() -> void:
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	add_child(anim)
	var library := AnimationLibrary.new()
	anim.add_animation_library("", library)
	var idle := _animation("idle", 2.0, true)
	_key(idle, "Model:rotation", PackedFloat32Array([0.0, 1.0, 2.0]), [Vector3.ZERO, Vector3(0.015, 0, 0), Vector3.ZERO])
	var walk := _animation("walk", 0.7, true)
	_key(walk, "Model:position", PackedFloat32Array([0.0, .175, .35, .525, .7]), [Vector3.ZERO, Vector3(0, .025, 0), Vector3.ZERO, Vector3(0, .025, 0), Vector3.ZERO])
	_key(walk, "Model/LeftArm:rotation", PackedFloat32Array([0.0, 0.35, 0.7]), [Vector3(-0.42, 0, 0), Vector3(0.42, 0, 0), Vector3(-0.42, 0, 0)])
	_key(walk, "Model/RightArm:rotation", PackedFloat32Array([0.0, 0.35, 0.7]), [Vector3(0.42, 0, 0), Vector3(-0.42, 0, 0), Vector3(0.42, 0, 0)])
	_key(walk, "Model/LeftLeg:rotation", PackedFloat32Array([0.0, 0.35, 0.7]), [Vector3(0.3, 0, 0), Vector3(-0.3, 0, 0), Vector3(0.3, 0, 0)])
	_key(walk, "Model/RightLeg:rotation", PackedFloat32Array([0.0, 0.35, 0.7]), [Vector3(-0.3, 0, 0), Vector3(0.3, 0, 0), Vector3(-0.3, 0, 0)])
	var run := _animation("run", 0.42, true)
	_key(run, "Model:position", PackedFloat32Array([0.0, .105, .21, .315, .42]), [Vector3.ZERO, Vector3(0, .045, 0), Vector3.ZERO, Vector3(0, .045, 0), Vector3.ZERO])
	_key(run, "Model/LeftArm:rotation", PackedFloat32Array([0.0, 0.21, 0.42]), [Vector3(-0.85, 0, 0), Vector3(0.85, 0, 0), Vector3(-0.85, 0, 0)])
	_key(run, "Model/RightArm:rotation", PackedFloat32Array([0.0, 0.21, 0.42]), [Vector3(0.85, 0, 0), Vector3(-0.85, 0, 0), Vector3(0.85, 0, 0)])
	_key(run, "Model/LeftLeg:rotation", PackedFloat32Array([0.0, 0.21, 0.42]), [Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0), Vector3(0.62, 0, 0)])
	_key(run, "Model/RightLeg:rotation", PackedFloat32Array([0.0, 0.21, 0.42]), [Vector3(-0.62, 0, 0), Vector3(0.62, 0, 0), Vector3(-0.62, 0, 0)])
	var attack := _animation("attack", float(stats["attack_windup"]) + 0.35, false)
	var windup := float(stats["attack_windup"])
	_key(attack, "Model:rotation", PackedFloat32Array([0.0, windup, windup + .25]), [Vector3.ZERO, Vector3(-.12, 0, -.07), Vector3(.17, 0, .1)])
	_key(attack, "Model/RightArm:rotation", PackedFloat32Array([0.0, windup * 0.8, windup, windup + 0.25]), [Vector3.ZERO, Vector3(-2.2, 0, 0), Vector3(-2.2, 0, 0), Vector3(1.0, 0, 0)])
	if kind == KK.EnemyKind.INSPECTOR:
		_key(attack, "Model:position", PackedFloat32Array([0.0, windup, windup + 0.25]), [Vector3.ZERO, Vector3.ZERO, Vector3(0, 0, -0.28)])
	var stunned := _animation("stunned", 0.7, true)
	_key(stunned, "Model:rotation", PackedFloat32Array([0.0, 0.2, 0.45, 0.7]), [Vector3.ZERO, Vector3(0, 0, -0.18), Vector3(0, 0, 0.18), Vector3.ZERO])
	_key(stunned, "DizzyStars:rotation", PackedFloat32Array([0.0, 0.7]), [Vector3.ZERO, Vector3(0, TAU, 0)])
	var down := _animation("down", 0.55, false)
	_key(down, "Model:rotation", PackedFloat32Array([0.0, 0.55]), [Vector3.ZERO, Vector3(1.4, 0, 0)])
	_key(down, "Model:position", PackedFloat32Array([0.0, 0.55]), [Vector3.ZERO, Vector3(0, -0.65, 0)])
	var look := _animation("look_around", 2.0, true)
	_key(look, "Model/Head:rotation", PackedFloat32Array([0.0, 0.5, 1.0, 1.5, 2.0]), [Vector3.ZERO, Vector3(0, -0.7, 0), Vector3.ZERO, Vector3(0, 0.7, 0), Vector3.ZERO])
	_play("idle")
