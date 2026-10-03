extends RefCounted
## A compact, stationary stretch-wrap service with a loaded turntable.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BaggageWrappingStation"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colors: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.LINEN]
	var accent: Color = colors[choice]
	var oak: Material = Kit.wood()
	var walnut: Material = Kit.wood(Kit.WALNUT, "walnut")
	var steel: Material = Kit.metal()
	var brass: Material = Kit.brass()
	var rubber: Material = Kit.paint(Kit.CHARCOAL, 0.95)
	var casing: Material = Kit.paint(accent)
	var pearl: Material = Kit.paint(Color(0.9, 0.93, 0.88), 0.24)
	var film: Material = _film_material()

	# Honed-stone machine bed; the circular platter has a bevel and brass rim.
	Kit.rbox(root, Vector3(1.85, 0.12, 1.55), Vector3(-0.85, 0.06, 0.0), Kit.stone(), 0.055)
	Kit.rbox(root, Vector3(1.72, 0.14, 1.42), Vector3(-0.85, 0.18, 0.0), casing, 0.065)
	_turned(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.67, 0.0), Vector2(0.72, 0.025), Vector2(0.72, 0.055), Vector2(0.68, 0.08), Vector2(0.0, 0.08)]), Vector3(-0.78, 0.25, 0.08), brass)
	_turned(root, PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.65, 0.0), Vector2(0.675, 0.018), Vector2(0.65, 0.04), Vector2(0.0, 0.04)]), Vector3(-0.78, 0.33, 0.08), rubber)
	for x: float in [-1.4, -0.3]:
		Kit.rbox(root, Vector3(0.15, 0.016, 0.065), Vector3(x, 0.261, 0.66), brass, 0.012)

	# Film carriage: a full-height spindle, exposed roll and narrow tension roller.
	Kit.rbox(root, Vector3(0.24, 1.23, 0.28), Vector3(-1.57, 0.865, -0.4), steel, 0.06)
	Kit.rbox(root, Vector3(0.42, 0.085, 0.4), Vector3(-1.48, 0.5, -0.24), casing, 0.035)
	Kit.rbox(root, Vector3(0.42, 0.085, 0.4), Vector3(-1.48, 1.19, -0.24), casing, 0.035)
	_turned(root, _cylinder_profile(0.033, 0.78), Vector3(-1.4, 0.46, -0.2), brass)
	_turned(root, PackedVector2Array([Vector2(0.055, 0.0), Vector2(0.13, 0.0), Vector2(0.15, 0.025), Vector2(0.15, 0.575), Vector2(0.13, 0.6), Vector2(0.055, 0.6), Vector2(0.055, 0.0)]), Vector3(-1.4, 0.545, -0.2), pearl)
	_turned(root, _cylinder_profile(0.053, 0.62), Vector3(-1.4, 0.535, -0.2), Kit.paint(Kit.OAK, 0.85))
	_turned(root, _cylinder_profile(0.027, 0.64), Vector3(-1.24, 0.53, 0.015), steel)
	Kit.add(root, _film_web(), film, Vector3.ZERO, Vector3.ZERO, false)

	# A believable carry-on: wheels, zipped split shell, ribs and an open handle.
	for x: float in [-1.0, -0.56]:
		for z: float in [-0.08, 0.26]:
			_turned(root, _cylinder_profile(0.045, 0.05), Vector3(x - 0.025, 0.414, z), rubber, Vector3(0.0, 0.0, -90.0))
	Kit.rbox(root, Vector3(0.63, 0.76, 0.42), Vector3(-0.78, 0.825, 0.09), rubber, 0.085)
	Kit.rbox(root, Vector3(0.65, 0.75, 0.19), Vector3(-0.78, 0.825, 0.212), casing, 0.075)
	Kit.rbox(root, Vector3(0.65, 0.75, 0.19), Vector3(-0.78, 0.825, -0.032), casing, 0.075)
	for i: int in 4:
		Kit.rbox(root, Vector3(0.023, 0.56, 0.018), Vector3(-1.0 + float(i) * 0.145, 0.82, 0.308), Kit.paint(accent.lightened(0.13)), 0.008)
	for x: float in [-0.9, -0.66]:
		Kit.rbox(root, Vector3(0.03, 0.13, 0.035), Vector3(x, 1.25, 0.08), steel, 0.012)
	Kit.rbox(root, Vector3(0.3, 0.055, 0.065), Vector3(-0.78, 1.305, 0.08), walnut, 0.025)
	Kit.rbox(root, Vector3(0.035, 0.075, 0.022), Vector3(-0.443, 1.02, 0.09), brass, 0.008)
	# Overlapping wrap bands leave the handle and spinner wheels accessible.
	for i: int in 3:
		Kit.rbox(root, Vector3(0.666, 0.205, 0.454), Vector3(-0.78, 0.615 + float(i) * 0.188, 0.09), film, 0.077, false)
		Kit.rbox(root, Vector3(0.51, 0.008, 0.007), Vector3(-0.78, 0.699 + float(i) * 0.188, 0.321), pearl, 0.003, false)

	# Operator controls, sheltered screen, status light and red emergency stop.
	Kit.rbox(root, Vector3(0.32, 0.27, 0.12), Vector3(-1.57, 1.39, -0.245), casing, 0.035)
	Kit.rbox(root, Vector3(0.22, 0.115, 0.018), Vector3(-1.57, 1.43, -0.178), steel, 0.014)
	Kit.rbox(root, Vector3(0.17, 0.06, 0.008), Vector3(-1.57, 1.435, -0.165), Kit.washi(Kit.SAGE, 0.6, "wrap_screen"), 0.01, false)
	_turned(root, _cylinder_profile(0.038, 0.03), Vector3(-1.63, 1.315, -0.17), Kit.paint(Color(0.72, 0.16, 0.12)), Vector3(90.0, 0.0, 0.0))
	Kit.rbox(root, Vector3(0.05, 0.018, 0.012), Vector3(-1.49, 1.325, -0.175), Kit.washi(Kit.SAGE, 1.0, "wrap_ready"), 0.006, false)

	# Oak service counter with a recessed walnut toe-kick and linen inset doors.
	Kit.rbox(root, Vector3(1.24, 0.12, 0.72), Vector3(1.05, 0.06, -0.05), walnut, 0.025)
	Kit.rbox(root, Vector3(1.38, 0.86, 0.84), Vector3(1.05, 0.55, -0.05), oak, 0.055)
	Kit.rbox(root, Vector3(1.5, 0.075, 0.98), Vector3(1.05, 1.0175, -0.025), oak, 0.035)
	Kit.rbox(root, Vector3(1.32, 0.025, 0.015), Vector3(1.05, 0.967, 0.377), brass, 0.006)
	for x: float in [0.72, 1.38]:
		Kit.rbox(root, Vector3(0.59, 0.65, 0.025), Vector3(x, 0.54, 0.38), walnut, 0.025)
		Kit.rbox(root, Vector3(0.53, 0.59, 0.016), Vector3(x, 0.54, 0.398), Kit.fabric(Kit.LINEN), 0.02)
		Kit.rbox(root, Vector3(0.2, 0.026, 0.038), Vector3(x, 0.79, 0.43), brass, 0.012)
	Kit.rbox(root, Vector3(0.32, 0.055, 0.24), Vector3(1.38, 1.083, 0.13), walnut, 0.025)
	var terminal: MeshInstance3D = Kit.rbox(root, Vector3(0.24, 0.16, 0.045), Vector3(1.38, 1.17, 0.14), steel, 0.018)
	terminal.rotation_degrees.x = -22.0
	var display: MeshInstance3D = Kit.rbox(root, Vector3(0.18, 0.1, 0.008), Vector3(1.38, 1.18, 0.173), Kit.washi(Kit.INDIGO, 0.7, "wrap_payment"), 0.01, false)
	display.rotation_degrees.x = -22.0

	# Freestanding walnut price board. Large text is arranged in six languages.
	for x: float in [-1.48, 1.48]:
		Kit.rbox(root, Vector3(0.38, 0.065, 0.5), Vector3(x, 0.0325, -0.68), steel, 0.025)
		Kit.rbox(root, Vector3(0.055, 2.7, 0.055), Vector3(x, 1.415, -0.68), steel, 0.018)
	Kit.rbox(root, Vector3(3.64, 1.7, 0.16), Vector3(0.0, 2.48, -0.68), walnut, 0.07)
	Kit.rbox(root, Vector3(3.48, 1.54, 0.024), Vector3(0.0, 2.48, -0.587), Kit.washi(Kit.CREAM, 0.35, "wrap_board"), 0.045, false)
	Kit.rbox(root, Vector3(3.18, 0.018, 0.016), Vector3(0.0, 2.71, -0.566), brass, 0.006, false)
	_label(root, "BAGGAGE WRAP", Vector3(0.0, 3.015, -0.568), 112, 0.0027)
	_label(root, "USD 15 / BAG", Vector3(0.0, 2.805, -0.568), 100, 0.0027)
	_label(root, "手荷物ラッピング  ·  行李打包", Vector3(0.0, 2.51, -0.568), 72, 0.0027)
	_label(root, "Bọc hành lý", Vector3(0.0, 2.29, -0.568), 72, 0.0027)
	_label(root, "Emballage des bagages", Vector3(0.0, 2.07, -0.568), 72, 0.0027)
	_label(root, "Envoltura de equipaje", Vector3(0.0, 1.85, -0.568), 72, 0.0027)
	# A different top-edge inlay makes even neutral variants easy to distinguish.
	Kit.rbox(root, Vector3(0.34 + float(choice) * 0.16, 0.025, 0.018), Vector3(-1.35 + float(choice) * 0.08, 3.288, -0.59), casing, 0.008, false)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = pixel_size
	label.position = at
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _cylinder_profile(radius: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, 0.0), Vector2(radius * 0.86, 0.0), Vector2(radius, 0.008), Vector2(radius, height - 0.008), Vector2(radius * 0.86, height), Vector2(0.0, height)])


static func _turned(parent: Node3D, profile: PackedVector2Array, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	Kit.add(parent, Kit.lathe(profile, 32), material, at, rotation)


static func _film_material() -> StandardMaterial3D:
	if _materials.has("film"):
		return _materials["film"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.96, 0.94, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.16
	material.metallic = 0.12
	_materials["film"] = material
	return material


static func _film_web() -> ArrayMesh:
	if _meshes.has("web"):
		return _meshes["web"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: PackedVector3Array = PackedVector3Array([
		Vector3(-1.24, 0.555, 0.035), Vector3(-1.24, 1.135, 0.035),
		Vector3(-1.1, 1.135, 0.22), Vector3(-1.1, 0.555, 0.22)])
	var indices: PackedInt32Array = PackedInt32Array([0, 1, 2, 0, 2, 3])
	for index: int in indices:
		st.add_vertex(points[index])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["web"] = mesh
	return mesh
