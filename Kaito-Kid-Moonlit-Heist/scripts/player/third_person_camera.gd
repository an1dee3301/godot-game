class_name ThirdPersonCamera
extends Node3D
## Shoulder camera with wall avoidance, responsive orbit, and cinematic showcase mode.

const SENSITIVITY := 0.0025
const PITCH_MIN := -65.0
const PITCH_MAX := 35.0

var target: Node3D
var camera: Camera3D
var input_enabled := false
var _arm: SpringArm3D
var _yaw := 0.0
var _pitch := deg_to_rad(-14.0)
var _showcase := false
var _trauma := 0.0
var _time := 0.0
var _distance := 4.2


func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.name = "WallAvoidance"
	_arm.spring_length = _distance
	_arm.margin = 0.2
	_arm.collision_mask = KK.LAYER_WORLD
	add_child(_arm)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.h_offset = 0.8
	camera.fov = 70.0
	camera.current = true
	_arm.add_child(camera)
	var attributes := CameraAttributesPractical.new()
	attributes.auto_exposure_enabled = false
	attributes.dof_blur_far_enabled = DisplayServer.get_name() != "headless"
	attributes.dof_blur_far_distance = 20.0
	attributes.dof_blur_far_transition = 15.0
	camera.attributes = attributes
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and not _showcase and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * SENSITIVITY, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))


func _process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(target):
		return
	if _showcase:
		_yaw += delta * 0.16
		_pitch = lerpf(_pitch, deg_to_rad(-17.0), 1.0 - exp(-2.0 * delta))
	elif input_enabled:
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.17:
			_yaw -= stick.x * delta * 2.0
			_pitch = clampf(_pitch - stick.y * delta * 1.5, deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))
	var desired_distance := 7.0 if _showcase else (3.4 if target is PhantomThief and (target as PhantomThief).is_crouching() else 4.35)
	_distance = lerpf(_distance, desired_distance, 1.0 - exp(-5.0 * delta))
	_arm.spring_length = _distance
	var height := 1.7 if _showcase else (1.25 if target is PhantomThief and (target as PhantomThief).is_crouching() else 1.65)
	global_position = global_position.lerp(target.global_position + Vector3.UP * height, 1.0 - exp(-11.0 * delta))
	rotation = Vector3(_pitch, _yaw, 0.0)
	var sprinting := target is PhantomThief and (target as PhantomThief).is_sprinting()
	camera.fov = lerpf(camera.fov, 78.0 if sprinting and not _showcase else 70.0, 1.0 - exp(-5.0 * delta))
	_trauma = maxf(0.0, _trauma - delta * 1.7)
	var amount := _trauma * _trauma
	# Shoulder offset + shake go through h/v_offset: the SpringArm owns camera.position.
	camera.h_offset = 0.8 + sin(_time * 38.0) * amount * 0.16
	camera.v_offset = cos(_time * 45.0) * amount * 0.12
	camera.rotation.z = sin(_time * 31.0) * amount * 0.025


## Rotation of the camera view around world Y, in radians.
func get_yaw() -> float:
	return _yaw


## Centre ray direction used by the card gun.
func get_aim_direction() -> Vector3:
	return -camera.global_basis.z if camera else -global_basis.z


## Centre ray origin used by the card gun.
func get_aim_origin() -> Vector3:
	return camera.global_position if camera else global_position


## Aligns the camera behind the player's facing direction.
func snap_behind_target() -> void:
	if not is_instance_valid(target):
		return
	_yaw = target.global_rotation.y
	_pitch = deg_to_rad(-14.0)
	global_position = target.global_position + Vector3.UP * 1.65
	rotation = Vector3(_pitch, _yaw, 0.0)


## Adds a short camera impact shake.
func shake(strength: float) -> void:
	_trauma = clampf(_trauma + strength, 0.0, 1.0)


## Enables a slow orbit for the title screen.
func set_showcase(on: bool) -> void:
	_showcase = on
