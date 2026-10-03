extends RefCounted
## A compact, open-front tea atelier. Metres; customer side is +Z.

const DK = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TeaShop"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DK.SAGE, DK.CLAY, DK.INDIGO, DK.OCHRE]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DK.wood()
	var walnut: StandardMaterial3D = DK.wood(DK.WALNUT, "tea_walnut")
	var stone: StandardMaterial3D = DK.stone()
	var iron: StandardMaterial3D = DK.metal(DK.CHARCOAL, 0.82, 0.65, "tea_cast_iron")
	var brass: StandardMaterial3D = DK.brass()
	var enamel: StandardMaterial3D = DK.paint(accent, 0.4)
	var paper: StandardMaterial3D = DK.washi(DK.CREAM, 0.65, "tea_paper")

	# Recessed walnut plinth, limestone threshold, oak frame with exposed joints.
	DK.rbox(root, Vector3(4.7, 0.08, 2.65), Vector3(0.0, 0.04, -0.08), stone, 0.035)
	DK.rbox(root, Vector3(4.42, 0.16, 0.6), Vector3(0.0, 0.16, -1.02), walnut, 0.04)
	DK.rbox(root, Vector3(4.34, 2.55, 0.09), Vector3(0.0, 1.55, -1.29), DK.fabric(DK.LINEN, "tea_linen"), 0.035)
	for x: float in [-2.2, 2.2]:
		DK.rbox(root, Vector3(0.14, 3.4, 0.16), Vector3(x, 1.78, -1.12), oak, 0.035)
		DK.rbox(root, Vector3(0.18, 0.08, 0.2), Vector3(x, 0.12, -1.12), brass, 0.015)
		DK.rbox(root, Vector3(0.12, 0.08, 2.3), Vector3(x, 3.37, -0.05), oak, 0.025)
	DK.rbox(root, Vector3(4.65, 0.17, 0.26), Vector3(0.0, 3.42, -1.12), oak, 0.05)
	DK.rbox(root, Vector3(4.65, 0.13, 0.22), Vector3(0.0, 3.37, 1.04), oak, 0.045)
	# Four generous shelf levels, with warm continuous lighting tucked under the lips.
	for level: int in 4:
		var shelf_y: float = 0.38 + float(level) * 0.66
		DK.rbox(root, Vector3(4.3, 0.075, 0.51), Vector3(0.0, shelf_y, -1.01), oak, 0.025)
		if level > 0:
			DK.rbox(root, Vector3(4.1, 0.018, 0.025), Vector3(0.0, shelf_y - 0.042, -0.81), paper, 0.006, false)
		if level < 3:
			for column: int in 4:
				var tint: Color = accent if (column + level + choice) % 3 != 0 else DK.CREAM
				_tin(root, Vector3(-1.53 + float(column) * 1.02, shelf_y + 0.038, -0.98), DK.paint(tint, 0.43), brass)

	# A limestone tasting ledge on rounded oak cabinetry, with inset coloured fronts.
	DK.rbox(root, Vector3(4.35, 0.13, 0.84), Vector3(0.0, 0.145, 0.67), walnut, 0.045)
	DK.rbox(root, Vector3(4.4, 0.83, 0.87), Vector3(0.0, 0.58, 0.67), oak, 0.075)
	for side: float in [-1.0, 1.0]:
		DK.rbox(root, Vector3(1.94, 0.64, 0.045), Vector3(side * 1.055, 0.59, 1.119), enamel, 0.06)
		DK.rbox(root, Vector3(0.36, 0.026, 0.055), Vector3(side * 1.055, 0.86, 1.155), brass, 0.012)
	DK.rbox(root, Vector3(4.62, 0.105, 1.05), Vector3(0.0, 1.048, 0.68), stone, 0.05)
	DK.rbox(root, Vector3(4.39, 0.02, 0.035), Vector3(0.0, 0.98, 1.12), brass, 0.009, false)
	# Three distinct service trays: squat tetsubin, removable lids and open tasting bowls.
	for station: int in 3:
		var x: float = -1.36 + float(station) * 1.36
		var tray_z: float = 0.68 + (0.045 if choice % 2 == 1 and station == 1 else 0.0)
		DK.rbox(root, Vector3(0.98, 0.035, 0.68), Vector3(x, 1.118, tray_z), walnut, 0.07)
		DK.rbox(root, Vector3(0.88, 0.014, 0.58), Vector3(x, 1.14, tray_z), DK.fabric(DK.LINEN, "tea_linen"), 0.045, false)
		_teapot(root, Vector3(x - 0.15, 1.147, tray_z - 0.09), iron, walnut, station % 2 == 0)
		for cup: int in 2:
			DK.add(root, _bowl(), DK.stone(DK.CREAM, 0.24, "tea_glaze"), Vector3(x + 0.3, 1.148, tray_z - 0.15 + float(cup) * 0.29))

	# A suspended framed washi sign; separate typography keeps the main name very large.
	for x: float in [-1.6, 1.6]:
		DK.rbox(root, Vector3(0.018, 0.44, 0.018), Vector3(x, 3.08, 0.95), iron, 0.007, false)
	DK.rbox(root, Vector3(4.12, 0.89, 0.14), Vector3(0.0, 2.78, 0.95), walnut, 0.065)
	DK.rbox(root, Vector3(3.96, 0.73, 0.035), Vector3(0.0, 2.78, 1.027), paper, 0.045, false)
	_label(root, "TEA 茶", Vector3(0.0, 2.9, 1.051), 180, 0.0034, DK.CHARCOAL)
	_label(root, "Trà · Thé · Té", Vector3(0.0, 2.54, 1.052), 72, 0.0031, DK.CHARCOAL)
	return root


static func _tin(parent: Node3D, at: Vector3, enamel: Material, brass: Material) -> void:
	var body: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.155, 0.0), Vector2(0.18, 0.025),
		Vector2(0.18, 0.39), Vector2(0.165, 0.41), Vector2(0.0, 0.41)]), 24)
	var lid: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.185, 0.0), Vector2(0.19, 0.018),
		Vector2(0.175, 0.037), Vector2(0.0, 0.037)]), 24)
	DK.add(parent, body, enamel, at)
	DK.add(parent, lid, brass, at + Vector3(0.0, 0.401, 0.0), Vector3.ZERO, false)
	# Blank embossed lozenge, a physical detail rather than unreadably small text.
	DK.rbox(parent, Vector3(0.11, 0.14, 0.018), at + Vector3(0.0, 0.22, 0.179), brass, 0.045, false)


static func _teapot(parent: Node3D, at: Vector3, iron: Material, grip: Material, reverse: bool) -> void:
	var body: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.17, 0.035),
		Vector2(0.205, 0.095), Vector2(0.2, 0.16), Vector2(0.165, 0.215),
		Vector2(0.11, 0.235), Vector2(0.0, 0.235)]), 32)
	var lid: ArrayMesh = DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.13, 0.014),
		Vector2(0.09, 0.035), Vector2(0.025, 0.045), Vector2(0.027, 0.07),
		Vector2(0.015, 0.083), Vector2(0.0, 0.083)]), 24)
	DK.add(parent, body, iron, at)
	DK.add(parent, lid, iron, at + Vector3(0.0, 0.227, 0.0))
	var handle_points: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	for step: int in 17:
		var angle: float = PI * float(step) / 16.0
		handle_points.append(Vector3(cos(angle) * 0.185, 0.19 + sin(angle) * 0.29, 0.0))
		radii.append(0.018)
	DK.add(parent, _tube("pot_handle", handle_points, radii), iron, at)
	DK.rbox(parent, Vector3(0.13, 0.039, 0.046), at + Vector3(0.0, 0.478, 0.0), grip, 0.018, false)
	var spout: PackedVector3Array = PackedVector3Array([
		Vector3(0.15, 0.095, 0.0), Vector3(0.24, 0.14, 0.0),
		Vector3(0.3, 0.225, 0.0), Vector3(0.345, 0.255, 0.0)])
	var facing: Vector3 = Vector3(0.0, 180.0 if reverse else 0.0, 0.0)
	DK.add(parent, _tube("pot_spout", spout, PackedFloat32Array([0.055, 0.043, 0.032, 0.029])), iron, at, facing)


static func _bowl() -> ArrayMesh:
	return DK.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.05, 0.013),
		Vector2(0.08, 0.025), Vector2(0.092, 0.075), Vector2(0.088, 0.083),
		Vector2(0.08, 0.078), Vector2(0.068, 0.034), Vector2(0.0, 0.022)]), 24)


static func _tube(key: String, points: PackedVector3Array, radii: PackedFloat32Array) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i: int in points.size():
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var normal: Vector3 = Vector3.FORWARD
		var across: Vector3 = tangent.cross(normal).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for side: int in 12:
			var angle: float = TAU * float(side) / 12.0
			ring.append(points[i] + (normal * cos(angle) + across * sin(angle)) * radii[i])
		rings.append(ring)
	for i: int in points.size() - 1:
		var lower: PackedVector3Array = rings[i]
		var upper: PackedVector3Array = rings[i + 1]
		for side: int in 12:
			var next: int = (side + 1) % 12
			var vertices: PackedVector3Array = PackedVector3Array([lower[side], upper[side], lower[next], lower[next], upper[side], upper[next]])
			for vertex: Vector3 in vertices:
				tool.add_vertex(vertex)
	tool.generate_normals()
	var mesh: ArrayMesh = tool.commit()
	_meshes[key] = mesh
	return mesh


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = SIGNS.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
