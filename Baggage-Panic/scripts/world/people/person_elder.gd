extends RefCounted
## A quietly cheerful elder, travelling with a walnut cane and a linen cabin bag.
## Local +Z is forward; both shoes, both wheels and the cane tip touch y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ElderTraveller"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 3)
	var coat_colors: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO]
	var bag_colors: Array[Color] = [Kit.CLAY.darkened(0.12), Kit.SAGE, Kit.OCHRE.darkened(0.12)]
	var skin_colors: Array[Color] = [Color(0.72, 0.48, 0.33), Color(0.9, 0.68, 0.5), Color(0.48, 0.3, 0.22)]
	var coat: Material = Kit.fabric(coat_colors[style], "elder_cardigan_%d" % style)
	var trousers: Material = Kit.fabric(Kit.CHARCOAL.lightened(0.1), "elder_wool_trousers")
	var linen: Material = Kit.fabric(Kit.LINEN.lightened(0.08), "elder_scarf")
	var bag_fabric: Material = Kit.fabric(bag_colors[style], "elder_bag_%d" % style)
	var skin: Material = Kit.paint(skin_colors[style], 0.83)
	var silver: Material = Kit.paint(Kit.CREAM.lerp(Kit.CHARCOAL, 0.22 if style == 2 else 0.12), 0.94)
	var leather: Material = Kit.paint(Kit.WALNUT.darkened(0.3), 0.73)
	var rubber: Material = Kit.paint(Kit.CHARCOAL.darkened(0.3), 0.96)
	var walnut: Material = Kit.wood(Kit.WALNUT, "elder_cane_walnut")
	var steel: Material = Kit.metal(Kit.CHARCOAL.lightened(0.13), 0.42, 0.82, "elder_handle_steel")

	# Elliptical loafers and softly tapered trouser legs: a small, settled stride.
	_ellipsoid(root, "LeftLoafer", Vector3(-0.115, 0.065, 0.072), Vector3(0.18, 0.13, 0.30), leather)
	_ellipsoid(root, "RightLoafer", Vector3(0.12, 0.065, 0.115), Vector3(0.18, 0.13, 0.30), leather)
	_limb(root, "LeftTrouser", Vector3(-0.115, 0.15, 0.012), Vector3(-0.10, 0.84, -0.025), 0.084, trousers)
	_limb(root, "RightTrouser", Vector3(0.12, 0.15, 0.055), Vector3(0.10, 0.84, -0.025), 0.084, trousers)

	# A rounded, pear-shaped cardigan; the upper body leans gently toward +Z.
	var body_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.205, 0.035),
		Vector2(0.222, 0.18), Vector2(0.215, 0.35), Vector2(0.195, 0.49),
		Vector2(0.15, 0.555), Vector2(0.075, 0.58), Vector2(0.0, 0.58),
	])
	var body: MeshInstance3D = Kit.add(root, Kit.lathe(body_profile, 16), coat, Vector3(0.0, 0.735, -0.02))
	body.name = "SoftCardigan"
	body.scale.z = 0.74
	body.rotation_degrees.x = 7.0
	_ellipsoid(root, "CreamShirt", Vector3(0.0, 1.19, 0.177), Vector3(0.18, 0.23, 0.058), linen)
	_ellipsoid(root, "Neck", Vector3(0.0, 1.32, 0.075), Vector3(0.13, 0.17, 0.125), skin)
	var scarf_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.075, 0.0), Vector2(0.12, 0.012), Vector2(0.129, 0.044),
		Vector2(0.117, 0.082), Vector2(0.073, 0.089), Vector2(0.075, 0.0),
	])
	var scarf: MeshInstance3D = Kit.add(root, Kit.lathe(scarf_profile, 16), linen, Vector3(0.0, 1.26, 0.085))
	scarf.name = "FoldedLinenScarf"
	scarf.scale.z = 0.83
	var scarf_tail: MeshInstance3D = _ellipsoid(root, "ScarfEnd", Vector3(-0.065, 1.155, 0.195), Vector3(0.085, 0.265, 0.036), linen)
	scarf_tail.rotation_degrees.z = -10.0

	# Relaxed elbows with the hands genuinely meeting the two accessory handles.
	_limb(root, "CaneUpperSleeve", Vector3(0.18, 1.245, 0.048), Vector3(0.31, 1.025, 0.055), 0.085, coat)
	_limb(root, "CaneLowerSleeve", Vector3(0.31, 1.025, 0.055), Vector3(0.42, 0.954, 0.283), 0.069, coat)
	_limb(root, "BagUpperSleeve", Vector3(-0.18, 1.245, 0.048), Vector3(-0.315, 1.035, -0.008), 0.085, coat)
	_limb(root, "BagLowerSleeve", Vector3(-0.315, 1.035, -0.008), Vector3(-0.48, 0.885, -0.02), 0.066, coat)
	_ellipsoid(root, "CaneHand", Vector3(0.437, 0.955, 0.33), Vector3(0.09, 0.082, 0.105), skin)
	_ellipsoid(root, "BagHand", Vector3(-0.51, 0.861, -0.02), Vector3(0.10, 0.092, 0.084), skin)

	# Forward-set head, little ears and a softly faceted silver hairline.
	var head_at: Vector3 = Vector3(0.0, 1.48, 0.09)
	_ellipsoid(root, "Face", head_at, Vector3(0.316, 0.405, 0.296), skin)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(root, "Ear", Vector3(side * 0.156, 1.462, 0.088), Vector3(0.052, 0.083, 0.06), skin)
	_ellipsoid(root, "Nose", Vector3(0.0, 1.46, 0.244), Vector3(0.058, 0.073, 0.064), skin)
	var hair: MeshInstance3D = Kit.add(root, _hair_mesh(style), silver, head_at)
	hair.name = "SilverHair"
	hair.scale = Vector3(0.166, 0.216, 0.158)
	if style == 1:
		_ellipsoid(root, "SilverBun", Vector3(0.0, 1.573, -0.065), Vector3(0.14, 0.14, 0.125), silver)
	elif style == 2:
		_ellipsoid(root, "WalnutBeret", Vector3(0.015, 1.668, 0.073), Vector3(0.34, 0.117, 0.29), Kit.fabric(Kit.WALNUT, "elder_beret"))
		_ellipsoid(root, "BeretStem", Vector3(0.035, 1.73, 0.065), Vector3(0.025, 0.025, 0.028), leather)

	var eyes: MeshInstance3D = Kit.add(root, _cluster("eyes", PackedVector3Array([
		Vector3(-0.063, 1.499, 0.231), Vector3(0.063, 1.499, 0.231),
	]), Vector3(0.018, 0.023, 0.012)), rubber, Vector3.ZERO)
	eyes.name = "KindEyes"
	var frames: Array[PackedVector3Array] = []
	for side: float in [-1.0, 1.0]:
		frames.append(_ellipse_path(Vector3(side * 0.063, 1.493, 0.242), Vector2(0.052, 0.043), 16))
		frames.append(PackedVector3Array([
			Vector3(side * 0.115, 1.5, 0.242), Vector3(side * 0.151, 1.507, 0.185),
			Vector3(side * 0.166, 1.488, 0.09),
		]))
	frames.append(PackedVector3Array([Vector3(-0.012, 1.5, 0.245), Vector3(0.0, 1.511, 0.253), Vector3(0.012, 1.5, 0.245)]))
	Kit.add(root, _tubes("spectacles", frames, 0.0055), Kit.brass(), Vector3.ZERO).name = "RoundBrassSpectacles"
	var brows: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(-0.097, 1.543, 0.212), Vector3(-0.068, 1.553, 0.221), Vector3(-0.035, 1.546, 0.226)]),
		PackedVector3Array([Vector3(0.035, 1.546, 0.226), Vector3(0.068, 1.553, 0.221), Vector3(0.097, 1.543, 0.212)]),
	]
	Kit.add(root, _tubes("brows", brows, 0.0065), silver, Vector3.ZERO).name = "SilverBrows"
	Kit.add(root, _cluster("buttons", PackedVector3Array([
		Vector3(0.016, 1.065, 0.185), Vector3(0.016, 0.96, 0.169), Vector3(0.016, 0.855, 0.155),
	]), Vector3(0.022, 0.022, 0.011)), walnut, Vector3.ZERO).name = "WoodenButtons"
	var seams: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(-0.008, 1.1, 0.188), Vector3(-0.008, 0.96, 0.174), Vector3(-0.008, 0.795, 0.148)]),
		PackedVector3Array([Vector3(-0.17, 0.955, 0.112), Vector3(-0.158, 0.886, 0.129), Vector3(-0.078, 0.887, 0.155), Vector3(-0.068, 0.956, 0.165)]),
		PackedVector3Array([Vector3(0.068, 0.956, 0.165), Vector3(0.078, 0.887, 0.155), Vector3(0.158, 0.886, 0.129), Vector3(0.17, 0.955, 0.112)]),
	]
	Kit.add(root, _tubes("cardigan_seams", seams, 0.0038), Kit.fabric(coat_colors[style].lightened(0.16), "elder_seams_%d" % style), Vector3.ZERO).name = "CardiganPocketSeams"

	# One continuous carved cane, with a generous crook, brass ferrule and rubber sole.
	var crook: PackedVector3Array = PackedVector3Array([Vector3(0.44, 0.037, 0.27), Vector3(0.44, 0.897, 0.27)])
	for step: int in range(1, 13):
		var angle: float = PI * float(step) / 12.0
		crook.append(Vector3(0.44, 0.897 + sin(angle) * 0.077, 0.347 - cos(angle) * 0.077))
	var cane_paths: Array[PackedVector3Array] = [crook]
	Kit.add(root, _tubes("cane", cane_paths, 0.018, 8), walnut, Vector3.ZERO).name = "WalnutCrookCane"
	var foot_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.021, 0.0), Vector2(0.027, 0.005),
		Vector2(0.025, 0.039), Vector2(0.018, 0.049), Vector2(0.0, 0.049),
	])
	Kit.add(root, Kit.lathe(foot_profile, 12), rubber, Vector3(0.44, 0.0, 0.27)).name = "CaneRubberTip"
	_limb(root, "CaneBrassCollar", Vector3(0.44, 0.049, 0.27), Vector3(0.44, 0.084, 0.27), 0.019, Kit.brass())

	# A 34 cm cabin roller with a rounded fabric body, inset pocket and zipper welt.
	Kit.rbox(root, Vector3(0.34, 0.48, 0.255), Vector3(-0.51, 0.34, -0.065), bag_fabric, 0.065).name = "LinenCabinBag"
	Kit.rbox(root, Vector3(0.255, 0.305, 0.036), Vector3(-0.51, 0.324, 0.065), bag_fabric, 0.017).name = "BagFrontPocket"
	var piping: Array[PackedVector3Array] = [_rounded_rect_path(Vector3(-0.51, 0.34, 0.039), Vector2(0.30, 0.432), 0.05)]
	piping.append(PackedVector3Array([Vector3(-0.607, 0.446, 0.087), Vector3(-0.413, 0.446, 0.087), Vector3(-0.408, 0.408, 0.091)]))
	Kit.add(root, _tubes("bag_welt", piping, 0.005), Kit.brass(), Vector3.ZERO).name = "BagZipperAndPull"
	var wheel_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -0.026), Vector2(0.038, -0.026), Vector2(0.052, -0.017),
		Vector2(0.052, 0.017), Vector2(0.038, 0.026), Vector2(0.0, 0.026),
	])
	for wheel_x: float in [-0.636, -0.384]:
		Kit.add(root, Kit.lathe(wheel_profile, 16), rubber, Vector3(wheel_x, 0.052, -0.065), Vector3(0.0, 0.0, 90.0)).name = "BagWheel"
	var rails: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(-0.595, 0.535, -0.026), Vector3(-0.595, 0.855, -0.026)]),
		PackedVector3Array([Vector3(-0.425, 0.535, -0.026), Vector3(-0.425, 0.855, -0.026)]),
	]
	Kit.add(root, _tubes("bag_rails", rails, 0.011, 8), steel, Vector3.ZERO).name = "TelescopicHandleRails"
	_limb(root, "BagLeatherGrip", Vector3(-0.612, 0.855, -0.026), Vector3(-0.408, 0.855, -0.026), 0.019, leather)
	# Shared airport pictogram, with no tiny lettering on the luggage.
	Kit.add(root, _patch_mesh(), Signs._icon_material("plane", Color(0.0, 0.0, 0.0, 0.0)), Vector3(-0.51, 0.315, 0.084), Vector3.ZERO, false).name = "AirportPlanePatch"
	return root


static func _sphere() -> SphereMesh:
	if _meshes.has("sphere"):
		return _meshes["sphere"] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_meshes["sphere"] = mesh
	return mesh


static func _ellipsoid(parent: Node3D, part_name: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, _sphere(), material, at)
	node.name = part_name
	node.scale = size * 0.5
	return node


static func _limb(parent: Node3D, part_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var length: float = start.distance_to(end)
	var safe_radius: float = minf(radius, length * 0.49)
	var key: String = "capsule:%.5f:%.5f" % [safe_radius, length]
	var mesh: CapsuleMesh
	if _meshes.has(key):
		mesh = _meshes[key] as CapsuleMesh
	else:
		mesh = CapsuleMesh.new()
		mesh.radius = safe_radius
		mesh.height = length
		mesh.radial_segments = 12
		mesh.rings = 4
		_meshes[key] = mesh
	var node: MeshInstance3D = Kit.add(parent, mesh, material, (start + end) * 0.5)
	node.name = part_name
	node.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return node


static func _cluster(key: String, centers: PackedVector3Array, size: Vector3) -> ArrayMesh:
	var cache_key: String = "cluster:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for center: Vector3 in centers:
		surface.append_from(_sphere(), 0, Transform3D(Basis.from_scale(size * 0.5), center))
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _hair_mesh(style: int) -> ArrayMesh:
	var key: String = "hair:%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: int in range(16):
		for row: int in range(5):
			var points: PackedVector3Array = PackedVector3Array()
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)]:
				var azimuth: float = TAU * float(side + corner.x) / 16.0
				var front: float = maxf(0.0, sin(azimuth))
				var hairline: float = 1.74 - front * (0.66 if style != 1 else 0.46)
				var sweep: float = 0.075 * cos(azimuth) * front
				var polar: float = (hairline + sweep) * float(row + corner.y) / 5.0
				points.append(Vector3(sin(polar) * cos(azimuth), cos(polar), sin(polar) * sin(azimuth)))
			for index: int in [0, 1, 2, 2, 1, 3]:
				surface.set_normal(points[index].normalized())
				surface.add_vertex(points[index])
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _ellipse_path(center: Vector3, radii: Vector2, segments: int) -> PackedVector3Array:
	var path: PackedVector3Array = PackedVector3Array()
	for index: int in range(segments + 1):
		var angle: float = TAU * float(index) / float(segments)
		path.append(center + Vector3(cos(angle) * radii.x, sin(angle) * radii.y, 0.0))
	return path


static func _rounded_rect_path(center: Vector3, size: Vector2, radius: float) -> PackedVector3Array:
	var path: PackedVector3Array = PackedVector3Array()
	for corner: int in range(4):
		var middle: float = PI * 0.25 + float(corner) * PI * 0.5
		var pivot: Vector3 = center + Vector3(signf(cos(middle)) * (size.x * 0.5 - radius), signf(sin(middle)) * (size.y * 0.5 - radius), 0.0)
		for step: int in range(5):
			var angle: float = float(corner) * PI * 0.5 + float(step) * PI * 0.125
			path.append(pivot + Vector3(cos(angle) * radius, sin(angle) * radius, 0.0))
	path.append(path[0])
	return path


static func _tubes(key: String, paths: Array[PackedVector3Array], radius: float, sides: int = 6) -> ArrayMesh:
	var cache_key: String = "tube:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for path: PackedVector3Array in paths:
		var vertices: PackedVector3Array = PackedVector3Array()
		var normals: PackedVector3Array = PackedVector3Array()
		for ring: int in range(path.size()):
			var before: Vector3 = path[maxi(0, ring - 1)]
			var after: Vector3 = path[mini(path.size() - 1, ring + 1)]
			var tangent: Vector3 = (after - before).normalized()
			var reference: Vector3 = Vector3.RIGHT if absf(tangent.dot(Vector3.FORWARD)) > 0.92 else Vector3.FORWARD
			var axis_u: Vector3 = tangent.cross(reference).normalized()
			var axis_v: Vector3 = axis_u.cross(tangent).normalized()
			for side: int in range(sides):
				var angle: float = TAU * float(side) / float(sides)
				var normal: Vector3 = axis_u * cos(angle) + axis_v * sin(angle)
				vertices.append(path[ring] + normal * radius)
				normals.append(normal)
		for ring: int in range(path.size() - 1):
			for side: int in range(sides):
				var a: int = ring * sides + side
				var b: int = (ring + 1) * sides + side
				var c: int = ring * sides + (side + 1) % sides
				var d: int = (ring + 1) * sides + (side + 1) % sides
				for index: int in [a, b, c, c, b, d]:
					surface.set_normal(normals[index])
					surface.add_vertex(vertices[index])
		# Seal the two ends; closed paths already meet themselves.
		if not path[0].is_equal_approx(path[path.size() - 1]):
			for end_index: int in [0, path.size() - 1]:
				var outward: Vector3 = (path[0] - path[1]).normalized() if end_index == 0 else (path[end_index] - path[end_index - 1]).normalized()
				for side: int in range(sides):
					var a: int = end_index * sides + side
					var b: int = end_index * sides + (side + 1) % sides
					var cap: PackedVector3Array = PackedVector3Array([path[end_index], vertices[b], vertices[a]]) if end_index == 0 else PackedVector3Array([path[end_index], vertices[a], vertices[b]])
					for point: Vector3 in cap:
						surface.set_normal(outward)
						surface.add_vertex(point)
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _patch_mesh() -> QuadMesh:
	if _meshes.has("plane_patch"):
		return _meshes["plane_patch"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.095, 0.095)
	_meshes["plane_patch"] = mesh
	return mesh
