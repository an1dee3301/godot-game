extends RefCounted
## INTENDED_SCALE = 7.0
## A 45 m airport tower authored at 1:7; every node retains unit scale.
## Floor contact is y = 0; the entrance and radar aperture face +Z.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ControlTower"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.93, 0.70, 0.20), KIT.CLAY, KIT.SAGE, KIT.CHARCOAL]
	var accent: Color = colours[scheme]
	var concrete: StandardMaterial3D = KIT.stone(KIT.LIMESTONE, 0.72, "tower_cast_limestone")
	var steel: StandardMaterial3D = KIT.metal()
	var trim: StandardMaterial3D = KIT.brass()
	var oak: StandardMaterial3D = KIT.wood(KIT.OAK, "tower_oak")
	var walnut: StandardMaterial3D = KIT.wood(KIT.WALNUT, "tower_walnut")
	var paint: StandardMaterial3D = KIT.paint(accent)
	var warm: StandardMaterial3D = KIT.washi(KIT.CREAM, 1.5, "tower_soffit")
	var glass: StandardMaterial3D = _glass()
	# A softened stone podium and low oak-lined entrance pavilion.
	KIT.rbox(root, Vector3(2.95, 0.12, 2.55), Vector3(0.0, 0.06, 0.1), concrete, 0.055)
	KIT.rbox(root, Vector3(2.7, 1.42, 1.45), Vector3(0.0, 0.83, 0.55), concrete, 0.12)
	KIT.rbox(root, Vector3(2.8, 0.08, 1.6), Vector3(0.0, 1.57, 0.55), oak, 0.035)
	KIT.rbox(root, Vector3(2.7, 0.045, 1.5), Vector3(0.0, 1.63, 0.55), paint, 0.018)
	KIT.rbox(root, Vector3(0.55, 0.59, 0.045), Vector3(0.0, 0.415, 1.292), steel, 0.024)
	KIT.rbox(root, Vector3(0.47, 0.5, 0.025), Vector3(0.0, 0.425, 1.321), walnut, 0.012)
	KIT.rbox(root, Vector3(0.21, 0.23, 0.018), Vector3(0.0, 0.51, 1.34), glass, 0.014)
	KIT.rbox(root, Vector3(0.015, 0.15, 0.02), Vector3(0.17, 0.35, 1.346), trim, 0.006)
	for x: float in [-0.42, 0.42]:
		KIT.rbox(root, Vector3(0.085, 0.16, 0.07), Vector3(x, 0.5, 1.31), steel, 0.02)
		KIT.rbox(root, Vector3(0.055, 0.11, 0.02), Vector3(x, 0.5, 1.354), warm, 0.012, false)
	# Tapered cast shaft with a gently curved shoulder supporting the cab.
	_profile(root, PackedVector2Array([
		Vector2(0.0, 0.12), Vector2(0.74, 0.12), Vector2(0.76, 0.18),
		Vector2(0.7, 0.5), Vector2(0.46, 4.43), Vector2(0.49, 4.57),
		Vector2(0.69, 4.72), Vector2(1.16, 4.91), Vector2(1.25, 5.02),
		Vector2(0.0, 5.02)]), concrete, 48)
	# Recess-like horizontal construction joints read as fine shadow lines.
	for i: int in range(1, 7):
		var y: float = 1.1 + float(i) * 0.47
		var radius: float = 0.7 - (y - 0.5) * (0.24 / 3.93) + 0.004
		_ring(root, radius, y, 0.008, KIT.paint(Color(0.63, 0.60, 0.54)), 48)
	KIT.rbox(root, Vector3(0.09, 3.8, 0.055), Vector3(0.0, 2.55, -0.63), steel, 0.018)
	# Twelve outward-raked glass facets; smooth roof and layered warm soffit.
	_ring(root, 1.29, 5.025, 0.075, oak, 48)
	_ring(root, 1.305, 5.09, 0.035, warm, 48)
	_profile(root, PackedVector2Array([
		Vector2(0.0, 5.11), Vector2(1.19, 5.11),
		Vector2(1.43, 5.72), Vector2(0.0, 5.72)]), glass, 12)
	_ring(root, 1.22, 5.13, 0.04, paint, 12)
	_ring(root, 1.445, 5.73, 0.055, steel, 12)
	for i: int in 12:
		var angle: float = TAU * float(i) / 12.0
		var outward: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		_beam(root, outward * 1.195 + Vector3.UP * 5.13,
			outward * 1.435 + Vector3.UP * 5.72, 0.023, steel)
	_profile(root, PackedVector2Array([
		Vector2(0.0, 5.76), Vector2(1.49, 5.76), Vector2(1.52, 5.8),
		Vector2(1.49, 5.85), Vector2(1.22, 5.91), Vector2(0.0, 5.91)]), steel, 48)
	_ring(root, 1.49, 5.8, 0.018, trim, 48)
	# Fixed surveillance radar: pedestal, bearing collar, open framed aperture.
	_profile(root, PackedVector2Array([
		Vector2(0.0, 5.91), Vector2(0.19, 5.91), Vector2(0.19, 5.97),
		Vector2(0.08, 5.99), Vector2(0.08, 6.14), Vector2(0.0, 6.14)]), steel, 24)
	_ring(root, 0.115, 6.09, 0.05, trim, 24)
	KIT.rbox(root, Vector3(1.32, 0.29, 0.07), Vector3(0.0, 6.23, 0.0), steel, 0.033)
	KIT.rbox(root, Vector3(1.23, 0.21, 0.025), Vector3(0.0, 6.23, 0.046), KIT.paint(KIT.LINEN), 0.025)
	for i: int in 9:
		KIT.rbox(root, Vector3(0.017, 0.21, 0.027), Vector3(-0.56 + float(i) * 0.14, 6.23, 0.064), steel, 0.006)
	KIT.rbox(root, Vector3(1.23, 0.017, 0.027), Vector3(0.0, 6.23, 0.068), trim, 0.006)
	# The obstruction mast defines exactly 45 / 7 metres of total height.
	_beam(root, Vector3(0.62, 5.9, -0.4), Vector3(0.62, 6.38, -0.4), 0.025, steel)
	_profile(root, PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.041, 0.0), Vector2(0.045, 0.015),
		Vector2(0.035, 0.039), Vector2(0.0, 0.048571)]),
		KIT.washi(Color(1.0, 0.22, 0.08), 3.0, "tower_obstruction"), 16, Vector3(0.62, 6.38, -0.4))
	# A proper entrance identity sign: four substantial lines in six languages.
	KIT.rbox(root, Vector3(2.48, 0.77, 0.055), Vector3(0.0, 1.13, 1.297), steel, 0.032)
	KIT.rbox(root, Vector3(2.34, 0.016, 0.012), Vector3(0.0, 1.473, 1.331), trim, 0.005, false)
	_caption(root, "CONTROL TOWER", 1.38, 0.17, KIT.CREAM)
	_caption(root, "管制塔 · 控制塔", 1.20, 0.15, KIT.CREAM)
	_caption(root, "Đài kiểm soát", 1.02, 0.14, KIT.LINEN)
	_caption(root, "Tour de contrôle · Torre de control", 0.84, 0.14, KIT.LINEN)
	return root


static func _profile(parent: Node3D, points: PackedVector2Array, material: Material, segments: int, at: Vector3 = Vector3.ZERO) -> void:
	KIT.add(parent, KIT.lathe(points, segments), material, at)


static func _ring(parent: Node3D, radius: float, y: float, height: float, material: Material, segments: int) -> void:
	_profile(parent, PackedVector2Array([
		Vector2(radius - 0.025, y), Vector2(radius, y),
		Vector2(radius, y + height), Vector2(radius - 0.025, y + height),
		Vector2(radius - 0.025, y)]), material, segments)


static func _beam(parent: Node3D, start: Vector3, end: Vector3, width: float, material: Material) -> void:
	var beam: MeshInstance3D = KIT.rbox(parent, Vector3(width, start.distance_to(end), width), (start + end) * 0.5, material, width * 0.3)
	beam.quaternion = Quaternion(Vector3.UP, (end - start).normalized())


static func _caption(parent: Node3D, caption: String, y: float, height: float, colour: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = SIGNS.font()
	label.text = caption
	label.font_size = 64
	var measured: Vector2 = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 64)
	label.pixel_size = minf(height / label.font.get_height(64), 2.3 / maxf(measured.x, 1.0))
	label.position = Vector3(0.0, y, 1.333)
	label.modulate = colour
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("cab_glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.075, 0.14, 0.16)
		material.metallic = 0.32
		material.roughness = 0.16
		_materials["cab_glass"] = material
	return _materials["cab_glass"] as StandardMaterial3D
