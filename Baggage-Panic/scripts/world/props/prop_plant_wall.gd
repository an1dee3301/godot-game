extends RefCounted
## Floor-standing living wall, facing +Z. All foliage is opaque, batched geometry.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PlantWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = Kit.wood(Kit.OAK, "oak")
	var steel: StandardMaterial3D = Kit.metal()
	var stone_tint: Color = Kit.LIMESTONE
	if style == 1:
		stone_tint = Kit.PLASTER
	elif style == 2:
		stone_tint = Kit.CLAY.lightened(0.27)
	elif style == 3:
		stone_tint = Kit.SAGE.lightened(0.32)
	var stone: StandardMaterial3D = Kit.stone(stone_tint, 0.78, "plant_wall_trough_%d" % style)
	# A recessed steel kick and honed-stone trough give a believable floor contact.
	Kit.rbox(root, Vector3(3.76, 0.08, 0.56), Vector3(0.0, 0.04, 0.03), steel, 0.025)
	Kit.rbox(root, Vector3(4.0, 0.25, 0.68), Vector3(0.0, 0.205, 0.05), stone, 0.075)
	Kit.rbox(root, Vector3(3.64, 0.055, 0.47), Vector3(0.0, 0.337, 0.08), Kit.stone(Color(0.14, 0.20, 0.105), 0.98, "plant_wall_soil"), 0.025)
	# The growing cassette is recessed behind a deep oak picture frame.
	Kit.rbox(root, Vector3(3.69, 2.57, 0.15), Vector3(0.0, 1.595, -0.11), Kit.fabric(Color(0.12, 0.19, 0.12), "plant_wall_felt"), 0.055)
	for side: float in [-1.0, 1.0]:
		Kit.rbox(root, Vector3(0.16, 2.71, 0.34), Vector3(side * 1.92, 1.645, -0.02), oak, 0.045)
		Kit.rbox(root, Vector3(0.018, 2.43, 0.018), Vector3(side * 1.824, 1.555, 0.16), Kit.brass(), 0.006, false)
		# Dark walnut splines celebrate the frame's corner joinery.
		for height: float in [0.47, 2.91]:
			Kit.rbox(root, Vector3(0.10, 0.014, 0.018), Vector3(side * 1.92, height, 0.155), Kit.wood(Kit.WALNUT, "walnut"), 0.004, false)
	Kit.rbox(root, Vector3(3.72, 0.16, 0.34), Vector3(0.0, 2.92, -0.02), oak, 0.04)
	Kit.rbox(root, Vector3(3.72, 0.10, 0.34), Vector3(0.0, 0.38, -0.02), oak, 0.03)
	# A flush oak welcome band uses the airport's shared international lettering.
	Kit.rbox(root, Vector3(3.68, 0.52, 0.08), Vector3(0.0, 2.585, 0.045), oak, 0.035)
	var welcome: Array = Signs.TEXT["welcome"]
	_caption(root, "%s · %s · %s" % [welcome[0], welcome[1], welcome[2]], 2.715, 78)
	_caption(root, "%s · %s · %s" % [welcome[3], welcome[4], welcome[5]], 2.465, 70)
	Kit.rbox(root, Vector3(3.50, 0.018, 0.028), Vector3(0.0, 2.30, 0.107), steel, 0.006, false)
	Kit.rbox(root, Vector3(3.43, 0.012, 0.014), Vector3(0.0, 2.293, 0.126), Kit.washi(Kit.CREAM, 0.65, "plant_wall_warm_strip"), 0.004, false)
	_populate(root, style)
	return root


static func _caption(parent: Node3D, text: String, height: float, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = 0.0028
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(0.0, height, 0.09)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _populate(parent: Node3D, style: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 81347 + style * 711
	var broad: MultiMesh = _batch(parent, "LayeredRosettes", _leaf_mesh(false), 840)
	var fine: MultiMesh = _batch(parent, "FernFronds", _leaf_mesh(true), 576)
	var moss: MultiMesh = _batch(parent, "MossCushions", _moss_mesh(), 260)
	var greens: Array[Color] = [Color(0.24, 0.39, 0.17), Color(0.37, 0.49, 0.22), Color(0.15, 0.31, 0.20), Color(0.44, 0.55, 0.31), Color(0.20, 0.37, 0.26), Color(0.32, 0.44, 0.25), Color(0.51, 0.58, 0.35)]
	# Staggered depth layers of six-leaf rosettes stay inside the oak border.
	var index: int = 0
	for row in 10:
		for column in 14:
			var center: Vector3 = Vector3(-1.64 + float(column) * 0.25 + rng.randf_range(-0.045, 0.045), 0.57 + float(row) * 0.169 + rng.randf_range(-0.035, 0.035), 0.065 + rng.randf_range(0.0, 0.08))
			center.z += float(posmod(column + row + style, 2)) * 0.065
			var patch: int = posmod(floori(float(column) / 3.0) + floori(float(row) / 3.0) + style, greens.size())
			for petal in 6:
				var angle: float = float(petal) * TAU / 6.0 + rng.randf_range(-0.30, 0.30)
				var length: float = rng.randf_range(0.20, 0.33)
				var basis: Basis = Basis.from_euler(Vector3(rng.randf_range(-0.23, 0.18), rng.randf_range(-0.30, 0.30), angle))
				basis = basis.scaled(Vector3(length * rng.randf_range(0.80, 1.16), length, length))
				broad.set_instance_transform(index, Transform3D(basis, center + Vector3(0.0, 0.0, float(petal % 2) * 0.055)))
				var tint: Color = greens[patch]
				broad.set_instance_color(index, tint.lightened(rng.randf_range(0.0, 0.12)))
				index += 1
	# Ferns form long feathered sprays in draping islands over the broad-leaf layer.
	index = 0
	for frond in 36:
		var start: Vector3 = Vector3(rng.randf_range(-1.35, 1.35), rng.randf_range(1.03, 2.03), 0.23)
		var sweep: float = rng.randf_range(-0.65, 0.65)
		for pair in 8:
			var t: float = float(pair) / 7.0
			var spine: Vector3 = start + Vector3(sweep * t, -0.52 * t, 0.10 * sin(t * PI))
			for side: float in [-1.0, 1.0]:
				var length: float = lerpf(0.22, 0.085, t)
				var basis: Basis = Basis.from_euler(Vector3(-0.15, side * 0.12, side * 1.13 + sweep * 0.4))
				fine.set_instance_transform(index, Transform3D(basis.scaled(Vector3(length, length, length)), spine))
				var tint: Color = greens[posmod(frond + style + 2, greens.size())]
				fine.set_instance_color(index, tint.lightened(0.10))
				index += 1
	# Rounded, uneven moss pillows hide cassette seams and soften the trough lip.
	for tuft in 260:
		var along_base: bool = tuft < 170
		var position: Vector3 = Vector3(rng.randf_range(-1.76, 1.76), rng.randf_range(0.37, 0.46), rng.randf_range(-0.09, 0.26))
		if not along_base:
			position = Vector3(rng.randf_range(-1.71, 1.71), rng.randf_range(0.52, 2.19), 0.075)
		var radius: float = rng.randf_range(0.055, 0.13)
		var scale: Vector3 = Vector3(radius * 1.5, radius * 0.65, radius)
		moss.set_instance_transform(tuft, Transform3D(Basis.IDENTITY.scaled(scale), position))
		var tint: Color = greens[posmod(tuft + style, greens.size())]
		moss.set_instance_color(tuft, tint.darkened(0.10))


static func _batch(parent: Node3D, title: String, mesh: Mesh, count: int) -> MultiMesh:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = count
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = batch
	node.material_override = _foliage_material()
	# Tiny fern blades and moss receive shadows without adding shadow draw calls.
	if title != "LayeredRosettes":
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return batch


static func _foliage_material() -> StandardMaterial3D:
	if _materials.has("foliage"):
		return _materials["foliage"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.78
	_materials["foliage"] = material
	return material


static func _leaf_mesh(narrow: bool) -> ArrayMesh:
	var key: String = "fern" if narrow else "broad"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# A cupped blade with a raised pale midrib, pointed tip, and darker edges.
	for segment in 8:
		var t0: float = float(segment) / 8.0
		var t1: float = float(segment + 1) / 8.0
		for band in 4:
			var u0: float = float(band) * 0.5 - 1.0
			var u1: float = float(band + 1) * 0.5 - 1.0
			var parameters: Array[Vector2] = [Vector2(u0, t0), Vector2(u0, t1), Vector2(u1, t1), Vector2(u0, t0), Vector2(u1, t1), Vector2(u1, t0)]
			for parameter: Vector2 in parameters:
				var u: float = parameter.x
				var t: float = parameter.y
				var width: float = pow(maxf(0.0, sin(PI * t)), 0.75) * (0.19 if narrow else 0.40)
				var ridge: float = (1.0 - absf(u)) * 0.075 * sin(PI * t)
				var curl: float = 0.16 * sin(PI * t) - 0.13 * t * t
				var lightness: float = 0.73 + (1.0 - absf(u)) * 0.27
				surface.set_color(Color(lightness, lightness, lightness, 1.0))
				surface.set_uv(Vector2((u + 1.0) * 0.5, t))
				surface.add_vertex(Vector3(u * width, t, curl + ridge))
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _moss_mesh() -> ArrayMesh:
	if _meshes.has("moss"):
		return _meshes["moss"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Low, irregular hummocks: small lobes and mottled vertex colours break up
	# the smooth sphere silhouette without textures or separate tuft nodes.
	for ring in 8:
		for sector in 12:
			var corners: Array[Vector2] = [
				Vector2(sector, ring), Vector2(sector, ring + 1), Vector2(sector + 1, ring + 1),
				Vector2(sector, ring), Vector2(sector + 1, ring + 1), Vector2(sector + 1, ring),
			]
			for corner: Vector2 in corners:
				var longitude: float = corner.x * TAU / 12.0
				var latitude: float = corner.y * PI / 8.0
				var normal: Vector3 = Vector3(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude))
				var lobes: float = sin(longitude * 5.0 + latitude * 3.0) * sin(latitude)
				var radius: float = 1.0 + 0.13 * lobes + 0.055 * sin(latitude * 7.0)
				var shade: float = 0.84 + lobes * 0.12
				surface.set_normal(normal)
				surface.set_color(Color(shade, shade, shade, 1.0))
				surface.add_vertex(normal * radius)
	var mesh: ArrayMesh = surface.commit()
	_meshes["moss"] = mesh
	return mesh
