class_name PhantomThief
extends CharacterBody3D
## Kaito Kid: camera-relative movement, stealth, calling cards, smoke, and an articulated procedural costume.

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
var _hips: Node3D
var _torso: Node3D
var _head: Node3D
var _hat: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _right_hand: Node3D
var _cape: MeshInstance3D
var _cape_material: ShaderMaterial
var _cape_lining_material: ShaderMaterial
var _crouching := false
var _sprinting := false
var _coyote := 0.0
var _air_time := 0.0
var _step_time := 0.0
var _fire_time := 0.0
var _invuln := 0.0
var _action_time := 0.0
var _flash_time := 0.0
var _materials: Array[StandardMaterial3D] = []


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
	_build_model()
	_build_animations()
	anim.play("idle")


func _build_model() -> void:
	var rig: Dictionary = preload("res://scripts/player/kid_model.gd").build(self)
	_model = rig["model"]
	_hips = rig["hips"]
	_torso = rig["torso"]
	_head = rig["head"]
	_hat = rig["hat"]
	_left_arm = rig["left_arm"]
	_right_arm = rig["right_arm"]
	_left_leg = rig["left_leg"]
	_right_leg = rig["right_leg"]
	_right_hand = rig["right_hand"]
	_cape = rig["cape"]
	_cape_material = rig["cape_material"]
	_cape_lining_material = rig["lining_material"]


func _make_animation(name: String, poses: Array[Dictionary], length: float, looped: bool) -> void:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
	for path in ["Model/Hips:position", "Model/Hips/Torso:rotation", "Model/Hips/Torso/LeftArm:rotation", "Model/Hips/Torso/RightArm:rotation", "Model/Hips/LeftLeg:rotation", "Model/Hips/RightLeg:rotation", "Model/Hips/Torso/Head/Hat:rotation"]:
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath(path))
		animation.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
		for pose: Dictionary in poses:
			var values: Array = pose["v"]
			var index := ["Model/Hips:position", "Model/Hips/Torso:rotation", "Model/Hips/Torso/LeftArm:rotation", "Model/Hips/Torso/RightArm:rotation", "Model/Hips/LeftLeg:rotation", "Model/Hips/RightLeg:rotation", "Model/Hips/Torso/Head/Hat:rotation"].find(path)
			animation.track_insert_key(track, float(pose["t"]), values[index])
	if name == "death":
		var hat_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(hat_track, NodePath("Model/Hips/Torso/Head/Hat:position"))
		animation.track_insert_key(hat_track, 0.0, Vector3(0.0, 0.275, 0.0))
		animation.track_insert_key(hat_track, 0.5, Vector3(0.22, 0.39, 0.0))
		animation.track_insert_key(hat_track, 1.0, Vector3(0.64, -0.72, 0.12))
	var library: AnimationLibrary = anim.get_animation_library("")
	library.add_animation(name, animation)


func _pose(t: float, bob: float = 0.0, lean: float = 0.0, left_arm: float = 0.0, right_arm: float = 0.0, left_leg: float = 0.0, right_leg: float = 0.0, hat: float = 0.0) -> Dictionary:
	return {"t": t, "v": [Vector3(0.0, 0.94 + bob, 0.0), Vector3(lean, 0.0, 0.0), Vector3(left_arm, 0.0, 0.0), Vector3(right_arm, 0.0, 0.0), Vector3(left_leg, 0.0, 0.0), Vector3(right_leg, 0.0, 0.0), Vector3(hat, 0.0, 0.0)]}


func _build_animations() -> void:
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	add_child(anim)
	anim.add_animation_library("", AnimationLibrary.new())
	_make_animation("idle", [_pose(0.0), _pose(1.0, 0.025), _pose(2.0)], 2.0, true)
	_make_animation("walk", [_pose(0.0, 0.0, 0.08, -0.5, 0.5, 0.55, -0.55), _pose(0.3, 0.055, 0.08), _pose(0.6, 0.0, 0.08, 0.5, -0.5, -0.55, 0.55), _pose(0.9, 0.055, 0.08), _pose(1.2, 0.0, 0.08, -0.5, 0.5, 0.55, -0.55)], 1.2, true)
	_make_animation("run", [_pose(0.0, 0.0, 0.27, -0.85, 0.85, 0.82, -0.82), _pose(0.22, 0.09, 0.27), _pose(0.44, 0.0, 0.27, 0.85, -0.85, -0.82, 0.82), _pose(0.66, 0.09, 0.27), _pose(0.88, 0.0, 0.27, -0.85, 0.85, 0.82, -0.82)], 0.88, true)
	_make_animation("crouch_idle", [_pose(0.0, -0.35, 0.28, 0.15, 0.15, -0.15, -0.15), _pose(1.0, -0.33, 0.28, 0.15, 0.15, -0.15, -0.15), _pose(2.0, -0.35, 0.28, 0.15, 0.15, -0.15, -0.15)], 2.0, true)
	_make_animation("crouch_walk", [_pose(0.0, -0.35, 0.32, -0.2, 0.2, 0.3, -0.3), _pose(0.45, -0.33, 0.32, 0.2, -0.2, -0.3, 0.3), _pose(0.9, -0.35, 0.32, -0.2, 0.2, 0.3, -0.3)], 0.9, true)
	_make_animation("jump", [_pose(0.0, 0.0, -0.1, -0.3, -0.3, 0.3, -0.2), _pose(0.3, 0.06, -0.1, -0.5, -0.5, 0.45, -0.35)], 0.3, false)
	_make_animation("fall", [_pose(0.0, 0.0, 0.13, 0.3, 0.3, -0.2, -0.2), _pose(0.5, 0.0, 0.13, 0.3, 0.3, -0.2, -0.2)], 0.5, true)
	_make_animation("throw", [_pose(0.0), _pose(0.12, 0.0, 0.12, 0.0, -1.8), _pose(0.3, 0.0, 0.1, 0.0, -0.9), _pose(0.5)], 0.5, false)
	_make_animation("hurt", [_pose(0.0), _pose(0.15, 0.0, -0.35, -0.5, -0.5), _pose(0.45)], 0.45, false)
	_make_animation("death", [_pose(0.0), _pose(0.5, -0.48, 1.2, -0.9, 0.8, 0.5, -0.5, 0.5), _pose(1.0, -0.65, 1.5, -1.2, 0.7, 0.4, -0.4, 1.5)], 1.0, false)


func _physics_process(delta: float) -> void:
	_fire_time = maxf(0.0, _fire_time - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_action_time = maxf(0.0, _action_time - delta)
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
		_crouching = Input.is_action_pressed("crouch") and not use_scripted_input
		_sprinting = not _crouching and input.length() > 0.15 and Input.is_action_pressed("sprint") and not use_scripted_input
		if Input.is_action_just_pressed("jump") and _coyote > 0.0 and not _crouching:
			velocity.y = KK.PLAYER_JUMP_VELOCITY
			_coyote = 0.0
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
	var rate := 16.0 if direction.length() > 0.0 else 22.0
	velocity.x = move_toward(velocity.x, desired.x, rate * delta)
	velocity.z = move_toward(velocity.z, desired.z, rate * delta)
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 12.0))
	if not is_on_floor():
		velocity.y -= 14.0 * delta
		_air_time += delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	if not was_grounded and is_on_floor():
		if _air_time > 0.4:
			landed.emit()
			KK.emit_noise(get_tree(), global_position, KK.NOISE_LAND)
		_air_time = 0.0
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
		state = "jump" if velocity.y > 0.0 else "fall"
	elif _crouching:
		state = "crouch_walk" if planar_speed > 0.4 else "crouch_idle"
	elif planar_speed > 0.5:
		state = "run" if _sprinting else "walk"
	if anim.current_animation != state:
		anim.play(state, 0.18)


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
	var origin := _right_hand.global_position + _right_hand.global_basis * Vector3(0.04, -0.42, -0.2)
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
	_action_time = 0.38
	anim.play("throw", 0.07)
	card_fired.emit()
	return true


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
	_action_time = 0.38
	anim.play("throw", 0.07)
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
