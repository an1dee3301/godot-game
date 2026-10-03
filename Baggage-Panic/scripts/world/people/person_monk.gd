extends RefCounted
## A quiet traveller: wrapped woven robe, soft sling bag and simple sandals.
## Metres; +Z is the face, and the sandal soles touch y = 0.

const Kit = preload("res://scripts/world/design_kit.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MonkTraveller"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var robe_colors: Array[Color] = [Kit.OCHRE, Kit.CLAY, Kit.SAGE.darkened(0.19), Kit.WALNUT]
	var bag_colors: Array[Color] = [Kit.LINEN, Kit.CREAM.darkened(0.13), Kit.CLAY.darkened(0.13), Kit.SAGE]
	var skin_colors: Array[Color] = [Color(0.66, 0.43, 0.29), Color(0.84, 0.64, 0.47), Color(0.48, 0.31, 0.23), Color(0.73, 0.54, 0.39)]
	var robe_color: Color = robe_colors[style]
	var bag_color: Color = bag_colors[style]
	var skin_color: Color = skin_colors[style]
	var robe: StandardMaterial3D = Kit.fabric(robe_color, "monk_robe_%d" % style)
	var wrap: StandardMaterial3D = Kit.fabric(robe_color.lightened(0.075), "monk_wrap_%d" % style)
	var hem: StandardMaterial3D = Kit.fabric(robe_color.darkened(0.12), "monk_hem_%d" % style)
	var cloth: StandardMaterial3D = Kit.fabric(bag_color, "monk_bag_%d" % style)
	var binding: StandardMaterial3D = Kit.fabric(bag_color.darkened(0.19), "monk_binding_%d" % style)
	var skin: StandardMaterial3D = Kit.paint(skin_color, 0.88)
	var ink: StandardMaterial3D = Kit.paint(Kit.CHARCOAL, 0.95)
	var sandal: StandardMaterial3D = Kit.fabric(Kit.WALNUT.darkened(0.24), "monk_sandal")
	var sole: StandardMaterial3D = Kit.wood(Kit.WALNUT, "monk_sandal_sole")

	# Slightly staggered feet give the long robe a grounded, relaxed stance.
	for side: int in [-1, 1]:
		var x: float = float(side) * 0.112
		var z: float = 0.045 if side < 0 else 0.012
		_oval(root, "SandalSole", Vector3(x, 0.024, z + 0.04), Vector3(0.077, 0.024, 0.145), sole)
		_oval(root, "Foot", Vector3(x, 0.064, z + 0.046), Vector3(0.067, 0.033, 0.117), skin)
		_segment(root, "Ankle", Vector3(x, 0.077, z - 0.009), Vector3(x, 0.225, z - 0.009), 0.043, skin)
		var sandal_points: PackedVector3Array = PackedVector3Array([
			Vector3(-0.065, 0.068, 0.0), Vector3(-0.043, 0.091, 0.0),
			Vector3(0.0, 0.102, 0.0), Vector3(0.043, 0.091, 0.0), Vector3(0.065, 0.068, 0.0)])
		var band: MeshInstance3D = Kit.add(root, _ribbon("sandal_band", sandal_points, 0.043, Vector3.FORWARD), sandal, Vector3(x, 0.0, z + 0.075))
		band.name = "SandalClothBand"

	var body_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.17), Vector2(0.23, 0.17), Vector2(0.252, 0.182),
		Vector2(0.257, 0.21), Vector2(0.25, 0.40), Vector2(0.233, 0.70),
		Vector2(0.21, 0.98), Vector2(0.219, 1.17), Vector2(0.235, 1.28),
		Vector2(0.211, 1.34), Vector2(0.125, 1.38), Vector2(0.065, 1.395), Vector2(0.0, 1.395)])
	var body: MeshInstance3D = Kit.add(root, Kit.lathe(body_profile, 20), robe, Vector3.ZERO)
	body.name = "LongWovenRobe"
	body.scale.z = 0.72
	var hem_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.248, 0.182), Vector2(0.256, 0.185), Vector2(0.26, 0.209),
		Vector2(0.26, 0.225), Vector2(0.254, 0.229)])
	var hem_node: MeshInstance3D = Kit.add(root, Kit.lathe(hem_profile, 20), hem, Vector3.ZERO)
	hem_node.name = "TurnedRobeHem"
	hem_node.scale.z = 0.72
	var wrap_node: MeshInstance3D = Kit.add(root, _wrap_mesh(), wrap, Vector3.ZERO)
	wrap_node.name = "OverlappingRobeDrape"

	# Narrow raised folds follow the front surface; no drawn-on fabric stripes.
	var fold_left: PackedVector3Array = PackedVector3Array([
		Vector3(-0.15, 0.225, 0.151), Vector3(-0.132, 0.43, 0.155),
		Vector3(-0.103, 0.70, 0.154), Vector3(-0.074, 0.95, 0.146)])
	var fold_right: PackedVector3Array = PackedVector3Array([
		Vector3(0.172, 0.23, 0.14), Vector3(0.149, 0.44, 0.149),
		Vector3(0.119, 0.71, 0.15), Vector3(0.095, 0.93, 0.142)])
	Kit.add(root, _ribbon("robe_fold_left", fold_left, 0.013), wrap, Vector3.ZERO)
	Kit.add(root, _ribbon("robe_fold_right", fold_right, 0.012), hem, Vector3.ZERO)
	var collar_left: PackedVector3Array = PackedVector3Array([
		Vector3(-0.078, 1.389, 0.045), Vector3(-0.053, 1.348, 0.112), Vector3(0.014, 1.272, 0.167)])
	var collar_right: PackedVector3Array = PackedVector3Array([
		Vector3(0.078, 1.389, 0.045), Vector3(0.052, 1.345, 0.119), Vector3(-0.015, 1.292, 0.166)])
	var lining: StandardMaterial3D = Kit.fabric(Kit.LINEN, "monk_collar_linen")
	Kit.add(root, _ribbon("collar_left", collar_left, 0.03), lining, Vector3.ZERO)
	Kit.add(root, _ribbon("collar_right", collar_right, 0.026), lining, Vector3.ZERO)

	_sleeve(root, Vector3(-0.205, 1.28, 0.0), Vector3(-0.279, 0.965, 0.072), robe, hem)
	_sleeve(root, Vector3(0.205, 1.28, 0.0), Vector3(0.282, 1.004, 0.18), robe, hem)
	var left_hand: MeshInstance3D = _oval(root, "RelaxedHand", Vector3(-0.286, 0.932, 0.086), Vector3(0.045, 0.064, 0.039), skin)
	left_hand.rotation_degrees.z = -10.0
	var right_hand: MeshInstance3D = _oval(root, "HandAtBag", Vector3(0.292, 0.978, 0.205), Vector3(0.048, 0.057, 0.04), skin)
	right_hand.rotation_degrees.x = -28.0

	_segment(root, "Neck", Vector3(0.0, 1.378, 0.0), Vector3(0.0, 1.474, 0.0), 0.063, skin)
	_oval(root, "Head", Vector3(0.0, 1.555, 0.013), Vector3(0.137, 0.162, 0.13), skin)
	for side: int in [-1, 1]:
		_oval(root, "Ear", Vector3(float(side) * 0.135, 1.535, 0.015), Vector3(0.023, 0.034, 0.022), skin)
		_oval(root, "Eye", Vector3(float(side) * 0.047, 1.565, 0.135), Vector3(0.008, 0.012, 0.005), ink)
	_oval(root, "Nose", Vector3(0.0, 1.522, 0.144), Vector3(0.018, 0.024, 0.024), skin)
	_segment(root, "QuietSmile", Vector3(-0.016, 1.49, 0.131), Vector3(0.016, 1.49, 0.131), 0.0035, Kit.paint(skin_color.darkened(0.34), 0.9))
	if style % 2 == 1:
		var crop_profile: PackedVector2Array = PackedVector2Array([
			Vector2(0.137, 0.012), Vector2(0.138, 0.04), Vector2(0.121, 0.089),
			Vector2(0.094, 0.128), Vector2(0.054, 0.153), Vector2(0.0, 0.164)])
		var hair_color: Color = skin_color.lerp(Kit.CHARCOAL, 0.47) if style == 1 else Kit.LINEN.darkened(0.32)
		var crop: MeshInstance3D = Kit.add(root, Kit.lathe(crop_profile, 16), Kit.paint(hair_color, 0.98), Vector3(0.0, 1.555, 0.013))
		crop.name = "CloseCroppedHair"
		crop.scale.z = 0.947

	# Cloth sling: a rounded belly with gathered shoulders and a folded-over mouth.
	var bag_root: Node3D = Node3D.new()
	bag_root.name = "ClothShoulderBag"
	bag_root.position = Vector3(0.368, 0.573, 0.067)
	bag_root.rotation_degrees.z = -6.0
	root.add_child(bag_root)
	var bag_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.075, 0.007), Vector2(0.145, 0.035),
		Vector2(0.184, 0.095), Vector2(0.186, 0.183), Vector2(0.166, 0.28),
		Vector2(0.123, 0.351), Vector2(0.083, 0.371), Vector2(0.0, 0.374)])
	var bag: MeshInstance3D = Kit.add(bag_root, Kit.lathe(bag_profile, 16), cloth, Vector3.ZERO)
	bag.name = "SoftBagBelly"
	bag.scale.z = 0.56
	var flap: MeshInstance3D = _oval(bag_root, "FoldedBagFlap", Vector3(0.0, 0.292, 0.071), Vector3(0.132, 0.083, 0.036), cloth)
	flap.rotation_degrees.x = -14.0
	var bag_seam: PackedVector3Array = PackedVector3Array([
		Vector3(-0.135, 0.26, 0.056), Vector3(-0.153, 0.155, 0.063),
		Vector3(-0.113, 0.062, 0.063), Vector3(0.0, 0.025, 0.055),
		Vector3(0.113, 0.062, 0.063), Vector3(0.153, 0.155, 0.063), Vector3(0.135, 0.26, 0.056)])
	Kit.add(bag_root, _ribbon("bag_bound_seam", bag_seam, 0.009), binding, Vector3.ZERO)
	var strap_points: PackedVector3Array = PackedVector3Array([
		Vector3(0.39, 0.91, 0.139), Vector3(0.267, 1.005, 0.194),
		Vector3(0.1, 1.152, 0.198), Vector3(-0.068, 1.299, 0.174),
		Vector3(-0.161, 1.355, 0.1), Vector3(-0.173, 1.373, 0.0),
		Vector3(-0.158, 1.348, -0.1), Vector3(-0.05, 1.27, -0.17),
		Vector3(0.114, 1.133, -0.178), Vector3(0.273, 0.99, -0.145), Vector3(0.39, 0.909, 0.008)])
	var strap: MeshInstance3D = Kit.add(root, _ribbon("crossbody_strap", strap_points, 0.047), binding, Vector3.ZERO)
	strap.name = "ContinuousWovenShoulderStrap"
	if style < 2:
		_segment(bag_root, "WoodenBagToggle", Vector3(-0.032, 0.235, 0.101), Vector3(0.032, 0.235, 0.101), 0.011, Kit.wood(Kit.OAK, "monk_bag_toggle"))
	else:
		_oval(bag_root, "ClothTieKnot", Vector3(0.0, 0.238, 0.102), Vector3(0.023, 0.018, 0.014), binding)
		_segment(bag_root, "TieEnd", Vector3(0.008, 0.23, 0.102), Vector3(0.033, 0.19, 0.104), 0.007, binding)
	return root


static func _oval(parent: Node3D, part_name: String, at: Vector3, radii: Vector3, material: Material) -> MeshInstance3D:
	if not _meshes.has("unit_sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["unit_sphere"] = sphere
	var mesh: Mesh = _meshes["unit_sphere"] as Mesh
	var node: MeshInstance3D = Kit.add(parent, mesh, material, at)
	node.name = part_name
	node.scale = radii
	return node


static func _segment(parent: Node3D, part_name: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var delta: Vector3 = finish - start
	var height: float = delta.length() + 2.0 * radius
	var key: String = "capsule:%.5f:%.5f" % [radius, height]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = height
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	var mesh: Mesh = _meshes[key] as Mesh
	var node: MeshInstance3D = Kit.add(parent, mesh, material, (start + finish) * 0.5)
	node.name = part_name
	node.quaternion = Quaternion(Vector3.UP, delta.normalized())
	return node


static func _sleeve(parent: Node3D, shoulder: Vector3, wrist: Vector3, material: Material, cuff_material: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.073, 0.0), Vector2(0.088, 0.06),
		Vector2(0.1, 0.24), Vector2(0.112, 0.69), Vector2(0.099, 0.9),
		Vector2(0.07, 1.0), Vector2(0.0, 1.0)])
	var direction: Vector3 = shoulder - wrist
	var sleeve: MeshInstance3D = Kit.add(parent, Kit.lathe(profile, 14), material, wrist)
	sleeve.name = "DrapedSleeve"
	sleeve.quaternion = Quaternion(Vector3.UP, direction.normalized())
	sleeve.scale.y = direction.length()
	var cuff_profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.064, -0.006), Vector2(0.077, -0.006), Vector2(0.085, 0.015), Vector2(0.082, 0.027)])
	var cuff: MeshInstance3D = Kit.add(parent, Kit.lathe(cuff_profile, 14), cuff_material, wrist)
	cuff.name = "FoldedSleeveCuff"
	cuff.quaternion = sleeve.quaternion


static func _wrap_mesh() -> ArrayMesh:
	if _meshes.has("robe_wrap"):
		return _meshes["robe_wrap"] as ArrayMesh
	# Each row is (radius, height, first angle, last angle). The panel hugs the robe.
	var rows: Array[Vector4] = [
		Vector4(0.262, 0.217, 0.65, 1.47), Vector4(0.256, 0.40, 0.8, 1.64),
		Vector4(0.239, 0.70, 0.93, 1.74), Vector4(0.217, 0.98, 1.01, 1.82),
		Vector4(0.225, 1.17, 1.08, 1.98), Vector4(0.24, 1.28, 1.27, 2.20),
		Vector4(0.217, 1.34, 1.67, 2.31)]
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in range(rows.size() - 1):
		var lower: Vector4 = rows[row]
		var upper: Vector4 = rows[row + 1]
		for section: int in range(8):
			var u0: float = float(section) / 8.0
			var u1: float = float(section + 1) / 8.0
			var a: Vector3 = _wrap_point(lower, u0)
			var b: Vector3 = _wrap_point(lower, u1)
			var c: Vector3 = _wrap_point(upper, u0)
			var d: Vector3 = _wrap_point(upper, u1)
			for vertex: Vector3 in [a, c, b, b, c, d]:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["robe_wrap"] = mesh
	return mesh


static func _wrap_point(row: Vector4, u: float) -> Vector3:
	var angle: float = lerpf(row.z, row.w, u)
	var radius: float = row.x + sin(u * PI * 3.0) * 0.003
	return Vector3(cos(angle) * radius, row.y, sin(angle) * radius * 0.72)


static func _ribbon(key: String, points: PackedVector3Array, width: float, fixed_side: Vector3 = Vector3.ZERO) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	# A closed, softly bevelled cloth strip, with a consistent frame over shoulders.
	var rings: Array[PackedVector3Array] = []
	var previous_side: Vector3 = Vector3.RIGHT
	for index: int in range(points.size()):
		var before: Vector3 = points[maxi(index - 1, 0)]
		var after: Vector3 = points[mini(index + 1, points.size() - 1)]
		var tangent: Vector3 = (after - before).normalized()
		var side: Vector3 = fixed_side
		if side == Vector3.ZERO:
			side = tangent.cross(Vector3.FORWARD)
			if side.length_squared() < 0.001:
				side = previous_side
			side = side.normalized()
			if side.dot(previous_side) < 0.0:
				side = -side
		previous_side = side
		var normal: Vector3 = side.cross(tangent).normalized()
		var centre: Vector3 = points[index]
		var half_width: float = width * 0.5
		var bevel: float = minf(0.0025, width * 0.18)
		var ring: PackedVector3Array = PackedVector3Array([
			centre - side * half_width,
			centre - side * (half_width - bevel) + normal * 0.0025,
			centre + side * (half_width - bevel) + normal * 0.0025,
			centre + side * half_width,
			centre + side * (half_width - bevel) - normal * 0.0025,
			centre - side * (half_width - bevel) - normal * 0.0025])
		rings.append(ring)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(rings.size() - 1):
		var current: PackedVector3Array = rings[index]
		var next: PackedVector3Array = rings[index + 1]
		for edge: int in range(6):
			var other: int = (edge + 1) % 6
			for vertex: Vector3 in [current[edge], current[other], next[edge], current[other], next[other], next[edge]]:
				st.add_vertex(vertex)
	for end: int in [0, rings.size() - 1]:
		var ring: PackedVector3Array = rings[end]
		for edge: int in range(6):
			var other: int = (edge + 1) % 6
			st.add_vertex(points[end])
			st.add_vertex(ring[edge] if end == 0 else ring[other])
			st.add_vertex(ring[other] if end == 0 else ring[edge])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
