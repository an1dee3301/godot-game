extends RefCounted
## A two-metre private family room with a radiused, ribbed oak enclosure.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "NursingPod"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var stone: StandardMaterial3D = DesignKit.stone()
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.15, "nursing_paper")
	# Low, softened stone sill and a continuous shell: an actual hollow room.
	DesignKit.rbox(root, Vector3(2.0, 0.08, 2.0), Vector3(0.0, 0.04, 0.0), stone, 0.038)
	DesignKit.add(root, _shell(), oak, Vector3.ZERO)
	DesignKit.add(root, _ribs(), oak, Vector3.ZERO)
	DesignKit.rbox(root, Vector3(2.0, 0.13, 2.0), Vector3(0.0, 2.535, 0.0), walnut, 0.064)
	DesignKit.rbox(root, Vector3(1.83, 0.045, 1.83), Vector3(0.0, 2.445, 0.0), glow, 0.021, false)
	# Front opening: dark gasket, rebated timber jambs and a recessed privacy door.
	DesignKit.rbox(root, Vector3(1.15, 2.19, 0.055), Vector3(0.0, 1.175, 0.941), steel, 0.027)
	DesignKit.rbox(root, Vector3(1.065, 2.09, 0.07), Vector3(0.0, 1.135, 0.98), DesignKit.paint(accent), 0.034)
	for x: float in [-0.59, 0.59]:
		DesignKit.rbox(root, Vector3(0.085, 2.23, 0.14), Vector3(x, 1.195, 0.925), walnut, 0.025)
	# The transom is luminous but opaque, preserving privacy.
	DesignKit.rbox(root, Vector3(1.11, 0.22, 0.045), Vector3(0.0, 2.295, 0.957), glow, 0.022, false)
	for x: float in [-0.35, 0.0, 0.35]:
		DesignKit.rbox(root, Vector3(0.018, 0.22, 0.022), Vector3(x, 2.295, 0.988), walnut, 0.008, false)
	DesignKit.rbox(root, Vector3(1.30, 0.28, 0.105), Vector3(0.0, 2.435, 1.0), walnut, 0.04)
	_label(root, "Nursing / Family", Vector3(0.0, 2.435, 1.058), 0.145, 1.21, DesignKit.CREAM)
	# A raised universal parent cradling a baby, readable without language.
	DesignKit.rbox(root, Vector3(0.64, 0.61, 0.026), Vector3(0.0, 1.76, 1.027), glow, 0.012, false)
	_disc(root, Vector3(-0.10, 1.935, 1.05), 0.067, steel)
	DesignKit.rbox(root, Vector3(0.115, 0.26, 0.018), Vector3(-0.105, 1.736, 1.05), steel, 0.008, false)
	var arm: MeshInstance3D = DesignKit.rbox(root, Vector3(0.27, 0.054, 0.018), Vector3(0.005, 1.76, 1.063), steel, 0.008, false)
	arm.rotation_degrees.z = -22.0
	_disc(root, Vector3(0.12, 1.837, 1.067), 0.045, steel)
	var infant: MeshInstance3D = DesignKit.rbox(root, Vector3(0.16, 0.07, 0.02), Vector3(0.065, 1.787, 1.067), steel, 0.009, false)
	infant.rotation_degrees.z = 24.0
	DesignKit.rbox(root, Vector3(0.30, 0.058, 0.02), Vector3(0.025, 1.613, 1.052), steel, 0.009, false)
	DesignKit.rbox(root, Vector3(0.058, 0.12, 0.02), Vector3(0.148, 1.559, 1.052), steel, 0.009, false)
	# Full language names on the door; each line has a generous physical text size.
	_label(root, "授乳室", Vector3(0.0, 1.327, 1.02), 0.155, 0.90, DesignKit.CREAM)
	_label(root, "母婴室", Vector3(0.0, 1.125, 1.02), 0.155, 0.90, DesignKit.CREAM)
	_label(root, "Phòng mẹ & bé", Vector3(0.0, 0.932, 1.02), 0.12, 0.95, DesignKit.CREAM)
	_label(root, "Espace famille", Vector3(0.0, 0.754, 1.02), 0.12, 0.95, DesignKit.CREAM)
	_label(root, "Sala familiar", Vector3(0.0, 0.576, 1.02), 0.12, 0.95, DesignKit.CREAM)
	# Edge-mounted pull leaves the graphic and text unobstructed.
	DesignKit.rbox(root, Vector3(0.052, 0.34, 0.042), Vector3(0.451, 1.04, 1.062), brass, 0.018, false)
	for y: float in [0.905, 1.175]:
		DesignKit.rbox(root, Vector3(0.035, 0.032, 0.048), Vector3(0.451, y, 1.031), brass, 0.011, false)
	for y: float in [0.43, 1.9]:
		DesignKit.rbox(root, Vector3(0.023, 0.12, 0.026), Vector3(-0.53, y, 1.013), brass, 0.01, false)
	_disc(root, Vector3(0.70, 1.55, 1.004), 0.046, brass)
	_disc(root, Vector3(0.70, 1.55, 1.02), 0.031, DesignKit.washi(accent.lightened(0.25), 0.75, "pod_status_%d" % choice))
	# Real interior furnishings, sheltered by the closed door.
	DesignKit.rbox(root, Vector3(1.30, 0.34, 0.55), Vector3(0.0, 0.27, -0.57), walnut, 0.065)
	DesignKit.rbox(root, Vector3(1.28, 0.12, 0.57), Vector3(0.0, 0.49, -0.57), DesignKit.fabric(accent, "pod_seat_%d" % choice), 0.055)
	DesignKit.rbox(root, Vector3(1.28, 0.55, 0.12), Vector3(0.0, 0.79, -0.79), DesignKit.fabric(), 0.055)
	DesignKit.rbox(root, Vector3(0.38, 0.06, 0.59), Vector3(0.66, 0.86, 0.12), stone, 0.028)
	var light: OmniLight3D = OmniLight3D.new()
	light.position = Vector3(0.0, 2.19, 0.10)
	light.light_color = Color(1.0, 0.86, 0.68)
	light.light_energy = 0.65
	light.omni_range = 1.9
	light.shadow_enabled = false
	root.add_child(light)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, width: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.font_size = 80
	label.pixel_size = height / 80.0
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 80).x * label.pixel_size
	if measured > width:
		label.pixel_size *= width / measured
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _disc(parent: Node3D, at: Vector3, radius: float, material: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -0.006), Vector2(radius - 0.006, -0.006),
		Vector2(radius, 0.0), Vector2(radius - 0.006, 0.006), Vector2(0.0, 0.006)])
	DesignKit.add(parent, DesignKit.lathe(profile, 24), material, at, Vector3(90.0, 0.0, 0.0), false)


static func _shell() -> ArrayMesh:
	if _meshes.has("shell"):
		return _meshes["shell"] as ArrayMesh
	var outer: PackedVector2Array = PackedVector2Array([Vector2(0.56, 1.0)])
	var inner: PackedVector2Array = PackedVector2Array([Vector2(0.56, 0.88)])
	var centers: Array[Vector2] = [Vector2(0.72, 0.72), Vector2(0.72, -0.72), Vector2(-0.72, -0.72), Vector2(-0.72, 0.72)]
	for corner: int in 4:
		var center: Vector2 = centers[corner]
		for step: int in 13:
			var angle: float = PI * 0.5 - float(corner) * PI * 0.5 - float(step) * PI / 24.0
			var direction: Vector2 = Vector2(cos(angle), sin(angle))
			outer.append(center + direction * 0.28)
			inner.append(center + direction * 0.16)
	outer.append(Vector2(-0.56, 1.0))
	inner.append(Vector2(-0.56, 0.88))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in outer.size() - 1:
		var a: Vector3 = Vector3(outer[i].x, 0.08, outer[i].y)
		var b: Vector3 = Vector3(outer[i + 1].x, 0.08, outer[i + 1].y)
		var c: Vector3 = Vector3(inner[i].x, 0.08, inner[i].y)
		var d: Vector3 = Vector3(inner[i + 1].x, 0.08, inner[i + 1].y)
		var up: Vector3 = Vector3(0.0, 2.39, 0.0)
		var normal: Vector3 = Vector3(-(b.z - a.z), 0.0, b.x - a.x).normalized()
		_quad(st, a, a + up, b + up, b, normal)
		_quad(st, c, d, d + up, c + up, -normal)
		_quad(st, a + up, c + up, d + up, b + up, Vector3.UP)
		_quad(st, a, b, d, c, Vector3.DOWN)
	var mesh: ArrayMesh = st.commit()
	_meshes["shell"] = mesh
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	var vertices: Array[Vector3] = [a, b, c, a, c, d]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		vertices = [a, c, b, a, d, c]
	for vertex: Vector3 in vertices:
		st.set_normal(normal)
		st.set_uv(Vector2(vertex.x + vertex.z, vertex.y))
		st.add_vertex(vertex)


static func _ribs() -> ArrayMesh:
	if _meshes.has("ribs"):
		return _meshes["ribs"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rib: ArrayMesh = DesignKit.rounded_box(Vector3(0.026, 2.29, 0.022), 0.01)
	for i: int in 17:
		var offset: float = -0.66 + float(i) * 0.0825
		st.append_from(rib, 0, Transform3D(Basis.IDENTITY, Vector3(offset, 1.265, -1.002)))
		for side: float in [-1.0, 1.0]:
			st.append_from(rib, 0, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(side * 1.002, 1.265, offset)))
	var mesh: ArrayMesh = st.commit()
	_meshes["ribs"] = mesh
	return mesh
