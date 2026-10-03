class_name FollowCamera
extends Camera3D
## Smooth chase camera with lane-aware framing and a brief decaying shake.

var target: Node3D
## Menu mode: a slow low dolly beside the suitcase looking down the concourse.
var showcase := false

var _showcase_time := 0.0
var _speed_feel := 0.0
var _shake_strength := 0.0
var _shake_left := 0.0
var _shake_total := 0.0
var _rng := RandomNumberGenerator.new()
var _roll := 0.0
var _roll_target := 0.0
var _landing_bump := 0.0
var _speed_lines: Array[MeshInstance3D] = []


func _ready() -> void:
	current = true
	fov = 70.0
	_rng.randomize()
	_build_speed_lines()
	if target != null:
		snap_to_target()


func _process(delta: float) -> void:
	if target == null:
		return
	if showcase:
		_showcase(delta)
		return
	var follow_rate := 1.0 - exp(-7.0 * delta)
	var desired := _desired_position()
	global_position = global_position.lerp(desired, follow_rate)
	var look_point := target.global_position + Vector3(0.0, 1.15, -8.0)
	look_at(look_point, Vector3.UP)
	_roll_target = lerpf(_roll_target, 0.0, 1.0 - exp(-7.0 * delta))
	_roll = lerpf(_roll, _roll_target, 1.0 - exp(-8.0 * delta))
	rotate_object_local(Vector3.FORWARD, _roll)
	_landing_bump = lerpf(_landing_bump, 0.0, 1.0 - exp(-12.0 * delta))
	global_position.y -= _landing_bump
	fov = lerpf(fov, 70.0 + 13.0 * _speed_feel, 1.0 - exp(-5.0 * delta))
	for line: MeshInstance3D in _speed_lines:
		line.visible = _speed_feel > 0.48
	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var fade := _shake_left / maxf(_shake_total, 0.001)
		var offset := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * _shake_strength * fade
		global_position += global_transform.basis * offset


func _showcase(delta: float) -> void:
	_showcase_time += delta
	var t := _showcase_time
	var base := target.global_position
	global_position = base + Vector3(-3.4 + 0.5 * sin(t * 0.13), 1.25 + 0.25 * sin(t * 0.21), 5.6 + 0.8 * sin(t * 0.09))
	look_at(base + Vector3(3.4 - 0.6 * sin(t * 0.11), 2.2, -18.0), Vector3.UP)
	fov = 50.0
	for line: MeshInstance3D in _speed_lines:
		line.visible = false


func _desired_position() -> Vector3:
	return Vector3(target.global_position.x * 0.6, target.global_position.y + 3.6, target.global_position.z + 6.5)


func snap_to_target() -> void:
	if target == null:
		return
	global_position = _desired_position()
	look_at(target.global_position + Vector3(0.0, 1.15, -8.0), Vector3.UP)
	_shake_left = 0.0
	_roll = 0.0
	_roll_target = 0.0
	_landing_bump = 0.0


func shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(0.0, strength)
	_shake_total = maxf(0.0, duration)
	_shake_left = _shake_total


func set_speed_feel(amount: float) -> void:
	_speed_feel = clampf(amount, 0.0, 1.0)


func lane_nudge(direction: int) -> void:
	_roll_target = clampf(-float(direction) * 0.035, -0.035, 0.035)


func land_bump() -> void:
	_landing_bump = 0.13


func _build_speed_lines() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.63, 0.94, 1.0, 0.28)
	material.emission_enabled = true
	material.emission = Color(0.2, 0.7, 1.0)
	material.no_depth_test = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.012, 0.008, 0.31)
	for side: int in [-1, 1]:
		for index: int in 4:
			var line := MeshInstance3D.new()
			line.name = "SpeedLine"
			line.mesh = mesh
			line.material_override = material
			line.position = Vector3(float(side) * (0.72 + 0.19 * float(index)), -0.63 + float(index) * 0.37, -1.8)
			line.rotation.x = -0.28
			line.visible = false
			add_child(line)
			_speed_lines.append(line)
