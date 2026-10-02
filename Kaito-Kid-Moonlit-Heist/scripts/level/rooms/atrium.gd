extends RefCounted
## Ceremonial hub: a fountain breaks the foyer-to-gallery sight line while the
## Inspector's perimeter patrol and all four arches retain clear approaches.

static var _wing_mesh: ArrayMesh
static var _water_material: ShaderMaterial


static func dress(kit: LevelKit, room_id: String) -> void:
	var centre: Vector3 = MuseumLayout.CENTREPIECE["pos"]
	_fountain(kit, room_id, centre)
	_columns(kit, room_id)
	_stair(kit, room_id, -1.0)
	_stair(kit, room_id, 1.0)
	_chandelier(kit, room_id, centre)
	_banners(kit, room_id)
	_furniture(kit, room_id)
	kit.spot(room_id, centre + Vector3(0, 8.2, 0), centre + Vector3(0, 2.2, 0), Color(0.63, 0.76, 1.0), 2.2, 10.0, 42.0, true)
	for x in [-10.7, 10.7]:
		kit.omni(room_id, Vector3(x, 5.6, 6.0), Color(1.0, 0.72, 0.43), 0.9, 7.0)


static func _fountain(kit: LevelKit, room_id: String, centre: Vector3) -> void:
	# The structure owns the fountain's 3.2 m radius collider.
	var black: Material = kit.mat("marble_black")
	var white: Material = kit.mat("marble_white")
	var gold: Material = kit.mat("gold")
	var rim := TorusMesh.new()
	rim.inner_radius = 2.72
	rim.outer_radius = 3.16
	rim.rings = 64
	rim.ring_segments = 12
	kit.prop(room_id, rim, Transform3D(Basis(), centre + Vector3(0, 1.36, 0)), white)
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
	kit.prop(room_id, water, Transform3D(Basis(), centre + Vector3(0, 1.26, 0)), _water())
	for i in 8:
		var a: float = TAU * float(i) / 8.0
		_sphere(kit, room_id, centre + Vector3(cos(a) * 2.45, 1.39, sin(a) * 2.45), Vector3(0.09, 0.045, 0.09), gold)
	# Carved winged figure with a tapered gown, articulated arms and moon halo.
	_cylinder(kit, room_id, centre + Vector3(0, 1.56, 0), 0.87, 0.87, 0.58, black)
	_cylinder(kit, room_id, centre + Vector3(0, 1.9, 0), 0.70, 0.65, 0.16, gold)
	_cylinder(kit, room_id, centre + Vector3(0, 2.45, 0), 0.53, 0.32, 1.08, white)
	_sphere(kit, room_id, centre + Vector3(0, 3.13, 0), Vector3(0.40, 0.64, 0.29), white)
	_sphere(kit, room_id, centre + Vector3(0, 3.87, 0), Vector3(0.27, 0.32, 0.26), white)
	for side in [-1.0, 1.0]:
		_beam(kit, room_id, centre + Vector3(side * 0.36, 3.53, 0), centre + Vector3(side * 0.76, 4.15, -0.02), 0.14, white)
		_beam(kit, room_id, centre + Vector3(side * 0.76, 4.15, -0.02), centre + Vector3(side * 0.43, 4.78, -0.08), 0.11, white)
		var wing_basis := Basis.IDENTITY
		if side < 0.0:
			wing_basis = Basis(Vector3.UP, PI)
		kit.prop(room_id, _wings(), Transform3D(wing_basis, centre + Vector3(0, 3.3, 0.2)), white)
	_sphere(kit, room_id, centre + Vector3(0, 5.13, -0.06), Vector3(0.39, 0.39, 0.39), kit.mat("emissive_cool"))
	var halo := TorusMesh.new()
	halo.inner_radius = 0.43
	halo.outer_radius = 0.49
	halo.rings = 32
	kit.prop(room_id, halo, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), centre + Vector3(0, 5.13, -0.06)), gold)


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
		for z in [-6.1, 1.8, 11.0, 17.2]:
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
	for i in 9:
		var y: float = 0.23 + float(i) * 0.265
		var z: float = -5.05 + float(i) * 0.69
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
	var gold: Material = kit.mat("brass")
	var ring := TorusMesh.new()
	ring.inner_radius = 1.40
	ring.outer_radius = 1.53
	ring.rings = 48
	ring.ring_segments = 10
	kit.prop(room_id, ring, Transform3D(Basis(), centre + Vector3(0, 7.05, 0)), gold)
	kit.prop(room_id, ring, Transform3D(Basis().scaled(Vector3(0.7, 1, 0.7)), centre + Vector3(0, 7.55, 0)), gold)
	_cylinder(kit, room_id, centre + Vector3(0, 8.03, 0), 0.075, 0.075, 1.85, gold)
	for i in 12:
		var a: float = TAU * float(i) / 12.0
		var p := centre + Vector3(cos(a) * 1.48, 7.02, sin(a) * 1.48)
		_beam(kit, room_id, p, centre + Vector3(0, 8.10, 0), 0.025, gold)
		_sphere(kit, room_id, p + Vector3(0, -0.17, 0), Vector3(0.10, 0.24, 0.10), kit.mat("glass"))
		if i % 2 == 0:
			_sphere(kit, room_id, p + Vector3(0, 0.14, 0), Vector3(0.14, 0.17, 0.14), kit.mat("emissive_warm"))
	kit.omni(room_id, centre + Vector3(0, 7.1, 0), Color(1.0, 0.76, 0.48), 1.2, 8.0)


static func _banners(kit: LevelKit, room_id: String) -> void:
	for x in [-13.34, 13.34]:
		for z in [-2.9, 14.2]:
			_box(kit, room_id, Vector3(x, 5.18, z), Vector3(0.08, 2.86, 1.26), kit.mat("wallpaper_navy"))
			_box(kit, room_id, Vector3(x, 5.18, z - 0.57), Vector3(0.09, 2.86, 0.08), kit.mat("gold"))
			_box(kit, room_id, Vector3(x, 5.18, z + 0.57), Vector3(0.09, 2.86, 0.08), kit.mat("gold"))
			_box(kit, room_id, Vector3(x, 6.67, z), Vector3(0.18, 0.08, 1.5), kit.mat("wood_dark"))
			kit.label(room_id, "☾", Vector3(x - signf(x) * 0.055, 5.25, z), PI * 0.5 if x < 0.0 else -PI * 0.5, 92, Color(0.95, 0.77, 0.38))


static func _furniture(kit: LevelKit, room_id: String) -> void:
	# Cover stays away from open_a (-7,13) and both side arch approaches.
	for p in [Vector3(6.2, 0, -2.6), Vector3(6.2, 0, 14.8), Vector3(-6.2, 0, -2.6)]:
		kit.cylinder_solid(room_id, p, 0.71, 1.11, kit.mat("marble_black"), 20)
		_cylinder(kit, room_id, p + Vector3(0, 0.94, 0), 0.79, 0.72, 0.12, kit.mat("gold"))
		for i in 5:
			var a: float = TAU * float(i) / 5.0
			_sphere(kit, room_id, p + Vector3(cos(a) * 0.29, 1.49, sin(a) * 0.29), Vector3(0.42, 0.56, 0.42), kit.mat("velvet_green"))
	var b := Vector3(5.5, 0, -5.3)
	kit.solid(room_id, b, Vector3(2.7, 1.12, 0.63), kit.mat("wood_dark"), 0.0, false)
	_box(kit, room_id, b + Vector3(0, 0.48, -0.04), Vector3(2.55, 0.13, 0.56), kit.mat("velvet_blue"))
	_box(kit, room_id, b + Vector3(0, 0.91, 0.24), Vector3(2.65, 0.43, 0.10), kit.mat("wood_light"))
	_box(kit, room_id, b + Vector3(0, 0.58, -0.34), Vector3(2.78, 0.06, 0.06), kit.mat("brass"))


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


static func _wings() -> ArrayMesh:
	if _wing_mesh == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var outline: PackedVector3Array = PackedVector3Array([
			Vector3(0.24, 0.06, 0.0), Vector3(0.78, 0.65, 0.12),
			Vector3(1.2, 1.08, 0.22), Vector3(1.47, 0.85, 0.18),
			Vector3(1.72, 1.12, 0.16), Vector3(1.55, 0.48, 0.13),
			Vector3(1.85, 0.63, 0.12), Vector3(1.50, 0.06, 0.08),
			Vector3(1.73, 0.12, 0.07), Vector3(1.19, -0.28, 0.02),
			Vector3(1.38, -0.38, 0.02), Vector3(0.73, -0.39, 0.0)
		])
		for i in range(1, outline.size() - 1):
			for v in [outline[0], outline[i], outline[i + 1]]:
				st.set_normal(Vector3(0, 0, 1))
				st.add_vertex(v)
			for v in [outline[i + 1], outline[i], outline[0]]:
				st.set_normal(Vector3(0, 0, -1))
				st.add_vertex(v)
		_wing_mesh = st.commit()
	return _wing_mesh


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
