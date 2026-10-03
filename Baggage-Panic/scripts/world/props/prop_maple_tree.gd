extends RefCounted
## A sculptural Acer palmatum: open branches and overlapping, five-lobed autumn leaves.
## No specimen labels: the quiet planter is part of the terminal landscape.

const Kit = preload("res://scripts/world/design_kit.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "JapaneseMaple"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var finishes: Array[Color] = [Kit.LIMESTONE, Kit.CLAY.lightened(0.2), Kit.PLASTER, Kit.SAGE.lightened(0.25)]
	var finish: Color = finishes[choice]
	var stone: StandardMaterial3D = Kit.stone(finish, 0.78, "maple_planter_%d" % choice)
	# Recessed foot, softly rolled lip, and a genuine hollow inner wall.
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.43, 0.0), Vector2(0.46, 0.025),
		Vector2(0.46, 0.075), Vector2(0.43, 0.09), Vector2(0.0, 0.09)
	]), 48), Kit.metal(), Vector3.ZERO)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.07), Vector2(0.46, 0.07), Vector2(0.49, 0.095),
		Vector2(0.52, 0.14), Vector2(0.59, 0.5), Vector2(0.61, 0.6),
		Vector2(0.608, 0.635), Vector2(0.59, 0.65), Vector2(0.566, 0.65),
		Vector2(0.551, 0.633), Vector2(0.548, 0.59), Vector2(0.49, 0.16),
		Vector2(0.0, 0.16)
	]), 64), stone, Vector3.ZERO)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.521, 0.17), Vector2(0.529, 0.18), Vector2(0.532, 0.195),
		Vector2(0.527, 0.203), Vector2(0.521, 0.17)
	]), 64), Kit.brass(), Vector3.ZERO, Vector3.ZERO, false)
	Kit.add(root, Kit.lathe(PackedVector2Array([
		Vector2(0.0, 0.585), Vector2(0.545, 0.585), Vector2(0.0, 0.585)
	]), 48), Kit.stone(Color(0.23, 0.19, 0.14), 0.97, "maple_mulch"), Vector3.ZERO)
	var tree: Node3D = Node3D.new()
	tree.name = "TrunkAndCanopy"
	tree.rotation_degrees.y = float(choice) * 21.0
	root.add_child(tree)
	Kit.add(tree, _branch_mesh(), Kit.wood(Color(0.34, 0.29, 0.24), "maple_bark"), Vector3.ZERO)
	var clusters: Array[Vector3] = [
		Vector3(-0.79, 1.93, 0.15), Vector3(0.73, 2.08, 0.35),
		Vector3(-0.5, 2.32, -0.55), Vector3(0.66, 2.43, -0.42),
		Vector3(-0.24, 2.59, 0.35), Vector3(0.27, 2.82, -0.06),
		Vector3(-0.93, 2.34, 0.02), Vector3(0.95, 2.3, 0.12),
		Vector3(0.06, 2.25, 0.76)
	]
	var foliage: Array[Color] = [Color(0.67, 0.16, 0.08), Color(0.77, 0.27, 0.07), Color(0.53, 0.09, 0.08), Color(0.72, 0.2, 0.12)]
	for i in clusters.size():
		var cluster: MeshInstance3D = Kit.add(tree, _leaf_cluster(i % 3), _leaf_material(foliage[choice], choice), clusters[i])
		cluster.rotation_degrees.y = float(i * 47 + choice * 13)
		var spread: float = 0.8 if i == 5 else 1.0
		cluster.scale = Vector3(spread, 0.85 if i % 2 == 0 else 1.0, spread)
	# River pebbles are instanced in one node, with space around the visible root flare.
	var pebbles: MultiMesh = MultiMesh.new()
	pebbles.transform_format = MultiMesh.TRANSFORM_3D
	pebbles.mesh = Kit.lathe(PackedVector2Array([
		Vector2(0.0, -0.015), Vector2(0.02, -0.012), Vector2(0.036, 0.0),
		Vector2(0.029, 0.017), Vector2(0.012, 0.025), Vector2(0.0, 0.026)
	]), 10)
	pebbles.instance_count = 38
	for i in pebbles.instance_count:
		var angle: float = float(i) * 2.39996
		var radius: float = 0.19 + 0.32 * sqrt(float(i) / 38.0)
		var basis: Basis = Basis(Vector3.UP, angle).scaled(Vector3(1.2, 0.8, 0.85))
		pebbles.set_instance_transform(i, Transform3D(basis, Vector3(cos(angle) * radius, 0.6, sin(angle) * radius)))
	var gravel: MultiMeshInstance3D = MultiMeshInstance3D.new()
	gravel.name = "RiverPebbles"
	gravel.multimesh = pebbles
	gravel.material_override = Kit.stone(Kit.LIMESTONE.darkened(0.19), 0.86, "maple_pebbles")
	gravel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gravel)
	return root


static func _leaf_material(tint: Color, choice: int) -> StandardMaterial3D:
	var key: String = "leaves_%d" % choice
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = Kit.paint(tint, 0.82).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.backlight_enabled = true
	material.backlight = Color(0.3, 0.12, 0.035)
	_materials[key] = material
	return material


static func _branch_mesh() -> ArrayMesh:
	if _meshes.has("branches"):
		return _meshes["branches"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, PackedVector3Array([Vector3(-0.08, 0.57, 0.0), Vector3(-0.04, 0.92, 0.02), Vector3(0.08, 1.3, 0.0), Vector3(-0.03, 1.66, -0.04), Vector3(0.13, 2.12, -0.08), Vector3(0.26, 2.77, -0.06)]), 0.092, 0.013)
	_tube(st, PackedVector3Array([Vector3(0.04, 1.28, 0.0), Vector3(-0.23, 1.57, 0.06), Vector3(-0.62, 1.75, 0.11), Vector3(-1.01, 1.92, 0.15)]), 0.048, 0.009)
	_tube(st, PackedVector3Array([Vector3(-0.02, 1.58, -0.03), Vector3(0.3, 1.77, 0.1), Vector3(0.69, 1.95, 0.28), Vector3(1.02, 2.13, 0.27)]), 0.043, 0.008)
	_tube(st, PackedVector3Array([Vector3(0.07, 1.94, -0.07), Vector3(-0.2, 2.09, -0.29), Vector3(-0.51, 2.25, -0.55)]), 0.033, 0.007)
	_tube(st, PackedVector3Array([Vector3(0.11, 2.08, -0.08), Vector3(0.37, 2.25, -0.29), Vector3(0.76, 2.43, -0.43)]), 0.031, 0.006)
	_tube(st, PackedVector3Array([Vector3(0.13, 2.19, -0.08), Vector3(-0.19, 2.37, 0.2), Vector3(-0.43, 2.52, 0.4)]), 0.025, 0.006)
	_tube(st, PackedVector3Array([Vector3(0.24, 1.77, 0.08), Vector3(0.14, 1.95, 0.43), Vector3(0.06, 2.22, 0.79)]), 0.025, 0.005)
	for i in 5:
		var angle: float = TAU * float(i) / 5.0
		_tube(st, PackedVector3Array([Vector3(-0.05, 0.73, 0.0), Vector3(cos(angle) * 0.14 - 0.05, 0.6, sin(angle) * 0.14), Vector3(cos(angle) * 0.25 - 0.05, 0.586, sin(angle) * 0.25)]), 0.045, 0.008)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["branches"] = mesh
	return mesh


static func _tube(st: SurfaceTool, points: PackedVector3Array, start_radius: float, end_radius: float) -> void:
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var tangent: Vector3 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var u: Vector3 = tangent.cross(Vector3.FORWARD).normalized()
		var v: Vector3 = tangent.cross(u).normalized()
		var radius: float = lerpf(start_radius, end_radius, float(i) / float(points.size() - 1))
		var ring: PackedVector3Array = PackedVector3Array()
		for j in 10:
			var angle: float = TAU * float(j) / 10.0
			ring.append(points[i] + (u * cos(angle) + v * sin(angle)) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		for j in 10:
			var next: int = (j + 1) % 10
			for vertex: Vector3 in [a[j], b[j], a[next], a[next], b[j], b[next]]:
				st.add_vertex(vertex)


static func _leaf_cluster(seed_index: int) -> ArrayMesh:
	var key: String = "cluster_%d" % seed_index
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4137 + seed_index * 919
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Deep cuts between five pointed lobes make the silhouette read as maple foliage.
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -0.37), Vector2(-0.25, -0.25), Vector2(-0.87, -0.05),
		Vector2(-0.35, 0.15), Vector2(-0.83, 0.64), Vector2(-0.24, 0.39),
		Vector2(0.0, 1.0), Vector2(0.24, 0.39), Vector2(0.83, 0.64),
		Vector2(0.35, 0.15), Vector2(0.87, -0.05), Vector2(0.25, -0.25)
	])
	for i in 220:
		var azimuth: float = rng.randf_range(0.0, TAU)
		var radius: float = sqrt(rng.randf())
		var position: Vector3 = Vector3(cos(azimuth) * radius * 0.59, rng.randf_range(-0.15, 0.16) + (1.0 - radius) * 0.09, sin(azimuth) * radius * 0.46)
		var orientation: Basis = Basis.from_euler(Vector3(rng.randf_range(-0.65, 0.65), rng.randf_range(0.0, TAU), rng.randf_range(-0.55, 0.55)))
		var size: float = rng.randf_range(0.07, 0.115)
		var shade: float = rng.randf_range(0.72, 1.22)
		st.set_color(Color(shade, shade * rng.randf_range(0.86, 1.12), shade * 0.88))
		for j in outline.size():
			var a: Vector2 = outline[j]
			var b: Vector2 = outline[(j + 1) % outline.size()]
			st.add_vertex(position + orientation * Vector3(0.0, 0.013, 0.0))
			st.add_vertex(position + orientation * Vector3(a.x * size, -a.length() * 0.012, a.y * size))
			st.add_vertex(position + orientation * Vector3(b.x * size, -b.length() * 0.012, b.y * size))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
