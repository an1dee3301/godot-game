class_name Player
extends CharacterBody3D
## First-person controller: WASD + mouse look, jump, gravity, sprint,
## aim-down-sights, two hitscan weapons with magazines and reloads,
## recoil and spread, footsteps, health and death.

signal health_changed(current: float, maximum: float)
signal ammo_changed(mag: int, reserve: int, weapon_name: String)
signal damaged(amount: float, source_position: Vector3)
signal died
signal shot_fired
signal hit_landed(target: Node, headshot: bool, killed: bool)
signal interact_prompt_changed(text: String)

const MAX_HEALTH := 100.0
const WALK_SPEED := 5.2
const SPRINT_SPEED := 8.4
const ADS_SPEED := 3.1
const GROUND_ACCEL := 60.0
const AIR_ACCEL := 10.0
const JUMP_VELOCITY := 5.6
const GRAVITY := 16.0
const EYE_HEIGHT := 1.62
const DEFAULT_FOV := 80.0
const ADS_FOV := 52.0
const BASE_SENSITIVITY := 0.0022
const STEP_DISTANCE := 2.3
const INTERACT_RANGE := 3.2


class Weapon:
	var name := ""
	var damage := 0.0
	var headshot_multiplier := 4.0
	var fire_interval := 0.1
	var automatic := true
	var mag_size := 30
	var mag := 30
	var reserve := 90
	var max_reserve := 90
	var reload_time := 2.3
	var base_spread := 0.3
	var move_spread := 3.5
	var bloom_per_shot := 0.55
	var recoil := 0.9
	var max_range := 150.0
	var sound := "rifle"


var input_enabled := false
var infinite_reserve := false
var invulnerable := false
var mouse_sensitivity := 1.0
var health := MAX_HEALTH
var alive := true
var weapons: Array[Weapon] = []
var current_weapon := 0
var reloading := false
var aiming := false
var sprinting := false
var sound_fx: SoundFX
var effects_root: Node3D

var _head: Node3D
var _camera: Camera3D
var _view_root: Node3D
var _gun_models: Array[Node3D] = []
var _muzzles: Array[Node3D] = []
var _flash_meshes: Array[MeshInstance3D] = []
var _flash_light: OmniLight3D
var _rng := RandomNumberGenerator.new()

var _fire_cooldown := 0.0
var _reload_timer := 0.0
var _reload_in_played := false
var _switch_timer := 0.0
var _bloom := 0.0
var _recoil_pitch := 0.0
var _recoil_yaw := 0.0
var _since_shot := 1.0
var _kick := 0.0
var _flash_timer := 0.0
var _bob_time := 0.0
var _step_accumulator := 0.0
var _was_on_floor := true
var _fall_speed := 0.0
var _shake := 0.0
var _sway := Vector2.ZERO
var _ads_blend := 0.0
var _prompt := ""
var _prompt_timer := 0.0
var _trigger_released := true


func _ready() -> void:
	_rng.randomize()
	add_to_group("player")
	add_to_group("damageable")
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(46.0)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position.y = EYE_HEIGHT
	add_child(_head)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = DEFAULT_FOV
	_camera.near = 0.03
	_camera.far = 400.0
	_head.add_child(_camera)
	_view_root = Node3D.new()
	_view_root.name = "ViewModel"
	_camera.add_child(_view_root)
	_flash_light = OmniLight3D.new()
	_flash_light.light_color = Color(1.0, 0.75, 0.4)
	_flash_light.light_energy = 0.0
	_flash_light.omni_range = 6.0
	_camera.add_child(_flash_light)
	_flash_light.position = Vector3(0.2, -0.1, -0.9)

	weapons = [_make_rifle(), _make_pistol()]
	_gun_models = [_build_rifle_model(), _build_pistol_model()]
	_select_model(0)


# --- Public API ----------------------------------------------------------------

func get_camera() -> Camera3D:
	return _camera


func get_eye_position() -> Vector3:
	return _head.global_position


func get_weapon() -> Weapon:
	return weapons[current_weapon]


func get_weapon_name() -> String:
	return weapons[current_weapon].name


func get_reload_progress() -> float:
	if not reloading:
		return 0.0
	return 1.0 - _reload_timer / weapons[current_weapon].reload_time


## Current cone half-angle in degrees (also drives the dynamic crosshair).
func get_spread_degrees() -> float:
	var weapon := weapons[current_weapon]
	var horizontal := Vector2(velocity.x, velocity.z).length()
	var spread := weapon.base_spread + _bloom
	spread += weapon.move_spread * clampf(horizontal / WALK_SPEED, 0.0, 1.4) * (0.35 if aiming else 1.0)
	if not is_on_floor():
		spread += 4.0
	if aiming:
		spread *= 0.45
	return spread


func reset(spawn: Transform3D) -> void:
	global_transform = Transform3D(Basis.IDENTITY, spawn.origin)
	rotation.y = spawn.basis.get_euler().y
	velocity = Vector3.ZERO
	health = MAX_HEALTH
	alive = true
	_head.position = Vector3(0.0, EYE_HEIGHT, 0.0)
	_head.rotation = Vector3.ZERO
	_camera.rotation = Vector3.ZERO
	_camera.fov = DEFAULT_FOV
	weapons = [_make_rifle(), _make_pistol()]
	current_weapon = 0
	reloading = false
	aiming = false
	_fire_cooldown = 0.0
	_switch_timer = 0.0
	_bloom = 0.0
	_recoil_pitch = 0.0
	_recoil_yaw = 0.0
	_shake = 0.0
	_ads_blend = 0.0
	_select_model(0)
	_view_root.visible = true
	health_changed.emit(health, MAX_HEALTH)
	_emit_ammo()


func heal(amount: float) -> bool:
	if not alive or health >= MAX_HEALTH:
		return false
	health = minf(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	return true


func add_ammo() -> bool:
	var changed := false
	for weapon in weapons:
		if weapon.reserve < weapon.max_reserve:
			weapon.reserve = mini(weapon.reserve + weapon.mag_size * 2, weapon.max_reserve)
			changed = true
	if changed:
		_emit_ammo()
	return changed


func take_damage(amount: float, _hit_position: Vector3, _headshot: bool, source: Node) -> bool:
	if not alive or invulnerable:
		return false
	health = maxf(health - amount, 0.0)
	_shake = minf(_shake + amount * 0.012, 0.35)
	var source_position := global_position
	if source is Node3D:
		source_position = (source as Node3D).global_position
	health_changed.emit(health, MAX_HEALTH)
	damaged.emit(amount, source_position)
	if sound_fx:
		sound_fx.play("hurt", -4.0, _rng.randf_range(0.9, 1.1))
	if health <= 0.0:
		_die()
		return true
	return false


func switch_weapon(index: int) -> void:
	if index == current_weapon or index < 0 or index >= weapons.size() or not alive:
		return
	reloading = false
	current_weapon = index
	_switch_timer = 0.45
	_bloom = 0.0
	_select_model(index)
	if sound_fx:
		sound_fx.play("switch", -6.0)
	_emit_ammo()


func start_reload() -> bool:
	var weapon := weapons[current_weapon]
	if reloading or not alive or _switch_timer > 0.0:
		return false
	if weapon.mag >= weapon.mag_size or (weapon.reserve <= 0 and not infinite_reserve):
		return false
	reloading = true
	_reload_timer = weapon.reload_time
	_reload_in_played = false
	if sound_fx:
		sound_fx.play("reload_out", -3.0)
	return true


## Fires one shot if the weapon is ready. Returns true when a bullet left the gun.
func try_fire() -> bool:
	if not alive or reloading or _switch_timer > 0.0 or _fire_cooldown > 0.0:
		return false
	var weapon := weapons[current_weapon]
	if weapon.mag <= 0:
		_fire_cooldown = 0.25
		if sound_fx:
			sound_fx.play("dry_fire", -4.0)
		if weapon.reserve > 0 or infinite_reserve:
			start_reload()
		else:
			_show_prompt("Out of ammo - find an ammo crate", 1.5)
		return false
	weapon.mag -= 1
	_fire_cooldown = weapon.fire_interval
	_since_shot = 0.0
	_fire_ray(weapon)
	_bloom = minf(_bloom + weapon.bloom_per_shot, 6.0)
	_recoil_pitch += deg_to_rad(weapon.recoil)
	_recoil_yaw += deg_to_rad(_rng.randf_range(-0.35, 0.35) * weapon.recoil)
	_kick = 1.0
	_flash_timer = 0.05
	if sound_fx:
		sound_fx.play(weapon.sound, -2.0, _rng.randf_range(0.95, 1.05))
	shot_fired.emit()
	_emit_ammo()
	return true


# --- Input & frame update -------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var scale := BASE_SENSITIVITY * mouse_sensitivity * (_camera.fov / DEFAULT_FOV)
		rotate_y(-motion.relative.x * scale)
		_head.rotation.x = clampf(_head.rotation.x - motion.relative.y * scale, deg_to_rad(-88.0), deg_to_rad(88.0))
		_sway += motion.relative * 0.0004
	elif event.is_action_pressed("reload"):
		start_reload()
	elif event.is_action_pressed("weapon_1"):
		switch_weapon(0)
	elif event.is_action_pressed("weapon_2"):
		switch_weapon(1)
	elif event.is_action_pressed("weapon_next") or event.is_action_pressed("weapon_prev"):
		switch_weapon((current_weapon + 1) % weapons.size())
	elif event.is_action_pressed("interact"):
		var target := _interact_target()
		if target:
			target.interact(self)


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_switch_timer = maxf(_switch_timer - delta, 0.0)
	_since_shot += delta
	_bloom = move_toward(_bloom, 0.0, delta * (3.0 if _since_shot > 0.15 else 0.6))
	_update_reload(delta)
	_update_movement(delta)
	_update_combat_input()
	_update_interact_prompt(delta)


func _process(delta: float) -> void:
	_update_camera(delta)
	_update_view_model(delta)


func _update_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	var wants_jump := false
	var wants_sprint := false
	if input_enabled and alive:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		wants_jump = Input.is_action_just_pressed("jump")
		wants_sprint = Input.is_action_pressed("sprint")
	var wish := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y))
	wish.y = 0.0
	if wish.length() > 1.0:
		wish = wish.normalized()
	sprinting = wants_sprint and input_dir.y < -0.1 and not aiming
	var speed := ADS_SPEED if aiming else (SPRINT_SPEED if sprinting else WALK_SPEED)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var on_floor := is_on_floor()
	if on_floor:
		horizontal = horizontal.move_toward(wish * speed, GROUND_ACCEL * delta)
		if wants_jump:
			velocity.y = JUMP_VELOCITY
			_bloom += 1.5
	else:
		velocity.y -= GRAVITY * delta
		_fall_speed = maxf(_fall_speed, -velocity.y)
		if wish.length() > 0.01:
			horizontal = horizontal.move_toward(wish * maxf(speed, horizontal.length()), AIR_ACCEL * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	var landed := is_on_floor()
	if landed and not _was_on_floor:
		if _fall_speed > 4.0 and sound_fx:
			sound_fx.play("land", -6.0)
		_fall_speed = 0.0
	_was_on_floor = landed
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	if landed and ground_speed > 1.5:
		_bob_time += delta * ground_speed * 1.25
		_step_accumulator += ground_speed * delta
		var stride := STEP_DISTANCE * (1.25 if sprinting else 1.0)
		if _step_accumulator >= stride:
			_step_accumulator = 0.0
			if sound_fx and not aiming:
				sound_fx.play("footstep", -2.0 if sprinting else -7.0, _rng.randf_range(0.85, 1.15))


func _update_combat_input() -> void:
	if not input_enabled or not alive:
		aiming = false
		return
	aiming = Input.is_action_pressed("aim") and not reloading and _switch_timer <= 0.0
	var weapon := weapons[current_weapon]
	var pressed := Input.is_action_pressed("shoot")
	if pressed and (weapon.automatic or _trigger_released):
		try_fire()
	_trigger_released = not pressed


func _update_reload(delta: float) -> void:
	if not reloading:
		return
	var weapon := weapons[current_weapon]
	_reload_timer -= delta
	if not _reload_in_played and _reload_timer <= weapon.reload_time * 0.35:
		_reload_in_played = true
		if sound_fx:
			sound_fx.play("reload_in", -3.0)
	if _reload_timer <= 0.0:
		reloading = false
		var needed := weapon.mag_size - weapon.mag
		var taken := needed if infinite_reserve else mini(needed, weapon.reserve)
		weapon.mag += taken
		if not infinite_reserve:
			weapon.reserve -= taken
		_emit_ammo()


func _update_interact_prompt(delta: float) -> void:
	var text := ""
	if _prompt_timer > 0.0:
		_prompt_timer -= delta
		text = _prompt
	elif input_enabled and alive:
		var weapon := weapons[current_weapon]
		var target := _interact_target()
		if target:
			text = target.get_interact_text()
		elif weapon.mag == 0 and not reloading:
			text = "Press R to reload" if (weapon.reserve > 0 or infinite_reserve) else "Out of ammo - find an ammo crate"
	if text != _prompt or _prompt_timer <= 0.0:
		if text != _prompt:
			_prompt = text
			interact_prompt_changed.emit(text)


func _show_prompt(text: String, duration: float) -> void:
	_prompt = text
	_prompt_timer = duration
	interact_prompt_changed.emit(text)


func _interact_target() -> Node:
	if not is_inside_tree():
		return null
	var from := _camera.global_position
	var to := from - _camera.global_transform.basis.z * INTERACT_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Object = result["collider"]
	if collider and collider.has_method("interact"):
		return collider as Node
	return null


func _update_camera(delta: float) -> void:
	_ads_blend = move_toward(_ads_blend, 1.0 if aiming else 0.0, delta * 7.0)
	var target_fov := lerpf(DEFAULT_FOV, ADS_FOV, _ads_blend)
	if sprinting and not aiming:
		target_fov += 6.0
	_camera.fov = lerpf(_camera.fov, target_fov, minf(delta * 12.0, 1.0))
	# Recoil climbs while spraying and recovers when the trigger is released.
	var recover := 9.0 if _since_shot > 0.12 else 1.5
	_recoil_pitch = lerpf(_recoil_pitch, 0.0, minf(delta * recover, 1.0))
	_recoil_yaw = lerpf(_recoil_yaw, 0.0, minf(delta * recover, 1.0))
	_shake = move_toward(_shake, 0.0, delta * 1.2)
	var shake_offset := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * _shake * 0.05
	_camera.rotation = Vector3(_recoil_pitch + shake_offset.x, _recoil_yaw + shake_offset.y, _camera.rotation.z)


func _update_view_model(delta: float) -> void:
	if _gun_models.is_empty():
		return
	_kick = move_toward(_kick, 0.0, delta * 10.0)
	_sway = _sway.lerp(Vector2.ZERO, minf(delta * 8.0, 1.0))
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	var flash_on := _flash_timer > 0.0
	for index in _flash_meshes.size():
		_flash_meshes[index].visible = flash_on and index == current_weapon
		if flash_on:
			_flash_meshes[index].rotation.z = _rng.randf() * TAU
	_flash_light.light_energy = 3.0 if flash_on else 0.0

	var hip := Vector3(0.17, -0.16, -0.36) if current_weapon == 0 else Vector3(0.15, -0.14, -0.36)
	var ads := Vector3(0.0, -0.085, -0.3)
	var offset := hip.lerp(ads, _ads_blend)
	var moving := Vector2(velocity.x, velocity.z).length() > 1.5 and is_on_floor()
	var bob_amount := (0.012 if not sprinting else 0.03) * (1.0 - _ads_blend * 0.8)
	if moving:
		offset += Vector3(cos(_bob_time) * bob_amount, absf(sin(_bob_time)) * bob_amount, 0.0)
	offset += Vector3(-_sway.x, _sway.y, 0.0).limit_length(0.04)
	offset.z += _kick * 0.06
	var tilt := Vector3(_kick * 0.08, 0.0, 0.0)
	if reloading:
		var progress := get_reload_progress()
		var dip := sin(progress * PI)
		offset.y -= dip * 0.12
		tilt.x -= dip * 0.6
		tilt.z += dip * 0.4
	if _switch_timer > 0.0:
		offset.y -= _switch_timer * 0.5
	if sprinting and not aiming:
		tilt.y += 0.35
		tilt.x -= 0.15
	_view_root.position = _view_root.position.lerp(offset, minf(delta * 18.0, 1.0))
	_view_root.rotation = _view_root.rotation.lerp(tilt, minf(delta * 14.0, 1.0))


# --- Shooting ------------------------------------------------------------------

func _fire_ray(weapon: Weapon) -> void:
	var basis := _camera.global_transform.basis
	var forward := -basis.z
	var spread := deg_to_rad(get_spread_degrees())
	if spread > 0.0:
		var angle := _rng.randf() * TAU
		var radius := sqrt(_rng.randf()) * spread
		forward = (forward + basis.x * cos(angle) * tan(radius) + basis.y * sin(angle) * tan(radius)).normalized()
	var from := _camera.global_position
	var to := from + forward * weapon.max_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 4, [get_rid()])
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var muzzle := _muzzles[current_weapon].global_position
	var end := to
	if not result.is_empty():
		end = result["position"]
		var collider: Object = result["collider"]
		var normal: Vector3 = result["normal"]
		if collider is Bot:
			var bot := collider as Bot
			var headshot := bot.is_headshot_position(end)
			var amount := weapon.damage * (weapon.headshot_multiplier if headshot else 1.0)
			var killed := bot.take_damage(amount, end, headshot, self)
			if sound_fx:
				sound_fx.play("headshot" if headshot else "hit", -4.0 if headshot else -8.0)
			hit_landed.emit(bot, headshot, killed)
		else:
			if collider and collider.has_method("take_damage"):
				collider.take_damage(weapon.damage, end, false, self)
			Fx.impact(effects_root, end, normal, false)
	if effects_root:
		Fx.tracer(effects_root, muzzle, end, Color(1.0, 0.85, 0.45))


func _die() -> void:
	alive = false
	reloading = false
	aiming = false
	_view_root.visible = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_head, "position:y", 0.35, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_head, "rotation:z", 0.6, 0.7)
	died.emit()


func _emit_ammo() -> void:
	var weapon := weapons[current_weapon]
	ammo_changed.emit(weapon.mag, weapon.reserve, weapon.name)


# --- Weapons -------------------------------------------------------------------

func _make_rifle() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "AK-47"
	weapon.damage = 30.0
	weapon.fire_interval = 0.1
	weapon.automatic = true
	weapon.mag_size = 30
	weapon.mag = 30
	weapon.reserve = 90
	weapon.max_reserve = 120
	weapon.reload_time = 2.4
	weapon.base_spread = 0.25
	weapon.move_spread = 3.5
	weapon.bloom_per_shot = 0.45
	weapon.recoil = 0.85
	weapon.sound = "rifle"
	return weapon


func _make_pistol() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "DESERT EAGLE"
	weapon.damage = 55.0
	weapon.fire_interval = 0.32
	weapon.automatic = false
	weapon.mag_size = 7
	weapon.mag = 7
	weapon.reserve = 35
	weapon.max_reserve = 42
	weapon.reload_time = 2.0
	weapon.base_spread = 0.2
	weapon.move_spread = 3.0
	weapon.bloom_per_shot = 1.6
	weapon.recoil = 2.4
	weapon.sound = "pistol"
	return weapon


func _select_model(index: int) -> void:
	for model_index in _gun_models.size():
		_gun_models[model_index].visible = model_index == index


func _gun_part(parent: Node3D, size: Vector3, offset: Vector3, color: Color, metallic := 0.5, rotation_x := 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.45
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.position = offset
	part.rotation.x = rotation_x
	parent.add_child(part)


func _add_muzzle(model: Node3D, muzzle_position: Vector3) -> void:
	var muzzle := Node3D.new()
	muzzle.position = muzzle_position
	model.add_child(muzzle)
	_muzzles.append(muzzle)
	var flash_mesh := QuadMesh.new()
	flash_mesh.size = Vector2(0.16, 0.16)
	var flash := MeshInstance3D.new()
	flash.mesh = flash_mesh
	var material := Fx.unshaded(Color(1.0, 0.78, 0.35, 0.95), 4.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	flash.material_override = material
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.visible = false
	muzzle.add_child(flash)
	var side := MeshInstance3D.new()
	var side_mesh := QuadMesh.new()
	side_mesh.size = Vector2(0.07, 0.22)
	side.mesh = side_mesh
	side.material_override = material
	side.rotation.x = -PI * 0.5
	side.position.z = -0.08
	flash.add_child(side)
	_flash_meshes.append(flash)


func _build_rifle_model() -> Node3D:
	var model := Node3D.new()
	model.name = "Rifle"
	model.scale = Vector3.ONE * 0.62
	_view_root.add_child(model)
	var metal := Color(0.13, 0.13, 0.14)
	var wood := Color(0.48, 0.27, 0.12)
	_gun_part(model, Vector3(0.06, 0.08, 0.42), Vector3(0.0, 0.0, -0.05), metal)
	_gun_part(model, Vector3(0.025, 0.025, 0.34), Vector3(0.0, 0.02, -0.42), metal)
	_gun_part(model, Vector3(0.055, 0.06, 0.22), Vector3(0.0, -0.005, -0.33), wood, 0.0)
	_gun_part(model, Vector3(0.045, 0.16, 0.06), Vector3(0.0, -0.11, -0.1), metal, 0.5, 0.35)
	_gun_part(model, Vector3(0.04, 0.11, 0.05), Vector3(0.0, -0.08, 0.08), wood, 0.0, -0.3)
	_gun_part(model, Vector3(0.05, 0.08, 0.22), Vector3(0.0, -0.03, 0.25), wood, 0.0)
	_gun_part(model, Vector3(0.012, 0.03, 0.012), Vector3(0.0, 0.05, -0.55), Color(1.0, 0.5, 0.1), 0.0)
	_add_muzzle(model, Vector3(0.0, 0.02, -0.61))
	return model


func _build_pistol_model() -> Node3D:
	var model := Node3D.new()
	model.name = "Pistol"
	model.scale = Vector3.ONE * 0.75
	_view_root.add_child(model)
	var metal := Color(0.55, 0.56, 0.58)
	var grip := Color(0.12, 0.12, 0.12)
	_gun_part(model, Vector3(0.05, 0.065, 0.28), Vector3(0.0, 0.0, -0.08), metal, 0.8)
	_gun_part(model, Vector3(0.045, 0.14, 0.06), Vector3(0.0, -0.09, 0.03), grip, 0.1, -0.25)
	_gun_part(model, Vector3(0.012, 0.025, 0.012), Vector3(0.0, 0.04, -0.2), Color(1.0, 0.5, 0.1), 0.0)
	_add_muzzle(model, Vector3(0.0, 0.0, -0.24))
	return model
