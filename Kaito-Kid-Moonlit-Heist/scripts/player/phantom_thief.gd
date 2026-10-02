class_name PhantomThief
extends CharacterBody3D
## Kaito Kid: camera-relative movement, stealth, cards, smoke, and a skinned human costume.

signal health_changed(hp: float, max_hp: float)
signal damaged(amount: float)
signal died
signal smoke_changed(count: int)
signal card_fired
signal smoke_thrown(position: Vector3)
signal footstep(running: bool)
signal landed

var hp: float = KK.PLAYER_MAX_HP
var max_hp: float = KK.PLAYER_MAX_HP
var smoke_bombs: int = KK.PLAYER_START_SMOKE
var is_dead := false
var controls_enabled := false
var camera_rig: ThirdPersonCamera
var effects_root: Node3D
var anim: AnimationPlayer
var use_scripted_input := false
var scripted_input := Vector2.ZERO

var _collider: CollisionShape3D
var _model: Node3D
var _hat: Node3D
var _right_hand: Node3D
var _shot_anim: AnimationPlayer
var _stand_check: ShapeCast3D
var _cape_material: ShaderMaterial
var _cape_lining_material: ShaderMaterial
var _crouching := false
var _sprinting := false
var _coyote := 0.0
var _jump_buffer := 0.0
var _air_time := 0.0
var _landing_time := 0.0
var _jump_start_time := 0.0
var _step_time := 0.0
var _fire_time := 0.0
var _gun_hide_time := 0.0
var _invuln := 0.0
var _action_time := 0.0
var _flash_time := 0.0


func _ready() -> void:
	add_to_group(KK.GROUP_PLAYER)
	collision_layer = KK.LAYER_PLAYER
	collision_mask = KK.LAYER_WORLD | KK.LAYER_GLASS | KK.LAYER_ENEMY
	floor_snap_length = 0.18
	_collider = CollisionShape3D.new()
	_collider.position.y = 0.9
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	_collider.shape = capsule
	add_child(_collider)
	_stand_check = ShapeCast3D.new()
	var stand_shape := capsule.duplicate() as CapsuleShape3D
	stand_shape.height = 1.74
	_stand_check.shape = stand_shape
	_stand_check.position.y = 0.91
	_stand_check.target_position = Vector3.ZERO
	_stand_check.collision_mask = collision_mask
	_stand_check.add_exception(self)
	add_child(_stand_check)
	_build_model()
	anim.play("idle")


func _build_model() -> void:
	var rig := HumanRig.new()
	rig.name = "Model"
	add_child(rig)
	rig.build_vroid(KaitoVroid.MODEL, {"idle": "Idle", "walk": "Walk_Formal", "run": "Sprint",
		"crouch_idle": "Crouch_Idle", "crouch_walk": "Crouch_Fwd",
		"jump": "Jump_Start", "fall": "Jump", "land": "Jump_Land", "throw": "Pistol_Shoot",
		"hurt": "Hit_Chest", "death": "Death01"},
		["idle", "walk", "run", "crouch_idle", "crouch_walk", "fall"])
	_model = rig
	anim = rig.anim
	var costume: Dictionary = KaitoVroid.build(rig)
	_hat = costume["hat"]
	_right_hand = costume["hand"]
	_cape_material = costume["cape_material"]
	_cape_lining_material = costume["lining_material"]
	# A second player writes only upper-body tracks, after the locomotion player.
	# This leaves the legs running while the card-gun recoil plays.
	_shot_anim = AnimationPlayer.new()
	_shot_anim.name = "UpperBodyAction"
	anim.get_parent().add_child(_shot_anim)
	var shot := (anim.get_animation("throw") as Animation).duplicate(true) as Animation
	for track in range(shot.get_track_count() - 1, -1, -1):
		var path := String(shot.track_get_path(track))
		var upper := path.contains(":Chest") or path.contains(":UpperChest") \
			or path.contains(":Neck") or path.contains(":Head") or path.contains(":Right")
		if not upper or path.contains("UpperLeg") or path.contains("LowerLeg") or path.contains("Foot"):
			shot.remove_track(track)
	var shot_library := AnimationLibrary.new()
	shot_library.add_animation("throw", shot)
	_shot_anim.add_animation_library("", shot_library)
	anim.set_blend_time("idle", "walk", 0.18)
	anim.set_blend_time("walk", "run", 0.2)
	anim.set_blend_time("run", "walk", 0.17)
	anim.set_blend_time("walk", "idle", 0.2)


func _physics_process(delta: float) -> void:
	_fire_time = maxf(0.0, _fire_time - delta)
	_gun_hide_time = maxf(0.0, _gun_hide_time - delta)
	if _gun_hide_time <= 0.0:
		_right_hand.visible = false
	_invuln = maxf(0.0, _invuln - delta)
	_action_time = maxf(0.0, _action_time - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_landing_time = maxf(0.0, _landing_time - delta)
	_jump_start_time = maxf(0.0, _jump_start_time - delta)
	_flash_time += delta
	if _invuln > 0.0:
		_model.visible = fmod(_flash_time, 0.11) < 0.065
	else:
		_model.visible = true
	var was_grounded := is_on_floor()
	_coyote = 0.12 if was_grounded else maxf(0.0, _coyote - delta)
	var input := Vector2.ZERO
	if controls_enabled and not is_dead:
		input = scripted_input if use_scripted_input else Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		input = input.limit_length()
		var wants_crouch := Input.is_action_pressed("crouch") and not use_scripted_input
		_crouching = wants_crouch or (_crouching and not _can_stand())
		_sprinting = not _crouching and input.length() > 0.15 and Input.is_action_pressed("sprint") and not use_scripted_input
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = 0.14
		if _jump_buffer > 0.0 and _coyote > 0.0 and not _crouching:
			velocity.y = KK.PLAYER_JUMP_VELOCITY
			_coyote = 0.0
			_jump_buffer = 0.0
			_jump_start_time = 0.16
		if Input.is_action_just_pressed("fire"):
			fire_card()
		if Input.is_action_just_pressed("smoke"):
			throw_smoke()
		if Input.is_action_just_pressed("interact"):
			try_interact()
	else:
		_crouching = false
		_sprinting = false
	var capsule := _collider.shape as CapsuleShape3D
	capsule.height = lerpf(capsule.height, 1.2 if _crouching else 1.8, minf(1.0, delta * 12.0))
	_collider.position.y = capsule.height * 0.5
	var yaw := camera_rig.get_yaw() if camera_rig else rotation.y
	var direction := (Basis(Vector3.UP, yaw) * Vector3(input.x, 0.0, -input.y)).normalized()
	var speed := KK.PLAYER_CROUCH_SPEED if _crouching else (KK.PLAYER_SPRINT_SPEED if _sprinting else KK.PLAYER_WALK_SPEED)
	var desired := direction * speed
	var rate := 24.0 if direction.length() > 0.0 else 34.0
	if not was_grounded:
		rate *= 0.38
	velocity.x = move_toward(velocity.x, desired.x, rate * delta)
	velocity.z = move_toward(velocity.z, desired.z, rate * delta)
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-12.0 * delta))
	var turn_amount := wrapf(atan2(-direction.x, -direction.z) - rotation.y, -PI, PI) if direction.length() > 0.1 else 0.0
	_model.rotation.z = lerpf(_model.rotation.z, clampf(-turn_amount * 0.09, -0.09, 0.09), 1.0 - exp(-9.0 * delta))
	var aim_twist := 0.0
	if _shot_anim.is_playing() and camera_rig:
		aim_twist = clampf(wrapf(camera_rig.get_yaw() - rotation.y, -PI, PI), -0.45, 0.45)
	_model.rotation.y = lerp_angle(_model.rotation.y, aim_twist, 1.0 - exp(-15.0 * delta))
	if not is_on_floor():
		velocity.y -= 14.0 * delta
		_air_time += delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	if not was_grounded and is_on_floor():
		_landing_time = 0.19
		if camera_rig:
			camera_rig.land_dip(minf(1.0, _air_time / 0.5))
		if _air_time > 0.4:
			landed.emit()
			KK.emit_noise(get_tree(), global_position, KK.NOISE_LAND)
		_air_time = 0.0
		if _jump_buffer > 0.0 and not _crouching:
			velocity.y = KK.PLAYER_JUMP_VELOCITY
			_jump_buffer = 0.0
			_coyote = 0.0
			_jump_start_time = 0.16
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and planar_speed > 0.5 and not is_dead:
		_step_time += delta
		var cadence := 0.28 if _sprinting else (0.48 if _crouching else 0.4)
		if _step_time >= cadence:
			_step_time = 0.0
			footstep.emit(_sprinting)
			if not _crouching:
				KK.emit_noise(get_tree(), global_position, KK.NOISE_SPRINT_STEP if _sprinting else KK.NOISE_WALK_STEP)
	else:
		_step_time = 0.0
	_cape_material.set_shader_parameter("speed", clampf(planar_speed / KK.PLAYER_SPRINT_SPEED, 0.0, 1.0))
	_cape_material.set_shader_parameter("flare", 0.42 if _sprinting else (0.11 if planar_speed > 0.5 else 0.02))
	_cape_lining_material.set_shader_parameter("speed", clampf(planar_speed / KK.PLAYER_SPRINT_SPEED, 0.0, 1.0))
	_cape_lining_material.set_shader_parameter("flare", 0.42 if _sprinting else (0.11 if planar_speed > 0.5 else 0.02))
	if is_dead or _action_time > 0.0:
		return
	var state := "idle"
	if not is_on_floor():
		state = "jump" if _jump_start_time > 0.0 else "fall"
	elif _landing_time > 0.0:
		state = "land"
	elif _crouching:
		state = "crouch_walk" if planar_speed > 0.4 else "crouch_idle"
	elif planar_speed > 0.5:
		state = "run" if planar_speed > 5.0 else "walk"
	if anim.current_animation != state:
		anim.play(state, 0.18)
	if state == "walk":
		anim.speed_scale = clampf(planar_speed / 1.4, 0.65, 3.4)
	elif state == "run":
		anim.speed_scale = clampf(planar_speed / 5.5, 0.72, 1.5)
	elif state == "crouch_walk":
		anim.speed_scale = clampf(planar_speed / 1.2, 0.65, 2.2)
	else:
		anim.speed_scale = 1.0


func _can_stand() -> bool:
	_stand_check.force_shapecast_update()
	return not _stand_check.is_colliding()


## Applies damage with brief immunity, knockback, and a one-shot death signal.
func take_damage(amount: float, source: Node3D = null) -> void:
	if is_dead or _invuln > 0.0 or amount <= 0.0:
		return
	var old_hp := hp
	hp = maxf(0.0, hp - amount)
	if hp == old_hp:
		return
	_invuln = 0.6
	_flash_time = 0.0
	if source:
		var away := global_position - source.global_position
		away.y = 0.0
		if away.length() > 0.01:
			velocity += away.normalized() * 4.0
	velocity.y = maxf(velocity.y, 2.0)
	damaged.emit(old_hp - hp)
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		is_dead = true
		controls_enabled = false
		anim.play("death", 0.1)
		_tumble_hat()
		died.emit()
	else:
		_action_time = 0.4
		anim.play("hurt", 0.08)


## Restores health, returning false if already full.
func heal(amount: float) -> bool:
	if is_dead or hp >= max_hp or amount <= 0.0:
		return false
	hp = minf(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	return true


## Adds smoke bombs up to the inventory limit.
func add_smoke(count: int) -> bool:
	if count <= 0 or smoke_bombs >= KK.PLAYER_MAX_SMOKE:
		return false
	smoke_bombs = mini(smoke_bombs + count, KK.PLAYER_MAX_SMOKE)
	smoke_changed.emit(smoke_bombs)
	return true


func is_crouching() -> bool:
	return _crouching


func is_sprinting() -> bool:
	return _sprinting


## Detection multiplier used by guard vision.
func visibility_factor() -> float:
	if SmokeCloud.point_in_smoke(get_tree(), aim_point()):
		return 0.0
	return 0.45 if _crouching else (1.0 if _sprinting else 0.8)


## Fires a card toward the camera centre ray's first hit.
func fire_card() -> bool:
	if not controls_enabled or is_dead or _fire_time > 0.0 or effects_root == null:
		return false
	_fire_time = KK.CARD_COOLDOWN
	var origin := _right_hand.global_position + _right_hand.global_basis * Vector3(0.015, 0.0, -0.28)
	var aim := origin + -global_basis.z * KK.CARD_RANGE
	if camera_rig:
		var start := camera_rig.get_aim_origin()
		var end := start + camera_rig.get_aim_direction() * KK.CARD_RANGE
		var query := PhysicsRayQueryParameters3D.create(start, end, KK.LAYER_WORLD | KK.LAYER_ENEMY | KK.LAYER_GLASS)
		query.exclude = [get_rid()]
		query.collide_with_areas = true
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		aim = hit["position"] if not hit.is_empty() else end
	var projectile := CardProjectile.new()
	effects_root.add_child(projectile)
	projectile.launch(origin, (aim - origin).normalized(), self)
	_muzzle_flash(origin)
	_show_card_gun()
	_shot_anim.play("throw", 0.04)
	card_fired.emit()
	return true


func _show_card_gun() -> void:
	_right_hand.visible = true
	_gun_hide_time = _shot_anim.get_animation("throw").length


func _tumble_hat() -> void:
	if effects_root == null:
		return
	_hat.reparent(effects_root, true)
	var tween := create_tween()
	tween.tween_property(_hat, "global_position", _hat.global_position + Vector3(0.5, -1.0, 0.35), 0.7).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_hat, "rotation", Vector3(2.5, 0.5, 1.7), 0.7)


func _muzzle_flash(origin: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var flash := Node3D.new()
	effects_root.add_child(flash)
	flash.global_position = origin
	var sparkle_material := StandardMaterial3D.new()
	sparkle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sparkle_material.albedo_color = Color(1.0, 0.96, 0.78)
	sparkle_material.emission_enabled = true
	sparkle_material.emission = Color(1.0, 0.9, 0.6)
	for i in range(6):
		var sparkle := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.013
		mesh.height = 0.026
		sparkle.mesh = mesh
		sparkle.material_override = sparkle_material
		flash.add_child(sparkle)
		var angle := TAU * float(i) / 6.0
		var destination := Vector3(cos(angle), sin(angle), -0.5) * 0.17
		var tween := create_tween()
		tween.tween_property(sparkle, "position", destination, 0.18)
		tween.parallel().tween_property(sparkle, "scale", Vector3.ZERO, 0.18)
	get_tree().create_timer(0.22).timeout.connect(flash.queue_free)


## Consumes one bomb and creates a smoke screen at the player's feet.
func throw_smoke() -> bool:
	if not controls_enabled or is_dead or smoke_bombs <= 0 or effects_root == null:
		return false
	smoke_bombs -= 1
	smoke_changed.emit(smoke_bombs)
	var cloud := SmokeCloud.new()
	cloud.setup()
	effects_root.add_child(cloud)
	cloud.global_position = global_position
	_shot_anim.play("throw", 0.04)
	smoke_thrown.emit(global_position)
	return true


## Activates the nearest valid object in front of the player.
func try_interact() -> bool:
	if not controls_enabled or is_dead:
		return false
	var focus := get_focus_interactable()
	if focus == null:
		return false
	focus.call("interact", self)
	return true


## Returns the nearest valid interactable within reach and the frontal arc.
func get_focus_interactable() -> Node:
	if not is_inside_tree():
		return null
	var best: Node = null
	var best_distance := KK.INTERACT_RANGE
	for candidate: Node in get_tree().get_nodes_in_group(KK.GROUP_INTERACTABLE):
		if not candidate is Node3D or not candidate.has_method("can_interact") or not candidate.has_method("interact_position"):
			continue
		if not bool(candidate.call("can_interact", self)):
			continue
		var position: Vector3 = candidate.call("interact_position")
		var offset := position - global_position
		var distance := offset.length()
		if distance > best_distance:
			continue
		offset.y = 0.0
		if offset.length() > 0.2 and -global_basis.z.dot(offset.normalized()) < 0.1:
			continue
		best = candidate
		best_distance = distance
	return best


## Chest-height position for enemy sight checks.
func aim_point() -> Vector3:
	return global_position + Vector3.UP * (0.9 if _crouching else 1.2)
