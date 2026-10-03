extends RefCounted
## A quiet living screen: carved limestone, pebble mulch and jointed bamboo.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BambooGrove"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var stones: Array[Color] = [DesignKit.LIMESTONE, DesignKit.PLASTER, Color(0.70, 0.72, 0.65), Color(0.77, 0.69, 0.59)]
	var greens: Array[Color] = [Color(0.38, 0.49, 0.24), Color(0.49, 0.55, 0.29), Color(0.31, 0.45, 0.30), Color(0.47, 0.49, 0.24)]
	var stone: StandardMaterial3D = DesignKit.stone(stones[style], 0.73, "bamboo_trough_%d" % style)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "bamboo_walnut")
	var culm_material: StandardMaterial3D = DesignKit.wood(greens[style].lightened(0.13), "bamboo_culm_%d" % style)
	var collar_material: StandardMaterial3D = DesignKit.paint(greens[style].darkened(0.18), 0.78)
	var leaf_material: StandardMaterial3D = _leaf_material(style, greens[style])
	# Recessed plinth creates a shadow reveal; all geometry sits above the floor.
	DesignKit.rbox(root, Vector3(2.76, 0.11, 0.98), Vector3(0.0, 0.055, 0.0), DesignKit.metal(), 0.045)
	DesignKit.rbox(root, Vector3(2.88, 0.075, 1.08), Vector3(0.0, 0.12, 0.0), walnut, 0.035)
	DesignKit.rbox(root, Vector3(3.0, 0.14, 1.2), Vector3(0.0, 0.21, 0.0), stone, 0.065)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(3.0, 0.41, 0.16), Vector3(0.0, 0.445, side * 0.52), stone, 0.065)
		DesignKit.rbox(root, Vector3(0.16, 0.41, 0.98), Vector3(side * 1.42, 0.445, 0.0), stone, 0.065)
		# Slightly proud, softly rolled coping around the open planting well.
		DesignKit.rbox(root, Vector3(3.0, 0.085, 0.19), Vector3(0.0, 0.65, side * 0.505), stone, 0.041)
		DesignKit.rbox(root, Vector3(0.19, 0.085, 0.86), Vector3(side * 1.405, 0.65, 0.0), stone, 0.041)
	DesignKit.rbox(root, Vector3(2.68, 0.055, 0.87), Vector3(0.0, 0.576, 0.0), DesignKit.stone(Color(0.31, 0.30, 0.25), 0.95, "bamboo_mulch"), 0.025)
	# Low-relief planting inscription; CJK uses the shared international font.
	var caption: Label3D = Label3D.new()
	caption.text = "竹 · BAMBOO"
	caption.font = Signage.font()
	caption.font_size = 80
	caption.pixel_size = 0.003
	caption.modulate = DesignKit.CHARCOAL
	caption.outline_size = 0
	caption.position = Vector3(0.0, 0.43, 0.604)
	caption.double_sided = false
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(caption)
	var count: int = 10 + style % 3
	for i: int in count:
		var column: int = i / 2
		var row: int = i % 2
		var columns: int = (count + 1) / 2
		var x: float = -1.12 + float(column) * 2.24 / float(columns - 1)
		var z: float = -0.23 + float(row) * 0.43 + sin(float(i) * 2.7 + float(style)) * 0.05
		var height: float = 2.55 + float((i * 3 + style * 2) % 7) * 0.14
		var radius: float = 0.028 + float(i % 3) * 0.004
		var lean: Vector3 = Vector3(float((i + style) % 3 - 1) * 1.8, float(i * 37), float(i % 3 - 1) * 1.6)
		var culm: MeshInstance3D = DesignKit.add(root, _culm_mesh(false), culm_material, Vector3(x, 0.59, z), lean)
		culm.scale = Vector3(radius, height, radius)
		var collars: MeshInstance3D = DesignKit.add(root, _culm_mesh(true), collar_material, culm.position, lean)
		collars.scale = culm.scale
		for tier: int in 3:
			var local_height: float = height * (0.49 + float(tier) * 0.20)
			var tuft_at: Vector3 = culm.position + culm.basis.orthonormalized() * Vector3(0.0, local_height, 0.0)
			var tuft: MeshInstance3D = DesignKit.add(root, _tuft_mesh((i + tier) % 3), leaf_material, tuft_at, Vector3(0.0, float(i * 137 + tier * 91 + style * 23), 0.0))
			var spread: float = 0.72 + float((i + tier) % 4) * 0.10
			tuft.scale = Vector3.ONE * spread
	# Rounded river stones are instanced together, with no per-pebble nodes.
	var pebble_material: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE.darkened(0.18), 0.88, "bamboo_pebbles")
	var pebbles: MultiMesh = MultiMesh.new()
	pebbles.transform_format = MultiMesh.TRANSFORM_3D
	pebbles.mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.022), Vector2(0.040, -0.017), Vector2(0.057, 0.0), Vector2(0.043, 0.022), Vector2(0.0, 0.029)]), 10)
	pebbles.instance_count = 64
	for i: int in pebbles.instance_count:
		var pebble_x: float = -1.24 + float(i % 16) * 0.164 + sin(float(i) * 4.3) * 0.017
		var pebble_z: float = -0.34 + float(i / 16) * 0.225 + cos(float(i) * 2.1) * 0.018
		var pebble_basis: Basis = Basis(Vector3.UP, float(i) * 1.7).scaled(Vector3(1.1, 0.8, 0.74 + float(i % 3) * 0.1))
		pebbles.set_instance_transform(i, Transform3D(pebble_basis, Vector3(pebble_x, 0.619, pebble_z)))
	var pebble_node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	pebble_node.multimesh = pebbles
	pebble_node.material_override = pebble_material
	root.add_child(pebble_node)
	return root


static func _culm_mesh(collars_only: bool) -> ArrayMesh:
	var key: String = "collars" if collars_only else "culm"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var profile: PackedVector2Array = PackedVector2Array()
	if not collars_only:
		profile.append(Vector2(0.0, 0.0))
		profile.append(Vector2(1.0, 0.0))
		for joint: int in 8:
			var y: float = float(joint + 1) / 9.0
			var taper: float = 1.0 - y * 0.30
			profile.append(Vector2(taper * 0.96, y - 0.009))
			profile.append(Vector2(taper * 1.14, y - 0.003))
			profile.append(Vector2(taper * 1.14, y + 0.003))
			profile.append(Vector2(taper, y + 0.009))
		profile.append(Vector2(0.63, 1.0))
		profile.append(Vector2(0.0, 1.0))
	else:
		# Separate disconnected rings: join along the hidden culm centreline.
		profile.append(Vector2.ZERO)
		for joint: int in 8:
			var y: float = float(joint + 1) / 9.0
			var taper: float = 1.0 - y * 0.30
			profile.append(Vector2(0.0, y - 0.002))
			profile.append(Vector2(taper * 1.145, y - 0.002))
			profile.append(Vector2(taper * 1.145, y + 0.002))
			profile.append(Vector2(0.0, y + 0.002))
	var mesh: ArrayMesh = DesignKit.lathe(profile, 12)
	_meshes[key] = mesh
	return mesh


static func _leaf_material(style: int, tint: Color) -> StandardMaterial3D:
	if _materials.has(style):
		return _materials[style] as StandardMaterial3D
	var material: StandardMaterial3D = DesignKit.paint(tint, 0.82).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[style] = material
	return material


static func _tuft_mesh(shape: int) -> ArrayMesh:
	var key: String = "leaves_%d" % shape
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for spray: int in 3:
		var angle: float = float(spray) * TAU / 3.0 + float(shape) * 0.21
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var sideways: Vector3 = Vector3(-sin(angle), 0.0, cos(angle))
		var end: Vector3 = direction * 0.49 + Vector3.UP * (0.16 + float(spray % 2) * 0.09)
		_twig(surface, Vector3.ZERO, end, 0.006)
		for leaf: int in 7:
			var fraction: float = 0.20 + float(leaf) * 0.105
			var start: Vector3 = end * fraction
			var sign_value: float = -1.0 if leaf % 2 == 0 else 1.0
			var forward: Vector3 = (direction * 0.52 + sideways * sign_value * 0.85 + Vector3.UP * 0.08).normalized()
			var across: Vector3 = forward.cross(Vector3.UP).normalized()
			var length: float = 0.28 + sin(float(leaf + shape) * 1.7) * 0.055
			# A lancet with a folded midrib and gently drooping tip, rather than flat cards.
			for section: int in 5:
				var t0: float = float(section) / 5.0
				var t1: float = float(section + 1) / 5.0
				var middle0: Vector3 = start + forward * length * t0 + Vector3.UP * (sin(t0 * PI) * 0.045 - t0 * t0 * 0.09)
				var middle1: Vector3 = start + forward * length * t1 + Vector3.UP * (sin(t1 * PI) * 0.045 - t1 * t1 * 0.09)
				var width0: float = sin(t0 * PI) * 0.023
				var width1: float = sin(t1 * PI) * 0.023
				for edge: float in [-1.0, 1.0]:
					var edge0: Vector3 = middle0 + across * width0 * edge - Vector3.UP * width0 * 0.35
					var edge1: Vector3 = middle1 + across * width1 * edge - Vector3.UP * width1 * 0.35
					_triangle(surface, middle0, edge0, middle1)
					_triangle(surface, edge0, edge1, middle1)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _twig(surface: SurfaceTool, start: Vector3, end: Vector3, radius: float) -> void:
	var direction: Vector3 = (end - start).normalized()
	var u: Vector3 = direction.cross(Vector3.UP).normalized()
	var v: Vector3 = direction.cross(u).normalized()
	for side: int in 6:
		var angle0: float = float(side) * TAU / 6.0
		var angle1: float = float(side + 1) * TAU / 6.0
		var offset0: Vector3 = (u * cos(angle0) + v * sin(angle0)) * radius
		var offset1: Vector3 = (u * cos(angle1) + v * sin(angle1)) * radius
		_triangle(surface, start + offset0, end + offset0 * 0.35, start + offset1)
		_triangle(surface, start + offset1, end + offset0 * 0.35, end + offset1 * 0.35)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
