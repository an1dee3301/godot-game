extends RefCounted
## A freestanding medical point, facing +Z. All dimensions are metres.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FirstAidStation"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var cushions: Array[Color] = [Kit.SAGE, Kit.LINEN, Kit.CLAY, Kit.INDIGO]
	var green: StandardMaterial3D = Kit.paint(Color(0.12, 0.43, 0.29), 0.48)
	var white: StandardMaterial3D = Kit.paint(Color(0.96, 0.96, 0.91), 0.4)
	var timber: StandardMaterial3D = Kit.wood(Kit.OAK if choice % 2 == 0 else Kit.WALNUT, "aid_timber_%d" % (choice % 2))
	var steel: StandardMaterial3D = Kit.metal()
	var trim: StandardMaterial3D = Kit.brass() if choice < 2 else steel
	var linen: StandardMaterial3D = Kit.fabric(cushions[choice], "aid_seat_%d" % choice)
	var seam: StandardMaterial3D = Kit.fabric(cushions[choice].darkened(0.17), "aid_seam_%d" % choice)
	var glow: StandardMaterial3D = Kit.washi(Kit.CREAM, 0.65, "aid_header")

	# Oak uprights and stone footings frame a calm, high-visibility header.
	for x: float in [-1.91, 1.91]:
		Kit.rbox(root, Vector3(0.28, 0.07, 0.56), Vector3(x, 0.035, -0.12), Kit.stone(), 0.03)
		Kit.rbox(root, Vector3(0.11, 2.62, 0.12), Vector3(x, 1.38, -0.27), timber, 0.025)
	Kit.rbox(root, Vector3(4.3, 1.12, 0.19), Vector3(0.0, 2.64, -0.22), timber, 0.075)
	Kit.rbox(root, Vector3(4.17, 0.99, 0.045), Vector3(0.0, 2.64, -0.104), glow, 0.06)
	Kit.rbox(root, Vector3(4.02, 0.018, 0.018), Vector3(0.0, 2.18, -0.073), trim, 0.007, false)
	_cross(root, Vector3(-1.67, 2.66, -0.063), 0.61, green)
	_label(root, "FIRST AID", Vector3(0.39, 2.93, -0.072), 112, 0.003, 3.05, Kit.CHARCOAL)
	_label(root, "救護室  ·  急救", Vector3(0.39, 2.68, -0.072), 76, 0.003, 3.05, Kit.CHARCOAL)
	_label(root, "Sơ cứu", Vector3(0.39, 2.46, -0.072), 68, 0.003, 3.05, Kit.CHARCOAL)
	_label(root, "Premiers secours · Primeros auxilios", Vector3(0.39, 2.27, -0.072), 64, 0.003, 3.13, Kit.CHARCOAL)

	# Powder-coated cabinet with a recessed toe kick, twin doors and a service ledge.
	Kit.rbox(root, Vector3(1.28, 0.12, 0.52), Vector3(-1.16, 0.06, 0.01), steel, 0.025)
	Kit.rbox(root, Vector3(1.48, 1.85, 0.62), Vector3(-1.16, 1.045, 0.0), white, 0.095)
	Kit.rbox(root, Vector3(1.36, 1.7, 0.025), Vector3(-1.16, 1.055, 0.316), Kit.paint(Kit.CHARCOAL.lightened(0.15)), 0.04)
	for x: float in [-1.504, -0.816]:
		Kit.rbox(root, Vector3(0.675, 1.68, 0.045), Vector3(x, 1.055, 0.342), white, 0.038)
		Kit.rbox(root, Vector3(0.025, 0.24, 0.055), Vector3(x + (0.25 if x < -1.16 else -0.25), 0.97, 0.394), trim, 0.012)
	_cross(root, Vector3(-1.16, 1.52, 0.377), 0.63, green)
	Kit.rbox(root, Vector3(1.53, 0.065, 0.67), Vector3(-1.16, 2.0, 0.0), Kit.stone(Kit.LIMESTONE, 0.42, "aid_counter"), 0.032)
	# Hinges read as hardware rather than small text.
	for y: float in [0.45, 1.62]:
		Kit.rbox(root, Vector3(0.028, 0.1, 0.045), Vector3(-1.81, y, 0.363), trim, 0.011)

	# AED case on its own oak spine: recessed dark window, visible device and latch.
	Kit.rbox(root, Vector3(0.72, 1.94, 0.12), Vector3(-0.025, 1.04, -0.25), timber, 0.055)
	Kit.rbox(root, Vector3(0.65, 0.89, 0.3), Vector3(-0.025, 1.48, 0.03), white, 0.065)
	Kit.rbox(root, Vector3(0.56, 0.58, 0.028), Vector3(-0.025, 1.43, 0.192), steel, 0.034)
	Kit.rbox(root, Vector3(0.4, 0.39, 0.055), Vector3(-0.025, 1.42, 0.218), green, 0.07)
	Kit.rbox(root, Vector3(0.17, 0.045, 0.038), Vector3(-0.025, 1.65, 0.225), white, 0.018)
	_label(root, "AED", Vector3(-0.025, 1.81, 0.199), 88, 0.003, 0.53, Kit.CHARCOAL)
	Kit.add(root, _symbol("heart"), white, Vector3(-0.025, 1.43, 0.251), Vector3.ZERO, false)
	Kit.add(root, _symbol("bolt"), green, Vector3(-0.025, 1.43, 0.253), Vector3.ZERO, false)
	Kit.rbox(root, Vector3(0.07, 0.19, 0.047), Vector3(0.225, 1.43, 0.226), trim, 0.019)
	Kit.add(root, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.022, 0.0), Vector2(0.022, 0.012), Vector2(0.0, 0.012)]), 12), Kit.washi(Color(0.28, 0.9, 0.44), 1.4, "aid_ready"), Vector3(0.217, 1.81, 0.203), Vector3(90.0, 0.0, 0.0), false)

	# A low waiting bench: solid timber rails, linen cushions and rounded arm rests.
	for x: float in [0.62, 1.68]:
		for z: float in [-0.18, 0.28]:
			Kit.rbox(root, Vector3(0.065, 0.39, 0.065), Vector3(x, 0.195, z), steel, 0.021)
	Kit.rbox(root, Vector3(1.53, 0.09, 0.65), Vector3(1.15, 0.395, 0.06), timber, 0.04)
	for x: float in [0.765, 1.535]:
		Kit.rbox(root, Vector3(0.745, 0.055, 0.57), Vector3(x, 0.453, 0.065), seam, 0.027)
		Kit.rbox(root, Vector3(0.72, 0.105, 0.545), Vector3(x, 0.485, 0.065), linen, 0.05)
	for x: float in [0.48, 1.82]:
		Kit.rbox(root, Vector3(0.05, 0.49, 0.055), Vector3(x, 0.67, -0.24), steel, 0.018)
		Kit.rbox(root, Vector3(0.048, 0.24, 0.05), Vector3(x, 0.545, 0.24), steel, 0.018)
		Kit.rbox(root, Vector3(0.095, 0.065, 0.58), Vector3(x, 0.69, 0.035), timber, 0.03)
	Kit.rbox(root, Vector3(1.44, 0.3, 0.085), Vector3(1.15, 0.77, -0.25), timber, 0.042)
	Kit.rbox(root, Vector3(1.33, 0.24, 0.08), Vector3(1.15, 0.775, -0.193), linen, 0.039)
	return root


static func _cross(parent: Node3D, at: Vector3, size: float, material: Material) -> void:
	Kit.rbox(parent, Vector3(size, size / 3.0, 0.025), at, material, 0.015, false)
	Kit.rbox(parent, Vector3(size / 3.0, size, 0.024), at + Vector3(0.0, 0.0, 0.001), material, 0.015, false)


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, width: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signs.font()
	label.text = caption
	label.pixel_size = pixel
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x * pixel
	label.font_size = mini(size, int(float(size) * width / maxf(measured, 0.001)))
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _symbol(kind: String) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind] as ArrayMesh
	var points: PackedVector2Array
	if kind == "heart":
		points = PackedVector2Array([Vector2(0.0, -0.12), Vector2(-0.12, -0.01), Vector2(-0.14, 0.05), Vector2(-0.11, 0.1), Vector2(-0.055, 0.11), Vector2(0.0, 0.07), Vector2(0.055, 0.11), Vector2(0.11, 0.1), Vector2(0.14, 0.05), Vector2(0.12, -0.01)])
	else:
		points = PackedVector2Array([Vector2(0.022, 0.094), Vector2(-0.055, -0.009), Vector2(-0.005, -0.009), Vector2(-0.024, -0.092), Vector2(0.062, 0.027), Vector2(0.011, 0.027)])
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The glyph is a front-facing relief; duplicate reverse winding to avoid culled icons.
	for i: int in range(0, triangles.size(), 3):
		for index: int in [triangles[i], triangles[i + 1], triangles[i + 2], triangles[i + 2], triangles[i + 1], triangles[i]]:
			var p: Vector2 = points[index]
			surface.set_normal(Vector3.FORWARD)
			surface.add_vertex(Vector3(p.x, p.y, 0.0))
	var mesh: ArrayMesh = surface.commit()
	_meshes[kind] = mesh
	return mesh
