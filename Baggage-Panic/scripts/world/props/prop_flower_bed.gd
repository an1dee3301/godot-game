extends RefCounted
## Low oak garden trough; all botanical geometry is shared by three instanced batches.

const KIT = preload("res://scripts/world/design_kit.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FlowerBed"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak_tint: Color = KIT.OAK.lightened(float(style) * 0.025)
	var oak: StandardMaterial3D = KIT.wood(oak_tint, "flower_bed_oak_%d" % style)
	var dark: StandardMaterial3D = KIT.metal()
	var walnut: StandardMaterial3D = KIT.wood(KIT.WALNUT, "flower_bed_walnut")
	KIT.rbox(root, Vector3(3.22, 0.08, 1.22), Vector3(0.0, 0.04, 0.0), KIT.stone(), 0.035)
	KIT.rbox(root, Vector3(3.16, 0.06, 1.16), Vector3(0.0, 0.105, 0.0), dark, 0.025)
	# Two courses with real shadow joints; three boards along each long face.
	for course in 2:
		var y: float = 0.195 + float(course) * 0.145
		for side: float in [-1.0, 1.0]:
			for board in 3:
				KIT.rbox(root, Vector3(1.092, 0.137, 0.105), Vector3(float(board - 1) * 1.10, y, side * 0.637), oak, 0.017)
			KIT.rbox(root, Vector3(0.105, 0.137, 1.164), Vector3(side * 1.603, y, 0.0), oak, 0.017)
	# Recessed liner and textured earth remain visible between the planting clusters.
	KIT.rbox(root, Vector3(3.12, 0.20, 1.13), Vector3(0.0, 0.26, 0.0), dark, 0.035)
	KIT.rbox(root, Vector3(3.06, 0.035, 1.07), Vector3(0.0, 0.365, 0.0), KIT.stone(Color(0.19, 0.14, 0.095), 0.98, "flower_bed_soil"), 0.015)
	# Soft coping surrounds the open planting area rather than covering it.
	for side: float in [-1.0, 1.0]:
		KIT.rbox(root, Vector3(3.35, 0.065, 0.15), Vector3(0.0, 0.433, side * 0.64), oak, 0.027)
		KIT.rbox(root, Vector3(0.15, 0.065, 1.13), Vector3(side * 1.60, 0.433, 0.0), oak, 0.027)
		KIT.rbox(root, Vector3(3.26, 0.016, 0.015), Vector3(0.0, 0.392, side * 0.691), walnut, 0.006, false)
		# Flush brass joinery pins catch the light on the front and back.
		for x: float in [-1.10, 0.0, 1.10]:
			KIT.add(root, KIT.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.009, 0.0), Vector2(0.009, 0.004), Vector2(0.0, 0.004)]), 8), KIT.brass(), Vector3(x, 0.337, side * 0.691), Vector3(side * 90.0, 0.0, 0.0), false)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7819 + style * 137
	var plants: Array[Array] = [[], [], []]
	for row in 6:
		for column in 18:
			var species: int = posmod(column + row * 2 + style, 3)
			if style == 1 and column % 4 == 0:
				species = 0
			elif style == 2 and row % 3 == 0:
				species = 1
			elif style == 3 and column % 4 == 0:
				species = 2
			var position: Vector3 = Vector3(-1.43 + float(column) * 0.168 + rng.randf_range(-0.035, 0.035), 0.38, -0.445 + float(row) * 0.178 + rng.randf_range(-0.025, 0.025))
			var scale: float = rng.randf_range(0.78, 1.15)
			var basis: Basis = Basis.from_euler(Vector3(rng.randf_range(-0.10, 0.10), rng.randf_range(0.0, TAU), rng.randf_range(-0.10, 0.10))).scaled(Vector3(scale, scale, scale))
			plants[species].append(Transform3D(basis, position))
	for species in 3:
		var batch: MultiMesh = MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.use_colors = true
		batch.mesh = _plant_mesh(species)
		# Fixed local bounds include all jittered stems, petals and leaning tips.
		batch.custom_aabb = AABB(Vector3(-1.58, 0.36, -0.59), Vector3(3.16, 0.65, 1.18))
		var transforms: Array = plants[species]
		batch.instance_count = transforms.size()
		for i in transforms.size():
			var transform: Transform3D = transforms[i]
			batch.set_instance_transform(i, transform)
			var warmth: float = rng.randf_range(0.89, 1.0)
			batch.set_instance_color(i, Color(warmth, warmth, rng.randf_range(0.93, 1.0)))
		var flowers: MultiMeshInstance3D = MultiMeshInstance3D.new()
		flowers.name = ["Lavender", "WhiteDaisies", "YellowBlooms"][species]
		flowers.multimesh = batch
		flowers.material_override = _plant_material()
		root.add_child(flowers)
	return root


static func _plant_material() -> StandardMaterial3D:
	if not _materials.has("botanical"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.87
		_materials["botanical"] = material
	return _materials["botanical"] as StandardMaterial3D


static func _plant_mesh(species: int) -> ArrayMesh:
	if _meshes.has(species):
		return _meshes[species] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green: Color = Color(0.25, 0.37, 0.21) if species != 0 else KIT.SAGE.darkened(0.23)
	var height: float = 0.46 if species == 0 else 0.30
	_ellipsoid(surface, Vector3(0.0, height * 0.5, 0.0), Vector3(0.006, height * 0.5, 0.006), Basis.IDENTITY, green)
	for leaf in 4:
		var angle: float = float(leaf) * 2.4
		var center: Vector3 = Vector3(cos(angle) * 0.035, 0.08 + float(leaf) * 0.047, sin(angle) * 0.035)
		var leaf_basis: Basis = Basis(Vector3.UP, -angle) * Basis(Vector3.FORWARD, 0.35)
		_ellipsoid(surface, center, Vector3(0.059, 0.006, 0.018), leaf_basis, green.lightened(0.06))
	if species == 0:
		# Small overlapping florets make a recognisable tapered lavender spike.
		for tier in 7:
			var radius: float = 0.024 * (1.0 - float(tier) * 0.08)
			for floret in 4:
				var angle: float = float(floret) * TAU / 4.0 + float(tier) * 0.65
				_ellipsoid(surface, Vector3(cos(angle) * radius, 0.36 + float(tier) * 0.023, sin(angle) * radius), Vector3(0.017, 0.023, 0.017), Basis.IDENTITY, Color(0.59, 0.46, 0.72).lightened(float(tier) * 0.025))
	else:
		var petal_color: Color = KIT.CREAM if species == 1 else Color(0.95, 0.76, 0.28)
		var petal_count: int = 9 if species == 1 else 7
		for petal in petal_count:
			var angle: float = TAU * float(petal) / float(petal_count)
			var center: Vector3 = Vector3(cos(angle) * 0.043, height, sin(angle) * 0.043)
			_ellipsoid(surface, center, Vector3(0.041, 0.009, 0.016), Basis(Vector3.UP, -angle), petal_color)
		_ellipsoid(surface, Vector3(0.0, height + 0.012, 0.0), Vector3(0.022, 0.015, 0.022), Basis.IDENTITY, KIT.OCHRE if species == 1 else Color(0.40, 0.24, 0.10))
	var mesh: ArrayMesh = surface.commit()
	_meshes[species] = mesh
	return mesh


## Small smooth botanical volumes; explicit normals keep thin leaves softly lit.
static func _ellipsoid(surface: SurfaceTool, center: Vector3, radii: Vector3, basis: Basis, color: Color) -> void:
	for band in 5:
		for segment in 8:
			var corners: Array[Vector2] = [Vector2(segment, band), Vector2(segment + 1, band), Vector2(segment + 1, band + 1), Vector2(segment, band + 1)]
			for index: int in [0, 2, 1, 0, 3, 2]:
				var corner: Vector2 = corners[index]
				var latitude: float = PI * corner.y / 5.0
				var longitude: float = TAU * corner.x / 8.0
				var unit: Vector3 = Vector3(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude))
				surface.set_color(color)
				surface.set_normal((basis * (unit / radii)).normalized())
				surface.add_vertex(center + basis * (unit * radii))
