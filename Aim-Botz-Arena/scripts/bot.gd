class_name Bot
extends CharacterBody3D
## Enemy bot driven by a small finite state machine:
## IDLE -> CHASE (navmesh pathing toward the player) -> ATTACK (strafe and
## shoot while it has line of sight) -> DEAD.
## In practice mode the bot is a static (or strafing) Aim Botz target.

signal died(bot: Bot, headshot: bool, cause: String, by_player: bool)

enum Type { STANDARD, HEAVY }
enum BotState { IDLE, CHASE, ATTACK, DEAD }

const GRAVITY := 18.0
const SIGHT_RANGE := 60.0
const THINK_INTERVAL := 0.15

var bot_type := Type.STANDARD
var bot_name := "BOT"
var practice_target := false
var practice_strafe := false
var player: Player
var sound_fx: SoundFX
var effects_root: Node3D

var max_health := 100.0
var health := 100.0
var state := BotState.IDLE

var _scale := 1.0
var _move_speed := 3.8
var _damage := 4.0
var _accuracy := 0.42
var _attack_range := 24.0
var _burst_size := 3
var _burst_gap := 0.13
var _burst_cooldown := 1.35
var _head_threshold := 1.47

var _visual: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _muzzle: Node3D
var _health_fill: Sprite3D
var _health_back: Sprite3D
var _name_label: Label3D
var _agent: NavigationAgent3D
var _rng := RandomNumberGenerator.new()

var _think_timer := 0.0
var _can_see_player := false
var _lost_sight_timer := 0.0
var _reaction_timer := 0.0
var _fire_timer := 0.0
var _burst_left := 0
var _strafe_dir := 1.0
var _strafe_timer := 0.0
var _stuck_timer := 0.0
var _unstick_timer := 0.0
var _unstick_dir := Vector3.ZERO
var _walk_cycle := 0.0
var _flinch := 0.0
var _home := Vector3.ZERO
var _practice_time := 0.0
var _last_cause := "AK-47"
var _last_by_player := true


func _ready() -> void:
	_rng.randomize()
	add_to_group("bots")
	add_to_group("damageable")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.4
	if bot_type == Type.HEAVY:
		_scale = 1.18
		max_health = 250.0
		_move_speed = 2.7
		_damage = 10.0
		_accuracy = 0.36
		_attack_range = 18.0
		_burst_size = 1
		_burst_cooldown = 1.25
	health = max_health
	_head_threshold = 1.47 * _scale
	_home = global_position
	_practice_time = _rng.randf() * TAU
	_build_collision()
	_build_visual()
	_build_health_bar()
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.7
	_agent.target_desired_distance = 1.0
	_agent.radius = 0.45
	_agent.height = 1.8 * _scale
	add_child(_agent)
	state = BotState.IDLE if practice_target else BotState.CHASE
	_reaction_timer = 0.6
	if player:
		_face_towards(player.global_position)


func is_alive() -> bool:
	return state != BotState.DEAD


func is_headshot_position(hit_position: Vector3) -> bool:
	return hit_position.y - global_position.y >= _head_threshold


func get_head_position() -> Vector3:
	return global_position + Vector3(0.0, 1.65 * _scale, 0.0)


func take_damage(amount: float, hit_position: Vector3, headshot: bool, source: Node) -> bool:
	if state == BotState.DEAD:
		return false
	health = maxf(health - amount, 0.0)
	_flinch = 1.0
	_update_health_bar()
	if source is Player:
		_last_cause = (source as Player).get_weapon_name()
		_last_by_player = true
	elif source is ExplosiveBarrel:
		_last_cause = "EXPLOSION"
		_last_by_player = (source as ExplosiveBarrel).last_attacker != null
	if effects_root:
		var away := (hit_position - get_head_position()).normalized()
		Fx.impact(effects_root, hit_position, away, true)
	if state == BotState.IDLE and not practice_target:
		state = BotState.CHASE
	if health <= 0.0:
		_die(headshot)
		return true
	return false


func _physics_process(delta: float) -> void:
	if state == BotState.DEAD:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -1.0)
	_flinch = move_toward(_flinch, 0.0, delta * 5.0)

	if practice_target:
		_practice_update(delta)
		return

	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = THINK_INTERVAL
		_think()

	var desired := Vector3.ZERO
	match state:
		BotState.IDLE:
			desired = Vector3.ZERO
		BotState.CHASE:
			desired = _chase_direction() * _move_speed
		BotState.ATTACK:
			desired = _attack_update(delta)
	desired += _separation() * 2.0
	if _unstick_timer > 0.0:
		_unstick_timer -= delta
		desired = _unstick_dir * _move_speed
	velocity.x = move_toward(velocity.x, desired.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z, 30.0 * delta)
	move_and_slide()
	_open_nearby_doors()
	_check_stuck(desired, delta)
	_animate(delta)


# --- Brain -------------------------------------------------------------------

func _think() -> void:
	if player == null or not player.alive:
		state = BotState.IDLE
		_can_see_player = false
		return
	_can_see_player = _has_line_of_sight()
	var distance := global_position.distance_to(player.global_position)
	if state == BotState.IDLE:
		state = BotState.CHASE
	if state == BotState.CHASE and _can_see_player and distance <= _attack_range:
		state = BotState.ATTACK
		_reaction_timer = _rng.randf_range(0.45, 0.8)
		_burst_left = 0
	elif state == BotState.ATTACK:
		if _can_see_player:
			_lost_sight_timer = 0.0
			if distance > _attack_range * 1.25:
				state = BotState.CHASE
		else:
			_lost_sight_timer += THINK_INTERVAL
			if _lost_sight_timer > 1.0:
				state = BotState.CHASE
	if state == BotState.CHASE:
		_agent.target_position = player.global_position


func _has_line_of_sight() -> bool:
	if global_position.distance_to(player.global_position) > SIGHT_RANGE:
		return false
	var eye := get_head_position()
	var space := get_world_3d().direct_space_state
	for target in [player.get_eye_position(), player.global_position + Vector3.UP * 1.0]:
		var query := PhysicsRayQueryParameters3D.create(eye, target, 1 | 2, [get_rid()])
		var result := space.intersect_ray(query)
		if not result.is_empty() and result["collider"] == player:
			return true
	return false


func _chase_direction() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var next := _agent.get_next_path_position()
	var to_next := next - global_position
	to_next.y = 0.0
	var direction: Vector3
	if to_next.length() < 0.05 or _agent.is_navigation_finished():
		direction = player.global_position - global_position
		direction.y = 0.0
	else:
		direction = to_next
	if direction.length() < 0.6:
		return Vector3.ZERO
	direction = direction.normalized()
	_face_direction(direction)
	return direction


func _attack_update(delta: float) -> Vector3:
	_face_towards(player.global_position)
	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		_strafe_timer = _rng.randf_range(0.7, 1.6)
		_strafe_dir = -_strafe_dir if _rng.randf() < 0.7 else _strafe_dir
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var forward := to_player.normalized()
	var side := forward.cross(Vector3.UP)
	var move := side * _strafe_dir * _move_speed * 0.45
	if to_player.length() > _attack_range * 0.8:
		move += forward * _move_speed * 0.5

	if _reaction_timer > 0.0:
		_reaction_timer -= delta
		return move
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _can_see_player:
		if _burst_left <= 0:
			_burst_left = _burst_size
		_shoot()
		_burst_left -= 1
		_fire_timer = _burst_gap if _burst_left > 0 else _burst_cooldown + _rng.randf_range(0.0, 0.4)
	return move


func _shoot() -> void:
	if _muzzle == null or player == null:
		return
	var from := _muzzle.global_position
	var target := player.global_position + Vector3.UP * 1.15
	var distance := from.distance_to(target)
	var player_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var chance := _accuracy - distance * 0.006 - clampf(player_speed / 8.0, 0.0, 1.0) * 0.18
	chance = clampf(chance, 0.08, 0.85)
	var hit := _rng.randf() < chance
	var end := target
	if not hit:
		var miss := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.4, 0.9), _rng.randf_range(-1.0, 1.0)).normalized()
		end = target + miss * _rng.randf_range(0.7, 1.4) + (target - from).normalized() * 6.0
	if sound_fx:
		sound_fx.play_at("bot_shot", from, -3.0, _rng.randf_range(0.92, 1.05))
	if effects_root:
		Fx.flash(effects_root, from, 0.12 * _scale)
		Fx.tracer(effects_root, from, end, Color(1.0, 0.55, 0.3), 0.03, 0.09)
	if hit:
		player.take_damage(_damage, target, false, self)


func _separation() -> Vector3:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("bots"):
		if other == self or not (other as Bot).is_alive():
			continue
		var offset := global_position - (other as Node3D).global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > 0.01 and distance < 1.6:
			push += offset / distance * (1.6 - distance)
	return push


func _check_stuck(desired: Vector3, delta: float) -> void:
	var wanted := Vector2(desired.x, desired.z).length()
	var actual := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	if wanted > 1.0 and actual < wanted * 0.25:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	if _stuck_timer > 0.8:
		_stuck_timer = 0.0
		_unstick_timer = 0.6
		var angle := _rng.randf_range(-PI, PI)
		_unstick_dir = Vector3(cos(angle), 0.0, sin(angle))


func _open_nearby_doors() -> void:
	for door in get_tree().get_nodes_in_group("doors"):
		var sliding := door as SlidingDoor
		if not sliding.is_open and sliding.global_position.distance_to(global_position) < 2.4:
			sliding.open()


func _practice_update(delta: float) -> void:
	_practice_time += delta
	var target_x := _home.x
	if practice_strafe:
		target_x += sin(_practice_time * 1.3) * 2.5
	velocity.x = (target_x - global_position.x) * 6.0
	velocity.z = (_home.z - global_position.z) * 6.0
	move_and_slide()
	if player:
		_face_towards(player.global_position)
	_animate(delta)


# --- Presentation -------------------------------------------------------------

func _face_towards(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0.0
	if direction.length() > 0.01:
		_face_direction(direction.normalized())


func _face_direction(direction: Vector3) -> void:
	if _visual:
		var yaw := atan2(-direction.x, -direction.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, yaw, 0.35)


func _animate(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	_walk_cycle += delta * speed * 2.6
	var swing := sin(_walk_cycle) * clampf(speed / 3.0, 0.0, 1.0) * 0.6
	if _left_leg:
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
	_visual.position.z = 0.0
	_visual.rotation.x = -_flinch * 0.18


func _build_collision() -> void:
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.34 * _scale
	body_shape.height = 1.45 * _scale
	var body_collision := CollisionShape3D.new()
	body_collision.shape = body_shape
	body_collision.position.y = 0.725 * _scale
	add_child(body_collision)
	var head_shape := SphereShape3D.new()
	head_shape.radius = 0.21 * _scale
	var head_collision := CollisionShape3D.new()
	head_collision.shape = head_shape
	head_collision.position.y = 1.65 * _scale
	add_child(head_collision)


func _build_visual() -> void:
	var heavy := bot_type == Type.HEAVY
	var cloth := Color(0.36, 0.1, 0.1) if heavy else Color(0.72, 0.6, 0.4)
	var vest := Color(0.18, 0.18, 0.2) if heavy else Color(0.36, 0.4, 0.26)
	var skin := Color(0.85, 0.66, 0.52)
	_visual = Node3D.new()
	_visual.name = "Visual"
	_visual.scale = Vector3.ONE * _scale
	add_child(_visual)
	_left_leg = _limb(Vector3(-0.12, 0.8, 0.0), Vector3(0.18, 0.8, 0.2), cloth.darkened(0.25))
	_right_leg = _limb(Vector3(0.12, 0.8, 0.0), Vector3(0.18, 0.8, 0.2), cloth.darkened(0.25))
	_part(Vector3(0.5, 0.64, 0.28), Vector3(0.0, 1.12, 0.0), cloth)
	_part(Vector3(0.54, 0.42, 0.32), Vector3(0.0, 1.18, 0.0), vest)
	var left_arm := _limb(Vector3(-0.32, 1.4, 0.0), Vector3(0.13, 0.55, 0.15), cloth)
	var right_arm := _limb(Vector3(0.32, 1.4, 0.0), Vector3(0.13, 0.55, 0.15), cloth)
	left_arm.rotation = Vector3(deg_to_rad(70.0), deg_to_rad(-25.0), 0.0)
	right_arm.rotation = Vector3(deg_to_rad(80.0), deg_to_rad(10.0), 0.0)
	# Gun held in front of the chest.
	_part(Vector3(0.08, 0.11, 0.62), Vector3(0.1, 1.3, -0.45), Color(0.12, 0.12, 0.13))
	_muzzle = Node3D.new()
	_muzzle.position = Vector3(0.1, 1.32, -0.8)
	_visual.add_child(_muzzle)
	# Head with helmet and visor (the visor shows which way the bot faces).
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	head.mesh = head_mesh
	head.material_override = _material(skin)
	head.position.y = 1.65
	_visual.add_child(head)
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.2
	helmet_mesh.height = 0.26
	helmet_mesh.is_hemisphere = true
	helmet.mesh = helmet_mesh
	helmet.material_override = _material(vest.darkened(0.2))
	helmet.position.y = 1.7
	_visual.add_child(helmet)
	_part(Vector3(0.26, 0.06, 0.06), Vector3(0.0, 1.66, -0.16), Color(0.05, 0.05, 0.05))
	if heavy:
		_part(Vector3(0.62, 0.18, 0.36), Vector3(0.0, 1.42, 0.0), Color(0.12, 0.12, 0.14))


func _limb(pivot: Vector3, size: Vector3, color: Color) -> Node3D:
	var joint := Node3D.new()
	joint.position = pivot
	_visual.add_child(joint)
	var mesh := BoxMesh.new()
	mesh.size = size
	var limb := MeshInstance3D.new()
	limb.mesh = mesh
	limb.material_override = _material(color)
	limb.position.y = -size.y * 0.5
	joint.add_child(limb)
	return joint


func _part(size: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _material(color)
	part.position = offset
	_visual.add_child(part)
	return part


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material


func _build_health_bar() -> void:
	var height := 2.2 * _scale
	_health_back = _bar_sprite(Color(0.05, 0.05, 0.05, 0.75), height, 0)
	_health_fill = _bar_sprite(Color(1.0, 1.0, 1.0), height, 1)
	_name_label = Label3D.new()
	_name_label.text = bot_name
	_name_label.font_size = 32
	_name_label.pixel_size = 0.008
	_name_label.outline_size = 8
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.modulate = Color(1.0, 0.45, 0.4) if bot_type == Type.HEAVY else Color(1.0, 0.92, 0.8)
	_name_label.position.y = height + 0.2
	add_child(_name_label)
	_update_health_bar()


func _bar_sprite(color: Color, height: float, priority: int) -> Sprite3D:
	var image := Image.create_empty(64, 8, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var sprite := Sprite3D.new()
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.012
	sprite.centered = false
	sprite.offset = Vector2(-32.0, -4.0)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, 0.0, 64.0, 8.0)
	sprite.render_priority = priority
	sprite.shaded = false
	sprite.position.y = height
	add_child(sprite)
	return sprite


func _update_health_bar() -> void:
	if _health_fill == null:
		return
	var ratio := clampf(health / max_health, 0.0, 1.0)
	_health_fill.region_rect = Rect2(0.0, 0.0, maxf(64.0 * ratio, 0.01), 8.0)
	_health_fill.modulate = Color(0.95, 0.2, 0.15).lerp(Color(0.3, 0.95, 0.3), ratio)


func _die(headshot: bool) -> void:
	state = BotState.DEAD
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 1
	remove_from_group("damageable")
	_health_back.visible = false
	_health_fill.visible = false
	_name_label.visible = false
	died.emit(self, headshot, _last_cause, _last_by_player)
	var tween := create_tween()
	tween.tween_property(_visual, "rotation:x", deg_to_rad(88.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_visual, "position:y", 0.2, 0.45)
	tween.tween_interval(2.0)
	tween.tween_property(_visual, "scale", Vector3(_scale, 0.01, _scale), 0.35)
	tween.tween_callback(queue_free)
