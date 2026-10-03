extends RefCounted
## Twelve-metre static travelator; +Z is the arrival/boarding end.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Travelator"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.LINEN, DesignKit.INDIGO]
	var accent: Color = accents[choice]
	var timber: Material = DesignKit.wood(DesignKit.WALNUT if choice % 2 == 1 else DesignKit.OAK, "travelator_wood_%d" % (choice % 2))
	var steel: Material = DesignKit.metal(DesignKit.CHARCOAL, 0.4, 0.8, "travelator_steel")
	var rubber: Material = DesignKit.paint(Color(0.045, 0.043, 0.04), 0.78)
	var tread: Material = DesignKit.metal(Color(0.19, 0.18, 0.17), 0.62, 0.45, "travelator_tread")
	var warm_light: Material = DesignKit.washi(DesignKit.CREAM, 1.1, "travelator_edge_light")
	# Honed limestone perimeter sits on the floor; the mechanism is recessed in its reveal.
	DesignKit.rbox(root, Vector3(2.38, 0.06, 12.0), Vector3(0.0, 0.03, 0.0), DesignKit.stone(), 0.025)
	DesignKit.rbox(root, Vector3(1.88, 0.025, 11.74), Vector3(0.0, 0.0575, 0.0), rubber, 0.01)
	DesignKit.add(root, _pallets(), tread, Vector3.ZERO)
	DesignKit.add(root, _ribs(), tread, Vector3.ZERO, Vector3.ZERO, false)
	# Brass landing plates and actual interleaving comb teeth, rather than a painted stripe.
	for end: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(1.78, 0.026, 0.54), Vector3(0.0, 0.073, end * 5.70), steel, 0.012)
		DesignKit.rbox(root, Vector3(1.72, 0.018, 0.10), Vector3(0.0, 0.092, end * 5.43), DesignKit.brass(), 0.006)
		DesignKit.add(root, _comb(), DesignKit.brass(), Vector3(0.0, 0.0, end * 5.31), Vector3(0.0, 0.0 if end > 0.0 else 180.0, 0.0), false)
		DesignKit.rbox(root, Vector3(1.64, 0.007, 0.023), Vector3(0.0, 0.09, end * 5.82), DesignKit.brass(), 0.003, false)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 1.0
		# Layered skirt, wood reveal and quiet concealed lighting under the clear guard.
		DesignKit.rbox(root, Vector3(0.24, 0.19, 11.30), Vector3(x, 0.155, 0.0), steel, 0.055)
		DesignKit.rbox(root, Vector3(0.028, 0.11, 10.70), Vector3(x + side * 0.126, 0.16, 0.0), timber, 0.012)
		DesignKit.rbox(root, Vector3(0.02, 0.018, 10.44), Vector3(x - side * 0.123, 0.245, 0.0), warm_light, 0.007, false)
		DesignKit.add(root, _glass_guard(), _glass(choice), Vector3(x, 0.0, 0.0), Vector3.ZERO, false)
		DesignKit.add(root, _rail(), rubber, Vector3(x, 0.0, 0.0))
		# Glass joints and low clamp shoes: no opaque wall hiding the transparent panels.
		for joint in 7:
			var z: float = -5.16 + float(joint) * 1.72
			DesignKit.rbox(root, Vector3(0.045, 0.12, 0.085), Vector3(x, 0.29, z), steel, 0.014, false)
			if joint > 0 and joint < 6:
				DesignKit.rbox(root, Vector3(0.027, 0.64, 0.005), Vector3(x, 0.635, z), _glass_edge(), 0.002, false)
		for end: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.23, 0.28, 0.36), Vector3(x, 0.26, end * 5.35), steel, 0.085)
			DesignKit.rbox(root, Vector3(0.027, 0.17, 0.22), Vector3(x + side * 0.12, 0.30, end * 5.35), DesignKit.paint(accent), 0.013)
			# Recessed emergency stop in a brass bezel on the accessible outer skirt.
			var button_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.047, 0.0), Vector2(0.047, 0.012), Vector2(0.038, 0.022), Vector2(0.0, 0.022)]), 16)
			DesignKit.add(root, button_mesh, DesignKit.brass(), Vector3(x + side * 0.137, 0.32, end * 5.35), Vector3(0.0, 0.0, -side * 90.0), false)
			DesignKit.add(root, button_mesh, DesignKit.paint(DesignKit.CLAY), Vector3(x + side * 0.15, 0.32, end * 5.35), Vector3(0.0, 0.0, -side * 90.0), false).scale = Vector3(0.65, 0.65, 0.65)
	# Large, six-language wayfinding beside the entrance, clear of the passenger lane.
	for x: float in [2.00, 5.20]:
		DesignKit.rbox(root, Vector3(0.12, 1.69, 0.12), Vector3(x, 0.845, 5.10), timber, 0.025)
		DesignKit.rbox(root, Vector3(0.32, 0.055, 0.32), Vector3(x, 0.0275, 5.10), steel, 0.025)
	Signage.panel(root, Vector3(3.60, 2.25, 5.10), "gates", {"width": 4.2, "arrow": "up", "accent": accent})
	return root


static func _pallets() -> ArrayMesh:
	if _meshes.has("pallets"):
		return _meshes["pallets"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pallet: ArrayMesh = DesignKit.rounded_box(Vector3(1.70, 0.025, 0.394), 0.006, 2)
	for i in 27:
		st.append_from(pallet, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.075, -5.20 + float(i) * 0.4)))
	var mesh: ArrayMesh = st.commit()
	_meshes["pallets"] = mesh
	return mesh


static func _ribs() -> ArrayMesh:
	if _meshes.has("ribs"):
		return _meshes["ribs"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rib: ArrayMesh = DesignKit.rounded_box(Vector3(0.013, 0.009, 10.76), 0.003, 2)
	for i in 69:
		st.append_from(rib, 0, Transform3D(Basis.IDENTITY, Vector3(-0.816 + float(i) * 0.024, 0.091, 0.0)))
	var mesh: ArrayMesh = st.commit()
	_meshes["ribs"] = mesh
	return mesh


static func _comb() -> ArrayMesh:
	if _meshes.has("comb"):
		return _meshes["comb"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tooth: ArrayMesh = DesignKit.rounded_box(Vector3(0.010, 0.014, 0.19), 0.004, 2)
	for i in 68:
		st.append_from(tooth, 0, Transform3D(Basis.IDENTITY, Vector3(-0.804 + float(i) * 0.024, 0.096, 0.0)))
	var mesh: ArrayMesh = st.commit()
	_meshes["comb"] = mesh
	return mesh


## Closed capsule path in the YZ plane: handrail bends down and returns beneath its top run.
static func _rail() -> ArrayMesh:
	if _meshes.has("rail"):
		return _meshes["rail"] as ArrayMesh
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	for end in 2:
		for i in 19:
			var angle: float = float(i) / 18.0 * PI + float(end) * PI
			points.append(Vector3(0.0, 0.66 + cos(angle) * 0.37, (5.22 if end == 0 else -5.22) + sin(angle) * 0.37))
			normals.append(Vector3(0.0, cos(angle), sin(angle)))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size():
		var next: int = (i + 1) % points.size()
		for j in 12:
			for corner: Vector2i in [Vector2i(i, j), Vector2i(next, j), Vector2i(next, j + 1), Vector2i(i, j), Vector2i(next, j + 1), Vector2i(i, j + 1)]:
				var angle: float = float(corner.y) / 12.0 * TAU
				var outward: Vector3 = Vector3.RIGHT * cos(angle) / 0.048 + normals[corner.x] * sin(angle) / 0.022
				st.set_normal(outward.normalized())
				st.add_vertex(points[corner.x] + Vector3.RIGHT * cos(angle) * 0.048 + normals[corner.x] * sin(angle) * 0.022)
	var mesh: ArrayMesh = st.commit()
	_meshes["rail"] = mesh
	return mesh


static func _glass_guard() -> ArrayMesh:
	if _meshes.has("glass_guard"):
		return _meshes["glass_guard"] as ArrayMesh
	# A thin, bevelled clear guard with softened ends fits inside the handrail loop.
	var mesh: ArrayMesh = DesignKit.rounded_box(Vector3(0.024, 0.71, 10.82), 0.011, 4)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(mesh, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.645, 0.0)))
	var result: ArrayMesh = st.commit()
	_meshes["glass_guard"] = result
	return result


static func _glass(choice: int) -> StandardMaterial3D:
	var key: String = "glass_%d" % choice
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = Color(0.69, 0.84, 0.80, 0.20 + float(choice) * 0.015)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.12
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = m
	return m


static func _glass_edge() -> Material:
	return DesignKit.paint(Color(0.37, 0.53, 0.47), 0.3)
