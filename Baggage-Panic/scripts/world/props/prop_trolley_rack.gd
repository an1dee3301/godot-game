extends RefCounted
## Six tapered, nesting airport carts in a softly framed oak return station.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TrolleyReturnRack"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[choice]
	var oak: Material = DesignKit.wood(DesignKit.OAK, "oak")
	var steel: Material = DesignKit.metal(Color(0.67, 0.7, 0.69), 0.28, 0.95, "trolley_stainless")
	var charcoal: Material = DesignKit.metal(DesignKit.CHARCOAL, 0.43, 0.75, "trolley_charcoal")
	var rubber: Material = DesignKit.paint(Color(0.075, 0.075, 0.07), 0.94)
	# Open-ended parking bay: honed-stone anchors, steel guides and oak bump rails.
	for side: float in [-1.0, 1.0]:
		for z: float in [-1.36, 1.26]:
			DesignKit.rbox(root, Vector3(0.22, 0.08, 0.32), Vector3(side * 0.65, 0.04, z), DesignKit.stone(), 0.035)
			DesignKit.rbox(root, Vector3(0.065, 0.47, 0.065), Vector3(side * 0.65, 0.315, z), charcoal, 0.025)
		DesignKit.rbox(root, Vector3(0.075, 0.10, 2.95), Vector3(side * 0.65, 0.51, -0.05), oak, 0.035)
		DesignKit.rbox(root, Vector3(0.025, 0.028, 2.87), Vector3(side * 0.607, 0.51, -0.05), rubber, 0.012, false)
		# Sign legs are behind the innermost cart; brass collars protect the end grain.
		DesignKit.rbox(root, Vector3(0.09, 1.98, 0.09), Vector3(side * 0.65, 1.03, -1.36), oak, 0.03)
		DesignKit.rbox(root, Vector3(0.105, 0.14, 0.105), Vector3(side * 0.65, 0.15, -1.36), DesignKit.brass(), 0.025)
	DesignKit.rbox(root, Vector3(1.28, 0.08, 0.09), Vector3(0.0, 0.28, -1.48), charcoal, 0.035)
	for cart_index: int in 6:
		var offset: Vector3 = Vector3(0.0, 0.0, -0.86 + float(cart_index) * 0.285)
		var frame: MeshInstance3D = DesignKit.add(root, _cart_frame(), steel, offset)
		frame.name = "NestedTrolley_%02d" % (cart_index + 1)
		DesignKit.rbox(root, Vector3(0.48, 0.057, 0.064), offset + Vector3(0.0, 1.045, 0.43), DesignKit.paint(accent.darkened(0.23)), 0.027, false)
		DesignKit.rbox(root, Vector3(0.21, 0.095, 0.07), offset + Vector3(0.0, 0.967, 0.45), charcoal, 0.025, false)
		DesignKit.rbox(root, Vector3(0.13, 0.024, 0.012), offset + Vector3(0.0, 0.97, 0.491), DesignKit.paint(accent), 0.008, false)
		for wheel_at: Vector3 in [Vector3(-0.30, 0.085, 0.33), Vector3(0.30, 0.085, 0.33), Vector3(0.0, 0.085, -0.53)]:
			DesignKit.add(root, _wheel(), rubber, offset + wheel_at, Vector3(0.0, 0.0, 90.0), false)
			DesignKit.add(root, _hub(), steel, offset + wheel_at, Vector3(0.0, 0.0, 90.0), false)
	# Thick oak surround, recessed limestone-coloured face, warm concealed top wash.
	DesignKit.rbox(root, Vector3(3.70, 1.46, 0.16), Vector3(0.0, 2.19, -1.36), oak, 0.08)
	DesignKit.rbox(root, Vector3(3.53, 1.29, 0.035), Vector3(0.0, 2.19, -1.264), DesignKit.paint(DesignKit.CREAM), 0.05)
	DesignKit.rbox(root, Vector3(3.42, 0.018, 0.026), Vector3(0.0, 2.81, -1.236), DesignKit.washi(DesignKit.CREAM, 0.7, "trolley_sign_glow"), 0.007, false)
	DesignKit.rbox(root, Vector3(1.02, 1.02, 0.022), Vector3(-1.13, 2.22, -1.235), DesignKit.paint(accent), 0.07, false)
	_pictogram(root, Vector3(-1.13, 2.22, -1.213))
	_label(root, "Trolley Return", Vector3(0.57, 2.65, -1.238), 112, 2.25)
	_label(root, "カート返却 · 手推车归还", Vector3(0.57, 2.37, -1.238), 76, 2.25)
	_label(root, "Trả xe đẩy", Vector3(0.57, 2.14, -1.238), 76, 2.25)
	_label(root, "Retour chariots", Vector3(0.57, 1.91, -1.238), 76, 2.25)
	_label(root, "Devolución carros", Vector3(0.57, 1.68, -1.238), 76, 2.25)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, width: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.pixel_size = 0.0027
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	label.font_size = mini(size, int(float(size) * width / maxf(measured, 0.001)))
	label.position = at
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _pictogram(parent: Node3D, at: Vector3) -> void:
	# Raised line-art trolley with a rounded suitcase: unmistakable at a distance.
	var ink: Material = DesignKit.paint(DesignKit.CREAM)
	var st: SurfaceTool = SurfaceTool.new()
	if not _meshes.has("pictogram"):
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tube(st, PackedVector3Array([Vector3(-0.35, 0.32, 0.0), Vector3(-0.23, 0.32, 0.0), Vector3(-0.12, -0.21, 0.0), Vector3(0.34, -0.21, 0.0)]), 0.027)
		_tube(st, PackedVector3Array([Vector3(-0.17, -0.04, 0.0), Vector3(0.31, -0.04, 0.0), Vector3(0.36, 0.23, 0.0)]), 0.025)
		_meshes["pictogram"] = st.commit()
	DesignKit.add(parent, _meshes["pictogram"] as Mesh, ink, at, Vector3.ZERO, false)
	DesignKit.rbox(parent, Vector3(0.29, 0.30, 0.025), at + Vector3(0.07, 0.15, 0.0), ink, 0.035, false)
	DesignKit.rbox(parent, Vector3(0.11, 0.07, 0.028), at + Vector3(0.07, 0.33, 0.0), ink, 0.02, false)
	for x: float in [-0.075, 0.285]:
		DesignKit.add(parent, _hub(), ink, at + Vector3(x, -0.32, 0.0), Vector3(90.0, 0.0, 0.0), false)


static func _wheel() -> Mesh:
	return DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.023), Vector2(0.063, -0.023), Vector2(0.079, -0.016), Vector2(0.085, -0.007), Vector2(0.085, 0.007), Vector2(0.079, 0.016), Vector2(0.063, 0.023), Vector2(0.0, 0.023)]), 20)


static func _hub() -> Mesh:
	return DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.027), Vector2(0.034, -0.027), Vector2(0.044, -0.021), Vector2(0.044, 0.021), Vector2(0.034, 0.027), Vector2(0.0, 0.027)]), 16)


static func _cart_frame() -> Mesh:
	if _meshes.has("cart_frame"):
		return _meshes["cart_frame"] as Mesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Narrow nose slides inside the next trolley's broad rear frame.
	for side: float in [-1.0, 1.0]:
		_tube(st, PackedVector3Array([Vector3(side * 0.19, 0.23, -0.55), Vector3(side * 0.29, 0.27, 0.34), Vector3(side * 0.29, 0.90, 0.42), Vector3(side * 0.27, 1.02, 0.43), Vector3(side * 0.23, 1.045, 0.43)]), 0.018)
		# Small open wire basket, carried ahead of the handle.
		_tube(st, PackedVector3Array([Vector3(side * 0.23, 0.72, 0.34), Vector3(side * 0.19, 0.72, 0.05), Vector3(side * 0.23, 0.91, 0.02), Vector3(side * 0.27, 0.91, 0.36)]), 0.009)
		for z: float in [0.09, 0.18, 0.27]:
			_tube(st, PackedVector3Array([Vector3(side * 0.20, 0.73, z), Vector3(side * 0.25, 0.90, z)]), 0.004)
		# Twin caster forks and axles, not wheels floating under a deck.
		for fork_side: float in [-1.0, 1.0]:
			_tube(st, PackedVector3Array([Vector3(side * 0.30 + fork_side * 0.031, 0.085, 0.33), Vector3(side * 0.30 + fork_side * 0.031, 0.18, 0.35), Vector3(side * 0.29, 0.24, 0.34)]), 0.009)
	for z: float in [-0.54, -0.34, -0.14, 0.06, 0.27]:
		var half_width: float = lerpf(0.19, 0.29, (z + 0.55) / 0.89)
		_tube(st, PackedVector3Array([Vector3(-half_width, 0.245, z), Vector3(half_width, 0.245, z)]), 0.012)
	for x: float in [-0.12, 0.0, 0.12]:
		_tube(st, PackedVector3Array([Vector3(x, 0.245, -0.54), Vector3(x, 0.245, 0.28)]), 0.008)
	for y: float in [0.73, 0.91]:
		_tube(st, PackedVector3Array([Vector3(-0.23, y, 0.04), Vector3(0.23, y, 0.04)]), 0.009)
	for x: float in [-0.15, -0.075, 0.0, 0.075, 0.15]:
		_tube(st, PackedVector3Array([Vector3(x, 0.73, 0.34), Vector3(x, 0.73, 0.04), Vector3(x, 0.91, 0.02)]), 0.004)
	_tube(st, PackedVector3Array([Vector3(-0.24, 1.045, 0.43), Vector3(0.24, 1.045, 0.43)]), 0.018)
	for fork_side: float in [-1.0, 1.0]:
		_tube(st, PackedVector3Array([Vector3(fork_side * 0.031, 0.085, -0.53), Vector3(fork_side * 0.031, 0.18, -0.50), Vector3(0.0, 0.245, -0.50)]), 0.009)
	var mesh: ArrayMesh = st.commit()
	_meshes["cart_frame"] = mesh
	return mesh


static func _tube(st: SurfaceTool, points: PackedVector3Array, radius: float) -> void:
	# Smooth ring frames share each bend, merging all steel parts into one cached mesh.
	var rings: Array[PackedVector3Array] = []
	var normals: Array[PackedVector3Array] = []
	for i: int in points.size():
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var reference: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		var u: Vector3 = tangent.cross(reference).normalized()
		var v: Vector3 = tangent.cross(u).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		var normal_ring: PackedVector3Array = PackedVector3Array()
		for segment: int in 10:
			var angle: float = TAU * float(segment) / 10.0
			var normal: Vector3 = u * cos(angle) + v * sin(angle)
			ring.append(points[i] + normal * radius)
			normal_ring.append(normal)
		rings.append(ring)
		normals.append(normal_ring)
	for i: int in points.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		var na: PackedVector3Array = normals[i]
		var nb: PackedVector3Array = normals[i + 1]
		for segment: int in 10:
			var next: int = (segment + 1) % 10
			var vertices: PackedVector3Array = PackedVector3Array([a[segment], b[segment], a[next], a[next], b[segment], b[next]])
			var vertex_normals: PackedVector3Array = PackedVector3Array([na[segment], nb[segment], na[next], na[next], nb[segment], nb[next]])
			for vertex_index: int in 6:
				st.set_normal(vertex_normals[vertex_index])
				st.add_vertex(vertices[vertex_index])
	# Close tube ends with small flat discs.
	for endpoint: int in [0, points.size() - 1]:
		var ring: PackedVector3Array = rings[endpoint]
		var normal: Vector3 = (points[0] - points[1]).normalized() if endpoint == 0 else (points[endpoint] - points[endpoint - 1]).normalized()
		for segment: int in 10:
			var next: int = (segment + 1) % 10
			st.set_normal(normal)
			st.add_vertex(points[endpoint])
			st.add_vertex(ring[segment] if endpoint == 0 else ring[next])
			st.add_vertex(ring[next] if endpoint == 0 else ring[segment])
