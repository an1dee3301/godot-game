extends RefCounted
## A welcoming ramen chef: woven whites, a tied hachimaki and a bowl ready to serve.
## Garments carry a shared dining pictogram instead of lettering at an illegible scale.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var style: int = posmod(variant, 3)
	var apron_colors: Array[Color] = [Kit.SAGE.darkened(0.12), Kit.CLAY.darkened(0.10), Kit.INDIGO]
	var skin_colors: Array[Color] = [Color(0.81, 0.57, 0.40), Color(0.48, 0.30, 0.22), Color(0.94, 0.73, 0.56)]
	var hair_colors: Array[Color] = [Color(0.12, 0.095, 0.078), Kit.WALNUT.darkened(0.34), Color(0.28, 0.28, 0.26)]
	var white: StandardMaterial3D = Kit.fabric(Color(0.96, 0.95, 0.90), "chef_cotton_white")
	var linen: StandardMaterial3D = Kit.fabric(Kit.CREAM, "chef_folded_linen")
	var apron: StandardMaterial3D = Kit.fabric(apron_colors[style], "chef_apron_%d" % style)
	var trim: StandardMaterial3D = Kit.fabric(apron_colors[style].lightened(0.18), "chef_trim_%d" % style)
	var trousers: StandardMaterial3D = Kit.fabric(Kit.CHARCOAL, "chef_trousers")
	var skin: StandardMaterial3D = Kit.paint(skin_colors[style], 0.83)
	var hair: StandardMaterial3D = Kit.paint(hair_colors[style], 0.78)
	var dark: StandardMaterial3D = Kit.paint(Kit.CHARCOAL.darkened(0.52), 0.52)
	var root: Node3D = Node3D.new()
	root.name = "PersonChef_%d" % style
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	# Broad, softly rounded work clogs have separate rubber soles touching the floor.
	var soles: Array[Transform3D] = [
		_pose(Vector3(-0.115, 0.022, 0.063), Vector3(0.087, 0.022, 0.150)),
		_pose(Vector3(0.115, 0.022, 0.025), Vector3(0.087, 0.022, 0.150)),
	]
	var shoes: Array[Transform3D] = [
		_pose(Vector3(-0.115, 0.070, 0.066), Vector3(0.082, 0.055, 0.141)),
		_pose(Vector3(0.115, 0.070, 0.028), Vector3(0.082, 0.055, 0.141)),
	]
	_part(root, "GroundedRubberSoles", _cluster("soles", _sphere(), soles), dark)
	_part(root, "RoundedKitchenClogs", _cluster("clogs", _sphere(), shoes), Kit.paint(Kit.CHARCOAL, 0.38))
	var legs: Array[Transform3D] = [
		_limb_pose(Vector3(-0.115, 0.083, 0.015), Vector3(-0.102, 0.952, 0.0), 0.091),
		_limb_pose(Vector3(0.115, 0.083, -0.023), Vector3(0.102, 0.952, 0.0), 0.091),
	]
	_part(root, "RelaxedTrouserLegs", _cluster("legs", _limb(), legs), trousers)
	var jacket: MeshInstance3D = _part(root, "RoundedWhiteChefJacket", Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.858), Vector2(0.179, 0.858), Vector2(0.205, 0.883),
		Vector2(0.213, 0.944), Vector2(0.204, 1.049), Vector2(0.222, 1.169),
		Vector2(0.237, 1.254), Vector2(0.217, 1.299), Vector2(0.098, 1.335), Vector2(0.0, 1.337),
	]), 20), white)
	jacket.scale.z = 0.69

	# The left palm supports the bowl; the right hand holds chopsticks over its rim.
	var sleeves: Array[Transform3D] = [
		_limb_pose(Vector3(-0.203, 1.268, 0.0), Vector3(-0.332, 1.053, 0.080), 0.088),
		_limb_pose(Vector3(0.203, 1.268, 0.0), Vector3(0.329, 1.043, 0.080), 0.088),
	]
	_part(root, "SoftShortSleeves", _cluster("sleeves", _limb(), sleeves), white)
	var cuffs: Array[Transform3D] = [
		_pose(Vector3(-0.307, 1.095, 0.065), Vector3(0.080, 0.035, 0.074), -30.0),
		_pose(Vector3(0.306, 1.089, 0.065), Vector3(0.080, 0.035, 0.074), 30.0),
	]
	_part(root, "RolledLinenCuffs", _cluster("cuffs", _sphere(), cuffs), linen)
	var forearms: Array[Transform3D] = [
		_limb_pose(Vector3(-0.317, 1.073, 0.072), Vector3(-0.174, 1.073, 0.348), 0.054),
		_limb_pose(Vector3(0.316, 1.062, 0.075), Vector3(0.209, 1.208, 0.330), 0.053),
	]
	_part(root, "BentForearms", _cluster("forearms", _limb(), forearms), skin)
	var hands: Array[Transform3D] = [
		_pose(Vector3(-0.165, 1.076, 0.343), Vector3(0.067, 0.038, 0.052), 12.0),
		_pose(Vector3(0.208, 1.204, 0.336), Vector3(0.041, 0.055, 0.040), -32.0),
	]
	_part(root, "ServingHands", _cluster("hands", _sphere(), hands), skin)
	_ellipsoid(root, "Neck", Vector3(0.0, 1.359, 0.0), Vector3(0.063, 0.086, 0.058), skin)
	_part(root, "CrossedJacketCollar", _cloth("collar", [PackedVector3Array([
		Vector3(-0.061, 1.347, 0.052), Vector3(-0.149, 1.300, 0.120),
		Vector3(0.017, 1.189, 0.159), Vector3(0.053, 1.224, 0.160),
	]), PackedVector3Array([
		Vector3(0.061, 1.347, 0.052), Vector3(0.149, 1.300, 0.120),
		Vector3(0.059, 1.231, 0.157), Vector3(0.017, 1.270, 0.157),
	])]), linen)
	var buttons: Array[Transform3D] = []
	for x: float in [-0.076, 0.076]:
		for y: float in [1.099, 1.164]:
			buttons.append(_pose(Vector3(x, y, 0.145), Vector3(0.010, 0.010, 0.008)))
	_part(root, "FourClothCoveredButtons", _cluster("buttons", _sphere(), buttons), linen)

	# A curved, softly scalloped waist apron wraps the jacket rather than forming a slab.
	_part(root, "DrapedWaistApron", _apron_mesh(), apron)
	var sash: MeshInstance3D = _part(root, "WovenWaistTie", Kit.lathe(PackedVector2Array([
		Vector2(0.198, 1.002), Vector2(0.211, 1.005), Vector2(0.215, 1.020),
		Vector2(0.211, 1.050), Vector2(0.201, 1.054), Vector2(0.198, 1.002),
	]), 20), trim)
	sash.scale.z = 0.79
	_part(root, "ApronPatchPocket", _cloth("pocket", [PackedVector3Array([
		Vector3(-0.073, 0.925, 0.184), Vector3(0.073, 0.925, 0.184),
		Vector3(0.067, 0.824, 0.191), Vector3(0.050, 0.811, 0.192),
		Vector3(-0.050, 0.811, 0.192), Vector3(-0.067, 0.824, 0.191),
	])]), trim)
	_part(root, "SharedDiningPictogram", _badge(), Signs._icon_material("cup", Color(0.0, 0.0, 0.0, 0.0)), Vector3(0.0, 0.872, 0.206), false)
	_part(root, "FoldedServiceTowel", _cloth("towel", [PackedVector3Array([
		Vector3(0.135, 1.040, 0.153), Vector3(0.190, 1.031, 0.104),
		Vector3(0.211, 0.796, 0.103), Vector3(0.181, 0.780, 0.142), Vector3(0.143, 0.803, 0.170),
	])], 0.014), linen)

	var head: MeshInstance3D = _part(root, "SoftFacetedFace", Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.174), Vector2(0.063, -0.163), Vector2(0.116, -0.125),
		Vector2(0.153, -0.055), Vector2(0.158, 0.033), Vector2(0.142, 0.112),
		Vector2(0.096, 0.164), Vector2(0.0, 0.190),
	]), 20), skin, Vector3(0.0, 1.544, 0.0))
	head.scale.z = 0.91
	var ears: Array[Transform3D] = [
		_pose(Vector3(-0.154, 1.542, 0.0), Vector3(0.024, 0.038, 0.029)),
		_pose(Vector3(0.154, 1.542, 0.0), Vector3(0.024, 0.038, 0.029)),
	]
	_part(root, "Ears", _cluster("ears", _sphere(), ears), skin)
	var eyes: Array[Transform3D] = [
		_pose(Vector3(-0.055, 1.566, 0.147), Vector3(0.012, 0.014, 0.004)),
		_pose(Vector3(0.055, 1.566, 0.147), Vector3(0.012, 0.014, 0.004)),
	]
	_part(root, "FriendlyEyes", _cluster("eyes", _sphere(), eyes), dark)
	_ellipsoid(root, "SmallNose", Vector3(0.0, 1.526, 0.143), Vector3(0.021, 0.023, 0.019), skin)
	_part(root, "QuietSmile", _tube("smile", PackedVector3Array([
		Vector3(-0.028, 1.483, 0.140), Vector3(-0.014, 1.476, 0.146),
		Vector3(0.0, 1.474, 0.149), Vector3(0.014, 1.476, 0.146), Vector3(0.028, 1.483, 0.140),
	]), 0.0035), Kit.paint(skin_colors[style].darkened(0.43)))
	_part(root, "CroppedHair", _hair_mesh(style), hair, Vector3(0.0, 1.544, 0.0))
	# Both sides of the band clear the hair; match its elliptical cross-section.
	var band: MeshInstance3D = _part(root, "WhiteHachimaki", Kit.lathe(PackedVector2Array([
		Vector2(0.178, 1.616), Vector2(0.186, 1.616), Vector2(0.185, 1.625),
		Vector2(0.160, 1.672), Vector2(0.155, 1.680), Vector2(0.151, 1.675), Vector2(0.178, 1.616),
	]), 20), white)
	band.scale.z = 0.166 / 0.180
	_ellipsoid(root, "HeadbandKnot", Vector3(0.144, 1.643, -0.086), Vector3(0.035, 0.029, 0.033), linen)
	_part(root, "TiedHeadbandTails", _cloth("headband_tails", [PackedVector3Array([
		Vector3(0.146, 1.645, -0.075), Vector3(0.174, 1.642, -0.083),
		Vector3(0.239, 1.552, -0.098), Vector3(0.213, 1.532, -0.088), Vector3(0.189, 1.564, -0.070),
	]), PackedVector3Array([
		Vector3(0.140, 1.645, -0.108), Vector3(0.170, 1.635, -0.103),
		Vector3(0.180, 1.481, -0.119), Vector3(0.145, 1.495, -0.129),
	])], 0.008), white)
	if style == 1:
		_ellipsoid(root, "TuckedHairBun", Vector3(0.0, 1.626, -0.138), Vector3(0.080, 0.076, 0.069), hair)
	elif style == 2:
		_part(root, "WalnutPocketPen", _tube("pen", PackedVector3Array([
			Vector3(-0.047, 0.887, 0.202), Vector3(-0.047, 0.970, 0.201),
		]), 0.007), Kit.wood(Kit.WALNUT, "chef_pen_walnut"))

	_build_ramen(root, style)
	return root


static func _build_ramen(parent: Node3D, style: int) -> void:
	var bowl_colors: Array[Color] = [Kit.CREAM, Kit.SAGE.lightened(0.30), Kit.CLAY.lightened(0.24)]
	var bowl_at: Vector3 = Vector3(-0.058, 1.088, 0.350)
	var ceramic: StandardMaterial3D = Kit.stone(bowl_colors[style], 0.28, "chef_ceramic_%d" % style)
	_part(parent, "FootedStonewareRamenBowl", Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.068, 0.0), Vector2(0.075, 0.012),
		Vector2(0.075, 0.027), Vector2(0.096, 0.035), Vector2(0.132, 0.069),
		Vector2(0.158, 0.122), Vector2(0.157, 0.133), Vector2(0.147, 0.135),
		Vector2(0.140, 0.120), Vector2(0.116, 0.071), Vector2(0.075, 0.046), Vector2(0.0, 0.043),
	]), 24), ceramic, bowl_at)
	_part(parent, "DarkGlazedBowlLip", Kit.lathe(PackedVector2Array([
		Vector2(0.149, 0.123), Vector2(0.159, 0.123), Vector2(0.162, 0.130),
		Vector2(0.157, 0.137), Vector2(0.147, 0.135), Vector2(0.145, 0.129), Vector2(0.149, 0.123),
	]), 24), Kit.paint(Kit.WALNUT.darkened(0.24), 0.25), bowl_at)
	_part(parent, "MisoBroth", Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.114), Vector2(0.139, 0.114), Vector2(0.141, 0.117), Vector2(0.0, 0.117),
	]), 24), Kit.paint(Kit.OCHRE.darkened(0.18), 0.30), bowl_at)
	var noodles: ArrayMesh = _noodles()
	_part(parent, "CurledNoodles", noodles, Kit.paint(Kit.CREAM, 0.67), bowl_at)
	_ellipsoid(parent, "EggHalf", bowl_at + Vector3(-0.061, 0.121, -0.041), Vector3(0.044, 0.012, 0.057), Kit.paint(Color(0.98, 0.96, 0.86), 0.55))
	_ellipsoid(parent, "GoldenEggYolk", bowl_at + Vector3(-0.061, 0.133, -0.035), Vector3(0.024, 0.008, 0.028), Kit.paint(Kit.OCHRE.lightened(0.13), 0.44))
	var greens: Array[Transform3D] = [
		_pose(bowl_at + Vector3(0.064, 0.125, -0.051), Vector3(0.042, 0.012, 0.022), 8.0),
		_pose(bowl_at + Vector3(0.052, 0.126, -0.084), Vector3(0.029, 0.012, 0.016), -8.0),
	]
	_part(parent, "SageGreenGarnish", _cluster("greens", _sphere(), greens), Kit.paint(Kit.SAGE.darkened(0.35), 0.81))
	var sticks: Array[Transform3D] = [
		_limb_pose(Vector3(0.021, 1.221, 0.376), Vector3(0.301, 1.321, 0.318), 0.007),
		_limb_pose(Vector3(0.028, 1.220, 0.393), Vector3(0.313, 1.310, 0.337), 0.007),
	]
	_part(parent, "OakCookingChopsticks", _cluster("chopsticks", _limb(), sticks), Kit.wood(Kit.OAK, "chef_chopstick_oak"))


static func _part(parent: Node3D, part_name: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, mesh, material, at, Vector3.ZERO, shadows)
	node.name = part_name
	return node


static func _ellipsoid(parent: Node3D, part_name: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = _part(parent, part_name, _sphere(), material, at)
	node.scale = radii
	return node


static func _pose(at: Vector3, radii: Vector3, roll: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, deg_to_rad(roll)) * Basis.from_scale(radii), at)


static func _limb_pose(start: Vector3, end: Vector3, radius: float) -> Transform3D:
	var delta: Vector3 = end - start
	return Transform3D(Basis(Quaternion(Vector3.UP, delta.normalized())) * Basis.from_scale(Vector3(radius, delta.length(), radius)), start)


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


static func _limb() -> ArrayMesh:
	return Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.64, 0.025), Vector2(0.92, 0.08),
		Vector2(1.0, 0.19), Vector2(0.96, 0.76), Vector2(0.79, 0.94), Vector2(0.0, 1.0),
	]), 12)


static func _badge() -> QuadMesh:
	if _meshes.has("badge"):
		return _meshes["badge"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.071, 0.071)
	_meshes["badge"] = mesh
	return mesh


static func _cluster(key: String, source: Mesh, poses: Array[Transform3D]) -> ArrayMesh:
	var cache_key: String = "cluster:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pose: Transform3D in poses:
		surface.append_from(source, 0, pose)
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	for point: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x, point.y))
		surface.add_vertex(point)


static func _cloth(key: String, panels: Array[PackedVector3Array], fold: float = 0.007) -> ArrayMesh:
	var cache_key: String = "cloth:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for outline: PackedVector3Array in panels:
		var points: PackedVector3Array = outline.duplicate()
		var center: Vector3 = Vector3.ZERO
		var area: float = 0.0
		for i: int in points.size():
			var p: Vector3 = points[i]
			var q: Vector3 = points[(i + 1) % points.size()]
			center += p
			area += p.x * q.y - q.x * p.y
		center /= float(points.size())
		if area > 0.0:
			points.reverse()
		var back: Vector3 = Vector3(0.0, 0.0, -0.006)
		for i: int in points.size():
			var p: Vector3 = points[i]
			var q: Vector3 = points[(i + 1) % points.size()]
			_triangle(surface, center + Vector3(0.0, 0.0, fold), p, q)
			_triangle(surface, center + back, q + back, p + back)
			_triangle(surface, p, p + back, q)
			_triangle(surface, q, p + back, q + back)
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _apron_mesh() -> ArrayMesh:
	if _meshes.has("apron"):
		return _meshes["apron"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in 5:
		for column: int in 16:
			var a: Vector3 = _apron_point(float(column) / 16.0, float(row) / 5.0)
			var b: Vector3 = _apron_point(float(column + 1) / 16.0, float(row) / 5.0)
			var c: Vector3 = _apron_point(float(column) / 16.0, float(row + 1) / 5.0)
			var d: Vector3 = _apron_point(float(column + 1) / 16.0, float(row + 1) / 5.0)
			_triangle(surface, a, c, b)
			_triangle(surface, b, c, d)
			var back: Vector3 = Vector3(0.0, 0.0, -0.005)
			_triangle(surface, a + back, b + back, c + back)
			_triangle(surface, b + back, d + back, c + back)
	var mesh: ArrayMesh = surface.commit()
	_meshes["apron"] = mesh
	return mesh


static func _apron_point(u: float, v: float) -> Vector3:
	var angle: float = lerpf(-1.22, 1.22, u)
	var width: float = lerpf(0.218, 0.216, v)
	var depth: float = lerpf(0.185, 0.169, v)
	var pleat: float = 0.006 * cos(u * TAU * 3.0) * (1.0 - v)
	var hem: float = 0.022 * pow(absf(2.0 * u - 1.0), 4.0) * (1.0 - v)
	return Vector3(sin(angle) * width, lerpf(0.619, 1.034, v) + hem, cos(angle) * depth + pleat)


static func _hair_mesh(style: int) -> ArrayMesh:
	var key: String = "hair:%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in 20:
		var a: float = TAU * float(segment) / 20.0
		var b: float = TAU * float(segment + 1) / 20.0
		for ring: int in 7:
			var lo: float = float(ring) / 7.0
			var hi: float = float(ring + 1) / 7.0
			var p: Vector3 = _hair_point(a, lo, style)
			var q: Vector3 = _hair_point(b, lo, style)
			var r: Vector3 = _hair_point(a, hi, style)
			var s: Vector3 = _hair_point(b, hi, style)
			# Clockwise winding gives outward normals, including the closed crown.
			if ring == 0:
				_triangle(surface, p, s, r)
			else:
				_triangle(surface, p, q, r)
				_triangle(surface, q, s, r)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _hair_point(angle: float, fraction: float, style: int) -> Vector3:
	var hairline: float = lerpf(1.99, 1.01, maxf(cos(angle), 0.0))
	var sweep: float = 0.08 * sin(angle) if style != 1 else 0.0
	var polar: float = fraction * (hairline + sweep)
	# The previous ellipsoid crossed the forehead profile. These radii provide
	# at least 6 mm of clearance even between the low-poly rings and facets.
	return Vector3(sin(angle) * sin(polar) * 0.180, cos(polar) * 0.211, cos(angle) * sin(polar) * 0.166)


static func _tube(key: String, points: PackedVector3Array, radius: float) -> ArrayMesh:
	var poses: Array[Transform3D] = []
	for i: int in points.size() - 1:
		poses.append(_limb_pose(points[i], points[i + 1], radius))
	return _cluster("tube:" + key, _limb(), poses)


static func _noodles() -> ArrayMesh:
	if _meshes.has("noodles"):
		return _meshes["noodles"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for strand: int in 3:
		var points: PackedVector3Array = PackedVector3Array()
		for step: int in 13:
			var angle: float = float(step) / 12.0 * TAU * 1.30 + float(strand)
			var radius: float = 0.025 + float(step) * 0.004
			points.append(Vector3(cos(angle) * radius, 0.122 + float(strand) * 0.0015, sin(angle) * radius + 0.014))
		surface.append_from(_tube("noodle_%d" % strand, points, 0.004), 0, Transform3D.IDENTITY)
	var mesh: ArrayMesh = surface.commit()
	_meshes["noodles"] = mesh
	return mesh
