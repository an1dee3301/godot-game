extends RefCounted
## A quiet airport moment: a linen-coated parent and a child with their hands clasped.
## Local +Z is forward; all four shoe soles meet y = 0. No small text on clothing.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
const COATS: Array[Color] = [KIT.SAGE, KIT.LINEN, KIT.CLAY, KIT.INDIGO]
const KNITS: Array[Color] = [KIT.CLAY, KIT.INDIGO, KIT.SAGE, KIT.OCHRE]
const SKINS: Array[Color] = [Color(0.76, 0.52, 0.36), Color(0.40, 0.25, 0.18), Color(0.62, 0.39, 0.26), Color(0.90, 0.69, 0.51)]
const HAIR: Array[Color] = [Color(0.19, 0.13, 0.10), Color(0.10, 0.085, 0.075), Color(0.26, 0.16, 0.095), Color(0.14, 0.11, 0.10)]

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FamilyTravelers"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, COATS.size())
	_build_parent(root, style)
	_build_child(root, style)
	return root


static func _build_parent(root: Node3D, style: int) -> void:
	var coat_color: Color = COATS[style]
	var skin_color: Color = SKINS[style]
	var hair_color: Color = HAIR[style]
	var coat: Material = KIT.fabric(coat_color, "family_coat_%d" % style)
	var edging: Material = KIT.fabric(coat_color.darkened(0.17), "family_coat_edge_%d" % style)
	var linen: Material = KIT.fabric(KIT.CREAM, "family_cream_linen")
	var skin: Material = KIT.paint(skin_color, 0.86)
	var hair: Material = KIT.paint(hair_color, 0.93)
	var trousers: Material = KIT.fabric(KIT.CHARCOAL.lightened(0.08), "family_walnut_trousers")
	var leather: Material = KIT.paint(KIT.WALNUT.darkened(0.12), 0.78)
	var adult: Node3D = Node3D.new()
	adult.name = "Parent"
	adult.position.x = -0.29
	root.add_child(adult)

	_add(adult, "TaperedLinenCoat", KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.204, 0.0), Vector2(0.221, 0.023),
		Vector2(0.231, 0.17), Vector2(0.222, 0.43), Vector2(0.194, 0.53),
		Vector2(0.143, 0.58), Vector2(0.077, 0.604), Vector2(0.0, 0.604)
	]), 16), coat, Vector3(0.0, 0.78, 0.0), Vector3(1.0, 1.0, 0.73))
	_add(adult, "BoundCoatHem", KIT.lathe(PackedVector2Array([
		Vector2(0.205, 0.0), Vector2(0.223, 0.019), Vector2(0.226, 0.040),
		Vector2(0.221, 0.042), Vector2(0.205, 0.0)
	]), 16), edging, Vector3(0.0, 0.78, 0.0), Vector3(1.0, 1.0, 0.73))
	_legs_and_shoes(adult, false, trousers, leather, linen)
	_add(adult, "FaceNeckAndEars", _head_mesh(false), skin, Vector3(0.0, 1.535, 0.0))
	_add(adult, "SweptHair", _hair_mesh(false, style % 2 == 0), hair, Vector3(0.0, 1.535, -0.008))
	_add(adult, "GentleExpression", _face_mesh(false), KIT.paint(KIT.CHARCOAL.darkened(0.45)), Vector3(0.0, 1.535, 0.0))
	if style % 2 == 0:
		_orb(adult, "LowHairBun", Vector3(0.115, 0.115, 0.105), Vector3(-0.045, 1.637, -0.147), hair)

	var outer_shoulder: Vector3 = Vector3(-0.195, 1.28, 0.0)
	var outer_wrist: Vector3 = Vector3(-0.277, 1.035, 0.037)
	var inner_shoulder: Vector3 = Vector3(0.195, 1.29, 0.0)
	var inner_wrist: Vector3 = Vector3(0.438, 1.024, 0.05)
	_segment(adult, "RelaxedSleeve", outer_shoulder, outer_wrist, 0.077, coat)
	_segment(adult, "ReachingSleeve", inner_shoulder, inner_wrist, 0.077, coat)
	_cuffs(adult, false, outer_shoulder, outer_wrist, inner_shoulder, inner_wrist, edging)
	_orb(adult, "FreeHand", Vector3(0.079, 0.124, 0.078), Vector3(-0.299, 0.94, 0.052), skin)
	# Parent palm overlaps the child's palm at world x = 0.21, y = 0.956.
	_segment(adult, "HoldingChildHand", Vector3(0.461, 0.994, 0.056), Vector3(0.498, 0.958, 0.063), 0.041, skin)

	_add(adult, "LinenCollar", KIT.lathe(PackedVector2Array([
		Vector2(0.066, 0.0), Vector2(0.097, 0.008), Vector2(0.102, 0.030),
		Vector2(0.076, 0.068), Vector2(0.062, 0.068), Vector2(0.066, 0.0)
	]), 16), linen, Vector3(0.0, 1.337, 0.0), Vector3(1.0, 1.0, 0.81))
	_add(adult, "TailoredFrontSeam", _path_mesh("adult_placket", PackedVector3Array([
		Vector3(0.0, 0.815, 0.158), Vector3(0.0, 0.97, 0.173),
		Vector3(0.0, 1.20, 0.170), Vector3(0.0, 1.325, 0.117)
	]), 0.006), edging, Vector3.ZERO)
	_build_satchel(adult, style, linen, leather)


static func _build_child(root: Node3D, style: int) -> void:
	var knit_color: Color = KNITS[style]
	var skin_color: Color = SKINS[style]
	var hair_color: Color = HAIR[style]
	var knit: Material = KIT.fabric(knit_color, "family_child_knit_%d" % style)
	var ribbing: Material = KIT.fabric(knit_color.darkened(0.19), "family_child_ribbing_%d" % style)
	var linen: Material = KIT.fabric(KIT.CREAM, "family_cream_linen")
	var skin: Material = KIT.paint(skin_color.lightened(0.035), 0.86)
	var hair: Material = KIT.paint(hair_color, 0.93)
	var child: Node3D = Node3D.new()
	child.name = "Child"
	child.position = Vector3(0.46, 0.0, 0.03)
	root.add_child(child)

	_add(child, "SoftKnitSweater", KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.135, 0.0), Vector2(0.163, 0.036),
		Vector2(0.170, 0.15), Vector2(0.158, 0.30), Vector2(0.128, 0.36),
		Vector2(0.067, 0.408), Vector2(0.0, 0.408)
	]), 16), knit, Vector3(0.0, 0.455, 0.0), Vector3(1.0, 1.0, 0.76))
	_add(child, "RibbedSweaterHem", KIT.lathe(PackedVector2Array([
		Vector2(0.136, 0.0), Vector2(0.149, 0.012), Vector2(0.158, 0.043),
		Vector2(0.154, 0.047), Vector2(0.136, 0.0)
	]), 16), ribbing, Vector3(0.0, 0.455, 0.0), Vector3(1.0, 1.0, 0.76))
	_legs_and_shoes(child, true, KIT.fabric(KIT.INDIGO.darkened(0.14), "family_child_trousers"), linen, KIT.paint(KIT.WALNUT, 0.9))
	_add(child, "FaceNeckAndEars", _head_mesh(true), skin, Vector3(0.0, 0.979, 0.0))
	_add(child, "SoftFringe", _hair_mesh(true, style == 2), hair, Vector3(0.0, 0.979, -0.006))
	_add(child, "CuriousExpression", _face_mesh(true), KIT.paint(KIT.CHARCOAL.darkened(0.45)), Vector3(0.0, 0.979, 0.0))

	var outer_shoulder: Vector3 = Vector3(0.132, 0.784, 0.0)
	var outer_wrist: Vector3 = Vector3(0.186, 0.613, 0.026)
	var inner_shoulder: Vector3 = Vector3(-0.128, 0.79, 0.0)
	var inner_wrist: Vector3 = Vector3(-0.186, 0.871, 0.023)
	_segment(child, "SmallRelaxedSleeve", outer_shoulder, outer_wrist, 0.060, knit)
	_segment(child, "RaisedSleeve", inner_shoulder, inner_wrist, 0.060, knit)
	_cuffs(child, true, outer_shoulder, outer_wrist, inner_shoulder, inner_wrist, ribbing)
	_orb(child, "FreeHand", Vector3(0.065, 0.083, 0.065), Vector3(0.205, 0.536, 0.035), skin)
	_segment(child, "HoldingParentHand", Vector3(-0.210, 0.906, 0.029), Vector3(-0.231, 0.950, 0.042), 0.033, skin)
	_add(child, "CreamCrewNeck", KIT.lathe(PackedVector2Array([
		Vector2(0.045, 0.0), Vector2(0.075, 0.004), Vector2(0.077, 0.021),
		Vector2(0.053, 0.042), Vector2(0.044, 0.036), Vector2(0.045, 0.0)
	]), 16), linen, Vector3(0.0, 0.833, 0.0), Vector3(1.0, 1.0, 0.86))
	_add(child, "AirportAdventurePrint", _print_mesh(), _print_material(), Vector3(0.0, 0.703, 0.126))
	if style % 2 == 0:
		# A soft daypack, tucked behind the torso, with two continuous shoulder loops.
		_add(child, "LittleLinenDaypack", KIT.rounded_box(Vector3(0.216, 0.255, 0.115), 0.052, 3), linen, Vector3(0.0, 0.675, -0.153))
		var straps: Array[Mesh] = []
		for side: int in [-1, 1]:
			var strap_x: float = float(side) * 0.088
			straps.append(_path_mesh("child_pack_strap_%d" % side, PackedVector3Array([
				Vector3(strap_x, 0.560, -0.164), Vector3(strap_x, 0.811, -0.111),
				Vector3(strap_x, 0.840, 0.007), Vector3(strap_x, 0.780, 0.094),
				Vector3(strap_x, 0.578, 0.111), Vector3(strap_x, 0.560, -0.164)
			]), 0.008))
		_add(child, "DaypackShoulderLoops", _merge("child_pack_straps", straps, [Transform3D.IDENTITY, Transform3D.IDENTITY]), ribbing, Vector3.ZERO)

	if style % 2 == 1:
		_add(child, "LinenBucketHat", KIT.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.171, 0.0), Vector2(0.174, 0.013),
			Vector2(0.142, 0.034), Vector2(0.135, 0.085), Vector2(0.103, 0.099),
			Vector2(0.0, 0.101)
		]), 16), linen, Vector3(0.0, 1.08, -0.008), Vector3(1.0, 1.0, 0.91))
	elif style == 2:
		_orb(child, "SmallTopknot", Vector3(0.065, 0.065, 0.065), Vector3(0.06, 1.118, -0.047), hair)


static func _legs_and_shoes(parent: Node3D, small: bool, cloth: Material, upper: Material, sole: Material) -> void:
	var key: String = "child" if small else "adult"
	var spread: float = 0.080 if small else 0.108
	var trouser_height: float = 0.424 if small else 0.795
	var radius: float = 0.060 if small else 0.077
	var leg: Mesh = KIT.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(radius * 0.88, 0.0), Vector2(radius, 0.025),
		Vector2(radius * 1.13, trouser_height * 0.74), Vector2(radius, trouser_height),
		Vector2(0.0, trouser_height)
	]), 12)
	var shoe_size: Vector3 = Vector3(0.13, 0.076, 0.194) if small else Vector3(0.171, 0.084, 0.267)
	var shoe: Mesh = KIT.rounded_box(shoe_size, 0.037, 3)
	var outsole: Mesh = KIT.rounded_box(Vector3(shoe_size.x + 0.006, 0.032, shoe_size.z + 0.008), 0.015, 3)
	var legs: Array[Transform3D] = []
	var shoes: Array[Transform3D] = []
	var soles: Array[Transform3D] = []
	for side: int in [-1, 1]:
		var x: float = float(side) * spread
		var z: float = 0.022 if side < 0 else -0.025
		legs.append(_pose(Vector3(x, 0.073, z), Vector3(1.0, 1.0, 0.9)))
		shoes.append(_pose(Vector3(x, 0.032 + shoe_size.y * 0.5, z + 0.039)))
		# Flat bottoms, including both feet of the shorter figure, are exactly y = 0.
		soles.append(_pose(Vector3(x, 0.016, z + 0.039)))
	_add(parent, "TaperedTrouserLegs", _merge(key + "_legs", [leg, leg], legs), cloth, Vector3.ZERO)
	_add(parent, "RoundedWalkingShoes", _merge(key + "_shoes", [shoe, shoe], shoes), upper, Vector3.ZERO)
	_add(parent, "LayeredShoeSoles", _merge(key + "_soles", [outsole, outsole], soles), sole, Vector3.ZERO)


static func _build_satchel(parent: Node3D, style: int, linen: Material, leather: Material) -> void:
	var bag_color: Color = KIT.OAK if style % 2 == 0 else KIT.SAGE.darkened(0.18)
	var canvas: Material = KIT.fabric(bag_color, "family_satchel_%d" % (style % 2))
	_add(parent, "RolledLeatherShoulderStrap", _path_mesh("satchel_strap", PackedVector3Array([
		Vector3(-0.330, 0.887, -0.065), Vector3(-0.328, 1.118, -0.067),
		Vector3(-0.207, 1.317, -0.022), Vector3(-0.185, 1.328, 0.063),
		Vector3(-0.314, 1.09, 0.092), Vector3(-0.340, 0.887, 0.094)
	]), 0.011), leather, Vector3.ZERO)
	_add(parent, "CanvasShoulderBag", KIT.rounded_box(Vector3(0.250, 0.285, 0.170), 0.057, 3), canvas, Vector3(-0.331, 0.774, 0.018))
	_add(parent, "RoundedBagFlap", KIT.rounded_box(Vector3(0.229, 0.109, 0.026), 0.012, 3), linen, Vector3(-0.331, 0.856, 0.105))
	_add(parent, "SatchelFlapBinding", _path_mesh("satchel_binding", PackedVector3Array([
		Vector3(-0.430, 0.893, 0.119), Vector3(-0.430, 0.822, 0.119),
		Vector3(-0.417, 0.814, 0.120), Vector3(-0.245, 0.814, 0.120),
		Vector3(-0.232, 0.822, 0.119), Vector3(-0.232, 0.893, 0.119)
	]), 0.003), leather, Vector3.ZERO)
	_orb(parent, "BrassBagClasp", Vector3(0.024, 0.031, 0.012), Vector3(-0.331, 0.829, 0.124), KIT.brass())


static func _cuffs(parent: Node3D, small: bool, shoulder_a: Vector3, wrist_a: Vector3, shoulder_b: Vector3, wrist_b: Vector3, material: Material) -> void:
	var radius: float = 0.059 if small else 0.075
	var cuff: Mesh = KIT.lathe(PackedVector2Array([
		Vector2(0.0, -0.015), Vector2(radius - 0.004, -0.015), Vector2(radius, -0.009),
		Vector2(radius, 0.009), Vector2(radius - 0.004, 0.015), Vector2(0.0, 0.015)
	]), 12)
	var direction_a: Vector3 = (wrist_a - shoulder_a).normalized()
	var direction_b: Vector3 = (wrist_b - shoulder_b).normalized()
	var poses: Array[Transform3D] = [
		Transform3D(Basis(Quaternion(Vector3.UP, direction_a)), wrist_a + direction_a * 0.025),
		Transform3D(Basis(Quaternion(Vector3.UP, direction_b)), wrist_b + direction_b * 0.025)
	]
	_add(parent, "WovenSleeveCuffs", _merge("child_cuffs" if small else "adult_cuffs", [cuff, cuff], poses), material, Vector3.ZERO)


static func _head_mesh(small: bool) -> Mesh:
	var key: String = "child_head" if small else "adult_head"
	var radii: Vector3 = Vector3(0.142, 0.153, 0.136) if small else Vector3(0.160, 0.184, 0.147)
	var sphere: Mesh = _sphere()
	var neck_y: float = -0.132 if small else -0.170
	var parts: Array[Mesh] = [sphere, sphere, sphere, sphere, sphere]
	var poses: Array[Transform3D] = [
		_pose(Vector3.ZERO, radii),
		_pose(Vector3(-radii.x * 0.96, -0.018, -0.007), Vector3(0.026, 0.036, 0.028)),
		_pose(Vector3(radii.x * 0.96, -0.018, -0.007), Vector3(0.026, 0.036, 0.028)),
		_pose(Vector3(0.0, -0.021, radii.z * 0.96), Vector3(0.023, 0.025, 0.033)),
		_pose(Vector3(0.0, neck_y, 0.0), Vector3(0.053, 0.077, 0.050))
	]
	return _merge(key, parts, poses)


static func _face_mesh(small: bool) -> Mesh:
	var key: String = "child_expression" if small else "adult_expression"
	var eye_x: float = 0.049 if small else 0.057
	var face_z: float = 0.131 if small else 0.142
	var sphere: Mesh = _sphere()
	var smile: Mesh = _path_mesh(key + "_smile", PackedVector3Array([
		Vector3(-0.024, -0.060, face_z - 0.005), Vector3(0.0, -0.066, face_z),
		Vector3(0.024, -0.060, face_z - 0.005)
	]), 0.0032)
	return _merge(key, [sphere, sphere, smile], [
		_pose(Vector3(-eye_x, 0.010, face_z), Vector3(0.010, 0.014, 0.007)),
		_pose(Vector3(eye_x, 0.010, face_z), Vector3(0.010, 0.014, 0.007)),
		Transform3D.IDENTITY
	])


static func _hair_mesh(small: bool, swept: bool) -> Mesh:
	var key: String = "hair_%s_%s" % [small, swept]
	if _meshes.has(key):
		return _meshes[key] as Mesh
	var radii: Vector3 = Vector3(0.149, 0.164, 0.143) if small else Vector3(0.170, 0.205, 0.157)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The front hairline sits above the eyes; sides wrap down to a softly cropped nape.
	for segment: int in range(20):
		for ring: int in range(7):
			var corners: Array[Vector2] = [
				Vector2(segment, ring), Vector2(segment, ring + 1), Vector2(segment + 1, ring),
				Vector2(segment + 1, ring), Vector2(segment, ring + 1), Vector2(segment + 1, ring + 1)
			]
			for corner: Vector2 in corners:
				var azimuth: float = corner.x / 20.0 * TAU
				var front: float = (cos(azimuth) + 1.0) * 0.5
				var hem_angle: float = lerpf(2.09, 1.10, front)
				if swept:
					hem_angle += sin(azimuth) * 0.14 * front
				var latitude: float = corner.y / 7.0 * hem_angle
				var unit: Vector3 = Vector3(sin(azimuth) * sin(latitude), cos(latitude), cos(azimuth) * sin(latitude))
				surface.set_normal((unit / radii).normalized())
				surface.set_uv(Vector2(corner.x / 20.0, corner.y / 7.0))
				surface.add_vertex(unit * radii)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _print_mesh() -> Mesh:
	if not _meshes.has("plane_print"):
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.135, 0.135)
		_meshes["plane_print"] = quad
	return _meshes["plane_print"] as Mesh


static func _print_material() -> Material:
	if not _materials.has("plane_print"):
		# Reuse the terminal's nonverbal wayfinding artwork as a matte screen print.
		var material: StandardMaterial3D = SIGNS._icon_material("plane", Color(0.0, 0.0, 0.0, 0.0)).duplicate() as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		material.emission_enabled = false
		material.roughness = 0.95
		_materials["plane_print"] = material
	return _materials["plane_print"] as Material


static func _sphere() -> Mesh:
	if not _meshes.has("sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 16
		sphere.rings = 8
		_meshes["sphere"] = sphere
	return _meshes["sphere"] as Mesh


static func _capsule(radius: float, span: float) -> Mesh:
	var key: String = "capsule:%.5f:%.5f" % [radius, span]
	if not _meshes.has(key):
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = span + radius * 2.0
		capsule.radial_segments = 12
		capsule.rings = 4
		_meshes[key] = capsule
	return _meshes[key] as Mesh


static func _path_mesh(key: String, points: PackedVector3Array, radius: float) -> Mesh:
	var cache_key: String = "path:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as Mesh
	var parts: Array[Mesh] = []
	var poses: Array[Transform3D] = []
	for index: int in range(points.size() - 1):
		var a: Vector3 = points[index]
		var b: Vector3 = points[index + 1]
		parts.append(_capsule(radius, a.distance_to(b)))
		poses.append(Transform3D(Basis(Quaternion(Vector3.UP, (b - a).normalized())), (a + b) * 0.5))
	return _merge(cache_key, parts, poses)


static func _merge(key: String, parts: Array[Mesh], poses: Array[Transform3D]) -> Mesh:
	if _meshes.has(key):
		return _meshes[key] as Mesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(parts.size()):
		var part: Mesh = parts[index]
		var pose: Transform3D = poses[index]
		surface.append_from(part, 0, pose)
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _pose(at: Vector3, size: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_scale(size), at)


static func _add(parent: Node3D, part_name: String, mesh: Mesh, material: Material, at: Vector3, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance: MeshInstance3D = KIT.add(parent, mesh, material, at)
	instance.name = part_name
	instance.scale = size
	return instance


static func _orb(parent: Node3D, part_name: String, diameter: Vector3, at: Vector3, material: Material) -> void:
	_add(parent, part_name, _sphere(), material, at, diameter * 0.5)


static func _segment(parent: Node3D, part_name: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var instance: MeshInstance3D = _add(parent, part_name, _capsule(radius, a.distance_to(b)), material, (a + b) * 0.5)
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
