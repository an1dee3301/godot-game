extends RefCounted
## A lunar observatory leading to the balcony finale.

static var _meshes: Dictionary = {}


static func dress(kit: LevelKit, room_id: String) -> void:
	var brass := kit.mat("brass")
	var gold := kit.mat("gold")
	var blue := kit.mat("velvet_blue")
	var navy := kit.mat("wallpaper_navy")
	var ivory := kit.mat("ivory")
	var wood := kit.mat("wood_dark")
	# A three metre moon suspended in a brass equatorial armature. It sits to
	# one side so the atrium-to-gate axis remains obvious and walkable.
	var moon_at := Vector3(-6.2, 3.82, -15.8)
	kit.cylinder_solid(room_id, Vector3(-6.2, 0, -15.8), 1.8, 0.55, kit.mat("marble_black"), 32)
	kit.cylinder_solid(room_id, Vector3(-6.2, 0.55, -15.8), 0.19, 1.05, brass, 16)
	kit.prop(room_id, _sphere(1.75, 48), Transform3D(Basis.IDENTITY, moon_at), ivory)
	_ring(kit, room_id, moon_at, 1.98, 0.035, Basis(Vector3.RIGHT, deg_to_rad(22.0)), brass)
	_ring(kit, room_id, moon_at, 1.99, 0.026, Basis(Vector3.FORWARD, deg_to_rad(25.0)), gold)
	# Sparse recessed craters give the globe scale without a noisy texture.
	var craters: Array[Transform3D] = []
	for data in [[-0.68, 0.37, 0.93], [0.2, 0.68, 0.7], [0.7, -0.28, 0.81], [-0.22, -0.43, 0.64], [0.55, 0.4, 0.38]]:
		var cx: float = data[0]
		var cy: float = data[1]
		var radius: float = data[2]
		var cz := sqrt(maxf(0.0, 1.0 - cx * cx - cy * cy))
		var normal := Vector3(cx, cy, cz).normalized()
		var basis := Basis(Quaternion(Vector3.UP, normal)).scaled(Vector3(radius, 0.035, radius))
		craters.append(Transform3D(basis, moon_at + normal * 1.72))
	kit.multi(room_id, _sphere(1.0, 20), craters, kit.mat("stone"))
	kit.label(room_id, "SELENE  /  THE NEAR SIDE", Vector3(-6.2, 1.38, -13.98), PI, 26, Color(0.82, 0.77, 0.61))

	# A restrained celestial diagram inlaid flush with the marble floor.
	# Its arcs visually pull the player north without changing navigation.
	for r in [3.0, 5.8, 8.5]:
		_ring(kit, room_id, Vector3(0, 0.027, -20.2), r, 0.015, Basis.IDENTITY, brass)
	var stars: Array[Transform3D] = []
	for i in 26:
		var a := float(i) * 2.39996323
		var r := 3.0 + float(i % 3) * 2.45
		stars.append(Transform3D(Basis(Vector3.UP, a), Vector3(cos(a) * r, 0.031, -20.2 + sin(a) * r)))
	kit.multi(room_id, _star_mesh(), stars, gold)
	var constellations: Array[Transform3D] = []
	for i in 7:
		var a := float(i) * TAU / 7.0
		constellations.append(Transform3D(Basis(Vector3.UP, a), Vector3(cos(a) * 6.6, 0.028, -20.2 + sin(a) * 6.6)))
	kit.multi(room_id, _box(Vector3(0.025, 0.011, 1.15)), constellations, gold)

	# Observatory instruments are offset from the central route and the
	# inspector's z=-22 sweep. Their bases double as crouch-height cover.
	_telescope(kit, room_id, Vector3(8.0, 0, -15.3))
	_orrery(kit, room_id, Vector3(-8.0, 0, -26.1))
	kit.solid(room_id, Vector3(8.1, 0, -25.2), Vector3(2.8, 1.13, 1.15), navy)
	kit.prop(room_id, _box(Vector3(2.9, 0.12, 1.24)), Transform3D(Basis.IDENTITY, Vector3(8.1, 1.16, -25.2)), brass)
	kit.solid(room_id, Vector3(4.7, 0, -12.8), Vector3(2.4, 1.1, 0.9), wood)
	kit.prop(room_id, _box(Vector3(2.5, 0.08, 1.0)), Transform3D(Basis.IDENTITY, Vector3(4.7, 1.12, -12.8)), brass)

	# North wall: tall existing windows receive moon-facing reveals and cool
	# shafts. The centre gate is framed like a stage, clear from x=-2..2.
	for x in [-8.0, 8.0]:
		_box_prop(kit, room_id, Vector3(x - 1.45, 3.25, -29.42), Vector3(0.1, 4.55, 0.13), ivory)
		_box_prop(kit, room_id, Vector3(x + 1.45, 3.25, -29.42), Vector3(0.1, 4.55, 0.13), ivory)
		_box_prop(kit, room_id, Vector3(x, 5.56, -29.42), Vector3(3.0, 0.11, 0.13), gold)
		kit.spot(room_id, Vector3(x, 5.85, -29.2), Vector3(x * 0.82, 0.15, -22.0), Color(0.53, 0.67, 1.0), 1.5, 10.0, 31.0)
	for x in [-3.03, 3.03]:
		_box_prop(kit, room_id, Vector3(x, 3.3, -29.42), Vector3(0.28, 5.75, 0.23), brass)
		_box_prop(kit, room_id, Vector3(x, 3.55, -29.12), Vector3(0.55, 4.9, 0.2), blue)
		for fold in [-0.19, 0.0, 0.19]:
			_box_prop(kit, room_id, Vector3(x + fold, 3.57, -29.0), Vector3(0.035, 4.83, 0.035), navy)
	_box_prop(kit, room_id, Vector3(0, 6.08, -29.39), Vector3(6.25, 0.25, 0.25), gold)
	kit.label(room_id, "AD ASTRA", Vector3(0, 5.47, -29.08), 0.0, 39, Color(0.92, 0.83, 0.57))
	kit.spot(room_id, Vector3(-4.3, 5.9, -26.8), Vector3(0, 0.15, -29.4), Color(0.72, 0.81, 1.0), 2.0, 8.5, 31.0)
	kit.spot(room_id, Vector3(4.3, 5.9, -26.8), Vector3(0, 0.15, -29.4), Color(0.72, 0.81, 1.0), 2.0, 8.5, 31.0)
	kit.spot(room_id, Vector3(-6.2, 6.18, -15.8), moon_at, Color(0.67, 0.77, 1.0), 2.6, 7.0, 37.0, true)
	kit.omni(room_id, Vector3(8.3, 4.6, -15.2), Color(1.0, 0.73, 0.43), 0.65, 5.0)
	kit.omni(room_id, Vector3(-8.1, 4.6, -25.5), Color(1.0, 0.73, 0.43), 0.5, 4.2)
	kit.label(room_id, "THE HEAVENS IN MOTION", Vector3(0, 5.72, -8.59), PI, 34, Color(0.85, 0.76, 0.53))


static func _telescope(kit: LevelKit, room_id: String, pos: Vector3) -> void:
	var brass := kit.mat("brass")
	kit.cylinder_solid(room_id, pos, 1.12, 0.33, kit.mat("marble_black"), 24)
	kit.cylinder_solid(room_id, pos + Vector3(0, 0.33, 0), 0.11, 1.25, brass, 12)
	var pivot := pos + Vector3(0, 1.78, 0)
	kit.prop(room_id, _sphere(0.22, 16), Transform3D(Basis.IDENTITY, pivot), brass)
	var tube_dir := Vector3(-0.25, 0.47, -0.85).normalized()
	var tube_basis := Basis(Quaternion(Vector3.UP, tube_dir))
	kit.prop(room_id, _cylinder(0.28, 2.5, 20), Transform3D(tube_basis, pivot + tube_dir * 0.52), kit.mat("bronze"))
	kit.prop(room_id, _cylinder(0.33, 0.13, 20), Transform3D(tube_basis, pivot + tube_dir * 1.82), kit.mat("gold"))
	kit.prop(room_id, _cylinder(0.16, 0.3, 16), Transform3D(tube_basis, pivot - tube_dir * 0.84), brass)
	kit.label(room_id, "LUNAR OBSERVATORY", pos + Vector3(0, 0.75, 1.12), PI, 20)


static func _orrery(kit: LevelKit, room_id: String, pos: Vector3) -> void:
	var brass := kit.mat("brass")
	kit.cylinder_solid(room_id, pos, 1.15, 0.95, kit.mat("wood_dark"), 24)
	kit.prop(room_id, _cylinder(1.26, 0.07, 32), Transform3D(Basis.IDENTITY, pos + Vector3(0, 1.0, 0)), brass)
	var centre := pos + Vector3(0, 1.28, 0)
	kit.prop(room_id, _sphere(0.22, 20), Transform3D(Basis.IDENTITY, centre), kit.mat("emissive_warm"))
	for radius in [0.45, 0.73, 1.04]:
		_ring(kit, room_id, centre, radius, 0.018, Basis.IDENTITY, brass)
	for i in 3:
		var a := float(i) * TAU / 3.0 + 0.4
		var r := 0.45 + float(i) * 0.29
		var planet_pos := centre + Vector3(cos(a) * r, 0.07, sin(a) * r)
		var planet_mat := kit.mat("lapis") if i == 1 else kit.mat("ivory")
		kit.prop(room_id, _sphere(0.085 + float(i) * 0.025, 16),
			Transform3D(Basis.IDENTITY, planet_pos), planet_mat)
	kit.label(room_id, "CELESTIAL MECHANISM", pos + Vector3(0, 0.62, 1.14), PI, 19)


static func _box_prop(kit: LevelKit, room_id: String, centre: Vector3, size: Vector3, material: Material) -> void:
	kit.prop(room_id, _box(size), Transform3D(Basis.IDENTITY, centre), material)


static func _box(size: Vector3) -> BoxMesh:
	var key := "box_%s" % str(size)
	if not _meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_meshes[key] = mesh
	return _meshes[key] as BoxMesh


static func _sphere(radius: float, segments: int) -> SphereMesh:
	var key := "sphere_%s_%s" % [str(radius), str(segments)]
	if not _meshes.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = segments
		mesh.rings = segments / 2
		_meshes[key] = mesh
	return _meshes[key] as SphereMesh


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var key := "cyl_%s_%s" % [str(radius), str(height)]
	if not _meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = segments
		_meshes[key] = mesh
	return _meshes[key] as CylinderMesh


static func _ring(kit: LevelKit, room_id: String, pos: Vector3, radius: float, tube: float, basis: Basis, material: Material) -> void:
	var key := "ring_%s_%s" % [str(radius), str(tube)]
	if not _meshes.has(key):
		var mesh := TorusMesh.new()
		mesh.inner_radius = radius - tube
		mesh.outer_radius = radius + tube
		mesh.ring_segments = 48
		mesh.rings = 8
		_meshes[key] = mesh
	kit.prop(room_id, _meshes[key] as Mesh, Transform3D(basis, pos), material)


static func _star_mesh() -> Mesh:
	if _meshes.has("star"):
		return _meshes["star"] as Mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var a := float(i) * TAU / 8.0
		var b := float(i + 1) * TAU / 8.0
		var ra := 0.22 if i % 2 == 0 else 0.075
		var rb := 0.22 if (i + 1) % 2 == 0 else 0.075
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(cos(b) * rb, 0, sin(b) * rb))
		st.add_vertex(Vector3(cos(a) * ra, 0, sin(a) * ra))
	st.generate_normals()
	var mesh := st.commit()
	_meshes["star"] = mesh
	return mesh
