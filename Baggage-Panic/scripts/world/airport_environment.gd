class_name AirportEnvironment
extends Node3D
## Recycled passenger terminal shell, glazing, roof and airfield outside it.

const TILE_LENGTH := 36.0
const TILE_COUNT := 10
const WALL_X := 30.0

static var _mesh_cache: Dictionary = {}
static var _material_cache: Dictionary = {}
static var _floor_texture: ImageTexture

var _tiles: Array[Node3D] = []
var _sun: DirectionalLight3D
var _world: WorldEnvironment
var _sky_material: ProceduralSkyMaterial
var _terminal_props: TerminalProps
var _tarmac: TarmacView
var _dressings: Array[Node3D] = []
var _far_ground: MeshInstance3D

## Generated dressing layers (props, people, vehicles); loaded only if present.
const DRESSINGS := ["res://scripts/world/concourse_dressing.gd", "res://scripts/world/tarmac_dressing.gd"]
var _intensity := 0.0
var _pendant_lights: Array[OmniLight3D] = []

const SUN_DAY := Vector3(-17.0, -62.0, 0.0)
const SUN_DUSK := Vector3(-6.0, -74.0, 0.0)
const AMBIENT_DAY := Color(0.62, 0.62, 0.66)
const FOG_DAY := Color(0.8, 0.76, 0.7)
var _last_follow_z := 0.0


func _ready() -> void:
	_world = WorldEnvironment.new()
	_world.name = "TerminalAtmosphere"
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_material = ProceduralSkyMaterial.new()
	_sky_material.sky_top_color = Color(0.32, 0.57, 0.83)
	_sky_material.sky_horizon_color = Color(1.0, 0.71, 0.48)
	_sky_material.ground_bottom_color = Color(0.21, 0.27, 0.35)
	_sky_material.ground_horizon_color = Color(0.67, 0.53, 0.45)
	sky.sky_material = _sky_material
	atmosphere.sky = sky
	# Golden-hour look: a dim sky-lit interior so the low sun, its shafts through the haze and the
	# warm pendant pools carry the image. Forward+ only (volumetric fog, SSR, SSAO, SSIL).
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = AMBIENT_DAY
	atmosphere.ambient_light_energy = 0.45
	atmosphere.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	atmosphere.tonemap_mode = Environment.TONE_MAPPER_AGX
	atmosphere.tonemap_exposure = 1.05
	atmosphere.tonemap_white = 9.0
	atmosphere.ssao_enabled = true
	atmosphere.ssao_radius = 1.6
	atmosphere.ssao_intensity = 2.2
	atmosphere.ssil_enabled = true
	atmosphere.ssil_intensity = 0.8
	atmosphere.ssr_enabled = true
	atmosphere.ssr_max_steps = 56
	atmosphere.ssr_fade_out = 1.6
	atmosphere.glow_enabled = true
	atmosphere.glow_intensity = 0.7
	atmosphere.glow_strength = 1.05
	atmosphere.glow_bloom = 0.06
	atmosphere.glow_hdr_threshold = 1.05
	atmosphere.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	atmosphere.set_glow_level(0, 0.0)
	atmosphere.set_glow_level(2, 1.0)
	atmosphere.set_glow_level(4, 0.8)
	atmosphere.set_glow_level(6, 0.5)
	atmosphere.fog_enabled = true
	atmosphere.fog_light_color = FOG_DAY
	atmosphere.fog_density = 0.0007
	atmosphere.fog_sun_scatter = 0.15
	atmosphere.volumetric_fog_enabled = true
	atmosphere.volumetric_fog_density = 0.0035
	atmosphere.volumetric_fog_albedo = Color(0.9, 0.88, 0.86)
	atmosphere.volumetric_fog_anisotropy = 0.62
	atmosphere.volumetric_fog_length = 45.0
	atmosphere.volumetric_fog_ambient_inject = 0.0
	atmosphere.adjustment_enabled = true
	atmosphere.adjustment_contrast = 1.08
	atmosphere.adjustment_saturation = 1.08
	_world.environment = atmosphere
	add_child(_world)

	_sun = DirectionalLight3D.new()
	_sun.name = "ApronSun"
	# Low and from the side: it rakes through the west glazing and skylights across the belts.
	_sun.rotation_degrees = SUN_DAY
	_sun.light_color = Color(1.0, 0.76, 0.5)
	_sun.light_energy = 3.2
	_sun.light_volumetric_fog_energy = 1.0
	_sun.light_angular_distance = 0.6
	_sun.shadow_enabled = true
	_sun.shadow_normal_bias = 1.2
	_sun.directional_shadow_max_distance = 90.0
	_sun.directional_shadow_blend_splits = true
	add_child(_sun)

	_terminal_props = TerminalProps.new()
	_terminal_props.name = "TerminalProps"
	add_child(_terminal_props)
	for i in TILE_COUNT:
		var tile := Node3D.new()
		tile.name = "TerminalShell%02d" % i
		tile.position.z = TILE_LENGTH - float(i) * TILE_LENGTH
		add_child(tile)
		_tiles.append(tile)
		_build_tile(tile, i)
	# Countryside beyond the airfield so the horizon never shows a void.
	_far_ground = MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(4000.0, 4000.0)
	_far_ground.mesh = ground_mesh
	_far_ground.material_override = DesignKit.stone(Color(0.46, 0.47, 0.37), 0.95, "far_ground")
	_far_ground.position.y = -0.72
	_far_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_far_ground)
	_tarmac = TarmacView.new()
	_tarmac.name = "TarmacView"
	add_child(_tarmac)
	for path: String in DRESSINGS:
		if ResourceLoader.exists(path):
			var script := load(path) as GDScript
			var layer := script.new() as Node3D if script != null and script.can_instantiate() else null
			if layer != null:
				layer.name = path.get_file().get_basename().to_pascal_case()
				add_child(layer)
				_dressings.append(layer)


func follow(player_z: float) -> void:
	if player_z > _last_follow_z + TILE_LENGTH * 2.0:
		for i in _tiles.size():
			_tiles[i].position.z = TILE_LENGTH - float(i) * TILE_LENGTH
	for tile in _tiles:
		while tile.position.z > player_z + TILE_LENGTH * 2.0:
			tile.position.z -= TILE_COUNT * TILE_LENGTH
	_last_follow_z = player_z
	_far_ground.position.z = player_z
	_terminal_props.follow(player_z)
	_tarmac.follow(player_z)
	for layer in _dressings:
		layer.call("follow", player_z)


## 0..1 changes the airport from bright daylight through sunset to blue night.
func set_intensity(amount: float) -> void:
	_intensity = clampf(amount, 0.0, 1.0)
	var dusk := smoothstep(0.16, 0.68, _intensity)
	var night := smoothstep(0.54, 1.0, _intensity)
	# The sun sinks and reddens, then hands the image over to the interior lights.
	_sun.rotation_degrees = SUN_DAY.lerp(SUN_DUSK, dusk)
	_sun.light_color = Color(1.0, 0.76, 0.5).lerp(Color(1.0, 0.5, 0.26), dusk)
	_sun.light_energy = lerpf(3.2, 2.2, dusk) * (1.0 - night)
	_sun.visible = night < 0.99
	var env := _world.environment
	env.ambient_light_color = AMBIENT_DAY.lerp(Color(0.62, 0.5, 0.5), dusk).lerp(Color(0.2, 0.26, 0.42), night)
	env.ambient_light_energy = lerpf(0.45, 0.38, dusk)
	env.fog_light_color = FOG_DAY.lerp(Color(0.8, 0.5, 0.42), dusk).lerp(Color(0.16, 0.2, 0.32), night)
	env.volumetric_fog_albedo = Color(0.9, 0.88, 0.86).lerp(Color(0.8, 0.82, 0.95), night)
	env.volumetric_fog_density = lerpf(0.0035, 0.006, dusk)
	_sky_material.sky_top_color = Color(0.32, 0.57, 0.83).lerp(Color(0.42, 0.29, 0.52), dusk).lerp(Color(0.015, 0.035, 0.11), night)
	_sky_material.sky_horizon_color = Color(1.0, 0.71, 0.48).lerp(Color(1.0, 0.45, 0.25), dusk).lerp(Color(0.14, 0.22, 0.43), night)
	_sky_material.sky_energy_multiplier = lerpf(1.0, 0.6, night)
	_mat("curtain_glass", Color(0.3, 0.36, 0.38, 0.07)).albedo_color = Color(0.3, 0.36, 0.38, 0.07).lerp(Color(0.1, 0.14, 0.2, 0.14), dusk)
	_mat("pendant_light", Color(1.0, 0.88, 0.64), true).emission_energy_multiplier = lerpf(2.5, 6.0, dusk)
	_mat("led_strip", Color(1.0, 0.93, 0.8), true).emission_energy_multiplier = lerpf(1.2, 4.0, dusk)
	for light in _pendant_lights:
		light.light_energy = lerpf(0.9, 2.6, dusk)
	_terminal_props.set_intensity(amount)
	_tarmac.set_intensity(amount)
	for layer in _dressings:
		if layer.has_method("set_intensity"):
			layer.call("set_intensity", amount)


func _build_tile(tile: Node3D, index: int) -> void:
	var white := _mat("roof_white", Color(0.86, 0.82, 0.75), false, 0.7)
	var trim := _mat("warm_trim", Color(0.74, 0.56, 0.38), false, 0.6)
	var mullion := _mat("mullion", Color(0.13, 0.12, 0.11), false, 0.45)
	var glass := _mat("curtain_glass", Color(0.3, 0.36, 0.38, 0.07), false, 0.04)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Polished terrazzo: low roughness so SSR picks up the sun patches, signs and pendants.
	var floor_mat := _mat("terrazzo", Color(0.9, 0.88, 0.84), false, 0.16)
	if _floor_texture == null:
		_floor_texture = _make_floor_texture()
		floor_mat.albedo_texture = _floor_texture
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60.0, TILE_LENGTH)
	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.material_override = floor_mat
	floor_instance.position = Vector3(0.0, -0.51, -18.0)
	floor_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tile.add_child(floor_instance)

	# The roof begins high above the camera and rises gently at the centre.
	for j in 12:
		var x: float = -27.5 + float(j) * 5.0
		var y := 13.0 + 1.55 * cos(x / 30.0 * PI)
		if j in [2, 3, 8, 9]:
			_box(tile, Vector3(x, y, -18.0), Vector3(4.85, 0.12, 36.0), glass)
			# Louvre slats under the skylight stripe the sunlight on the floor and in the haze.
			for k in 12:
				_box(tile, Vector3(x, y - 0.35, -1.5 - float(k) * 3.0), Vector3(4.85, 0.5, 0.18), trim)
		else:
			_box(tile, Vector3(x, y, -18.0), Vector3(4.95, 0.24, 36.0), white)
		_box(tile, Vector3(x, y - 0.15, -18.0), Vector3(0.12, 0.25, 36.0), trim)
		if j in [5, 6]:
			var strip := _box(tile, Vector3(x, y - 0.3, -18.0), Vector3(0.22, 0.06, 36.0), _mat("led_strip", Color(1.0, 0.93, 0.8), true))
			strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in [-1.0, -18.0, -35.0]:
		_box(tile, Vector3(0.0, 14.35, z), Vector3(60.0, 0.28, 0.28), white)
		for side in [-1.0, 1.0]:
			_build_pendant(tile, Vector3(side * 19.0, 11.7, z - 6.0))

	for side in [-1.0, 1.0]:
		var x: float = side * WALL_X
		# Floor-to-roof curtain wall: a slim sill and fascia, tall glass, thin steel mullions.
		_box(tile, Vector3(x, -0.38, -18.0), Vector3(0.5, 0.26, 36.0), mullion)
		_box(tile, Vector3(x, 12.75, -18.0), Vector3(0.5, 0.5, 36.0), white)
		_box(tile, Vector3(x, 6.1, -18.0), Vector3(0.08, 12.9, 36.0), glass)
		for transom_y in [4.2, 8.6]:
			_box(tile, Vector3(x - side * 0.12, transom_y, -18.0), Vector3(0.1, 0.1, 36.0), mullion)
		for k in 6:
			var z := -float(k) * 6.0
			_box(tile, Vector3(x - side * 0.14, 6.1, z), Vector3(0.16, 12.9, 0.12), mullion)
		for z in [-3.0, -30.0]:
			_build_column(tile, side, z, white, trim, index)
	if index == 2 or index == 7:
		_build_hanging_board(tile, index)


func _build_hanging_board(tile: Node3D, index: int) -> void:
	var board := SplitFlapBoard.new()
	board.position = Vector3(0.0, 7.5, -17.9)
	tile.add_child(board)
	board.setup(38, 4, Vector2(0.25, 0.51))
	board.set_text_immediate(0, "DEPARTURES", Color("f4ce83"))
	board.set_text_immediate(1, "TIME  FLIGHT  DESTINATION       GATE")
	for row in 2:
		var id := index * 2 + row
		var iata: String = ["LHR", "SGN", "NRT", "CDG"][id % 4]
		var city := str(AirportData.get_airport(iata).city).to_upper().substr(0, 12)
		board.set_text_immediate(row + 2, "%02d:%02d DN%03d  %-16s A%02d" % [8 + id % 12, id * 7 % 60, 210 + id * 7, city + " " + iata, 1 + id % 12])
	for x in [-4.2, 4.2]:
		_box(tile, Vector3(x, 9.0, -18.0), Vector3(0.06, 1.2, 0.06), _mat("pendant_cord", Color(0.16, 0.15, 0.14)))


func _build_column(tile: Node3D, side: float, z: float, white: Material, trim: Material, index: int) -> void:
	var x := side * 29.7
	# Plaster column with an oak-clad base and a flared capital meeting the roof.
	var column := DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.5), Vector2(0.62, -0.5), Vector2(0.62, 2.6), Vector2(0.55, 2.7), Vector2(0.5, 10.6), Vector2(0.95, 12.4), Vector2(0.0, 12.4)]), 24)
	DesignKit.add(tile, column, DesignKit.stone(DesignKit.PLASTER, 0.75, "plaster"), Vector3(x, 0.0, z))
	var cladding := DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.5), Vector2(0.66, -0.5), Vector2(0.66, 2.5), Vector2(0.0, 2.5)]), 24)
	DesignKit.add(tile, cladding, DesignKit.wood(), Vector3(x, 0.0, z))
	var label := Label3D.new()
	label.position = Vector3(x - side * 0.68, 1.6, z)
	label.rotation_degrees.y = 90.0 if side < 0.0 else -90.0
	label.pixel_size = 0.006
	label.font_size = 38
	label.modulate = Color.WHITE
	label.text = "%s%02d" % ["A" if side < 0.0 else "B", index + 1]
	label.double_sided = false
	label.visibility_range_end = 55.0
	label.visibility_range_end_margin = 10.0
	tile.add_child(label)


func _build_pendant(tile: Node3D, at: Vector3) -> void:
	_cylinder(tile, at + Vector3(0.0, 0.9, 0.0), 0.035, 2.0, _mat("pendant_cord", Color(0.16, 0.15, 0.14)))
	# Washi paper lantern: a softly bellied drum with blackened-steel rims.
	var lantern := DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.75), Vector2(0.55, -0.75), Vector2(0.72, -0.4), Vector2(0.78, 0.0), Vector2(0.72, 0.4), Vector2(0.55, 0.75), Vector2(0.0, 0.75)]), 20)
	DesignKit.add(tile, lantern, _mat("pendant_light", Color(1.0, 0.88, 0.64), true), at, Vector3.ZERO, false)
	var rim := DesignKit.lathe(PackedVector2Array([Vector2(0.5, -0.04), Vector2(0.58, -0.04), Vector2(0.58, 0.04), Vector2(0.5, 0.04)]), 20)
	for y in [-0.76, 0.76]:
		DesignKit.add(tile, rim, DesignKit.metal(), at + Vector3(0.0, y, 0.0), Vector3.ZERO, false)
	var light := OmniLight3D.new()
	light.position = at + Vector3(0.0, -1.1, 0.0)
	light.light_color = Color(1.0, 0.8, 0.56)
	light.light_energy = 0.9
	light.omni_range = 13.0
	light.omni_attenuation = 1.4
	light.light_volumetric_fog_energy = 0.4
	light.distance_fade_enabled = true
	light.distance_fade_begin = 70.0
	light.distance_fade_length = 15.0
	tile.add_child(light)
	_pendant_lights.append(light)


func _make_floor_texture() -> ImageTexture:
	var image := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 512:
			var fleck := float((x * 73 + y * 41 + x * y * 3) % 97) / 97.0
			var color := Color(0.86, 0.83, 0.77)
			if fleck > 0.94:
				color = Color(0.68, 0.74, 0.73)
			elif fleck < 0.04:
				color = Color(0.92, 0.84, 0.69)
			if x % 64 <= 1 or y % 64 <= 1:
				color = Color(0.7, 0.66, 0.6)
			if abs(x - 75) < 3 or abs(x - 437) < 3:
				color = Color(0.6, 0.45, 0.3)
			if abs(x - 92) < 2 or abs(x - 420) < 2:
				color = Color(0.25, 0.23, 0.21)
			image.set_pixel(x, y, color)
	# Large painted chevrons direct passengers toward gates along both concourses.
	for arrow_y in [34, 115, 196]:
		for a in 14:
			for thickness in 5:
				for centre_x in [49, 463]:
					var px: int = centre_x + (a if centre_x < 256 else -a)
					var py: int = arrow_y + absi(a - 7) + thickness
					image.set_pixel(px, py, Color(0.62, 0.56, 0.48))
	return ImageTexture.create_from_image(image)


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _box_mesh(size)
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = _shadow_mode(material)
	parent.add_child(instance)
	return instance


## Structure casts sun shadows (mullions, columns, roof slats); glass and lamps let light through.
func _shadow_mode(material: Material) -> GeometryInstance3D.ShadowCastingSetting:
	var base := material as BaseMaterial3D
	if base and (base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or base.emission_enabled):
		return GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _box_mesh(size: Vector3) -> BoxMesh:
	var key := "box:" + str(size)
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_mesh_cache[key] = mesh
	return _mesh_cache[key] as BoxMesh


func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var key := "cylinder:%s:%s" % [radius, height]
	if not _mesh_cache.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 10
		_mesh_cache[key] = mesh
	var instance := MeshInstance3D.new()
	instance.mesh = _mesh_cache[key] as Mesh
	instance.material_override = material
	instance.position = at
	instance.rotation_degrees = rotation
	instance.cast_shadow = _shadow_mode(material)
	parent.add_child(instance)


func _sphere(parent: Node3D, at: Vector3, radius: float, material: Material) -> void:
	var key := "sphere:%s" % radius
	if not _mesh_cache.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		_mesh_cache[key] = mesh
	var instance := MeshInstance3D.new()
	instance.mesh = _mesh_cache[key] as Mesh
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _mat(key: String, color: Color, emissive: bool = false, roughness: float = 0.72) -> StandardMaterial3D:
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = roughness
		if emissive:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = 0.75
		_material_cache[key] = material
	return _material_cache[key] as StandardMaterial3D
