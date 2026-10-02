extends RefCounted
## Egyptology exhibition. The diagonal patrol at z=23..25 remains clear.

static var _box: BoxMesh
static var _sphere: SphereMesh
static var _obelisk: ArrayMesh
static var _coffin: ArrayMesh
static var _glyph_material: StandardMaterial3D
static var _painting_material: StandardMaterial3D


static func dress(kit: LevelKit, room_id: String) -> void:
	var sand := kit.mat("sandstone")
	var gold := kit.mat("gold")
	var lapis := kit.mat("lapis")
	var dark := kit.mat("wood_dark")
	kit.solid(room_id, Vector3(-26, 0.01, 26), Vector3(22.9, 0.018, 10.9),
		kit.pbr("large_sandstone_blocks", 1.5, Color(0.87, 0.72, 0.50)), 0.0, false)
	for x in [-35.9, -16.1]:
		for z in [21.15, 30.85]:
			_column(kit, room_id, Vector3(x, 0, z), sand, gold)
	for x in [-37.72, -14.28]:
		for y in [0.24, 1.12, 5.62]:
			kit.solid(room_id, Vector3(x, y, 26), Vector3(0.1, 0.08, 10.0),
				gold if y == 1.12 else sand, 0.0, false)

	# The actual jewel and its glass case are placed by MuseumLevel at (-33, 27).
	# A high portal draws the eye to it without obstructing interaction.
	for x in [-35.35, -30.65]:
		kit.solid(room_id, Vector3(x, 0.42, 30.7), Vector3(0.35, 3.5, 0.35), sand, 0.0, false)
		kit.solid(room_id, Vector3(x, 3.92, 30.7), Vector3(0.55, 0.15, 0.55), gold, 0.0, false)
	kit.solid(room_id, Vector3(-33, 3.92, 30.7), Vector3(5.1, 0.3, 0.55), sand, 0.0, false)
	kit.solid(room_id, Vector3(-33, 4.22, 30.7), Vector3(4.6, 0.15, 0.38), lapis, 0.0, false)
	kit.label(room_id, "THE EMERALD EMPRESS", Vector3(-33, 3.32, 30.36), PI, 35, Color(0.93, 0.75, 0.39))
	kit.solid(room_id, Vector3(-33, 4.08, 29.95), Vector3(0.55, 0.16, 0.25), kit.mat("brass"), 0.0, false)
	kit.spot(room_id, Vector3(-33, 4.02, 29.83), Vector3(-33, 1.1, 27), Color(1, 0.72, 0.42), 2.0, 5.8, 40.0, true)

	# Landmark obelisk on the east edge, off the guard route.
	kit.solid(room_id, Vector3(-17.2, 0, 29.0), Vector3(1.48, 0.37, 1.48), dark)
	kit.solid(room_id, Vector3(-17.2, 0.37, 29.0), Vector3(1.6, 0.10, 1.6), gold, 0.0, false)
	kit.prop(room_id, _obelisk_mesh(), Transform3D(Basis.IDENTITY, Vector3(-17.2, 0.47, 29.0)), sand, Vector3(0.95, 4.3, 0.95))
	kit.prop(room_id, _taper(Vector2(0.33, 0.33), Vector2(0.01, 0.01), 0.56), Transform3D(Basis.IDENTITY, Vector3(-17.2, 4.26, 29.0)), gold)
	for i in 4:
		var facing := Basis(Vector3.UP, float(i) * PI * 0.5)
		var glyph := QuadMesh.new()
		glyph.size = Vector2(0.59, 2.75)
		kit.prop(room_id, glyph, Transform3D(facing,
			Vector3(-17.2, 2.06, 29.0) + facing * Vector3(0, 0, 0.39)), _glyphs())

	# Low sphinx and coffins split sight lines. The west and east flanks stay walkable.
	_coffin_case(kit, room_id, Vector3(-28.65, 0, 29.5), lapis, gold, kit.mat("ivory"))
	_coffin_case(kit, room_id, Vector3(-20.5, 0, 29.6), sand, gold, lapis)
	_canopic(kit, room_id, Vector3(-15.45, 0, 26.6), dark, kit.mat("papyrus"), gold)
	for z in [22.6, 27.0]:
		_glyph_panel(kit, room_id, Vector3(-14.46, 3.3, z), sand, gold)
	kit.solid(room_id, Vector3(-34.9, 0, 30.4), Vector3(1.6, 0.82, 0.85), dark)
	kit.model(room_id, "treasure_chest", Transform3D(Basis(Vector3.UP, -0.22),
		Vector3(-34.9, 0.83, 30.4)), 0.66, "none")
	kit.model(room_id, "brass_vase_01", Transform3D(Basis.IDENTITY,
		Vector3(-18.9, 0.0, 30.9)), 0.88)
	_painting(kit, room_id)
	kit.model(room_id, "fancy_picture_frame_02", Transform3D(Basis(Vector3.UP, PI),
		Vector3(-33.3, 2.7, 31.71)), 1.48, "none")
	var papyrus := QuadMesh.new()
	papyrus.size = Vector2(0.92, 1.10)
	kit.prop(room_id, papyrus, Transform3D(Basis(Vector3.UP, PI),
		Vector3(-33.3, 3.44, 31.73)), _glyphs())
	kit.model(room_id, "lantern_chandelier_01", Transform3D(Basis.IDENTITY,
		Vector3(-25.5, 4.75, 27.7)), 1.05, "none")
	kit.omni(room_id, Vector3(-25.5, 4.52, 27.7), Color(1.0, 0.72, 0.43), 1.2, 7.4)
	for p in [Vector3(-37.1, 2.9, 22.4), Vector3(-37.1, 2.9, 29.7),
			Vector3(-14.9, 2.9, 22.3), Vector3(-14.9, 2.9, 29.7)]:
		_torch(kit, room_id, p)
	kit.spot(room_id, Vector3(-26, 4.0, 31.45), Vector3(-26, 0.4, 26.8),
		Color(0.47, 0.66, 1.0), 1.15, 7.4, 51.0)
	kit.omni(room_id, Vector3(-26, 3.7, 25.5), Color(0.62, 0.72, 0.89), 0.24, 8.3)


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
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.35, 0.14, 0.36)), p + Vector3(0, 1.14, -0.72)), face)
	for x in [-0.33, 0.33]:
		kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.07, 0.025, 0.69)),
			p + Vector3(x, 1.08, -0.52)), gold)
	for z in [-0.22, 0.09, 0.4, 0.71]:
		kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.94, 0.024, 0.045)), p + Vector3(0, 1.12, z)), gold)
	kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(1.02, 0.16, 0.045)),
		p + Vector3(0, 0.3, 1.24)), kit.mat("brass"))
	kit.prop(id, _box_mesh(), Transform3D(Basis().scaled(Vector3(0.38, 0.13, 0.23)),
		p + Vector3(0, 4.14, 0.2)), kit.mat("brass"))
	kit.spot(id, p + Vector3(0, 4.1, 0.2), p + Vector3(0, 0.8, 0), Color(1, 0.72, 0.4), 0.75, 4.5, 43.0)


static func _canopic(kit: LevelKit, id: String, p: Vector3, dark: Material, clay: Material, gold: Material) -> void:
	kit.solid(id, p, Vector3(0.88, 0.94, 2.32), dark)
	kit.solid(id, p + Vector3(0, 0.94, 0), Vector3(1.03, 0.08, 2.46), gold, 0.0, false)
	var names := ["antique_ceramic_vase_01", "ceramic_vase_01",
		"ceramic_vase_02", "brass_vase_01"]
	for i in 4:
		kit.model(id, names[i], Transform3D(Basis.IDENTITY,
			p + Vector3(0, 1.03, -0.84 + float(i) * 0.56)), 0.42, "none")


static func _torch(kit: LevelKit, id: String, p: Vector3) -> void:
	kit.solid(id, p + Vector3(0, -1.28, 0), Vector3(0.42, 0.90, 0.34),
		kit.mat("sandstone"), 0.0, false)
	kit.model(id, "brass_candleholders", Transform3D(Basis.IDENTITY,
		p + Vector3(0, -0.37, 0)), 0.72, "none")
	kit.prop(id, _sphere_mesh(), Transform3D(Basis().scaled(Vector3(0.095, 0.15, 0.095)),
		p + Vector3(0, 0.32, 0)), kit.mat("emissive_warm"))
	var light := kit.omni(id, p + Vector3(0, 0.31, 0),
		Color(1.0, 0.61, 0.31), 0.72, 4.7)
	var flicker := light.create_tween().set_loops()
	flicker.tween_property(light, "light_energy", 0.57, 0.13).set_trans(Tween.TRANS_SINE)
	flicker.tween_property(light, "light_energy", 0.78, 0.18).set_trans(Tween.TRANS_SINE)
	flicker.tween_property(light, "light_energy", 0.68, 0.11).set_trans(Tween.TRANS_SINE)


static func _painting(kit: LevelKit, id: String) -> void:
	var p := Vector3(-19.9, 3.33, 31.72)
	var width := 2.65
	var height := 1.66
	var q := QuadMesh.new()
	q.size = Vector2(width, height)
	kit.prop(id, q, Transform3D(Basis(Vector3.UP, PI), p), _painting_mat())
	for side in [-1.0, 1.0]:
		kit.solid(id, p + Vector3(side * (width * 0.5 + 0.085), -height * 0.5 - 0.17, 0.06),
			Vector3(0.17, height + 0.34, 0.13), kit.mat("wood_dark"), 0.0, false)
		kit.solid(id, p + Vector3(0, side * (height * 0.5 + 0.085) - 0.085, 0.06),
			Vector3(width + 0.34, 0.17, 0.13), kit.mat("gold"), 0.0, false)
	kit.solid(id, p + Vector3(0, height * 0.5 + 0.24, -0.23),
		Vector3(0.72, 0.07, 0.16), kit.mat("brass"), 0.0, false)
	kit.spot(id, p + Vector3(0, height * 0.5 + 0.23, -0.27),
		p + Vector3(0, 0, -0.08), Color(1, 0.76, 0.48), 0.78, 3.1, 52.0)


static func _painting_mat() -> StandardMaterial3D:
	if _painting_material == null:
		_painting_material = StandardMaterial3D.new()
		_painting_material.albedo_texture = load("res://assets/art/egyptian/nile_funeral_barge.png")
		_painting_material.roughness = 0.85
		_painting_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _painting_material


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
	# Narrow head and feet, broad shoulders and a raised crown form an
	# anthropoid lid instead of an eight-sided rectangular coffin.
	var outline := PackedVector2Array([
		Vector2(-0.19, -1.12), Vector2(0.19, -1.12),
		Vector2(0.29, -0.98), Vector2(0.31, -0.72),
		Vector2(0.46, -0.48), Vector2(0.56, -0.27),
		Vector2(0.49, 0.39), Vector2(0.31, 1.12),
		Vector2(-0.31, 1.12), Vector2(-0.49, 0.39),
		Vector2(-0.56, -0.27), Vector2(-0.46, -0.48),
		Vector2(-0.31, -0.72), Vector2(-0.29, -0.98),
	])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var a := Vector3(outline[i].x, 0, outline[i].y)
		var b := Vector3(outline[j].x, 0, outline[j].y)
		var ah := 0.43 + 0.08 * (1.0 - absf(outline[i].x) / 0.56)
		var bh := 0.43 + 0.08 * (1.0 - absf(outline[j].x) / 0.56)
		_quad(st, a, b, b + Vector3(0, bh, 0), a + Vector3(0, ah, 0))
		_tri(st, Vector3(0, 0.59, 0), a + Vector3(0, ah, 0), b + Vector3(0, bh, 0))
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
