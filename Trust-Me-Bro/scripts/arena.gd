extends Node3D
## One Blender-authored game-show set. The four trap modules retain their quiz physics.
const INK := Color("263854")
const CREAM := Color("fff6df")
const COLORS: Array[Color] = [Color("fa636b"), Color("51a6f5"), Color("47cda4"), Color("ffcf4d")]
const LETTERS: Array[String] = ["A", "B", "C", "D"]
const PAD_SIZE: float = 6.5
const GARDEN = preload("res://assets/world/party_garden.glb")
const PLATFORM = preload("res://assets/world/answer_platform.glb")
const CLOUD = preload("res://assets/world/marshmallow_cloud.glb")
const SHOW_FONT = preload("res://assets/fonts/Fredoka.ttf")
const QuizScreenScript = preload("res://scripts/quiz_screen.gd")
const StageShowScript = preload("res://scripts/stage_show.gd")
const WATER_Y: float = -4.95

var tile_centers: Array[Vector3] = [Vector3(-3.4,0,-3.4),Vector3(3.4,0,-3.4),Vector3(-3.4,0,3.4),Vector3(3.4,0,3.4)]
var tiles: Array = []
var blackout: bool = false
var sweeper_active: bool = false
var sweeper_angle: float = 0.0
var conveyor_active: bool = false
var _tile_visuals: Array[Node3D] = []
var _tile_bodies: Array[StaticBody3D] = []
var _tile_shapes: Array[CollisionShape3D] = []
var _tile_labels: Array[Label3D] = []
var _tile_scales: Array[float] = [1.0,1.0,1.0,1.0]
var _open: Array[bool] = [false,false,false,false]
var _lights: Array[Light3D] = []
var _environment: Environment
var _sweeper: Node3D
var _conveyors: Array[Node3D] = []
var _clock: float = 0.0
var _mat_cache: Dictionary = {}
var _finale_step: int = 0
var _round_index: int = 0
var _ice_marks: Array[Node3D] = []
var _ice_materials: Dictionary = {}
var _pad_meshes: Array = []
var _clouds: Array[Node3D] = []
var _pad_tweens: Array = [null,null,null,null]
var _labels_visible: bool = true
var _highlight_index: int = -1
var _water: MeshInstance3D
var _pressure: float = 0.0
var _warning_materials: Array[StandardMaterial3D] = []
var _show_font: FontVariation
var quiz_screen: Node3D
var stage_show: Node3D
var _slop: MeshInstance3D
var _pillar: MeshInstance3D
var _pillar_material: ShaderMaterial
var _pillar_level: float = 0.0
var _medallion_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	name = "Arena"
	_build_lighting()
	var garden: Node3D = GARDEN.instantiate()
	garden.name = "BlenderShowground"
	add_child(garden)
	_build_water()
	for i in 4: _build_pad(i)
	_build_balcony_collision()
	quiz_screen = QuizScreenScript.new()
	quiz_screen.name = "GiantQuizScreen"
	add_child(quiz_screen)
	_build_clouds()
	_build_sweeper()
	_build_slop()
	_build_pillar()
	stage_show = StageShowScript.new()
	add_child(stage_show)

func _process(delta: float) -> void:
	_clock += delta
	if is_instance_valid(stage_show): stage_show.set_tension(_pressure)
	if _pillar_level > 0.002 or _pillar.visible:
		_pillar_level = lerpf(_pillar_level,0.0,1.0 - exp(-delta * 0.9))
		_pillar.visible = _pillar_level > 0.01
		_pillar_material.set_shader_parameter("strength",_pillar_level * (0.85 + 0.15 * sin(_clock * 14.0)))
	for i in _medallion_materials.size():
		var lit: float = 1.0 if i == _highlight_index else 0.0
		_medallion_materials[i].emission_energy_multiplier = lerpf(_medallion_materials[i].emission_energy_multiplier,(0.42 + sin(_clock * 9.0) * 0.14) * lit + 0.12 + _pressure * 0.25 * (0.5 + 0.5 * sin(_clock * 10.0)),1.0 - exp(-delta * 8.0))
	if not _warning_materials.is_empty():
		var pulse: float = (0.5 + 0.5 * sin(_clock * (8.0 + _pressure * 7.0))) * _pressure
		for material in _warning_materials:
			material.albedo_color = Color("edc765").lerp(Color("ff655d"),pulse)
			material.emission_enabled = _pressure > 0.01
			material.emission = Color("ff8b58")
			material.emission_energy_multiplier = pulse * 0.35
	for i in _clouds.size():
		var cloud: Node3D = _clouds[i]
		var home: Vector3 = cloud.get_meta("home")
		cloud.position = home + Vector3(sin(_clock * 0.10 + i) * 1.8,sin(_clock * 0.22 + i * 1.4) * 0.15,0)
	for root in _conveyors:
		if not conveyor_active: continue
		for chevron in root.get_children():
			var origin_z: float = float(chevron.get_meta("start_z",0.0))
			chevron.position.z = fposmod(origin_z - _clock * 1.7 + 2.6,5.2) - 2.6

func _physics_process(delta: float) -> void:
	if sweeper_active:
		sweeper_angle += delta * 1.12
		_sweeper.rotation.y = -sweeper_angle

func _build_lighting() -> void:
	var world: WorldEnvironment = WorldEnvironment.new()
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("4f9fd6")
	sky_material.sky_horizon_color = Color("ffd9a8")
	sky_material.ground_bottom_color = Color("3f97a8")
	sky_material.ground_horizon_color = Color("ffd9a8")
	sky_material.sky_energy_multiplier = 0.8
	sky_material.ground_energy_multiplier = 0.8
	sky.sky_material = sky_material
	_environment.sky = sky
	_environment.background_color = Color("accfcb")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("c9d6f2")
	_environment.ambient_light_energy = 0.22
	# A gentle filmic curve, bloom on emissive bulbs and a little extra colour.
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.tonemap_white = 1.9
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.42
	_environment.glow_strength = 0.9
	_environment.glow_bloom = 0.0
	_environment.glow_hdr_threshold = 1.15
	_environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.adjustment_enabled = true
	_environment.adjustment_saturation = 1.1
	_environment.adjustment_contrast = 1.05
	world.environment = _environment
	add_child(world)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "WarmShowgroundSun"
	sun.rotation_degrees = Vector3(-48,-32,-8)
	sun.light_color = Color("ffe9c4")
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55.0
	sun.shadow_normal_bias = 2.5
	sun.shadow_bias = 0.1
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.light_angular_distance = 1.5
	add_child(sun)
	_lights.append(sun)
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "BlueSkyFill"
	fill.rotation_degrees = Vector3(-30,140,0)
	fill.light_color = Color("a9dcff")
	fill.light_energy = 0.1
	add_child(fill)
	_lights.append(fill)

func _build_water() -> void:
	_water = MeshInstance3D.new()
	_water.name = "PartyLagoon"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(220,220)
	_water.mesh = plane
	_water.position.y = WATER_Y
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
// A toon lagoon: depth bands around the showground, foam where hulls meet the
// water, drifting ripple contours and the odd sparkle. Entirely procedural.
uniform vec3 water_tint = vec3(1.0);
varying vec3 world_pos;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float box(vec2 p, vec2 half){
	vec2 d = abs(p) - half;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
void vertex(){ world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	vec2 p = world_pos.xz;
	// The trap basin is open to the slop below, not the lagoon.
	if (abs(p.x) < 7.25 && abs(p.y) < 7.25) discard;
	vec2 q = (p - vec2(0.0, -1.7)) / vec2(11.05, 11.8);
	float shore = (pow(pow(abs(q.x), 4.0) + pow(abs(q.y), 4.0), 0.25) - 1.0) * 11.0;
	shore = min(shore, box(vec2(abs(p.x) - 13.6, p.y + 9.4), vec2(2.15, 5.7)));
	float slow = noise(p * 0.22 + vec2(TIME * 0.05, TIME * 0.035));
	float fine = noise(p * 0.75 + vec2(-TIME * 0.11, TIME * 0.16) + slow * 1.5);
	float depth = smoothstep(0.0, 13.0, shore + slow * 3.0);
	vec3 color = mix(vec3(0.33, 0.76, 0.74), vec3(0.15, 0.55, 0.66), smoothstep(0.0, 0.4, depth));
	color = mix(color, vec3(0.09, 0.37, 0.58), smoothstep(0.35, 1.0, depth));
	// Ripple contours: thin isolines of the drifting noise.
	float contour = 1.0 - smoothstep(0.0, 0.035, abs(fine - 0.5));
	contour += (1.0 - smoothstep(0.0, 0.02, abs(fine - 0.72))) * 0.6;
	color += vec3(0.11, 0.15, 0.13) * contour * (0.55 + 0.45 * slow);
	// Foam hugging every hull, plus slow rings travelling outward.
	float lap = shore + (fine - 0.5) * 0.7 + sin(TIME * 1.3 + p.x * 0.6 + p.y * 0.4) * 0.1;
	float foam = 1.0 - smoothstep(0.32, 0.5, lap);
	float ring = 1.0 - smoothstep(0.0, 0.07, abs(fract(shore * 0.32 - TIME * 0.11) - 0.5));
	foam = max(foam, ring * (1.0 - smoothstep(0.6, 6.5, shore)) * step(0.0, shore) * (0.35 + 0.65 * fine) * 0.75);
	color = mix(color, vec3(0.96, 1.0, 0.97), clamp(foam, 0.0, 1.0));
	float sparkle = step(0.965, noise(p * 2.4 + vec2(TIME * 0.5, 0.0))) * step(0.6, noise(p * 1.1 - vec2(0.0, TIME * 0.7)));
	color += vec3(0.5) * sparkle;
	ALBEDO = color * water_tint;
}
"""
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	_water.material_override = material
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water)
	_static_box(self,Vector3(100,0.5,100),Vector3(0,-8,0))

func _build_slop() -> void:
	# Whatever is in the trap basin, nobody wants to land in it.
	_slop = MeshInstance3D.new()
	_slop.name = "TrapBasinSlop"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(14.4,14.4)
	_slop.mesh = plane
	_slop.position.y = -5.75
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded;
uniform float level = 1.0;
varying vec3 world_pos;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex(){ world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	vec2 p = world_pos.xz;
	float swirl = noise(p * 0.45 + vec2(TIME * 0.09, -TIME * 0.06));
	float goo = noise(p * 1.1 + swirl * 2.4 + vec2(0.0, TIME * 0.12));
	vec3 color = mix(vec3(0.20, 0.10, 0.38), vec3(0.38, 0.20, 0.62), smoothstep(0.3, 0.7, goo));
	color = mix(color, vec3(0.66, 0.45, 0.9), 1.0 - smoothstep(0.0, 0.05, abs(goo - 0.62)));
	// Lazy bubbles pop on a grid of cells.
	vec2 cell = floor(p * 0.7);
	vec2 local = fract(p * 0.7) - 0.5;
	float life = fract(TIME * (0.12 + hash(cell) * 0.2) + hash(cell + 7.0));
	float radius = life * 0.36 * step(0.55, hash(cell + 3.0));
	float bubble = 1.0 - smoothstep(0.0, 0.045, abs(length(local + (vec2(hash(cell + 1.0), hash(cell + 2.0)) - 0.5) * 0.4) - radius));
	color += vec3(0.45, 0.35, 0.5) * bubble * (1.0 - life);
	ALBEDO = color * level;
}
"""
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	_slop.material_override = material
	_slop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_slop)

func _build_pillar() -> void:
	# A column of light lands on the correct pad at the buzzer.
	_pillar = MeshInstance3D.new()
	_pillar.name = "CorrectAnswerLight"
	var column: CylinderMesh = CylinderMesh.new()
	column.top_radius = 2.2
	column.bottom_radius = 2.9
	column.height = 9.0
	column.radial_segments = 28
	column.rings = 1
	column.cap_top = false
	column.cap_bottom = false
	_pillar.mesh = column
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float strength = 0.0;
varying float height;
void vertex(){ height = VERTEX.y / 9.0 + 0.5; }
void fragment(){
	float rim = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.3);
	ALBEDO = tint.rgb;
	ALPHA = rim * pow(1.0 - clamp(height, 0.0, 1.0), 1.7) * strength * 0.75;
}
"""
	_pillar_material = ShaderMaterial.new()
	_pillar_material.shader = shader
	_pillar.material_override = _pillar_material
	_pillar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pillar.hide()
	add_child(_pillar)

func _build_pad(index: int) -> void:
	var root: Node3D = Node3D.new()
	root.name = "AnswerPad" + LETTERS[index]
	root.position = tile_centers[index]
	add_child(root)
	tiles.append(root)
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "TrapdoorBody"
	body.position.y = -0.3
	body.collision_layer = 1
	body.collision_mask = 6
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.friction = 0.8
	root.add_child(body)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(PAD_SIZE,0.6,PAD_SIZE)
	shape.shape = box
	body.add_child(shape)
	_tile_bodies.append(body)
	_tile_shapes.append(shape)
	var visual: Node3D = Node3D.new()
	visual.name = "ModeledAnswerIsland"
	root.add_child(visual)
	_tile_visuals.append(visual)
	var platform: Node3D = PLATFORM.instantiate()
	visual.add_child(platform)
	var meshes: Array[Node] = platform.find_children("*","MeshInstance3D",true,false)
	_pad_meshes.append(meshes)
	for instance: MeshInstance3D in meshes:
		for surface in instance.mesh.get_surface_count():
			var original: StandardMaterial3D = instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if original == null: continue
			var material: StandardMaterial3D = original.duplicate() as StandardMaterial3D
			if original.resource_name == "white": material.albedo_color = COLORS[index]
			if original.resource_name == "signal": _warning_materials.append(material)
			material.roughness = 0.48
			material.metallic = 0.0
			instance.set_surface_override_material(surface,material)
			instance.set_meta("normal_%d" % surface,material)
	var disk: MeshInstance3D = _cylinder(visual,1.4,0.018,Vector3(0,0.039,0),COLORS[index].lightened(0.17))
	disk.name = "AnswerMedallion"
	var medallion: StandardMaterial3D = (disk.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	medallion.emission_enabled = true
	medallion.emission = COLORS[index].lightened(0.3)
	medallion.emission_energy_multiplier = 0.12
	disk.material_override = medallion
	_medallion_materials.append(medallion)
	var rim: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 1.40
	torus.outer_radius = 1.47
	torus.rings = 36
	torus.ring_segments = 8
	rim.mesh = torus
	rim.material_override = _material(CREAM)
	rim.position.y = 0.053
	visual.add_child(rim)
	var label: Label3D = _label(visual,LETTERS[index],Vector3(0,0.072,0),INK,256,0.012)
	label.rotation.x = -PI / 2.0
	label.outline_size = 0
	_tile_labels.append(label)
	var conveyor: Node3D = Node3D.new()
	conveyor.name = "ConveyorArrows"
	conveyor.position.y = 0.09
	conveyor.rotation.y = tile_centers[index].signed_angle_to(Vector3.FORWARD,Vector3.UP)
	visual.add_child(conveyor)
	_conveyors.append(conveyor)
	for k in 4:
		var chevron: Node3D = Node3D.new()
		chevron.position.z = -2.0 + k * 1.4
		chevron.set_meta("start_z",chevron.position.z)
		conveyor.add_child(chevron)
		for sign_x in [-1.0,1.0]:
			var mark: MeshInstance3D = _box(chevron,Vector3(0.78,0.025,0.13),Vector3(sign_x * 0.27,0,0),INK)
			mark.rotation.y = sign_x * 0.65
	conveyor.hide()
	var frost: Node3D = Node3D.new()
	frost.name = "FrostCrystals"
	frost.hide()
	visual.add_child(frost)
	_ice_marks.append(frost)
	var frost_batch: MultiMeshInstance3D = MultiMeshInstance3D.new()
	frost_batch.name = "BatchedFrostCrystals"
	var frost_mesh: BoxMesh = BoxMesh.new()
	frost_mesh.size = Vector3(0.025,0.016,0.65)
	var frost_instances: MultiMesh = MultiMesh.new()
	frost_instances.transform_format = MultiMesh.TRANSFORM_3D
	frost_instances.mesh = frost_mesh
	frost_instances.instance_count = 12
	var frost_index: int = 0
	for x in [-2.2,2.2]:
		for z in [-2.1,2.1]:
			for k in 3:
				frost_instances.set_instance_transform(frost_index,Transform3D(Basis(Vector3.UP,k * PI / 3.0),Vector3(x,0.08,z)))
				frost_index += 1
	frost_batch.multimesh = frost_instances
	frost_batch.material_override = _material(Color("e9fbff"))
	frost.add_child(frost_batch)

func _build_balcony_collision() -> void:
	_static_box(self,Vector3(15,0.7,2.5),Vector3(0,1.15,-10))
	for x in [-7.3,7.3]: _static_box(self,Vector3(0.3,1.5,2.5),Vector3(x,2,-10))
	_static_box(self,Vector3(15,1.3,0.3),Vector3(0,2.1,-11.15))
	var label: Label3D = _label(self,"CHEER SQUAD",Vector3(0,0.82,-8.51),CREAM,64,0.009)
	label.outline_size = 0

func set_pressure(value: float) -> void:
	_pressure = clampf(value,0.0,1.0)

func _build_clouds() -> void:
	var homes: Array[Vector3] = [Vector3(-16,5,-27),Vector3(17,7,-28),Vector3(2,9,-38)]
	for i in homes.size():
		var cloud: Node3D = CLOUD.instantiate()
		cloud.name = "MarshmallowCloud"
		cloud.position = homes[i]
		cloud.scale = Vector3.ONE * (0.9 + float(i % 3) * 0.25)
		cloud.set_meta("home",cloud.position)
		add_child(cloud)
		_clouds.append(cloud)

func _build_sweeper() -> void:
	_sweeper = Node3D.new()
	_sweeper.name = "CandyPinwheelSweeper"
	_sweeper.position.y = 0.8
	add_child(_sweeper)
	_cylinder(_sweeper,0.58,1.38,Vector3(0,-0.05,0),Color("e8b875"))
	_cylinder(_sweeper,0.72,0.16,Vector3(0,0.72,0),COLORS[3])
	_box(_sweeper,Vector3(13.3,0.55,0.62),Vector3.ZERO,COLORS[0])
	for x in [-6.65,6.65]: _sphere(_sweeper,0.33,Vector3(x,0,0),COLORS[0])
	for x in [-5.3,-3.5,-1.7,1.7,3.5,5.3]: _box(_sweeper,Vector3(0.25,0.58,0.65),Vector3(x,0,0),CREAM)
	_sweeper.hide()

func reset_round(round_index: int) -> void:
	_round_index = round_index
	restore_tiles()
	set_labels_visible(true)
	set_blackout(false)
	set_sweeper(round_index == 3)
	set_conveyor(round_index == 4)
	_finale_step = 0
	set_friction(0.015 if round_index == 3 else 0.8)
	_set_ice_style(round_index == 3)

func set_friction(value: float) -> void:
	for body in _tile_bodies: body.physics_material_override.friction = clampf(value,0.0,1.0)

func _set_ice_style(value: bool) -> void:
	for marks in _ice_marks: marks.visible = value
	for meshes: Array in _pad_meshes:
		for instance: MeshInstance3D in meshes:
			for surface in instance.mesh.get_surface_count():
				var normal: StandardMaterial3D = instance.get_meta("normal_%d" % surface) as StandardMaterial3D
				if normal in _warning_materials:
					instance.set_surface_override_material(surface,normal)
					continue
				if not value:
					instance.set_surface_override_material(surface,normal)
					continue
				var key: int = normal.get_instance_id()
				if not _ice_materials.has(key):
					var ice: StandardMaterial3D = normal.duplicate() as StandardMaterial3D
					ice.albedo_color = normal.albedo_color.lerp(Color("c6edff"),0.23)
					ice.roughness = 0.13
					ice.metallic = 0.08
					ice.clearcoat_enabled = true
					ice.clearcoat = 0.8
					_ice_materials[key] = ice
				instance.set_surface_override_material(surface,_ice_materials[key])

func set_tile_scale(index: int,ratio: float) -> void:
	if index < 0 or index >= tiles.size(): return
	var value: float = clampf(ratio,0.3,1.0)
	_tile_scales[index] = value
	_tile_visuals[index].scale = Vector3(value,1,value)
	var shape: BoxShape3D = _tile_shapes[index].shape as BoxShape3D
	shape.size = Vector3(PAD_SIZE * value,0.6,PAD_SIZE * value)

func set_labels_visible(value: bool) -> void:
	_labels_visible = value
	for label in _tile_labels: label.visible = value

func set_blackout(value: bool) -> void:
	blackout = value
	for light in _lights: light.visible = not value
	_environment.ambient_light_energy = 0.075 if value else 0.22
	_environment.background_mode = Environment.BG_COLOR if value else Environment.BG_SKY
	_environment.background_color = Color("192f54") if value else Color("accfcb")
	if is_instance_valid(_water):
		(_water.material_override as ShaderMaterial).set_shader_parameter("water_tint",Vector3(0.10,0.17,0.34) if value else Vector3.ONE)
	if is_instance_valid(_slop):
		(_slop.material_override as ShaderMaterial).set_shader_parameter("level",0.3 if value else 1.0)
	if is_instance_valid(stage_show): stage_show.set_dark(value)

func open_wrong_tiles(correct: int) -> void:
	for i in tiles.size():
		if i == correct or _open[i]: continue
		_open[i] = true
		_tile_shapes[i].set_deferred("disabled",true)
		_stop_pad_tween(i)
		var tween: Tween = create_tween().set_parallel(true)
		_pad_tweens[i] = tween
		tween.tween_property(tiles[i],"position:y",-5.4,0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(_tile_visuals[i],"rotation:z",-0.15 if i % 2 == 0 else 0.15,0.65)

func restore_tiles() -> void:
	_highlight_index = -1
	_pillar_level = 0.0
	set_pressure(0.0)
	for i in tiles.size():
		_stop_pad_tween(i)
		_open[i] = false
		tiles[i].position = tile_centers[i]
		_tile_visuals[i].rotation = Vector3.ZERO
		_tile_shapes[i].set_deferred("disabled",false)
		set_tile_scale(i,1.0)
		_tile_labels[i].modulate = INK

func _stop_pad_tween(index: int) -> void:
	var tween: Tween = _pad_tweens[index] as Tween
	if tween and tween.is_running(): tween.kill()
	_pad_tweens[index] = null

func get_tile_at(world_position: Vector3) -> int:
	if world_position.y < -1.6 or world_position.y > 5.0: return -1
	for i in tile_centers.size():
		if _open[i]: continue
		var half: float = PAD_SIZE * _tile_scales[i] * 0.5
		if absf(world_position.x - tile_centers[i].x) <= half and absf(world_position.z - tile_centers[i].z) <= half: return i
	return -1

func set_sweeper(value: bool) -> void:
	sweeper_active = value
	_sweeper.visible = value
	sweeper_angle = 0.0

func set_conveyor(value: bool) -> void:
	conveyor_active = value
	for root in _conveyors: root.visible = value

func set_finale_step(step: int) -> void:
	_finale_step = step
	for i in 4: set_tile_scale(i,maxf(0.53,1.0 - step * 0.16))

func set_answer_highlight(correct: int) -> void:
	if correct < 0 or correct >= _tile_labels.size(): return
	_highlight_index = correct
	_tile_labels[correct].modulate = CREAM
	spawn_confetti(tile_centers[correct] + Vector3(0,2.2,0),COLORS[correct])
	_pillar.position = tile_centers[correct] + Vector3(0,4.5,0)
	_pillar_material.set_shader_parameter("tint",COLORS[correct].lightened(0.35))
	_pillar_level = 1.0
	_pillar.show()

func get_network_state() -> Dictionary:
	var heights: Array[float] = []
	var tilts: Array[float] = []
	for i in tiles.size():
		heights.append(tiles[i].position.y)
		tilts.append(_tile_visuals[i].rotation.z)
	return {"scales":_tile_scales.duplicate(),"open":_open.duplicate(),"heights":heights,"tilts":tilts,"labels":_labels_visible,"blackout":blackout,"sweeper":sweeper_active,"angle":sweeper_angle,"conveyor":conveyor_active,"finale":_finale_step,"round":_round_index,"highlight":_highlight_index,"pressure":_pressure}

func apply_network_state(data: Dictionary) -> void:
	set_pressure(float(data.get("pressure",0.0)))
	var incoming_round: int = int(data.get("round",_round_index))
	if incoming_round != _round_index:
		_round_index = incoming_round
		_set_ice_style(_round_index == 3)
	var scales: Array = data.get("scales",[])
	var opened: Array = data.get("open",[])
	var heights: Array = data.get("heights",[])
	var tilts: Array = data.get("tilts",[])
	for i in mini(4,scales.size()):
		_stop_pad_tween(i)
		set_tile_scale(i,float(scales[i]))
		_open[i] = bool(opened[i]) if i < opened.size() else false
		_tile_shapes[i].set_deferred("disabled",_open[i])
		tiles[i].position.y = float(heights[i]) if i < heights.size() else 0.0
		_tile_visuals[i].rotation.z = float(tilts[i]) if i < tilts.size() else 0.0
	var night: bool = bool(data.get("blackout",false))
	if night != blackout: set_blackout(night)
	set_labels_visible(bool(data.get("labels",true)))
	var sweep: bool = bool(data.get("sweeper",false))
	if sweep != sweeper_active: set_sweeper(sweep)
	sweeper_angle = float(data.get("angle",0.0))
	_sweeper.rotation.y = -sweeper_angle
	var belt: bool = bool(data.get("conveyor",false))
	if belt != conveyor_active: set_conveyor(belt)
	_finale_step = int(data.get("finale",0))
	var incoming_highlight: int = int(data.get("highlight",-1))
	if incoming_highlight >= 0 and incoming_highlight != _highlight_index: set_answer_highlight(incoming_highlight)
	_highlight_index = incoming_highlight
	for i in _tile_labels.size(): _tile_labels[i].modulate = CREAM if i == _highlight_index else INK

func spawn_confetti(pos: Vector3,color: Color) -> void:
	if is_instance_valid(stage_show) and stage_show.is_inside_tree(): stage_show.celebrate_at(pos,color)

func _material(color: Color,emissive: bool = false) -> StandardMaterial3D:
	var key: String = color.to_html() + ("e" if emissive else "m")
	if _mat_cache.has(key): return _mat_cache[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.8
	_mat_cache[key] = material
	return material

func _box(parent: Node3D,size: Vector3,pos: Vector3,color: Color,emissive: bool = false) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _material(color,emissive)
	instance.position = pos
	parent.add_child(instance)
	return instance

func _cylinder(parent: Node3D,radius: float,height: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = pos
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D,radius: float,pos: Vector3,color: Color) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 20
	mesh.rings = 12
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = pos
	parent.add_child(instance)
	return instance

func _static_box(parent: Node3D,size: Vector3,pos: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 6
	parent.add_child(body)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _label(parent: Node3D,caption: String,pos: Vector3,color: Color,font_size: int,pixel_size: float) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = caption
	if _show_font == null:
		_show_font = FontVariation.new()
		_show_font.base_font = SHOW_FONT
		_show_font.variation_opentype = {2003265652: 680.0,2003072104: 100.0}
	label.font = _show_font
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 0
	label.position = pos
	label.shaded = false
	parent.add_child(label)
	return label
