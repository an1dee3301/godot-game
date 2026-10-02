class_name MuseumAtmosphere
extends Node3D
## Procedural night sky, weather, moonlit glazing and museum alarm lighting.

signal lightning(strength: float)

const SKY_CODE := """
shader_type sky;
uniform float storm_time = 0.0;
uniform float flash = 0.0;
uniform vec3 moon_dir = vec3(-0.36, 0.36, -0.86);
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
 vec2 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash21(i), hash21(i+vec2(1.0,0.0)), f.x), mix(hash21(i+vec2(0.0,1.0)), hash21(i+1.0), f.x), f.y);
}
float fbm(vec2 p) { float v=0.0; float a=0.52; for(int i=0;i<4;i++){v+=a*noise2(p);p=p*2.07+vec2(8.7,3.1);a*=0.49;} return v; }
void sky() {
 vec3 d=normalize(EYEDIR);
 float horizon=1.0-smoothstep(-0.05,0.45,d.y);
 vec3 col=mix(vec3(0.003,0.008,0.030),vec3(0.018,0.040,0.092),clamp(1.0-d.y,0.0,1.0));
 col+=vec3(0.060,0.035,0.045)*pow(horizon,7.0);
 vec2 star_uv=vec2(atan(d.z,d.x),asin(clamp(d.y,-1.0,1.0)))*vec2(195.0,280.0);
 float star=step(0.9978,hash21(floor(star_uv)))*pow(max(0.0,1.0-length(fract(star_uv)-0.5)*1.6),6.0);
 float clouds=fbm(d.xz/max(0.20,d.y+0.20)*2.6+vec2(storm_time*0.012,storm_time*0.004));
 clouds=smoothstep(0.45,0.70,clouds+0.11*(1.0-d.y));
 clouds*=smoothstep(-0.02,0.19,d.y);
 col+=vec3(0.45,0.57,0.78)*star*(1.0-clouds);
 vec3 md=normalize(moon_dir);
 float angle=dot(d,md);
 float disc=smoothstep(0.9967,0.9975,angle);
 float halo=pow(max(angle,0.0),80.0)*0.14+pow(max(angle,0.0),450.0)*0.17;
 col+=vec3(0.52,0.72,1.0)*halo;
 col+=vec3(2.6,2.8,3.0)*disc*(1.0-clouds*0.48);
 col=mix(col,vec3(0.024,0.037,0.069)+vec3(0.25,0.34,0.51)*flash,clouds*0.78);
 col+=vec3(0.45,0.53,0.70)*flash*(0.4+clouds*0.6);
 COLOR=col;
}
"""

const GLASS_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.16,0.25,0.34,0.18);
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 q=UV*vec2(48.0,22.0);
 vec2 cell=floor(q);
 float speed=0.18+0.52*h(vec2(cell.x,1.0));
 float head=fract(h(vec2(cell.x,4.0))+TIME*speed);
 float x=abs(fract(q.x)-0.5);
 float y=fract(q.y+head);
 float drop=exp(-x*x*190.0)*exp(-y*19.0);
 float trail=exp(-x*x*380.0)*smoothstep(0.95,0.1,y)*0.21;
 float bead=drop+trail;
 ALBEDO=tint.rgb+vec3(0.11,0.17,0.22)*bead;
 METALLIC=0.05;
 ROUGHNESS=mix(0.22,0.055,clamp(bead,0.0,1.0));
 SPECULAR=0.85;
 ALPHA=clamp(tint.a+bead*0.42+0.045*pow(1.0-abs(dot(NORMAL,VIEW)),3.0),0.0,0.8);
}
"""

const CITY_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec3 facade : source_color = vec3(0.013,0.020,0.036);
uniform float seed = 0.0;
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=UV*vec2(18.0,34.0);
 vec2 cell=floor(p);
 vec2 f=fract(p);
 float lit=step(0.73,h(cell+seed));
 float window=step(0.28,f.x)*step(f.x,0.69)*step(0.26,f.y)*step(f.y,0.72)*lit;
 vec3 warm=mix(vec3(0.18,0.31,0.55),vec3(1.0,0.62,0.24),step(0.55,h(cell+seed+19.0)));
 ALBEDO=facade;
 EMISSION=warm*window*1.25;
}
"""

var _environment: Environment
var _sky_material: ShaderMaterial
var _moon: DirectionalLight3D
var _flash_light: DirectionalLight3D
var _window_beams: Array[SpotLight3D] = []
var _beacons: Array[Node3D] = []
var _beacon_lights: Array[SpotLight3D] = []
var _police_lights: Array[OmniLight3D] = []
var _alarm_on := false
var _clock := 0.0
var _next_flash := 10.0
var _flash_age := 100.0
var _flash_strength := 0.0
var _double_flash := false
var _bolt: MeshInstance3D
var _rng := RandomNumberGenerator.new()
var _base_ambient := Color(0.27, 0.32, 0.43)
var _base_fog := Color(0.22, 0.29, 0.39)


## Build the sky, windows and exterior effects around the playable AABB.
func setup(bounds: AABB, windows: Array, alarm_points: PackedVector3Array) -> void:
	_rng.randomize()
	_make_environment()
	_make_moon()
	for entry: Variant in windows:
		if entry is Dictionary:
			var window: Dictionary = entry
			if window.has("transform") and window.has("size"):
				_make_window(window["transform"], window["size"])
	_make_skyline(bounds)
	_make_alarm_points(alarm_points)
	if DisplayServer.get_name() != "headless":
		_make_rain(bounds)
	_next_flash = _rng.randf_range(7.0, 18.0)
	set_process(true)


## Enable or disable the rotating red museum alarm.
func set_alarm(on: bool) -> void:
	_alarm_on = on
	for beacon: Node3D in _beacons:
		beacon.visible = on
	for light: OmniLight3D in _police_lights:
		light.visible = on
	if not on and _environment != null:
		_environment.volumetric_fog_albedo = _base_fog
		_environment.ambient_light_color = _base_ambient


## Start a lightning burst immediately; emits lightning at its first visible frame.
func flash_now(strength: float = 1.0) -> void:
	_flash_strength = clampf(strength, 0.3, 1.0)
	_flash_age = 0.0
	_double_flash = _rng.randf() < 0.32
	lightning.emit(_flash_strength)
	if _rng.randf() < 0.48:
		_make_bolt()


func _process(delta: float) -> void:
	if _sky_material == null or _environment == null or _flash_light == null:
		return
	_clock += delta
	_sky_material.set_shader_parameter("storm_time", _clock)
	_next_flash -= delta
	if _next_flash <= 0.0:
		flash_now(_rng.randf_range(0.45, 1.0))
		_next_flash = _rng.randf_range(7.0, 18.0)
	_flash_age += delta
	var pulse := 0.0
	if _flash_age < 0.33:
		pulse = pow(maxf(0.0, 1.0 - _flash_age / 0.33), 2.2)
		if _flash_age > 0.11 and _flash_age < 0.15:
			pulse *= 0.12
	elif _double_flash and _flash_age < 0.52:
		pulse = pow(maxf(0.0, 1.0 - (_flash_age - 0.33) / 0.19), 2.0) * 0.57
	pulse *= _flash_strength
	_flash_light.light_energy = pulse * 3.6
	_environment.ambient_light_energy = 0.92 + pulse * 1.4
	for beam: SpotLight3D in _window_beams:
		beam.light_energy = 0.82 + pulse * 3.4
	_sky_material.set_shader_parameter("flash", pulse)
	_environment.volumetric_fog_emission = Color(0.22, 0.34, 0.55) * pulse * 0.32
	_environment.volumetric_fog_emission_energy = pulse
	if _bolt != null:
		_bolt.visible = pulse > 0.13
		if _flash_age > 0.55:
			_bolt.queue_free()
			_bolt = null
	if _alarm_on:
		var beat := 0.5 + 0.5 * sin(_clock * 4.4)
		_environment.volumetric_fog_albedo = _base_fog.lerp(Color(0.31, 0.105, 0.13), 0.13 + beat * 0.16)
		_environment.ambient_light_color = _base_ambient.lerp(Color(0.22, 0.09, 0.14), beat * 0.18)
		for beacon: Node3D in _beacons:
			beacon.rotation.y += delta * 3.1
		for light: SpotLight3D in _beacon_lights:
			light.light_energy = 1.0 + beat * 0.75
		for i: int in _police_lights.size():
			_police_lights[i].light_energy = 0.6 + 0.55 * (0.5 + 0.5 * sin(_clock * 9.0 + float(i) * PI))


func _make_environment() -> void:
	var sky_shader := Shader.new()
	sky_shader.code = SKY_CODE
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = sky_shader
	var sky := Sky.new()
	sky.sky_material = _sky_material
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = _base_ambient
	_environment.ambient_light_energy = 0.92
	_environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.48
	_environment.glow_strength = 0.62
	_environment.glow_bloom = 0.045
	_environment.glow_hdr_threshold = 1.7
	_environment.set("glow_levels/1", 0.48)
	_environment.set("glow_levels/2", 0.55)
	_environment.set("glow_levels/3", 0.35)
	_environment.set("glow_levels/4", 0.15)
	_environment.ssao_enabled = true
	_environment.ssao_radius = 1.7
	_environment.ssao_intensity = 0.85
	_environment.ssil_enabled = true
	_environment.ssil_radius = 3.0
	_environment.ssil_intensity = 0.62
	_environment.ssr_enabled = true
	_environment.ssr_max_steps = 48
	_environment.volumetric_fog_enabled = true
	_environment.volumetric_fog_density = 0.011
	_environment.volumetric_fog_albedo = _base_fog
	_environment.volumetric_fog_anisotropy = 0.6
	_environment.volumetric_fog_gi_inject = 0.45
	_environment.volumetric_fog_length = 84.0
	_environment.volumetric_fog_ambient_inject = 0.32
	_environment.adjustment_enabled = true
	_environment.adjustment_contrast = 1.04
	_environment.adjustment_saturation = 0.95
	var world_env := WorldEnvironment.new()
	world_env.name = "MoonlitWorld"
	world_env.environment = _environment
	add_child(world_env)


func _make_moon() -> void:
	_moon = DirectionalLight3D.new()
	_moon.name = "Moonlight"
	_moon.light_color = Color(0.70, 0.81, 1.0)
	_moon.light_energy = 0.75
	_moon.shadow_enabled = true
	_moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_moon.directional_shadow_max_distance = 80.0
	_moon.directional_shadow_blend_splits = true
	_moon.light_volumetric_fog_energy = 0.7
	_moon.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(155.0), deg_to_rad(10.0))
	add_child(_moon)
	_flash_light = DirectionalLight3D.new()
	_flash_light.name = "StormFlash"
	_flash_light.light_color = Color(0.73, 0.83, 1.0)
	_flash_light.light_energy = 0.0
	_flash_light.shadow_enabled = false
	_flash_light.light_volumetric_fog_energy = 1.2
	_flash_light.rotation = Vector3(deg_to_rad(-56.0), deg_to_rad(-30.0), 0.0)
	add_child(_flash_light)


func _make_window(world_transform: Transform3D, opening: Vector2) -> void:
	var root := Node3D.new()
	root.name = "StormWindow"
	add_child(root)
	root.transform = world_transform
	var w: float = maxf(0.6, opening.x)
	var h: float = maxf(0.6, opening.y)
	var metal := _material(Color(0.035, 0.047, 0.063), 0.28, 0.75)
	var trim := _material(Color(0.13, 0.12, 0.12), 0.54, 0.55)
	for side: float in [-1.0, 1.0]:
		_add_box(root, Vector3(side * w * 0.5, 0.0, 0.0), Vector3(0.15, h + 0.15, 0.065), trim, "OuterJamb")
		_add_box(root, Vector3(0.0, side * h * 0.5, 0.0), Vector3(w + 0.15, 0.15, 0.065), trim, "OuterRail")
	# The glass is a separate transparent surface just beyond the inner frame.
	var glass_shader := Shader.new()
	glass_shader.code = GLASS_CODE
	var glass_mat := ShaderMaterial.new()
	glass_mat.shader = glass_shader
	var pane := MeshInstance3D.new()
	pane.name = "RainStreakedGlass"
	var plane := PlaneMesh.new()
	plane.size = Vector2(w - 0.12, h - 0.12)
	pane.mesh = plane
	pane.material_override = glass_mat
	pane.rotation.x = -PI * 0.5
	pane.position.z = 0.035
	root.add_child(pane)
	# Frame is built as slim bars so the opening stays transparent from either side.
	for side: float in [-1.0, 1.0]:
		_add_box(root, Vector3(side * (w * 0.5 - 0.045), 0.0, 0.065), Vector3(0.09, h, 0.11), metal, "Jamb")
		_add_box(root, Vector3(0.0, side * (h * 0.5 - 0.045), 0.065), Vector3(w, 0.09, 0.11), metal, "Rail")
	_add_box(root, Vector3(0.0, 0.0, 0.07), Vector3(0.065, h, 0.09), metal, "Mullion")
	if w > 2.6:
		for side: float in [-1.0, 1.0]:
			_add_box(root, Vector3(side * w / 4.0, 0.0, 0.07), Vector3(0.045, h, 0.08), metal, "Mullion")
	_add_box(root, Vector3(0.0, -h * 0.10, 0.07), Vector3(w, 0.045, 0.08), metal, "Crossbar")
	var blocker := StaticBody3D.new()
	blocker.name = "GlassCollision"
	blocker.collision_layer = KK.LAYER_GLASS
	blocker.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w - 0.11, h - 0.11, 0.045)
	shape.shape = box
	blocker.add_child(shape)
	root.add_child(blocker)
	var shaft := SpotLight3D.new()
	shaft.name = "Moonbeam"
	shaft.position = Vector3(0.0, 0.0, 2.8)
	shaft.light_color = Color(0.48, 0.66, 1.0)
	shaft.light_energy = 0.82
	shaft.spot_range = 12.0
	shaft.spot_angle = 28.0
	shaft.shadow_enabled = false
	shaft.light_volumetric_fog_energy = 1.7
	root.add_child(shaft)
	_window_beams.append(shaft)


func _make_skyline(bounds: AABB) -> void:
	var city := Node3D.new()
	city.name = "DistantCity"
	add_child(city)
	var z: float = bounds.position.z - 78.0
	var mid_x: float = bounds.position.x + bounds.size.x * 0.5
	var dark := _material(Color(0.008, 0.014, 0.026), 0.9)
	for i: int in 32:
		var x := mid_x + (float(i) - 15.5) * 8.0
		var height := _rng.randf_range(9.0, 32.0)
		var width := _rng.randf_range(4.5, 7.5)
		var shader := Shader.new()
		shader.code = CITY_CODE
		var facade := ShaderMaterial.new()
		facade.shader = shader
		facade.set_shader_parameter("seed", float(i) * 7.31)
		_add_box(city, Vector3(x, height * 0.5 - 3.0, z + _rng.randf_range(-5.0, 5.0)), Vector3(width, height, 5.0), facade, "CityBlock")
		if i % 5 == 0:
			_add_box(city, Vector3(x, height - 2.6, z), Vector3(width + 0.8, 0.55, 5.7), dark, "Cornice")
	var tower_x := mid_x + 35.0
	_add_box(city, Vector3(tower_x, 16.0, z + 6.0), Vector3(7.0, 32.0, 7.0), dark, "ClockTower")
	_add_box(city, Vector3(tower_x, 33.5, z + 6.0), Vector3(9.0, 3.0, 9.0), dark, "ClockCrown")
	_add_box(city, Vector3(tower_x, 38.0, z + 6.0), Vector3(0.55, 7.0, 0.55), dark, "Spire")
	var clock_face := _material(Color(0.62, 0.72, 0.7), 0.8)
	clock_face.emission_enabled = true
	clock_face.emission = Color(0.55, 0.65, 0.71)
	clock_face.emission_energy_multiplier = 0.75
	for side: float in [-1.0, 1.0]:
		var face := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 2.4
		disc.bottom_radius = 2.4
		disc.height = 0.08
		face.mesh = disc
		face.material_override = clock_face
		face.position = Vector3(tower_x, 28.0, z + 6.0 + side * 3.58)
		face.rotation.x = PI * 0.5
		city.add_child(face)
	for i: int in 2:
		var light := OmniLight3D.new()
		light.name = "PoliceStreetFlicker"
		light.position = Vector3(mid_x + 19.0 + float(i) * 5.0, 1.0, z + 27.0)
		light.light_color = Color(1.0, 0.04, 0.07) if i == 0 else Color(0.08, 0.17, 1.0)
		light.omni_range = 8.0
		light.visible = false
		city.add_child(light)
		_police_lights.append(light)


func _make_alarm_points(points: PackedVector3Array) -> void:
	var base := _material(Color(0.18, 0.19, 0.21), 0.3, 0.7)
	var red := _material(Color(0.55, 0.025, 0.035), 0.2)
	red.emission_enabled = true
	red.emission = Color(1.0, 0.015, 0.02)
	red.emission_energy_multiplier = 2.6
	for point: Vector3 in points:
		var root := Node3D.new()
		root.name = "RotatingAlarm"
		root.position = point
		root.visible = false
		add_child(root)
		_add_box(root, Vector3.ZERO, Vector3(0.43, 0.12, 0.43), base, "BeaconHousing")
		_add_box(root, Vector3(0.0, 0.12, 0.0), Vector3(0.29, 0.17, 0.20), red, "BeaconLens")
		for side: float in [-1.0, 1.0]:
			var spot := SpotLight3D.new()
			spot.position = Vector3(0.0, 0.12, 0.0)
			spot.rotation.y = 0.0 if side > 0.0 else PI
			spot.light_color = Color(1.0, 0.08, 0.075)
			spot.light_energy = 1.0
			spot.spot_range = 8.5
			spot.spot_angle = 34.0
			spot.shadow_enabled = false
			spot.light_volumetric_fog_energy = 1.6
			root.add_child(spot)
			_beacon_lights.append(spot)
		_beacons.append(root)


func _make_rain(bounds: AABB) -> void:
	var center := bounds.position + bounds.size * 0.5
	var xspan := bounds.size.x + 12.0
	var zspan := bounds.size.z + 12.0
	var y: float = bounds.position.y + bounds.size.y + 9.0
	var rain_mat := StandardMaterial3D.new()
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.albedo_color = Color(0.49, 0.68, 0.88, 0.38)
	rain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	rain_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var streak := QuadMesh.new()
	streak.size = Vector2(0.018, 0.7)
	streak.material = rain_mat
	for side: float in [-1.0, 1.0]:
		_add_rain_emitter(Vector3(center.x + side * (bounds.size.x * 0.5 + 3.0), y, center.z), Vector3(2.8, 0.1, zspan * 0.5), streak, 750)
		_add_rain_emitter(Vector3(center.x, y, center.z + side * (bounds.size.z * 0.5 + 3.0)), Vector3(xspan * 0.5, 0.1, 2.8), streak, 750)
	# The northmost seven metres of the level bounds are the open balcony.
	var balcony_z := bounds.position.z + 3.5
	_add_rain_emitter(Vector3(center.x, y, balcony_z), Vector3(minf(9.0, xspan * 0.2), 0.1, 3.4), streak, 650)
	var splash_mat := StandardMaterial3D.new()
	splash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	splash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splash_mat.albedo_color = Color(0.48, 0.68, 0.85, 0.24)
	splash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var splash := QuadMesh.new()
	splash.size = Vector2(0.12, 0.12)
	splash.material = splash_mat
	var p := GPUParticles3D.new()
	p.name = "BalconyRainSplashes"
	p.position = Vector3(center.x, bounds.position.y + 0.14, balcony_z)
	p.amount = 170
	p.lifetime = 0.42
	p.draw_pass_1 = splash
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(minf(9.0, xspan * 0.2), 0.04, 3.4)
	process.direction = Vector3.UP
	process.spread = 80.0
	process.initial_velocity_min = 0.25
	process.initial_velocity_max = 0.65
	process.gravity = Vector3(0.0, -3.0, 0.0)
	p.process_material = process
	add_child(p)


func _add_rain_emitter(pos: Vector3, extents: Vector3, mesh: Mesh, count: int) -> void:
	var p := GPUParticles3D.new()
	p.name = "ExteriorRain"
	p.position = pos
	p.amount = count
	p.lifetime = 1.8
	p.visibility_aabb = AABB(Vector3(-extents.x, -30.0, -extents.z), Vector3(extents.x * 2.0, 33.0, extents.z * 2.0))
	p.draw_pass_1 = mesh
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(0.12, -1.0, 0.03)
	process.particle_flag_align_y = true
	process.spread = 4.0
	process.initial_velocity_min = 11.0
	process.initial_velocity_max = 16.0
	process.gravity = Vector3(0.0, -9.0, 0.0)
	p.process_material = process
	add_child(p)


func _make_bolt() -> void:
	if _bolt != null:
		_bolt.queue_free()
	var points := PackedVector3Array()
	var x := _rng.randf_range(-24.0, 24.0)
	for i: int in 11:
		points.append(Vector3(x, 38.0 - float(i) * 3.3, -72.0))
		x += _rng.randf_range(-3.0, 3.0)
	var vertices := PackedVector3Array()
	for i: int in 10:
		var a := points[i]
		var b := points[i + 1]
		var width := 0.28 * (1.0 - float(i) / 15.0)
		var offset := Vector3(width, 0.0, 0.0)
		vertices.append_array(PackedVector3Array([a-offset, a+offset, b+offset, a-offset, b+offset, b-offset]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := _material(Color(0.7, 0.83, 1.0), 0.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.65, 0.82, 1.0)
	mat.emission_energy_multiplier = 7.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_bolt = MeshInstance3D.new()
	_bolt.name = "LightningBolt"
	_bolt.mesh = mesh
	_bolt.material_override = mat
	add_child(_bolt)


func _material(color: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	return mat


func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, label: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
