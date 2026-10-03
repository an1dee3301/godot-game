extends RefCounted
## A calm cabin-crew silhouette: shaped tailoring, a folded scarf and a wheeled carry-on.
## The airport's shared pictogram supplies insignia; there is no miniature lettering.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var style: int = posmod(variant, 3)
	var uniforms: Array[Color] = [Kit.SAGE.darkened(0.29), Kit.INDIGO, Kit.WALNUT]
	var scarves: Array[Color] = [Kit.CLAY, Kit.CREAM, Kit.SAGE]
	var skins: Array[Color] = [Color(0.76, 0.51, 0.36), Color(0.91, 0.70, 0.53), Color(0.48, 0.29, 0.20)]
	var hairs: Array[Color] = [Color(0.12, 0.09, 0.075), Color(0.25, 0.16, 0.10), Color(0.08, 0.075, 0.065)]
	var suit: StandardMaterial3D = Kit.fabric(uniforms[style], "attendant_suit_%d" % style)
	var lapel: StandardMaterial3D = Kit.fabric(uniforms[style].lightened(0.09), "attendant_lapel_%d" % style)
	var scarf: StandardMaterial3D = Kit.fabric(scarves[style], "attendant_scarf_%d" % style)
	var linen: StandardMaterial3D = Kit.fabric(Kit.CREAM, "attendant_shirt")
	var skin: StandardMaterial3D = Kit.paint(skins[style], 0.82)
	var hair: StandardMaterial3D = Kit.paint(hairs[style], 0.75)
	var leather: StandardMaterial3D = Kit.paint(Kit.CHARCOAL.darkened(0.32), 0.4)
	var root: Node3D = Node3D.new()
	root.name = "PersonAttendant_%d" % style
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	# The two soles touch y = 0, with a subtly staggered, adult standing posture.
	var shoe_poses: Array[Transform3D] = [
		_pose(Vector3(-0.089, 0.058, 0.069), Vector3(0.066, 0.042, 0.133)),
		_pose(Vector3(0.088, 0.058, 0.018), Vector3(0.066, 0.042, 0.133)),
	]
	var sole_poses: Array[Transform3D] = [
		_pose(Vector3(-0.089, 0.017, 0.069), Vector3(0.067, 0.017, 0.135)),
		_pose(Vector3(0.088, 0.017, 0.018), Vector3(0.067, 0.017, 0.135)),
	]
	_part(root, "SoftLeatherLoafers", _cluster("shoes", _sphere(), shoe_poses), leather)
	_part(root, "GroundedRubberSoles", _cluster("soles", _sphere(), sole_poses), Kit.paint(Kit.CHARCOAL.darkened(0.55)))
	var leg_material: Material = suit if style == 1 else Kit.fabric(skins[style].darkened(0.23), "attendant_stockings_%d" % style)
	var leg_radius: float = 0.076 if style == 1 else 0.047
	_between(root, "LeftLeg", Vector3(-0.089, 0.069, 0.025), Vector3(-0.081, 0.952, 0.0), leg_radius, leg_material)
	_between(root, "RightLeg", Vector3(0.088, 0.069, -0.022), Vector3(0.079, 0.952, 0.0), leg_radius, leg_material)
	if style != 1:
		# Tuck the hidden waist inside the jacket, rather than crossing its hem.
		var skirt: MeshInstance3D = _part(root, "ShapedMidiSkirt", _lathe(PackedVector2Array([
			Vector2(0.0, 0.607), Vector2(0.163, 0.607), Vector2(0.174, 0.620),
			Vector2(0.181, 0.700), Vector2(0.188, 0.820), Vector2(0.145, 0.852),
			Vector2(0.134, 0.950), Vector2(0.0, 0.955),
		]), 16), suit)
		skirt.scale.z = 0.68

	var jacket: MeshInstance3D = _part(root, "TailoredJacket", _lathe(PackedVector2Array([
		Vector2(0.0, 0.862), Vector2(0.162, 0.862), Vector2(0.181, 0.883),
		Vector2(0.178, 0.935), Vector2(0.151, 1.039), Vector2(0.166, 1.144),
		Vector2(0.207, 1.239), Vector2(0.210, 1.262), Vector2(0.180, 1.294),
		Vector2(0.089, 1.321), Vector2(0.0, 1.324),
	]), 16), suit)
	jacket.scale.z = 0.67
	_between(root, "LeftUpperSleeve", Vector3(-0.186, 1.253, 0.0), Vector3(-0.266, 1.057, 0.025), 0.068, suit)
	_between(root, "LeftForearm", Vector3(-0.266, 1.071, 0.025), Vector3(-0.247, 0.922, 0.107), 0.052, suit)
	_between(root, "RightUpperSleeve", Vector3(0.187, 1.250, 0.0), Vector3(0.336, 1.075, -0.024), 0.068, suit)
	_between(root, "RightForearm", Vector3(0.328, 1.084, -0.025), Vector3(0.460, 0.963, -0.015), 0.051, suit)
	var cuff_poses: Array[Transform3D] = [
		_pose(Vector3(-0.248, 0.939, 0.100), Vector3(0.045, 0.018, 0.043), 7.0),
		_pose(Vector3(0.449, 0.974, -0.016), Vector3(0.044, 0.018, 0.042), 47.0),
	]
	_part(root, "LinenCuffs", _cluster("cuffs", _sphere(), cuff_poses), linen)
	var hand_poses: Array[Transform3D] = [
		_pose(Vector3(-0.244, 0.894, 0.122), Vector3(0.037, 0.052, 0.034), -9.0),
		_pose(Vector3(0.482, 0.950, -0.008), Vector3(0.045, 0.039, 0.038), 40.0),
	]
	_part(root, "RelaxedHands", _cluster("hands", _sphere(), hand_poses), skin)
	_ellipsoid(root, "Neck", Vector3(0.0, 1.338, 0.0), Vector3(0.056, 0.087, 0.052), skin)

	# Closed folds are 4 mm thick; successive layers clear the underlying ridge by 6 mm.
	_part(root, "LinenShirtFront", _folds("shirt", [PackedVector3Array([
		Vector3(-0.091, 1.299, 0.113), Vector3(0.091, 1.299, 0.113), Vector3(0.0, 1.110, 0.127),
	])]), linen)
	_part(root, "NotchedLapels", _folds("lapels", [PackedVector3Array([
		Vector3(-0.079, 1.307, 0.121), Vector3(-0.175, 1.245, 0.101),
		Vector3(-0.113, 1.194, 0.131), Vector3(-0.133, 1.165, 0.129), Vector3(-0.014, 1.086, 0.134),
	]), PackedVector3Array([
		Vector3(0.079, 1.307, 0.121), Vector3(0.175, 1.245, 0.101),
		Vector3(0.113, 1.194, 0.131), Vector3(0.133, 1.165, 0.129), Vector3(0.014, 1.086, 0.134),
	])]), lapel, Vector3(0.0, 0.0, 0.018))
	var button_poses: Array[Transform3D] = [
		_pose(Vector3(0.014, 1.057, 0.108), Vector3(0.009, 0.009, 0.005)),
		_pose(Vector3(0.014, 0.991, 0.117), Vector3(0.009, 0.009, 0.005)),
	]
	_part(root, "BrassJacketButtons", _cluster("buttons", _sphere(), button_poses), Kit.brass())
	var collar: MeshInstance3D = _part(root, "WrappedScarf", _lathe(PackedVector2Array([
		Vector2(0.048, -0.023), Vector2(0.069, -0.028), Vector2(0.080, -0.009),
		Vector2(0.074, 0.021), Vector2(0.053, 0.026), Vector2(0.048, -0.023),
	]), 16), scarf, Vector3(0.0, 1.342, 0.0))
	collar.scale.z = 0.86
	_ellipsoid(root, "ScarfKnot", Vector3(0.058, 1.319, 0.070), Vector3(0.036, 0.028, 0.027), scarf)
	_part(root, "FoldedScarfTails", _folds("scarf_tails", [PackedVector3Array([
		Vector3(0.049, 1.322, 0.090), Vector3(0.097, 1.310, 0.084),
		Vector3(0.176, 1.164, 0.121), Vector3(0.126, 1.184, 0.149), Vector3(0.105, 1.167, 0.153),
	]), PackedVector3Array([
		Vector3(0.050, 1.321, 0.118), Vector3(0.081, 1.315, 0.126),
		Vector3(0.075, 1.217, 0.185), Vector3(0.024, 1.230, 0.172),
	])]), scarf, Vector3(0.0, 0.0, 0.040))

	var head: MeshInstance3D = _part(root, "SoftFacetedFace", _lathe(PackedVector2Array([
		Vector2(0.0, -0.185), Vector2(0.056, -0.176), Vector2(0.105, -0.147),
		Vector2(0.139, -0.087), Vector2(0.152, 0.014), Vector2(0.141, 0.104),
		Vector2(0.099, 0.163), Vector2(0.037, 0.187), Vector2(0.0, 0.192),
	]), 16), skin, Vector3(0.0, 1.493, 0.0))
	head.scale = Vector3(0.96, 1.0, 0.87)
	var ear_poses: Array[Transform3D] = [
		_pose(Vector3(-0.143, 1.485, 0.001), Vector3(0.022, 0.036, 0.026)),
		_pose(Vector3(0.143, 1.485, 0.001), Vector3(0.022, 0.036, 0.026)),
	]
	_part(root, "Ears", _cluster("ears", _sphere(), ear_poses), skin)
	var eye_poses: Array[Transform3D] = [
		_pose(Vector3(-0.052, 1.517, 0.131), Vector3(0.010, 0.013, 0.006)),
		_pose(Vector3(0.052, 1.517, 0.131), Vector3(0.010, 0.013, 0.006)),
	]
	_part(root, "KindEyes", _cluster("eyes", _sphere(), eye_poses), Kit.paint(Kit.CHARCOAL.darkened(0.55)))
	_ellipsoid(root, "SmallNose", Vector3(0.0, 1.477, 0.135), Vector3(0.018, 0.022, 0.018), skin)
	_part(root, "QuietSmile", _folds("smile", [PackedVector3Array([
		Vector3(-0.023, 1.444, 0.128), Vector3(0.0, 1.438, 0.132), Vector3(0.023, 1.444, 0.128),
		Vector3(0.013, 1.435, 0.130), Vector3(-0.013, 1.435, 0.130),
	])], 0.001), Kit.paint(skins[style].darkened(0.39)), Vector3(0.0, 0.0, 0.006))
	_part(root, "SidePartedHair", _hair(style), hair, Vector3(0.0, 1.493, 0.0))
	if style == 1:
		var cap: MeshInstance3D = _ellipsoid(root, "TiltedCrewCap", Vector3(-0.025, 1.690, -0.015), Vector3(0.124, 0.052, 0.102), suit)
		cap.rotation_degrees.z = -12.0
		_ellipsoid(root, "CapBrassPin", Vector3(-0.018, 1.703, 0.080), Vector3(0.026, 0.007, 0.006), Kit.brass())
	else:
		_ellipsoid(root, "LowChignon", Vector3(-0.019, 1.465, -0.142), Vector3(0.079, 0.073, 0.069), hair)
		var pin_poses: Array[Transform3D] = [
			_pose(Vector3(-0.152, 1.470, 0.013), Vector3(0.011, 0.011, 0.009)),
			_pose(Vector3(0.152, 1.470, 0.013), Vector3(0.011, 0.011, 0.009)),
		]
		_part(root, "BrassStudEarrings", _cluster("earrings", _sphere(), pin_poses), Kit.brass())

	_build_bag(root, style, leather)
	var insignia: StandardMaterial3D = Signs._icon_material("plane", Color(0.0, 0.0, 0.0, 0.0))
	_part(root, "CrewWingInsignia", _badge(), insignia, Vector3(-0.139, 1.192, 0.165), false)
	return root


static func _build_bag(root: Node3D, style: int, leather: Material) -> void:
	var bag_colors: Array[Color] = [Kit.WALNUT, Kit.SAGE.darkened(0.18), Kit.LINEN.darkened(0.16)]
	var shell: StandardMaterial3D = Kit.fabric(bag_colors[style], "attendant_bag_%d" % style)
	var bag_at: Vector3 = Vector3(0.539, 0.309, -0.018)
	Kit.rbox(root, Vector3(0.326, 0.482, 0.222), bag_at, leather, 0.054).name = "CarryOnZipperGusset"
	Kit.rbox(root, Vector3(0.313, 0.464, 0.134), bag_at + Vector3(0.0, 0.0, 0.054), shell, 0.050).name = "WovenCarryOnShell"
	Kit.rbox(root, Vector3(0.261, 0.318, 0.026), bag_at + Vector3(0.0, -0.032, 0.114), leather, 0.012).name = "PocketWelt"
	Kit.rbox(root, Vector3(0.250, 0.306, 0.029), bag_at + Vector3(0.0, -0.032, 0.124), shell, 0.014).name = "RoundedFrontPocket"
	var wheel_poses: Array[Transform3D] = []
	for x: float in [0.427, 0.651]:
		for z: float in [-0.086, 0.052]:
			wheel_poses.append(_pose(Vector3(x, 0.036, z), Vector3(0.024, 0.036, 0.036)))
	_part(root, "FourSpinnerWheels", _cluster("wheels", _sphere(), wheel_poses), leather)
	var rail_poses: Array[Transform3D] = [
		_pose(Vector3(0.476, 0.733, -0.020), Vector3.ONE),
		_pose(Vector3(0.602, 0.733, -0.020), Vector3.ONE),
	]
	_part(root, "TwinTelescopingRails", _cluster("rails", Kit.rounded_box(Vector3(0.015, 0.396, 0.018), 0.006), rail_poses), Kit.metal(Kit.CHARCOAL.lightened(0.15), 0.32, 0.8, "attendant_rails"))
	Kit.rbox(root, Vector3(0.192, 0.041, 0.047), Vector3(0.539, 0.932, -0.020), leather, 0.019).name = "CarryOnHandGrip"
	var pull_poses: Array[Transform3D] = [
		_pose(Vector3(0.623, 0.457, 0.148), Vector3(0.008, 0.022, 0.004), -18.0),
		_pose(Vector3(0.639, 0.449, 0.146), Vector3(0.008, 0.022, 0.004), 12.0),
	]
	_part(root, "BrassZipPulls", _cluster("zip_pulls", _sphere(), pull_poses), Kit.brass())
	_part(root, "BagCrewEmblem", _badge(), Signs._icon_material("plane", Color(0.0, 0.0, 0.0, 0.0)), Vector3(0.539, 0.328, 0.152), false)


static func _part(parent: Node3D, part_name: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, mesh, material, at, Vector3.ZERO, shadows)
	node.name = part_name
	return node


static func _ellipsoid(parent: Node3D, part_name: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	var node: MeshInstance3D = _part(parent, part_name, _sphere(), material, at)
	node.scale = radii
	return node


static func _pose(at: Vector3, scale_value: Vector3, roll_degrees: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.BACK, deg_to_rad(roll_degrees)) * Basis.from_scale(scale_value), at)


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


static func _badge() -> QuadMesh:
	if _meshes.has("badge"):
		return _meshes["badge"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.062, 0.062)
	_meshes["badge"] = mesh
	return mesh


static func _between(parent: Node3D, part_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var mesh: ArrayMesh = _lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.65, 0.035), Vector2(0.94, 0.10), Vector2(1.0, 0.24),
		Vector2(0.94, 0.68), Vector2(0.73, 0.91), Vector2(0.50, 0.97), Vector2(0.0, 1.0),
	]), 12)
	var difference: Vector3 = end - start
	var node: MeshInstance3D = _part(parent, part_name, mesh, material, start)
	node.quaternion = Quaternion(Vector3.UP, difference.normalized())
	node.scale = Vector3(radius, difference.length(), radius)


static func _lathe(profile: PackedVector2Array, segments: int) -> ArrayMesh:
	var key: String = "outward_lathe:%s:%d" % [profile, segments]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var source: ArrayMesh = Kit.lathe(profile, segments)
	var arrays: Array = source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# The helper's turned triangles wind inward under Godot's clockwise convention.
	# Correct a private copy so shared meshes used by other modules remain untouched.
	for i: int in range(0, vertices.size(), 3):
		var vertex: Vector3 = vertices[i + 1]
		vertices[i + 1] = vertices[i + 2]
		vertices[i + 2] = vertex
		var normal: Vector3 = normals[i + 1]
		normals[i] = -normals[i]
		normals[i + 1] = -normals[i + 2]
		normals[i + 2] = -normal
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[key] = mesh
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


static func _folds(key: String, panels: Array[PackedVector3Array], ridge: float = 0.009) -> ArrayMesh:
	var cache_key: String = "fold:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for outline: PackedVector3Array in panels:
		var points: PackedVector3Array = outline.duplicate()
		var center: Vector3 = Vector3.ZERO
		var signed_area: float = 0.0
		for i: int in points.size():
			var p: Vector3 = points[i]
			var q: Vector3 = points[(i + 1) % points.size()]
			center += p
			signed_area += p.x * q.y - q.x * p.y
		center /= float(points.size())
		if signed_area > 0.0:
			points.reverse()
		var back: Vector3 = Vector3(0.0, 0.0, -0.004)
		for i: int in points.size():
			var p: Vector3 = points[i]
			var q: Vector3 = points[(i + 1) % points.size()]
			_triangle(surface, center + Vector3(0.0, 0.0, ridge), p, q)
			_triangle(surface, center + back, q + back, p + back)
			_triangle(surface, p, p + back, q)
			_triangle(surface, q, p + back, q + back)
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	for point: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x, point.y))
		surface.add_vertex(point)


static func _hair(style: int) -> ArrayMesh:
	var key: String = "hair:%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment: int in 20:
		var a: float = TAU * float(segment) / 20.0
		var b: float = TAU * float(segment + 1) / 20.0
		for ring: int in 7:
			var lower: float = float(ring) / 7.0
			var upper: float = float(ring + 1) / 7.0
			var p: Vector3 = _hair_point(a, lower, style)
			var q: Vector3 = _hair_point(b, lower, style)
			var r: Vector3 = _hair_point(a, upper, style)
			var s: Vector3 = _hair_point(b, upper, style)
			if ring > 0:
				_triangle(surface, p, q, r)
			_triangle(surface, q, s, r)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _hair_point(angle: float, fraction: float, style: int) -> Vector3:
	var back_length: float = 1.76 if style == 1 else 2.12
	var hairline: float = lerpf(back_length, 1.19, maxf(cos(angle), 0.0)) + 0.10 * sin(angle)
	var polar: float = fraction * hairline
	# Extra clearance also covers the different facet counts of scalp and hair.
	return Vector3(sin(angle) * sin(polar) * 0.169, cos(polar) * 0.215, cos(angle) * sin(polar) * 0.156)
