extends RefCounted
## INTENDED_SCALE = 6
## Nominal 40 m wide x 16 m high x 18 m deep; coordinates and meshes are
## authored at 1/6 size. All node scales remain ONE, including the module root.
## Front (+Z) has two parked sliding leaves and an airline-neutral aircraft nose.

const UNIT: float = 1.0 / 6.0
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MaintenanceHangar"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var palettes: Array[Color] = [Color(0.92, 0.70, 0.20), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var scheme: int = posmod(variant, 4)
	var accent: Color = palettes[scheme]
	var stripe: Material = DesignKit.brass() if scheme == 3 else DesignKit.paint(DesignKit.CLAY if scheme == 1 else accent)
	var oak: Material = DesignKit.wood()
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "hangar_walnut")
	var stone: Material = DesignKit.stone()
	var steel: Material = DesignKit.metal()
	var cladding: Material = DesignKit.paint(DesignKit.PLASTER)
	var warm: Material = DesignKit.washi(DesignKit.CREAM, 1.4, "hangar_worklight")
	var amber: Material = DesignKit.washi(Color(1.0, 0.52, 0.10), 3.0, "hangar_amber")
	var roof: Material = _roof_material()
	_box(root, Vector3(40.0, 0.12, 18.0), Vector3(0.0, 0.06, 0.0), stone, 0.05)
	# Honed plinths, pale wall cladding and structural oak piers.
	for side: float in [-1.0, 1.0]:
		_box(root, Vector3(0.50, 1.0, 18.0), Vector3(side * 19.7, 0.5, 0.0), stone, 0.12)
		_box(root, Vector3(0.26, 8.8, 18.0), Vector3(side * 19.7, 5.4, 0.0), cladding, 0.06)
		_box(root, Vector3(0.32, 0.38, 18.0), Vector3(side * 19.72, 2.0, 0.0), stripe, 0.06)
		for bay in 4:
			var z: float = -6.75 + float(bay) * 4.5
			_box(root, Vector3(0.60, 9.9, 0.42), Vector3(side * 19.35, 5.05, z), oak, 0.10)
			_box(root, Vector3(0.08, 1.30, 3.55), Vector3(side * 19.87, 8.20, z), steel, 0.04)
			_box(root, Vector3(0.09, 1.08, 3.30), Vector3(side * 19.93, 8.20, z), warm, 0.05)
	_box(root, Vector3(39.4, 9.8, 0.32), Vector3(0.0, 5.0, -8.80), cladding, 0.08)
	DesignKit.add(root, _arch(18.0, 0.24), roof, Vector3.ZERO)
	# Arched end fascias and structural ribs make the vault readable from the apron.
	for z: float in [-8.95, 8.95]:
		DesignKit.add(root, _arch(0.22, 0.38), walnut, Vector3(0.0, 0.0, z * UNIT))
		DesignKit.add(root, _gable(), cladding, Vector3(0.0, 0.0, z * UNIT))
	for rib in 3:
		var z: float = -5.5 + float(rib) * 5.5
		DesignKit.add(root, _arch(0.20, 0.46), oak, Vector3(0.0, -0.20 * UNIT, z * UNIT))
		_box(root, Vector3(28.0, 0.20, 0.28), Vector3(0.0, 9.90, z), steel, 0.06)
		_box(root, Vector3(12.0, 0.12, 0.35), Vector3(0.0, 9.70, z), warm, 0.05)
	# Broad leaves park over the side bays, exposing an 18 m central opening.
	_box(root, Vector3(39.7, 0.32, 0.60), Vector3(0.0, 9.65, 9.04), steel, 0.10)
	_box(root, Vector3(39.4, 0.06, 0.18), Vector3(0.0, 0.17, 8.95), DesignKit.brass(), 0.02)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 14.50
		_box(root, Vector3(10.7, 9.1, 0.36), Vector3(x, 4.70, 9.0), DesignKit.paint(accent), 0.10)
		_box(root, Vector3(10.35, 7.95, 0.10), Vector3(x, 4.90, 9.22), oak, 0.06)
		for slat in 10:
			_box(root, Vector3(0.16, 7.90, 0.08), Vector3(x - 4.70 + float(slat) * 1.04, 4.90, 9.30), walnut, 0.03)
		_box(root, Vector3(10.50, 0.65, 0.08), Vector3(x, 1.25, 9.30), stripe, 0.03)
		_box(root, Vector3(0.13, 1.10, 0.18), Vector3(side * 9.55, 4.20, 9.40), DesignKit.brass(), 0.05)
		for roller_x: float in [-3.8, 3.8]:
			_box(root, Vector3(0.44, 0.44, 0.30), Vector3(x + roller_x, 9.30, 9.05), steel, 0.14)
		_box(root, Vector3(0.50, 0.15, 0.48), Vector3(side * 8.8, 9.83, 9.08), steel, 0.05)
		DesignKit.add(root, _beacon(), amber, Vector3(side * 8.8, 9.90, 9.08) * UNIT, Vector3.ZERO, false)
		# Recessed floodlights in the jambs, facing the apron.
		_box(root, Vector3(0.65, 0.50, 0.30), Vector3(side * 8.8, 7.90, 8.85), steel, 0.12)
		_box(root, Vector3(0.50, 0.34, 0.08), Vector3(side * 8.8, 7.90, 9.04), warm, 0.08)
	# Large exterior typography: heights are roughly 0.45–0.85 m after integration.
	_box(root, Vector3(23.0, 3.50, 0.18), Vector3(0.0, 12.35, 9.15), steel, 0.14)
	_box(root, Vector3(22.50, 0.05, 0.08), Vector3(0.0, 13.91, 9.27), DesignKit.brass(), 0.02)
	_label(root, "MAINTENANCE  /  01", Vector3(0.0, 13.22, 9.28), 0.83, 21.5, DesignKit.CREAM)
	_label(root, "整備格納庫　·　维修机库", Vector3(0.0, 12.38, 9.28), 0.57, 21.5, DesignKit.LINEN)
	_label(root, "Nhà chứa bảo dưỡng", Vector3(0.0, 11.74, 9.28), 0.49, 21.5, DesignKit.LINEN)
	_label(root, "Hangar de maintenance · Hangar de mantenimiento", Vector3(0.0, 11.12, 9.28), 0.49, 21.5, DesignKit.LINEN)
	# Shared international terminology on the rear service zone, visible through the opening.
	var staff: Array = Signage.TEXT["staff_only"]
	_box(root, Vector3(15.5, 1.80, 0.15), Vector3(0.0, 8.30, -8.55), walnut, 0.08)
	_label(root, "%s · %s · %s" % [staff[0], staff[1], staff[2]], Vector3(0.0, 8.70, -8.45), 0.47, 14.8, DesignKit.CREAM)
	_label(root, "%s · %s · %s" % [staff[3], staff[4], staff[5]], Vector3(0.0, 7.96, -8.45), 0.42, 14.8, DesignKit.CREAM)
	_aircraft(root, steel, warm)
	# Painted taxi centreline and short stop bar, without an oversized apron slab.
	_box(root, Vector3(0.16, 0.015, 3.8), Vector3(0.0, 0.14, 6.80), DesignKit.paint(DesignKit.OCHRE), 0.004)
	_box(root, Vector3(5.0, 0.015, 0.20), Vector3(0.0, 0.14, 7.50), DesignKit.paint(DesignKit.OCHRE), 0.004)
	return root


static func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, radius: float) -> MeshInstance3D:
	return DesignKit.rbox(parent, size * UNIT, at * UNIT, mat, radius * UNIT)


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, width: float, tint: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	var metrics: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x
	label.pixel_size = minf(height / label.font.get_height(96), width / maxf(metrics, 1.0)) * UNIT
	label.position = at * UNIT
	label.modulate = tint
	label.outline_size = 0
	label.no_depth_test = false
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _aircraft(parent: Node3D, steel: Material, light: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(2.45, 0.0), Vector2(2.50, 5.0),
		Vector2(2.40, 7.3), Vector2(2.10, 9.0), Vector2(1.50, 10.6),
		Vector2(0.75, 11.65), Vector2(0.20, 12.05), Vector2(0.0, 12.12)])
	for i in profile.size():
		profile[i] *= UNIT
	DesignKit.add(parent, DesignKit.lathe(profile, 48), DesignKit.paint(DesignKit.CREAM, 0.30), Vector3(0.0, 4.10, -7.10) * UNIT, Vector3(90.0, 0.0, 0.0))
	var glass: Material = DesignKit.metal(DesignKit.INDIGO.darkened(0.45), 0.17, 0.45, "hangar_cockpit")
	for side: float in [-1.0, 1.0]:
		var pane: MeshInstance3D = _box(parent, Vector3(1.45, 0.80, 0.14), Vector3(side * 0.82, 5.70, 2.70), glass, 0.14)
		pane.rotation_degrees = Vector3(-22.0, side * 27.0, 0.0)
		_box(parent, Vector3(0.11, 0.65, 0.06), Vector3(side * 0.08, 5.65, 2.96), steel, 0.02)
		DesignKit.add(parent, _wheel(), DesignKit.paint(DesignKit.CHARCOAL, 0.95), Vector3(side * 0.47, 0.75, 1.70) * UNIT, Vector3(0.0, 0.0, 90.0))
		_box(parent, Vector3(0.16, 0.12, 0.06), Vector3(side * 0.35, 2.65, 3.85), light, 0.04)
	_box(parent, Vector3(0.22, 1.50, 0.25), Vector3(0.0, 1.80, 1.70), steel, 0.05)
	_box(parent, Vector3(1.10, 0.16, 0.22), Vector3(0.0, 0.75, 1.70), steel, 0.04)


static func _wheel() -> Mesh:
	return _scaled_lathe(PackedVector2Array([
		Vector2(0.0, -0.16), Vector2(0.55, -0.16), Vector2(0.63, -0.10),
		Vector2(0.63, 0.10), Vector2(0.55, 0.16), Vector2(0.0, 0.16)]), 24)


static func _beacon() -> Mesh:
	return _scaled_lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.18, 0.22),
		Vector2(0.13, 0.30), Vector2(0.0, 0.32)]), 16)


static func _roof_material() -> Material:
	if not _materials.has("roof"):
		var mat: StandardMaterial3D = DesignKit.metal(DesignKit.SAGE.lightened(0.22), 0.60, 0.40, "hangar_roof").duplicate() as StandardMaterial3D
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["roof"] = mat
	return _materials["roof"] as Material


static func _arch(depth: float, thickness: float) -> ArrayMesh:
	var key: String = "arch:%s:%s" % [depth, thickness]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 48:
		var a: float = PI * float(segment) / 48.0
		var b: float = PI * float(segment + 1) / 48.0
		var outer_a: Vector3 = Vector3(20.0 * cos(a), 10.0 + 6.0 * sin(a), 0.0)
		var outer_b: Vector3 = Vector3(20.0 * cos(b), 10.0 + 6.0 * sin(b), 0.0)
		var inner_a: Vector3 = Vector3((20.0 - thickness) * cos(a), 10.0 - thickness + 6.0 * sin(a), 0.0)
		var inner_b: Vector3 = Vector3((20.0 - thickness) * cos(b), 10.0 - thickness + 6.0 * sin(b), 0.0)
		var front: Vector3 = Vector3(0.0, 0.0, depth * 0.5)
		var back: Vector3 = -front
		_quad(st, outer_a + front, outer_b + front, outer_b + back, outer_a + back)
		_quad(st, inner_b + front, inner_a + front, inner_a + back, inner_b + back)
		_quad(st, outer_b + front, outer_a + front, inner_a + front, inner_b + front)
		_quad(st, outer_a + back, outer_b + back, inner_b + back, inner_a + back)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _gable() -> ArrayMesh:
	if _meshes.has("gable"):
		return _meshes["gable"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 48:
		var a: float = PI * float(segment) / 48.0
		var b: float = PI * float(segment + 1) / 48.0
		var va: Vector3 = Vector3(19.6 * cos(a), 9.8 + 5.85 * sin(a), 0.0)
		var vb: Vector3 = Vector3(19.6 * cos(b), 9.8 + 5.85 * sin(b), 0.0)
		_quad(st, Vector3(va.x, 9.8, 0.0), Vector3(vb.x, 9.8, 0.0), vb, va)
		_quad(st, Vector3(vb.x, 9.8, -0.05), Vector3(va.x, 9.8, -0.05), va + Vector3(0.0, 0.0, -0.05), vb + Vector3(0.0, 0.0, -0.05))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["gable"] = mesh
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for vertex: Vector3 in [a, b, c, a, c, d]:
		st.set_uv(Vector2(vertex.x, vertex.z) * 0.15)
		st.add_vertex(vertex * UNIT)


static func _scaled_lathe(profile: PackedVector2Array, segments: int) -> ArrayMesh:
	for i in profile.size():
		profile[i] *= UNIT
	return DesignKit.lathe(profile, segments)
