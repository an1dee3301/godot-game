extends RefCounted
## A quietly adventurous traveller. Floor-contact origin; face and cap bill point +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Backpacker"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = ((variant % 4) + 4) % 4
	var shirts: Array[Color] = [Kit.LINEN, Kit.SAGE, Kit.CLAY, Kit.CREAM]
	var packs: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.OCHRE]
	var trousers: Array[Color] = [Kit.INDIGO, Kit.WALNUT, Kit.CHARCOAL, Kit.SAGE.darkened(0.25)]
	var skins: Array[Color] = [Color(0.72, 0.48, 0.33), Color(0.9, 0.68, 0.5), Color(0.43, 0.27, 0.19), Color(0.79, 0.56, 0.4)]
	var hair_colors: Array[Color] = [Kit.CHARCOAL, Kit.WALNUT, Color(0.12, 0.09, 0.075), Color(0.57, 0.36, 0.18)]
	var shirt: Material = Kit.fabric(shirts[style], "backpacker_shirt_%d" % style)
	var canvas: Material = Kit.fabric(packs[style], "backpacker_canvas_%d" % style)
	var dark_canvas: Material = Kit.fabric(packs[style].darkened(0.23), "backpacker_reinforcement_%d" % style)
	var pants: Material = Kit.fabric(trousers[style], "backpacker_trousers_%d" % style)
	var skin: Material = Kit.paint(skins[style], 0.86)
	var hair: Material = Kit.paint(hair_colors[style], 0.94)
	var webbing: Material = Kit.fabric(Kit.WALNUT.darkened(0.2), "backpacker_webbing")
	var cream: Material = Kit.fabric(Kit.CREAM, "backpacker_cotton")
	var rubber: Material = Kit.paint(Kit.LIMESTONE, 0.95)
	var shoe: Material = Kit.fabric(shirts[style].darkened(0.2), "backpacker_sneakers_%d" % style)

	# Long legs and small, layered trainers retain adult proportions beneath the cap.
	var foot_offsets: Array[Vector3] = [Vector3(-0.112, 0.0, 0.061), Vector3(0.112, 0.0, 0.019)]
	var foot_transforms: Array[Transform3D] = []
	var upper_transforms: Array[Transform3D] = []
	var sock_transforms: Array[Transform3D] = []
	var lace_transforms: Array[Transform3D] = []
	for index: int in 2:
		var offset: Vector3 = foot_offsets[index]
		foot_transforms.append(Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.8)), offset))
		upper_transforms.append(Transform3D(Basis.from_scale(Vector3(0.169, 0.134, 0.282)), offset + Vector3(0.0, 0.109, -0.021)))
		sock_transforms.append(Transform3D(Basis.IDENTITY, offset + Vector3(0.0, 0.18, -0.057)))
		var leg: MeshInstance3D = _part(root, "TrouserLeg%d" % index, _capsule(0.076, 0.667), pants, offset + Vector3(0.0, 0.5225, -0.04))
		leg.rotation_degrees.z = -1.0 if index == 0 else 1.0
		for row: int in 3:
			lace_transforms.append(Transform3D(Basis.IDENTITY, offset + Vector3(0.0, -float(row) * 0.004, float(row) * 0.031 - 0.035)))
	var sole_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.071, 0.0), Vector2(0.087, 0.01), Vector2(0.09, 0.032), Vector2(0.082, 0.047), Vector2(0.0, 0.047)])
	_part(root, "CreamRubberSoles", _copies("soles", Kit.lathe(sole_profile, 16), foot_transforms), rubber)
	_part(root, "CanvasSneakers", _copies("shoe_uppers", _ball(), upper_transforms), shoe)
	_part(root, "RibbedSocks", _copies("socks", _capsule(0.05, 0.16), sock_transforms), cream)
	var lace: ArrayMesh = _ribbon("lace", PackedVector3Array([Vector3(-0.06, 0.147, 0.0), Vector3(-0.028, 0.171, 0.0), Vector3(0.028, 0.171, 0.0), Vector3(0.06, 0.147, 0.0)]), 0.011, 0.008, Vector3.FORWARD)
	_part(root, "CottonLaces", _copies("six_laces", lace, lace_transforms), cream)
	_oval(root, "TrouserSeat", Vector3(0.338, 0.255, 0.255), Vector3(0.0, 0.823, -0.007), pants)

	var torso_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.184, 0.033), Vector2(0.194, 0.2), Vector2(0.22, 0.345), Vector2(0.207, 0.401), Vector2(0.119, 0.46), Vector2(0.082, 0.477), Vector2(0.0, 0.477)])
	var torso: MeshInstance3D = _part(root, "LinenOvershirt", Kit.lathe(torso_profile, 16), shirt, Vector3(0.0, 0.845, 0.0))
	torso.scale.z = 0.7
	_oval(root, "CollarBinding", Vector3(0.187, 0.046, 0.144), Vector3(0.0, 1.308, 0.0), cream)
	_part(root, "Neck", _capsule(0.062, 0.144), skin, Vector3(0.0, 1.359, 0.0))
	_oval(root, "Face", Vector3(0.286, 0.321, 0.264), Vector3(0.0, 1.511, 0.008), skin)
	var ears: Array[Transform3D] = [Transform3D(Basis.from_scale(Vector3(0.057, 0.083, 0.055)), Vector3(-0.139, 1.507, 0.003)), Transform3D(Basis.from_scale(Vector3(0.057, 0.083, 0.055)), Vector3(0.139, 1.507, 0.003))]
	_part(root, "Ears", _copies("ears", _ball(), ears), skin)
	var eyes: Array[Transform3D] = [Transform3D(Basis.from_scale(Vector3(0.015, 0.023, 0.012)), Vector3(-0.048, 1.533, 0.132)), Transform3D(Basis.from_scale(Vector3(0.015, 0.023, 0.012)), Vector3(0.048, 1.533, 0.132))]
	_part(root, "BrightEyes", _copies("eyes", _ball(), eyes), Kit.paint(Kit.CHARCOAL, 0.65))
	_oval(root, "Nose", Vector3(0.04, 0.047, 0.036), Vector3(0.0, 1.499, 0.142), skin)
	_oval(root, "HairAtNape", Vector3(0.258, 0.205, 0.087), Vector3(0.0, 1.558, -0.099), hair)
	if style % 2 == 1:
		_oval(root, "LowHairBun", Vector3(0.115, 0.123, 0.115), Vector3(0.0, 1.503, -0.17), hair)
	else:
		_oval(root, "SideSweptFringe", Vector3(0.137, 0.046, 0.035), Vector3(-0.043, 1.611, 0.105), hair, Vector3(0.0, 0.0, -13.0))
	var cap_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.148, 0.0), Vector2(0.154, 0.016), Vector2(0.148, 0.061), Vector2(0.116, 0.104), Vector2(0.06, 0.126), Vector2(0.0, 0.134)])
	var crown: MeshInstance3D = _part(root, "SoftCapCrown", Kit.lathe(cap_profile, 16), canvas, Vector3(0.0, 1.599, -0.006))
	crown.scale.z = 0.94
	_oval(root, "CurvedCapBill", Vector3(0.316, 0.028, 0.281), Vector3(0.0, 1.612, 0.116), dark_canvas, Vector3(9.0, 0.0, 0.0))
	_oval(root, "CapButton", Vector3(0.029, 0.016, 0.029), Vector3(0.0, 1.731, -0.006), dark_canvas)

	# One arm holds a shoulder strap; the other hangs in a relaxed, asymmetric pose.
	_limb(root, "LeftSleeve", Vector3(-0.201, 1.239, 0.0), Vector3(-0.274, 1.09, 0.023), 0.079, shirt)
	_limb(root, "RightSleeve", Vector3(0.201, 1.239, 0.0), Vector3(0.264, 1.09, -0.011), 0.079, shirt)
	_limb(root, "BentForearm", Vector3(-0.279, 1.056, 0.039), Vector3(-0.16, 1.18, 0.165), 0.046, skin)
	_limb(root, "RelaxedForearm", Vector3(0.269, 1.047, 0.005), Vector3(0.288, 0.906, 0.055), 0.047, skin)
	_oval(root, "StrapHoldingHand", Vector3(0.078, 0.089, 0.079), Vector3(-0.147, 1.205, 0.171), skin)
	_oval(root, "RelaxedHand", Vector3(0.076, 0.116, 0.082), Vector3(0.29, 0.853, 0.063), skin)

	# A substantial hiking pack: padded shell, reinforced boot, overlapping lid and pocket.
	var pack_body: MeshInstance3D = _part(root, "RucksackCanvasShell", _capsule(0.237, 0.673), canvas, Vector3(0.0, 1.115, -0.259))
	pack_body.scale.z = 0.7
	_oval(root, "ReinforcedPackBase", Vector3(0.448, 0.224, 0.321), Vector3(0.0, 0.849, -0.27), dark_canvas)
	_oval(root, "OverlappingTopFlap", Vector3(0.484, 0.195, 0.355), Vector3(0.0, 1.351, -0.274), dark_canvas)
	_oval(root, "RearBellowsPocket", Vector3(0.33, 0.31, 0.142), Vector3(0.0, 1.065, -0.411), canvas)
	var shoulder: ArrayMesh = _ribbon("shoulder", PackedVector3Array([Vector3(0.0, 0.905, -0.133), Vector3(0.0, 1.227, -0.177), Vector3(0.0, 1.321, -0.114), Vector3(0.0, 1.349, -0.022), Vector3(0.0, 1.306, 0.112), Vector3(0.0, 1.191, 0.143), Vector3(0.0, 1.019, 0.131), Vector3(0.0, 0.916, 0.091)]), 0.052, 0.023)
	var shoulder_offsets: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3(-0.127, 0.0, 0.0)), Transform3D(Basis.IDENTITY, Vector3(0.127, 0.0, 0.0))]
	_part(root, "CurvedPaddedShoulderStraps", _copies("two_shoulders", shoulder, shoulder_offsets), webbing)
	_part(root, "PackCarryLoop", _ribbon("carry_loop", PackedVector3Array([Vector3(-0.058, 1.421, -0.244), Vector3(-0.057, 1.481, -0.244), Vector3(0.0, 1.497, -0.244), Vector3(0.057, 1.481, -0.244), Vector3(0.058, 1.421, -0.244)]), 0.022, 0.018, Vector3.FORWARD), webbing)
	var closure: ArrayMesh = _ribbon("closure", PackedVector3Array([Vector3(0.0, 1.389, -0.393), Vector3(0.0, 1.32, -0.44), Vector3(0.0, 1.223, -0.438), Vector3(0.0, 1.168, -0.453)]), 0.031, 0.012)
	var closure_offsets: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3(-0.113, 0.0, 0.0)), Transform3D(Basis.IDENTITY, Vector3(0.113, 0.0, 0.0))]
	_part(root, "LidWebbingTails", _copies("two_closures", closure, closure_offsets), webbing)
	var buckle_offsets: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3(-0.113, 1.233, -0.449)), Transform3D(Basis.IDENTITY, Vector3(0.113, 1.233, -0.449))]
	_part(root, "BrassPackClasps", _copies("clasps", Kit.rounded_box(Vector3(0.045, 0.04, 0.018), 0.008), buckle_offsets), Kit.brass())

	# Shared airport pictogram, used as a woven travel patch without miniature text.
	var departure_text: Array = Signs.TEXT["departures"]
	var plane_icon: String = str(departure_text[6])
	var patch: MeshInstance3D = _part(root, "AircraftTravelPatch", _patch(), Signs._icon_material(plane_icon, Kit.CLAY if style == 0 else Kit.OCHRE), Vector3(0.0, 1.071, -0.484))
	patch.rotation_degrees.y = 180.0
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var accessory_side: float = 1.0 if style % 2 == 0 else -1.0
	var bottle_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.041, 0.0), Vector2(0.048, 0.015), Vector2(0.048, 0.187), Vector2(0.031, 0.211), Vector2(0.027, 0.238), Vector2(0.0, 0.238)])
	_part(root, "ReusableFlask", Kit.lathe(bottle_profile, 12), Kit.metal(Kit.LINEN, 0.42, 0.45, "backpacker_flask"), Vector3(accessory_side * 0.261, 0.997, -0.276))
	_part(root, "FlaskCap", _capsule(0.029, 0.038), Kit.brass(), Vector3(accessory_side * 0.261, 1.238, -0.276))
	_oval(root, "BottleSidePocket", Vector3(0.14, 0.19, 0.169), Vector3(accessory_side * 0.244, 1.012, -0.271), dark_canvas)
	return root


static func _part(parent: Node3D, part_name: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = Kit.add(parent, mesh, material, at)
	node.name = part_name
	return node


static func _oval(parent: Node3D, part_name: String, size: Vector3, at: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var node: MeshInstance3D = _part(parent, part_name, _ball(), material, at)
	node.scale = size
	node.rotation_degrees = rotation


static func _limb(parent: Node3D, part_name: String, start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var direction: Vector3 = end - start
	var node: MeshInstance3D = _part(parent, part_name, _capsule(radius, direction.length() + radius * 2.0), material, (start + end) * 0.5)
	node.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var key: String = "capsule:%.5f:%.5f" % [radius, height]
	if not _meshes.has(key):
		var mesh: CapsuleMesh = CapsuleMesh.new()
		mesh.radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		mesh.rings = 4
		_meshes[key] = mesh
	return _meshes[key] as CapsuleMesh


static func _ball() -> SphereMesh:
	if not _meshes.has("ball"):
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 16
		mesh.rings = 8
		_meshes["ball"] = mesh
	return _meshes["ball"] as SphereMesh


static func _patch() -> QuadMesh:
	if not _meshes.has("patch"):
		var mesh: QuadMesh = QuadMesh.new()
		mesh.size = Vector2(0.103, 0.096)
		_meshes["patch"] = mesh
	return _meshes["patch"] as QuadMesh


static func _copies(key: String, source: Mesh, transforms: Array[Transform3D]) -> ArrayMesh:
	var cache_key: String = "copies:" + key
	if not _meshes.has(cache_key):
		var surface: SurfaceTool = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for transform: Transform3D in transforms:
			surface.append_from(source, 0, transform)
		_meshes[cache_key] = surface.commit()
	return _meshes[cache_key] as ArrayMesh


## Closed, softly octagonal webbing swept along a polyline; all generated meshes are shared.
static func _ribbon(key: String, points: PackedVector3Array, width: float, thickness: float, across: Vector3 = Vector3.RIGHT) -> ArrayMesh:
	var cache_key: String = "ribbon:" + key
	if _meshes.has(cache_key):
		return _meshes[cache_key] as ArrayMesh
	var rings: Array[PackedVector3Array] = []
	for index: int in points.size():
		var tangent: Vector3 = (points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]).normalized()
		var normal: Vector3 = tangent.cross(across).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for corner: int in 8:
			var angle: float = TAU * float(corner) / 8.0
			ring.append(points[index] + across * cos(angle) * width * 0.5 + normal * sin(angle) * thickness * 0.5)
		rings.append(ring)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in rings.size() - 1:
		var lower: PackedVector3Array = rings[index]
		var upper: PackedVector3Array = rings[index + 1]
		for corner: int in 8:
			var next: int = (corner + 1) % 8
			for vertex: Vector3 in [lower[corner], upper[corner], lower[next], lower[next], upper[corner], upper[next]]:
				surface.add_vertex(vertex)
	var first: PackedVector3Array = rings[0]
	var last: PackedVector3Array = rings[rings.size() - 1]
	for corner: int in 8:
		var next: int = (corner + 1) % 8
		for vertex: Vector3 in [points[0], first[corner], first[next], points[points.size() - 1], last[next], last[corner]]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[cache_key] = mesh
	return mesh
