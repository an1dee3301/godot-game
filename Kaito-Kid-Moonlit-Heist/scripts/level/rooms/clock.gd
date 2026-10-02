extends RefCounted
## A moonlit clockwork gallery with staggered cover and a clear approach to the Black Star.

static var _dial_mesh: Mesh
static var _gear_cache: Dictionary = {}


static func dress(kit: LevelKit, room_id: String) -> void:
	var walnut := kit.mat("wood_dark")
	var brass := kit.mat("brass")
	var gold := kit.mat("gold")
	var ivory := kit.mat("ivory")
	var glass := kit.mat("glass")
	var iron := kit.mat("iron")
	var centre := Vector3(-26.0, 3.9, -29.18)

	# The transparent dial uses the north window as its cold backlight.
	var dial := kit.prop(room_id, _dial(), Transform3D(Basis.IDENTITY, centre))
	dial.name = "Astronomical_Dial"
	_ring(kit, room_id, centre + Vector3(0, 0, 0.03), 2.39, 0.075, brass)
	_ring(kit, room_id, centre + Vector3(0, 0, 0.05), 2.22, 0.018, gold)
	var numerals := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for i in 12:
		var angle := float(i) * TAU / 12.0
		var p := centre + Vector3(sin(angle) * 1.80, cos(angle) * 1.80, 0.09)
		kit.label(room_id, numerals[i], p, 0.0, 55, Color(0.96, 0.78, 0.42))
	var hour := kit.prop(room_id, _hand(1.04, 0.105), Transform3D(Basis.IDENTITY, centre + Vector3(0, 0, 0.14)), brass)
	var minute := kit.prop(room_id, _hand(1.50, 0.061), Transform3D(Basis.IDENTITY, centre + Vector3(0, 0, 0.17)), ivory)
	hour.name = "Hour_Hand"
	minute.name = "Minute_Hand"
	hour.rotation.z = -0.77
	minute.rotation.z = 1.0
	_spin(hour, 360.0)
	_spin(minute, 60.0)
	kit.prop(room_id, _sphere(0.13), Transform3D(Basis.IDENTITY, centre + Vector3(0, 0, 0.23)), gold)
	kit.spot(room_id, Vector3(-26.0, 5.95, -27.7), centre, Color(1.0, 0.77, 0.43), 1.6, 6.5, 44.0)

	_gear(kit, room_id, Vector3(-31.15, 3.63, -29.12), 1.38, 20, 92.0, brass)
	_gear(kit, room_id, Vector3(-21.12, 3.16, -29.12), 1.08, 16, -73.0, brass)
	_gear(kit, room_id, Vector3(-19.36, 4.49, -29.12), 0.54, 12, 51.0, gold)
	var pendulum := kit.prop(room_id, _pendulum(), Transform3D(Basis.IDENTITY, Vector3(-26, 2.05, -29.02)), brass)
	pendulum.name = "Pendulum"
	var swing := pendulum.create_tween().set_loops()
	swing.tween_property(pendulum, "rotation:z", 0.19, 1.22).from(-0.19).set_trans(Tween.TRANS_SINE)
	swing.tween_property(pendulum, "rotation:z", -0.19, 1.22).set_trans(Tween.TRANS_SINE)

	# Cases stand at crouch height, offset to make alternating sight-line breaks.
	_watch_case(kit, room_id, Vector3(-29.3, 0, -17.6), 3.25, walnut, brass, glass, ivory)
	_watch_case(kit, room_id, Vector3(-22.2, 0, -21.0), 3.0, walnut, brass, glass, ivory)
	kit.spot(room_id, Vector3(-29.3, 4.4, -17.6), Vector3(-29.3, 1.05, -17.6), Color(1.0, 0.78, 0.5), 1.15, 5.0, 31.0)
	kit.spot(room_id, Vector3(-22.2, 4.4, -21.0), Vector3(-22.2, 1.05, -21.0), Color(1.0, 0.78, 0.5), 1.15, 5.0, 31.0)
	_bookshelf(kit, room_id, -31.2, -9.16, walnut, brass)
	_bookshelf(kit, room_id, -27.4, -9.16, walnut, brass)
	_stair(kit, room_id, Vector3(-35.1, 0, -26.0), iron, brass)
	kit.omni(room_id, Vector3(-30.0, 3.5, -17.3), Color(1.0, 0.71, 0.39), 0.32, 4.2)
	kit.omni(room_id, Vector3(-25.8, 2.8, -25.7), Color(0.73, 0.81, 1.0), 0.30, 4.0)


static func _dial() -> Mesh:
	if _dial_mesh != null:
		return _dial_mesh
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in 512:
		for x in 512:
			var dx := float(x - 256) / 256.0
			var dy := float(y - 256) / 256.0
			var r := sqrt(dx * dx + dy * dy)
			var a := atan2(dx, -dy)
			var tick := absf(wrapf(a + TAU / 120.0, 0.0, TAU / 60.0) - TAU / 120.0)
			var major := absf(wrapf(a + TAU / 24.0, 0.0, TAU / 12.0) - TAU / 24.0)
			var ink := (r > 0.87 and r < 0.89) or (r > 0.965 and r < 0.985)
			ink = ink or (r > 0.76 and r < 0.85 and tick < 0.0035)
			ink = ink or (r > 0.72 and r < 0.86 and major < 0.007)
			var alpha := 0.0
			if ink:
				alpha = 0.92
			elif r < 0.70:
				alpha = 0.13
			if alpha > 0.0:
				image.set_pixel(x, y, Color(0.96, 0.75, 0.38, alpha))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(4.7, 4.7)
	mesh.material = material
	_dial_mesh = mesh
	return mesh


static func _ring(kit: LevelKit, room_id: String, pos: Vector3, radius: float, width: float, material: Material) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - width
	mesh.outer_radius = radius
	mesh.rings = 64
	mesh.ring_segments = 8
	kit.prop(room_id, mesh, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pos), material)


static func _hand(length: float, width: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector2Array([
		Vector2(-width, -0.18), Vector2(width, -0.18),
		Vector2(width * 0.65, length * 0.75), Vector2(0, length),
		Vector2(-width * 0.65, length * 0.75),
	])
	for i in range(1, points.size() - 1):
		for j in [0, i, i + 1]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(Vector3(points[j].x, points[j].y, 0))
	return st.commit()


static func _sphere(radius: float) -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


static func _spin(node: Node3D, seconds: float) -> void:
	var start := node.rotation.z
	var tween := node.create_tween().set_loops()
	var direction := -1.0 if seconds > 0.0 else 1.0
	tween.tween_property(node, "rotation:z", start + direction * TAU, absf(seconds)).from(start)


static func _gear(kit: LevelKit, room_id: String, pos: Vector3, radius: float, teeth: int, seconds: float, material: Material) -> void:
	var key := "%d_%.2f" % [teeth, radius]
	if not _gear_cache.has(key):
		_gear_cache[key] = _gear_mesh(radius, teeth)
	var node := kit.prop(room_id, _gear_cache[key], Transform3D(Basis.IDENTITY, pos), material)
	node.name = "Clockwork_Gear"
	_spin(node, seconds)
	_ring(kit, room_id, pos + Vector3(0, 0, 0.04), radius * 0.26, radius * 0.08, kit.mat("bronze"))
	kit.prop(room_id, _sphere(radius * 0.095), Transform3D(Basis.IDENTITY, pos + Vector3(0, 0, 0.07)), kit.mat("gold"))


static func _gear_mesh(radius: float, teeth: int) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := teeth * 4
	for i in count:
		var a0 := TAU * float(i) / float(count)
		var a1 := TAU * float(i + 1) / float(count)
		var outer0 := radius * (1.0 if i % 4 == 1 or i % 4 == 2 else 0.88)
		var outer1 := radius * (1.0 if (i + 1) % 4 == 1 or (i + 1) % 4 == 2 else 0.88)
		var p0 := Vector3(cos(a0) * outer0, sin(a0) * outer0, 0.0)
		var p1 := Vector3(cos(a1) * outer1, sin(a1) * outer1, 0.0)
		var q0 := Vector3(cos(a0) * radius * 0.69, sin(a0) * radius * 0.69, 0.0)
		var q1 := Vector3(cos(a1) * radius * 0.69, sin(a1) * radius * 0.69, 0.0)
		for p in [q0, p0, p1, q0, p1, q1]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(p)
		if i % maxi(1, int(count / 6)) == 0:
			var h0 := Vector3(cos(a0) * radius * 0.15, sin(a0) * radius * 0.15, 0.0)
			var h1 := Vector3(cos(a1) * radius * 0.15, sin(a1) * radius * 0.15, 0.0)
			for p in [h0, q0, q1, h0, q1, h1]:
				st.set_normal(Vector3.BACK)
				st.add_vertex(p)
	return st.commit()


static func _pendulum() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections := 16
	for i in sections:
		var a := TAU * float(i) / float(sections)
		var b := TAU * float(i + 1) / float(sections)
		for section in 2:
			var y: float = -1.65 if section == 0 else 0.0
			var next_y := -1.40
			var radius: float = 0.23 if section == 0 else 0.025
			var p0 := Vector3(cos(a) * radius, y, sin(a) * radius)
			var p1 := Vector3(cos(b) * radius, y, sin(b) * radius)
			var p2 := Vector3(cos(b) * radius, next_y, sin(b) * radius)
			var p3 := Vector3(cos(a) * radius, next_y, sin(a) * radius)
			for p in [p0, p1, p2, p0, p2, p3]:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


static func _watch_case(
	kit: LevelKit, room_id: String, pos: Vector3, width: float,
	walnut: Material, brass: Material, glass: Material, ivory: Material
) -> void:
	kit.solid(room_id, pos, Vector3(width, 1.15, 1.15), walnut)
	kit.solid(room_id, pos + Vector3(0, 1.15, 0), Vector3(width + 0.1, 0.085, 1.22), brass, 0.0, false)
	kit.solid(room_id, pos + Vector3(0, 1.235, 0), Vector3(width, 0.065, 1.12), ivory, 0.0, false)
	var cover := BoxMesh.new()
	cover.size = Vector3(width - 0.13, 0.37, 1.02)
	kit.prop(room_id, cover, Transform3D(Basis.IDENTITY, pos + Vector3(0, 1.49, 0)), glass)
	for i in 5:
		var x := pos.x + (float(i) - 2.0) * (width - 0.55) / 5.0
		var watch := CylinderMesh.new()
		watch.top_radius = 0.13
		watch.bottom_radius = 0.13
		watch.height = 0.035
		watch.radial_segments = 20
		kit.prop(room_id, watch, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, 1.38, pos.z)), brass)
		kit.prop(room_id, _sphere(0.035), Transform3D(Basis.IDENTITY, Vector3(x, 1.38, pos.z + 0.027)), ivory)
	kit.label(room_id, "HOROLOGY  •  1894", pos + Vector3(0, 0.80, 0.592), 0.0, 31, Color(0.89, 0.72, 0.44))


static func _bookshelf(kit: LevelKit, room_id: String, x: float, z: float, walnut: Material, brass: Material) -> void:
	var width := 3.2
	kit.solid(room_id, Vector3(x, 0, z), Vector3(width, 2.75, 0.66), walnut)
	for y in [0.45, 1.11, 1.77, 2.43]:
		var shelf := BoxMesh.new()
		shelf.size = Vector3(width + 0.08, 0.06, 0.72)
		kit.prop(room_id, shelf, Transform3D(Basis.IDENTITY, Vector3(x, y, z)), brass)
	var book := BoxMesh.new()
	book.size = Vector3(0.095, 0.42, 0.22)
	var transforms: Array = []
	for row in 3:
		for i in 26:
			if i == 8 or i == 19:
				continue
			var bx := x - 1.46 + float(i) * 0.112
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(bx, 0.72 + float(row) * 0.66, z + 0.24)))
	kit.multi(room_id, book, transforms, kit.mat("velvet_red"))
	kit.label(room_id, "THE ART OF TIME", Vector3(x, 2.94, z + 0.38), 0.0, 36, Color(0.88, 0.70, 0.39))


static func _stair(kit: LevelKit, room_id: String, base: Vector3, iron: Material, brass: Material) -> void:
	kit.cylinder_solid(room_id, base, 0.18, 4.4, iron, 12)
	var step := BoxMesh.new()
	step.size = Vector3(1.35, 0.085, 0.40)
	var steps: Array = []
	for i in 15:
		var a := float(i) * 0.45
		var y := 0.24 + float(i) * 0.23
		steps.append(Transform3D(Basis(Vector3.UP, -a), base + Vector3(cos(a) * 0.66, y, sin(a) * 0.66)))
	kit.multi(room_id, step, steps, iron)
	var rail := TorusMesh.new()
	rail.inner_radius = 1.17
	rail.outer_radius = 1.20
	rail.rings = 48
	rail.ring_segments = 6
	kit.prop(room_id, rail, Transform3D(Basis.IDENTITY, base + Vector3(0, 3.82, 0)), brass)
