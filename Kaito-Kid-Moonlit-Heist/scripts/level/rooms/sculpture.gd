extends RefCounted
## Navy sculpture hall: a moonlit court of classical marble, with a readable jewel dais and cover.

static var _bust_torso: ArrayMesh
static var _plinth_profile: ArrayMesh
static var _plinth_ring: ArrayMesh
static var _reclining_limb: ArrayMesh


static func dress(kit: LevelKit, room_id: String) -> void:
	var marble := kit.mat("marble_white")
	var dark := kit.mat("marble_black")
	var gold := kit.mat("gold")
	var stone := kit.mat("stone")
	var velvet := kit.mat("velvet_blue")
	# The guard walks the perimeter: x=-34/-18 and z=-4/16. The displays sit
	# inside that loop, leaving the three full-height entries and north vent free.
	for x in [-31.0, -21.0]:
		for z in [3.0, 11.0]:
			_make_plinth(kit, room_id, Vector3(x, 0, z), marble, gold)
			_make_bust(kit, room_id, Vector3(x, 1.22, z), marble, stone, x < -26.0)
	# Jewel plinth is placed by MuseumLevel. Low tiered stonework frames it
	# without hiding the case or narrowing the path from the eastern arch.
	kit.solid(room_id, Vector3(-26, 0, 6), Vector3(3.4, 0.20, 3.4), dark, 0.0, false)
	kit.solid(room_id, Vector3(-26, 0, 3.97), Vector3(3.0, 0.10, 0.53), marble, 0.0, false)
	kit.solid(room_id, Vector3(-26, 0, 8.03), Vector3(3.0, 0.10, 0.53), marble, 0.0, false)
	kit.solid(room_id, Vector3(-28.03, 0, 6), Vector3(0.53, 0.10, 3.0), marble, 0.0, false)
	kit.solid(room_id, Vector3(-23.97, 0, 6), Vector3(0.53, 0.10, 3.0), marble, 0.0, false)
	# A narrow gold seam sets the jewel apart from the pale figures.
	for x in [-27.76, -24.24]:
		kit.solid(room_id, Vector3(x, 0.205, 6), Vector3(0.035, 0.018, 3.5), gold, 0.0, false)
	for z in [4.24, 7.76]:
		kit.solid(room_id, Vector3(-26, 0.205, z), Vector3(3.5, 0.018, 0.035), gold, 0.0, false)
	# Landmark seen across the jewel from the atrium: a reclining marble figure
	# on a single broad sarcophagus, with a curved body and limbs rather than boxes.
	_make_reclining(kit, room_id, Vector3(-26, 0, -0.6), marble, dark, gold)
	# Two benches are useful, low sight-line breaks. Their open ends let the
	# player move between the statue, the jewel and the southern doorway.
	_make_bench(kit, room_id, Vector3(-26, 0, 13.5), marble, velvet, gold)
	_make_bench(kit, room_id, Vector3(-26, 0, -6.2), marble, velvet, gold)
	# The vent at x=-20.4 on the north wall stays open. A nearby sculpture
	# makes it less obvious on entry without impeding a crouched approach.
	kit.cylinder_solid(room_id, Vector3(-23.4, 0, -5.5), 0.62, 1.08, dark, 24)
	var vent_profile: Array[Vector2] = [
		Vector2(0.32, 0), Vector2(0.44, 0.12), Vector2(0.34, 0.26),
		Vector2(0.17, 0.46), Vector2(0.14, 0.70), Vector2(0.24, 0.86), Vector2(0.0, 0.91),
	]
	kit.prop(room_id, _lathe(vent_profile, 20),
		Transform3D(Basis.IDENTITY, Vector3(-23.4, 1.08, -5.5)), marble)
	# Cool spill from the north window and restrained amber museum spots.
	kit.spot(room_id, Vector3(-26, 5.9, -8.0), Vector3(-26, 1.3, -1.0), Color(0.53, 0.69, 1.0), 1.45, 12.0, 49.0)
	kit.spot(room_id, Vector3(-25.0, 5.9, 8.0), Vector3(-26, 1.0, 6.0), Color(1.0, 0.73, 0.43), 1.5, 8.0, 38.0, true)
	kit.spot(room_id, Vector3(-33.1, 5.7, 5.0), Vector3(-31.0, 1.9, 7.0), Color(1.0, 0.82, 0.57), 0.8, 8.0, 48.0)
	kit.spot(room_id, Vector3(-19.2, 5.7, 6.0), Vector3(-21.0, 1.9, 7.0), Color(1.0, 0.82, 0.57), 0.8, 8.0, 48.0)
	kit.label(room_id, "THE SCARLET LADY", Vector3(-26, 0.39, 8.67), 0.0, 30, Color(0.77, 0.61, 0.36))


static func _make_plinth(kit: LevelKit, id: String, p: Vector3, marble: Material, gold: Material) -> void:
	kit.cylinder_solid(id, p, 0.65, 1.17, marble, 32)
	if _plinth_profile == null:
		var profile: Array[Vector2] = [
			Vector2(0.0, 0), Vector2(0.83, 0), Vector2(0.87, 0.10),
			Vector2(0.73, 0.18), Vector2(0.65, 0.93), Vector2(0.75, 1.06),
			Vector2(0.86, 1.13), Vector2(0.86, 1.20), Vector2(0.0, 1.20),
		]
		_plinth_profile = _lathe(profile, 32)
		_plinth_ring = _ring(0.76, 0.79, 0.035, 32)
	kit.prop(id, _plinth_profile, Transform3D(Basis.IDENTITY, p), marble)
	kit.prop(id, _plinth_ring, Transform3D(Basis.IDENTITY, p + Vector3(0, 1.08, 0)), gold)


static func _make_bust(kit: LevelKit, id: String, p: Vector3, marble: Material, stone: Material, turned: bool) -> void:
	if _bust_torso == null:
		var profile: Array[Vector2] = [
			Vector2(0.0, 0), Vector2(0.52, 0), Vector2(0.65, 0.12),
			Vector2(0.61, 0.29), Vector2(0.32, 0.57), Vector2(0.19, 0.77),
			Vector2(0.17, 0.92), Vector2(0.0, 0.92),
		]
		_bust_torso = _lathe(profile, 24)
	var basis := Basis(Vector3.UP, PI if turned else 0.0)
	kit.prop(id, _bust_torso, Transform3D(basis, p), marble)
	var head := SphereMesh.new()
	head.radius = 0.28
	head.height = 0.56
	kit.prop(id, head, Transform3D(basis.scaled(Vector3(0.89, 1.15, 0.80)), p + Vector3(0, 1.13, 0)), marble)
	# Low swept hair cap and a projecting nose give the silhouette a face.
	var hair := SphereMesh.new()
	hair.radius = 0.30
	hair.height = 0.38
	kit.prop(id, hair, Transform3D(basis.scaled(Vector3(1.0, 0.65, 0.88)), p + Vector3(0, 1.32, 0)), stone)
	var nose := SphereMesh.new()
	nose.radius = 0.075
	nose.height = 0.17
	kit.prop(id, nose, Transform3D(basis, p + Vector3(0, 1.10, -0.24 if not turned else 0.24)), marble)


static func _make_reclining(kit: LevelKit, id: String, p: Vector3, marble: Material, dark: Material, gold: Material) -> void:
	kit.solid(id, p, Vector3(5.4, 0.93, 1.9), dark)
	kit.solid(id, p + Vector3(0, 0.93, 0), Vector3(5.57, 0.13, 2.04), marble, 0.0, false)
	kit.solid(id, p + Vector3(0, 0.82, 0), Vector3(5.5, 0.035, 1.98), gold, 0.0, false)
	var torso := CapsuleMesh.new()
	torso.radius = 0.47
	torso.height = 2.30
	kit.prop(id, torso, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), p + Vector3(-0.25, 1.55, 0)), marble)
	var head := SphereMesh.new()
	head.radius = 0.39
	head.height = 0.78
	kit.prop(id, head, Transform3D(Basis.IDENTITY, p + Vector3(-1.65, 1.67, 0.05)), marble)
	var hair := SphereMesh.new()
	hair.radius = 0.40
	hair.height = 0.38
	kit.prop(id, hair, Transform3D(Basis.IDENTITY, p + Vector3(-1.72, 1.92, 0.08)), dark)
	var limb := _limb()
	# Bent legs and an arm supporting the head make the horizontal silhouette legible.
	kit.prop(id, limb, Transform3D(Basis(Vector3.FORWARD, -PI * 0.5),
		p + Vector3(0.55, 1.35, -0.25)), marble)
	kit.prop(id, limb, Transform3D(Basis(Vector3.FORWARD, -PI * 0.5),
		p + Vector3(0.55, 1.28, 0.33)), marble)
	kit.prop(id, limb, Transform3D(Basis(Vector3.FORWARD, PI * 0.5).scaled(Vector3(0.55, 0.68, 0.65)),
		p + Vector3(-1.15, 1.66, -0.45)), marble)


static func _make_bench(kit: LevelKit, id: String, p: Vector3, marble: Material, velvet: Material, gold: Material) -> void:
	kit.solid(id, p, Vector3(2.25, 0.45, 0.72), marble, 0.0, false)
	kit.solid(id, p + Vector3(0, 0.45, 0), Vector3(2.13, 0.07, 0.62), velvet, 0.0, false)
	for x in [-0.94, 0.94]:
		kit.solid(id, p + Vector3(x, 0.35, 0), Vector3(0.055, 0.035, 0.74), gold, 0.0, false)


static func _limb() -> ArrayMesh:
	if _reclining_limb == null:
		var profile: Array[Vector2] = [
			Vector2(0.0, 0), Vector2(0.22, 0.04), Vector2(0.27, 0.32),
			Vector2(0.21, 0.78), Vector2(0.26, 1.14), Vector2(0.14, 1.57), Vector2(0.0, 1.68),
		]
		_reclining_limb = _lathe(profile, 16)
	return _reclining_limb


static func _ring(inner: float, outer: float, height: float, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a := TAU * float(i) / float(segments)
		var b := TAU * float(i + 1) / float(segments)
		var p0 := Vector3(cos(a) * inner, 0, sin(a) * inner)
		var p1 := Vector3(cos(a) * outer, 0, sin(a) * outer)
		var p2 := Vector3(cos(b) * outer, height, sin(b) * outer)
		var p3 := Vector3(cos(b) * inner, height, sin(b) * inner)
		_tri(st, p0, p2, p1)
		_tri(st, p0, p3, p2)
	st.generate_normals()
	return st.commit()


static func _lathe(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in profile.size() - 1:
		for i in segments:
			var a := TAU * float(i) / float(segments)
			var b := TAU * float(i + 1) / float(segments)
			var p0 := Vector3(cos(a) * profile[j].x, profile[j].y, sin(a) * profile[j].x)
			var p1 := Vector3(cos(b) * profile[j].x, profile[j].y, sin(b) * profile[j].x)
			var p2 := Vector3(cos(b) * profile[j + 1].x, profile[j + 1].y, sin(b) * profile[j + 1].x)
			var p3 := Vector3(cos(a) * profile[j + 1].x, profile[j + 1].y, sin(a) * profile[j + 1].x)
			_tri(st, p0, p2, p1)
			_tri(st, p0, p3, p2)
	st.generate_normals()
	return st.commit()


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
