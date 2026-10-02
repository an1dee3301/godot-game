extends RefCounted
## Egyptology exhibition. The diagonal patrol at z=23..25 remains clear.

static var _box: BoxMesh
static var _sphere: SphereMesh
static var _obelisk: ArrayMesh
static var _coffin: ArrayMesh
static var _glyph_material: StandardMaterial3D


static func dress(kit: LevelKit, room_id: String) -> void:
	var sand := kit.mat("sandstone")
	var gold := kit.mat("gold")
	var lapis := kit.mat("lapis")
	var dark := kit.mat("wood_dark")
	kit.solid(room_id, Vector3(-26, 0.01, 26), Vector3(19.4, 0.025, 8.8), sand, 0.0, false)
	for x in [-36.0, -16.0]:
		for z in [22.0, 30.0]:
			_column(kit, room_id, Vector3(x, 0, z), sand, gold)

	# The actual jewel and its glass case are placed by MuseumLevel at (-33, 27).
	# A high portal draws the eye to it without obstructing interaction.
	for x in [-35.4, -30.6]:
		kit.solid(room_id, Vector3(x, 0, 29.8), Vector3(0.35, 3.5, 0.35), sand, 0.0, false)
		kit.solid(room_id, Vector3(x, 3.45, 29.8), Vector3(0.55, 0.15, 0.55), gold, 0.0, false)
	kit.solid(room_id, Vector3(-33, 3.5, 29.8), Vector3(5.1, 0.3, 0.55), gold, 0.0, false)
	kit.solid(room_id, Vector3(-33, 3.8, 29.8), Vector3(4.6, 0.15, 0.38), lapis, 0.0, false)
	kit.label(room_id, "THE EMERALD EMPRESS", Vector3(-33, 2.8, 29.48), PI, 35, Color(0.93, 0.75, 0.39))
	kit.spot(room_id, Vector3(-33, 4.8, 28.8), Vector3(-33, 1.1, 27), Color(1, 0.67, 0.31), 1.4, 6.0, 32.0, true)

	# Landmark obelisk on the east edge, off the guard route.
	kit.solid(room_id, Vector3(-17.2, 0, 29.0), Vector3(1.8, 0.37, 1.8), dark)
	kit.solid(room_id, Vector3(-17.2, 0.37, 29.0), Vector3(1.6, 0.13, 1.6), gold, 0.0, false)
	kit.prop(room_id, _obelisk_mesh(), Transform3D(Basis.IDENTITY, Vector3(-17.2, 0.5, 29.0)), sand, Vector3(1.0, 4.3, 1.0))
	kit.prop(room_id, _taper(Vector2(0.33, 0.33), Vector2(0.01, 0.01), 0.56), Transform3D(Basis.IDENTITY, Vector3(-17.2, 4.29, 29.0)), gold)
	kit.spot(room_id, Vector3(-18.5, 5.5, 28), Vector3(-17.2, 2.1, 29), Color(1, 0.62, 0.3), 0.55, 5.0, 35.0)

	# Low sphinx and coffins split sight lines. The west and east flanks stay walkable.
	_sphinx(kit, room_id, Vector3(-23.4, 0, 28.1), sand, lapis, gold)
	_coffin_case(kit, room_id, Vector3(-28.9, 0, 29.85), lapis, gold, kit.mat("ivory"))
	_coffin_case(kit, room_id, Vector3(-20.1, 0, 30.0), sand, gold, lapis)
	_canopic(kit, room_id, Vector3(-16.4, 0, 26.4), dark, kit.mat("papyrus"), gold)
	for z in [23.7, 27.0]:
		_glyph_panel(kit, room_id, Vector3(-14.46, 3.3, z), sand, gold)
	for p in [Vector3(-36.2, 3.1, 22.8), Vector3(-15.8, 3.1, 23.0)]:
		kit.prop(room_id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.13, 0.22, 0.13)), p), kit.mat("emissive_warm"))
		kit.omni(room_id, p, Color(1, 0.54, 0.23), 0.4, 4.0)


static func _column(kit: LevelKit, id: String, p: Vector3, sand: Material, gold: Material) -> void:
	kit.cylinder_solid(id, p, 0.38, 5.62, sand, 20)
	for y in [0.12, 5.2]:
		kit.solid(id, p + Vector3(0, y, 0), Vector3(1.12, 0.23, 1.12), sand, 0.0, false)
	for y in [0.45, 4.94, 5.48]:
		var ring := CylinderMesh.new()
		ring.top_radius = 0.48
		ring.bottom_radius = 0.48
		ring.height = 0.055
		kit.prop(id, ring, Transform3D(Basis.IDENTITY, p + Vector3(0, y, 0)), gold)
	for i in 4:
		var a := float(i) * TAU / 4.0
		var leaf := CylinderMesh.new()
		leaf.bottom_radius = 0.11
		leaf.top_radius = 0.34
		leaf.height = 0.5
		leaf.radial_segments = 8
		kit.prop(id, leaf, Transform3D(Basis.IDENTITY, p + Vector3(cos(a) * 0.22, 5.04, sin(a) * 0.22)), sand)


static func _sphinx(kit: LevelKit, id: String, p: Vector3, sand: Material, lapis: Material, gold: Material) -> void:
	kit.solid(id, p, Vector3(3.35, 0.22, 1.9), kit.mat("wood_dark"))
	# One broad collider makes this a reliable crouch-height cover piece.
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(1.15, 0.61, 0.64)), p + Vector3(0.2, 0.88, 0)), sand, Vector3(2.75, 1.2, 1.35))
	for z in [-0.53, 0.53]:
		kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.81, 0.18, 0.2)), p + Vector3(-0.96, 0.43, z)), sand)
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.45, 0.59, 0.46)), p + Vector3(-0.9, 1.56, 0)), lapis)
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.3, 0.37, 0.34)), p + Vector3(-1.12, 1.7, 0)), sand)
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.12, 0.2, 0.18)), p + Vector3(-1.37, 1.52, 0)), gold)
	kit.solid(id, p + Vector3(-0.94, 2.03, 0), Vector3(0.75, 0.09, 0.69), gold, 0.0, false)


static func _coffin_case(kit: LevelKit, id: String, p: Vector3, shell: Material, gold: Material, face: Material) -> void:
	kit.solid(id, p, Vector3(1.37, 0.46, 2.43), kit.mat("wood_dark"))
	kit.solid(id, p + Vector3(0, 0.46, 0), Vector3(1.48, 0.06, 2.54), gold, 0.0, false)
	kit.prop(id, _coffin_mesh(), Transform3D(Basis.IDENTITY, p + Vector3(0, 0.52, 0)), shell, Vector3(1.16, 0.62, 2.27))
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.35, 0.11, 0.44)), p + Vector3(0, 1.14, -0.57)), face)
	for z in [-0.22, 0.09, 0.4, 0.71]:
		kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.94, 0.024, 0.045)), p + Vector3(0, 1.105, z)), gold)
	kit.spot(id, p + Vector3(0, 4.1, 0.2), p + Vector3(0, 0.8, 0), Color(1, 0.72, 0.4), 0.46, 4.0, 34.0)


static func _canopic(kit: LevelKit, id: String, p: Vector3, dark: Material, clay: Material, gold: Material) -> void:
	kit.solid(id, p, Vector3(1.15, 0.94, 2.0), dark)
	kit.solid(id, p + Vector3(0, 0.94, 0), Vector3(1.3, 0.08, 2.1), gold, 0.0, false)
	for z in [-0.67, -0.22, 0.22, 0.67]:
		var jar := CylinderMesh.new()
		jar.bottom_radius = 0.15
		jar.top_radius = 0.22
		jar.height = 0.46
		jar.radial_segments = 12
		kit.prop(id, jar, Transform3D(Basis.IDENTITY, p + Vector3(0, 1.29, z)), clay)
		kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.22, 0.11, 0.22)), p + Vector3(0, 1.55, z)), gold)


static func _glyph_panel(kit: LevelKit, id: String, p: Vector3, sand: Material, gold: Material) -> void:
	var plane := QuadMesh.new()
	plane.size = Vector2(2.1, 3.0)
	kit.prop(id, plane, Transform3D(Basis(Vector3.UP, -PI * 0.5), p), _glyphs())
	for z in [-1.14, 1.14]:
		kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.07, 3.2, 0.07)), p + Vector3(-0.015, 0, z)), gold)
	for y in [-1.58, 1.58]:
		kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.07, 0.07, 2.35)), p + Vector3(-0.015, y, 0)), sand)


static func _glyphs() -> StandardMaterial3D:
	if _glyph_material != null:
		return _glyph_material
	var img := Image.create(256, 384, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.58, 0.44, 0.29))
	var ink := Color(0.13, 0.19, 0.26)
	for row in 9:
		for col in 4:
			var x := 21 + col * 55
			var y := 20 + row * 40
			_line(img, Vector2i(x, y + 24), Vector2i(x + 29, y + 24), ink)
			match (row * 7 + col * 3) % 5:
				0:
					_line(img, Vector2i(x + 5, y + 4), Vector2i(x + 25, y + 4), ink)
					_line(img, Vector2i(x + 15, y + 4), Vector2i(x + 15, y + 21), ink)
				1:
					_line(img, Vector2i(x + 4, y + 19), Vector2i(x + 15, y + 3), ink)
					_line(img, Vector2i(x + 15, y + 3), Vector2i(x + 27, y + 19), ink)
				2:
					_line(img, Vector2i(x + 4, y + 5), Vector2i(x + 26, y + 19), ink)
					_line(img, Vector2i(x + 5, y + 19), Vector2i(x + 25, y + 5), ink)
				3:
					_line(img, Vector2i(x + 15, y + 2), Vector2i(x + 15, y + 21), ink)
					_line(img, Vector2i(x + 5, y + 12), Vector2i(x + 25, y + 12), ink)
				4:
					for k in 3:
						_line(img, Vector2i(x + 5, y + k * 7), Vector2i(x + 25, y + k * 7), ink)
	_glyph_material = StandardMaterial3D.new()
	_glyph_material.albedo_texture = ImageTexture.create_from_image(img)
	_glyph_material.roughness = 0.95
	_glyph_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _glyph_material


static func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var steps := maxi(abs(b.x - a.x), abs(b.y - a.y))
	for i in steps + 1:
		var t := float(i) / float(maxi(steps, 1))
		var x := clampi(roundi(lerpf(float(a.x), float(b.x), t)), 1, 254)
		var y := clampi(roundi(lerpf(float(a.y), float(b.y), t)), 1, 382)
		for ox in [-1, 0, 1]:
			for oy in [-1, 0, 1]:
				img.set_pixel(x + ox, y + oy, c)


static func _obelisk_mesh() -> ArrayMesh:
	if _obelisk == null:
		_obelisk = _taper(Vector2(0.52, 0.52), Vector2(0.32, 0.32), 3.79)
	return _obelisk


static func _coffin_mesh() -> ArrayMesh:
	if _coffin != null:
		return _coffin
	var outline := PackedVector2Array([
		Vector2(-0.28, -1.08), Vector2(0.28, -1.08), Vector2(0.5, -0.7),
		Vector2(0.53, 0.48), Vector2(0.3, 1.08), Vector2(-0.3, 1.08),
		Vector2(-0.53, 0.48), Vector2(-0.5, -0.7),
	])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var a := Vector3(outline[i].x, 0, outline[i].y)
		var b := Vector3(outline[j].x, 0, outline[j].y)
		_quad(st, a, b, b + Vector3(0, 0.61, 0), a + Vector3(0, 0.61, 0))
		_tri(st, Vector3(0, 0.62, 0), a + Vector3(0, 0.61, 0), b + Vector3(0, 0.61, 0))
	st.generate_normals()
	_coffin = st.commit()
	return _coffin


static func _taper(bottom: Vector2, top: Vector2, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	for i in 4:
		var j := (i + 1) % 4
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[j]
		_quad(st,
			Vector3(a.x * bottom.x, 0, a.y * bottom.y),
			Vector3(b.x * bottom.x, 0, b.y * bottom.y),
			Vector3(b.x * top.x, h, b.y * top.y),
			Vector3(a.x * top.x, h, a.y * top.y))
	st.generate_normals()
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)
	_tri(st, a, c, d)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _box_mesh() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
	return _box


static func _sphere_mesh() -> SphereMesh:
	if _sphere == null:
		_sphere = SphereMesh.new()
		_sphere.radial_segments = 16
		_sphere.rings = 8
	return _sphere
