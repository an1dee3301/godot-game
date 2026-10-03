extends RefCounted
## Two end-entry berths: moulded shells, oak joinery and sliding privacy doors.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SleepPods"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "sleep_pod_walnut")
	var shell: StandardMaterial3D = DesignKit.paint(Color(0.96, 0.95, 0.91), 0.32)
	var steel: StandardMaterial3D = DesignKit.metal()
	var linen: StandardMaterial3D = DesignKit.fabric()
	var upholstery: StandardMaterial3D = DesignKit.fabric(accent, "sleep_pod_%d" % choice)
	var glow: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.79, 0.49), 1.8, "sleep_pod_light")
	DesignKit.rbox(root, Vector3(2.95, 0.16, 2.55), Vector3(0.0, 0.08, 0.0), DesignKit.stone(), 0.07)
	DesignKit.rbox(root, Vector3(2.65, 0.08, 2.3), Vector3(-0.05, 0.2, 0.0), walnut, 0.035)
	# Four continuous oak posts and three mortised cross rails support the capsules.
	for x: float in [-1.19, 0.77]:
		for z: float in [-1.12, 1.12]:
			DesignKit.rbox(root, Vector3(0.13, 2.68, 0.13), Vector3(x, 1.56, z), oak, 0.035)
	for y: float in [0.26, 1.61, 2.94]:
		for z: float in [-1.12, 1.12]:
			DesignKit.rbox(root, Vector3(2.06, 0.12, 0.16), Vector3(-0.21, y, z), oak, 0.035)
	for berth: int in 2:
		var cy: float = 0.89 + float(berth) * 1.35
		DesignKit.add(root, _capsule_shell(), shell, Vector3(-0.21, cy, 0.0))
		DesignKit.rbox(root, Vector3(1.46, 1.04, 0.1), Vector3(-0.21, cy, -1.08), oak, 0.2)
		DesignKit.rbox(root, Vector3(1.36, 0.11, 2.03), Vector3(-0.21, cy - 0.4, -0.025), linen, 0.052)
		DesignKit.rbox(root, Vector3(1.24, 0.045, 0.68), Vector3(-0.21, cy - 0.322, 0.49), upholstery, 0.02)
		DesignKit.rbox(root, Vector3(0.72, 0.15, 0.4), Vector3(-0.21, cy - 0.27, -0.73), linen, 0.07)
		# Recessed warm ceiling light washes the pillow; no unbounded terminal lighting.
		DesignKit.rbox(root, Vector3(1.08, 0.04, 0.1), Vector3(-0.21, cy + 0.46, -0.3), glow, 0.019, false)
		var light: OmniLight3D = OmniLight3D.new()
		light.position = Vector3(-0.21, cy + 0.28, -0.25)
		light.light_color = Color(1.0, 0.78, 0.51)
		light.light_energy = 0.55
		light.omni_range = 1.35
		light.shadow_enabled = false
		root.add_child(light)
		# A partially slid door leaves a generous view into the berth on its left.
		DesignKit.rbox(root, Vector3(0.67, 1.03, 0.065), Vector3(0.14, cy, 1.17), shell, 0.13)
		DesignKit.rbox(root, Vector3(0.58, 0.018, 0.015), Vector3(0.14, cy - 0.36, 1.209), DesignKit.brass(), 0.007, false)
		DesignKit.rbox(root, Vector3(0.06, 0.24, 0.035), Vector3(-0.085, cy - 0.1, 1.224), steel, 0.018, false)
		DesignKit.rbox(root, Vector3(0.026, 0.18, 0.065), Vector3(-0.085, cy - 0.1, 1.255), DesignKit.brass(), 0.012, false)
		_label(root, "%02d" % (choice * 2 + berth + 1), Vector3(0.15, cy + 0.22, 1.209), 140, 0.003, DesignKit.CHARCOAL)
		DesignKit.rbox(root, Vector3(0.13, 0.055, 0.018), Vector3(0.25, cy - 0.16, 1.214), DesignKit.washi(accent.lightened(0.25), 0.7, "sleep_status_%d" % choice), 0.02, false)
		# Dark slide tracks and a walnut threshold articulate the entry opening.
		DesignKit.rbox(root, Vector3(1.3, 0.028, 0.035), Vector3(-0.21, cy + 0.47, 1.13), steel, 0.012, false)
		DesignKit.rbox(root, Vector3(1.3, 0.055, 0.19), Vector3(-0.21, cy - 0.5, 1.14), walnut, 0.022)
		for slot: int in 4:
			DesignKit.rbox(root, Vector3(0.15, 0.015, 0.017), Vector3(-0.74, cy + 0.23 + float(slot) * 0.05, 1.136), steel, 0.006, false)
	# Steep ship-style access steps occupy their own narrow bay beside the upper berth.
	for x: float in [0.94, 1.4]:
		DesignKit.add(root, DesignKit.rounded_box(Vector3(0.055, 2.07, 0.065), 0.02), steel, Vector3(x, 1.16, 1.36), Vector3(-12.0, 0.0, 0.0))
		DesignKit.rbox(root, Vector3(0.05, 0.48, 0.055), Vector3(x, 2.13, 1.14), DesignKit.brass(), 0.024)
	for step: int in 5:
		var sy: float = 0.34 + float(step) * 0.3
		var sz: float = 1.53 - float(step) * 0.063
		DesignKit.rbox(root, Vector3(0.51, 0.06, 0.22), Vector3(1.17, sy, sz), oak, 0.025)
		DesignKit.rbox(root, Vector3(0.41, 0.009, 0.035), Vector3(1.17, sy + 0.034, sz + 0.055), steel, 0.004, false)
	# Large, three-line international identification on a softly edged washi fascia.
	DesignKit.rbox(root, Vector3(3.35, 0.9, 0.15), Vector3(0.0, 3.43, 1.13), oak, 0.09)
	DesignKit.rbox(root, Vector3(3.17, 0.73, 0.025), Vector3(0.0, 3.43, 1.22), DesignKit.washi(DesignKit.CREAM, 0.45, "sleep_fascia"), 0.065, false)
	_label(root, "Sleep pods", Vector3(0.0, 3.65, 1.24), 108, 0.003, DesignKit.CHARCOAL)
	_label(root, "睡眠ポッド · 睡眠舱", Vector3(0.0, 3.41, 1.24), 72, 0.003, DesignKit.CHARCOAL)
	_label(root, "Buồng ngủ · Repos · Descanso", Vector3(0.0, 3.19, 1.24), 64, 0.003, DesignKit.CHARCOAL)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixels: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixels
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _contour(half: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var center: Vector2 = Vector2(half.x - radius, half.y - radius)
		if corner == 1 or corner == 2:
			center.x = -center.x
		if corner == 2 or corner == 3:
			center.y = -center.y
		for segment: int in 9:
			var a: float = angle + float(segment) * PI / 16.0
			points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points


static func _capsule_shell() -> ArrayMesh:
	if _meshes.has("capsule"):
		return _meshes["capsule"] as ArrayMesh
	var outside: PackedVector2Array = _contour(Vector2(0.82, 0.6), 0.26)
	var inside: PackedVector2Array = _contour(Vector2(0.755, 0.535), 0.195)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in outside.size():
		var j: int = (i + 1) % outside.size()
		var a: Vector2 = outside[i]
		var b: Vector2 = outside[j]
		var c: Vector2 = inside[i]
		var d: Vector2 = inside[j]
		var outward: Vector3 = Vector3(b.y - a.y, a.x - b.x, 0.0).normalized()
		_quad(st, Vector3(a.x, a.y, -1.13), Vector3(b.x, b.y, -1.13), Vector3(b.x, b.y, 1.13), Vector3(a.x, a.y, 1.13), outward)
		_quad(st, Vector3(c.x, c.y, -1.13), Vector3(d.x, d.y, -1.13), Vector3(d.x, d.y, 1.13), Vector3(c.x, c.y, 1.13), -outward)
		for end: float in [-1.0, 1.0]:
			var z: float = end * 1.13
			_quad(st, Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(d.x, d.y, z), Vector3(c.x, c.y, z), Vector3(0.0, 0.0, end))
	var mesh: ArrayMesh = st.commit()
	_meshes["capsule"] = mesh
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c, d]
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
	for index: int in order:
		var vertex: Vector3 = vertices[index]
		st.set_normal(normal)
		st.set_uv(Vector2(vertex.x + vertex.z, vertex.y))
		st.add_vertex(vertex)
