extends RefCounted
## The steel treasury: open radial portal, deposit bank and a guarded exhibit.

static var _meshes: Dictionary = {}


static func dress(kit: LevelKit, room_id: String) -> void:
	var iron := kit.mat("iron")
	var brass := kit.mat("brass")
	var gold := kit.mat("gold")
	var red := kit.mat("velvet_red")
	var marble := kit.pbr("marble_01", 2.4, Color(0.29, 0.30, 0.34), 0.36)
	# A lighter polished field lets the existing black-marble perimeter remain a border.
	_box(kit, room_id, Vector3(26, 0.018, -19), Vector3(21.8, 0.014, 19.8), marble)
	for x in [16.1, 35.9]:
		_box(kit, room_id, Vector3(x, 0.031, -19), Vector3(0.07, 0.012, 19.0), brass)
	for z in [-28.4, -9.6]:
		_box(kit, room_id, Vector3(26, 0.031, z), Vector3(19.8, 0.012, 0.07), brass)
	# Steel coffers and a few valuable objects provide scale without occupying the patrol loop.
	kit.model(room_id, "GothicCabinet_01", Transform3D(Basis.IDENTITY, Vector3(18.0, 0, -28.85)), 2.65)
	kit.model(room_id, "vintage_cabinet_01", Transform3D(Basis.IDENTITY, Vector3(34.5, 0, -28.9)), 2.45)
	kit.model(room_id, "steel_frame_shelves_01", Transform3D(Basis.IDENTITY, Vector3(35.8, 0, -16.0)), 2.25)
	# Deposit bank is one composed wall. The drawer fronts are batched.
	_box(kit, room_id, Vector3(26, 3.0, -8.65), Vector3(19.4, 4.8, 0.15), iron)
	var fronts: Array[Transform3D] = []
	var pulls: Array[Transform3D] = []
	for row in 5:
		for col in 19:
			var p := Vector3(17.0 + float(col) * 0.99, 1.0 + float(row) * 0.77, -8.79)
			fronts.append(Transform3D(Basis.IDENTITY, p))
			pulls.append(Transform3D(Basis.IDENTITY, p + Vector3(0, 0, -0.05)))
	kit.multi(room_id, _box_mesh(Vector3(0.9, 0.61, 0.07)), fronts, brass)
	kit.multi(room_id, _box_mesh(Vector3(0.24, 0.035, 0.045)), pulls, iron)
	_box(kit, room_id, Vector3(26, 5.48, -8.74), Vector3(19.8, 0.08, 0.22), gold)
	kit.label(room_id, "THE PANDORA RESERVE", Vector3(25.5, 5.88, -8.93), 0.0, 32)

	# The portal occupies the east wall; the leaf swings into the edge of the
	# room while leaving the x=34 guard route and the Moonstone accessible.
	var wall_basis := Basis(Vector3.FORWARD, PI * 0.5)
	_ring(kit, room_id, Vector3(37.31, 3.05, -16.25), 2.16, 0.22, wall_basis, iron)
	_ring(kit, room_id, Vector3(37.22, 3.05, -16.25), 1.82, 0.06, wall_basis, brass)
	var leaf_basis := Basis(Vector3.UP, deg_to_rad(49.0)) * wall_basis
	var leaf_pos := Vector3(36.55, 3.05, -15.0)
	kit.solid(room_id, Vector3(36.5, 0, -15.0), Vector3(0.62, 3.45, 1.85), iron)
	kit.prop(room_id, _cylinder(1.69, 0.23, 48), Transform3D(leaf_basis, leaf_pos), iron)
	_ring(kit, room_id, leaf_pos - Vector3(0.12, 0, 0), 1.37, 0.055, leaf_basis, brass)
	var spokes: Array[Transform3D] = []
	for i in 8:
		spokes.append(Transform3D(leaf_basis * Basis(Vector3.UP, float(i) * TAU / 8.0), leaf_pos))
	kit.multi(room_id, _box_mesh(Vector3(2.65, 0.055, 0.055)), spokes, brass)
	kit.prop(room_id, _cylinder(0.29, 0.18, 24), Transform3D(leaf_basis, leaf_pos - Vector3(0.2, 0, 0)), gold)

	# Three low cases make alternating occlusion pockets. They stay off the
	# patrol polyline and clear of the entrance, window, and jewel plinth.
	_case(kit, room_id, Vector3(20.1, 0, -17), 3.2, 1.45)
	_case(kit, room_id, Vector3(20.7, 0, -24.7), 2.9, 1.4)
	_case(kit, room_id, Vector3(33.0, 0, -26.8), 2.2, 1.3)
	# The lid reads open from the main aisle; loose gold is contained on the case.
	kit.model(room_id, "treasure_chest", Transform3D(Basis(Vector3.UP, deg_to_rad(22.0)), Vector3(20.1, 1.31, -17.0)), 0.74, "none")
	_box(kit, room_id, Vector3(20.1, 1.70, -17.28), Vector3(0.92, 0.055, 0.48), kit.mat("wood_dark"))
	for i in 11:
		var a := float(i) * 2.39996
		var p := Vector3(20.1 + cos(a) * 0.32, 1.39 + float(i % 3) * 0.035, -16.92 + sin(a) * 0.18)
		kit.prop(room_id, _sphere(0.065), Transform3D(Basis.IDENTITY, p), gold)
	kit.model(room_id, "metal_tool_chest", Transform3D(Basis.IDENTITY, Vector3(20.7, 1.33, -24.7)), 0.52, "none")
	kit.model(room_id, "brass_vase_01", Transform3D(Basis.IDENTITY, Vector3(33.0, 1.33, -26.8)), 0.62, "none")

	# Engraved pressure plates are flush with the floor; they are a warning
	# motif, rather than extra obstacles in the navigation mesh.
	var horizontal: Array[Transform3D] = []
	var vertical: Array[Transform3D] = []
	for ix in 9:
		for iz in 5:
			var x := 16.9 + float(ix) * 2.15
			var z := -27.5 + float(iz) * 3.8
			if Vector2(x - 28.0, z + 25.0).length() < 2.8:
				continue
			horizontal.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.025, z - 0.74)))
			horizontal.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.025, z + 0.74)))
			vertical.append(Transform3D(Basis.IDENTITY, Vector3(x - 0.78, 0.025, z)))
			vertical.append(Transform3D(Basis.IDENTITY, Vector3(x + 0.78, 0.025, z)))
	kit.multi(room_id, _box_mesh(Vector3(1.54, 0.012, 0.022)), horizontal, brass)
	kit.multi(room_id, _box_mesh(Vector3(0.022, 0.012, 1.48)), vertical, brass)

	# The jewel object supplies the central plinth; rope posts sit beyond its
	# interaction radius and the ring pulls the eye into the cold light pool.
	_ring(kit, room_id, Vector3(28, 0.04, -25), 2.0, 0.025, Basis.IDENTITY, gold)
	for i in 4:
		var a := float(i) * TAU / 4.0 + PI * 0.25
		var b := a + TAU / 4.0
		var post := Vector3(28 + cos(a) * 2.0, 0, -25 + sin(a) * 2.0)
		var next := Vector3(28 + cos(b) * 2.0, 0, -25 + sin(b) * 2.0)
		kit.cylinder_solid(room_id, post, 0.07, 0.7, brass, 12)
		kit.prop(room_id, _sphere(0.105), Transform3D(Basis.IDENTITY, post + Vector3(0, 0.72, 0)), gold)
		if i != 0: # An open north arc keeps the diagonal guard route clear.
			_segment(kit, room_id, post + Vector3(0, 0.57, 0), (post + next) * 0.5 + Vector3(0, 0.45, 0), red)
			_segment(kit, room_id, (post + next) * 0.5 + Vector3(0, 0.45, 0), next + Vector3(0, 0.57, 0), red)
	# One shadowed beam is reserved for the jewel. Every warm pool has a physical fixture.
	kit.model(room_id, "hanging_industrial_lamp", Transform3D(Basis.IDENTITY, Vector3(28, 4.95, -25)), 1.10, "none")
	kit.spot(room_id, Vector3(28, 5.22, -25), Vector3(28, 0.9, -25), Color(0.69, 0.84, 1.0), 5.0, 7.2, 34.0, true)
	for p in [Vector3(20.1, 5.0, -17.0), Vector3(32.9, 5.0, -26.8)]:
		kit.model(room_id, "hanging_industrial_lamp", Transform3D(Basis.IDENTITY, p), 0.95, "none")
		kit.omni(room_id, p + Vector3(0, -0.55, 0), Color(1.0, 0.72, 0.43), 1.8, 6.2)
	for p in [Vector3(18.4, 3.4, -8.66), Vector3(33.5, 3.4, -8.66), Vector3(37.55, 3.4, -25.8)]:
		var yaw := PI if p.z > -9.0 else -PI * 0.5
		kit.model(room_id, "industrial_caged_sconce", Transform3D(Basis(Vector3.UP, yaw), p), 0.43, "none")
		kit.omni(room_id, p + Vector3(0, 0.15, -0.28 if p.z > -9.0 else 0), Color(1.0, 0.70, 0.40), 1.15, 4.8)
	kit.omni(room_id, Vector3(26, 3.8, -18), Color(0.60, 0.75, 1.0), 0.42, 11.0)
	var security_red := StandardMaterial3D.new()
	security_red.albedo_color = Color(0.8, 0.07, 0.09)
	security_red.emission_enabled = true
	security_red.emission = Color(0.9, 0.015, 0.025)
	security_red.emission_energy_multiplier = 2.3
	var strips: Array[Transform3D] = []
	for x in [17.0, 23.0, 29.0, 35.0]:
		strips.append(Transform3D(Basis.IDENTITY, Vector3(x, 5.55, -8.86)))
	kit.multi(room_id, _box_mesh(Vector3(3.2, 0.045, 0.035)), strips, security_red)
	for z in [-27.0, -21.0, -12.5]:
		_box(kit, room_id, Vector3(37.55, 5.55, z), Vector3(0.035, 0.045, 2.6), security_red)
	kit.label(room_id, "SECURE COLLECTION  /  05", Vector3(28, 3.65, -29.53), 0.0, 25, Color(0.73, 0.83, 0.9))


static func _case(kit: LevelKit, room_id: String, pos: Vector3, width: float, depth: float) -> void:
	kit.solid(room_id, pos, Vector3(width, 1.12, depth), kit.mat("iron"))
	_box(kit, room_id, pos + Vector3(0, 1.16, 0), Vector3(width + 0.08, 0.08, depth + 0.08), kit.mat("brass"))
	_box(kit, room_id, pos + Vector3(0, 1.26, 0), Vector3(width - 0.16, 0.10, depth - 0.16), kit.mat("glass"))


static func _box(kit: LevelKit, room_id: String, centre: Vector3, size: Vector3, material: Material) -> void:
	kit.prop(room_id, _box_mesh(size), Transform3D(Basis.IDENTITY, centre), material)


static func _box_mesh(size: Vector3) -> BoxMesh:
	var key := "b_%s" % str(size)
	if not _meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_meshes[key] = mesh
	return _meshes[key] as BoxMesh


static func _cylinder(radius: float, height: float, segments: int) -> CylinderMesh:
	var key := "c_%s_%s" % [str(radius), str(height)]
	if not _meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = segments
		_meshes[key] = mesh
	return _meshes[key] as CylinderMesh


static func _sphere(radius: float) -> SphereMesh:
	var key := "s_%s" % str(radius)
	if not _meshes.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		_meshes[key] = mesh
	return _meshes[key] as SphereMesh


static func _ring(kit: LevelKit, room_id: String, pos: Vector3, radius: float, tube: float, basis: Basis, material: Material) -> void:
	var key := "t_%s_%s" % [str(radius), str(tube)]
	if not _meshes.has(key):
		var mesh := TorusMesh.new()
		mesh.inner_radius = radius - tube
		mesh.outer_radius = radius + tube
		mesh.ring_segments = 48
		mesh.rings = 8
		_meshes[key] = mesh
	kit.prop(room_id, _meshes[key] as Mesh, Transform3D(basis, pos), material)


static func _segment(kit: LevelKit, room_id: String, a: Vector3, b: Vector3, material: Material) -> void:
	var direction := b - a
	kit.prop(room_id, _cylinder(0.026, direction.length(), 8), Transform3D(Basis(Quaternion(Vector3.UP, direction.normalized())), (a + b) * 0.5), material)
