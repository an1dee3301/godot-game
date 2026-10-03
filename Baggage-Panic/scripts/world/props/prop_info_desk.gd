extends RefCounted
## Bowed reception island. All geometry is in metres, with the visitor side at +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "InformationDesk"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "info_walnut")
	var stone: StandardMaterial3D = DesignKit.stone()
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var trim_wood: StandardMaterial3D = walnut if choice % 2 == 1 else oak
	# Continuous curved solids, including rounded end caps and bevelled top/bottom edges.
	DesignKit.add(root, _counter_mesh(0.37, 0.12, 0.018), steel, Vector3(0.0, 0.0, 0.0))
	DesignKit.add(root, _counter_mesh(0.39, 0.035, 0.009), brass, Vector3(0.0, 0.12, 0.0))
	DesignKit.add(root, _counter_mesh(0.43, 0.84, 0.035), oak, Vector3(0.0, 0.155, 0.0))
	DesignKit.add(root, _counter_mesh(0.445, 0.026, 0.008), walnut, Vector3(0.0, 0.986, 0.0))
	DesignKit.add(root, _counter_mesh(0.49, 0.09, 0.025), stone, Vector3(0.0, 1.012, 0.0))
	# Narrow individually rounded flutes share one draw call, retaining oak between them.
	var flutes: MultiMesh = MultiMesh.new()
	flutes.transform_format = MultiMesh.TRANSFORM_3D
	flutes.mesh = DesignKit.rounded_box(Vector3(0.038, 0.73, 0.032), 0.014)
	flutes.instance_count = 57
	for index in flutes.instance_count:
		var angle: float = lerpf(-0.775, 0.775, float(index) / 56.0)
		var point: Vector3 = Vector3(sin(angle) * 3.435, 0.565, cos(angle) * 3.435 - 2.8)
		flutes.set_instance_transform(index, Transform3D(Basis(Vector3.UP, angle), point))
	var ribs: MultiMeshInstance3D = MultiMeshInstance3D.new()
	ribs.name = "OakFlutedFront"
	ribs.multimesh = flutes
	ribs.material_override = trim_wood
	root.add_child(ribs)
	# Two paired workstations, angled slightly toward the staff aisle at -Z.
	for index in 2:
		var x: float = -0.95 if index == 0 else 0.95
		var station: Node3D = Node3D.new()
		station.name = "Monitor_%d" % index
		station.position = Vector3(x, 1.102, -0.08)
		station.rotation_degrees.y = -8.0 if index == 0 else 8.0
		root.add_child(station)
		DesignKit.rbox(station, Vector3(0.38, 0.028, 0.24), Vector3(0.0, 0.014, 0.0), steel, 0.012)
		DesignKit.rbox(station, Vector3(0.07, 0.19, 0.07), Vector3(0.0, 0.12, 0.0), brass, 0.018)
		var display: Node3D = Node3D.new()
		display.position = Vector3(0.0, 0.36, 0.0)
		display.rotation_degrees.x = -9.0
		station.add_child(display)
		DesignKit.rbox(display, Vector3(0.64, 0.40, 0.055), Vector3.ZERO, steel, 0.025)
		DesignKit.rbox(display, Vector3(0.59, 0.345, 0.009), Vector3(0.0, 0.0, -0.031), DesignKit.washi(accent.darkened(0.65), 0.65, "info_screen_%d" % choice), 0.014, false)
		# Staff-facing screen graphics suggest a terminal map without illegible microtext.
		DesignKit.rbox(display, Vector3(0.44, 0.018, 0.006), Vector3(0.0, 0.07, -0.039), DesignKit.paint(DesignKit.CREAM), 0.003, false)
		DesignKit.rbox(display, Vector3(0.018, 0.18, 0.006), Vector3(-0.12, 0.0, -0.039), DesignKit.paint(DesignKit.CREAM), 0.003, false)
		DesignKit.rbox(display, Vector3(0.20, 0.045, 0.008), Vector3(0.0, -0.055, 0.031), trim_wood, 0.012, false)
		DesignKit.rbox(station, Vector3(0.47, 0.018, 0.16), Vector3(0.0, 0.009, -0.26), steel, 0.008, false)
	# Low writing area on the rounded right return, edged with brass.
	DesignKit.rbox(root, Vector3(0.73, 0.045, 0.62), Vector3(2.31, 0.77, -0.78), brass, 0.021)
	DesignKit.rbox(root, Vector3(0.70, 0.06, 0.59), Vector3(2.31, 0.81, -0.78), stone, 0.028)
	DesignKit.rbox(root, Vector3(0.16, 0.72, 0.39), Vector3(2.49, 0.36, -0.92), trim_wood, 0.045)
	# Freestanding pictogram: turned stone foot, brass mast, and a warm inset face.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.31, 0.0), Vector2(0.36, 0.025),
		Vector2(0.36, 0.07), Vector2(0.31, 0.105), Vector2(0.0, 0.105)
	]), 32), stone, Vector3(-3.05, 0.0, -0.18))
	DesignKit.rbox(root, Vector3(0.095, 1.87, 0.095), Vector3(-3.05, 1.03, -0.18), brass, 0.032)
	DesignKit.rbox(root, Vector3(0.82, 1.12, 0.17), Vector3(-3.05, 1.93, -0.18), trim_wood, 0.08)
	DesignKit.rbox(root, Vector3(0.73, 1.03, 0.028), Vector3(-3.05, 1.93, -0.082), DesignKit.paint(accent), 0.07)
	DesignKit.rbox(root, Vector3(0.13, 0.43, 0.035), Vector3(-3.05, 1.81, -0.048), brass, 0.026)
	DesignKit.rbox(root, Vector3(0.24, 0.065, 0.04), Vector3(-3.05, 1.60, -0.043), brass, 0.022)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.073, 0.0), Vector2(0.08, 0.008),
		Vector2(0.08, 0.025), Vector2(0.073, 0.033), Vector2(0.0, 0.033)
	]), 24), brass, Vector3(-3.05, 2.18, -0.034), Vector3(90.0, 0.0, 0.0), false)
	# Information has no TEXT key: use the shared international font on a custom panel.
	for x in [-1.88, 1.88]:
		DesignKit.rbox(root, Vector3(0.045, 2.65, 0.045), Vector3(x, 1.325, -0.64), steel, 0.015)
	DesignKit.rbox(root, Vector3(4.46, 1.45, 0.15), Vector3(0.0, 2.79, -0.64), trim_wood, 0.07)
	DesignKit.rbox(root, Vector3(4.31, 1.30, 0.025), Vector3(0.0, 2.79, -0.551), DesignKit.washi(DesignKit.CREAM, 0.4, "info_sign_washi"), 0.055, false)
	DesignKit.rbox(root, Vector3(4.14, 0.018, 0.012), Vector3(0.0, 3.36, -0.53), brass, 0.005, false)
	_label(root, "Information", Vector3(0.0, 3.13, -0.529), 112, 0.0036)
	_label(root, "ご案内  ·  问讯处", Vector3(0.0, 2.79, -0.529), 72, 0.0036)
	_label(root, "Thông tin", Vector3(0.0, 2.50, -0.529), 68, 0.0036)
	_label(root, "Informations  ·  Información", Vector3(0.0, 2.24, -0.529), 64, 0.0036)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _outline(half_depth: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var extent: float = 0.78
	for index in 49:
		var angle: float = lerpf(-extent, extent, float(index) / 48.0)
		points.append(Vector2(sin(angle), cos(angle)) * (3.0 + half_depth) + Vector2(0.0, -2.8))
	var radial: Vector2 = Vector2(sin(extent), cos(extent))
	var tangent: Vector2 = Vector2(cos(extent), -sin(extent))
	var center: Vector2 = radial * 3.0 + Vector2(0.0, -2.8)
	for index in range(1, 13):
		var angle: float = PI * float(index) / 12.0
		points.append(center + (radial * cos(angle) + tangent * sin(angle)) * half_depth)
	for index in range(47, -1, -1):
		var angle: float = lerpf(-extent, extent, float(index) / 48.0)
		points.append(Vector2(sin(angle), cos(angle)) * (3.0 - half_depth) + Vector2(0.0, -2.8))
	radial = Vector2(sin(-extent), cos(-extent))
	tangent = Vector2(cos(-extent), -sin(-extent))
	center = radial * 3.0 + Vector2(0.0, -2.8)
	for index in range(1, 12):
		var angle: float = PI + PI * float(index) / 12.0
		points.append(center + (radial * cos(angle) + tangent * sin(angle)) * half_depth)
	return points


static func _counter_mesh(half_depth: float, height: float, bevel: float) -> ArrayMesh:
	var key: String = "curve:%0.3f:%0.3f:%0.3f" % [half_depth, height, bevel]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var levels: Array[Vector2] = [Vector2(bevel, 0.0), Vector2(0.0, bevel), Vector2(0.0, height - bevel), Vector2(bevel, height)]
	for level in 3:
		var lower: PackedVector2Array = _outline(half_depth - levels[level].x)
		var upper: PackedVector2Array = _outline(half_depth - levels[level + 1].x)
		for index in lower.size():
			var next: int = (index + 1) % lower.size()
			var a: Vector3 = Vector3(lower[index].x, levels[level].y, lower[index].y)
			var b: Vector3 = Vector3(lower[next].x, levels[level].y, lower[next].y)
			var c: Vector3 = Vector3(upper[next].x, levels[level + 1].y, upper[next].y)
			var d: Vector3 = Vector3(upper[index].x, levels[level + 1].y, upper[index].y)
			var edge: Vector2 = lower[next] - lower[index]
			var normal: Vector3 = Vector3(-edge.y, 0.0, edge.x).normalized()
			if level == 0:
				normal = (normal + Vector3.DOWN).normalized()
			elif level == 2:
				normal = (normal + Vector3.UP).normalized()
			_triangle(st, a, b, c, normal)
			_triangle(st, a, c, d, normal)
	var cap: PackedVector2Array = _outline(half_depth - bevel)
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(cap)
	for index in range(0, triangles.size(), 3):
		var a: Vector2 = cap[triangles[index]]
		var b: Vector2 = cap[triangles[index + 1]]
		var c: Vector2 = cap[triangles[index + 2]]
		_triangle(st, Vector3(a.x, height, a.y), Vector3(b.x, height, b.y), Vector3(c.x, height, c.y), Vector3.UP)
		_triangle(st, Vector3(a.x, 0.0, a.y), Vector3(b.x, 0.0, b.y), Vector3(c.x, 0.0, c.y), Vector3.DOWN)
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	# Godot front faces use clockwise winding as viewed from outside.
	var vertices: Array[Vector3] = [a, b, c]
	if (c - a).cross(b - a).dot(normal) <= 0.0:
		vertices[1] = c
		vertices[2] = b
	for vertex in vertices:
		st.set_normal(normal)
		st.set_uv(Vector2(vertex.x + vertex.z, vertex.y + vertex.z))
		st.add_vertex(vertex)
