class_name ArenaLevel
extends Node3D
## Builds the Aim Botz-style arena: a big dev-textured training floor, a raised
## player platform with ramps, cover objects, a container lane, a two-room
## bunker with a sliding door, lighting and a baked navigation mesh.

const HALF_SIZE := 40.0
const WALL_HEIGHT := 9.0
const PLATFORM_TOP := 3.0

var player_spawn := Transform3D(Basis.IDENTITY, Vector3(0.0, PLATFORM_TOP + 0.05, 32.0))
var bot_spawns: Array[Vector3] = []
var practice_spots: Array[Vector3] = []
var health_spots: Array[Vector3] = []
var ammo_spots: Array[Vector3] = []
var barrel_spots: Array[Vector3] = []
## Obstacle footprints (x/z) drawn on the radar.
var radar_rects: Array[Rect2] = []
var doors: Array[SlidingDoor] = []
var nav_region: NavigationRegion3D

var _materials := {}


func _ready() -> void:
	_build_materials()
	_build_environment()
	nav_region = NavigationRegion3D.new()
	nav_region.name = "NavRegion"
	add_child(nav_region)
	_build_shell()
	_build_platform()
	_build_cover()
	_build_container_lane()
	_build_bunker()
	_build_decor()
	_define_spots()
	_bake_navigation()


func reset_doors() -> void:
	for door in doors:
		door.reset()


func set_sound_fx(sound_fx: SoundFX) -> void:
	for door in doors:
		door.sound_fx = sound_fx


# --- Materials -------------------------------------------------------------

func _build_materials() -> void:
	_materials["floor"] = _dev_material(Color(0.42, 0.43, 0.45), Color(0.55, 0.56, 0.58), Color(0.33, 0.34, 0.36), 0.25)
	_materials["wall"] = _dev_material(Color(0.86, 0.5, 0.17), Color(0.95, 0.62, 0.3), Color(0.7, 0.38, 0.1), 0.25)
	_materials["platform"] = _dev_material(Color(0.2, 0.3, 0.45), Color(0.32, 0.43, 0.58), Color(0.14, 0.22, 0.34), 0.5)
	_materials["concrete"] = _dev_material(Color(0.5, 0.5, 0.49), Color(0.58, 0.58, 0.57), Color(0.4, 0.4, 0.39), 0.25)
	_materials["crate"] = _dev_material(Color(0.55, 0.38, 0.2), Color(0.66, 0.48, 0.28), Color(0.38, 0.24, 0.12), 0.5)
	_materials["container_red"] = _dev_material(Color(0.6, 0.16, 0.12), Color(0.5, 0.12, 0.1), Color(0.45, 0.1, 0.08), 0.33)
	_materials["container_blue"] = _dev_material(Color(0.16, 0.32, 0.55), Color(0.12, 0.26, 0.46), Color(0.1, 0.22, 0.4), 0.33)
	_materials["container_green"] = _dev_material(Color(0.2, 0.45, 0.26), Color(0.15, 0.36, 0.2), Color(0.12, 0.3, 0.16), 0.33)
	_materials["door"] = _dev_material(Color(0.25, 0.27, 0.3), Color(0.35, 0.37, 0.4), Color(0.18, 0.19, 0.22), 0.5)


## Classic "dev texture": a 1 m grid with a thicker line every 4 m, mapped
## with world-space triplanar UVs so every box lines up regardless of size.
func _dev_material(base: Color, line: Color, border: Color, uv_scale: float) -> StandardMaterial3D:
	var size := 256
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(base)
	for step in range(0, size, 64):
		image.fill_rect(Rect2i(step, 0, 2, size), line)
		image.fill_rect(Rect2i(0, step, size, 2), line)
	image.fill_rect(Rect2i(0, 0, 4, size), border)
	image.fill_rect(Rect2i(0, 0, size, 4), border)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * uv_scale
	material.roughness = 0.85
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.32, 0.5, 0.78)
	sky_material.sky_horizon_color = Color(0.72, 0.8, 0.88)
	sky_material.ground_horizon_color = Color(0.6, 0.62, 0.64)
	sky_material.ground_bottom_color = Color(0.3, 0.3, 0.32)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.25
	environment.glow_hdr_threshold = 1.2
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)


# --- Geometry --------------------------------------------------------------

func _box(size: Vector3, center: Vector3, material_key: String, rotation_z := 0.0, on_radar := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	body.rotation.z = rotation_z
	var mesh := BoxMesh.new()
	mesh.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _materials[material_key]
	body.add_child(mesh_instance)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	nav_region.add_child(body)
	if on_radar:
		var width := size.x * cos(rotation_z)
		radar_rects.append(Rect2(center.x - width * 0.5, center.z - size.z * 0.5, width, size.z))
	return body


func _build_shell() -> void:
	_box(Vector3(HALF_SIZE * 2.0, 1.0, HALF_SIZE * 2.0), Vector3(0.0, -0.5, 0.0), "floor", 0.0, false)
	var span := HALF_SIZE * 2.0 + 2.0
	var mid_height := WALL_HEIGHT * 0.5
	_box(Vector3(span, WALL_HEIGHT, 1.0), Vector3(0.0, mid_height, -HALF_SIZE - 0.5), "wall")
	_box(Vector3(span, WALL_HEIGHT, 1.0), Vector3(0.0, mid_height, HALF_SIZE + 0.5), "wall")
	_box(Vector3(1.0, WALL_HEIGHT, span), Vector3(-HALF_SIZE - 0.5, mid_height, 0.0), "wall")
	_box(Vector3(1.0, WALL_HEIGHT, span), Vector3(HALF_SIZE + 0.5, mid_height, 0.0), "wall")


## The Aim Botz overlook: a raised platform at the south end with two ramps.
func _build_platform() -> void:
	_box(Vector3(14.0, PLATFORM_TOP, 8.0), Vector3(0.0, PLATFORM_TOP * 0.5, 31.0), "platform")
	var slope := atan2(PLATFORM_TOP, 8.0)
	_box(Vector3(9.2, 0.4, 4.0), Vector3(-11.0, 1.4, 31.0), "platform", slope)
	_box(Vector3(9.2, 0.4, 4.0), Vector3(11.0, 1.4, 31.0), "platform", -slope)
	# Waist-high cover with a gap in the middle.
	_box(Vector3(5.5, 1.1, 0.4), Vector3(-4.25, PLATFORM_TOP + 0.55, 27.2), "concrete")
	_box(Vector3(5.5, 1.1, 0.4), Vector3(4.25, PLATFORM_TOP + 0.55, 27.2), "concrete")


func _build_cover() -> void:
	# Crate clusters.
	for crate in [
		Vector3(-12.0, 1.0, 8.0), Vector3(-10.0, 1.0, 8.0), Vector3(-12.0, 3.0, 8.0),
		Vector3(12.0, 1.0, 6.0), Vector3(12.0, 1.0, 4.0), Vector3(12.0, 3.0, 6.0),
		Vector3(-4.0, 1.0, -17.0), Vector3(4.0, 1.0, -27.0), Vector3(4.0, 3.0, -27.0),
		Vector3(-12.0, 1.0, -27.0), Vector3(12.0, 1.0, -27.0), Vector3(-20.0, 1.0, 16.0),
		Vector3(20.0, 1.0, 16.0),
	]:
		_box(Vector3(2.0, 2.0, 2.0), crate, "crate")
	# Low concrete walls in the middle of the field.
	_box(Vector3(6.0, 1.3, 0.5), Vector3(0.0, 0.65, 12.0), "concrete")
	_box(Vector3(6.0, 1.3, 0.5), Vector3(0.0, 0.65, -6.0), "concrete")
	_box(Vector3(0.5, 1.3, 5.0), Vector3(-17.0, 0.65, 0.0), "concrete")
	# Pillars.
	for pillar in [Vector3(-6.0, 3.5, -2.0), Vector3(6.0, 3.5, -2.0), Vector3(-20.0, 3.5, -17.0), Vector3(20.0, 3.5, -17.0)]:
		_box(Vector3(2.0, 7.0, 2.0), pillar, "concrete")


func _build_container_lane() -> void:
	_box(Vector3(3.0, 3.0, 12.0), Vector3(-31.0, 1.5, -14.0), "container_red")
	_box(Vector3(3.0, 3.0, 12.0), Vector3(-31.0, 1.5, 6.0), "container_blue")
	_box(Vector3(3.0, 3.0, 8.0), Vector3(-31.0, 4.5, -12.0), "container_green")
	_box(Vector3(3.0, 3.0, 10.0), Vector3(-35.5, 1.5, 22.0), "container_green")


## Two-room bunker on the east side. The west entrance has a sliding door,
## the north side has an open doorway so it can't become a dead end.
func _build_bunker() -> void:
	var height := 4.0
	var y := height * 0.5
	var t := 0.5
	# West wall (x = 22) with a doorway at z 0.8..3.2.
	_box(Vector3(t, height, 8.8), Vector3(22.0, y, -3.6), "concrete")
	_box(Vector3(t, height, 6.8), Vector3(22.0, y, 6.6), "concrete")
	_box(Vector3(t, 1.0, 2.4), Vector3(22.0, 3.5, 2.0), "concrete", 0.0, false)
	# East wall.
	_box(Vector3(t, height, 18.0), Vector3(36.0, y, 1.0), "concrete")
	# North wall (z = -8) with an open doorway at x 31..33.4.
	_box(Vector3(9.0, height, t), Vector3(26.5, y, -8.0), "concrete")
	_box(Vector3(2.6, height, t), Vector3(34.7, y, -8.0), "concrete")
	_box(Vector3(2.4, 1.0, t), Vector3(32.2, 3.5, -8.0), "concrete", 0.0, false)
	# South wall.
	_box(Vector3(14.0, height, t), Vector3(29.0, y, 10.0), "concrete")
	# Inner wall (x = 29) with an open doorway at z 0.8..3.2.
	_box(Vector3(t, height, 8.8), Vector3(29.0, y, -3.6), "concrete")
	_box(Vector3(t, height, 6.8), Vector3(29.0, y, 6.6), "concrete")
	_box(Vector3(t, 1.0, 2.4), Vector3(29.0, 3.5, 2.0), "concrete", 0.0, false)
	# Roof.
	_box(Vector3(14.5, 0.4, 18.5), Vector3(29.0, height + 0.2, 1.0), "concrete", 0.0, false)
	for light_position in [Vector3(25.5, 3.4, 1.0), Vector3(32.5, 3.4, 1.0)]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.9, 0.75)
		lamp.light_energy = 1.6
		lamp.omni_range = 9.0
		lamp.position = light_position
		add_child(lamp)

	# The sliding door lives outside the nav region so the doorway stays walkable.
	var door := SlidingDoor.new()
	door.setup(Vector3(0.3, 3.0, 2.4), Vector3(22.0, 1.5, 2.0), Vector3(0.0, 0.0, 2.45), _materials["door"])
	add_child(door)
	doors.append(door)

	var bunker_sign := Label3D.new()
	bunker_sign.text = "BUNKER"
	bunker_sign.font_size = 96
	bunker_sign.pixel_size = 0.01
	bunker_sign.outline_size = 12
	bunker_sign.position = Vector3(21.7, 3.5, 6.5)
	bunker_sign.rotation_degrees.y = -90.0
	add_child(bunker_sign)


func _build_decor() -> void:
	var title := Label3D.new()
	title.text = "AIM BOTZ ARENA"
	title.font_size = 256
	title.pixel_size = 0.02
	title.outline_size = 24
	title.modulate = Color(1.0, 0.95, 0.85)
	title.position = Vector3(0.0, 6.2, -HALF_SIZE + 0.05)
	add_child(title)
	# Distance markers on the floor, measured from the player platform (like Aim Botz).
	for metres in [10, 20, 30, 40, 50, 60]:
		var marker := Label3D.new()
		marker.text = "%d m" % metres
		marker.font_size = 128
		marker.pixel_size = 0.01
		marker.outline_size = 10
		marker.modulate = Color(1.0, 1.0, 1.0, 0.85)
		marker.rotation_degrees.x = -90.0
		marker.position = Vector3(-37.0, 0.02, player_spawn.origin.z - float(metres))
		add_child(marker)
		var stripe := MeshInstance3D.new()
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(4.0, 0.02, 0.15)
		stripe.mesh = stripe_mesh
		stripe.material_override = Fx.unshaded(Color(1.0, 0.85, 0.3))
		stripe.position = Vector3(-37.0, 0.01, player_spawn.origin.z - float(metres) + 0.8)
		add_child(stripe)


func _define_spots() -> void:
	bot_spawns = [
		Vector3(-24.0, 0.0, -35.0), Vector3(-12.0, 0.0, -36.0), Vector3(0.0, 0.0, -36.0),
		Vector3(12.0, 0.0, -36.0), Vector3(24.0, 0.0, -35.0), Vector3(-34.0, 0.0, -30.0),
		Vector3(34.0, 0.0, -30.0), Vector3(-26.0, 0.0, -10.0), Vector3(32.5, 0.0, -4.0),
		Vector3(-35.0, 0.0, 0.0), Vector3(36.0, 0.0, 16.0), Vector3(-8.0, 0.0, -32.0),
	]
	# Aim Botz-style rows of bots for practice mode.
	for row_z in [-12.0, -22.0, -32.0]:
		for column_x in [-16.0, -8.0, 0.0, 8.0, 16.0]:
			practice_spots.append(Vector3(column_x, 0.0, row_z))
	health_spots = [Vector3(25.5, 0.0, 6.0), Vector3(-31.0, 0.0, -4.0), Vector3(16.0, 0.0, -32.0), Vector3(-8.0, 0.0, 18.0)]
	ammo_spots = [Vector3(5.0, PLATFORM_TOP, 33.5), Vector3(32.5, 0.0, 6.0), Vector3(-22.0, 0.0, -6.0), Vector3(8.0, 0.0, 18.0)]
	barrel_spots = [Vector3(-22.0, 0.0, -29.0), Vector3(22.0, 0.0, -29.0), Vector3(3.5, 0.0, -7.3), Vector3(14.5, 0.0, 7.0), Vector3(-27.5, 0.0, -14.0)]


func _bake_navigation() -> void:
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_collision_mask = 1
	navigation_mesh.agent_radius = 0.5
	navigation_mesh.agent_height = 2.0
	navigation_mesh.agent_max_climb = 0.25
	navigation_mesh.agent_max_slope = 40.0
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	nav_region.navigation_mesh = navigation_mesh
	nav_region.bake_navigation_mesh(false)
