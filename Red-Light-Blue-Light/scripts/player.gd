class_name RacePlayer
extends CharacterBody3D
## Owner-driven runner; remote copies interpolate replicated pose and animate locally.

const WALK_SPEED := 6.2
const SPRINT_SPEED := 9.4
const GRAVITY := 24.0
var sync_position := Vector3.ZERO
var sync_yaw := 0.0
var sync_speed := 0.0
var is_local := false
var controls_enabled := false
var use_test_input := false
var test_input := Vector2.ZERO
var player_id := 0
var player_name := ""
var slot := 0
var model: Node3D
var camera: Camera3D
var yaw_pivot: Node3D
var pitch_pivot: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var _knockback := 0.0
var _walk_phase := 0.0
var _shove_anim := 0.0
var _out := false
var _step_time := 0.0

func setup(id: int, display_name: String, color_slot: int, spawn: Vector3) -> void:
	name = str(id)
	player_id = id
	player_name = display_name
	slot = color_slot
	position = spawn
	sync_position = spawn
	set_multiplayer_authority(id)

func _ready() -> void:
	is_local = is_multiplayer_authority()
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	_build_model()
	if is_local:
		_build_camera()

func _build_model() -> void:
	model = Node3D.new()
	model.name = "Model"
	add_child(model)
	var color: Color = GameLevel.COLORS[slot]
	_part("Torso", Vector3(0, 1.27, 0), Vector3(0.75, 0.88, 0.43), color, model)
	_part("JacketZip", Vector3(0, 1.25, 0.232), Vector3(0.045, 0.76, 0.015), Color("fff2da"), model)
	_sphere("Head", Vector3(0, 1.99, 0), Vector3(0.3, 0.34, 0.29), Color("e5b78d"), model)
	_sphere("Hair", Vector3(0, 2.24, -0.04), Vector3(0.32, 0.14, 0.31), Color("302c37"), model)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.22, 0.87, 0)
		model.add_child(leg)
		_part("Leg", Vector3(0, -0.43, 0), Vector3(0.29, 0.84, 0.32), color, leg)
		_part("Shoe", Vector3(0, -0.78, 0.1), Vector3(0.32, 0.17, 0.5), Color("343a41"), leg)
		_part("Sole", Vector3(0, -0.86, 0.1), Vector3(0.33, 0.04, 0.51), Color("eee8da"), leg)
		legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.5, 1.58, 0)
		model.add_child(arm)
		_part("Arm", Vector3(0, -0.4, 0), Vector3(0.25, 0.78, 0.27), color, arm)
		_part("SleeveStripe", Vector3(side * 0.12, -0.36, 0.02), Vector3(0.035, 0.68, 0.28), Color("f7edda"), arm)
		_part("Hand", Vector3(0, -0.83, 0), Vector3(0.2, 0.18, 0.22), Color("e5b78d"), arm)
		arms.append(arm)
	for direction in [-1.0, 1.0]:
		var bib := Label3D.new()
		bib.text = "%03d" % (slot + 1)
		bib.font_size = 64
		bib.pixel_size = 0.004
		bib.modulate = Color("202b3c")
		bib.position = Vector3(0, 1.3, direction * 0.245)
		bib.rotation.y = PI if direction < 0 else 0.0
		model.add_child(bib)
	var tag := Label3D.new()
	tag.text = "▼ YOU  " + player_name if is_local else player_name
	tag.font_size = 45
	tag.pixel_size = 0.006
	tag.position = Vector3(0, 2.78, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("fff4dd") if is_local else color
	model.add_child(tag)

func _part(label: String, at: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	instance.set_meta("original_color", color)
	parent.add_child(instance)

func _sphere(label: String, at: Vector3, size: Vector3, color: Color, parent: Node3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	instance.set_meta("original_color", color)
	parent.add_child(instance)

func _build_camera() -> void:
	yaw_pivot = Node3D.new()
	yaw_pivot.position.y = 1.55
	add_child(yaw_pivot)
	pitch_pivot = Node3D.new()
	pitch_pivot.rotation.x = -0.18
	yaw_pivot.add_child(pitch_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 4.2
	arm.margin = 0.15
	pitch_pivot.add_child(arm)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 74
	arm.add_child(camera)
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_pivot.rotation.y -= event.relative.x * 0.0025
		pitch_pivot.rotation.x = clampf(pitch_pivot.rotation.x - event.relative.y * 0.0025, -0.8, 0.45)

func _physics_process(delta: float) -> void:
	if is_local:
		_move_local(delta)
	else:
		var gap := global_position.distance_to(sync_position)
		global_position = sync_position if gap > 5.0 else global_position.lerp(sync_position, clampf(delta * 12.0, 0.0, 1.0))
		model.rotation.y = lerp_angle(model.rotation.y, sync_yaw, clampf(delta * 12.0, 0.0, 1.0))
	_animate(delta)

func _move_local(delta: float) -> void:
	var input := test_input if use_test_input else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not controls_enabled or _out:
		input = Vector2.ZERO
	var heading := Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw_pivot.rotation.y)
	var sprint := Input.is_action_pressed("sprint") and controls_enabled
	var target := heading * (SPRINT_SPEED if sprint else WALK_SPEED)
	var braking := 4.0 if sprint else 12.0
	var rate := 20.0 if input.length() > 0.1 else braking
	if _knockback > 0.0:
		_knockback -= delta
		rate = 0.8
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)
	if is_on_floor():
		if controls_enabled and not _out and Input.is_action_just_pressed("jump"):
			velocity.y = 8.0
		else:
			velocity.y = -0.2
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if Vector2(velocity.x, velocity.z).length() > 0.2:
		model.rotation.y = atan2(velocity.x, velocity.z)
	sync_position = global_position
	sync_yaw = model.rotation.y
	sync_speed = Vector2(velocity.x, velocity.z).length()
	if controls_enabled and is_on_floor() and sync_speed > 1.0:
		_step_time -= delta
		if _step_time <= 0.0:
			_step_time = 0.38 if sprint else 0.52
			var sound := get_parent().get_parent().get_node_or_null("SoundFX") as SoundFX
			if sound != null:
				sound.play("step", -19.0)

func _animate(delta: float) -> void:
	_walk_phase += delta * sync_speed * 1.5
	var swing := sin(_walk_phase) * minf(sync_speed / SPRINT_SPEED, 1.0) * 0.55
	if legs.size() == 2:
		legs[0].rotation.x = swing
		legs[1].rotation.x = -swing
	if arms.size() == 2:
		arms[0].rotation.x = -swing
		arms[1].rotation.x = swing
	_shove_anim = maxf(_shove_anim - delta, 0.0)
	if _shove_anim > 0.0:
		arms[1].rotation.x = -1.5 * _shove_anim / 0.25
	if not _out and (not is_on_floor() if is_local else global_position.y > 0.25):
		arms[0].rotation.x = -0.55
		arms[1].rotation.x = -0.55
		legs[0].rotation.x = 0.35
		legs[1].rotation.x = -0.35
	model.rotation.z = lerpf(model.rotation.z, -1.35 if _out else 0.0, minf(delta * 7.0, 1.0))

func apply_shove(impulse: Vector3) -> void:
	if not is_local or _out:
		return
	velocity += impulse
	_knockback = 0.35

func play_shove() -> void:
	_shove_anim = 0.25

func set_eliminated(out: bool) -> void:
	_out = out
	collision_layer = 0 if out else 2
	if model != null:
		_set_model_tint(model, out)

func _set_model_tint(root: Node, out: bool) -> void:
	for node in root.get_children():
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			var mat := mesh.material_override as StandardMaterial3D
			if mat != null:
				mat.albedo_color = Color("777c82") if out else mesh.get_meta("original_color")
		_set_model_tint(node, out)

func reset_to_spawn(spawn: Vector3) -> void:
	if not is_local:
		return
	global_position = spawn
	velocity = Vector3.ZERO
	sync_position = spawn
	sync_speed = 0.0
	sync_yaw = 0.0
	model.rotation = Vector3.ZERO
	_out = false
	collision_layer = 2
	if model != null:
		_set_model_tint(model, false)
