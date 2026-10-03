extends RefCounted
## A softly tailored airport cleaner, hands resting on a compact linen-bag trolley.
## +Z is forward. Shoes and all four trolley wheels touch y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CleanerWithCart"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var uniform_colors: Array[Color] = [Kit.SAGE, Color(0.43, 0.53, 0.43), Color(0.63, 0.67, 0.55)]
	var skin_colors: Array[Color] = [Color(0.76, 0.52, 0.36), Color(0.43, 0.28, 0.20), Color(0.91, 0.70, 0.53)]
	var hair_colors: Array[Color] = [Color(0.18, 0.14, 0.12), Color(0.11, 0.10, 0.09), Color(0.48, 0.45, 0.39)]
	var uniform: Material = Kit.fabric(uniform_colors[style], "cleaner_sage_%d" % style)
	var trousers: Material = Kit.fabric(Kit.CHARCOAL.lightened(0.06), "cleaner_trousers")
	var linen: Material = Kit.fabric(Kit.LINEN, "cleaner_linen")
	var skin: Material = Kit.paint(skin_colors[style], 0.82)
	var hair: Material = Kit.paint(hair_colors[style], 0.9)
	var rubber: Material = Kit.paint(Color(0.10, 0.11, 0.10), 0.94)
	var steel: Material = Kit.metal()
	var oak: Material = Kit.wood()
	var accent: Material = Kit.fabric(Kit.CLAY if style == 1 else Kit.CREAM, "cleaner_trim_%d" % style)

	# One turned, elliptical tunic: flared hem, full shoulders, inset neckline.
	var tunic: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.20, 0.0), Vector2(0.224, 0.025),
		Vector2(0.218, 0.12), Vector2(0.238, 0.33), Vector2(0.245, 0.39),
		Vector2(0.214, 0.455), Vector2(0.085, 0.51), Vector2(0.0, 0.51),
	]), 16), uniform, Vector3(0.0, 0.775, -0.255), Vector3(5.0, 0.0, 0.0))
	tunic.scale.z = 0.69
	_limb(root, Vector3(-0.106, 0.80, -0.25), Vector3(-0.11, 0.18, -0.23), 0.092, trousers)
	_limb(root, Vector3(0.106, 0.80, -0.27), Vector3(0.11, 0.18, -0.38), 0.092, trousers)
	_batch(root, "shoes", _sphere(), rubber, [
		_pose(Vector3(-0.11, 0.075, -0.20), Vector3(0.19, 0.15, 0.30)),
		_pose(Vector3(0.11, 0.075, -0.35), Vector3(0.19, 0.15, 0.30)),
	])
	_batch(root, "shoe_soles", _sphere(), Kit.paint(Kit.LINEN.darkened(0.18)), [
		_pose(Vector3(-0.11, 0.023, -0.20), Vector3(0.19, 0.046, 0.29)),
		_pose(Vector3(0.11, 0.023, -0.35), Vector3(0.19, 0.046, 0.29)),
	])
	_oval(root, Vector3(0.0, 1.319, -0.213), Vector3(0.14, 0.18, 0.135), skin)
	var collar: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.074, 0.0), Vector2(0.103, 0.0), Vector2(0.103, 0.015),
		Vector2(0.084, 0.043), Vector2(0.071, 0.043), Vector2(0.074, 0.0),
	]), 16), accent, Vector3(0.0, 1.266, -0.211))
	collar.scale.z = 0.79
	_oval(root, Vector3(0.0, 1.505, -0.20), Vector3(0.345, 0.375, 0.335), skin)
	_oval(root, Vector3(0.0, 1.554, -0.272), Vector3(0.349, 0.325, 0.287), hair)
	_batch(root, "ears", _sphere(), skin, [
		_pose(Vector3(-0.172, 1.495, -0.205), Vector3(0.052, 0.084, 0.061)),
		_pose(Vector3(0.172, 1.495, -0.205), Vector3(0.052, 0.084, 0.061)),
	])
	_batch(root, "eyes", _sphere(), Kit.paint(Kit.CHARCOAL), [
		_pose(Vector3(-0.061, 1.535, -0.043), Vector3(0.025, 0.032, 0.018)),
		_pose(Vector3(0.061, 1.535, -0.043), Vector3(0.025, 0.032, 0.018)),
	])
	_oval(root, Vector3(0.0, 1.487, -0.025), Vector3(0.061, 0.066, 0.052), skin)

	# A low, soft work cap with a broad curved peak and a contrasting woven band.
	var cap: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.179, 0.0), Vector2(0.188, 0.025),
		Vector2(0.178, 0.067), Vector2(0.142, 0.109), Vector2(0.068, 0.133),
		Vector2(0.0, 0.139),
	]), 16), uniform, Vector3(0.0, 1.617, -0.212))
	cap.scale.z = 0.94
	_oval(root, Vector3(0.0, 1.641, -0.068), Vector3(0.39, 0.043, 0.27), uniform)
	var band: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.181, 0.0), Vector2(0.19, 0.003), Vector2(0.188, 0.019),
		Vector2(0.18, 0.019),
	]), 16), accent, Vector3(0.0, 1.626, -0.212))
	band.scale.z = 0.94
	if style == 1:
		_oval(root, Vector3(0.0, 1.52, -0.424), Vector3(0.145, 0.145, 0.14), hair)

	# Sleeved elbows bend forward; both hands visibly wrap over the oak push bar.
	for side: float in [-1.0, 1.0]:
		_limb(root, Vector3(side * 0.218, 1.181, -0.175), Vector3(side * 0.281, 1.032, 0.066), 0.077, uniform)
		_limb(root, Vector3(side * 0.281, 1.032, 0.066), Vector3(side * 0.246, 0.99, 0.274), 0.060, uniform)
	_batch(root, "hands", _sphere(), skin, [
		_pose(Vector3(-0.246, 0.99, 0.323), Vector3(0.093, 0.091, 0.105)),
		_pose(Vector3(0.246, 0.99, 0.323), Vector3(0.093, 0.091, 0.105)),
	])
	Kit.rbox(root, Vector3(0.013, 0.325, 0.012), Vector3(0.0, 1.071, -0.063), accent, 0.005, false)
	Kit.rbox(root, Vector3(0.11, 0.106, 0.021), Vector3(-0.109, 1.135, -0.086), uniform, 0.022)

	_build_cart(root, style, linen, steel, rubber, oak)
	return root


static func _build_cart(root: Node3D, style: int, linen: Material, steel: Material, rubber: Material, oak: Material) -> void:
	# Four rounded rubber casters; each wheel and hub shares one cached draw mesh.
	var wheel: Mesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.033), Vector2(0.065, -0.033), Vector2(0.084, -0.022),
		Vector2(0.084, 0.022), Vector2(0.065, 0.033), Vector2(0.0, 0.033),
	]), 16)
	var wheel_poses: Array[Transform3D] = []
	var hub_poses: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		for depth: float in [0.41, 0.85]:
			wheel_poses.append(_pose(Vector3(side * 0.287, 0.084, depth), Vector3.ONE, Vector3(0.0, 0.0, 90.0)))
			hub_poses.append(_pose(Vector3(side * 0.322, 0.084, depth), Vector3(0.016, 0.054, 0.054)))
	_batch(root, "cart_wheels", wheel, rubber, wheel_poses)
	_batch(root, "cart_hubs", _sphere(), Kit.brass(), hub_poses)
	Kit.rbox(root, Vector3(0.65, 0.075, 0.65), Vector3(0.0, 0.207, 0.64), steel, 0.035)
	Kit.rbox(root, Vector3(0.594, 0.031, 0.59), Vector3(0.0, 0.259, 0.64), oak, 0.014)
	var frame_segments: PackedVector3Array = PackedVector3Array([
		Vector3(-0.287, 0.115, 0.41), Vector3(-0.305, 0.956, 0.33),
		Vector3(0.287, 0.115, 0.41), Vector3(0.305, 0.956, 0.33),
		Vector3(-0.305, 0.956, 0.33), Vector3(0.305, 0.956, 0.33),
		Vector3(-0.287, 0.115, 0.85), Vector3(-0.287, 0.797, 0.85),
		Vector3(0.287, 0.115, 0.85), Vector3(0.287, 0.797, 0.85),
		Vector3(-0.305, 0.797, 0.33), Vector3(-0.287, 0.797, 0.85),
		Vector3(0.305, 0.797, 0.33), Vector3(0.287, 0.797, 0.85),
		Vector3(-0.287, 0.797, 0.85), Vector3(0.287, 0.797, 0.85),
		Vector3(-0.287, 0.555, 0.65), Vector3(-0.37, 0.555, 0.65),
	])
	Kit.add(root, _pipework("cart_frame", frame_segments, 0.018), steel, Vector3.ZERO)
	_limb(root, Vector3(-0.29, 0.978, 0.33), Vector3(0.29, 0.978, 0.33), 0.021, oak)

	# A real hollow sack, folded over an oval rim, carried above the lower deck.
	var sack: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.181, 0.0), Vector2(0.222, 0.045),
		Vector2(0.23, 0.19), Vector2(0.245, 0.40), Vector2(0.25, 0.447),
		Vector2(0.236, 0.447), Vector2(0.224, 0.39), Vector2(0.207, 0.075),
		Vector2(0.168, 0.043), Vector2(0.0, 0.043),
	]), 16), linen, Vector3(0.0, 0.31, 0.64))
	sack.scale = Vector3(1.10, 1.0, 0.99)
	var rim: MeshInstance3D = Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.232, 0.0), Vector2(0.251, 0.0), Vector2(0.257, 0.016),
		Vector2(0.251, 0.032), Vector2(0.23, 0.032), Vector2(0.232, 0.0),
	]), 16), Kit.fabric(Kit.SAGE.darkened(0.10), "cleaner_bag_rim"), Vector3(0.0, 0.746, 0.64))
	rim.scale = Vector3(1.10, 1.0, 0.99)
	var towel_color: Color = Kit.CLAY if style == 0 else Kit.INDIGO if style == 1 else Kit.CREAM
	Kit.rbox(root, Vector3(0.16, 0.27, 0.035), Vector3(0.17, 0.678, 0.833), Kit.fabric(towel_color, "cleaner_towel_%d" % style), 0.015)

	# A tall clipped mop and an unlabelled refill bottle make the role readable.
	_limb(root, Vector3(0.34, 0.287, 0.67), Vector3(0.382, 1.335, 0.69), 0.014, oak)
	Kit.rbox(root, Vector3(0.26, 0.076, 0.125), Vector3(0.335, 0.297, 0.67), linen, 0.032)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.046, 0.0), Vector2(0.060, 0.017),
		Vector2(0.060, 0.157), Vector2(0.046, 0.183), Vector2(0.021, 0.205),
		Vector2(0.021, 0.245), Vector2(0.0, 0.245),
	]), 12), Kit.paint(Kit.CREAM), Vector3(-0.355, 0.563, 0.65))
	Kit.rbox(root, Vector3(0.115, 0.038, 0.04), Vector3(-0.355, 0.813, 0.664), steel, 0.016)
	# Reuse the airport's staff shield/check pictogram. No miniature wording.
	var pictogram: QuadMesh = _pictogram_quad()
	Kit.add(root, pictogram, Signs._icon_material("shield", Kit.SAGE.darkened(0.25)), Vector3(-0.041, 0.58, 0.879), Vector3.ZERO, false)


static func _sphere() -> SphereMesh:
	if _meshes.has("sphere"):
		return _meshes["sphere"] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_meshes["sphere"] = mesh
	return mesh


static func _pictogram_quad() -> QuadMesh:
	if _meshes.has("pictogram_quad"):
		return _meshes["pictogram_quad"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.24, 0.24)
	_meshes["pictogram_quad"] = mesh
	return mesh


static func _capsule(radius: float, length: float) -> CapsuleMesh:
	var key: String = "capsule:%.5f:%.5f" % [radius, length]
	if _meshes.has(key):
		return _meshes[key] as CapsuleMesh
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length + radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 4
	_meshes[key] = mesh
	return mesh


static func _oval(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, _sphere(), material, at)
	node.scale = size
	return node


static func _limb(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var node: MeshInstance3D = Kit.add(parent, _capsule(radius, direction.length()), material, (start + end) * 0.5)
	node.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return node


static func _pose(at: Vector3, size: Vector3 = Vector3.ONE, angles: Vector3 = Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(angles * (PI / 180.0)) * Basis.from_scale(size), at)


static func _batch(parent: Node3D, key: String, source: Mesh, material: Material, poses: Array[Transform3D]) -> MeshInstance3D:
	var cache_key: String = "batch:" + key
	var mesh: ArrayMesh
	if _meshes.has(cache_key):
		mesh = _meshes[cache_key] as ArrayMesh
	else:
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for pose: Transform3D in poses:
			surface.append_from(source, 0, pose)
		mesh = surface.commit()
		_meshes[cache_key] = mesh
	return Kit.add(parent, mesh, material, Vector3.ZERO)


static func _pipework(key: String, endpoints: PackedVector3Array, radius: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(0, endpoints.size(), 2):
		var start: Vector3 = endpoints[index]
		var end: Vector3 = endpoints[index + 1]
		var direction: Vector3 = end - start
		var pose: Transform3D = Transform3D(Basis(Quaternion(Vector3.UP, direction.normalized())), (start + end) * 0.5)
		surface.append_from(_capsule(radius, direction.length()), 0, pose)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh
