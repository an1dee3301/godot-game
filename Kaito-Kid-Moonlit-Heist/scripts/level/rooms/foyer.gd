extends RefCounted
## Formal, quiet arrival room. The central sight line to the atrium stays open.

static var _leaf: ArrayMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	# The foyer is x=-10..10, z=20..32; spawn is (0, 29), arch is x=-3..3 at z=20.
	_medallion(kit, room_id)
	_box(kit, room_id, Vector3(0, 0.025, 26.0), Vector3(2.7, 0.025, 5.7), kit.mat("carpet_red"))
	for x in [-1.2, 1.2]:
		_box(kit, room_id, Vector3(x, 0.044, 26.0), Vector3(0.045, 0.01, 5.5), kit.mat("gold"))
	_banner(kit, room_id)
	_desk(kit, room_id)
	_statue(kit, room_id)
	for x in [-6.6, 6.6]:
		_bench(kit, room_id, Vector3(x, 0, 29.0))
	for x in [-8.0, 8.0]:
		_palm(kit, room_id, Vector3(x, 0, 21.6))
	# A short, open brass queue guides the eye to ticketing without enclosing the spawn.
	for z in [25.5, 27.6]:
		for x in [3.35, 5.05]:
			kit.cylinder_solid(room_id, Vector3(x, 0, z), 0.07, 0.88, kit.mat("brass"))
			_cylinder(kit, room_id, Vector3(x, 0.06, z), 0.14, 0.12, kit.mat("brass"))
			_sphere(kit, room_id, Vector3(x, 0.89, z), 0.09, kit.mat("gold"))
		for x in [3.65, 4.2, 4.75]:
			_sphere(kit, room_id, Vector3(x, 0.67 - 0.1 * (1.0 - absf(x - 4.2) / 0.55), z), 0.055, kit.mat("velvet_red"))
	kit.omni(room_id, Vector3(-6.0, 4.7, 26.0), Color(1.0, 0.77, 0.49), 0.85, 6.0)
	kit.omni(room_id, Vector3(6.0, 4.7, 26.0), Color(1.0, 0.77, 0.49), 0.85, 6.0)
	kit.spot(room_id, Vector3(-7.3, 4.8, 24.5), Vector3(-7.9, 1.8, 25.0), Color(1.0, 0.82, 0.57), 1.4, 5.2, 43.0, true)


static func _medallion(kit: LevelKit, id: String) -> void:
	for data in [[1.83, "marble_black", 0.025], [1.67, "brass", 0.035], [1.51, "marble_white", 0.046], [0.30, "wallpaper_navy", 0.068]]:
		_cylinder(kit, id, Vector3(0, data[2], 25.0), data[0], 0.015, kit.mat(data[1]))
	for i in 8:
		var a := float(i) * TAU / 8.0
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.24, 0.012, 1.08 if i % 2 else 1.35)
		kit.prop(id, mesh, Transform3D(Basis(Vector3.UP, a), Vector3(sin(a) * 0.75, 0.062, 25.0 + cos(a) * 0.75)), kit.mat("gold"))


static func _banner(kit: LevelKit, id: String) -> void:
	# High on the south wall; no window or playable floor is covered.
	_box(kit, id, Vector3(0, 5.15, 31.5), Vector3(7.9, 1.12, 0.13), kit.mat("wood_dark"))
	_box(kit, id, Vector3(0, 5.15, 31.39), Vector3(7.65, 0.95, 0.04), kit.mat("wallpaper_navy"))
	for y in [4.59, 5.71]:
		_box(kit, id, Vector3(0, y, 31.33), Vector3(8.0, 0.055, 0.08), kit.mat("gold"))
	kit.label(id, "MOONLIGHT MUSEUM", Vector3(0, 5.33, 31.28), PI, 51, Color(0.98, 0.82, 0.48))
	kit.label(id, "FIVE JEWELS  ·  ONE ENCORE", Vector3(0, 4.95, 31.27), PI, 27, Color(0.95, 0.9, 0.77))
	kit.spot(id, Vector3(0, 6.3, 28.9), Vector3(0, 5.1, 31.3), Color(1, 0.78, 0.46), 1.8, 6.0, 48.0)


static func _desk(kit: LevelKit, id: String) -> void:
	var p := Vector3(7.05, 0, 26.1)
	kit.solid(id, p, Vector3(3.7, 1.08, 1.22), kit.mat("wood_dark"))
	_box(kit, id, p + Vector3(0, 1.11, 0), Vector3(3.9, 0.12, 1.42), kit.mat("marble_black"))
	_box(kit, id, p + Vector3(0, 1.18, 0), Vector3(3.78, 0.025, 1.33), kit.mat("brass"))
	for x in [-1.22, 0.0, 1.22]:
		_box(kit, id, p + Vector3(x, 0.55, -0.63), Vector3(1.06, 0.72, 0.04), kit.mat("wood_light"))
		_box(kit, id, p + Vector3(x, 0.55, -0.66), Vector3(0.87, 0.53, 0.025), kit.mat("wood_dark"))
		_box(kit, id, p + Vector3(x, 0.55, -0.68), Vector3(0.62, 0.025, 0.025), kit.mat("gold"))
	kit.label(id, "ADMISSION", Vector3(7.05, 2.0, 29.5), PI, 30, Color(0.95, 0.78, 0.42))
	kit.spot(id, Vector3(7.0, 5.7, 27.0), p + Vector3(0, 0.7, 0), Color(1, 0.77, 0.48), 1.25, 5.5, 40.0)


static func _statue(kit: LevelKit, id: String) -> void:
	var p := Vector3(-8.0, 0, 25.0)
	_box(kit, id, Vector3(-9.40, 2.5, 25.0), Vector3(0.06, 4.0, 3.0), kit.mat("wallpaper_navy"))
	for z in [23.47, 26.53]:
		_box(kit, id, Vector3(-9.29, 2.5, z), Vector3(0.13, 4.15, 0.10), kit.mat("gold"))
	_box(kit, id, Vector3(-9.28, 4.62, 25.0), Vector3(0.14, 0.13, 3.2), kit.mat("gold"))
	kit.cylinder_solid(id, p, 0.60, 1.05, kit.mat("marble_white"))
	_cylinder(kit, id, p + Vector3(0, 1.10, 0), 0.68, 0.11, kit.mat("gold"))
	var body := CapsuleMesh.new()
	body.radius = 0.34
	body.height = 1.24
	kit.prop(id, body, Transform3D(Basis.IDENTITY, p + Vector3(0, 1.88, 0)), kit.mat("ivory"))
	_sphere(kit, id, p + Vector3(0, 2.67, 0), 0.24, kit.mat("ivory"))
	# Two swept wings give the niche a readable silhouette from the entrance.
	for side in [-1.0, 1.0]:
		for i in 4:
			var a := Vector3(side * 0.26, 2.27 - i * 0.13, 0)
			var b := Vector3(side * (0.67 + i * 0.09), 2.86 - i * 0.23, 0.05)
			_segment(kit, id, p + a, p + b, 0.065 - i * 0.009, kit.mat("gold"))


static func _bench(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.solid(id, p, Vector3(2.13, 0.42, 0.66), kit.mat("wood_dark"))
	_box(kit, id, p + Vector3(0, 0.46, 0), Vector3(2.22, 0.12, 0.71), kit.mat("velvet_blue"))
	kit.solid(id, p + Vector3(0, 0.45, 0.27), Vector3(2.22, 0.76, 0.10), kit.mat("wood_dark"), 0.0, false)
	for x in [-0.97, 0.97]:
		_box(kit, id, p + Vector3(x, 0.53, 0), Vector3(0.08, 0.09, 0.75), kit.mat("brass"))


static func _palm(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.cylinder_solid(id, p, 0.42, 0.72, kit.mat("marble_black"))
	_cylinder(kit, id, p + Vector3(0, 0.75, 0), 0.46, 0.08, kit.mat("gold"))
	_cylinder(kit, id, p + Vector3(0, 1.66, 0), 0.09, 1.77, kit.mat("wood_dark"))
	if _leaf == null:
		_leaf = _make_leaf()
	for i in 9:
		kit.prop(id, _leaf, Transform3D(Basis(Vector3.UP, float(i) * TAU / 9.0), p + Vector3(0, 2.49, 0)), kit.mat("velvet_green"))


static func _make_leaf() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var t := float(i) / 6.0
		var u := float(i + 1) / 6.0
		var a := Vector3(t * 1.48, 0.25 * sin(t * PI) - 0.57 * t * t, 0)
		var b := Vector3(u * 1.48, 0.25 * sin(u * PI) - 0.57 * u * u, 0)
		for side in [-1.0, 1.0]:
			for v in [a + Vector3(0, 0, side * 0.24 * sin(t * PI)), b + Vector3(0, 0, side * 0.24 * sin(u * PI)), a + Vector3(0, 0.05, 0)]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func _segment(kit: LevelKit, id: String, a: Vector3, b: Vector3, r: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	kit.prop(id, mesh, Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())), (a + b) * 0.5), material)


static func _sphere(kit: LevelKit, id: String, p: Vector3, r: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	kit.prop(id, mesh, Transform3D(Basis.IDENTITY, p), material)


static func _cylinder(kit: LevelKit, id: String, p: Vector3, r: float, h: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mesh.radial_segments = 32
	kit.prop(id, mesh, Transform3D(Basis.IDENTITY, p), material)


static func _box(kit: LevelKit, id: String, p: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	kit.prop(id, mesh, Transform3D(Basis.IDENTITY, p), material)
