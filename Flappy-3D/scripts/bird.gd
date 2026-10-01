class_name FlappyBird
extends CharacterBody3D

const GRAVITY := 20.5
const FLAP_SPEED := 7.6
const MAX_FALL_SPEED := 12.0
const DEATH_FLOOR_Y := -2.64
const MODEL_SCALE := 1.15

var flying := false
var dead := false
var _spawn_position := Vector3.ZERO
var _animation_time := 0.0
var _flap_pulse := 0.0

var _model: Node3D
var _front_wing: Node3D
var _back_wing: Node3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_build_collision()
	_build_model()


func _physics_process(delta: float) -> void:
	_animation_time += delta

	if flying:
		velocity.y = maxf(velocity.y - GRAVITY * delta, -MAX_FALL_SPEED)
		move_and_slide()
		position.x = 0.0
		position.z = 0.0
		var target_tilt := deg_to_rad(clampf(velocity.y * 4.8, -68.0, 27.0))
		_model.rotation.x = lerp_angle(_model.rotation.x, target_tilt, 1.0 - exp(-8.5 * delta))
		_model.rotation.y = PI * 0.5
	elif dead:
		if position.y > DEATH_FLOOR_Y:
			velocity.y = maxf(velocity.y - GRAVITY * 0.82 * delta, -MAX_FALL_SPEED)
			move_and_slide()
			_model.rotation.z -= 4.2 * delta
		if position.y <= DEATH_FLOOR_Y:
			position.y = DEATH_FLOOR_Y
			velocity = Vector3.ZERO
		position.z = 0.0
	else:
		position.y = _spawn_position.y + sin(_animation_time * 2.5) * 0.13
		position.x = 0.0
		position.z = 0.0
		_model.rotation.x = sin(_animation_time * 2.5) * 0.055
		_model.rotation.y = PI * 0.5

	_flap_pulse = maxf(_flap_pulse - delta * 5.8, 0.0)
	var wing_wave := sin(_animation_time * (18.0 if flying else 5.0))
	var wing_angle := lerpf(-0.18, 0.78, (wing_wave + 1.0) * 0.5)
	wing_angle += _flap_pulse * 0.9
	_front_wing.rotation.x = wing_angle
	_back_wing.rotation.x = -wing_angle * 0.75

	var target_scale := Vector3.ONE * MODEL_SCALE
	if _flap_pulse > 0.0:
		target_scale = Vector3(0.92, 1.12, 1.0) * MODEL_SCALE
	_model.scale = _model.scale.lerp(target_scale, 1.0 - exp(-13.0 * delta))


func reset_bird(at_position: Vector3) -> void:
	_spawn_position = at_position
	position = at_position
	velocity = Vector3.ZERO
	flying = false
	dead = false
	_animation_time = 0.0
	_flap_pulse = 0.0
	if is_instance_valid(_model):
		_model.rotation = Vector3(0.0, PI * 0.5, 0.0)
		_model.scale = Vector3.ONE * MODEL_SCALE


func start_flying() -> void:
	flying = true
	dead = false


func flap() -> void:
	if dead:
		return
	flying = true
	velocity.y = FLAP_SPEED
	_flap_pulse = 1.0


func die() -> void:
	if dead:
		return
	flying = false
	dead = true
	velocity.y = minf(velocity.y, 1.5)
	_flap_pulse = 0.0


func _build_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.92, 0.7, 0.72)
	collision.shape = shape
	add_child(collision)


func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "BirdModel"
	add_child(_model)

	var red := _material(Color(1.0, 0.34, 0.3), 0.72)
	var deep_red := _material(Color(0.86, 0.12, 0.24), 0.76)
	var cream := _material(Color(1.0, 0.97, 0.84), 0.8)
	var navy := _material(Color(0.035, 0.1, 0.16), 0.68)
	var gold := _material(Color(1.0, 0.72, 0.12), 0.66)

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.5
	body_mesh.height = 0.92
	body_mesh.radial_segments = 20
	body_mesh.rings = 12
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.material_override = red
	body.scale = Vector3(1.18, 0.94, 0.9)
	_model.add_child(body)

	var belly_mesh := SphereMesh.new()
	belly_mesh.radius = 0.34
	belly_mesh.height = 0.62
	belly_mesh.radial_segments = 16
	belly_mesh.rings = 10
	var belly := MeshInstance3D.new()
	belly.name = "Belly"
	belly.mesh = belly_mesh
	belly.material_override = cream
	belly.position = Vector3(0.12, -0.11, 0.36)
	belly.scale = Vector3(0.88, 0.78, 0.25)
	belly.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.add_child(belly)

	_back_wing = _make_wing(deep_red, -0.38)
	_back_wing.name = "BackWing"
	_model.add_child(_back_wing)
	_front_wing = _make_wing(deep_red, 0.4)
	_front_wing.name = "FrontWing"
	_model.add_child(_front_wing)

	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.145
	eye_mesh.height = 0.29
	eye_mesh.radial_segments = 14
	eye_mesh.rings = 8
	var eye := MeshInstance3D.new()
	eye.name = "Eye"
	eye.mesh = eye_mesh
	eye.material_override = cream
	eye.position = Vector3(0.29, 0.18, 0.39)
	_model.add_child(eye)

	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.066
	pupil_mesh.height = 0.132
	pupil_mesh.radial_segments = 12
	pupil_mesh.rings = 7
	var pupil := MeshInstance3D.new()
	pupil.name = "Pupil"
	pupil.mesh = pupil_mesh
	pupil.material_override = navy
	pupil.position = Vector3(0.33, 0.18, 0.505)
	_model.add_child(pupil)

	var beak_mesh := CylinderMesh.new()
	beak_mesh.top_radius = 0.0
	beak_mesh.bottom_radius = 0.15
	beak_mesh.height = 0.5
	beak_mesh.radial_segments = 12
	var beak := MeshInstance3D.new()
	beak.name = "Beak"
	beak.mesh = beak_mesh
	beak.material_override = gold
	beak.position = Vector3(0.67, -0.01, 0.08)
	beak.rotation.z = -PI * 0.5
	_model.add_child(beak)

	for index in 3:
		var tail_mesh := BoxMesh.new()
		tail_mesh.size = Vector3(0.34, 0.105, 0.12)
		var tail := MeshInstance3D.new()
		tail.name = "TailFeather%d" % index
		tail.mesh = tail_mesh
		tail.material_override = deep_red
		tail.position = Vector3(-0.67, (float(index) - 1.0) * 0.12, (float(index) - 1.0) * 0.07)
		tail.rotation.z = (float(index) - 1.0) * 0.2
		_model.add_child(tail)


func _make_wing(material: StandardMaterial3D, z_position: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(-0.12, -0.02, z_position)
	var mesh := SphereMesh.new()
	mesh.radius = 0.33
	mesh.height = 0.58
	mesh.radial_segments = 14
	mesh.rings = 8
	var wing := MeshInstance3D.new()
	wing.mesh = mesh
	wing.material_override = material
	wing.position = Vector3(-0.08, -0.1, 0.02 if z_position > 0.0 else -0.02)
	wing.scale = Vector3(1.15, 0.48, 0.34)
	pivot.add_child(wing)
	return pivot


func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material
