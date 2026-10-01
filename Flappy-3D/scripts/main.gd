extends Node3D

enum GameState { READY, RUNNING, GAME_OVER }

const FlappyBirdScript := preload("res://scripts/bird.gd")
const PipePairScript := preload("res://scripts/pipe_pair.gd")
const SoundFXScript := preload("res://scripts/sound_fx.gd")

const BIRD_START := Vector3(0.0, 2.45, 0.0)
const WORLD_BOTTOM := -3.0
const WORLD_TOP := 8.7
const FIRST_PIPE_Z := -22.0
const PIPE_SPAWN_Z := -24.0
const BASE_PIPE_SPEED := 10.2
const MAX_PIPE_SPEED := 14.4

var _state := GameState.READY
var _score := 0
var _best_score := 0
var _spawn_elapsed := 0.0
var _restart_lock := 0.0
var _last_gap_y := BIRD_START.y
var _camera_shake := 0.0
var _fov_kick := 0.0
var _blur_strength := 0.0
var _rng := RandomNumberGenerator.new()
var _fx_rng := RandomNumberGenerator.new()

var _bird
var _camera: Camera3D
var _camera_base_position := Vector3.ZERO
var _pipe_container: Node3D
var _effects_container: Node3D
var _clouds: Array[Node3D] = []
var _ground_tiles: Array[MeshInstance3D] = []
var _speed_streaks: Array[MeshInstance3D] = []
var _sound
var _speed_blur_material: ShaderMaterial

var _score_label: Label
var _best_label: Label
var _ready_card: Control
var _game_over_overlay: Control
var _game_over_score: Label
var _game_over_best: Label
var _restart_button: Button
var _flash: ColorRect
var _speed_label: Label


func _ready() -> void:
	_rng.randomize()
	_fx_rng.randomize()
	_load_best_score()
	_build_world()
	_build_hud()
	_spawn_bird()
	_sound = SoundFXScript.new()
	_sound.name = "SoundFX"
	add_child(_sound)
	_reset_game()


func _physics_process(delta: float) -> void:
	if _state == GameState.RUNNING:
		_spawn_elapsed += delta
		var interval := maxf(1.12, 1.55 - float(_score) * 0.012)
		if _spawn_elapsed >= interval:
			_spawn_elapsed -= interval
			_spawn_pipe(PIPE_SPAWN_Z)

		if _bird.position.y <= WORLD_BOTTOM + 0.36 or _bird.position.y >= WORLD_TOP - 0.36:
			_trigger_game_over()

	if _state == GameState.GAME_OVER:
		_restart_lock = maxf(_restart_lock - delta, 0.0)


func _process(delta: float) -> void:
	var scenery_speed := 2.2
	if _state == GameState.RUNNING:
		scenery_speed = _current_pipe_speed()

	for cloud in _clouds:
		if not is_instance_valid(cloud):
			continue
		var factor := float(cloud.get_meta("speed_factor", 0.4))
		cloud.position.z += scenery_speed * factor * delta
		if cloud.position.z > 4.0:
			cloud.position.z -= 58.0
			cloud.position.x = _random_side_position(3.4, 12.0)
			cloud.position.y = _fx_rng.randf_range(-1.0, 8.5)

	for tile in _ground_tiles:
		tile.position.z += scenery_speed * delta
		if tile.position.z > 7.0:
			tile.position.z -= 84.0

	for streak in _speed_streaks:
		streak.position.z += scenery_speed * (2.15 if _state == GameState.RUNNING else 0.7) * delta
		if streak.position.z > 5.5:
			_recycle_speed_streak(streak)

	_update_chase_camera(delta)
	_update_speed_presentation(delta)


func _unhandled_input(event: InputEvent) -> void:
	var wants_flap := false
	if event.is_action_pressed("ui_accept"):
		wants_flap = true
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		wants_flap = key_event.pressed and not key_event.echo and (key_event.keycode == KEY_W or key_event.keycode == KEY_UP)
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		wants_flap = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		wants_flap = (event as InputEventScreenTouch).pressed

	if wants_flap:
		get_viewport().set_input_as_handled()
		_request_flap()


func _request_flap() -> void:
	match _state:
		GameState.READY:
			_start_game()
			_do_flap()
		GameState.RUNNING:
			_do_flap()
		GameState.GAME_OVER:
			if _restart_lock <= 0.0:
				_reset_game()
				_start_game()
				_do_flap()


func _start_game() -> void:
	_state = GameState.RUNNING
	_ready_card.hide()
	_game_over_overlay.hide()
	_score_label.show()
	_bird.start_flying()
	_spawn_elapsed = 0.0
	_spawn_pipe(FIRST_PIPE_Z)


func _do_flap() -> void:
	_bird.flap()
	_sound.play_flap()
	_camera_shake = maxf(_camera_shake, 0.045)
	_fov_kick = maxf(_fov_kick, 1.8)
	_spawn_flap_puff()


func _reset_game() -> void:
	_state = GameState.READY
	_score = 0
	_spawn_elapsed = 0.0
	_restart_lock = 0.0
	_last_gap_y = BIRD_START.y
	_camera_shake = 0.0
	_fov_kick = 0.0
	_blur_strength = 0.0
	_camera_base_position = Vector3(1.45, BIRD_START.y + 1.18, 6.8)
	_camera.position = _camera_base_position
	_score_label.text = "0"
	_score_label.hide()
	_best_label.text = "BEST  %d" % _best_score
	_ready_card.show()
	_game_over_overlay.hide()
	_bird.reset_bird(BIRD_START)

	for child in _pipe_container.get_children():
		if child.has_method("set_running"):
			child.call("set_running", false)
		child.queue_free()


func _spawn_pipe(z_position: float) -> void:
	var gap_size := maxf(2.9, 3.8 - float(_score) * 0.026)
	var min_center := WORLD_BOTTOM + gap_size * 0.5 + 0.72
	var max_center := WORLD_TOP - gap_size * 0.5 - 0.72
	var target_center := _rng.randf_range(min_center, max_center)
	var smoothed_center := lerpf(_last_gap_y, target_center, 0.68)
	var gap_center := clampf(
		smoothed_center,
		maxf(min_center, _last_gap_y - 2.9),
		minf(max_center, _last_gap_y + 2.9)
	)
	_last_gap_y = gap_center

	var pair := PipePairScript.new()
	pair.name = "PipePair%d" % (_pipe_container.get_child_count() + 1)
	pair.configure(z_position, gap_center, gap_size, _current_pipe_speed(), _score % 3)
	pair.bird_hit.connect(_on_pipe_hit)
	pair.point_scored.connect(_on_pipe_scored)
	_pipe_container.add_child(pair)


func _current_pipe_speed() -> float:
	return BASE_PIPE_SPEED + minf(float(_score) * 0.18, MAX_PIPE_SPEED - BASE_PIPE_SPEED)


func _on_pipe_hit() -> void:
	_trigger_game_over()


func _on_pipe_scored() -> void:
	if _state != GameState.RUNNING:
		return
	_score += 1
	_score_label.text = str(_score)
	_sound.play_score()
	_camera_shake = maxf(_camera_shake, 0.065)
	_fov_kick = maxf(_fov_kick, 2.7)
	_pop_score()

	if _score > _best_score:
		_best_score = _score
		_best_label.text = "BEST  %d" % _best_score


func _trigger_game_over() -> void:
	if _state != GameState.RUNNING:
		return
	_state = GameState.GAME_OVER
	_restart_lock = 0.42
	_bird.die()
	_sound.play_hit()
	_camera_shake = 0.34

	for child in _pipe_container.get_children():
		if child.has_method("set_running"):
			child.call("set_running", false)

	if _score >= _best_score:
		_best_score = _score
		_save_best_score()

	_game_over_score.text = "SCORE   %d" % _score
	_game_over_best.text = "BEST    %d" % _best_score
	_game_over_overlay.show()
	_restart_button.grab_focus()
	_flash.color = Color(1.0, 1.0, 1.0, 0.48)
	var flash_tween := create_tween()
	flash_tween.tween_property(_flash, "color", Color(1.0, 1.0, 1.0, 0.0), 0.26)


func _build_world() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.08, 0.2)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.76, 1.0)
	environment.ambient_light_energy = 0.82
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.19, 0.58, 0.78)
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.18
	environment.glow_enabled = true
	environment.glow_intensity = 0.82
	environment.glow_bloom = 0.12
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-34.0, -26.0, -18.0)
	sun.light_color = Color(1.0, 0.88, 0.68)
	sun.light_energy = 1.28
	sun.shadow_enabled = true
	add_child(sun)

	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 68.0
	_camera.near = 0.08
	_camera.far = 110.0
	_camera.position = Vector3(1.45, BIRD_START.y + 1.18, 6.8)
	_camera.current = true
	add_child(_camera)
	_camera.look_at(Vector3(0.0, BIRD_START.y + 0.25, -12.0), Vector3.UP)
	_camera_base_position = _camera.position

	_pipe_container = Node3D.new()
	_pipe_container.name = "Pipes"
	add_child(_pipe_container)
	_effects_container = Node3D.new()
	_effects_container.name = "Effects"
	add_child(_effects_container)

	_build_fake_sky()
	_build_ground()
	_build_clouds()
	_build_speed_streaks()
	_build_speed_overlay()


func _build_fake_sky() -> void:
	var sky_shader := Shader.new()
	sky_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void fragment() {
	vec3 horizon = vec3(0.18, 0.72, 0.88);
	vec3 mid_sky = vec3(0.055, 0.30, 0.62);
	vec3 zenith = vec3(0.018, 0.055, 0.18);
	float vertical = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 sky = mix(horizon, mid_sky, smoothstep(0.0, 0.5, vertical));
	sky = mix(sky, zenith, smoothstep(0.48, 1.0, vertical));
	float haze = exp(-pow((UV.y - 0.63) * 11.0, 2.0));
	sky += vec3(0.38, 0.18, 0.07) * haze * 0.48;
	ALBEDO = sky;
}
"""
	var sky_material := ShaderMaterial.new()
	sky_material.shader = sky_shader
	var sky_mesh := QuadMesh.new()
	sky_mesh.size = Vector2(240.0, 140.0)
	var sky_backdrop := MeshInstance3D.new()
	sky_backdrop.name = "FakeSkyBackdrop"
	sky_backdrop.mesh = sky_mesh
	sky_backdrop.material_override = sky_material
	sky_backdrop.position = Vector3(0.0, 11.0, -55.0)
	sky_backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sky_backdrop)

	var sun_material := StandardMaterial3D.new()
	sun_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_material.albedo_color = Color(1.0, 0.56, 0.16)
	sun_material.emission_enabled = true
	sun_material.emission = Color(1.0, 0.28, 0.04)
	sun_material.emission_energy_multiplier = 4.0
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 2.6
	sun_mesh.height = 5.2
	sun_mesh.radial_segments = 24
	sun_mesh.rings = 12
	var fake_sun := MeshInstance3D.new()
	fake_sun.name = "FakeSun"
	fake_sun.mesh = sun_mesh
	fake_sun.material_override = sun_material
	fake_sun.position = Vector3(-16.0, 15.0, -43.0)
	fake_sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fake_sun)


func _build_ground() -> void:
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.025, 0.12, 0.19)
	ground_material.metallic = 0.28
	ground_material.roughness = 0.62
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(18.0, 0.5, 96.0)
	var ground := MeshInstance3D.new()
	ground.name = "Skyway"
	ground.mesh = ground_mesh
	ground.material_override = ground_material
	ground.position = Vector3(0.0, -3.26, -38.0)
	add_child(ground)

	var rail_material := StandardMaterial3D.new()
	rail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rail_material.albedo_color = Color(0.12, 0.9, 1.0)
	rail_material.emission_enabled = true
	rail_material.emission = Color(0.02, 0.55, 1.0)
	rail_material.emission_energy_multiplier = 2.4
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.13, 0.16, 96.0)
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.material_override = rail_material
		rail.position = Vector3(side * 6.0, -2.95, -38.0)
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rail)

	var tile_material := StandardMaterial3D.new()
	tile_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tile_material.albedo_color = Color(0.25, 0.94, 1.0)
	tile_material.emission_enabled = true
	tile_material.emission = Color(0.05, 0.58, 1.0)
	tile_material.emission_energy_multiplier = 1.8
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(0.18, 0.05, 1.7)
	for index in 32:
		for side in [-1.0, 1.0]:
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh
			tile.material_override = tile_material
			tile.position = Vector3(side * 5.35, -2.94, 6.0 - float(index) * 2.65)
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(tile)
			_ground_tiles.append(tile)


func _build_clouds() -> void:
	var cloud_material := StandardMaterial3D.new()
	cloud_material.albedo_color = Color(0.88, 0.96, 1.0)
	cloud_material.roughness = 1.0
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radius = 0.55
	cloud_mesh.height = 1.0
	cloud_mesh.radial_segments = 12
	cloud_mesh.rings = 7

	for index in 18:
		var cloud := Node3D.new()
		cloud.name = "Cloud%d" % index
		cloud.position = Vector3(
			_random_side_position(3.4, 12.0),
			_fx_rng.randf_range(-1.0, 8.5),
			_fx_rng.randf_range(-52.0, -6.0)
		)
		var depth_factor := remap(cloud.position.z, -52.0, -6.0, 0.24, 0.66)
		cloud.set_meta("speed_factor", depth_factor)
		add_child(cloud)
		_clouds.append(cloud)

		var puff_count := _fx_rng.randi_range(3, 5)
		for puff_index in puff_count:
			var puff := MeshInstance3D.new()
			puff.mesh = cloud_mesh
			puff.material_override = cloud_material
			puff.position = Vector3(
				(float(puff_index) - float(puff_count - 1) * 0.5) * 0.48,
				_fx_rng.randf_range(-0.1, 0.22),
				_fx_rng.randf_range(-0.12, 0.12)
			)
			var puff_scale := _fx_rng.randf_range(0.62, 1.08)
			puff.scale = Vector3(puff_scale, puff_scale * 0.72, puff_scale)
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(puff)


func _build_speed_streaks() -> void:
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.albedo_color = Color(0.58, 0.95, 1.0)
	streak_material.emission_enabled = true
	streak_material.emission = Color(0.1, 0.72, 1.0)
	streak_material.emission_energy_multiplier = 3.2
	var streak_mesh := BoxMesh.new()
	streak_mesh.size = Vector3(0.035, 0.035, 2.3)

	for index in 34:
		var streak := MeshInstance3D.new()
		streak.name = "SpeedStreak%d" % index
		streak.mesh = streak_mesh
		streak.material_override = streak_material
		streak.position = Vector3(
			_random_side_position(2.8, 9.5),
			_fx_rng.randf_range(-2.1, 8.2),
			_fx_rng.randf_range(-31.0, 4.0)
		)
		streak.scale.z = _fx_rng.randf_range(0.55, 1.8)
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(streak)
		_speed_streaks.append(streak)


func _build_speed_overlay() -> void:
	var overlay_layer := CanvasLayer.new()
	overlay_layer.name = "SpeedBlurLayer"
	overlay_layer.layer = 1
	add_child(overlay_layer)

	var blur_shader := Shader.new()
	blur_shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float blur_strength : hint_range(0.0, 0.035) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 direction = uv - vec2(0.5, 0.52);
	vec4 color = texture(screen_texture, uv) * 0.34;
	color += texture(screen_texture, uv - direction * blur_strength * 0.28) * 0.24;
	color += texture(screen_texture, uv - direction * blur_strength * 0.58) * 0.20;
	color += texture(screen_texture, uv - direction * blur_strength * 0.96) * 0.14;
	color += texture(screen_texture, uv - direction * blur_strength * 1.42) * 0.08;
	float edge = smoothstep(0.28, 0.72, length((uv - 0.5) * vec2(1.0, 0.68)));
	color.rgb *= 1.0 - edge * vignette_strength;
	COLOR = color;
}
"""
	_speed_blur_material = ShaderMaterial.new()
	_speed_blur_material.shader = blur_shader
	var overlay := ColorRect.new()
	overlay.name = "RadialSpeedBlur"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = _speed_blur_material
	overlay_layer.add_child(overlay)


func _spawn_bird() -> void:
	_bird = FlappyBirdScript.new()
	_bird.name = "Bird"
	add_child(_bird)
	_bird.reset_bird(BIRD_START)


func _spawn_flap_puff() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.96, 0.8, 0.52)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var puff_mesh := SphereMesh.new()
	puff_mesh.radius = 0.14
	puff_mesh.height = 0.24
	puff_mesh.radial_segments = 10
	puff_mesh.rings = 6
	var puff := MeshInstance3D.new()
	puff.mesh = puff_mesh
	puff.material_override = material
	puff.position = _bird.position + Vector3(0.0, -0.08, 0.52)
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_effects_container.add_child(puff)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(puff, "scale", Vector3(2.8, 2.8, 2.8), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(puff, "position", puff.position + Vector3(0.0, 0.08, 0.85), 0.28)
	tween.tween_property(material, "albedo_color", Color(1.0, 0.96, 0.8, 0.0), 0.28)
	tween.chain().tween_callback(puff.queue_free)


func _update_chase_camera(delta: float) -> void:
	if not is_instance_valid(_bird) or not is_instance_valid(_camera):
		return

	_camera_shake = maxf(_camera_shake - delta * 1.35, 0.0)
	var desired_position := Vector3(
		1.45,
		clampf(_bird.position.y + 1.18, 1.5, 6.45),
		6.8
	)
	_camera_base_position = _camera_base_position.lerp(desired_position, 1.0 - exp(-4.6 * delta))
	var shake_offset := Vector3.ZERO
	if _camera_shake > 0.0:
		shake_offset = Vector3(
			_fx_rng.randf_range(-_camera_shake, _camera_shake),
			_fx_rng.randf_range(-_camera_shake, _camera_shake),
			_fx_rng.randf_range(-_camera_shake, _camera_shake) * 0.3
		)
	_camera.position = _camera_base_position + shake_offset
	_camera.look_at(Vector3(0.0, _bird.position.y + 0.25, -12.0), Vector3.UP)


func _update_speed_presentation(delta: float) -> void:
	_fov_kick = maxf(_fov_kick - delta * 6.0, 0.0)
	var speed_ratio := clampf((_current_pipe_speed() - BASE_PIPE_SPEED) / (MAX_PIPE_SPEED - BASE_PIPE_SPEED), 0.0, 1.0)
	var target_fov := 69.0
	var target_blur := 0.0015
	var target_vignette := 0.2
	if _state == GameState.RUNNING:
		target_fov = 76.0 + speed_ratio * 4.0 + _fov_kick
		target_blur = 0.012 + speed_ratio * 0.008
		target_vignette = 0.28 + speed_ratio * 0.08
		_speed_label.text = "AIR SPEED  %03d KM/H" % int(_current_pipe_speed() * 24.0)
	elif _state == GameState.GAME_OVER:
		target_fov = 72.0
		target_blur = 0.004
		target_vignette = 0.3
		_speed_label.text = "AIR SPEED  000 KM/H"
	else:
		_speed_label.text = "AIR SPEED  READY"

	_camera.fov = lerpf(_camera.fov, target_fov, 1.0 - exp(-5.8 * delta))
	_blur_strength = lerpf(_blur_strength, target_blur, 1.0 - exp(-4.5 * delta))
	_speed_blur_material.set_shader_parameter("blur_strength", _blur_strength)
	_speed_blur_material.set_shader_parameter("vignette_strength", target_vignette)


func _recycle_speed_streak(streak: MeshInstance3D) -> void:
	streak.position = Vector3(
		_random_side_position(2.8, 9.5),
		_fx_rng.randf_range(-2.1, 8.2),
		_fx_rng.randf_range(-34.0, -25.0)
	)
	streak.scale.z = _fx_rng.randf_range(0.55, 1.8)


func _random_side_position(minimum: float, maximum: float) -> float:
	var direction := -1.0 if _fx_rng.randi() % 2 == 0 else 1.0
	return _fx_rng.randf_range(minimum, maximum) * direction


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	canvas.layer = 5
	add_child(canvas)

	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_score_label = _make_label("0", 68, Color(1.0, 0.97, 0.86))
	_score_label.name = "Score"
	_score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_score_label.offset_left = -160.0
	_score_label.offset_right = 160.0
	_score_label.offset_top = 20.0
	_score_label.offset_bottom = 112.0
	_score_label.add_theme_constant_override("outline_size", 13)
	_score_label.add_theme_color_override("font_outline_color", Color(0.05, 0.14, 0.23))
	root.add_child(_score_label)

	_best_label = _make_label("BEST  0", 22, Color(1.0, 0.97, 0.86))
	_best_label.name = "BestScore"
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_best_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_best_label.offset_left = -240.0
	_best_label.offset_right = -30.0
	_best_label.offset_top = 28.0
	_best_label.offset_bottom = 64.0
	_best_label.add_theme_constant_override("outline_size", 6)
	_best_label.add_theme_color_override("font_outline_color", Color(0.05, 0.14, 0.23))
	root.add_child(_best_label)

	_speed_label = _make_label("AIR SPEED  READY", 18, Color(0.48, 0.94, 1.0))
	_speed_label.name = "AirSpeed"
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speed_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_speed_label.offset_left = 30.0
	_speed_label.offset_right = 310.0
	_speed_label.offset_top = 28.0
	_speed_label.offset_bottom = 66.0
	_speed_label.add_theme_constant_override("outline_size", 6)
	_speed_label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.16))
	root.add_child(_speed_label)

	_ready_card = _make_card(Vector2(500.0, 222.0), Color(0.05, 0.15, 0.24, 0.9))
	_ready_card.name = "ReadyCard"
	_ready_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_ready_card)
	var ready_box := VBoxContainer.new()
	ready_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ready_box.alignment = BoxContainer.ALIGNMENT_CENTER
	ready_box.add_theme_constant_override("separation", 7)
	_ready_card.add_child(ready_box)
	var title := _make_label("FLAPPY 3D", 48, Color(1.0, 0.77, 0.19))
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color(0.76, 0.17, 0.23))
	ready_box.add_child(title)
	var subtitle := _make_label("CHASE THE HORIZON.", 20, Color(0.85, 0.95, 1.0))
	ready_box.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 8.0
	ready_box.add_child(spacer)
	var prompt := _make_label("CLICK  •  TAP  •  SPACE  TO FLAP", 18, Color(1.0, 0.97, 0.86))
	ready_box.add_child(prompt)

	_game_over_overlay = ColorRect.new()
	_game_over_overlay.name = "GameOverOverlay"
	_game_over_overlay.color = Color(0.025, 0.08, 0.14, 0.46)
	_game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(_game_over_overlay)
	var game_over_card := _make_card(Vector2(480.0, 330.0), Color(0.05, 0.15, 0.24, 0.96))
	_game_over_overlay.add_child(game_over_card)
	var game_over_box := VBoxContainer.new()
	game_over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_box.add_theme_constant_override("separation", 11)
	game_over_card.add_child(game_over_box)
	var game_over_title := _make_label("WING DOWN!", 43, Color(1.0, 0.42, 0.38))
	game_over_box.add_child(game_over_title)
	_game_over_score = _make_label("SCORE   0", 25, Color(1.0, 0.97, 0.86))
	game_over_box.add_child(_game_over_score)
	_game_over_best = _make_label("BEST    0", 22, Color(0.66, 0.9, 1.0))
	game_over_box.add_child(_game_over_best)
	var game_spacer := Control.new()
	game_spacer.custom_minimum_size.y = 6.0
	game_over_box.add_child(game_spacer)
	_restart_button = Button.new()
	_restart_button.text = "FLY AGAIN"
	_restart_button.custom_minimum_size = Vector2(250.0, 58.0)
	_restart_button.add_theme_font_size_override("font_size", 22)
	_restart_button.add_theme_color_override("font_color", Color(0.05, 0.14, 0.23))
	_restart_button.add_theme_color_override("font_hover_color", Color(0.05, 0.14, 0.23))
	_restart_button.add_theme_stylebox_override("normal", _button_style(Color(1.0, 0.77, 0.19)))
	_restart_button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.86, 0.35)))
	_restart_button.add_theme_stylebox_override("pressed", _button_style(Color(0.93, 0.62, 0.12)))
	_restart_button.pressed.connect(_request_flap)
	game_over_box.add_child(_restart_button)
	var restart_hint := _make_label("or press Space", 16, Color(0.7, 0.82, 0.89))
	game_over_box.add_child(restart_hint)

	_flash = ColorRect.new()
	_flash.name = "ImpactFlash"
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_card(card_size: Vector2, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -card_size.x * 0.5
	card.offset_right = card_size.x * 0.5
	card.offset_top = -card_size.y * 0.5
	card.offset_bottom = card_size.y * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	style.corner_radius_top_left = 26
	style.corner_radius_top_right = 26
	style.corner_radius_bottom_left = 26
	style.corner_radius_bottom_right = 26
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	card.add_theme_stylebox_override("panel", style)
	return card


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 17
	style.corner_radius_top_right = 17
	style.corner_radius_bottom_left = 17
	style.corner_radius_bottom_right = 17
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _pop_score() -> void:
	_score_label.pivot_offset = _score_label.size * 0.5
	_score_label.scale = Vector2(1.28, 1.28)
	var tween := create_tween()
	tween.tween_property(_score_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load("user://flappy_3d_score.cfg") == OK:
		_best_score = int(config.get_value("scores", "best", 0))


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "best", _best_score)
	config.save("user://flappy_3d_score.cfg")
