extends RefCounted
## Quiet, headphone-wearing traveller with an oversized hoodie and a canvas book tote.
## Feet touch y=0; the face, pocket and tote graphic look toward +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Student"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var colors: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var skins: Array[Color] = [Color(0.76, 0.53, 0.37), Color(0.91, 0.71, 0.55), Color(0.49, 0.32, 0.23)]
	var hairs: Array[Color] = [DesignKit.CHARCOAL, DesignKit.WALNUT, Color(0.19, 0.13, 0.10)]
	var hoodie: Material = DesignKit.fabric(colors[style], "student_hoodie_%d" % style)
	var rib: Material = DesignKit.fabric(colors[style].darkened(0.13), "student_rib_%d" % style)
	var skin: Material = DesignKit.paint(skins[style], 0.86)
	var hair: Material = DesignKit.paint(hairs[style], 0.94)
	var trousers: Material = DesignKit.fabric(DesignKit.CHARCOAL, "student_trousers")
	var canvas: Material = DesignKit.fabric(DesignKit.LINEN, "student_canvas")
	var cream: Material = DesignKit.paint(DesignKit.CREAM, 0.8)
	var dark: Material = DesignKit.paint(DesignKit.CHARCOAL, 0.7)
	var steel: Material = DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.55, "student_headphones")
	# Relaxed straight legs, with a small stagger to make the stance feel natural.
	for side: float in [-1.0, 1.0]:
		var z: float = 0.035 if side > 0.0 else -0.025
		_oval(root, Vector3(side * 0.112, 0.43, z), Vector3(0.16, 0.66, 0.17), trousers)
		DesignKit.rbox(root, Vector3(0.185, 0.055, 0.30), Vector3(side * 0.112, 0.0275, z + 0.065), cream, 0.025)
		_oval(root, Vector3(side * 0.112, 0.103, z + 0.05), Vector3(0.178, 0.115, 0.28), canvas)
	# A turned, slightly pear-shaped torso, flattened in depth like draped cloth.
	var body: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.185, 0.0), Vector2(0.228, 0.045),
		Vector2(0.235, 0.18), Vector2(0.24, 0.38), Vector2(0.215, 0.49),
		Vector2(0.13, 0.56), Vector2(0.0, 0.56)]), 16), hoodie, Vector3(0.0, 0.72, 0.0))
	body.scale.z = 0.7
	_oval(root, Vector3(0.0, 0.755, 0.0), Vector3(0.43, 0.085, 0.295), rib)
	_oval(root, Vector3(0.0, 1.205, -0.075), Vector3(0.36, 0.25, 0.28), rib)
	_oval(root, Vector3(0.0, 1.27, 0.0), Vector3(0.135, 0.18, 0.135), skin)
	for side: float in [-1.0, 1.0]:
		var sleeve: MeshInstance3D = _oval(root, Vector3(side * 0.275, 1.01, 0.0), Vector3(0.18, 0.43, 0.19), hoodie)
		sleeve.rotation_degrees.z = side * 12.0
		_oval(root, Vector3(side * 0.312, 0.817, 0.04), Vector3(0.145, 0.075, 0.15), rib)
		_oval(root, Vector3(side * 0.315, 0.752, 0.05), Vector3(0.11, 0.13, 0.115), skin)
	# Large soft head, tiny inset eyes and a rounded nose: no facial text.
	_oval(root, Vector3(0.0, 1.475, 0.025), Vector3(0.325, 0.37, 0.305), skin)
	_oval(root, Vector3(0.0, 1.607, -0.018), Vector3(0.35, 0.18, 0.30), hair)
	var fringe: MeshInstance3D = _oval(root, Vector3(-0.055, 1.596, 0.12), Vector3(0.23, 0.115, 0.075), hair)
	fringe.rotation_degrees.z = -14.0 if style != 1 else 14.0
	for side: float in [-1.0, 1.0]:
		_oval(root, Vector3(side * 0.061, 1.484, 0.171), Vector3(0.022, 0.032, 0.013), dark)
	_oval(root, Vector3(0.0, 1.443, 0.181), Vector3(0.038, 0.043, 0.038), skin)
	if style == 1:
		_oval(root, Vector3(0.0, 1.55, -0.171), Vector3(0.15, 0.15, 0.14), hair)
	# Continuous arched headband and two layered ear cups, with a brass outer ring.
	var headband: PackedVector3Array = PackedVector3Array()
	for i: int in 17:
		var angle: float = PI * float(i) / 16.0
		headband.append(Vector3(0.187 * cos(angle), 1.48 + 0.235 * sin(angle), -0.018))
	DesignKit.add(root, _tube(headband, 0.018), steel, Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		_oval(root, Vector3(side * 0.166, 1.473, -0.005), Vector3(0.067, 0.16, 0.14), dark)
		_oval(root, Vector3(side * 0.194, 1.473, -0.005), Vector3(0.035, 0.142, 0.123), DesignKit.brass())
		_oval(root, Vector3(side * 0.211, 1.473, -0.005), Vector3(0.031, 0.123, 0.106), steel)
	# Kangaroo pocket and cream drawcords have enough relief to read in silhouette.
	DesignKit.rbox(root, Vector3(0.285, 0.14, 0.045), Vector3(0.0, 0.873, 0.16), rib, 0.035)
	for side: float in [-1.0, 1.0]:
		DesignKit.add(root, _tube(PackedVector3Array([
			Vector3(side * 0.065, 1.25, 0.105), Vector3(side * 0.055, 1.16, 0.166),
			Vector3(side * 0.07, 1.075, 0.178)]), 0.009), cream, Vector3.ZERO)
	# Tote beside the left hip: curved bottom, bound top, and two continuous loop handles.
	DesignKit.rbox(root, Vector3(0.29, 0.37, 0.14), Vector3(-0.40, 0.62, 0.07), canvas, 0.065)
	DesignKit.rbox(root, Vector3(0.275, 0.035, 0.145), Vector3(-0.40, 0.795, 0.07), rib, 0.012)
	for z: float in [0.015, 0.125]:
		DesignKit.add(root, _tube(PackedVector3Array([
			Vector3(-0.51, 0.79, z), Vector3(-0.49, 0.93, z),
			Vector3(-0.35, 1.205, z), Vector3(-0.27, 1.23, z),
			Vector3(-0.32, 0.93, z), Vector3(-0.30, 0.79, z)]), 0.014), canvas, Vector3.ZERO)
	# Reuse the shared international wayfinding artwork as a bold, text-free tote print.
	DesignKit.add(root, _badge(), Signage._icon_material("plane", colors[style]), Vector3(-0.40, 0.635, 0.143), Vector3.ZERO, false)
	if style != 1:
		DesignKit.rbox(root, Vector3(0.17, 0.18, 0.027), Vector3(-0.40, 0.83, 0.063), cream, 0.007)
		DesignKit.rbox(root, Vector3(0.18, 0.19, 0.012), Vector3(-0.40, 0.83, 0.042), hoodie, 0.005)
	return root


static func _oval(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	if not _meshes.has("oval"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["oval"] = sphere
	var mesh: Mesh = _meshes["oval"]
	var instance: MeshInstance3D = DesignKit.add(parent, mesh, material, at)
	instance.scale = size
	return instance


static func _badge() -> Mesh:
	if not _meshes.has("badge"):
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.16, 0.16)
		_meshes["badge"] = quad
	return _meshes["badge"] as Mesh


static func _tube(points: PackedVector3Array, radius: float) -> ArrayMesh:
	var key: String = "tube:%s:%s" % [points, radius]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i: int in points.size():
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var across: Vector3 = tangent.cross(Vector3.FORWARD).normalized()
		var normal: Vector3 = tangent.cross(across).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for j: int in 8:
			var angle: float = TAU * float(j) / 8.0
			ring.append(points[i] + radius * (across * cos(angle) + normal * sin(angle)))
		rings.append(ring)
	for i: int in points.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		for j: int in 8:
			var next: int = (j + 1) % 8
			for vertex: Vector3 in [a[j], a[next], b[j], a[next], b[next], b[j]]:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
