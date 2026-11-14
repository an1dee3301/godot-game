extends RigidBody3D
## A force-driven toy contestant. Gameplay decisions stay in RoundManager.
signal action_requested(actor, action: String)
signal fell(actor)
signal feedback_requested(actor, event: String, intensity: float)

# The host simulates every body. Clients interpolate visual replicas.
var network_owner: int = 0
var network_replica: bool = false
var network_local: bool = false
var network_move: Vector2 = Vector2.ZERO
var local_input_blocked: bool = false
var _network_actions: Array[String] = []
var _net_position: Vector3 = Vector3.ZERO
var _net_rotation: Quaternion = Quaternion.IDENTITY
var _net_velocity: Vector3 = Vector3.ZERO
var _net_has_snapshot: bool = false
var _grab_cooldown: float = 0.0
var _avatar: Node3D
var _tinted_materials: Array[StandardMaterial3D] = []

@export var move_speed: float = 5.8
@export var jump_speed: float = 7.0
@export var acceleration: float = 24.0
@export var dive_impulse: float = 8.0

var contestant_id: int = 0
var display_name: String = "BRO"
var tint: Color = Color("ff6b61")
var human_slot: int = -1
var is_bot: bool = true
var active: bool = true
var spectator: bool = false
var score: int = 0
var perk: String = ""
var has_crown: bool = false
var held_cube: Node3D = null
var bot_target: Vector3 = Vector3.ZERO
var bot_moving: bool = false
var controls_enabled: bool = false
var ice: bool = false
var conveyor: bool = false
var heavy: bool = false
var pinball: bool = false
var facing: Vector3 = Vector3(0.0, 0.0, 1.0)
var shove_cooldown: float = 0.0
var flashlight: SpotLight3D

var _visual: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _ground: RayCast3D
var _name_label: Label3D
var _emote_label: Label3D
var _siren: Node3D
var _crown: Node3D
var _glasses: Node3D
var _material: StandardMaterial3D
var _human_ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _identity_is_human: bool = false
var _shove_left: float = 0.0
var _move: Vector3 = Vector3.ZERO
var _jump_buffer: float = 0.0
var _coyote_left: float = 0.0
var _dive_left: float = 0.0
var _dive_cooldown: float = 0.0
var _stun_left: float = 0.0
var _emote_left: float = 0.0
var _pinball_left: float = 0.0
var _time: float = 0.0
var _fall_sent: bool = false
var _teleport_pending: bool = false
var _teleport_position: Vector3 = Vector3.ZERO
var _prefix: String = ""
var _recovery_pending: bool = false
# Pose state belongs to the puppet, never the simulated rigid body/collider.
var _head: Node3D
var _body: Node3D
var _eyes: Array[Node3D] = []
var _left_foot_rest: Vector3
var _right_foot_rest: Vector3
var _gait: float = 0.0
var _jump_pose_left: float = 0.0
var _landing_left: float = 0.0
var _landing_strength: float = 0.0
var _hit_left: float = 0.0
var _hit_direction: float = 1.0
var _celebrate_left: float = 0.0
var _elimination_left: float = 0.0
var _pose_initialized: bool = false
var _was_grounded: bool = false
var _previous_velocity: Vector3 = Vector3.ZERO
var _feedback_grace: float = 0.2
var _showcase: bool = false
var _blink_clock: float = 0.0

func setup(id: int, label: String, color: Color, slot: int = -1) -> void:
	contestant_id = id
	display_name = label
	tint = color
	human_slot = slot
	is_bot = slot < 0
	network_owner = 0
	network_replica = false
	network_local = false
	network_move = Vector2.ZERO
	local_input_blocked = false
	freeze = false
	collision_layer = 2
	collision_mask = 7
	if human_slot >= 0:
		_setup_actions()
	if is_instance_valid(_material):
		_apply_avatar_tint()
		_refresh_identity()

func _ready() -> void:
	mass = 1.0
	can_sleep = false
	continuous_cd = true
	collision_layer = 2
	collision_mask = 7
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	linear_damp = 0.1
	angular_damp = 2.0
	contact_monitor = true
	max_contacts_reported = 6
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.65
	physics_material_override.bounce = 0.03
	var collision: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.46
	capsule.height = 1.8
	collision.shape = capsule
	add_child(collision)
	_ground = RayCast3D.new()
	_ground.target_position = Vector3(0.0, -1.06, 0.0)
	_ground.collision_mask = 1
	_ground.exclude_parent = true
	add_child(_ground)
	_build_mascot()
	body_entered.connect(_on_body_entered)
	if human_slot >= 0 and _prefix.is_empty():
		_setup_actions()

func _setup_actions() -> void:
	_prefix = "bro_p%d_" % human_slot
	var names: Array[String] = ["left", "right", "up", "down", "jump", "shove", "dive", "emote", "grab"]
	var keys: Array[int] = []
	if human_slot == 0:
		keys = [KEY_A, KEY_D, KEY_W, KEY_S, KEY_SPACE, KEY_F, KEY_G, KEY_H, KEY_E]
	elif human_slot == 1:
		keys = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_K, KEY_L, KEY_SEMICOLON, KEY_O]
	var buttons: Array[int] = [-1, -1, -1, -1, JOY_BUTTON_A, JOY_BUTTON_X, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_Y]
	for i in names.size():
		var action: StringName = StringName(_prefix + names[i])
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		if i < keys.size():
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = keys[i] as Key
			InputMap.action_add_event(action, key)
		if i >= 4:
			var button: InputEventJoypadButton = InputEventJoypadButton.new()
			button.device = human_slot
			button.button_index = buttons[i] as JoyButton
			InputMap.action_add_event(action, button)
		else:
			var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
			motion.device = human_slot
			motion.axis = JOY_AXIS_LEFT_X if i < 2 else JOY_AXIS_LEFT_Y
			motion.axis_value = -1.0 if i == 0 or i == 2 else 1.0
			InputMap.action_add_event(action, motion)

func _unhandled_input(event: InputEvent) -> void:
	if is_bot or local_input_blocked or not controls_enabled or (not active and not spectator) or _prefix.is_empty():
		return
	if network_replica:
		if network_local:
			for action: String in ["jump", "shove", "dive", "emote", "grab"]:
				if event.is_action_pressed(_prefix + action) and not _network_actions.has(action):
					_network_actions.append(action)
		return
	if event.is_action_pressed(_prefix + "jump"):
		request_jump()
	elif event.is_action_pressed(_prefix + "shove") and shove_cooldown <= 0.0:
		action_requested.emit(self, "junk" if spectator else "shove")
		shove_cooldown = 0.7 if not spectator else 1.5
	elif event.is_action_pressed(_prefix + "dive") and not spectator and _dive_cooldown <= 0.0:
		action_requested.emit(self, "dive")
	elif event.is_action_pressed(_prefix + "emote"):
		action_requested.emit(self, "emote")
	elif event.is_action_pressed(_prefix + "grab") and not spectator:
		action_requested.emit(self, "grab")

func _physics_process(delta: float) -> void:
	_time += delta
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	if network_replica:
		if _net_has_snapshot:
			var blend: float = 1.0 - exp(-18.0 * delta)
			global_position = global_position.lerp(_net_position, blend)
			quaternion = quaternion.slerp(_net_rotation, blend).normalized()
			_dive_left = maxf(0.0, _dive_left - delta)
			_emote_left = maxf(0.0, _emote_left - delta)
			_shove_left = maxf(0.0, _shove_left - delta)
		_update_visual(delta)
		return
	shove_cooldown = maxf(0.0, shove_cooldown - delta)
	_dive_cooldown = maxf(0.0, _dive_cooldown - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_pinball_left = maxf(0.0, _pinball_left - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_emote_left = maxf(0.0, _emote_left - delta)
	_shove_left = maxf(0.0, _shove_left - delta)
	if _dive_left > 0.0:
		_dive_left -= delta
		if _dive_left <= 0.0:
			_recovery_pending = true
	if _ground.is_colliding() and _dive_left <= 0.0:
		_coyote_left = 0.1
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
	_move = Vector3.ZERO
	if controls_enabled and (active or spectator) and not local_input_blocked:
		if network_owner > 0 and not network_local:
			_move = Vector3(network_move.x, 0.0, network_move.y)
		elif is_bot:
			if bot_moving:
				var offset: Vector3 = bot_target - global_position
				offset.y = 0.0
				if offset.length() > 0.35:
					_move = offset.normalized()
		elif not _prefix.is_empty():
			var input_direction: Vector2 = Input.get_vector(_prefix + "left", _prefix + "right", _prefix + "up", _prefix + "down")
			_move = Vector3(input_direction.x, 0.0, input_direction.y)
	if _move.length_squared() > 0.02:
		facing = _move.normalized()
	if global_position.y < -6.0 and not _teleport_pending and not _fall_sent and (active or spectator):
		_fall_sent = true
		notify_eliminated()
		fell.emit(self)
	_update_visual(delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if network_replica: return
	if _teleport_pending:
		var reset_transform: Transform3D = Transform3D(Basis.IDENTITY, _teleport_position)
		state.transform = reset_transform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_teleport_pending = false
		reset_physics_interpolation()
	if _recovery_pending:
		state.transform = Transform3D(Basis.IDENTITY, state.transform.origin)
		state.angular_velocity = Vector3.ZERO
		axis_lock_angular_x = true
		axis_lock_angular_y = true
		axis_lock_angular_z = true
		_recovery_pending = false
	if not active and not spectator:
		return
	if _dive_left <= 0.0 and _stun_left <= 0.0:
		var desired: Vector3 = _move * move_speed * (0.78 if heavy else 1.0)
		var horizontal: Vector3 = Vector3(state.linear_velocity.x, 0.0, state.linear_velocity.z)
		var traction: float = 2.6 if ice else acceleration
		if _move.length_squared() < 0.01:
			traction = 0.45 if ice else 15.0
		var force: Vector3 = (desired - horizontal) * traction * mass
		state.apply_central_force(force)
	if _jump_buffer > 0.0 and _coyote_left > 0.0 and _dive_left <= 0.0:
		state.apply_central_impulse(Vector3.UP * jump_speed * mass)
		_jump_buffer = 0.0
		_coyote_left = 0.0
	if spectator:
		var p: Vector3 = state.transform.origin
		p.x = clampf(p.x, -6.2, 6.2)
		p.z = clampf(p.z, -10.9, -9.3)
		if p.y < 2.2:
			p.y = 2.5
		state.transform = Transform3D(Basis.IDENTITY, p)

func respawn(pos: Vector3, as_spectator: bool = false) -> void:
	spectator = as_spectator
	active = not as_spectator
	_fall_sent = false
	_dive_left = 0.0
	_stun_left = 0.0
	_jump_pose_left = 0.0
	_landing_left = 0.0
	_hit_left = 0.0
	_celebrate_left = 0.0
	_elimination_left = 0.0
	_pose_initialized = false
	_feedback_grace = 0.2
	_recovery_pending = true
	_teleport_position = pos
	_teleport_pending = true
	if not is_inside_tree():
		position = pos
	visible = true
	sleeping = false

func apply_knockback(impulse: Vector3) -> void:
	if spectator or not active:
		return
	_stun_left = 0.38
	apply_central_impulse(impulse)
	_react_to_hit(impulse)

func set_perk(perk_name: String) -> void:
	perk = perk_name
	var lower_name: String = perk_name.to_lower()
	heavy = lower_name.contains("heavy") or lower_name.contains("boots")
	pinball = lower_name.contains("pinball") or lower_name.contains("bounc")
	mass = 2.0 if heavy else 1.0
	if physics_material_override:
		physics_material_override.bounce = 0.85 if pinball else 0.03
	if _siren:
		_siren.visible = lower_name.contains("nerd") or lower_name.contains("glass")
	if _glasses:
		_glasses.visible = lower_name.contains("nerd") or lower_name.contains("glass")

func request_jump() -> void:
	_jump_buffer = 0.15

func perform_dive() -> void:
	if _dive_cooldown > 0.0 or spectator or not active:
		return
	_dive_left = 0.8
	_dive_cooldown = 1.5
	_stun_left = 0.9
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	apply_central_impulse((facing * dive_impulse + Vector3.UP * 2.0) * mass)
	apply_torque_impulse(Vector3(facing.z, 0.0, -facing.x) * 3.4 * mass)
	feedback_requested.emit(self, "dive", 1.0)

func perform_shove() -> void:
	_shove_left = 0.24
	feedback_requested.emit(self, "shove", 0.8)

func perform_emote() -> void:
	_emote_left = 1.8
	if _emote_label:
		var lines: Array[String] = ["TRUST ME!", "THIS ONE!", "100% SAFE", "I STUDIED."]
		_emote_label.text = lines.pick_random()
	feedback_requested.emit(self, "emote", 1.0)

func set_showcase(enabled: bool) -> void:
	_showcase = enabled
	if enabled:
		facing = Vector3.FORWARD * -1.0

func celebrate(duration: float = 2.8) -> void:
	_celebrate_left = maxf(_celebrate_left, duration)

func notify_scored(points: int) -> void:
	if points > 0:
		celebrate(1.2)

func notify_eliminated() -> void:
	if _elimination_left > 0.0:
		return
	_elimination_left = 1.2
	feedback_requested.emit(self, "fall", 0.8)

func _react_to_hit(impulse: Vector3) -> void:
	_hit_left = 0.4
	_hit_direction = signf(impulse.x) if absf(impulse.x) > 0.2 else (-1.0 if contestant_id % 2 == 0 else 1.0)
	feedback_requested.emit(self, "hit", clampf(impulse.length() / 9.0, 0.55, 1.6))

func aim_direction() -> Vector3:
	return facing

func _on_body_entered(body: Node) -> void:
	if pinball and _pinball_left <= 0.0 and body is RigidBody3D and not spectator:
		var away: Vector3 = global_position - (body as RigidBody3D).global_position
		away.y = 0.3
		apply_knockback(away.normalized() * 7.0)
		_pinball_left = 0.4

func _material_for(color: Color, emission: bool = false) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.68
	if emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	return mat

func _capsule(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 16
	mesh.rings = 4
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D, at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance

func _box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = at
	parent.add_child(instance)
	return instance

func _build_mascot() -> void:
	_visual = Node3D.new()
	_visual.name = "PartyPuppet"
	add_child(_visual)
	var paths: Array[String] = ["bun", "cub", "pip", "sprout"]
	var packed: PackedScene = load("res://assets/characters/%s.glb" % paths[contestant_id % 4])
	_avatar = packed.instantiate() as Node3D
	_visual.add_child(_avatar)
	_left_arm = _avatar.find_child("ArmL", true, false) as Node3D
	_right_arm = _avatar.find_child("ArmR", true, false) as Node3D
	_left_leg = _avatar.find_child("FootL", true, false) as Node3D
	_right_leg = _avatar.find_child("FootR", true, false) as Node3D
	_head = _avatar.find_child("Head", true, false) as Node3D
	_body = _avatar.find_child("Body", true, false) as Node3D
	_left_foot_rest = _left_leg.position
	_right_foot_rest = _right_leg.position
	for eye_name: String in ["EyeL", "EyeR"]:
		var eye: Node3D = _avatar.find_child(eye_name, true, false) as Node3D
		if eye:
			_eyes.append(eye)
	_blink_clock = float(contestant_id) * 0.47
	for mesh_node: Node in _avatar.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = mesh_node as MeshInstance3D
		for surface in mesh_instance.mesh.get_surface_count():
			var original: Material = mesh_instance.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var mat: StandardMaterial3D = original.duplicate() as StandardMaterial3D
				mat.roughness = 0.48
				mesh_instance.set_surface_override_material(surface, mat)
				if mat.resource_name.begins_with("M_Coat") or mat.resource_name.begins_with("M_Boot"):
					_tinted_materials.append(mat)
					if _material == null and mat.resource_name.begins_with("M_Coat"): _material = mat
	_apply_avatar_tint()
	_name_label = Label3D.new()
	_name_label.position = Vector3(0, 1.76, 0)
	_name_label.font_size = 38
	_name_label.pixel_size = 0.0075
	_name_label.outline_size = 10
	_name_label.outline_modulate = Color("233d68")
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	add_child(_name_label)
	_human_ring = MeshInstance3D.new()
	var ring_mesh: TorusMesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.57
	ring_mesh.outer_radius = 0.62
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	_human_ring.mesh = ring_mesh
	_human_ring.position.y = -0.86
	_ring_material = _material_for(tint.lightened(0.35))
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_human_ring.material_override = _ring_material
	_human_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_human_ring)
	_emote_label = Label3D.new()
	_emote_label.position.y = 2.35
	_emote_label.font_size = 48
	_emote_label.pixel_size = 0.011
	_emote_label.outline_size = 12
	_emote_label.outline_modulate = Color("233d68")
	_emote_label.modulate = Color("ffe170")
	_emote_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote_label.no_depth_test = true
	_emote_label.visible = false
	add_child(_emote_label)
	_siren = Node3D.new()
	_siren.position.y = 1.38
	_siren.visible = false
	add_child(_siren)
	_sphere(_siren, Vector3.ZERO, 0.18, _material_for(Color("ff455d"), true))
	var siren_light: OmniLight3D = OmniLight3D.new()
	siren_light.light_color = Color("ff4568")
	siren_light.light_energy = 1.2
	siren_light.omni_range = 2.0
	_siren.add_child(siren_light)
	_glasses = Node3D.new()
	_glasses.visible = false
	_head.add_child(_glasses)
	var ink: Material = _material_for(Color("213554"))
	_box(_glasses, Vector3(-0.19, 0.1, 0.47), Vector3(0.25,0.22,0.04), ink)
	_box(_glasses, Vector3(0.19, 0.1, 0.47), Vector3(0.25,0.22,0.04), ink)
	_box(_glasses, Vector3(0,0.11,0.47), Vector3(0.14,0.035,0.04), ink)
	_crown = Node3D.new()
	_crown.position.y = 1.15
	_crown.visible = false
	add_child(_crown)
	var crown_scene: PackedScene = load("res://assets/props/crown.glb")
	var crown_model: Node3D = crown_scene.instantiate() as Node3D
	crown_model.scale = Vector3.ONE * 0.62
	_crown.add_child(crown_model)
	flashlight = SpotLight3D.new()
	flashlight.position = Vector3(0,0.25,0.55)
	flashlight.rotation = Vector3(-0.28,PI,0)
	flashlight.light_color = Color("fff6df")
	flashlight.light_energy = 3.2
	flashlight.spot_range = 12
	flashlight.spot_angle = 30
	flashlight.visible = false
	_visual.add_child(flashlight)
	_refresh_identity()

func _apply_avatar_tint() -> void:
	for mat in _tinted_materials:
		mat.albedo_color = tint.darkened(0.32) if mat.resource_name.begins_with("M_Boot") else tint

func _refresh_identity() -> void:
	_identity_is_human = _is_local_human()
	if _name_label:
		_name_label.text = (("YOU ▼" if network_local else "P%d ▼" % (human_slot + 1))) if _identity_is_human else ""
		_name_label.modulate = Color("fff9e6")
	if _human_ring:
		_human_ring.visible = _identity_is_human
	if _ring_material:
		_ring_material.albedo_color = tint.lightened(0.4)

func _is_local_human() -> bool:
	return not is_bot and (network_local if network_owner > 0 else human_slot >= 0)

func _update_visual(delta: float) -> void:
	if not is_instance_valid(_visual):
		return
	var visual_velocity: Vector3 = _net_velocity if network_replica else linear_velocity
	var grounded: bool = _ground.is_colliding() and visual_velocity.y < 1.8
	_observe_motion(visual_velocity, grounded, delta)
	_jump_pose_left = maxf(0.0, _jump_pose_left - delta)
	_landing_left = maxf(0.0, _landing_left - delta)
	_hit_left = maxf(0.0, _hit_left - delta)
	_celebrate_left = maxf(0.0, _celebrate_left - delta)
	_elimination_left = maxf(0.0, _elimination_left - delta)
	_blink_clock += delta
	var moving: float = minf(Vector2(visual_velocity.x, visual_velocity.z).length() / move_speed, 1.25)
	if moving < 0.045 or _showcase:
		moving = 0.0
	_gait += delta * (6.0 + moving * 8.0)
	var stride: float = sin(_gait) * moving
	var idle: float = sin(_time * 2.6 + float(contestant_id))
	var airborne: bool = not grounded and _feedback_grace <= 0.0 and not _showcase
	var celebrating: bool = _celebrate_left > 0.0 or (_showcase and fmod(_time + contestant_id * 0.7, 7.0) > 4.9)
	var pose: Vector3 = Vector3(moving * 0.11, 0.0, -stride * 0.065)
	var left_arm: Vector3 = Vector3(-stride * 0.8, 0.0, 0.10)
	var right_arm: Vector3 = Vector3(stride * 0.8, 0.0, -0.10)
	var left_leg: Vector3 = Vector3(stride * 0.78, 0.0, stride * 0.04)
	var right_leg: Vector3 = Vector3(-stride * 0.78, 0.0, -stride * 0.04)
	var head_pose: Vector3 = Vector3(-moving * 0.07 + idle * 0.025, sin(_time * 0.72 + contestant_id) * (0.13 if moving < 0.1 else 0.035), stride * 0.035)
	var foot_lift: float = 0.0
	var vertical_scale: float = 1.0 + idle * 0.012 * (1.0 - minf(moving, 1.0))
	var bounce: float = absf(sin(_gait)) * moving * 0.065
	if _jump_buffer > 0.0 and grounded:
		vertical_scale = 0.83
		left_arm.x = 0.4
		right_arm.x = 0.4
	if airborne:
		vertical_scale = 1.04 + 0.12 * _jump_pose_left / 0.24
		left_arm = Vector3(-0.35, 0.0, -0.66)
		right_arm = Vector3(-0.35, 0.0, 0.66)
		left_leg = Vector3(-0.42, 0.0, -0.1)
		right_leg = Vector3(0.2, 0.0, 0.1)
		foot_lift = 0.12
		head_pose.x = -0.08
		pose.x = clampf(-visual_velocity.y * 0.015, -0.12, 0.15)
	if _landing_left > 0.0:
		var landing: float = _landing_left / 0.30
		vertical_scale = 1.0 - (sin(landing * PI) * 0.15 + landing * 0.06) * _landing_strength
		pose.x += sin(landing * PI) * 0.13
	if _shove_left > 0.0:
		# The body loads back briefly, then the soft mitts snap forward.
		var windup: bool = _shove_left > 0.185
		left_arm = Vector3(0.48 if windup else -1.72, 0.0, 0.12)
		right_arm = Vector3(0.48 if windup else -1.72, 0.0, -0.12)
		pose.x = -0.14 if windup else 0.22
		head_pose.x = -pose.x * 0.65
		vertical_scale = 0.96 if windup else 1.04
	if _emote_left > 0.0:
		right_arm = Vector3(-0.25, 0.0, 2.25 + sin(_time * 15.0) * 0.25)
		left_arm.z = -0.25
		head_pose.z = -0.12
	if celebrating:
		left_arm = Vector3(-0.15, 0.0, -2.35 - sin(_time * 13.0) * 0.18)
		right_arm = Vector3(-0.15, 0.0, 2.35 + cos(_time * 13.0) * 0.18)
		pose.z = sin(_time * 9.0) * 0.09
		bounce += maxf(0.0, sin(_time * 9.0)) * 0.14
		head_pose.z = -pose.z * 0.8
	if _hit_left > 0.0:
		var hit: float = _hit_left / 0.4
		pose.z += sin(hit * PI * 3.0) * hit * _hit_direction * 0.28
		pose.x -= hit * 0.16
		head_pose.z -= sin(hit * PI * 3.0) * hit * _hit_direction * 0.14
		vertical_scale *= 1.0 - hit * 0.09
	if _dive_left > 0.0:
		left_arm = Vector3(-1.7, 0.0, -0.26)
		right_arm = Vector3(-1.7, 0.0, 0.26)
		left_leg = Vector3(0.65, 0.0, -0.2)
		right_leg = Vector3(-0.3, 0.0, 0.2)
		head_pose.x = -0.15
		vertical_scale = 1.08
		pose = Vector3.ZERO
	elif _elimination_left > 0.0 or (not active and not spectator):
		left_arm.z = -1.4
		right_arm.z = 1.4
		pose.z += sin(_time * 16.0) * 0.15
	if spectator:
		head_pose.y += sin(_time * 1.5) * 0.2
	var follow: float = 1.0 - exp(-22.0 * delta)
	var desired_angle: float = atan2(facing.x, facing.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, desired_angle, 1.0 - exp(-14.0 * delta))
	_visual.rotation.x = lerpf(_visual.rotation.x, pose.x, follow)
	_visual.rotation.z = lerpf(_visual.rotation.z, pose.z, follow)
	var wide: float = 1.0 / sqrt(vertical_scale)
	var size: float = 1.12 if _showcase else 1.0
	_visual.scale = _visual.scale.lerp(Vector3(wide, vertical_scale, wide) * size, follow)
	# Anchor squash to the soles; the capsule's centre and dimensions never change.
	_visual.position.y = (_visual.scale.y - 1.0) * 0.9 + bounce
	_left_arm.rotation = _left_arm.rotation.lerp(left_arm, follow)
	_right_arm.rotation = _right_arm.rotation.lerp(right_arm, follow)
	_left_leg.rotation = _left_leg.rotation.lerp(left_leg, follow)
	_right_leg.rotation = _right_leg.rotation.lerp(right_leg, follow)
	_left_leg.position = _left_foot_rest + Vector3.UP * (foot_lift + maxf(0.0, stride) * 0.08)
	_right_leg.position = _right_foot_rest + Vector3.UP * (foot_lift + maxf(0.0, -stride) * 0.08)
	if _head:
		_head.rotation = _head.rotation.lerp(head_pose, 1.0 - exp(-12.0 * delta))
	if _body:
		_body.rotation.z = -pose.z * 0.12
	var blink_phase: float = fmod(_blink_clock, 3.7)
	var eye_open: float = 1.0
	if blink_phase < 0.14:
		eye_open = maxf(0.06, absf(blink_phase - 0.07) / 0.07)
	elif _hit_left > 0.23:
		eye_open = 0.12
	for eye: Node3D in _eyes:
		eye.scale.y = eye_open
	_emote_label.visible = _emote_left > 0.0
	_emote_label.position.y = 2.14 + sin(_time * 5.0) * 0.025
	_crown.visible = has_crown
	_crown.rotation.y += delta * 1.5
	if _siren.visible:
		_siren.scale = Vector3.ONE * (1.0 + sin(_time * 12.0) * 0.13)
	if _identity_is_human != _is_local_human():
		_refresh_identity()
	_name_label.visible = _identity_is_human and not _showcase
	_human_ring.visible = _identity_is_human and _dive_left <= 0.0 and not _showcase
	_human_ring.scale = Vector3.ONE * (1.0 + sin(_time * 3.0) * 0.025)

func _observe_motion(velocity: Vector3, grounded: bool, delta: float) -> void:
	_feedback_grace = maxf(0.0, _feedback_grace - delta)
	if not _pose_initialized or _teleport_pending or _showcase:
		_pose_initialized = true
		_was_grounded = grounded
		_previous_velocity = velocity
		return
	if _feedback_grace <= 0.0:
		if velocity.y > 3.2 and _previous_velocity.y < 2.0 and _dive_left <= 0.0:
			_jump_pose_left = 0.24
			feedback_requested.emit(self, "jump", 0.8)
		if grounded and not _was_grounded and _previous_velocity.y < -1.6:
			_landing_left = 0.3
			_landing_strength = clampf(absf(_previous_velocity.y) / 6.0, 0.5, 1.5)
			feedback_requested.emit(self, "land", _landing_strength)
	_was_grounded = grounded
	_previous_velocity = velocity


func configure_network(owner_peer_id: int, local_peer_id: int, replica: bool) -> void:
	network_owner = owner_peer_id
	network_local = owner_peer_id > 0 and owner_peer_id == local_peer_id
	network_replica = replica
	is_bot = owner_peer_id == 0
	human_slot = 0 if network_local else -1
	if network_local: _setup_actions()
	freeze = replica
	collision_layer = 0 if replica else 2
	collision_mask = 0 if replica else 7
	if replica: _teleport_pending = false
	_refresh_identity()

func get_network_input() -> Dictionary:
	var direction: Vector2 = Vector2.ZERO
	var actions: Array[String] = []
	var peek: bool = false
	if network_local and not local_input_blocked and controls_enabled and (active or spectator) and not _prefix.is_empty():
		direction = Input.get_vector(_prefix+"left",_prefix+"right",_prefix+"up",_prefix+"down")
		actions.assign(_network_actions)
		peek = Input.is_key_pressed(KEY_TAB)
		for device in Input.get_connected_joypads():
			peek = peek or Input.is_joy_button_pressed(device,JOY_BUTTON_BACK)
	_network_actions.clear()
	return {"move":direction,"actions":actions,"peek":peek}

func apply_network_input(direction: Vector2) -> void:
	if not network_replica:
		network_move = direction.limit_length(1.0)

func apply_network_action(action: String) -> void:
	if network_replica or not controls_enabled or (not active and not spectator): return
	match action:
		"jump": request_jump()
		"shove":
			if shove_cooldown <= 0.0:
				action_requested.emit(self,"junk" if spectator else "shove")
				shove_cooldown = 1.5 if spectator else 0.7
		"dive":
			if not spectator and _dive_cooldown <= 0.0: action_requested.emit(self,"dive")
		"emote":
			if _emote_left <= 0.1: action_requested.emit(self,"emote")
		"grab":
			if not spectator and _grab_cooldown <= 0.0:
				action_requested.emit(self,"grab")
				_grab_cooldown = 0.25

func apply_network_snapshot(data: Dictionary) -> void:
	var previous_dive: float = _dive_left
	var previous_shove: float = _shove_left
	var previous_emote: float = _emote_left
	var previous_active: bool = active
	var previous_spectator: bool = spectator
	var previous_score: int = score
	var previous_net_velocity: Vector3 = _net_velocity
	var received_before: bool = _net_has_snapshot
	if int(data.get("owner",network_owner)) != network_owner:
		configure_network(int(data.get("owner",0)),multiplayer.get_unique_id(),true)
	var next_position: Vector3 = data.get("position",global_position)
	if not _net_has_snapshot or global_position.distance_to(next_position) > 3.5:
		global_position = next_position
		_pose_initialized = false
		_feedback_grace = 0.15
		reset_physics_interpolation()
	_net_position = next_position
	var incoming_rotation: Variant = data.get("rotation",Vector3.ZERO)
	_net_rotation = Quaternion.from_euler(incoming_rotation) if incoming_rotation is Vector3 else incoming_rotation
	_net_velocity = data.get("velocity",Vector3.ZERO)
	_net_has_snapshot = true
	facing = data.get("facing",facing)
	active = bool(data.get("active",true))
	spectator = bool(data.get("spectator",false))
	score = int(data.get("score",0))
	has_crown = bool(data.get("crown",false))
	controls_enabled = bool(data.get("controls_enabled",data.get("controls",true)))
	if flashlight: flashlight.visible = bool(data.get("flashlight",false))
	is_bot = bool(data.get("is_bot",network_owner == 0))
	_dive_left = float(data.get("dive_left",0.0))
	_emote_left = float(data.get("emote_left",0.0))
	_shove_left = float(data.get("shove_left",0.0))
	if _emote_label: _emote_label.text = str(data.get("emote_text","TRUST ME!"))
	var incoming_tint: Color = data.get("tint",tint)
	if incoming_tint != tint:
		tint = incoming_tint
		_apply_avatar_tint()
		_refresh_identity()
	display_name = str(data.get("name",display_name))
	var next_perk: String = str(data.get("perk",""))
	if next_perk != perk: set_perk(next_perk)
	# Recreate presentation from existing authoritative snapshots; no gameplay RPCs.
	if received_before:
		if (active and not previous_active) or (spectator and not previous_spectator):
			_elimination_left = 0.0
			_pose_initialized = false
			_feedback_grace = 0.15
		if _dive_left > previous_dive + 0.15:
			feedback_requested.emit(self, "dive", 1.0)
		if _shove_left > previous_shove + 0.08:
			feedback_requested.emit(self, "shove", 0.8)
		if _emote_left > previous_emote + 0.3:
			feedback_requested.emit(self, "emote", 1.0)
		if previous_active and not active:
			notify_eliminated()
		if score > previous_score:
			notify_scored(score - previous_score)
		var change: Vector3 = _net_velocity - previous_net_velocity
		change.y = 0.0
		if change.length() > 4.5 and _dive_left <= 0.0 and _hit_left <= 0.1:
			_react_to_hit(change)
