extends RefCounted
## A sheltered sakura: sculpted limestone vessel, weathered wood and cupped blossoms.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CherryTree"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var stones: Array[Color] = [KIT.LIMESTONE, Color(0.78, 0.76, 0.69), Color(0.88, 0.81, 0.73), Color(0.74, 0.77, 0.70)]
	var stone: StandardMaterial3D = KIT.stone(stones[style], 0.72, "sakura_vessel_%d" % style)
	# Complete hollow section: recessed foot, rounded belly, rolled lip and inner wall.
	var vessel: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.035), Vector2(0.91, 0.035), Vector2(0.98, 0.07),
		Vector2(1.02, 0.16), Vector2(1.17, 0.25), Vector2(1.29, 0.59),
		Vector2(1.34, 0.79), Vector2(1.33, 0.85), Vector2(1.29, 0.89),
		Vector2(1.21, 0.89), Vector2(1.17, 0.84), Vector2(1.17, 0.75),
		Vector2(0.97, 0.23), Vector2(0.0, 0.23)])
	KIT.add(root, KIT.lathe(vessel, 64), stone, Vector3.ZERO)
	KIT.add(root, KIT.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.93, 0.0), Vector2(0.93, 0.06), Vector2(0.0, 0.06)]), 48), KIT.metal(), Vector3.ZERO)
	KIT.add(root, KIT.lathe(PackedVector2Array([Vector2(1.027, 0.17), Vector2(1.045, 0.17), Vector2(1.054, 0.194), Vector2(1.036, 0.194)]), 64), KIT.brass(), Vector3.ZERO)
	KIT.add(root, KIT.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.16, 0.0), Vector2(1.16, 0.035), Vector2(0.0, 0.035)]), 48), KIT.stone(Color(0.20, 0.17, 0.13), 0.98, "sakura_mulch"), Vector3(0.0, 0.76, 0.0))
	var bark: StandardMaterial3D = KIT.wood(Color(0.29, 0.20, 0.17), "sakura_bark")
	KIT.add(root, _tree_mesh(), bark, Vector3.ZERO)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8713 + style * 419
	# Offset, overlapping ellipsoids make a wide, tiered crown rather than a ball.
	var centers: Array[Vector3] = [Vector3(-1.12, 2.76, 0.06), Vector3(-0.70, 3.18, -0.48), Vector3(0.13, 3.46, -0.16), Vector3(0.96, 3.20, -0.28), Vector3(1.35, 2.84, 0.33), Vector3(0.46, 3.00, 0.68), Vector3(-0.55, 2.77, 0.67), Vector3(0.05, 3.71, -0.05)]
	var blossoms: MultiMesh = MultiMesh.new()
	blossoms.transform_format = MultiMesh.TRANSFORM_3D
	blossoms.use_colors = true
	blossoms.mesh = _flower_mesh()
	blossoms.instance_count = centers.size() * 210
	var pinks: Array[Color] = [Color(1.0, 0.70, 0.78), Color(1.0, 0.82, 0.85), Color(0.95, 0.60, 0.72), Color(1.0, 0.88, 0.87)]
	for i in blossoms.instance_count:
		var center: Vector3 = centers[i / 210]
		var direction: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		var spread: float = pow(rng.randf(), 0.33333)
		var point: Vector3 = center + direction * Vector3(0.66, 0.39, 0.59) * spread
		var basis: Basis = Basis.from_euler(Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI)))
		basis = basis.scaled(Vector3.ONE * rng.randf_range(0.72, 1.25))
		blossoms.set_instance_transform(i, Transform3D(basis, point))
		var tint: Color = pinks[style].lerp(Color(1.0, 0.95, 0.91), rng.randf_range(0.0, 0.60))
		blossoms.set_instance_color(i, tint)
	_add_instances(root, blossoms, "BlossomClouds", true)
	var petals: MultiMesh = MultiMesh.new()
	petals.transform_format = MultiMesh.TRANSFORM_3D
	petals.use_colors = true
	petals.mesh = _petal_mesh()
	petals.instance_count = 160
	for i in petals.instance_count:
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(1.40, 2.25) if i < 115 else rng.randf_range(0.40, 1.12)
		var height: float = 0.012 if i < 115 else 0.805
		var point: Vector3 = Vector3(cos(angle) * radius, height, sin(angle) * radius)
		var basis: Basis = Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.65, 1.3))
		petals.set_instance_transform(i, Transform3D(basis, point))
		petals.set_instance_color(i, pinks[style].lightened(rng.randf_range(0.0, 0.25)))
	_add_instances(root, petals, "FallenPetals", false)
	# Broad walnut botanical tablet, mounted across the front of the curved vessel.
	KIT.rbox(root, Vector3(2.34, 0.74, 0.085), Vector3(0.0, 0.49, 1.30), KIT.wood(KIT.WALNUT, "sakura_tablet"), 0.065)
	KIT.rbox(root, Vector3(2.13, 0.014, 0.016), Vector3(0.0, 0.82, 1.348), KIT.brass(), 0.005, false)
	var inscription: Label3D = Label3D.new()
	inscription.text = "Cherry blossom\n桜 · 樱花 · Hoa anh đào\nCerisier · Cerezo"
	inscription.font = SIGNS.font()
	inscription.font_size = 64
	inscription.pixel_size = 0.003
	inscription.modulate = KIT.CREAM
	inscription.outline_size = 0
	inscription.position = Vector3(0.0, 0.48, 1.35)
	inscription.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(inscription)
	return root


static func _add_instances(parent: Node3D, multimesh: MultiMesh, title: String, shadows: bool) -> void:
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = multimesh
	var bounds: AABB = multimesh.get_instance_transform(0) * multimesh.mesh.get_aabb()
	for i in range(1, multimesh.instance_count):
		bounds = bounds.merge(multimesh.get_instance_transform(i) * multimesh.mesh.get_aabb())
	multimesh.custom_aabb = bounds
	node.material_override = _petal_material()
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _petal_material() -> StandardMaterial3D:
	if _materials.has("petals"):
		return _materials["petals"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.88
	material.backlight_enabled = true
	material.backlight = Color(0.34, 0.23, 0.23)
	_materials["petals"] = material
	return material


static func _tree_mesh() -> ArrayMesh:
	if _meshes.has("tree"):
		return _meshes["tree"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, PackedVector3Array([Vector3(-0.12, 0.77, 0.0), Vector3(-0.24, 1.09, 0.02), Vector3(-0.12, 1.43, 0.06), Vector3(0.15, 1.80, 0.01), Vector3(0.07, 2.17, -0.10), Vector3(0.22, 2.67, -0.17), Vector3(0.06, 3.55, -0.05)]), PackedFloat32Array([0.29, 0.25, 0.20, 0.17, 0.135, 0.075, 0.012]))
	var tips: Array[Vector3] = [Vector3(-1.37, 2.75, 0.12), Vector3(-0.85, 3.15, -0.58), Vector3(1.06, 3.20, -0.40), Vector3(1.43, 2.83, 0.35), Vector3(0.50, 3.12, 0.82), Vector3(-0.66, 2.83, 0.74)]
	for i in tips.size():
		var tip: Vector3 = tips[i]
		var start: Vector3 = Vector3(0.11, 1.82 + float(i % 3) * 0.19, -0.03)
		var elbow: Vector3 = start.lerp(tip, 0.56) - Vector3(0.0, 0.20, 0.0)
		_tube(st, PackedVector3Array([start, elbow, tip]), PackedFloat32Array([0.125 - float(i % 3) * 0.017, 0.067, 0.012]))
		for j in 3:
			var twig_start: Vector3 = elbow.lerp(tip, 0.3 + float(j) * 0.21)
			var twig_tip: Vector3 = twig_start + Vector3(0.18 * sin(float(i + j) * 2.7), 0.38, 0.26 * cos(float(i + j)))
			_tube(st, PackedVector3Array([twig_start, twig_tip]), PackedFloat32Array([0.025, 0.004]))
	for i in 7:
		var angle: float = float(i) * TAU / 7.0
		_tube(st, PackedVector3Array([Vector3(-0.12, 0.95, 0.0), Vector3(cos(angle) * 0.39 - 0.10, 0.82, sin(angle) * 0.39), Vector3(cos(angle) * 0.72 - 0.10, 0.797, sin(angle) * 0.72)]), PackedFloat32Array([0.12, 0.065, 0.009]))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["tree"] = mesh
	return mesh


static func _tube(st: SurfaceTool, points: PackedVector3Array, radii: PackedFloat32Array) -> void:
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var tangent: Vector3 = points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]
		tangent = tangent.normalized()
		var reference: Vector3 = Vector3.RIGHT if absf(tangent.dot(Vector3.UP)) > 0.92 else Vector3.UP
		var side: Vector3 = tangent.cross(reference).normalized()
		var across: Vector3 = tangent.cross(side).normalized()
		var ring: PackedVector3Array = PackedVector3Array()
		for j in 12:
			var angle: float = TAU * float(j) / 12.0
			var radius: float = radii[i] * (1.0 + 0.10 * sin(angle * 5.0 + float(i) * 0.8))
			ring.append(points[i] + (side * cos(angle) + across * sin(angle)) * radius)
		rings.append(ring)
	for i in points.size() - 1:
		var lower: PackedVector3Array = rings[i]
		var upper: PackedVector3Array = rings[i + 1]
		for j in 12:
			var next: int = (j + 1) % 12
			for vertex: Vector3 in [lower[j], upper[j], lower[next], lower[next], upper[j], upper[next]]:
				st.add_vertex(vertex)


static func _flower_mesh() -> ArrayMesh:
	if _meshes.has("flower"):
		return _meshes["flower"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var angle: float = float(i) * TAU / 5.0
		var axis: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var side: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
		var outline: PackedVector3Array = PackedVector3Array([axis * 0.017, axis * 0.056 - side * 0.028 + Vector3.UP * 0.012, axis * 0.094 - side * 0.017 + Vector3.UP * 0.023, axis * 0.082 + Vector3.UP * 0.020, axis * 0.094 + side * 0.017 + Vector3.UP * 0.023, axis * 0.056 + side * 0.028 + Vector3.UP * 0.012])
		var center: Vector3 = axis * 0.052 + Vector3.UP * 0.007
		for j in outline.size():
			st.set_color(Color(1.0, 0.91, 0.84))
			st.add_vertex(center)
			st.set_color(Color.WHITE)
			st.add_vertex(outline[(j + 1) % outline.size()])
			st.add_vertex(outline[j])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["flower"] = mesh
	return mesh


static func _petal_mesh() -> ArrayMesh:
	if _meshes.has("petal"):
		return _meshes["petal"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline: PackedVector3Array = PackedVector3Array([Vector3(0.0, 0.0, -0.025), Vector3(-0.016, 0.003, 0.0), Vector3(-0.010, 0.002, 0.023), Vector3(0.0, 0.001, 0.017), Vector3(0.010, 0.002, 0.023), Vector3(0.016, 0.003, 0.0)])
	for i in outline.size():
		st.add_vertex(Vector3(0.0, 0.004, 0.0))
		st.add_vertex(outline[(i + 1) % outline.size()])
		st.add_vertex(outline[i])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["petal"] = mesh
	return mesh
