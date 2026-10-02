extends RefCounted
## Ceremonial hub: a fountain breaks the foyer-to-gallery sight line while the
## Inspector's perimeter patrol and all four arches retain clear approaches.

static var _water_material: ShaderMaterial
static var _painting_material: StandardMaterial3D


static func dress(kit: LevelKit, room_id: String) -> void:
	var centre: Vector3 = MuseumLayout.CENTREPIECE["pos"]
	_fountain(kit, room_id, centre)
	_columns(kit, room_id)
	_stair(kit, room_id, -1.0)
	_stair(kit, room_id, 1.0)
	_chandelier(kit, room_id, centre)
	_banners(kit, room_id)
	_furniture(kit, room_id)
	_wall_art(kit, room_id)
	# Cool skylight and small perimeter bounce preserve the stealth light pools.
	kit.spot(room_id, centre + Vector3(0.8, 8.75, 0), centre + Vector3(0, 1.0, 0), Color(0.65, 0.77, 1.0), 1.5, 11.0, 44.0)
	for x in [-10.0, 10.0]:
		kit.omni(room_id, Vector3(x, 3.0, 7.8), Color(0.74, 0.82, 1.0), 0.27, 5.5)
	for z in [-5.3, 15.8]:
		for x in [-8.9, 8.9]:
			_pendant(kit, room_id, Vector3(x, 4.8, z), 0.0 if z < 0.0 else PI)


static func _fountain(kit: LevelKit, room_id: String, centre: Vector3) -> void:
	# The structure owns the fountain's 3.2 m radius collider.
	var black: Material = kit.mat("marble_black")
	var white: Material = kit.mat("marble_white")
	var gold: Material = kit.mat("brass")
	var rim := TorusMesh.new()
	rim.inner_radius = 2.72
	rim.outer_radius = 3.16
	rim.rings = 64
	rim.ring_segments = 12
	kit.prop(room_id, rim, Transform3D(Basis(), centre + Vector3(0, 1.43, 0)), white)
	var lower := TorusMesh.new()
	lower.inner_radius = 3.01
	lower.outer_radius = 3.17
	lower.rings = 64
	lower.ring_segments = 8
	kit.prop(room_id, lower, Transform3D(Basis(), centre + Vector3(0, 0.36, 0)), gold)
	var water := CylinderMesh.new()
	water.top_radius = 2.74
	water.bottom_radius = 2.74
	water.height = 0.025
	water.radial_segments = 64
	kit.prop(room_id, water, Transform3D(Basis(), centre + Vector3(0, 1.415, 0)), _water())
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		_sphere(kit, room_id, centre + Vector3(cos(a) * 2.45, 1.48, sin(a) * 2.45), Vector3(0.09, 0.045, 0.09), gold)
	# A real scanned sculpture stands on the graduated central pedestal.
	_cylinder(kit, room_id, centre + Vector3(0, 1.61, 0), 0.82, 0.77, 0.43, black)
	_cylinder(kit, room_id, centre + Vector3(0, 1.87, 0), 0.73, 0.68, 0.12, gold)
	_cylinder(kit, room_id, centre + Vector3(0, 2.05, 0), 0.60, 0.48, 0.34, white)
	kit.model(room_id, "gothic_statue", Transform3D(Basis(Vector3.UP, PI), centre + Vector3(0, 2.22, 0)), 2.4, "none")


static func _columns(kit: LevelKit, room_id: String) -> void:
	var marble: Material = kit.mat("marble_white")
	var gold: Material = kit.mat("gold")
	var flute_mesh := CylinderMesh.new()
	flute_mesh.top_radius = 0.035
	flute_mesh.bottom_radius = 0.035
	flute_mesh.height = 6.13
	flute_mesh.radial_segments = 6
	var flutes: Array[Transform3D] = []
	for x in [-11.7, 11.7]:
		for z in [-6.1, 1.8, 8.6, 14.0]:
			var p := Vector3(x, 0, z)
			kit.cylinder_solid(room_id, p + Vector3(0, 0.42, 0), 0.43, 7.05, marble, 20)
			_cylinder(kit, room_id, p + Vector3(0, 0.16, 0), 0.66, 0.66, 0.32, marble)
			_cylinder(kit, room_id, p + Vector3(0, 0.38, 0), 0.57, 0.51, 0.16, gold)
			_cylinder(kit, room_id, p + Vector3(0, 7.36, 0), 0.62, 0.51, 0.22, gold)
			_cylinder(kit, room_id, p + Vector3(0, 7.59, 0), 0.74, 0.63, 0.24, marble)
			for i in 12:
				var a: float = TAU * float(i) / 12.0
				flutes.append(Transform3D(Basis(), p + Vector3(cos(a) * 0.415, 3.86, sin(a) * 0.415)))
	kit.multi(room_id, flute_mesh, flutes, marble)


static func _stair(kit: LevelKit, room_id: String, side: float) -> void:
	# Exhibition stair is roped off at its foot; one collision volume gives the
	# treads honest collision without dozens of nav cutouts.
	var x: float = side * 12.35
	var stone: Material = kit.mat("marble_white")
	var gold: Material = kit.mat("brass")
	kit.solid(room_id, Vector3(x, 0, -2.0), Vector3(2.3, 2.5, 6.5), stone, 0.0, false)
	for i in 14:
		var y: float = 0.23 + float(i) * 0.28
		var z: float = -5.85 + float(i) * 0.58
		_box(kit, room_id, Vector3(x, y, z), Vector3(2.45, 0.13, 0.73), stone)
		_box(kit, room_id, Vector3(x, y + 0.075, z - 0.28), Vector3(2.46, 0.035, 0.10), gold)
	_box(kit, room_id, Vector3(side * 13.05, 4.18, -2.1), Vector3(1.15, 0.27, 11.2), kit.mat("wood_dark"))
	_box(kit, room_id, Vector3(side * 12.45, 5.19, -2.1), Vector3(0.10, 0.13, 11.2), gold)
	var baluster := CylinderMesh.new()
	baluster.top_radius = 0.055
	baluster.bottom_radius = 0.08
	baluster.height = 0.91
	baluster.radial_segments = 8
	var balusters: Array[Transform3D] = []
	for i in 18:
		balusters.append(Transform3D(Basis(), Vector3(side * 12.45, 4.69, -7.2 + float(i) * 0.60)))
	kit.multi(room_id, baluster, balusters, stone)
	for z in [-5.8, -3.7]:
		_cylinder(kit, room_id, Vector3(side * 10.9, 0.55, z), 0.08, 0.08, 1.1, gold)
		_sphere(kit, room_id, Vector3(side * 10.9, 1.16, z), Vector3.ONE * 0.16, gold)
	_beam(kit, room_id, Vector3(side * 10.9, 0.94, -5.8), Vector3(side * 10.9, 0.94, -3.7), 0.07, kit.mat("velvet_red"))


static func _chandelier(kit: LevelKit, room_id: String, centre: Vector3) -> void:
	# Chandelier_01 is authored in centimetres, so always set its metre height.
	kit.model(room_id, "Chandelier_01", Transform3D(Basis.IDENTITY, centre + Vector3(0, 6.28, 0)), 2.35, "none")
	_cylinder(kit, room_id, centre + Vector3(0, 8.82, 0), 0.035, 0.035, 0.38, kit.mat("brass"))
	kit.omni(room_id, centre + Vector3(0, 6.85, 0), Color(1.0, 0.73, 0.44), 2.1, 9.3, true)


static func _pendant(kit: LevelKit, room_id: String, pos: Vector3, yaw: float) -> void:
	var turn := Basis(Vector3.UP, yaw)
	kit.model(room_id, "Chandelier_02", Transform3D(turn, pos), 0.85, "none")
	_cylinder(kit, room_id, pos + Vector3(0, 2.43, 0), 0.025, 0.025, 3.16, kit.mat("brass"))
	kit.omni(room_id, pos + turn * Vector3(0, 0.24, 0.16), Color(1.0, 0.72, 0.44), 0.94, 6.4)


static func _banners(kit: LevelKit, room_id: String) -> void:
	for x in [-13.34, 13.34]:
		for z in [-2.9, 14.2]:
			_box(kit, room_id, Vector3(x, 5.18, z), Vector3(0.08, 2.86, 1.26), kit.mat("wallpaper_navy"))
			_box(kit, room_id, Vector3(x, 5.18, z - 0.57), Vector3(0.09, 2.86, 0.08), kit.mat("gold"))
			_box(kit, room_id, Vector3(x, 5.18, z + 0.57), Vector3(0.09, 2.86, 0.08), kit.mat("gold"))
			_box(kit, room_id, Vector3(x, 6.67, z), Vector3(0.18, 0.08, 1.5), kit.mat("wood_dark"))
			kit.label(room_id, "☾", Vector3(x - signf(x) * 0.055, 5.25, z), PI * 0.5 if x < 0.0 else -PI * 0.5, 92, Color(0.95, 0.77, 0.38))


static func _furniture(kit: LevelKit, room_id: String) -> void:
	# Cover inside the Inspector's x=+/-9, z=15 perimeter route.
	for p in [Vector3(-6.3, 0, -2.7), Vector3(6.3, 0, -2.7), Vector3(-6.3, 0, 13.7), Vector3(6.3, 0, 13.7)]:
		kit.model(room_id, "potted_plant_01", Transform3D(Basis.IDENTITY, p), 1.34)
	for p in [Vector3(-5.8, 0, -5.0), Vector3(5.8, 0, -5.0), Vector3(-5.8, 0, 17.2), Vector3(5.8, 0, 17.2)]:
		kit.model(room_id, "painted_wooden_bench", Transform3D(Basis.IDENTITY, p), 0.89)
	for x in [-5.7, 5.7]:
		var p := Vector3(x, 0, 0.1)
		kit.model(room_id, "ClassicConsole_01", Transform3D(Basis.IDENTITY, p), 0.95)
		kit.model(room_id, "antique_ceramic_vase_01", Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.95), 0.44, "none")


static func _wall_art(kit: LevelKit, room_id: String) -> void:
	# Reliefs, canvases and mirrors fill the visitor's eye-level band; arches stay open.
	for x in [-7.0, 7.0]:
		_painting(kit, room_id, Vector3(x, 2.0, -7.48), 0.0)
		_painting(kit, room_id, Vector3(x, 2.0, 19.48), PI)
	for x in [-10.0, 10.0]:
		kit.model(room_id, "lion_head", Transform3D(Basis.IDENTITY, Vector3(x, 3.15, -7.43)), 0.70, "none")
	for x in [-13.48, 13.48]:
		for z in [9.4, 16.5]:
			kit.model(room_id, "ornate_mirror_01", Transform3D(Basis(Vector3.UP, -PI * 0.5 if x > 0.0 else PI * 0.5), Vector3(x, 2.0, z)), 1.35, "none")


static func _painting(kit: LevelKit, room_id: String, base: Vector3, yaw: float) -> void:
	var facing := Basis(Vector3.UP, yaw)
	kit.model(room_id, "fancy_picture_frame_02", Transform3D(facing, base), 1.7, "none")
	var canvas := QuadMesh.new()
	canvas.size = Vector2(1.08, 1.23)
	kit.prop(room_id, canvas, Transform3D(facing, base + facing * Vector3(0, 0.85, 0.12)), _canvas())
	# Brass picture lamp and its short warm cone.
	var lamp := BoxMesh.new()
	lamp.size = Vector3(0.8, 0.065, 0.13)
	kit.prop(room_id, lamp, Transform3D(facing, base + facing * Vector3(0, 1.96, 0.22)), kit.mat("brass"))
	kit.spot(room_id, base + facing * Vector3(0, 1.92, 0.33), base + facing * Vector3(0, 0.85, 0.1), Color(1.0, 0.77, 0.48), 0.66, 3.0, 52.0)


static func _canvas() -> StandardMaterial3D:
	if _painting_material != null:
		return _painting_material
	# Generated oil painting: a moonlit Beaux-Arts roofline in rain.
	var image := Image.create(256, 288, false, Image.FORMAT_RGBA8)
	for y in 288:
		for x in 256:
			var u := float(x) / 255.0
			var v := float(y) / 287.0
			var grain := sin(float(x * 37 + y * 19)) * sin(float(x * 11 - y * 31)) * 0.025
			var color := Color(0.045, 0.065, 0.13).lerp(Color(0.30, 0.29, 0.31), v * 0.75)
			var moon := Vector2(u - 0.72, v - 0.29).length()
			if moon < 0.11:
				color = color.lerp(Color(0.94, 0.84, 0.59), 1.0 - smoothstep(0.065, 0.11, moon))
			var roof := 0.65 - 0.12 * (1.0 - absf(u - 0.5) * 2.0)
			if v > roof:
				color = Color(0.055, 0.052, 0.067).lerp(Color(0.16, 0.10, 0.09), (v - roof) * 0.8)
				if posmod(x, 29) < 5 and posmod(y, 41) < 14 and v < 0.9:
					color = color.lerp(Color(0.82, 0.52, 0.25), 0.75)
			if absf(sin(u * 91.0 + v * 28.0)) > 0.97:
				color = color.lerp(Color(0.57, 0.59, 0.64), 0.17)
			image.set_pixel(x, y, Color(clampf(color.r + grain, 0, 1), clampf(color.g + grain, 0, 1), clampf(color.b + grain, 0, 1)))
	image.generate_mipmaps()
	_painting_material = StandardMaterial3D.new()
	_painting_material.albedo_texture = ImageTexture.create_from_image(image)
	_painting_material.roughness = 0.82
	_painting_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _painting_material


static func _water() -> ShaderMaterial:
	if _water_material == null:
		_water_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type spatial; render_mode cull_disabled;\n" \
			+ "void vertex() { VERTEX.y += 0.022 * sin(VERTEX.x * 7.0 + TIME * 1.3) * cos(VERTEX.z * 6.0 - TIME); }\n" \
			+ "void fragment() { float ripple = sin(UV.x * 85.0 + TIME * 1.4) * sin(UV.y * 75.0 - TIME * 1.1);\n" \
			+ "ALBEDO = vec3(0.055, 0.23, 0.33) + ripple * 0.013; METALLIC = 0.36; ROUGHNESS = 0.09; SPECULAR = 0.85; }"
		_water_material.shader = shader
	return _water_material


static func _box(kit: LevelKit, room_id: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	kit.prop(room_id, mesh, Transform3D(Basis(), pos), material)


static func _cylinder(kit: LevelKit, room_id: String, pos: Vector3, bottom: float, top: float, height: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 20
	kit.prop(room_id, mesh, Transform3D(Basis(), pos), material)


static func _sphere(kit: LevelKit, room_id: String, pos: Vector3, scale_by: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	kit.prop(room_id, mesh, Transform3D(Basis().scaled(scale_by), pos), material)


static func _beam(kit: LevelKit, room_id: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var d: Vector3 = b - a
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = d.length()
	mesh.radial_segments = 8
	kit.prop(room_id, mesh, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), (a + b) * 0.5), material)
