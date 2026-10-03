extends RefCounted
## Compact housekeeping trolley; +Z is the stored warning sign and bucket end.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CleaningCart"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var colors: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.LINEN]
	var accent: Color = colors[choice]
	var frame: Material = Kit.metal(Kit.CHARCOAL, 0.48, 0.65, "cleaning_cart_frame")
	var rubber: Material = Kit.paint(Color(0.075, 0.072, 0.065), 0.95)
	var polymer: Material = Kit.paint(accent, 0.7)
	var yellow: Material = Kit.paint(Color(0.98, 0.76, 0.12), 0.56)
	var oak: Material = Kit.wood(Kit.OAK, "cleaning_cart_grip")
	var linen: Material = Kit.fabric(Kit.LINEN.darkened(float(choice) * 0.035), "cart_linen_%d" % choice)

	# Four swivel casters: soft tyre shoulders, inset hubs and rounded steel forks.
	var tyre: Mesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.027), Vector2(0.063, -0.027), Vector2(0.077, -0.017),
		Vector2(0.08, 0.0), Vector2(0.077, 0.017), Vector2(0.063, 0.027), Vector2(0.0, 0.027)]), 20)
	var hub: Mesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.03), Vector2(0.034, -0.03), Vector2(0.034, 0.03), Vector2(0.0, 0.03)]), 16)
	for x: float in [-0.28, 0.28]:
		for z: float in [-0.43, 0.43]:
			Kit.add(root, tyre, rubber, Vector3(x, 0.08, z), Vector3(0.0, 0.0, 90.0))
			Kit.add(root, hub, frame, Vector3(x, 0.08, z), Vector3(0.0, 0.0, 90.0))
			Kit.rbox(root, Vector3(0.035, 0.1, 0.07), Vector3(x + 0.043, 0.13, z), frame, 0.012)
	Kit.rbox(root, Vector3(0.7, 0.075, 1.13), Vector3(0.0, 0.205, 0.0), frame, 0.035)
	Kit.rbox(root, Vector3(0.73, 0.035, 1.16), Vector3(0.0, 0.185, 0.0), rubber, 0.016)
	for x: float in [-0.3, 0.3]:
		Kit.rbox(root, Vector3(0.035, 0.91, 0.035), Vector3(x, 0.685, -0.33), frame, 0.015)
		Kit.rbox(root, Vector3(0.035, 0.58, 0.035), Vector3(x, 0.52, 0.03), frame, 0.015)
		Kit.rbox(root, Vector3(0.035, 0.035, 0.45), Vector3(x, 1.13, -0.51), frame, 0.015)
	Kit.rbox(root, Vector3(0.61, 0.05, 0.055), Vector3(0.0, 1.13, -0.72), oak, 0.023)
	Kit.rbox(root, Vector3(0.64, 0.045, 0.49), Vector3(0.0, 0.79, -0.17), frame, 0.02)
	Kit.rbox(root, Vector3(0.58, 0.026, 0.42), Vector3(0.0, 0.823, -0.17), polymer, 0.012)

	# Removable linen waste sack behind the shelves, with rolled opening and bound seams.
	Kit.rbox(root, Vector3(0.48, 0.55, 0.29), Vector3(0.0, 0.53, -0.48), linen, 0.065)
	for x: float in [-0.235, 0.235]:
		Kit.rbox(root, Vector3(0.022, 0.5, 0.035), Vector3(x, 0.53, -0.345), linen, 0.01)
	Kit.rbox(root, Vector3(0.52, 0.045, 0.32), Vector3(0.0, 0.825, -0.48), linen, 0.02)
	Kit.rbox(root, Vector3(0.42, 0.012, 0.22), Vector3(0.0, 0.85, -0.48), rubber, 0.025)

	# Two open utility bins, a tapered bucket and a recessed dark water surface.
	var bin_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.095, 0.0), Vector2(0.116, 0.018),
		Vector2(0.127, 0.21), Vector2(0.135, 0.218), Vector2(0.135, 0.235),
		Vector2(0.119, 0.235), Vector2(0.112, 0.035), Vector2(0.0, 0.035)])
	for x: float in [-0.15, 0.15]:
		Kit.add(root, Kit.lathe(bin_profile, 24), polymer, Vector3(x, 0.836, -0.15))
		Kit.rbox(root, Vector3(0.11, 0.022, 0.036), Vector3(x, 1.017, -0.02), frame, 0.01)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.193, 0.025),
		Vector2(0.222, 0.3), Vector2(0.235, 0.315), Vector2(0.235, 0.335),
		Vector2(0.214, 0.335), Vector2(0.18, 0.035), Vector2(0.0, 0.035)]), 32),
		polymer, Vector3(-0.065, 0.245, 0.31))
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.194, 0.0), Vector2(0.0, 0.002)]), 32),
		Kit.paint(Color(0.24, 0.34, 0.32), 0.22), Vector3(-0.065, 0.475, 0.31))
	# Perforated press basket and its oak-tipped lever.
	Kit.rbox(root, Vector3(0.23, 0.14, 0.17), Vector3(-0.065, 0.575, 0.2), frame, 0.025)
	for i: int in 4:
		Kit.rbox(root, Vector3(0.022, 0.078, 0.008), Vector3(-0.14 + float(i) * 0.05, 0.59, 0.289), rubber, 0.007, false)
	var lever: MeshInstance3D = Kit.rbox(root, Vector3(0.025, 0.29, 0.025), Vector3(-0.2, 0.7, 0.18), frame, 0.009)
	lever.rotation_degrees.x = -24.0
	Kit.rbox(root, Vector3(0.14, 0.033, 0.04), Vector3(-0.2, 0.84, 0.12), oak, 0.015)

	# Parked flat mop: oak shaft, brass ferrule, scalloped textile pad.
	var pole: MeshInstance3D = Kit.rbox(root, Vector3(0.028, 1.27, 0.028), Vector3(-0.32, 0.91, 0.02), oak, 0.012)
	pole.rotation_degrees.z = 6.0
	Kit.rbox(root, Vector3(0.042, 0.08, 0.042), Vector3(-0.254, 0.3, 0.02), Kit.brass(), 0.012)
	Kit.rbox(root, Vector3(0.39, 0.025, 0.14), Vector3(-0.2, 0.258, 0.04), frame, 0.012)
	for i: int in 6:
		Kit.rbox(root, Vector3(0.059, 0.027, 0.17), Vector3(-0.365 + float(i) * 0.066, 0.241, 0.04), linen, 0.012)
	Kit.rbox(root, Vector3(0.052, 0.045, 0.07), Vector3(-0.3, 1.0, 0.01), rubber, 0.018)

	# Folded two-leaf safety sign clipped to the front. It stays closed for transport.
	var sign: Node3D = Node3D.new()
	sign.name = "FoldedWetFloorSign"
	sign.position = Vector3(0.18, 0.66, 0.57)
	root.add_child(sign)
	Kit.rbox(sign, Vector3(0.48, 0.78, 0.025), Vector3(0.0, 0.0, -0.023), yellow, 0.035)
	Kit.rbox(sign, Vector3(0.48, 0.78, 0.025), Vector3.ZERO, yellow, 0.035)
	# Visible dark hand opening, raised yellow surround and hinge knuckles.
	Kit.rbox(sign, Vector3(0.21, 0.065, 0.006), Vector3(0.0, 0.313, 0.015), rubber, 0.025, false)
	for x: float in [-0.17, 0.17]:
		Kit.rbox(sign, Vector3(0.075, 0.034, 0.06), Vector3(x, 0.372, -0.01), frame, 0.015)
	Kit.add(sign, _slip_icon(), rubber, Vector3(0.0, 0.08, 0.018), Vector3.ZERO, false)
	_label(sign, "WET FLOOR", Vector3(0.0, -0.17, 0.02), 0.072)
	var captions: Array[String] = ["足元注意 · 小心地滑", "Sàn ướt", "Sol glissant", "Suelo mojado"]
	_label(sign, captions[choice], Vector3(0.0, -0.285, 0.02), 0.052)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = 64
	var width: float = Signs.font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	label.pixel_size = minf(height / 64.0, 0.435 / maxf(width, 1.0))
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _slip_icon() -> ArrayMesh:
	if _meshes.has("slip"):
		return _meshes["slip"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Triangular warning outline and a falling person, all one cached mesh.
	var shapes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-0.19, -0.14), Vector2(0.0, 0.205), Vector2(0.0, 0.16), Vector2(-0.155, -0.12)]),
		PackedVector2Array([Vector2(0.0, 0.205), Vector2(0.19, -0.14), Vector2(0.155, -0.12), Vector2(0.0, 0.16)]),
		PackedVector2Array([Vector2(-0.19, -0.14), Vector2(0.19, -0.14), Vector2(0.155, -0.12), Vector2(-0.155, -0.12)]),
		PackedVector2Array([Vector2(-0.04, 0.025), Vector2(0.015, -0.018), Vector2(0.033, 0.005), Vector2(-0.02, 0.047)]),
		PackedVector2Array([Vector2(-0.03, 0.031), Vector2(-0.095, 0.002), Vector2(-0.086, -0.016), Vector2(-0.022, 0.007)]),
		PackedVector2Array([Vector2(-0.024, 0.025), Vector2(0.005, 0.087), Vector2(0.025, 0.078), Vector2(-0.003, 0.015)]),
		PackedVector2Array([Vector2(0.01, -0.012), Vector2(0.078, -0.028), Vector2(0.12, -0.008), Vector2(0.129, -0.026), Vector2(0.08, -0.049), Vector2(0.008, -0.034)]),
		PackedVector2Array([Vector2(0.012, -0.017), Vector2(-0.005, -0.07), Vector2(-0.072, -0.08), Vector2(-0.075, -0.1), Vector2(0.012, -0.089), Vector2(0.035, -0.026)])]
	var head: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var angle: float = TAU * float(i) / 16.0
		head.append(Vector2(-0.048, 0.077) + Vector2(cos(angle), sin(angle)) * 0.023)
	shapes.append(head)
	for polygon: PackedVector2Array in shapes:
		var indices: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
		for i: int in range(0, indices.size(), 3):
			for offset: int in [2, 1, 0]:
				var point: Vector2 = polygon[indices[i + offset]]
				st.set_normal(Vector3.BACK)
				st.add_vertex(Vector3(point.x, point.y, 0.0))
	var mesh: ArrayMesh = st.commit()
	_meshes["slip"] = mesh
	return mesh
