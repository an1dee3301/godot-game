extends RefCounted
## A moonlit clockwork gallery with staggered cover and a clear approach to the Black Star.

static var _dial_mesh: Mesh
static var _gear_cache: Dictionary = {}


static func dress(kit: LevelKit, room_id: String) -> void:
	var brass := kit.mat("brass")
	var gold := kit.mat("gold")
	var ivory := kit.mat("ivory")
	var centre := Vector3(-26.0, 3.9, -29.18)

	# The north window is the luminous backdrop for the working astronomical clock.
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
	_picture_light(kit, room_id, Vector3(-26, 5.9, -28.82), centre, 1.55)

	_gear(kit, room_id, Vector3(-31.15, 3.63, -29.12), 1.38, 20, 92.0, brass)
	_gear(kit, room_id, Vector3(-21.12, 3.16, -29.12), 1.08, 16, -73.0, brass)
	_gear(kit, room_id, Vector3(-19.36, 4.49, -29.12), 0.54, 12, 51.0, gold)
	var pendulum := kit.prop(room_id, _pendulum(), Transform3D(Basis.IDENTITY, Vector3(-26, 2.05, -29.02)), brass)
	pendulum.name = "Pendulum"
	var swing := pendulum.create_tween().set_loops()
	swing.tween_property(pendulum, "rotation:z", 0.19, 1.22).from(-0.19).set_trans(Tween.TRANS_SINE)
	swing.tween_property(pendulum, "rotation:z", -0.19, 1.22).set_trans(Tween.TRANS_SINE)

	# Antique clock ranks give the perimeter its library rhythm. The west service
	# door, east arch, south vent, guard route and Black Star remain clear.
	for z in [-26.5, -24.1, -21.6]:
		kit.model(room_id, "vintage_grandfather_clock_01", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-36.45, 0, z)), 2.2)
	for z in [-26.5, -24.1, -15.3]:
		kit.model(room_id, "vintage_grandfather_clock_01", Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-15.55, 0, z)), 2.2)

	# The south wall becomes a collected horology library rather than bare shelving.
	kit.model(room_id, "GothicCabinet_01", Transform3D(Basis.IDENTITY, Vector3(-35.9, 0, -8.78)), 2.81)
	var book_positions: Array = []
	for x in [-32.9, -31.25, -29.6, -27.95]:
		kit.model(room_id, "wooden_bookshelf_worn", Transform3D(Basis.IDENTITY, Vector3(x, 0, -8.64)), 2.06)
		for row in 3:
			for col in 20:
				var bx: float = float(x) - 0.51 + float(col) * 0.053
				book_positions.append(Transform3D(Basis(Vector3.UP, float((col + row) % 3 - 1) * 0.035), Vector3(bx, 0.41 + float(row) * 0.51, -8.94)))
	_books_multimesh(kit, room_id, book_positions)
	kit.label(room_id, "THE ART OF TIME", Vector3(-30.4, 2.82, -8.54), PI, 34, Color(0.88, 0.73, 0.48))

	# Two real cases and a low watch vitrine compose the middle ground.
	kit.model(room_id, "wooden_display_shelves_01", Transform3D(Basis.IDENTITY, Vector3(-30.0, 0, -18.1)), 1.56)
	kit.model(room_id, "vintage_cabinet_01", Transform3D(Basis(Vector3.UP, PI), Vector3(-19.3, 0, -27.4)), 2.58)
	kit.model(room_id, "mantel_clock_01", Transform3D(Basis.IDENTITY, Vector3(-30.0, 1.19, -18.1)), 0.31, "none")
	kit.model(room_id, "seadogs_compass", Transform3D(Basis.IDENTITY, Vector3(-30.0, 0.74, -18.1)), 0.035, "none")
	kit.model(room_id, "mantel_clock_01", Transform3D(Basis.IDENTITY, Vector3(-19.3, 1.52, -27.03)), 0.31, "none")
	kit.model(room_id, "seadogs_compass", Transform3D(Basis.IDENTITY, Vector3(-19.3, 0.91, -27.03)), 0.035, "none")
	_watch_case(kit, room_id, Vector3(-25.5, 0, -18.0), 2.65, kit.mat("wood_dark"), brass, kit.mat("glass"), ivory)

	# A place to pause and read sits beyond the patrol turn; the chess table is
	# deliberately separated from the jewel pedestal at (-26, -25).
	kit.model(room_id, "ArmChair_01", Transform3D(Basis(Vector3.UP, -0.58), Vector3(-33.9, 0, -26.35)), 1.07)
	kit.model(room_id, "ArmChair_01", Transform3D(Basis(Vector3.UP, 2.5), Vector3(-20.5, 0, -16.8)), 1.07)
	kit.model(room_id, "Ottoman_01", Transform3D(Basis.IDENTITY, Vector3(-32.7, 0, -26.1)), 0.46)
	kit.model(room_id, "ClassicConsole_01", Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-20.6, 0, -14.8)), 0.84)
	kit.model(room_id, "chess_set", Transform3D(Basis.IDENTITY, Vector3(-20.6, 0.86, -14.8)), 0.10, "none")
	kit.model(room_id, "brass_candleholders", Transform3D(Basis.IDENTITY, Vector3(-32.7, 0, -27.25)), 0.8, "none")
	# Textile islands temper the parquet without adding collision to patrol paths.
	_box_prop(kit, room_id, Vector3(-26.0, 0.018, -20.6), Vector3(9.0, 0.022, 3.0), kit.mat("carpet_red"))
	_box_prop(kit, room_id, Vector3(-33.0, 0.019, -26.0), Vector3(4.3, 0.022, 3.1), kit.mat("carpet_blue"))

	# Lit archival canvases at eye level; each has its own generated image in the frame.
	_framed_art(kit, room_id, Vector3(-23.0, 2.72, -8.53), PI, 1.35, 0)
	_framed_art(kit, room_id, Vector3(-18.4, 2.72, -8.53), PI, 1.35, 1)
	_framed_art(kit, room_id, Vector3(-36.53, 2.9, -14.0), PI * 0.5, 1.3, 2)

	# Visible 2700 K fixtures make three warm islands; only the central light casts shadows.
	_chandelier(kit, room_id, Vector3(-26.0, 4.95, -17.4), true)
	_chandelier(kit, room_id, Vector3(-26.0, 4.95, -24.7), false)
	kit.omni(room_id, Vector3(-33.05, 2.1, -27.05), Color(1.0, 0.69, 0.37), 0.6, 4.1)
	# The dial's window casts a cool lane across the north of the room.
	kit.spot(room_id, Vector3(-26.0, 5.25, -29.27), Vector3(-25.5, 0.3, -23.7), Color(0.56, 0.72, 1.0), 1.25, 8.0, 37.0)
	kit.omni(room_id, Vector3(-25.6, 3.0, -21.4), Color(0.75, 0.82, 1.0), 0.24, 5.5)


static func _box_prop(kit: LevelKit, room_id: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	kit.prop(room_id, mesh, Transform3D(Basis.IDENTITY, pos), material)


static func _books_multimesh(kit: LevelKit, room_id: String, positions: Array) -> void:
	var scene := load("res://assets/polyhaven/models/book_encyclopedia_set_01/book_encyclopedia_set_01.gltf") as PackedScene
	if scene == null:
		return
	var instance := scene.instantiate()
	var meshes := instance.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		instance.free()
		return
	# One scanned volume per instance; keep its native embedded PBR surfaces.
	var book_mesh := (meshes[0] as MeshInstance3D).mesh
	kit.multi(room_id, book_mesh, positions)
	instance.free()


static func _chandelier(kit: LevelKit, room_id: String, pos: Vector3, shadows: bool) -> void:
	kit.model(room_id, "Chandelier_01", Transform3D(Basis.IDENTITY, pos), 1.25, "none")
	# Model height is deliberately explicit: this scan is authored in centimetres.
	kit.omni(room_id, pos + Vector3(0, 0.13, 0), Color(1.0, 0.72, 0.43), 1.45, 6.4, shadows)
	kit.spot(room_id, pos + Vector3(0, -0.25, 0), pos + Vector3(0, -4.5, 0), Color(1.0, 0.72, 0.43), 0.65, 5.8, 55.0)


static func _picture_light(kit: LevelKit, room_id: String, pos: Vector3, target: Vector3, width: float) -> void:
	_box_prop(kit, room_id, pos, Vector3(width, 0.07, 0.13), kit.mat("brass"))
	_box_prop(kit, room_id, pos + Vector3(0, -0.055, 0.06), Vector3(width - 0.15, 0.025, 0.05), kit.mat("emissive_warm"))
	kit.spot(room_id, pos + Vector3(0, -0.05, 0.22), target, Color(1.0, 0.73, 0.44), 0.82, 4.2, 48.0)


static func _framed_art(kit: LevelKit, room_id: String, centre: Vector3, yaw: float, height: float, subject: int) -> void:
	var facing := Basis(Vector3.UP, yaw)
	var width := height * 0.78
	var quad := QuadMesh.new()
	quad.size = Vector2(width * 0.76, height * 0.77)
	var face_pos := centre + facing * Vector3(0, 0, 0.07)
	kit.prop(room_id, quad, Transform3D(facing, face_pos), _art_material(subject))
	kit.model(room_id, "fancy_picture_frame_02", Transform3D(facing, centre - Vector3(0, height * 0.5, 0)), height, "none")
	var lamp_pos := centre + facing * Vector3(0, height * 0.58, 0.28)
	var lamp_target := centre + facing * Vector3(0, 0, 0.12)
	var bar := BoxMesh.new()
	bar.size = Vector3(width * 0.64, 0.065, 0.11)
	kit.prop(room_id, bar, Transform3D(facing, lamp_pos), kit.mat("brass"))
	kit.spot(room_id, lamp_pos + facing * Vector3(0, -0.04, 0.06), lamp_target, Color(1.0, 0.72, 0.41), 0.55, 2.6, 44.0)


static var _art_cache: Dictionary = {}
static func _art_material(subject: int) -> Material:
	if _art_cache.has(subject):
		return _art_cache[subject]
	var image := Image.create(192, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 192:
			var u := float(x) / 191.0
			var v := float(y) / 255.0
			var grain := sin(float(x * 23 + y * 41)) * sin(float(x * 7 - y * 17)) * 0.025
			var color := Color(0.055, 0.085, 0.12).lerp(Color(0.46, 0.30, 0.18), v * 0.72)
			if subject == 0:
				# An antique astronomical plate: indigo field, orbit and gilt moon.
				color = Color(0.025, 0.075, 0.12).lerp(Color(0.13, 0.2, 0.22), v)
				var r := Vector2((u - 0.5) * 1.35, (v - 0.5)).length()
				if absf(r - 0.36) < 0.009 or absf(r - 0.26) < 0.006:
					color = Color(0.73, 0.57, 0.3)
				if Vector2(u - 0.57, v - 0.42).length() < 0.09:
					color = Color(0.88, 0.77, 0.48)
			elif subject == 1:
				# A storm study: distant tower under a bright break in cloud.
				color = Color(0.075, 0.09, 0.13).lerp(Color(0.38, 0.41, 0.42), v * 0.85)
				var tower := absf(u - 0.51) < 0.11 and v > 0.28 and v < 0.81
				if tower or (absf(u - 0.51) < 0.17 and v > 0.81):
					color = Color(0.08, 0.09, 0.1)
				if absf(u - 0.51) < 0.025 and v > 0.36 and v < 0.42:
					color = Color(0.9, 0.68, 0.31)
			else:
				# A warm archival portrait silhouette within a dark oval.
				color = Color(0.22, 0.08, 0.055).lerp(Color(0.52, 0.3, 0.16), 1.0 - v)
				var oval := pow((u - 0.5) / 0.42, 2.0) + pow((v - 0.5) / 0.47, 2.0)
				if oval < 1.0:
					color = Color(0.36, 0.24, 0.15)
				if Vector2((u - 0.5) * 1.3, v - 0.39).length() < 0.13 or (absf(u - 0.5) < 0.18 and v > 0.52 and v < 0.78):
					color = Color(0.085, 0.065, 0.06)
			image.set_pixel(x, y, color.lightened(grain) if grain > 0.0 else color.darkened(-grain))
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_art_cache[subject] = material
	return material


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
