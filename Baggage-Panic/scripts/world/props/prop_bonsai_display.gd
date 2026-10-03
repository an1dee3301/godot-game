extends RefCounted
## A small museum-like pine display: floor-contact walnut pedestal and a honed suiban.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BonsaiDisplay"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT.lightened(float(style) * 0.025), "bonsai_walnut_%d" % style)
	var stone_tint: Color = DesignKit.LIMESTONE.lerp(DesignKit.CLAY, float(style) * 0.035)
	var stone: StandardMaterial3D = DesignKit.stone(stone_tint, 0.76, "bonsai_tray_%d" % style)
	var shadow: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.72, 0.3, "bonsai_recess")
	# Inset toe, softened solid joinery, and an overhanging walnut cap.
	DesignKit.rbox(root, Vector3(0.73, 0.035, 0.49), Vector3(0.0, 0.0175, 0.0), shadow, 0.012)
	DesignKit.rbox(root, Vector3(0.86, 0.45, 0.62), Vector3(0.0, 0.26, 0.0), walnut, 0.045)
	DesignKit.rbox(root, Vector3(0.86, 0.014, 0.62), Vector3(0.0, 0.492, 0.0), shadow, 0.005)
	DesignKit.rbox(root, Vector3(0.91, 0.055, 0.67), Vector3(0.0, 0.5265, 0.0), walnut, 0.021)
	# A continuous turned bowl profile: bevelled underside, thick rounded lip, hollow interior.
	var tray: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.39, 0.0), Vector2(0.445, 0.018),
		Vector2(0.475, 0.045), Vector2(0.49, 0.088), Vector2(0.487, 0.101),
		Vector2(0.475, 0.108), Vector2(0.453, 0.108), Vector2(0.444, 0.096),
		Vector2(0.431, 0.049), Vector2(0.39, 0.034), Vector2(0.0, 0.034)
	]), 48), stone, Vector3(0.0, 0.555, 0.0))
	tray.scale.z = 0.72
	var bed: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.422, 0.0), Vector2(0.422, 0.012), Vector2(0.0, 0.012)
	]), 40), DesignKit.stone(DesignKit.LINEN, 0.94, "bonsai_gravel_bed"), Vector3(0.0, 0.598, 0.0))
	bed.scale.z = 0.72
	_scatter_gravel(root, style)
	var tree: MeshInstance3D = DesignKit.add(root, _bark_mesh(), DesignKit.wood(Color(0.29, 0.235, 0.17), "bonsai_bark"), Vector3.ZERO)
	tree.rotation_degrees.y = float(style - 1) * 8.0
	var needles: MeshInstance3D = DesignKit.add(root, _canopy_mesh(style), _foliage_material(), Vector3.ZERO)
	needles.rotation_degrees.y = tree.rotation_degrees.y
	var moss: MeshInstance3D = DesignKit.add(root, _moss_mesh(style), DesignKit.stone(Color(0.32, 0.40, 0.19), 0.98, "bonsai_moss"), Vector3.ZERO)
	moss.rotation_degrees.y = tree.rotation_degrees.y
	# Small plaque, with one generous bilingual engraving rather than miniature captions.
	DesignKit.rbox(root, Vector3(0.64, 0.18, 0.014), Vector3(0.0, 0.32, 0.317), DesignKit.brass(), 0.017)
	for x: float in [-0.29, 0.29]:
		var pin: MeshInstance3D = DesignKit.add(root, _pebble_mesh(), shadow, Vector3(x, 0.32, 0.327))
		pin.scale = Vector3(0.004, 0.004, 0.0015)
	var label: Label3D = Label3D.new()
	label.name = "PineEngraving"
	label.text = "PINE 松"
	label.font = Signage.font()
	label.font_size = 64
	label.pixel_size = 0.002
	label.position = Vector3(0.0, 0.32, 0.326)
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)
	return root


static func _pebble_mesh() -> SphereMesh:
	if _meshes.has("pebble"):
		return _meshes["pebble"] as SphereMesh
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_meshes["pebble"] = mesh
	return mesh


static func _scatter_gravel(parent: Node3D, style: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 481 + style * 17
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = _pebble_mesh()
	instances.instance_count = 145
	for i: int in instances.instance_count:
		var angle: float = rng.randf() * TAU
		var radius: float = sqrt(rng.randf()) * 0.408
		var size: float = rng.randf_range(0.009, 0.016)
		var basis: Basis = Basis.from_euler(Vector3(rng.randf(), angle, rng.randf())).scaled(Vector3(size, size * 0.62, size * 0.82))
		instances.set_instance_transform(i, Transform3D(basis, Vector3(cos(angle) * radius, 0.615, sin(angle) * radius * 0.70)))
		instances.set_instance_color(i, Color.WHITE.darkened(rng.randf_range(0.0, 0.19)))
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = "LooseGravel"
	node.multimesh = instances
	if not _materials.has("gravel"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = DesignKit.LINEN
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.95
		_materials["gravel"] = material
	node.material_override = _materials["gravel"] as Material
	parent.add_child(node)


static func _bark_mesh() -> ArrayMesh:
	if _meshes.has("bark"):
		return _meshes["bark"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, PackedVector3Array([
		Vector3(-0.105, 0.618, 0.0), Vector3(-0.115, 0.72, 0.0),
		Vector3(-0.04, 0.84, -0.025), Vector3(0.045, 0.93, 0.005),
		Vector3(0.028, 1.055, 0.014), Vector3(0.10, 1.17, -0.015), Vector3(0.075, 1.32, 0.0)
	]), PackedFloat32Array([0.064, 0.049, 0.037, 0.029, 0.021, 0.015, 0.006]))
	# Visible radial roots and downward-set branches form the pine's trained silhouette.
	for i: int in 5:
		var a: float = TAU * float(i) / 5.0
		_tube(st, PackedVector3Array([Vector3(-0.105, 0.68, 0.0), Vector3(-0.105 + cos(a) * 0.065, 0.625, sin(a) * 0.055), Vector3(-0.105 + cos(a) * 0.14, 0.616, sin(a) * 0.11)]), PackedFloat32Array([0.019, 0.019, 0.002]))
	var starts: PackedVector3Array = PackedVector3Array([
		Vector3(-0.04, 0.84, -0.025), Vector3(0.04, 0.93, 0.005), Vector3(0.028, 1.05, 0.014),
		Vector3(0.04, 1.07, 0.0), Vector3(0.09, 1.16, -0.01), Vector3(0.075, 1.29, 0.0)
	])
	var ends: PackedVector3Array = PackedVector3Array([
		Vector3(-0.34, 0.92, 0.03), Vector3(0.33, 1.01, 0.04), Vector3(-0.24, 1.145, -0.02),
		Vector3(0.10, 1.12, -0.19), Vector3(0.27, 1.23, 0.015), Vector3(0.055, 1.32, 0.025)
	])
	for i: int in starts.size():
		var start: Vector3 = starts[i]
		var end: Vector3 = ends[i]
		var elbow: Vector3 = start.lerp(end, 0.58) - Vector3(0.0, 0.035, 0.0)
		_tube(st, PackedVector3Array([start, elbow, end]), PackedFloat32Array([0.019 - float(i) * 0.002, 0.01, 0.003]))
		_tube(st, PackedVector3Array([elbow, end + Vector3(0.03, 0.0, 0.075)]), PackedFloat32Array([0.008, 0.002]))
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["bark"] = mesh
	return mesh


static func _tube(st: SurfaceTool, points: PackedVector3Array, radii: PackedFloat32Array) -> void:
	for j: int in points.size() - 1:
		var direction: Vector3 = (points[j + 1] - points[j]).normalized()
		var side: Vector3 = direction.cross(Vector3.FORWARD).normalized()
		var other: Vector3 = direction.cross(side).normalized()
		for k: int in 12:
			var a: float = TAU * float(k) / 12.0
			var b: float = TAU * float(k + 1) / 12.0
			var ra: Vector3 = side * cos(a) + other * sin(a)
			var rb: Vector3 = side * cos(b) + other * sin(b)
			var p: Vector3 = points[j] + ra * radii[j] * (1.0 + 0.08 * sin(a * 5.0))
			var q: Vector3 = points[j] + rb * radii[j] * (1.0 + 0.08 * sin(b * 5.0))
			var r: Vector3 = points[j + 1] + ra * radii[j + 1]
			var s: Vector3 = points[j + 1] + rb * radii[j + 1]
			for vertex: Vector3 in [p, r, q, q, r, s]:
				st.set_uv(Vector2(float(k) / 12.0, vertex.y * 3.0))
				st.add_vertex(vertex)


static func _foliage_material() -> StandardMaterial3D:
	if not _materials.has("needles"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.94
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["needles"] = material
	return _materials["needles"] as StandardMaterial3D


static func _canopy_mesh(style: int) -> ArrayMesh:
	var key: String = "canopy_%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 992 + style * 21
	var tint: Color = Color(0.19, 0.29, 0.17).lerp(Color(0.29, 0.36, 0.23), float(style) / 4.0)
	var centers: PackedVector3Array = PackedVector3Array([
		Vector3(-0.32, 0.94, 0.035), Vector3(0.32, 1.035, 0.035),
		Vector3(-0.22, 1.16, -0.015), Vector3(0.10, 1.15, -0.18),
		Vector3(0.26, 1.25, 0.015), Vector3(0.055, 1.335, 0.025)
	])
	for i: int in centers.size():
		var center: Vector3 = centers[i]
		var width: float = 0.17 - float(i) * 0.009
		for lobe: int in 5:
			var angle: float = float(lobe) * TAU / 5.0
			var at: Vector3 = center + Vector3(cos(angle) * width * 0.42, rng.randf_range(-0.01, 0.01), sin(angle) * width * 0.35)
			var size: Vector3 = Vector3(width * 0.68, 0.039, width * 0.53)
			_ellipsoid(st, at, size, tint.lightened(rng.randf_range(0.0, 0.09)))
			# Stiff needle fans grow from each pad; real geometry keeps the silhouette crisp.
			for spray: int in 70:
				var a: float = rng.randf() * TAU
				var h: float = rng.randf_range(-0.6, 1.0)
				var normal: Vector3 = Vector3(cos(a) * sqrt(1.0 - h * h), h, sin(a) * sqrt(1.0 - h * h))
				var base: Vector3 = at + normal * size
				var length: float = rng.randf_range(0.016, 0.032)
				for blade: int in 3:
					var direction: Vector3 = (normal + Vector3(float(blade - 1) * 0.4, 0.4, 0.1)).normalized()
					var side: Vector3 = direction.cross(Vector3.UP).normalized() * 0.0025
					st.set_color(tint.lightened(rng.randf_range(0.0, 0.17)))
					st.set_normal(normal)
					st.add_vertex(base - side)
					st.add_vertex(base + direction * length)
					st.add_vertex(base + side)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _ellipsoid(st: SurfaceTool, at: Vector3, size: Vector3, color: Color) -> void:
	var faces: PackedVector3Array = _pebble_mesh().get_faces()
	for vertex: Vector3 in faces:
		st.set_color(color)
		st.set_normal((vertex / size).normalized())
		st.add_vertex(at + vertex * size)


static func _moss_mesh(style: int) -> ArrayMesh:
	var key: String = "moss_%d" % style
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31 + style
	for i: int in 18:
		var angle: float = rng.randf() * TAU
		var radius: float = rng.randf_range(0.025, 0.115)
		var at: Vector3 = Vector3(-0.105 + cos(angle) * radius, 0.618, sin(angle) * radius * 0.8)
		_ellipsoid(st, at, Vector3(rng.randf_range(0.035, 0.065), rng.randf_range(0.013, 0.026), rng.randf_range(0.03, 0.06)), Color.WHITE)
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh
