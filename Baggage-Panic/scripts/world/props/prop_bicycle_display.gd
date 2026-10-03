extends RefCounted
## Static, side-on touring bicycle, presented toward +Z in a small travel gallery.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BicycleTravelDisplay"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colours: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.CREAM]
	var enamel: Material = DesignKit.paint(colours[choice], 0.34)
	var steel: Material = DesignKit.metal()
	var silver: Material = DesignKit.metal(Color(0.66, 0.65, 0.6), 0.28, 0.9, "bicycle_nickel")
	var oak: Material = DesignKit.wood()
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var brass: Material = DesignKit.brass()
	var rubber: Material = DesignKit.paint(Color(0.075, 0.07, 0.065), 0.94)
	var cream: Material = DesignKit.paint(DesignKit.LINEN, 0.86)
	# Recessed bearing skirt, honed bullnose stone, and a separate oak rotating deck.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(1.31, 0), Vector2(1.34, 0.035),
		Vector2(1.34, 0.08), Vector2(0, 0.08)]), 64), steel, Vector3.ZERO)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0, 0.065), Vector2(1.39, 0.065), Vector2(1.45, 0.10),
		Vector2(1.45, 0.18), Vector2(1.41, 0.21), Vector2(0, 0.21)]), 64),
		DesignKit.stone(), Vector3.ZERO)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0, 0.225), Vector2(1.37, 0.225), Vector2(1.39, 0.245),
		Vector2(1.39, 0.26), Vector2(1.37, 0.28), Vector2(0, 0.28)]), 64), oak, Vector3.ZERO)
	DesignKit.add(root, _arc(1.405, 0.008, 0.0, TAU, 96, 1.0), brass,
		Vector3(0, 0.215, 0), Vector3(90, 0, 0), false)
	# The 700 mm wheels sit exactly on the 280 mm deck.
	for x: float in [-0.57, 0.57]:
		var hub: Vector3 = Vector3(x, 0.63, 0)
		DesignKit.add(root, _arc(0.325, 0.025, 0.0, TAU, 64, 1.0), rubber, hub)
		DesignKit.add(root, _arc(0.317, 0.011, 0.0, TAU, 64, 0.5), cream, hub + Vector3(0, 0, 0.024), Vector3.ZERO, false)
		DesignKit.add(root, _arc(0.299, 0.009, 0.0, TAU, 64, 2.4), silver, hub)
		DesignKit.add(root, _spokes(), silver, hub, Vector3.ZERO, false)
		_tube(root, hub + Vector3(0, 0, -0.055), hub + Vector3(0, 0, 0.055), 0.025, silver)
		DesignKit.add(root, _arc(0.367, 0.009, 0.08, PI - 0.08, 40, 4.2), enamel, hub)
		_tube(root, hub + Vector3(0, 0, 0.042), hub + Vector3(-0.31, 0.19, 0.042), 0.005, silver)
		_tube(root, hub + Vector3(0, 0, 0.042), hub + Vector3(0.31, 0.19, 0.042), 0.005, silver)
	var rear: Vector3 = Vector3(-0.57, 0.63, 0)
	var crank: Vector3 = Vector3(-0.08, 0.60, 0)
	var seat: Vector3 = Vector3(-0.27, 1.20, 0)
	var head_top: Vector3 = Vector3(0.42, 1.24, 0)
	var head_low: Vector3 = Vector3(0.46, 1.08, 0)
	_tube(root, crank, seat, 0.021, enamel)
	_tube(root, seat, head_top, 0.021, enamel)
	_tube(root, crank, head_low, 0.024, enamel)
	_tube(root, head_low, head_top, 0.029, enamel)
	for z: float in [-0.045, 0.045]:
		_tube(root, rear + Vector3(0, 0, z), seat + Vector3(0, -0.03, z * 0.4), 0.012, enamel)
		_tube(root, rear + Vector3(0, 0, z), crank + Vector3(0, 0, z), 0.013, enamel)
		_tube(root, head_low + Vector3(0, 0, z), Vector3(0.57, 0.63, z), 0.015, enamel)
	# Nickel lugs and a stitched, gently tapered saddle.
	_tube(root, seat, seat + Vector3(-0.02, 0.13, 0), 0.014, silver)
	DesignKit.rbox(root, Vector3(0.27, 0.055, 0.19), Vector3(-0.33, 1.34, 0), walnut, 0.027)
	DesignKit.rbox(root, Vector3(0.14, 0.04, 0.075), Vector3(-0.16, 1.33, 0), walnut, 0.018)
	DesignKit.rbox(root, Vector3(0.25, 0.009, 0.18), Vector3(-0.33, 1.316, 0), brass, 0.004, false)
	_tube(root, head_top, Vector3(0.38, 1.43, 0), 0.014, silver)
	for z: float in [-0.23, 0.23]:
		_tube(root, Vector3(0.38, 1.43, 0), Vector3(0.38, 1.43, z * 0.7), 0.011, silver)
		_tube(root, Vector3(0.38, 1.43, z * 0.7), Vector3(0.23, 1.40, z), 0.011, silver)
		_tube(root, Vector3(0.23, 1.40, z), Vector3(0.12, 1.40, z), 0.019, walnut)
		_tube(root, Vector3(0.24, 1.38, z * 0.9), Vector3(0.14, 1.365, z * 0.9), 0.006, silver)
	# Bell, warm headlamp, enclosed chain guard, opposite pedals, and a display cradle.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.035, 0), Vector2(0.035, 0.016),
		Vector2(0.027, 0.03), Vector2(0, 0.035)])), brass, Vector3(0.32, 1.44, 0.14))
	_tube(root, Vector3(0.54, 1.07, 0), Vector3(0.64, 1.07, 0), 0.044, silver)
	_tube(root, Vector3(0.64, 1.07, 0), Vector3(0.647, 1.07, 0), 0.037,
		DesignKit.washi(DesignKit.CREAM, 0.7, "bicycle_lamp"))
	DesignKit.rbox(root, Vector3(0.53, 0.13, 0.045), Vector3(-0.31, 0.62, 0.084), enamel, 0.021)
	DesignKit.add(root, _arc(0.078, 0.007, 0, TAU, 32, 1.0), brass, crank + Vector3(0, 0, 0.112), Vector3.ZERO, false)
	for side: float in [-1.0, 1.0]:
		var pedal: Vector3 = crank + Vector3(side * 0.11, -side * 0.09, side * 0.13)
		_tube(root, crank + Vector3(0, 0, side * 0.115), pedal, 0.01, silver)
		DesignKit.rbox(root, Vector3(0.085, 0.025, 0.11), pedal, rubber, 0.009)
	DesignKit.rbox(root, Vector3(0.35, 0.03, 0.35), Vector3(-0.40, 0.295, -0.1), steel, 0.015)
	_tube(root, Vector3(-0.40, 0.31, -0.1), Vector3(-0.30, 0.92, -0.025), 0.014, steel)
	# Open basket: thin horizontal willow courses and vertical binding strips.
	DesignKit.rbox(root, Vector3(0.28, 0.035, 0.34), Vector3(0.66, 1.13, 0), walnut, 0.015)
	for course: int in 5:
		var height: float = 1.17 + float(course) * 0.037
		var width: float = 0.28 + float(course) * 0.014
		DesignKit.rbox(root, Vector3(width, 0.019, 0.016), Vector3(0.66, height, 0.18), oak, 0.007, false)
		DesignKit.rbox(root, Vector3(width, 0.019, 0.016), Vector3(0.66, height, -0.18), oak, 0.007, false)
		for side: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.016, 0.019, 0.36), Vector3(0.66 + side * width * 0.5, height, 0), oak, 0.007, false)
	for x: float in [0.54, 0.66, 0.78]:
		DesignKit.rbox(root, Vector3(0.012, 0.21, 0.014), Vector3(x, 1.24, 0.19), walnut, 0.005, false)
	# Rear carrier supports a linen parcel, or a walnut luggage case.
	DesignKit.rbox(root, Vector3(0.41, 0.025, 0.22), Vector3(-0.62, 1.02, 0), silver, 0.01)
	_tube(root, Vector3(-0.80, 1.02, -0.07), rear + Vector3(0, 0, -0.05), 0.007, silver)
	var luggage: Material = DesignKit.fabric(colours[(choice + 1) % 4], "bicycle_parcel_%d" % choice)
	if choice % 2 == 1:
		luggage = walnut
	DesignKit.rbox(root, Vector3(0.32, 0.15, 0.23), Vector3(-0.65, 1.10, 0), luggage, 0.035)
	for x: float in [-0.74, -0.56]:
		DesignKit.rbox(root, Vector3(0.025, 0.157, 0.237), Vector3(x, 1.10, 0), cream, 0.008, false)
	_poster(root, Vector3(-2.10, 0, -0.50), 12.0, "TOKYO", "東京 · 东京", "Ride & wander", 0, colours[choice])
	_poster(root, Vector3(2.10, 0, -0.50), -12.0, "HÀ NỘI", "Đi và khám phá", "Explore by bicycle", 1, colours[(choice + 1) % 4])
	_poster(root, Vector3(0, 0, -1.18), 0.0, "PARIS", "À vélo", "Viaja en bicicleta", 2, colours[(choice + 2) % 4])
	return root


static func _tube(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var length: float = a.distance_to(b)
	var mesh: Mesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0, -length * 0.5), Vector2(radius * 0.8, -length * 0.5),
		Vector2(radius, -length * 0.5 + minf(radius * 0.3, length * 0.2)),
		Vector2(radius, length * 0.5 - minf(radius * 0.3, length * 0.2)),
		Vector2(radius * 0.8, length * 0.5), Vector2(0, length * 0.5)]), 10)
	var instance: MeshInstance3D = DesignKit.add(parent, mesh, material, (a + b) * 0.5, Vector3.ZERO, false)
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())


static func _arc(radius: float, thickness: float, start: float, finish: float, segments: int, depth: float) -> ArrayMesh:
	var key: String = "arc:%s:%s:%s:%s:%s:%s" % [radius, thickness, start, finish, segments, depth]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in segments:
		for j: int in 8:
			var points: Array[Vector3] = []
			for corner: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var angle: float = lerpf(start, finish, float(corner.x) / float(segments))
				var cross_angle: float = TAU * float(corner.y) / 8.0
				var r: float = radius + thickness * cos(cross_angle)
				points.append(Vector3(r * cos(angle), r * sin(angle), thickness * sin(cross_angle) * depth))
			_quad(st, points[0], points[1], points[2], points[3])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _spokes() -> ArrayMesh:
	if _meshes.has("spokes"):
		return _meshes["spokes"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in 32:
		var angle: float = TAU * float(i) / 32.0
		var a: Vector3 = Vector3(0, 0, 0.025 if i % 2 == 0 else -0.025)
		var b: Vector3 = Vector3(cos(angle) * 0.297, sin(angle) * 0.297, 0)
		var sideways: Vector3 = Vector3(-sin(angle), cos(angle), 0) * 0.0018
		var forward: Vector3 = Vector3(0, 0, 0.0018)
		_quad(st, a - sideways - forward, b - sideways - forward, b + sideways - forward, a + sideways - forward)
		_quad(st, a + sideways + forward, b + sideways + forward, b - sideways + forward, a - sideways + forward)
		_quad(st, a + sideways - forward, b + sideways - forward, b + sideways + forward, a + sideways + forward)
		_quad(st, a - sideways + forward, b - sideways + forward, b - sideways - forward, a - sideways - forward)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["spokes"] = mesh
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point: Vector3 in [a, c, b, a, d, c]:
		st.add_vertex(point)


static func _poster(parent: Node3D, at: Vector3, angle: float, title: String, subtitle: String, invitation: String, scene: int, accent: Color) -> void:
	var stand: Node3D = Node3D.new()
	stand.name = "TravelPoster_%s" % title
	stand.position = at
	stand.rotation_degrees.y = angle
	parent.add_child(stand)
	var wood: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	DesignKit.rbox(stand, Vector3(1.32, 0.09, 0.70), Vector3(0, 0.045, 0), DesignKit.stone(), 0.035)
	for x: float in [-0.56, 0.56]:
		DesignKit.rbox(stand, Vector3(0.045, 0.68, 0.045), Vector3(x, 0.40, 0), DesignKit.brass(), 0.012)
	DesignKit.rbox(stand, Vector3(1.72, 2.34, 0.095), Vector3(0, 1.85, 0), wood, 0.035)
	DesignKit.rbox(stand, Vector3(1.60, 2.22, 0.021), Vector3(0, 1.85, 0.055),
		DesignKit.washi(DesignKit.CREAM, 0.25, "bicycle_poster_paper"), 0.01, false)
	_label(stand, title, Vector3(0, 2.70, 0.077), 0.25, DesignKit.CHARCOAL)
	_label(stand, subtitle, Vector3(0, 2.38, 0.077), 0.18, DesignKit.CHARCOAL)
	_label(stand, invitation, Vector3(0, 0.97, 0.077), 0.16, DesignKit.CHARCOAL)
	# Cut-paper illustration: rising sun and two overlapping, destination-specific skylines.
	var sun: Mesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0, 0), Vector2(0.22, 0), Vector2(0.22, 0.004), Vector2(0, 0.004)]), 40)
	DesignKit.add(stand, sun, DesignKit.paint(DesignKit.OCHRE), Vector3(0.30, 1.97, 0.075), Vector3(90, 0, 0), false)
	DesignKit.add(stand, _landscape(scene, false), DesignKit.paint(accent), Vector3(0, 1.35, 0.085), Vector3.ZERO, false)
	DesignKit.add(stand, _landscape(scene, true), DesignKit.paint(accent.darkened(0.22)), Vector3(0, 1.35, 0.089), Vector3.ZERO, false)


static func _landscape(scene: int, foreground: bool) -> ArrayMesh:
	var key: String = "landscape:%d:%s" % [scene, foreground]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var silhouette: PackedVector2Array
	if foreground:
		silhouette = PackedVector2Array([Vector2(-0.72, -0.17), Vector2(0.72, -0.17), Vector2(0.72, 0.02), Vector2(0.35, 0.12), Vector2(-0.15, -0.01), Vector2(-0.72, 0.10)])
	elif scene == 0:
		silhouette = PackedVector2Array([Vector2(-0.72, -0.17), Vector2(0.72, -0.17), Vector2(0.72, 0.12), Vector2(0.17, 0.70), Vector2(-0.04, 0.48), Vector2(-0.25, 0.57), Vector2(-0.72, 0.04)])
	elif scene == 1:
		silhouette = PackedVector2Array([Vector2(-0.72, -0.17), Vector2(0.72, -0.17), Vector2(0.72, 0.17), Vector2(0.46, 0.24), Vector2(0.31, 0.47), Vector2(0.06, 0.54), Vector2(-0.12, 0.31), Vector2(-0.30, 0.65), Vector2(-0.52, 0.53), Vector2(-0.72, 0.13)])
	else:
		silhouette = PackedVector2Array([Vector2(-0.72, -0.17), Vector2(0.72, -0.17), Vector2(0.72, 0.06), Vector2(0.17, 0.06), Vector2(0.07, 0.39), Vector2(0.025, 0.71), Vector2(-0.025, 0.71), Vector2(-0.07, 0.39), Vector2(-0.17, 0.06), Vector2(-0.72, 0.06)])
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(silhouette)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(0, triangles.size(), 3):
		for offset: int in [0, 2, 1]:
			var p: Vector2 = silhouette[triangles[i + offset]]
			st.set_normal(Vector3.FORWARD * -1.0)
			st.add_vertex(Vector3(p.x, p.y, 0))
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.font_size = 96
	label.pixel_size = height / 96.0
	var width: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, 96).x * label.pixel_size
	if width > 1.43:
		label.pixel_size *= 1.43 / width
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
