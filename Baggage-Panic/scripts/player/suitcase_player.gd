class_name SuitcasePlayer
extends CharacterBody3D
## A procedural suitcase with bottom-centred collision and belt movement.

signal hazard_hit(hazard: Hazard)
signal pickup_collected(pickup: Pickup)
signal trigger_entered(trigger: TrackTrigger)
signal fell
signal jumped
signal slid
signal lane_changed(lane: int)
signal landed

const GRAVITY := 38.0
const JUMP_SPEED := 12.5
const SLIDE_TIME := 0.75
const JUMP_BUFFER := 0.12

var lane := 1
var forward_speed := 0.0
var running := false
var alive := true
var start_z := 0.0
var is_sliding := false
var anim: AnimationPlayer
var hitbox: Area3D

var _visual: Node3D
var _case: Node3D
var _body_shape: BoxShape3D
var _body_collision: CollisionShape3D
var _hit_shape: BoxShape3D
var _hit_collision: CollisionShape3D
var _shield: MeshInstance3D
var _priority: Node3D
var _trail: CPUParticles3D
var _extra_bags: Array[Node3D] = []
var _lid: Node3D
var _clothes: Node3D
var _slide_left := 0.0
var _jump_buffer_left := 0.0
var _fell_sent := false
var _hit_left := 0.0
var _last_anim := ""
var _weight := 0.0
var _wheels: Array[Node3D] = []
var _dust: CPUParticles3D
var _was_airborne := false
var _landing_pulse := 0.0
var _visual_time := 0.0
static var _mesh_cache: Dictionary = {}
static var _material_cache: Dictionary = {}


func _ready() -> void:
	collision_layer = BP.LAYER_PLAYER
	collision_mask = BP.LAYER_WORLD
	floor_snap_length = 0.18
	_body_collision = CollisionShape3D.new()
	_body_collision.name = "BodyCollision"
	_body_shape = BoxShape3D.new()
	_body_shape.size = Vector3(BP.PLAYER_WIDTH, BP.PLAYER_HEIGHT, BP.PLAYER_DEPTH)
	_body_collision.shape = _body_shape
	_body_collision.position.y = BP.PLAYER_HEIGHT * 0.5
	add_child(_body_collision)

	hitbox = Area3D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = BP.LAYER_HAZARD | BP.LAYER_PICKUP
	hitbox.monitoring = true
	add_child(hitbox)
	_hit_collision = CollisionShape3D.new()
	_hit_collision.name = "HitShape"
	_hit_shape = BoxShape3D.new()
	_hit_shape.size = Vector3(BP.PLAYER_WIDTH * 0.88, BP.PLAYER_HEIGHT * 0.93, BP.PLAYER_DEPTH * 0.88)
	_hit_collision.shape = _hit_shape
	_hit_collision.position.y = BP.PLAYER_HEIGHT * 0.5
	hitbox.add_child(_hit_collision)
	hitbox.area_entered.connect(_on_area_entered)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_case = Node3D.new()
	_case.name = "Case"
	_visual.add_child(_case)
	_build_suitcase()
	_build_effects()
	_build_animations()
	reset_player()


func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var key := "%s:%s:%s:%s" % [color.to_html(), metallic, roughness, emission.to_html()]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	_material_cache[key] = material
	return material


func _box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var key := str(size)
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_mesh_cache[key] = mesh
	node.mesh = _mesh_cache[key] as Mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node


func _sphere(parent: Node3D, node_name: String, scale: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	if not _mesh_cache.has("sphere"):
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		_mesh_cache["sphere"] = mesh
	node.mesh = _mesh_cache["sphere"] as Mesh
	node.scale = scale
	node.position = pos
	node.material_override = material
	parent.add_child(node)
	return node


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var key := "cyl:%s:%s" % [radius, height]
	if not _mesh_cache.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		_mesh_cache[key] = mesh
	node.mesh = _mesh_cache[key] as Mesh
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node


func _build_suitcase() -> void:
	var teal := _mat(Color("12bdc1"), 0.25, 0.32)
	var dark := _mat(Color("154351"), 0.15, 0.42)
	var trim := _mat(Color("f9ad3b"), 0.35, 0.3)
	var silver := _mat(Color("dceef0"), 0.7, 0.23)
	var cream := _mat(Color("fff3cb"))
	var coral := _mat(Color("ff6b77"), 0.12, 0.33)
	var navy := _mat(Color("17263e"), 0.12, 0.31)
	var white := _mat(Color("fffdfa"), 0.04, 0.2)
	_box(_case, "Shell", Vector3(1.06, 1.12, 0.72), Vector3(0, 0.68, 0), teal)
	_box(_case, "RoundedInset", Vector3(0.96, 1.02, 0.055), Vector3(0, 0.68, 0.376), dark)
	_box(_case, "FrontPanel", Vector3(0.89, 0.95, 0.035), Vector3(0, 0.68, 0.412), teal)
	_box(_case, "Sheen", Vector3(0.05, 0.86, 0.012), Vector3(-0.39, 0.72, 0.438), _mat(Color("80f9e8"), 0.2, 0.22, Color("168a87")))
	for x: float in [-0.52, 0.52]:
		_box(_case, "CornerTrim", Vector3(0.055, 1.15, 0.77), Vector3(x, 0.68, 0), trim)
		for y: float in [0.13, 1.23]:
			_sphere(_case, "CornerProtector", Vector3(0.17, 0.17, 0.17), Vector3(x, y, 0.34), trim)
	for y: float in [0.12, 1.24]:
		_box(_case, "Rim", Vector3(1.1, 0.05, 0.78), Vector3(0, y, 0), dark)
		_box(_case, "Zipper", Vector3(0.96, 0.018, 0.014), Vector3(0, y + (0.023 if y < 0.5 else -0.023), 0.443), silver)
	for x: float in [-0.32, 0.32]:
		_box(_case, "Stripe", Vector3(0.045, 0.85, 0.014), Vector3(x, 0.69, 0.442), trim)
	for x: float in [-0.38, 0.38]:
		for z: float in [-0.27, 0.27]:
			var wheel_pivot := Node3D.new()
			wheel_pivot.name = "WheelPivot"
			wheel_pivot.position = Vector3(x, 0.1, z)
			_visual.add_child(wheel_pivot)
			var wheel := _cylinder(wheel_pivot, "Wheel", 0.11, 0.105, Vector3.ZERO, navy)
			wheel.rotation.z = PI * 0.5
			var hub := _cylinder(wheel_pivot, "Hub", 0.05, 0.11, Vector3.ZERO, silver)
			hub.rotation.z = PI * 0.5
			_wheels.append(wheel_pivot)
	var handle := Node3D.new()
	handle.name = "Handle"
	handle.position = Vector3(0, 1.28, 0)
	_visual.add_child(handle)
	for x: float in [-0.22, 0.22]:
		_box(handle, "Rail", Vector3(0.055, 0.21, 0.055), Vector3(x, 0.08, 0), silver)
	_box(handle, "Grip", Vector3(0.49, 0.065, 0.12), Vector3(0, 0.19, 0), dark)
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0, 1.22, 0.39)
	_visual.add_child(_lid)
	_box(_lid, "Lip", Vector3(1.04, 0.055, 0.08), Vector3(0, 0, -0.38), dark)
	_box(_lid, "Lining", Vector3(0.96, 0.05, 0.64), Vector3(0, 0.04, -0.06), cream)
	_lid.visible = false
	_clothes = Node3D.new()
	_clothes.name = "Clothes"
	_visual.add_child(_clothes)
	var pink := _mat(Color("ff789b"))
	var blue := _mat(Color("738dff"))
	_box(_clothes, "Shirt", Vector3(0.34, 0.07, 0.25), Vector3(-0.2, 1.0, 0), pink)
	_box(_clothes, "Sock", Vector3(0.12, 0.34, 0.09), Vector3(0.21, 1.04, 0.04), blue)
	_clothes.visible = false
	# Layered travel stickers and a tag read clearly from the chase camera.
	_sphere(_case, "SunSticker", Vector3(0.23, 0.23, 0.035), Vector3(-0.26, 0.42, 0.458), _mat(Color("ffe56a"), 0.0, 0.45, Color("8a650c")))
	_box(_case, "PassportSticker", Vector3(0.18, 0.21, 0.028), Vector3(0.25, 0.39, 0.456), coral)
	_box(_case, "StickerMark", Vector3(0.1, 0.035, 0.03), Vector3(0.25, 0.39, 0.475), cream)
	for x: float in [-0.19, 0.19]:
		_sphere(_case, "EyeWhite", Vector3(0.26, 0.29, 0.095), Vector3(x, 0.88, 0.47), white)
		_sphere(_case, "Pupil", Vector3(0.105, 0.15, 0.055), Vector3(x + 0.025, 0.87, 0.523), navy)
		_sphere(_case, "EyeGlint", Vector3(0.038, 0.045, 0.023), Vector3(x + 0.002, 0.93, 0.553), white)
	_box(_case, "Smile", Vector3(0.22, 0.035, 0.018), Vector3(0, 0.61, 0.456), navy)
	_sphere(_case, "CheekL", Vector3(0.1, 0.06, 0.02), Vector3(-0.25, 0.64, 0.462), coral)
	_sphere(_case, "CheekR", Vector3(0.1, 0.06, 0.02), Vector3(0.25, 0.64, 0.462), coral)
	var tag := Node3D.new()
	tag.name = "Tag"
	tag.position = Vector3(0.4, 1.3, -0.23)
	_visual.add_child(tag)
	_box(tag, "Cord", Vector3(0.018, 0.16, 0.018), Vector3(0, -0.08, 0), silver)
	_box(tag, "Label", Vector3(0.17, 0.19, 0.03), Vector3(0, -0.22, 0), cream)
	_box(tag, "Mark", Vector3(0.11, 0.035, 0.034), Vector3(0, -0.2, -0.002), trim)
	for index: int in 3:
		var bag := Node3D.new()
		bag.name = "ExtraBag%d" % index
		bag.position = Vector3(0.53 if index != 1 else -0.53, 0.32 + index * 0.23, 0.08)
		bag.rotation.z = 0.22 if index != 1 else -0.2
		_case.add_child(bag)
		_box(bag, "Bag", Vector3(0.25, 0.2, 0.46), Vector3.ZERO, _mat(Color("ffa14f") if index != 1 else Color("6d80e8")))
		_box(bag, "Strap", Vector3(0.26, 0.035, 0.48), Vector3(0, 0, -0.01), dark)
		bag.visible = false
		_extra_bags.append(bag)


func _build_effects() -> void:
	_shield = MeshInstance3D.new()
	_shield.name = "ShieldBubble"
	var sphere := SphereMesh.new()
	sphere.radius = 0.87
	sphere.height = 1.75
	_shield.mesh = sphere
	_shield.position.y = 0.75
	var bubble := _mat(Color(0.35, 0.9, 1.0, 0.19), 0.2, 0.1)
	bubble.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubble.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield.material_override = bubble
	_visual.add_child(_shield)
	_priority = Node3D.new()
	_priority.name = "PriorityBand"
	_visual.add_child(_priority)
	var bright := _mat(Color("ffe452"), 0.1, 0.2, Color("ffb51c"))
	_box(_priority, "Band", Vector3(1.12, 0.16, 0.78), Vector3(0, 0.93, 0), bright)
	var label := Label3D.new()
	label.name = "PriorityText"
	label.text = "PRIORITY"
	label.font_size = 64
	label.pixel_size = 0.0018
	label.modulate = Color("563a00")
	label.position = Vector3(0, 0.93, 0.403)
	_priority.add_child(label)
	_trail = CPUParticles3D.new()
	_trail.name = "SpeedTrail"
	_trail.amount = 24
	_trail.lifetime = 0.34
	_trail.explosiveness = 0.0
	_trail.direction = Vector3(0, 0, 1)
	_trail.spread = 24.0
	_trail.initial_velocity_min = 0.5
	_trail.initial_velocity_max = 1.8
	_trail.gravity = Vector3.ZERO
	_trail.color = Color(1.0, 0.73, 0.2, 0.6)
	var spark := SphereMesh.new()
	spark.radius = 0.035
	spark.height = 0.07
	_trail.mesh = spark
	_trail.position = Vector3(0, 0.55, 0.55)
	add_child(_trail)
	_dust = CPUParticles3D.new()
	_dust.name = "WheelDust"
	_dust.amount = 16
	_dust.lifetime = 0.45
	_dust.direction = Vector3(0, 0.4, 1)
	_dust.spread = 24.0
	_dust.initial_velocity_min = 0.2
	_dust.initial_velocity_max = 1.1
	_dust.gravity = Vector3(0, -0.6, 0)
	_dust.color = Color(0.68, 0.94, 1.0, 0.5)
	_dust.mesh = spark
	_dust.position = Vector3(0, 0.07, 0.31)
	add_child(_dust)


func _build_animations() -> void:
	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	add_child(anim)
	var library := AnimationLibrary.new()
	for anim_name: String in ["idle", "run", "jump", "slide", "hit", "death"]:
		var animation := Animation.new()
		animation.length = 0.8
		if anim_name in ["idle", "run", "slide"]:
			animation.loop_mode = Animation.LOOP_LINEAR
		match anim_name:
			"idle":
				animation.length = 1.2
				_track(animation, "Visual:position", [0.0, 0.6, 1.2], [Vector3.ZERO, Vector3(0, 0.025, 0), Vector3.ZERO])
				_track(animation, "Visual/Tag:rotation", [0.0, 0.6, 1.2], [Vector3(0, 0, -0.13), Vector3(0, 0, 0.13), Vector3(0, 0, -0.13)])
			"run":
				animation.length = 0.42
				_track(animation, "Visual:position", [0.0, 0.105, 0.21, 0.315, 0.42], [Vector3.ZERO, Vector3(0, 0.075, 0), Vector3.ZERO, Vector3(0, 0.075, 0), Vector3.ZERO])
				_track(animation, "Visual:rotation", [0.0, 0.105, 0.21, 0.315, 0.42], [Vector3(0, 0, -0.055), Vector3.ZERO, Vector3(0, 0, 0.055), Vector3.ZERO, Vector3(0, 0, -0.055)])
				_track(animation, "Visual/Handle:rotation", [0.0, 0.21, 0.42], [Vector3(0, 0, -0.05), Vector3(0, 0, 0.05), Vector3(0, 0, -0.05)])
				_track(animation, "Visual/Tag:rotation", [0.0, 0.21, 0.42], [Vector3(0, 0, -0.18), Vector3(0, 0, 0.18), Vector3(0, 0, -0.18)])
			"jump":
				animation.length = 0.68
				_track(animation, "Visual:scale", [0.0, 0.09, 0.2, 0.54, 0.68], [Vector3(1.12, 0.84, 1.12), Vector3(0.88, 1.16, 0.88), Vector3.ONE, Vector3.ONE, Vector3.ONE])
				_track(animation, "Visual:rotation", [0.0, 0.68], [Vector3.ZERO, Vector3(TAU, 0, 0)])
			"slide":
				animation.length = 0.38
				_track(animation, "Visual:scale", [0.0, 0.08, 0.3, 0.38], [Vector3(1.25, 0.42, 1.1), Vector3(1.35, 0.4, 1.12), Vector3(1.34, 0.4, 1.12), Vector3(1.25, 0.42, 1.1)])
				_track(animation, "Visual:position", [0.0, 0.38], [Vector3(0, 0.05, 0), Vector3(0, 0.05, 0)])
			"hit":
				animation.length = 0.32
				_track(animation, "Visual:position", [0.0, 0.08, 0.16, 0.24, 0.32], [Vector3.ZERO, Vector3(0.13, 0.02, 0), Vector3(-0.13, 0, 0), Vector3(0.08, 0.01, 0), Vector3.ZERO])
				_track(animation, "Visual:rotation", [0.0, 0.12, 0.24, 0.32], [Vector3.ZERO, Vector3(0, 0, 0.16), Vector3(0, 0, -0.12), Vector3.ZERO])
			"death":
				animation.length = 1.0
				_track(animation, "Visual:rotation", [0.0, 0.25, 0.65, 1.0], [Vector3.ZERO, Vector3(0.1, 0, -0.3), Vector3(0.2, 0, -1.25), Vector3(0.2, 0, -1.45)])
				_track(animation, "Visual/Lid:rotation", [0.0, 0.25, 0.65, 1.0], [Vector3.ZERO, Vector3(-0.15, 0, 0), Vector3(-1.8, 0, 0), Vector3(-2.1, 0, 0)])
				_track(animation, "Visual/Clothes:position", [0.0, 0.4, 0.75, 1.0], [Vector3.ZERO, Vector3(0, 0.5, 0), Vector3(0.4, 1.0, 0.1), Vector3(0.7, 0.4, 0.2)])
		library.add_animation(anim_name, animation)
	anim.add_animation_library("", library)


func _track(animation: Animation, path: String, times: Array[float], values: Array[Vector3]) -> void:
	var index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(index, NodePath(path))
	animation.value_track_set_update_mode(index, Animation.UPDATE_CONTINUOUS)
	for key_index: int in times.size():
		animation.track_insert_key(index, times[key_index], values[key_index])


func _physics_process(delta: float) -> void:
	if not alive or not running:
		return
	if Input.is_action_just_pressed("move_left"):
		move_lane(-1)
	if Input.is_action_just_pressed("move_right"):
		move_lane(1)
	if Input.is_action_just_pressed("jump"):
		if not jump():
			_jump_buffer_left = JUMP_BUFFER
	if Input.is_action_just_pressed("slide"):
		slide()
	if _jump_buffer_left > 0.0:
		_jump_buffer_left -= delta
		if is_on_floor():
			jump()
	if is_sliding:
		_slide_left -= delta
		if _slide_left <= 0.0:
			_end_slide()
	velocity.z = -forward_speed
	var dx := BP.lane_x(lane) - global_position.x
	velocity.x = clampf(dx * 12.0, -22.0, 22.0)
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	var grounded := is_on_floor()
	if grounded and _was_airborne and velocity.y <= 0.0:
		_landing_pulse = 1.0
		landed.emit()
	_was_airborne = not grounded
	_dust.emitting = grounded and not is_sliding
	_dust.amount = clampi(roundi(12.0 + forward_speed * 0.45), 12, 28)
	if grounded:
		for wheel: Node3D in _wheels:
			wheel.rotate_x(forward_speed * delta * 4.5)
	if global_position.y < -3.0 and not _fell_sent:
		_fell_sent = true
		fell.emit()
	_update_animation(delta)
	_visual_time += delta
	_landing_pulse = maxf(0.0, _landing_pulse - delta * 5.0)
	_case.scale = Vector3((1.0 + _weight * 0.15) * (1.0 + _landing_pulse * 0.13), (1.0 - _weight * 0.07) * (1.0 - _landing_pulse * 0.16), (1.0 + _weight * 0.08) * (1.0 + _landing_pulse * 0.13))
	if _shield.visible:
		var shimmer := 1.0 + sin(_visual_time * 7.0) * 0.025
		_shield.scale = Vector3.ONE * shimmer
		_shield.rotation.y += delta * 0.5


func _update_animation(delta: float) -> void:
	if _hit_left > 0.0:
		_hit_left -= delta
		return
	var desired := "run"
	if is_sliding:
		desired = "slide"
	elif not is_on_floor():
		desired = "jump"
	if desired != _last_anim:
		anim.play(desired, 0.09)
		_last_anim = desired
	# A small steering lean sits on the visual shell, outside the animation tracks.
	_case.rotation.z = lerpf(_case.rotation.z, clampf((BP.lane_x(lane) - global_position.x) * -0.11, -0.16, 0.16), minf(1.0, delta * 12.0))


func _on_area_entered(area: Area3D) -> void:
	if not alive or not running:
		return
	if area is Hazard:
		var hazard := area as Hazard
		if hazard.lethal:
			hazard_hit.emit(hazard)
	elif area is Pickup:
		pickup_collected.emit(area as Pickup)
	elif area is TrackTrigger:
		trigger_entered.emit(area as TrackTrigger)


func _set_slide_shape(sliding: bool) -> void:
	var height := BP.PLAYER_SLIDE_HEIGHT if sliding else BP.PLAYER_HEIGHT
	_body_shape.size = Vector3(BP.PLAYER_WIDTH, height, BP.PLAYER_DEPTH)
	_body_collision.position.y = height * 0.5
	_hit_shape.size = Vector3(BP.PLAYER_WIDTH * 0.88, height * 0.92, BP.PLAYER_DEPTH * 0.88)
	_hit_collision.position.y = height * 0.5


func _end_slide() -> void:
	is_sliding = false
	_slide_left = 0.0
	_set_slide_shape(false)


func reset_player() -> void:
	global_position = Vector3(BP.lane_x(1), 0, 0)
	lane = 1
	velocity = Vector3.ZERO
	alive = true
	running = false
	start_z = 0.0
	_fell_sent = false
	_was_airborne = false
	_landing_pulse = 0.0
	_visual_time = 0.0
	_jump_buffer_left = 0.0
	_hit_left = 0.0
	_end_slide()
	_case.rotation = Vector3.ZERO
	_case.scale = Vector3.ONE
	_visual.rotation = Vector3.ZERO
	_visual.position = Vector3.ZERO
	_visual.scale = Vector3.ONE
	_lid.visible = false
	_lid.rotation = Vector3.ZERO
	_clothes.visible = false
	_clothes.position = Vector3.ZERO
	set_shield_visual(false)
	set_boost_visual(false)
	_dust.emitting = false
	set_weight_visual(0.0)
	anim.play("idle")
	_last_anim = "idle"


func start_running() -> void:
	if alive:
		running = true
		anim.play("run")
		_last_anim = "run"


func stop_running() -> void:
	running = false
	_dust.emitting = false
	velocity = Vector3.ZERO
	if alive:
		anim.play("idle")
		_last_anim = "idle"


func set_forward_speed(speed: float) -> void:
	forward_speed = maxf(0.0, speed)


func distance_travelled() -> float:
	return maxf(0.0, start_z - global_position.z)


func move_lane(direction: int) -> bool:
	if not running or not alive or direction == 0:
		return false
	var next_lane := clampi(lane + signi(direction), 0, BP.LANE_COUNT - 1)
	if next_lane == lane:
		return false
	lane = next_lane
	lane_changed.emit(lane)
	return true


func jump() -> bool:
	if not running or not alive or not is_on_floor():
		return false
	if is_sliding:
		_end_slide()
	velocity.y = JUMP_SPEED
	_jump_buffer_left = 0.0
	anim.play("jump")
	_last_anim = "jump"
	jumped.emit()
	return true


func slide() -> bool:
	if not running or not alive or is_sliding:
		return false
	is_sliding = true
	_slide_left = SLIDE_TIME
	_jump_buffer_left = 0.0
	_set_slide_shape(true)
	if not is_on_floor():
		velocity.y = -18.0
	anim.play("slide")
	_last_anim = "slide"
	slid.emit()
	return true


func is_grounded() -> bool:
	return is_on_floor()


func play_hit() -> void:
	if not alive:
		return
	_hit_left = 0.32
	anim.play("hit")
	_last_anim = "hit"


func play_death() -> void:
	if not alive:
		return
	alive = false
	running = false
	velocity = Vector3.ZERO
	_lid.visible = true
	_clothes.visible = true
	anim.play("death")
	_last_anim = "death"


func set_shield_visual(active: bool) -> void:
	_shield.visible = active


func set_boost_visual(active: bool) -> void:
	_priority.visible = active
	_trail.emitting = active


func set_weight_visual(weight: float) -> void:
	_weight = clampf(weight, 0.0, 1.0)
	_case.scale = Vector3(1.0 + _weight * 0.15, 1.0 - _weight * 0.07, 1.0 + _weight * 0.08)
	_case.position.y = -_weight * 0.035
	for index: int in _extra_bags.size():
		_extra_bags[index].visible = _weight >= (float(index) + 1.0) / 3.5
