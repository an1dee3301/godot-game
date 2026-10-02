class_name ThirdPersonCamera
extends Node3D
## Shoulder camera with wall avoidance, responsive orbit, and cinematic showcase mode.

const PITCH_MIN := -65.0
const PITCH_MAX := 35.0

var target: Node3D
var camera: Camera3D
var input_enabled := false
var sensitivity := 0.0025
var invert_y := false
var _arm: SpringArm3D
var _arm_end: Node3D
var _yaw := 0.0
var _pitch := deg_to_rad(-14.0)
var _showcase := false
var _trauma := 0.0
var _time := 0.0
var _distance := 3.4
var _dip := 0.0


func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.name = "WallAvoidance"
	_arm.spring_length = _distance
	_arm.margin = 0.12
	var probe := SphereShape3D.new()
	probe.radius = 0.24
	_arm.shape = probe
	_arm.collision_mask = KK.LAYER_WORLD
	add_child(_arm)
	_arm_end = Node3D.new()
	_arm.add_child(_arm_end)
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.h_offset = 0.55
	camera.fov = 70.0
	camera.current = true
	add_child(camera)
	var attributes := CameraAttributesPractical.new()
	attributes.auto_exposure_enabled = false
	attributes.dof_blur_far_enabled = DisplayServer.get_name() != "headless"
	attributes.dof_blur_far_distance = 20.0
	attributes.dof_blur_far_transition = 15.0
	camera.attributes = attributes
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if input_enabled and not _showcase and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * sensitivity
		_pitch = clampf(_pitch + event.relative.y * sensitivity * (1.0 if invert_y else -1.0), deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))


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
			_pitch = clampf(_pitch + stick.y * delta * 1.5 * (1.0 if invert_y else -1.0), deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))
	var crouching := target is PhantomThief and (target as PhantomThief).is_crouching()
	var sprinting := target is PhantomThief and (target as PhantomThief).is_sprinting()
	var desired_distance := 7.0 if _showcase else (3.0 if crouching else (3.9 if sprinting else 3.4))
	_distance = lerpf(_distance, desired_distance, 1.0 - exp(-5.0 * delta))
	_arm.spring_length = _distance
	var height := 1.7 if _showcase else (1.2 if crouching else 1.55)
	_dip = lerpf(_dip, 0.0, 1.0 - exp(-15.0 * delta))
	var follow_rate := 7.0 if sprinting else 13.0
	global_position = global_position.lerp(target.global_position + Vector3.UP * (height - _dip), 1.0 - exp(-follow_rate * delta))
	rotation = Vector3(_pitch, _yaw, 0.0)
	# The spring arm probes the whole camera path. Retract immediately at a wall;
	# ease back out once clear, so collision cannot put the lens inside masonry.
	var safe_position := _arm_end.global_position
	var current_distance := camera.global_position.distance_to(global_position)
	var safe_distance := safe_position.distance_to(global_position)
	var release := 1.0 - exp(-9.0 * delta)
	var candidate := safe_position if safe_distance < current_distance else camera.global_position.lerp(safe_position, release)
	var query := PhysicsRayQueryParameters3D.create(global_position, candidate, KK.LAYER_WORLD)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		candidate = hit["position"] + hit["normal"] * 0.26
	camera.global_position = candidate
	camera.global_rotation = global_rotation
	camera.fov = lerpf(camera.fov, 76.0 if sprinting and not _showcase else 70.0, 1.0 - exp(-5.0 * delta))
	_trauma = maxf(0.0, _trauma - delta * 1.7)
	var amount := _trauma * _trauma
	# Framing offset and impact shake never move the physical lens through a wall.
	camera.h_offset = 0.55 + sin(_time * 38.0) * amount * 0.16
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
	global_position = target.global_position + Vector3.UP * 1.55
	rotation = Vector3(_pitch, _yaw, 0.0)
	if camera and _arm_end:
		camera.global_position = _arm_end.global_position
		camera.global_rotation = global_rotation


## Adds a short camera impact shake.
func shake(strength: float) -> void:
	_trauma = clampf(_trauma + strength, 0.0, 1.0)


## Briefly lowers the pivot after a landing, then springs it back to eye height.
func land_dip(strength: float) -> void:
	_dip = maxf(_dip, 0.055 * clampf(strength, 0.0, 1.0))


## Enables a slow orbit for the title screen.
func set_showcase(on: bool) -> void:
	_showcase = on
