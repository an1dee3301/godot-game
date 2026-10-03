extends RefCounted
## Eight-metre panoramic lift; local +Z is the landing entrance.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GlassElevator"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[style]
	var timber: Material = DesignKit.wood(DesignKit.OAK if style % 2 == 0 else DesignKit.WALNUT, "lift_oak" if style % 2 == 0 else "lift_walnut")
	var brass: Material = DesignKit.brass()
	var steel: Material = DesignKit.metal()
	var stone: Material = DesignKit.stone()
	var glow: Material = DesignKit.washi(DesignKit.CREAM, 1.4, "lift_ceiling")
	var glass: Material = _glass(style)
	# The turned plinth has a rounded lip and a recessed brass kick band.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.96, 0.0), Vector2(2.02, 0.03),
		Vector2(2.04, 0.07), Vector2(2.04, 0.13), Vector2(2.01, 0.17),
		Vector2(1.96, 0.19), Vector2(0.0, 0.19)
	]), 64), stone, Vector3.ZERO)
	_ring(root, 2.035, 0.085, 0.035, 0.025, brass)
	# Lower glass leaves a genuine landing doorway; upper glass continues to the crown.
	DesignKit.add(root, _arc(1.92, 0.23, 2.98, 36.0, 324.0), glass, Vector3.ZERO, Vector3.ZERO, false)
	DesignKit.add(root, _arc(1.92, 3.02, 7.78, 0.0, 360.0), glass, Vector3.ZERO, Vector3.ZERO, false)
	for height: float in [0.24, 3.0, 5.45, 7.8]:
		_ring(root, 1.94, height, 0.095, 0.055, brass)
	# Eight continuous mullions; the two front mullions flank the doorway.
	for angle: float in [36.0, 72.0, 108.0, 144.0, 180.0, 216.0, 252.0, 288.0, 324.0]:
		var radians: float = deg_to_rad(angle)
		var upright: MeshInstance3D = DesignKit.rbox(root, Vector3(0.065, 7.48, 0.085), Vector3(sin(radians) * 1.92, 4.02, cos(radians) * 1.92), steel, 0.018)
		upright.rotation_degrees.y = angle
	# Rear guide rails and the visible overhead service housing explain the mechanism.
	for x: float in [-0.55, 0.55]:
		DesignKit.rbox(root, Vector3(0.085, 7.36, 0.10), Vector3(x, 3.98, -1.72), steel, 0.018)
	DesignKit.rbox(root, Vector3(1.5, 0.34, 0.64), Vector3(0.0, 7.52, -0.82), steel, 0.08)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 7.84), Vector2(1.91, 7.84), Vector2(1.98, 7.87),
		Vector2(2.0, 7.92), Vector2(1.98, 7.97), Vector2(1.92, 8.0), Vector2(0.0, 8.0)
	]), 64), timber, Vector3.ZERO)
	# Cabin resting at the landing, with a stone floor and oak skirt/ceiling.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.19), Vector2(1.58, 0.19), Vector2(1.62, 0.22),
		Vector2(1.62, 0.28), Vector2(1.58, 0.31), Vector2(0.0, 0.31)
	]), 48), stone, Vector3.ZERO)
	_ring(root, 1.59, 0.34, 0.10, 0.05, timber)
	DesignKit.add(root, _arc(1.57, 0.39, 0.95, 43.0, 317.0), timber, Vector3.ZERO)
	DesignKit.add(root, _arc(1.57, 0.95, 2.64, 43.0, 317.0), glass, Vector3.ZERO, Vector3.ZERO, false)
	_ring(root, 1.60, 2.68, 0.14, 0.085, timber)
	_ring(root, 1.55, 2.57, 0.055, 0.035, glow)
	# A curved waist-height brass rail, ending before the door.
	DesignKit.add(root, _arc(1.45, 1.03, 1.075, 52.0, 308.0), brass, Vector3.ZERO)
	for angle: float in [65.0, 145.0, 215.0, 295.0]:
		var radians: float = deg_to_rad(angle)
		var support: MeshInstance3D = DesignKit.rbox(root, Vector3(0.035, 0.035, 0.14), Vector3(sin(radians) * 1.51, 1.05, cos(radians) * 1.51), steel, 0.012, false)
		support.rotation_degrees.y = angle
	# Landing surround, centre-opening glazed leaves, gasket seams and sill grooves.
	for x: float in [-1.08, 1.08]:
		DesignKit.rbox(root, Vector3(0.12, 2.51, 0.14), Vector3(x, 1.565, 1.56), timber, 0.035)
		DesignKit.rbox(root, Vector3(0.025, 2.39, 0.03), Vector3(x, 1.565, 1.65), brass, 0.009, false)
	DesignKit.rbox(root, Vector3(2.28, 0.19, 0.20), Vector3(0.0, 2.80, 1.56), timber, 0.05)
	DesignKit.rbox(root, Vector3(2.15, 0.045, 0.34), Vector3(0.0, 0.305, 1.62), brass, 0.012)
	for z: float in [1.54, 1.65, 1.75]:
		DesignKit.rbox(root, Vector3(2.04, 0.006, 0.014), Vector3(0.0, 0.331, z), steel, 0.002, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.98, 2.30, 0.035), Vector3(side * 0.505, 1.51, 1.59), glass, 0.01, false)
		DesignKit.rbox(root, Vector3(0.032, 2.30, 0.055), Vector3(side * 0.015, 1.51, 1.61), steel, 0.009)
		DesignKit.rbox(root, Vector3(0.032, 2.30, 0.055), Vector3(side * 1.0, 1.51, 1.61), brass, 0.009)
		DesignKit.rbox(root, Vector3(0.93, 0.09, 0.045), Vector3(side * 0.505, 1.08, 1.625), DesignKit.paint(accent), 0.018, false)
	# Broad, readable wayfinding above the landing, with six languages.
	DesignKit.rbox(root, Vector3(4.15, 1.54, 0.16), Vector3(0.0, 3.74, 1.98), steel, 0.09)
	DesignKit.rbox(root, Vector3(3.91, 0.035, 0.025), Vector3(0.0, 4.39, 2.075), brass, 0.011, false)
	_label(root, "ELEVATOR  ↕", Vector3(0.0, 4.14, 2.075), 110, 0.0032, DesignKit.CREAM)
	_label(root, "エレベーター  ·  电梯", Vector3(0.0, 3.77, 2.075), 72, 0.0032, DesignKit.CREAM)
	_label(root, "Thang máy", Vector3(0.0, 3.47, 2.075), 70, 0.0032, DesignKit.CREAM)
	_label(root, "Ascenseur  ·  Ascensor", Vector3(0.0, 3.17, 2.075), 70, 0.0032, DesignKit.CREAM)
	# Call station remains at reachable height; no miniature text labels.
	DesignKit.rbox(root, Vector3(0.42, 1.12, 0.13), Vector3(1.46, 1.18, 1.69), timber, 0.06)
	DesignKit.rbox(root, Vector3(0.33, 0.99, 0.035), Vector3(1.46, 1.18, 1.775), brass, 0.035, false)
	DesignKit.rbox(root, Vector3(0.27, 0.26, 0.025), Vector3(1.46, 1.49, 1.802), steel, 0.025, false)
	_label(root, "01" if style < 2 else "02", Vector3(1.46, 1.49, 1.819), 76, 0.0026, DesignKit.CREAM)
	for index: int in 2:
		var y: float = 1.15 - float(index) * 0.28
		DesignKit.add(root, _button(), brass, Vector3(1.46, y, 1.81), Vector3(90.0, 0.0, 0.0), false)
		DesignKit.add(root, _button(), glow if index == style % 2 else steel, Vector3(1.46, y, 1.825), Vector3(90.0, 0.0, 0.0), false).scale = Vector3(0.69, 0.6, 0.69)
		_label(root, "▲" if index == 0 else "▼", Vector3(1.46, y, 1.843), 52, 0.002, DesignKit.CREAM)
	return root


static func _ring(parent: Node3D, radius: float, y: float, height: float, depth: float, material: Material) -> void:
	var half: float = height * 0.5
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(radius - depth, -half * 0.65), Vector2(radius - depth * 0.7, -half),
		Vector2(radius + depth * 0.7, -half), Vector2(radius + depth, -half * 0.65),
		Vector2(radius + depth, half * 0.65), Vector2(radius + depth * 0.7, half),
		Vector2(radius - depth * 0.7, half), Vector2(radius - depth, half * 0.65),
		Vector2(radius - depth, -half * 0.65)
	])
	DesignKit.add(parent, DesignKit.lathe(profile, 64), material, Vector3(0.0, y, 0.0))


static func _arc(radius: float, bottom: float, top: float, start: float, end: float) -> ArrayMesh:
	var key: String = "arc:%s:%s:%s:%s:%s" % [radius, bottom, top, start, end]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = maxi(8, int((end - start) / 5.0))
	for index: int in segments:
		var a: float = deg_to_rad(lerpf(start, end, float(index) / float(segments)))
		var b: float = deg_to_rad(lerpf(start, end, float(index + 1) / float(segments)))
		var points: Array[Vector2] = [Vector2(a, bottom), Vector2(a, top), Vector2(b, bottom), Vector2(b, bottom), Vector2(a, top), Vector2(b, top)]
		for point: Vector2 in points:
			st.set_normal(Vector3(sin(point.x), 0.0, cos(point.x)))
			st.set_uv(Vector2(point.x * radius, point.y))
			st.add_vertex(Vector3(sin(point.x) * radius, point.y, cos(point.x) * radius))
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _glass(style: int) -> StandardMaterial3D:
	var key: String = "glass:%d" % style
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.73, 0.87, 0.83, 0.16) if style % 2 == 0 else Color(0.88, 0.86, 0.78, 0.17)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.12
	material.metallic = 0.08
	_materials[key] = material
	return material


static func _button() -> ArrayMesh:
	if _meshes.has("button"):
		return _meshes["button"] as ArrayMesh
	var mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.012), Vector2(0.084, -0.012), Vector2(0.094, -0.005),
		Vector2(0.094, 0.006), Vector2(0.084, 0.012), Vector2(0.0, 0.012)
	]), 24)
	_meshes["button"] = mesh
	return mesh


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_size: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
