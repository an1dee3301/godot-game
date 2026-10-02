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
	_cloak_counter(kit, room_id)
	_posters(kit, room_id)
	kit.model(room_id, "Sofa_01", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-7.2, 0, 29.4)), 0.87)
	kit.model(room_id, "ArmChair_01", Transform3D(Basis(Vector3.UP, -PI * 0.25), Vector3(-5.0, 0, 29.5)))
	kit.model(room_id, "Ottoman_01", Transform3D(Basis.IDENTITY, Vector3(-6.2, 0, 27.8)), 0.44)
	kit.model(room_id, "ArmChair_01", Transform3D(Basis(Vector3.UP, PI * 0.35), Vector3(-4.35, 0, 27.4)))
	kit.model(room_id, "ClassicConsole_01", Transform3D(Basis.IDENTITY, Vector3(-6.0, 0, 30.9)), 0.95)
	kit.model(room_id, "brass_vase_01", Transform3D(Basis.IDENTITY, Vector3(-6.0, 0.96, 30.9)), 0.50, "none")
	_box(kit, room_id, Vector3(-7.15, 0.018, 28.8), Vector3(3.5, 0.018, 3.5), kit.mat("carpet_blue"))
	for x in [-4.05, 4.05]:
		kit.model(room_id, "potted_plant_01", Transform3D(Basis.IDENTITY, Vector3(x, 0, 21.3)), 1.65)
	_wall_art(kit, room_id)
	# A short, open brass queue guides the eye to ticketing without enclosing the spawn.
	for z in [25.5, 27.6]:
		for x in [3.35, 5.05]:
			kit.cylinder_solid(room_id, Vector3(x, 0, z), 0.07, 0.88, kit.mat("brass"))
			_cylinder(kit, room_id, Vector3(x, 0.06, z), 0.14, 0.12, kit.mat("brass"))
			_sphere(kit, room_id, Vector3(x, 0.89, z), 0.09, kit.mat("gold"))
		for x in [3.65, 4.2, 4.75]:
			_sphere(kit, room_id, Vector3(x, 0.67 - 0.1 * (1.0 - absf(x - 4.2) / 0.55), z), 0.055, kit.mat("velvet_red"))
	kit.model(room_id, "Chandelier_01", Transform3D(Basis.IDENTITY, Vector3(0, 4.7, 25.0)), 1.35, "none")
	_cylinder(kit, room_id, Vector3(0, 6.28, 25.0), 0.025, 0.48, kit.mat("brass"))
	kit.omni(room_id, Vector3(0, 4.9, 25.0), Color(1.0, 0.73, 0.44), 1.7, 9.0, true)
	for x in [-6.0, 6.0]:
		kit.spot(room_id, Vector3(x, 4.2, 31.0), Vector3(x * 0.7, 0.25, 26.8), Color(0.48, 0.62, 0.94), 0.42, 7.0, 48.0)
	for z in [22.6, 26.0]:
		_sconce(kit, room_id, Vector3(-9.35, 3.3, z), PI * 0.5)
	_sconce(kit, room_id, Vector3(9.35, 3.3, 24.2), -PI * 0.5)
	# Soft reflected chandelier light keeps the entrance legible from the spawn.
	kit.omni(room_id, Vector3(0, 4.1, 29.0), Color(0.90, 0.78, 0.64), 0.55, 6.0)


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
	_box(kit, id, Vector3(0, 5.91, 31.2), Vector3(1.3, 0.07, 0.14), kit.mat("brass"))
	_box(kit, id, Vector3(0, 5.86, 31.2), Vector3(1.1, 0.018, 0.11), kit.mat("emissive_warm"))
	kit.spot(id, Vector3(0, 5.85, 31.0), Vector3(0, 5.1, 31.3), Color(1, 0.78, 0.46), 1.25, 3.5, 48.0)


static func _desk(kit: LevelKit, id: String) -> void:
	# Two scanned consoles make the ticket counter; the rose pickup at (7, 23) stays clear.
	for x in [6.16, 7.84]:
		kit.model(id, "ClassicConsole_01", Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0, 26.1)))
	_box(kit, id, Vector3(7, 0.98, 26.1), Vector3(3.4, 0.065, 0.7), kit.mat("marble_black"))
	_box(kit, id, Vector3(7, 1.02, 26.1), Vector3(3.44, 0.02, 0.74), kit.mat("brass"))
	for x in [5.88, 8.12]:
		kit.model(id, "brass_candleholders", Transform3D(Basis.IDENTITY, Vector3(x, 1.04, 26.1)), 0.5, "none")
		kit.omni(id, Vector3(x, 1.48, 26.1), Color(1, 0.68, 0.37), 0.58, 2.5)
	kit.model(id, "mantel_clock_01", Transform3D(Basis.IDENTITY, Vector3(7, 1.04, 26.1)), 0.24, "none")
	kit.label(id, "ADMISSION", Vector3(7.05, 2.0, 29.5), PI, 30, Color(0.95, 0.78, 0.42))


static func _cloak_counter(kit: LevelKit, id: String) -> void:
	# The cloak service faces the foyer arch; its case is low enough for a sightline.
	var p := Vector3(-6.45, 0, 22.6)
	for x in [-7.22, -5.68]:
		kit.model(id, "ClassicConsole_01", Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0, p.z)), 0.95)
	_box(kit, id, p + Vector3(0, 0.98, 0), Vector3(3.2, 0.08, 0.72), kit.mat("marble_black"))
	_box(kit, id, p + Vector3(0, 1.03, 0), Vector3(3.27, 0.025, 0.77), kit.mat("brass"))
	kit.model(id, "mantel_clock_01", Transform3D(Basis.IDENTITY, p + Vector3(0, 1.05, 0)), 0.25, "none")
	kit.label(id, "CLOAK ROOM", Vector3(-6.45, 2.0, 20.55), 0.0, 30, Color(0.97, 0.83, 0.58))
	kit.spot(id, Vector3(-6.4, 4.9, 22.1), p + Vector3(0, 0.85, 0), Color(1.0, 0.79, 0.54), 1.3, 5.8, 48.0)


static func _posters(kit: LevelKit, id: String) -> void:
	# Freestanding exhibition boards flank, rather than block, the spawn axis.
	for x in [-3.7, 3.7]:
		var p := Vector3(x, 0, 30.0)
		kit.cylinder_solid(id, p, 0.34, 0.13, kit.mat("marble_black"))
		_cylinder(kit, id, p + Vector3(0, 0.18, 0), 0.25, 0.10, kit.mat("brass"))
		kit.solid(id, p + Vector3(0, 0.26, 0), Vector3(0.10, 1.48, 0.10), kit.mat("wood_dark"))
		var board := BoxMesh.new()
		board.size = Vector3(1.12, 1.52, 0.07)
		kit.prop(id, board, Transform3D(Basis(), p + Vector3(0, 1.69, 0)), kit.mat("wallpaper_navy"))
		var edging := BoxMesh.new()
		edging.size = Vector3(1.18, 1.59, 0.055)
		kit.prop(id, edging, Transform3D(Basis(), p + Vector3(0, 1.69, 0.055)), kit.mat("brass"))
		kit.prop(id, board, Transform3D(Basis(), p + Vector3(0, 1.69, 0.09)), kit.mat("wallpaper_navy"))
		kit.label(id, "THE\nMOONLIT\nCOLLECTION", p + Vector3(0, 1.91, 0.135), 0.0, 34, Color(0.95, 0.82, 0.55))
		kit.spot(id, p + Vector3(0, 3.5, 0.9), p + Vector3(0, 1.7, 0), Color(1.0, 0.77, 0.5), 0.8, 3.8, 42.0)
	# A pair of low seats gives the ticket side its own waiting group.
	kit.model(id, "painted_wooden_bench", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(4.8, 0, 21.7)), 0.89)
	kit.model(id, "potted_plant_02", Transform3D(Basis.IDENTITY, Vector3(5.7, 0, 30.6)), 0.73)


static func _sconce(kit: LevelKit, id: String, pos: Vector3, yaw: float) -> void:
	var facing := Basis(Vector3.UP, yaw)
	kit.model(id, "industrial_caged_sconce", Transform3D(facing, pos), 0.43, "none")
	kit.omni(id, pos + facing * Vector3(0, 0, 0.34), Color(1.0, 0.72, 0.43), 0.9, 4.2)


static func _statue(kit: LevelKit, id: String) -> void:
	var p := Vector3(-8.0, 0, 25.0)
	_box(kit, id, Vector3(-9.40, 2.5, 25.0), Vector3(0.06, 4.0, 3.0), kit.mat("wallpaper_navy"))
	for z in [23.47, 26.53]:
		_box(kit, id, Vector3(-9.29, 2.5, z), Vector3(0.13, 4.15, 0.10), kit.mat("gold"))
	_box(kit, id, Vector3(-9.28, 4.62, 25.0), Vector3(0.14, 0.13, 3.2), kit.mat("gold"))
	kit.cylinder_solid(id, p, 0.55, 1.12, kit.mat("marble_black"))
	_cylinder(kit, id, p + Vector3(0, 1.16, 0), 0.6, 0.08, kit.mat("marble_white"))
	kit.model(id, "marble_bust_01", Transform3D(Basis(Vector3.UP, PI * 0.5), p + Vector3(0, 1.21, 0)), 0.96, "none")
	kit.label(id, "THE FOUNDER", Vector3(-9.16, 1.5, 25), PI * 0.5, 25, Color(0.92, 0.78, 0.5))


static func _wall_art(kit: LevelKit, id: String) -> void:
	# The large scanned frame holds a real painted canvas at eye level on the west wall.
	var facing := Basis(Vector3.UP, PI * 0.5)
	var centre := Vector3(-9.32, 2.86, 29.3)
	_box(kit, id, Vector3(-9.51, 2.86, 29.3), Vector3(0.035, 2.35, 3.15), kit.mat("wood_dark"))
	kit.model(id, "fancy_picture_frame_01", Transform3D(facing, centre), 2.18, "none")
	var canvas := QuadMesh.new()
	canvas.size = Vector2(2.27, 1.52)
	var paint := StandardMaterial3D.new()
	paint.albedo_texture = load("res://assets/art/foyer_moonlit_museum.png")
	paint.roughness = 0.88
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	kit.prop(id, canvas, Transform3D(facing, centre + Vector3(0.065, 0, 0)), paint)
	_box(kit, id, Vector3(-8.97, 4.20, 29.3), Vector3(0.13, 0.07, 1.0), kit.mat("brass"))
	_box(kit, id, Vector3(-8.96, 4.15, 29.3), Vector3(0.10, 0.018, 0.85), kit.mat("emissive_warm"))
	kit.spot(id, Vector3(-8.95, 4.12, 29.3), centre, Color(1, 0.74, 0.46), 1.1, 4.2, 51.0)
	# Mirror opposite the bust, away from the east service door at z=28..30.
	kit.model(id, "ornate_mirror_01", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(9.46, 2.8, 23.7)), 1.86, "none")
	_box(kit, id, Vector3(9.02, 4.0, 23.7), Vector3(0.13, 0.07, 0.85), kit.mat("brass"))
	_box(kit, id, Vector3(9.02, 3.95, 23.7), Vector3(0.10, 0.018, 0.7), kit.mat("emissive_warm"))
	kit.spot(id, Vector3(9.0, 3.92, 23.7), Vector3(9.42, 2.8, 23.7), Color(1, 0.74, 0.46), 0.8, 3.8, 50.0)
	kit.model(id, "fancy_picture_frame_02", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(9.46, 2.8, 25.9)), 1.58, "none")


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
