extends RefCounted
## An adult traveller, seated upright in a lightweight manual wheelchair.
## Wheel contact defines the floor; shoes rest naturally on the raised footplate.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WheelchairTraveller"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var coats: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO]
	var skins: Array[Color] = [Color(0.69, 0.46, 0.32), Color(0.91, 0.69, 0.52), Color(0.44, 0.28, 0.20)]
	var hairs: Array[Color] = [Color(0.18, 0.13, 0.10), Color(0.42, 0.39, 0.35), Color(0.10, 0.09, 0.08)]
	var coat: Material = Kit.fabric(coats[style], "wheelchair_coat_%d" % style)
	var trousers: Material = Kit.fabric(Kit.CHARCOAL, "wheelchair_trousers")
	var skin: Material = Kit.paint(skins[style], 0.88)
	var hair: Material = Kit.paint(hairs[style], 0.94)
	var steel: Material = Kit.metal(Kit.CHARCOAL, 0.42, 0.8, "wheelchair_frame")
	var rubber: Material = Kit.paint(Color(0.09, 0.095, 0.085), 0.95)
	var alloy: Material = Kit.metal(Color(0.62, 0.63, 0.59), 0.32, 0.9, "wheelchair_alloy")
	var linen: Material = Kit.fabric(Kit.LINEN, "wheelchair_seat")
	var oak: Material = Kit.wood(Kit.OAK, "wheelchair_armrests")

	# All bent frame rails, caster forks and rear hubs share one cached mesh.
	Kit.add(root, _frame(), steel, Vector3.ZERO)
	for side: float in [-1.0, 1.0]:
		var wheel_at: Vector3 = Vector3(side * 0.32, 0.32, -0.15)
		Kit.add(root, _ring(0.298, 0.022), rubber, wheel_at, Vector3(0.0, 0.0, 90.0))
		Kit.add(root, _ring(0.266, 0.009), alloy, wheel_at + Vector3(side * 0.043, 0.0, 0.0), Vector3(0.0, 0.0, 90.0))
		Kit.add(root, _spokes(), alloy, wheel_at, Vector3(0.0, 0.0, 90.0), false)
		Kit.add(root, _disc(0.085, 0.036), rubber, Vector3(side * 0.245, 0.085, 0.51), Vector3(0.0, 0.0, 90.0))
		Kit.rbox(root, Vector3(0.065, 0.045, 0.36), Vector3(side * 0.264, 0.77, 0.035), oak, 0.021)
	Kit.rbox(root, Vector3(0.46, 0.075, 0.43), Vector3(0.0, 0.535, 0.045), linen, 0.033)
	Kit.rbox(root, Vector3(0.44, 0.46, 0.065), Vector3(0.0, 0.785, -0.195), linen, 0.032)
	Kit.rbox(root, Vector3(0.37, 0.035, 0.24), Vector3(0.0, 0.085, 0.54), steel, 0.016)

	# A gently tapered jacket rather than a rectangular torso.
	var torso: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.20, 0.07),
		Vector2(0.205, 0.30), Vector2(0.19, 0.41), Vector2(0.115, 0.46), Vector2(0.0, 0.46)
	]), 12), coat, Vector3(0.0, 0.60, -0.015))
	torso.scale.z = 0.72
	_ellipsoid(root, Vector3(0.095, 0.125, 0.095), Vector3(0.0, 1.085, 0.0), skin)
	_ellipsoid(root, Vector3(0.32, 0.355, 0.30), Vector3(0.0, 1.285, 0.012), skin)
	var cap: MeshInstance3D = Kit.add(root, _hair(style), hair, Vector3(0.0, 1.325, -0.019))
	cap.scale.z = 0.92 if style != 1 else 1.02
	_ellipsoid(root, Vector3(0.043, 0.053, 0.052), Vector3(0.0, 1.268, 0.158), skin)
	Kit.add(root, _face_details(false), Kit.paint(Kit.CHARCOAL), Vector3.ZERO, Vector3.ZERO, false)
	Kit.add(root, _face_details(true), skin, Vector3.ZERO)
	# Cream shirt collar, visible above the soft jacket lapel.
	var collar: MeshInstance3D = Kit.add(root, _ring(0.06, 0.014), Kit.fabric(Kit.CREAM, "wheelchair_collar"), Vector3(0.0, 1.062, 0.0))
	collar.scale.z = 0.8

	for side: float in [-1.0, 1.0]:
		# Seated thighs and shins preserve adult proportions and a relaxed pose.
		_limb(root, Vector3(side * 0.105, 0.605, 0.04), Vector3(side * 0.11, 0.59, 0.405), 0.073, trousers)
		_limb(root, Vector3(side * 0.11, 0.585, 0.405), Vector3(side * 0.11, 0.185, 0.47), 0.059, trousers)
		_ellipsoid(root, Vector3(0.13, 0.115, 0.24), Vector3(side * 0.11, 0.16, 0.525), Kit.paint(Kit.WALNUT, 0.78))
		_limb(root, Vector3(side * 0.19, 0.975, 0.0), Vector3(side * 0.238, 0.785, 0.11), 0.064, coat)
		_limb(root, Vector3(side * 0.238, 0.785, 0.11), Vector3(side * 0.16, 0.78, 0.295), 0.046, skin)
		_ellipsoid(root, Vector3(0.085, 0.057, 0.10), Vector3(side * 0.155, 0.775, 0.31), skin)

	# Small structured carry-on satchel sits between the resting hands.
	var bag: Material = Kit.fabric(Kit.CLAY if style != 1 else Kit.SAGE, "wheelchair_bag_%d" % style)
	Kit.rbox(root, Vector3(0.29, 0.19, 0.14), Vector3(0.0, 0.727, 0.285), bag, 0.041)
	Kit.rbox(root, Vector3(0.27, 0.085, 0.02), Vector3(0.0, 0.774, 0.357), Kit.paint(Kit.WALNUT), 0.009)
	var handle: MeshInstance3D = Kit.add(root, _ring(0.053, 0.009), Kit.paint(Kit.WALNUT), Vector3(0.0, 0.824, 0.285), Vector3(90.0, 0.0, 0.0))
	handle.scale.y = 0.7
	Kit.rbox(root, Vector3(0.025, 0.035, 0.009), Vector3(0.0, 0.756, 0.373), Kit.brass(), 0.004, false)
	# A wordless travel motif avoids illegible miniature multilingual labels.
	var motif: Label3D = Label3D.new()
	motif.name = "TravelMotif"
	motif.font = Signs.font()
	motif.text = "✈"
	motif.font_size = 64
	motif.pixel_size = 0.0012
	motif.outline_size = 0
	motif.modulate = Kit.CREAM
	motif.position = Vector3(-0.079, 0.696, 0.358)
	motif.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(motif)
	return root


static func _ellipsoid(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, _sphere(), material, at)
	node.scale = size
	return node


static func _sphere() -> SphereMesh:
	if not _meshes.has("sphere"):
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 12
		mesh.rings = 6
		_meshes["sphere"] = mesh
	return _meshes["sphere"] as SphereMesh


static func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var length: float = start.distance_to(end)
	var key: String = "limb:%0.4f:%0.4f" % [length, radius]
	if not _meshes.has(key):
		var mesh: CapsuleMesh = CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = length + radius * 2.0
		mesh.radial_segments = 10
		mesh.rings = 3
		_meshes[key] = mesh
	var node: MeshInstance3D = Kit.add(parent, _meshes[key] as Mesh, material, (start + end) * 0.5)
	node.basis = _along(end - start)


static func _along(direction: Vector3) -> Basis:
	var up: Vector3 = direction.normalized()
	var reference: Vector3 = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var right: Vector3 = up.cross(reference).normalized()
	return Basis(right, up, right.cross(up).normalized())


static func _ring(radius: float, tube: float) -> ArrayMesh:
	var profile: PackedVector2Array = PackedVector2Array()
	for i: int in range(9):
		var angle: float = TAU * float(i) / 8.0
		profile.append(Vector2(radius + cos(angle) * tube, sin(angle) * tube))
	return Kit.lathe(profile, 24)


static func _disc(radius: float, width: float) -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([
		Vector2(0.0, -width * 0.5), Vector2(radius * 0.8, -width * 0.5),
		Vector2(radius, -width * 0.3), Vector2(radius, width * 0.3),
		Vector2(radius * 0.8, width * 0.5), Vector2(0.0, width * 0.5)
	]), 16)


static func _tube(st: SurfaceTool, start: Vector3, end: Vector3, radius: float) -> void:
	var mesh: ArrayMesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(radius, 0.0),
		Vector2(radius, start.distance_to(end)), Vector2(0.0, start.distance_to(end))
	]), 8)
	st.append_from(mesh, 0, Transform3D(_along(end - start), start))


static func _frame() -> ArrayMesh:
	if not _meshes.has("frame"):
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side: float in [-1.0, 1.0]:
			var x: float = side * 0.245
			_tube(st, Vector3(x, 0.32, -0.15), Vector3(x, 0.51, 0.27), 0.019)
			_tube(st, Vector3(x, 0.51, -0.21), Vector3(x, 0.51, 0.29), 0.019)
			_tube(st, Vector3(x, 0.51, -0.21), Vector3(x, 1.035, -0.23), 0.017)
			_tube(st, Vector3(x, 1.035, -0.23), Vector3(x, 1.035, -0.33), 0.023)
			_tube(st, Vector3(x, 0.51, 0.20), Vector3(x, 0.75, 0.20), 0.014)
			_tube(st, Vector3(x, 0.75, -0.17), Vector3(x, 0.75, 0.20), 0.014)
			_tube(st, Vector3(x, 0.51, 0.29), Vector3(x, 0.19, 0.51), 0.018)
			_tube(st, Vector3(x, 0.19, 0.51), Vector3(x + side * 0.027, 0.085, 0.51), 0.012)
			_tube(st, Vector3(x, 0.32, -0.15), Vector3(side * 0.357, 0.32, -0.15), 0.035)
			_tube(st, Vector3(x, 0.29, 0.42), Vector3(side * 0.175, 0.10, 0.54), 0.014)
		_tube(st, Vector3(-0.245, 0.36, -0.15), Vector3(0.245, 0.36, -0.15), 0.018)
		_tube(st, Vector3(-0.23, 0.49, -0.17), Vector3(0.23, 0.49, 0.24), 0.013)
		_tube(st, Vector3(0.23, 0.49, -0.17), Vector3(-0.23, 0.49, 0.24), 0.013)
		_meshes["frame"] = st.commit()
	return _meshes["frame"] as ArrayMesh


static func _spokes() -> ArrayMesh:
	if not _meshes.has("spokes"):
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i: int in range(12):
			var angle: float = TAU * float(i) / 12.0
			_tube(st, Vector3.ZERO, Vector3(cos(angle) * 0.287, 0.0, sin(angle) * 0.287), 0.0035)
		_meshes["spokes"] = st.commit()
	return _meshes["spokes"] as ArrayMesh


static func _hair(style: int) -> ArrayMesh:
	var crown: float = 0.15 if style != 2 else 0.175
	var radius: float = 0.165 if style != 1 else 0.175
	return Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(radius, 0.0), Vector2(radius, 0.065),
		Vector2(radius * 0.8, crown * 0.77), Vector2(radius * 0.44, crown * 0.96), Vector2(0.0, crown)
	]), 12)


static func _face_details(ears: bool) -> ArrayMesh:
	var key: String = "ears" if ears else "eyes"
	if not _meshes.has(key):
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for side: float in [-1.0, 1.0]:
			var size: Vector3 = Vector3(0.055, 0.085, 0.05) if ears else Vector3(0.022, 0.028, 0.014)
			var at: Vector3 = Vector3(side * 0.158, 1.285, 0.007) if ears else Vector3(side * 0.06, 1.305, 0.151)
			st.append_from(_sphere(), 0, Transform3D(Basis.from_scale(size), at))
		_meshes[key] = st.commit()
	return _meshes[key] as ArrayMesh
