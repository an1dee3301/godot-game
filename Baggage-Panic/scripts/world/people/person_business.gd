extends RefCounted
## A quiet moment between gates: a tailored coat, boarding phone and cabin case.
## All dimensions are metres; the soles and four spinner wheels touch y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

const COATS: Array[Color] = [Color(0.60, 0.46, 0.33), Kit.SAGE, Kit.INDIGO, Kit.CLAY]
const CASES: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.LIMESTONE, Kit.INDIGO]
const SKINS: Array[Color] = [Color(0.72, 0.49, 0.34), Color(0.88, 0.65, 0.47), Color(0.46, 0.29, 0.21), Color(0.79, 0.56, 0.41)]
const HAIR: Array[Color] = [Color(0.17, 0.12, 0.09), Color(0.10, 0.085, 0.075), Color(0.55, 0.52, 0.46), Color(0.25, 0.16, 0.10)]

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var style: int = posmod(variant, 4)
	var root: Node3D = Node3D.new()
	root.name = "BusinessTraveller"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var coat_color: Color = COATS[style]
	var coat: Material = Kit.fabric(coat_color, "business_coat_%d" % style)
	var facing: Material = Kit.fabric(coat_color.darkened(0.13), "business_facing_%d" % style)
	var trousers: Material = Kit.fabric(Kit.LINEN if style == 2 else Kit.CHARCOAL, "business_trousers_%d" % style)
	var shirt: Material = Kit.fabric(Kit.CREAM, "business_shirt")
	var skin_color: Color = SKINS[style]
	var skin: Material = Kit.paint(skin_color, 0.83)
	var hair_color: Color = HAIR[style]
	var hair: Material = Kit.paint(hair_color, 0.92)
	var leather: Material = Kit.paint(Kit.WALNUT.darkened(0.34), 0.47)
	var rubber: Material = Kit.paint(Kit.CHARCOAL.darkened(0.35), 0.9)
	var steel: Material = Kit.metal(Kit.CHARCOAL, 0.38, 0.78, "business_hardware")

	# Separate narrow trouser legs keep the coat silhouette recognisably adult.
	_span(root, "LeftTrouser", Vector3(-0.105, 0.18, 0.045), Vector3(-0.10, 0.74, 0.0), 0.073, trousers)
	_span(root, "RightTrouser", Vector3(0.105, 0.18, -0.025), Vector3(0.10, 0.74, 0.0), 0.073, trousers)
	var feet: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(-0.105, 0.0, 0.087)),
		Transform3D(Basis.IDENTITY, Vector3(0.105, 0.0, 0.012)),
	]
	var soles: Array[Transform3D] = []
	var uppers: Array[Transform3D] = []
	for foot: Transform3D in feet:
		soles.append(Transform3D(Basis.IDENTITY, foot.origin + Vector3(0.0, 0.0175, 0.0)))
		uppers.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.174, 0.108, 0.292)), foot.origin + Vector3(0.0, 0.077, 0.0)))
	_part(root, "LeatherSoles", _copies("soles", Kit.rounded_box(Vector3(0.174, 0.035, 0.296), 0.015), soles), rubber)
	_part(root, "WalnutLoafers", _copies("loafers", _sphere(), uppers), leather)

	var coat_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.615), Vector2(0.19, 0.615), Vector2(0.231, 0.636),
		Vector2(0.236, 0.69), Vector2(0.199, 0.95), Vector2(0.21, 1.14),
		Vector2(0.245, 1.245), Vector2(0.22, 1.29), Vector2(0.115, 1.365),
		Vector2(0.0, 1.365),
	])
	var body: MeshInstance3D = _part(root, "WoolCoat", Kit.lathe(coat_profile, 16), coat)
	body.scale.z = 0.69
	_ellipsoid(root, "LinenShirt", Vector3(0.172, 0.295, 0.065), Vector3(0.0, 1.247, 0.111), shirt)
	_part(root, "NotchedLapels", _lapels(), facing)
	var button_poses: Array[Transform3D] = []
	for height: float in [1.033, 0.887, 0.744]:
		button_poses.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.023, 0.023, 0.012)), Vector3(0.023, height, 0.154)))
	_part(root, "HornButtons", _copies("buttons", _sphere(), button_poses), leather)
	var pocket_poses: Array[Transform3D] = [
		Transform3D(Basis(Vector3.FORWARD, -0.15), Vector3(-0.137, 0.88, 0.115)),
		Transform3D(Basis(Vector3.FORWARD, 0.15), Vector3(0.137, 0.88, 0.115)),
	]
	_part(root, "WeltPockets", _copies("pockets", Kit.rounded_box(Vector3(0.105, 0.019, 0.024), 0.008), pocket_poses), facing)

	# One elbow bends toward the phone; the other hand closes over the case grip.
	_span(root, "PhoneUpperSleeve", Vector3(-0.222, 1.239, 0.0), Vector3(-0.327, 1.03, 0.06), 0.075, coat)
	_span(root, "PhoneLowerSleeve", Vector3(-0.327, 1.03, 0.06), Vector3(-0.295, 1.147, 0.247), 0.063, coat)
	_span(root, "CaseUpperSleeve", Vector3(0.228, 1.23, 0.0), Vector3(0.322, 1.021, -0.034), 0.075, coat)
	_span(root, "CaseLowerSleeve", Vector3(0.322, 1.021, -0.034), Vector3(0.479, 0.952, -0.071), 0.061, coat)
	_span(root, "PhoneCuff", Vector3(-0.295, 1.147, 0.247), Vector3(-0.291, 1.159, 0.266), 0.051, shirt)
	_span(root, "CaseCuff", Vector3(0.468, 0.956, -0.068), Vector3(0.49, 0.947, -0.074), 0.048, shirt)
	_ellipsoid(root, "PhoneHand", Vector3(0.079, 0.106, 0.081), Vector3(-0.281, 1.184, 0.285), skin)
	_ellipsoid(root, "CaseHand", Vector3(0.098, 0.081, 0.082), Vector3(0.523, 0.935, -0.076), skin)
	_span(root, "Neck", Vector3(0.0, 1.333, 0.0), Vector3(0.0, 1.414, 0.0), 0.061, skin)

	var head: Node3D = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 1.557, 0.015)
	head.rotation_degrees = Vector3(5.0, -9.0, 0.0)
	root.add_child(head)
	_ellipsoid(head, "Face", Vector3(0.289, 0.331, 0.266), Vector3.ZERO, skin)
	_part(head, "SculptedHair", _hair_cap(style), hair)
	if style == 1:
		_ellipsoid(head, "LowBun", Vector3(0.135, 0.133, 0.127), Vector3(0.0, 0.052, -0.153), hair)
	elif style != 3:
		var fringe: MeshInstance3D = _ellipsoid(head, "SweptFringe", Vector3(0.20, 0.072, 0.086), Vector3(-0.018, 0.126, 0.108), hair)
		fringe.rotation_degrees.z = -17.0
	var ear_poses: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY.scaled(Vector3(0.041, 0.065, 0.046)), Vector3(-0.143, -0.008, 0.0)),
		Transform3D(Basis.IDENTITY.scaled(Vector3(0.041, 0.065, 0.046)), Vector3(0.143, -0.008, 0.0)),
	]
	_part(head, "Ears", _copies("ears", _sphere(), ear_poses), skin)
	var eye_poses: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY.scaled(Vector3(0.017, 0.023, 0.013)), Vector3(-0.047, 0.011, 0.126)),
		Transform3D(Basis.IDENTITY.scaled(Vector3(0.017, 0.023, 0.013)), Vector3(0.047, 0.011, 0.126)),
	]
	_part(head, "Eyes", _copies("eyes", _sphere(), eye_poses), rubber)
	_ellipsoid(head, "Nose", Vector3(0.031, 0.036, 0.037), Vector3(0.0, -0.025, 0.139), skin)
	if style == 2 or style == 3:
		_part(head, "RoundSpectacles", _spectacles(), Kit.brass())
	elif style == 1:
		_span(root, "ClayScarf", Vector3(0.067, 1.329, 0.116), Vector3(0.064, 1.151, 0.158), 0.033, Kit.fabric(Kit.CLAY, "business_scarf"))

	_carry_on(root, style, leather, rubber, steel)
	_phone(root, style, steel)
	return root


static func _carry_on(parent: Node3D, style: int, leather: Material, rubber: Material, steel: Material) -> void:
	var luggage: Node3D = Node3D.new()
	luggage.name = "CabinCase"
	luggage.position = Vector3(0.55, 0.0, -0.079)
	parent.add_child(luggage)
	var case_color: Color = CASES[style]
	var shell: Material = Kit.paint(case_color, 0.53)
	_part(luggage, "ZipGusset", Kit.rounded_box(Vector3(0.348, 0.492, 0.221), 0.053), leather, Vector3(0.0, 0.324, 0.0))
	_part(luggage, "RearShell", Kit.rounded_box(Vector3(0.35, 0.494, 0.113), 0.051), shell, Vector3(0.0, 0.324, -0.062))
	_part(luggage, "FrontShell", Kit.rounded_box(Vector3(0.35, 0.494, 0.113), 0.051), shell, Vector3(0.0, 0.324, 0.062))
	var rib_poses: Array[Transform3D] = []
	for x: float in [-0.106, -0.053, 0.0, 0.053, 0.106]:
		rib_poses.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.325, 0.117)))
	_part(luggage, "MouldedRibs", _copies("case_ribs", Kit.rounded_box(Vector3(0.017, 0.362, 0.015), 0.006), rib_poses), Kit.paint(case_color.lightened(0.12), 0.53))
	var wheel_poses: Array[Transform3D] = []
	for x: float in [-0.122, 0.122]:
		for z: float in [-0.074, 0.074]:
			wheel_poses.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.047, 0.088, 0.088)), Vector3(x, 0.044, z)))
	_part(luggage, "FourSpinnerWheels", _copies("spinners", _sphere(), wheel_poses), rubber)
	var rail_poses: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(-0.074, 0.73, -0.033)),
		Transform3D(Basis.IDENTITY, Vector3(0.074, 0.73, -0.033)),
	]
	_part(luggage, "TelescopingRails", _copies("rails", Kit.rounded_box(Vector3(0.018, 0.397, 0.022), 0.007), rail_poses), steel)
	_part(luggage, "LeatherPullGrip", Kit.rounded_box(Vector3(0.195, 0.039, 0.055), 0.018), leather, Vector3(0.0, 0.929, -0.033))
	_span(luggage, "TopLiftHandle", Vector3(-0.058, 0.587, 0.011), Vector3(0.058, 0.587, 0.011), 0.015, leather)
	var tag: MeshInstance3D = _part(luggage, "BrassTag", Kit.rounded_box(Vector3(0.041, 0.075, 0.011), 0.008), Kit.brass(), Vector3(0.118, 0.528, 0.121))
	tag.rotation_degrees.z = -13.0


static func _phone(parent: Node3D, style: int, steel: Material) -> void:
	var phone: Node3D = Node3D.new()
	phone.name = "BoardingPhone"
	phone.position = Vector3(-0.274, 1.25, 0.307)
	phone.rotation_degrees = Vector3(-22.0, -10.0, -8.0)
	parent.add_child(phone)
	_part(phone, "PhoneFrame", Kit.rounded_box(Vector3(0.081, 0.151, 0.014), 0.006), steel)
	_part(phone, "WarmScreen", Kit.rounded_box(Vector3(0.070, 0.134, 0.004), 0.0015), Kit.washi(Kit.CREAM, 0.35, "business_phone_screen"), Vector3(0.0, 0.0, 0.008))
	# The same airport pictogram, with no miniature words or language-specific labels.
	var key: String = "phone_icon_quad"
	if not _meshes.has(key):
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.057, 0.057)
		_meshes[key] = quad
	var icon_mesh: Mesh = _meshes[key] as Mesh
	var tile_color: Color = CASES[style]
	_part(phone, "DeparturePictogram", icon_mesh, Signs._icon_material("plane", tile_color), Vector3(0.0, 0.019, 0.0105), false)


static func _part(parent: Node3D, title: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	var part: MeshInstance3D = Kit.add(parent, mesh, material, at, Vector3.ZERO, shadows)
	part.name = title
	return part


static func _sphere() -> SphereMesh:
	if not _meshes.has("sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 12
		sphere.rings = 6
		_meshes["sphere"] = sphere
	return _meshes["sphere"] as SphereMesh


static func _ellipsoid(parent: Node3D, title: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var part: MeshInstance3D = _part(parent, title, _sphere(), material, at)
	part.scale = size
	return part


static func _span(parent: Node3D, title: String, start: Vector3, end: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var distance: float = start.distance_to(end)
	var key: String = "capsule:%.5f:%.5f" % [radius, distance]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = distance + radius * 2.0
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key] as Mesh
	var part: MeshInstance3D = _part(parent, title, mesh, material, (start + end) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return part


## Repeated small details share one cached mesh and one draw call per material.
static func _copies(key: String, mesh: Mesh, poses: Array[Transform3D]) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pose: Transform3D in poses:
		surface.append_from(mesh, 0, pose)
	var result: ArrayMesh = surface.commit()
	_meshes[key] = result
	return result


static func _lapels() -> ArrayMesh:
	if _meshes.has("lapels"):
		return _meshes["lapels"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Folded, notched cloth with a raised ridge; both sides share a mesh.
	for side: float in [-1.0, 1.0]:
		var vertices: PackedVector3Array = PackedVector3Array([
			Vector3(side * 0.076, 1.362, 0.067), Vector3(side * 0.167, 1.285, 0.107),
			Vector3(side * 0.114, 1.262, 0.151), Vector3(side * 0.147, 1.233, 0.14),
			Vector3(side * 0.026, 1.074, 0.161), Vector3(side * 0.07, 1.253, 0.167),
		])
		var triangles: PackedInt32Array = PackedInt32Array([0, 1, 5, 1, 2, 5, 2, 3, 5, 3, 4, 5, 4, 0, 5])
		for triangle: int in range(0, triangles.size(), 3):
			var a: Vector3 = vertices[triangles[triangle]]
			var b: Vector3 = vertices[triangles[triangle + 1]]
			var c: Vector3 = vertices[triangles[triangle + 2]]
			_triangle(surface, a, b, c, Vector3(0.0, 0.2, 1.0))
	var result: ArrayMesh = surface.commit()
	_meshes["lapels"] = result
	return result


static func _hair_cap(style: int) -> ArrayMesh:
	var key: String = "hair_cap_%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in 5:
		for segment: int in 16:
			var a: Vector3 = _hair_vertex(float(ring) / 5.0, TAU * float(segment) / 16.0, style)
			var b: Vector3 = _hair_vertex(float(ring + 1) / 5.0, TAU * float(segment) / 16.0, style)
			var c: Vector3 = _hair_vertex(float(ring + 1) / 5.0, TAU * float(segment + 1) / 16.0, style)
			var d: Vector3 = _hair_vertex(float(ring) / 5.0, TAU * float(segment + 1) / 16.0, style)
			_triangle(surface, a, b, c, (a + b + c).normalized())
			if ring > 0:
				_triangle(surface, a, c, d, (a + c + d).normalized())
	var result: ArrayMesh = surface.commit()
	_meshes[key] = result
	return result


static func _hair_vertex(t: float, angle: float, style: int) -> Vector3:
	var hem: float = 0.021 + 0.065 * sin(angle)
	var crown: float = 0.178 if style == 3 else 0.19
	var radius: float = 0.153 * sin(t * PI * 0.5)
	var sweep: float = 0.011 * cos(angle) * sin(t * PI)
	return Vector3(cos(angle) * radius, hem + (crown - hem) * cos(t * PI * 0.5) + sweep, sin(angle) * radius * 0.91)


## Explicit outward normals and clockwise winding for the folded cloth/hair.
static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	if normal.dot(outward) < 0.0:
		normal = -normal
	surface.set_normal(normal)
	surface.set_uv(Vector2(a.x, a.y))
	surface.add_vertex(a)
	if (b - a).cross(c - a).dot(outward) > 0.0:
		surface.set_uv(Vector2(c.x, c.y))
		surface.add_vertex(c)
		surface.set_uv(Vector2(b.x, b.y))
		surface.add_vertex(b)
	else:
		surface.set_uv(Vector2(b.x, b.y))
		surface.add_vertex(b)
		surface.set_uv(Vector2(c.x, c.y))
		surface.add_vertex(c)


static func _spectacles() -> ArrayMesh:
	if _meshes.has("spectacles"):
		return _meshes["spectacles"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.029
	rim.outer_radius = 0.035
	rim.rings = 12
	rim.ring_segments = 6
	for x: float in [-0.048, 0.048]:
		surface.append_from(rim, 0, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, 0.011, 0.14)))
	surface.append_from(Kit.rounded_box(Vector3(0.036, 0.008, 0.01), 0.003), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.017, 0.143)))
	var result: ArrayMesh = surface.commit()
	_meshes["spectacles"] = result
	return result
