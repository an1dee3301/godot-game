extends RefCounted
## A toddler-scale timber aircraft and soft-play island. Front / slide exit faces +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "KidsPlayAircraft"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [Kit.SAGE.lightened(0.22), Kit.CLAY.lightened(0.32), Kit.OCHRE.lightened(0.3), Kit.INDIGO.lightened(0.4)]
	var accent: Color = accents[choice]
	var sage: Material = Kit.stone(Kit.SAGE.lightened(0.27), 0.98, "kids_rubber_sage")
	var clay: Material = Kit.stone(Kit.CLAY.lightened(0.38), 0.98, "kids_rubber_clay")
	var oak: Material = Kit.wood(Kit.OAK, "oak")
	var walnut: Material = Kit.wood(Kit.WALNUT, "walnut")
	var cream: Material = Kit.paint(Kit.CREAM, 0.72)
	var trim: Material = Kit.paint(accent, 0.82)
	# Low, softened rubber perimeter; four inset pads leave honest expansion seams.
	Kit.rbox(root, Vector3(4.0, 0.055, 4.0), Vector3(0.0, 0.0275, 0.0), sage, 0.026, false)
	for row: int in 2:
		for col: int in 2:
			var pad: Material = sage if (row + col + choice) % 2 == 0 else clay
			Kit.rbox(root, Vector3(1.94, 0.032, 1.94), Vector3(-0.98 + col * 1.96, 0.066, -0.98 + row * 1.96), pad, 0.015, false)
	# Aircraft is offset to leave a separate block-building patch on the left.
	var plane: Node3D = Node3D.new()
	plane.name = "LittleOakAirliner"
	plane.position = Vector3(0.58, 0.082, 0.0)
	root.add_child(plane)
	Kit.rbox(plane, Vector3(0.96, 0.13, 1.04), Vector3(0.0, 0.69, -0.83), oak, 0.06)
	Kit.rbox(plane, Vector3(0.7, 0.035, 0.7), Vector3(0.0, 0.772, -0.73), sage, 0.017, false)
	# Broad enclosed stair treads, 180 mm rises, approached from the rear.
	for step: int in 3:
		var height: float = 0.18 * (step + 1)
		var z: float = -1.64 + step * 0.25
		Kit.rbox(plane, Vector3(0.68, height, 0.3), Vector3(0.0, height * 0.5, z), oak, 0.045)
		Kit.rbox(plane, Vector3(0.6, 0.018, 0.23), Vector3(0.0, height + 0.009, z), trim, 0.008, false)
	for side: float in [-1.0, 1.0]:
		# Rounded fuselage cheeks double as the raised platform's guards.
		Kit.rbox(plane, Vector3(0.14, 0.54, 1.34), Vector3(side * 0.45, 0.89, -0.68), oak, 0.069)
		Kit.rbox(plane, Vector3(0.025, 0.048, 1.12), Vector3(side * 0.525, 0.72, -0.68), trim, 0.012, false)
		for window: int in 3:
			var wz: float = -1.02 + window * 0.33
			Kit.rbox(plane, Vector3(0.018, 0.21, 0.22), Vector3(side * 0.523, 0.98, wz), cream, 0.008, false)
			Kit.rbox(plane, Vector3(0.023, 0.155, 0.165), Vector3(side * 0.535, 0.98, wz), Kit.paint(Kit.INDIGO.lightened(0.16), 0.32), 0.011, false)
		# Swept, padded wings and little turned engine pods beneath them.
		Kit.add(plane, Kit.rounded_box(Vector3(0.68, 0.12, 0.6), 0.059, 5), trim, Vector3(side * 0.77, 0.56, -0.58), Vector3(0.0, side * 17.0, 0.0))
		var engine: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.135, 0.045), Vector2(0.135, 0.3), Vector2(0.1, 0.35), Vector2(0.0, 0.35)]), 20)
		Kit.add(plane, engine, cream, Vector3(side * 0.77, 0.36, -0.7), Vector3(90.0, 0.0, 0.0))
		Kit.rbox(plane, Vector3(0.12, 0.57, 0.38), Vector3(side * 0.45, 1.11, -1.17), trim, 0.055)
		# Grounded skids support the deck without thin exposed legs.
		Kit.rbox(plane, Vector3(0.15, 0.65, 0.85), Vector3(side * 0.38, 0.325, -0.74), walnut, 0.065)
	Kit.add(plane, _slide_mesh(), cream, Vector3.ZERO)
	# Soft rounded bumper at the low nose / slide run-out.
	Kit.rbox(plane, Vector3(0.89, 0.14, 0.24), Vector3(0.0, 0.1, 1.51), trim, 0.069)
	# Upholstered building blocks: piping is a narrow reveal between matching shells.
	_soft_block(root, Vector3(-1.22, 0.082, -0.95), Vector3(0.62, 0.4, 0.62), accent, 0.0)
	_soft_block(root, Vector3(-1.2, 0.482, -0.95), Vector3(0.45, 0.35, 0.45), Kit.CREAM.darkened(0.08), 12.0 + choice * 6.0)
	_soft_block(root, Vector3(-1.12, 0.082, 0.13), Vector3(0.67, 0.3, 0.62), Kit.CLAY.lightened(0.32), -12.0)
	_soft_block(root, Vector3(-1.2, 0.082, 1.18), Vector3(0.61, 0.48, 0.55), Kit.SAGE.lightened(0.23), choice * 8.0)
	var pouf: ArrayMesh = Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.25, 0.0), Vector2(0.31, 0.05), Vector2(0.32, 0.22), Vector2(0.27, 0.3), Vector2(0.0, 0.32)]), 28)
	Kit.add(root, pouf, Kit.fabric(Kit.LINEN, "kids_pouf"), Vector3(-0.35, 0.082, 1.45))
	_build_sign(root, oak, accent)
	return root


static func _soft_block(parent: Node3D, at: Vector3, size: Vector3, tint: Color, angle: float) -> void:
	var block: Node3D = Node3D.new()
	block.position = at
	block.rotation_degrees.y = angle
	parent.add_child(block)
	var fabric: Material = Kit.fabric(tint, "kids_block_" + tint.to_html())
	Kit.rbox(block, size, Vector3(0.0, size.y * 0.5, 0.0), fabric, 0.095)
	Kit.rbox(block, Vector3(size.x + 0.004, 0.018, size.z + 0.004), Vector3(0.0, size.y * 0.53, 0.0), Kit.fabric(tint.darkened(0.14), "kids_pipe_" + tint.to_html()), 0.008, false)
	# Linen lifting loop, with recessed centre, on the outward-facing front.
	Kit.rbox(block, Vector3(0.15, 0.067, 0.02), Vector3(0.0, size.y * 0.68, size.z * 0.5), Kit.fabric(Kit.LINEN, "linen"), 0.009, false)
	Kit.rbox(block, Vector3(0.09, 0.025, 0.024), Vector3(0.0, size.y * 0.68, size.z * 0.5 + 0.009), fabric, 0.011, false)


static func _slide_mesh() -> ArrayMesh:
	if _meshes.has("slide"):
		return _meshes["slide"] as ArrayMesh
	# Sweep a rounded trough along a cosine descent: level launch and gentle run-out.
	var section: PackedVector2Array = PackedVector2Array([
		Vector2(-0.43, 0.0), Vector2(-0.43, 0.17), Vector2(-0.415, 0.195),
		Vector2(-0.385, 0.195), Vector2(-0.365, 0.17), Vector2(-0.35, 0.035),
		Vector2(-0.31, 0.0), Vector2(0.31, 0.0), Vector2(0.35, 0.035),
		Vector2(0.365, 0.17), Vector2(0.385, 0.195), Vector2(0.415, 0.195),
		Vector2(0.43, 0.17), Vector2(0.43, 0.0), Vector2(0.4, -0.055),
		Vector2(-0.4, -0.055)])
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in 32:
		var t0: float = float(segment) / 32.0
		var t1: float = float(segment + 1) / 32.0
		for j: int in section.size():
			var k: int = (j + 1) % section.size()
			var a: Vector3 = _slide_vertex(section[j], t0)
			var b: Vector3 = _slide_vertex(section[k], t0)
			var c: Vector3 = _slide_vertex(section[k], t1)
			var d: Vector3 = _slide_vertex(section[j], t1)
			for vertex: Vector3 in [a, c, b, a, d, c]:
				st.add_vertex(vertex)
	# Cap the cross-section at both ends using triangulation of the concave trough.
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(section)
	for end: int in 2:
		for index: int in range(0, triangles.size(), 3):
			var a: Vector3 = _slide_vertex(section[triangles[index]], float(end))
			var b: Vector3 = _slide_vertex(section[triangles[index + 1]], float(end))
			var c: Vector3 = _slide_vertex(section[triangles[index + 2]], float(end))
			var vertices: PackedVector3Array = PackedVector3Array([a, b, c]) if end == 0 else PackedVector3Array([a, c, b])
			for vertex: Vector3 in vertices:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["slide"] = mesh
	return mesh


static func _slide_vertex(point: Vector2, t: float) -> Vector3:
	return Vector3(point.x, 0.13 + 0.645 * (0.5 + 0.5 * cos(PI * t)) + point.y, -0.35 + 1.88 * t)


static func _build_sign(parent: Node3D, oak: Material, accent: Color) -> void:
	for x: float in [-1.63, 1.63]:
		Kit.rbox(parent, Vector3(0.09, 2.66, 0.09), Vector3(x, 1.412, -1.85), oak, 0.035)
		Kit.rbox(parent, Vector3(0.19, 0.05, 0.19), Vector3(x, 0.107, -1.85), Kit.metal(), 0.022)
	Kit.rbox(parent, Vector3(3.65, 1.55, 0.12), Vector3(0.0, 2.08, -1.85), oak, 0.055)
	Kit.rbox(parent, Vector3(3.47, 1.37, 0.025), Vector3(0.0, 2.08, -1.778), Kit.washi(Kit.CREAM, 0.35, "kids_sign_washi"), 0.012, false)
	Kit.rbox(parent, Vector3(3.22, 0.022, 0.018), Vector3(0.0, 2.56, -1.755), Kit.paint(accent), 0.008, false)
	var captions: Array[String] = ["Kids' Play", "あそび場 · 儿童乐园", "Khu vui chơi trẻ em", "Espace de jeux", "Zona de juegos"]
	for line: int in captions.size():
		var label: Label3D = Label3D.new()
		label.text = captions[line]
		label.font = Signs.font()
		label.font_size = 72 if line == 0 else 51
		label.pixel_size = 0.004
		label.modulate = Kit.CHARCOAL
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(0.0, 2.38 - line * 0.22, -1.752)
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
