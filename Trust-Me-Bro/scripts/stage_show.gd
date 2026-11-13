extends Node3D
## Presentation-only festival layer around the showground: a cheering crowd on two
## moored barges, stage lamps with light beams, string lights, balloons, boats and
## fireworks. It never touches physics or match state; RoundManager stays in charge.
const DRESSING = preload("res://assets/world/festival_dressing.glb")
const FAN = preload("res://assets/world/crowd_fan.glb")
const BALLOON = preload("res://assets/world/party_balloon.glb")
const BOAT = preload("res://assets/world/sailboat.glb")
const BUOY = preload("res://assets/world/buoy.glb")
const WATER_Y: float = -4.95
## Barge decks were authored relative to the lagoon surface.
const LIFT: float = 2.75
const PARTY_COLORS: Array[Color] = [Color("ff6b61"),Color("6daaff"),Color("87eed0"),Color("ffe17c"),Color("be9bff"),Color("ff9ed1"),Color("fca66c"),Color("a4d8f0")]
const PAD_COLORS: Array[Color] = [Color("fa636b"),Color("51a6f5"),Color("47cda4"),Color("ffcf4d")]
const WARM: Color = Color("ffe9b0")

var excitement: float = 0.15
var _excite_target: float = 0.15
var _clock: float = 0.0
var _dark: bool = false
var _mode: String = "idle"
var _focus: Vector3 = Vector3.ZERO
var _focus_color: Color = WARM
var _crowd_materials: Array[ShaderMaterial] = []
var _bulb_materials: Array[StandardMaterial3D] = []
var _bulb_energy: Array[float] = []
var _beams: Array[Dictionary] = []
var _beam_shader: Shader
var _balloons: Array[Node3D] = []
var _floaters: Array[Node3D] = []
var _marquee: MultiMeshInstance3D
var _marquee_material: ShaderMaterial
var _spots: Array[SpotLight3D] = []
var _fx: Node3D
var _rain: CPUParticles3D
var _firework_timer: float = 0.0
var _fireworks_left: int = 0
var _spark_mesh: Mesh
var _confetti_mesh: Mesh
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	name = "FestivalShow"
	_rng.seed = 2111
	var dressing: Node3D = DRESSING.instantiate()
	dressing.name = "BlenderFestivalDressing"
	add_child(dressing)
	_collect_bulbs(dressing)
	_build_crowd()
	_build_marquee()
	_build_beams()
	_build_balloons()
	_build_floaters()
	_build_spots()
	_fx = Node3D.new()
	_fx.name = "ShowEffects"
	add_child(_fx)
	_build_particle_meshes()
	_build_rain()

# ------------------------------------------------------------------ construction
func _collect_bulbs(dressing: Node3D) -> void:
	for instance: MeshInstance3D in dressing.find_children("*","MeshInstance3D",true,false):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if str(instance.name).contains("bulb") or str(instance.name).contains("rope") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface in instance.mesh.get_surface_count():
			var material: StandardMaterial3D = instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if material == null: continue
			if str(material.resource_name).begins_with("bulb_"):
				var live: StandardMaterial3D = material.duplicate() as StandardMaterial3D
				live.emission_enabled = true
				live.emission = live.albedo_color
				instance.set_surface_override_material(surface,live)
				_bulb_materials.append(live)
				_bulb_energy.append(2.4)
			else:
				material.roughness = 0.6

func seat_positions() -> Array[Vector3]:
	# Mirrors the three rising tiers authored in tools/build_festival.py.
	var seats: Array[Vector3] = []
	for side: float in [-1.0,1.0]:
		var cx: float = side * 13.6
		for tier in 3:
			var x: float = cx - side * 1.25 + side * tier * 1.25
			var top: float = LIFT - 4.9 + tier * 1.05
			for row in 10:
				seats.append(Vector3(x,top + 0.09,-9.4 - 4.75 + row * 9.5 / 9.0))
	return seats

func _build_crowd() -> void:
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
uniform float excite = 0.15;
uniform float dim = 1.0;
uniform bool tinted = true;
uniform vec3 flat_color : source_color = vec3(0.1,0.16,0.25);
varying vec3 fan_color;
void vertex(){
	float phase = INSTANCE_CUSTOM.x * 6.2831;
	float speed = 5.2 + INSTANCE_CUSTOM.y * 3.2;
	float hop = pow(abs(sin(TIME * speed * 0.5 + phase)), 2.4) * (0.035 + excite * 0.55);
	float arms = smoothstep(0.24, 0.34, abs(VERTEX.x)) * smoothstep(0.4, 0.6, VERTEX.y);
	VERTEX.y += hop + arms * (0.05 + excite * 0.34) * (0.5 + 0.5 * sin(TIME * speed + phase));
	VERTEX.x += sin(TIME * 2.1 + phase) * 0.05 * VERTEX.y * (0.4 + excite);
	fan_color = COLOR.rgb;
}
void fragment(){
	ALBEDO = (tinted ? fan_color : flat_color) * dim;
	ROUGHNESS = 0.72;
}
"""
	var seats: Array[Vector3] = seat_positions()
	var fan: Node3D = FAN.instantiate()
	for source: MeshInstance3D in fan.find_children("*","MeshInstance3D",true,false):
		var crowd: MultiMeshInstance3D = MultiMeshInstance3D.new()
		crowd.name = "Crowd_" + str(source.name)
		var batch: MultiMesh = MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.use_custom_data = true
		batch.mesh = source.mesh
		batch.instance_count = seats.size()
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = 77
		for i in seats.size():
			var side: float = signf(seats[i].x)
			var yaw: float = atan2(-side * 0.85,0.55) + random.randf_range(-0.25,0.25)
			var size: float = random.randf_range(0.86,1.12)
			var basis: Basis = Basis(Vector3.UP,yaw).scaled(Vector3(size,size * random.randf_range(0.92,1.1),size))
			# Stagger alternate tiers and loosen the rows so the stand reads as a crowd.
			var tier: int = (i / 10) % 3
			var jitter: Vector3 = Vector3(random.randf_range(-0.3,0.3),0.0,random.randf_range(-0.16,0.16) + (0.5 if tier == 1 else 0.0))
			batch.set_instance_transform(i,Transform3D(basis,seats[i] + jitter))
			var color: Color = PARTY_COLORS[random.randi_range(0,PARTY_COLORS.size() - 1)].lerp(Color.WHITE,random.randf_range(0.0,0.3))
			batch.set_instance_color(i,color)
			batch.set_instance_custom_data(i,Color(random.randf(),random.randf(),0.0,0.0))
		crowd.multimesh = batch
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tinted",str(source.name).contains("body"))
		crowd.material_override = material
		crowd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		crowd.custom_aabb = AABB(Vector3(-17,-3,-16),Vector3(34,6,14))
		_crowd_materials.append(material)
		add_child(crowd)
	fan.free()

func _build_marquee() -> void:
	# A chase of bulbs around the giant quiz screen shell.
	var points: Array[Vector3] = []
	var w: float = 22.82
	var h: float = 5.02
	var r: float = 0.42
	for i in range(-13,14): points.append(Vector3(i * (w - 2.0 * r) / 26.0,5.2 + h / 2.0,-13.74))
	for i in range(-2,3): points.append(Vector3(w / 2.0,5.2 - i * (h - 2.0 * r) / 4.0,-13.74))
	for i in range(13,-14,-1): points.append(Vector3(i * (w - 2.0 * r) / 26.0,5.2 - h / 2.0,-13.74))
	for i in range(2,-3,-1): points.append(Vector3(-w / 2.0,5.2 - i * (h - 2.0 * r) / 4.0,-13.74))
	var bulb: SphereMesh = SphereMesh.new()
	bulb.radius = 0.11
	bulb.height = 0.22
	bulb.radial_segments = 10
	bulb.rings = 6
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_custom_data = true
	batch.mesh = bulb
	batch.instance_count = points.size()
	for i in points.size():
		batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,points[i]))
		batch.set_instance_custom_data(i,Color(float(i) / points.size(),float(i % 3),0,0))
	var shader: Shader = Shader.new()
	shader.code = """shader_type spatial;
render_mode unshaded;
uniform float speed = 0.35;
uniform float level = 1.0;
uniform vec3 hot : source_color = vec3(1.0,0.93,0.66);
uniform vec3 accent : source_color = vec3(1.0,0.55,0.5);
varying float glow;
void vertex(){
	float chase = fract(INSTANCE_CUSTOM.x * 9.0 - TIME * speed);
	glow = smoothstep(0.55, 1.0, chase) + 0.22;
}
void fragment(){
	ALBEDO = mix(accent * 0.45, hot * 2.4, clamp(glow, 0.0, 1.0)) * level;
}
"""
	_marquee_material = ShaderMaterial.new()
	_marquee_material.shader = shader
	_marquee = MultiMeshInstance3D.new()
	_marquee.name = "QuizScreenMarqueeBulbs"
	_marquee.multimesh = batch
	_marquee.material_override = _marquee_material
	_marquee.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_marquee)

func lamp_positions() -> Array[Vector3]:
	# Tower centre lamps and the mast lamps, as authored in tools/build_festival.py.
	var lamps: Array[Vector3] = []
	for side: float in [-1.0,1.0]:
		lamps.append(Vector3(side * 9.15,3.82,7.3))
		lamps.append(Vector3(side * 14.25,LIFT + 1.08,-14.4))
		lamps.append(Vector3(side * 14.95,LIFT - 0.72,-4.4))
	return lamps

func _build_beams() -> void:
	_beam_shader = Shader.new()
	_beam_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0,0.92,0.7,1.0);
uniform float strength = 0.0;
uniform float span = 10.0;
varying float along;
void vertex(){ along = VERTEX.y / span + 0.5; }
void fragment(){
	float rim = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	float fade = pow(clamp(along, 0.0, 1.0), 1.25);
	ALBEDO = tint.rgb;
	ALPHA = rim * fade * strength;
}
"""
	var lamps: Array[Vector3] = lamp_positions()
	for i in lamps.size():
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = 0.2
		cone.bottom_radius = 1.9
		cone.height = 1.0
		cone.radial_segments = 20
		cone.rings = 1
		cone.cap_top = false
		cone.cap_bottom = false
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = _beam_shader
		material.set_shader_parameter("span",1.0)
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "StageLightBeam%d" % i
		instance.mesh = cone
		instance.material_override = material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		_beams.append({"node":instance,"material":material,"from":lamps[i],"aim":Vector3.ZERO,"level":0.0,"color":WARM,"phase":float(i) * 1.7})

func _build_balloons() -> void:
	var anchors: Array[Vector3] = []
	for side: float in [-1.0,1.0]:
		anchors.append(Vector3(side * 6.9,2.56,-10.0))
		anchors.append(Vector3(side * 9.7,0.62,2.8))
		anchors.append(Vector3(side * 15.15,LIFT - 2.3,-4.4))
		anchors.append(Vector3(side * 11.58,LIFT - 3.95,-4.25))
	for i in anchors.size():
		var bunch: Node3D = Node3D.new()
		bunch.name = "BalloonBunch%d" % i
		bunch.position = anchors[i]
		add_child(bunch)
		for k in 3:
			var balloon: Node3D = BALLOON.instantiate()
			balloon.rotation = Vector3((k - 1) * 0.34,k * 2.1 + i,(k - 1) * 0.3 * (1.0 if i % 2 == 0 else -1.0))
			balloon.scale = Vector3.ONE * (1.0 + 0.16 * float((i + k) % 3))
			bunch.add_child(balloon)
			var color: Color = PARTY_COLORS[(i * 3 + k * 2) % PARTY_COLORS.size()]
			for instance: MeshInstance3D in balloon.find_children("*","MeshInstance3D",true,false):
				instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if str(instance.name).contains("balloon"):
					var material: StandardMaterial3D = StandardMaterial3D.new()
					material.albedo_color = color
					material.roughness = 0.28
					material.rim_enabled = true
					material.rim = 0.5
					instance.material_override = material
			balloon.set_meta("rest",balloon.rotation)
			balloon.set_meta("phase",float(i) * 1.3 + float(k) * 0.8)
			_balloons.append(balloon)

func _build_floaters() -> void:
	var boats: Array = [[Vector3(-15.6,WATER_Y,-24.0),0.7,1.25],[Vector3(13.2,WATER_Y,-30.0),-2.2,1.05],[Vector3(17.5,WATER_Y,-22.5),2.6,1.2],[Vector3(-19.0,WATER_Y,-33.0),1.9,1.0]]
	for entry: Array in boats:
		var boat: Node3D = BOAT.instantiate()
		boat.position = entry[0]
		boat.rotation.y = entry[1]
		boat.scale = Vector3.ONE * float(entry[2])
		_register_floater(boat,0.10,0.06)
	var buoys: Array[Vector3] = [Vector3(-12.6,WATER_Y,-18.6),Vector3(12.9,WATER_Y,-19.6),Vector3(-17.2,WATER_Y,-28.5),Vector3(15.4,WATER_Y,-35.0),Vector3(-12.2,WATER_Y,-36.0),Vector3(-13.9,WATER_Y,-1.2),Vector3(14.3,WATER_Y,-1.6)]
	for at: Vector3 in buoys:
		var buoy: Node3D = BUOY.instantiate()
		buoy.position = at
		buoy.scale = Vector3.ONE * 1.25
		_register_floater(buoy,0.14,0.11)

func _register_floater(node: Node3D,bob: float,tilt: float) -> void:
	node.set_meta("home",node.position)
	node.set_meta("bob",bob)
	node.set_meta("tilt",tilt)
	node.set_meta("phase",_rng.randf() * TAU)
	node.set_meta("yaw",node.rotation.y)
	for instance: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	_floaters.append(node)

func _build_spots() -> void:
	# Two real coloured key lights give contestants a showbiz rim.
	var setups: Array = [[Vector3(-9.15,3.9,7.3),Color("ffd9b8")],[Vector3(9.15,3.9,7.3),Color("bfe3ff")]]
	for entry: Array in setups:
		var spot: SpotLight3D = SpotLight3D.new()
		spot.name = "TowerKeyLight"
		spot.position = entry[0]
		spot.light_color = entry[1]
		spot.light_energy = 0.75
		spot.spot_range = 24.0
		spot.spot_angle = 46.0
		spot.spot_angle_attenuation = 0.8
		spot.spot_attenuation = 0.6
		spot.shadow_enabled = false
		add_child(spot)
		spot.look_at(Vector3(-signf(spot.position.x) * 1.5,0.0,-1.0))
		_spots.append(spot)

func _build_particle_meshes() -> void:
	var spark: SphereMesh = SphereMesh.new()
	spark.radius = 0.11
	spark.height = 0.22
	spark.radial_segments = 6
	spark.rings = 3
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.vertex_color_use_as_albedo = true
	glow.albedo_color = Color(1.25,1.25,1.25)
	spark.material = glow
	_spark_mesh = spark
	var chip: BoxMesh = BoxMesh.new()
	chip.size = Vector3(0.16,0.02,0.24)
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.vertex_color_use_as_albedo = true
	chip.material = paper
	_confetti_mesh = chip

func _party_gradient() -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var colors: PackedColorArray = PackedColorArray()
	var offsets: PackedFloat32Array = PackedFloat32Array()
	var palette: Array[Color] = [Color("fa636b"),Color("ffcf4d"),Color("47cda4"),Color("51a6f5"),Color("fff6df"),Color("be9bff")]
	for i in palette.size():
		colors.append(palette[i])
		offsets.append(float(i) / palette.size())
	gradient.colors = colors
	gradient.offsets = offsets
	return gradient

func _build_rain() -> void:
	_rain = CPUParticles3D.new()
	_rain.name = "ConfettiRain"
	_rain.mesh = _confetti_mesh
	_rain.amount = 140
	_rain.lifetime = 5.5
	_rain.preprocess = 1.5
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(13.0,0.4,9.0)
	_rain.position = Vector3(0,11.0,-2.0)
	_rain.direction = Vector3.DOWN
	_rain.spread = 18.0
	_rain.gravity = Vector3(0.3,-2.6,0.0)
	_rain.initial_velocity_min = 0.6
	_rain.initial_velocity_max = 1.8
	_rain.angular_velocity_min = -260.0
	_rain.angular_velocity_max = 260.0
	_rain.angle_min = 0.0
	_rain.angle_max = 360.0
	_rain.particle_flag_rotate_y = true
	_rain.scale_amount_min = 0.7
	_rain.scale_amount_max = 1.5
	_rain.color_initial_ramp = _party_gradient()
	_rain.emitting = false
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rain)

# -------------------------------------------------------------------- direction
func set_mode(mode: String,focus: Vector3 = Vector3.ZERO,color: Color = WARM) -> void:
	## idle · intro · question · reveal · gacha · results
	_mode = mode
	_focus = focus
	_focus_color = color
	_rain.emitting = mode == "results" and not _dark
	match mode:
		"idle": _excite_target = 0.16
		"intro": _excite_target = 0.55
		"question": _excite_target = 0.12
		"reveal": _excite_target = 0.9
		"gacha": _excite_target = 0.5
		"results":
			_excite_target = 1.0
			_fireworks_left = 14
			_firework_timer = 0.2

func set_tension(value: float) -> void:
	# The crowd leans in as the buzzer approaches.
	if _mode == "question": _excite_target = 0.12 + clampf(value,0.0,1.0) * 0.5

func cheer(amount: float = 1.0) -> void:
	excitement = maxf(excitement,clampf(amount,0.0,1.3))

func set_dark(value: bool) -> void:
	_dark = value
	for spot in _spots: spot.visible = not value
	for material in _crowd_materials: material.set_shader_parameter("dim",0.16 if value else 1.0)
	_marquee_material.set_shader_parameter("level",0.2 if value else 1.0)
	if value: _rain.emitting = false

func celebrate_at(at: Vector3,color: Color,amount: int = 26) -> void:
	_burst(at,color,amount,5.2,1.25,true)

func cannons(color: Color) -> void:
	# Both lighting towers fire paper over the stage.
	for side: float in [-1.0,1.0]:
		var shot: CPUParticles3D = _burst(Vector3(side * 9.15,4.2,7.3),color,54,11.0,2.3,true)
		shot.direction = Vector3(-side * 0.55,0.9,-0.75).normalized()
		shot.spread = 20.0

func splash(at: Vector3,color: Color) -> void:
	var drops: CPUParticles3D = _burst(Vector3(at.x,-5.5,at.z),color,22,7.2,0.8,false)
	drops.direction = Vector3.UP
	drops.spread = 30.0
	drops.gravity = Vector3(0,-19.0,0)
	drops.scale_amount_min = 0.55
	drops.scale_amount_max = 1.1
	drops.color = color

func firework(at: Vector3,color: Color) -> void:
	var shell: CPUParticles3D = _burst(at,color,72,7.5,1.5,false)
	shell.spread = 180.0
	shell.gravity = Vector3(0,-2.6,0)
	shell.damping_min = 2.2
	shell.damping_max = 3.4
	var core: CPUParticles3D = _burst(at,Color("fff6df"),20,3.0,0.9,false)
	core.spread = 180.0
	core.gravity = Vector3(0,-1.5,0)

func _burst(at: Vector3,color: Color,amount: int,speed: float,life: float,paper: bool) -> CPUParticles3D:
	while _fx.get_child_count() >= 36: _fx.get_child(0).free()
	var burst: CPUParticles3D = CPUParticles3D.new()
	burst.mesh = _confetti_mesh if paper else _spark_mesh
	burst.one_shot = true
	burst.explosiveness = 0.94
	burst.amount = amount
	burst.lifetime = life
	burst.direction = Vector3.UP
	burst.spread = 62.0
	burst.initial_velocity_min = speed * 0.45
	burst.initial_velocity_max = speed
	burst.gravity = Vector3(0,-9.5 if paper else -6.0,0)
	burst.damping_min = 1.0
	burst.damping_max = 2.4
	burst.scale_amount_min = 0.6
	burst.scale_amount_max = 1.35
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0.0,1.0))
	shrink.add_point(Vector2(0.7,0.9))
	shrink.add_point(Vector2(1.0,0.0))
	burst.scale_amount_curve = shrink
	if paper:
		burst.particle_flag_rotate_y = true
		burst.angle_max = 360.0
		burst.angular_velocity_min = -420.0
		burst.angular_velocity_max = 420.0
		var ramp: Gradient = Gradient.new()
		ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		ramp.colors = PackedColorArray([color,Color("fff6df"),color.lightened(0.35),Color("ffcf4d")])
		ramp.offsets = PackedFloat32Array([0.0,0.4,0.6,0.85])
		burst.color_initial_ramp = ramp
	else:
		burst.color = color.lightened(0.25)
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fx.add_child(burst)
	burst.global_position = at
	burst.emitting = true
	get_tree().create_timer(life + 0.4,false).timeout.connect(_retire.bind(burst.get_instance_id()))
	return burst

func _retire(burst_id: int) -> void:
	# Bursts may already have been recycled by the cap above.
	var burst: Object = instance_from_id(burst_id) if is_instance_id_valid(burst_id) else null
	if burst is Node: (burst as Node).queue_free()

# --------------------------------------------------------------------- animation
func _process(delta: float) -> void:
	_clock += delta
	excitement = lerpf(excitement,_excite_target,1.0 - exp(-delta * 1.6))
	for material in _crowd_materials: material.set_shader_parameter("excite",excitement)
	_animate_bulbs()
	_animate_beams(delta)
	for balloon in _balloons:
		var rest: Vector3 = balloon.get_meta("rest")
		var phase: float = balloon.get_meta("phase")
		balloon.rotation = rest + Vector3(sin(_clock * 0.9 + phase) * 0.07,0.0,sin(_clock * 0.7 + phase * 1.7) * 0.09)
	for floater in _floaters:
		var home: Vector3 = floater.get_meta("home")
		var phase: float = floater.get_meta("phase")
		floater.position.y = home.y + sin(_clock * 1.1 + phase) * float(floater.get_meta("bob"))
		floater.rotation = Vector3(sin(_clock * 0.9 + phase) * float(floater.get_meta("tilt")),float(floater.get_meta("yaw")),cos(_clock * 0.75 + phase) * float(floater.get_meta("tilt")))
	if _fireworks_left > 0 and not _dark:
		_firework_timer -= delta
		if _firework_timer <= 0.0:
			_firework_timer = _rng.randf_range(0.22,0.6)
			_fireworks_left -= 1
			var side: float = -1.0 if _fireworks_left % 2 == 0 else 1.0
			firework(Vector3(side * _rng.randf_range(10.5,14.5),_rng.randf_range(3.0,8.5),_rng.randf_range(-12.0,2.0)),PAD_COLORS[_fireworks_left % 4])
			if _mode == "results" and _fireworks_left == 0: _fireworks_left = 6

func _animate_bulbs() -> void:
	for i in _bulb_materials.size():
		var wave: float = 0.5 + 0.5 * sin(_clock * (2.2 + excitement * 5.0) + float(i) * 1.57)
		var energy: float = (1.5 + wave * 2.2) * (0.14 if _dark else 1.0)
		_bulb_materials[i].emission_energy_multiplier = energy
	_marquee_material.set_shader_parameter("speed",0.3 + excitement * 0.9)

func _animate_beams(delta: float) -> void:
	for i in _beams.size():
		var beam: Dictionary = _beams[i]
		var phase: float = beam.phase
		var aim: Vector3 = Vector3.ZERO
		var level: float = 0.0
		var color: Color = WARM
		match _mode:
			"idle":
				# Drift over the left pads so the title cast stays crisp.
				aim = Vector3(-3.4 + sin(_clock * 0.33 + phase) * 3.2,0.0,cos(_clock * 0.27 + phase * 1.3) * 6.0)
				level = 0.2
			"intro":
				aim = Vector3(sin(_clock * 1.5 + phase) * 6.5,0.0,cos(_clock * 1.2 + phase) * 6.0)
				level = 0.45
				color = PAD_COLORS[i % 4].lightened(0.35)
			"question":
				# Park the lights on the pad corners so answers stay readable.
				aim = Vector3((-1.0 if i % 2 == 0 else 1.0) * 7.2,0.0,(-7.2 if i < 3 else 7.2) + sin(_clock * 0.5 + phase) * 0.6)
				level = 0.14
			"reveal":
				aim = _focus + Vector3(sin(phase) * 0.9,0.0,cos(phase) * 0.9)
				level = 0.4
				color = _focus_color.lightened(0.3)
			"gacha":
				aim = Vector3(sin(_clock * 2.0 + phase) * 5.0,0.0,cos(_clock * 1.6 + phase * 2.0) * 5.0)
				level = 0.42
				color = PAD_COLORS[(i + int(_clock * 2.0)) % 4].lightened(0.25)
			"results":
				aim = Vector3(sin(_clock * 1.1 + phase) * 8.0,0.0,cos(_clock * 0.9 + phase) * 7.0)
				level = 0.45
				color = PAD_COLORS[(i + int(_clock)) % 4].lightened(0.3)
		if _dark: level = 0.0
		beam.aim = (beam.aim as Vector3).lerp(aim,1.0 - exp(-delta * 4.0))
		beam.level = lerpf(float(beam.level),level,1.0 - exp(-delta * 5.0))
		beam.color = (beam.color as Color).lerp(color,1.0 - exp(-delta * 5.0))
		_beams[i] = beam
		var node: MeshInstance3D = beam.node
		var from: Vector3 = beam.from
		var to: Vector3 = beam.aim
		var axis: Vector3 = from - to
		var length: float = maxf(axis.length(),0.5)
		var up: Vector3 = axis / length
		var side: Vector3 = up.cross(Vector3.RIGHT)
		if side.length_squared() < 0.001: side = up.cross(Vector3.FORWARD)
		side = side.normalized()
		node.transform = Transform3D(Basis(side,up * length,side.cross(up)),(from + to) * 0.5)
		node.visible = float(beam.level) > 0.004
		var material: ShaderMaterial = beam.material
		material.set_shader_parameter("strength",float(beam.level))
		material.set_shader_parameter("tint",beam.color)
