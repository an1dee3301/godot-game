extends RefCounted
## Six mechanical capsule dispensers on a crafted oak island. Front faces +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GachaRow"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: Material = Kit.wood()
	var walnut: Material = Kit.wood(Kit.WALNUT, "gacha_walnut")
	var steel: Material = Kit.metal()
	var brass: Material = Kit.brass()
	var palette: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.CREAM, Kit.INDIGO, Kit.OCHRE, Kit.LINEN]
	# Inset black toe-kick and layered oak joinery, with a honed stone worktop.
	Kit.rbox(root, Vector3(4.6, 0.1, 0.64), Vector3(0.0, 0.05, -0.02), steel, 0.035)
	Kit.rbox(root, Vector3(4.8, 0.26, 0.8), Vector3(0.0, 0.23, -0.02), oak, 0.055)
	Kit.rbox(root, Vector3(4.84, 0.07, 0.84), Vector3(0.0, 0.395, -0.02), Kit.stone(), 0.028)
	Kit.rbox(root, Vector3(4.63, 0.025, 0.018), Vector3(0.0, 0.13, 0.385), walnut, 0.007)
	for x: float in [-1.56, -0.78, 0.0, 0.78, 1.56]:
		Kit.rbox(root, Vector3(0.008, 0.18, 0.014), Vector3(x, 0.24, 0.383), walnut, 0.003)
	# Header carried by oak uprights behind the clear reservoirs.
	for x: float in [-2.26, 2.26]:
		Kit.rbox(root, Vector3(0.075, 1.84, 0.09), Vector3(x, 1.35, -0.35), oak, 0.022)
	Kit.rbox(root, Vector3(4.8, 0.78, 0.11), Vector3(0.0, 2.28, -0.35), walnut, 0.06)
	Kit.rbox(root, Vector3(4.64, 0.63, 0.035), Vector3(0.0, 2.28, -0.278), Kit.washi(Kit.CREAM, 0.45, "gacha_header"), 0.04)
	_caption(root, "CAPSULE TOYS", Vector3(0.0, 2.46, -0.254), 90, 0.0028)
	_caption(root, "カプセルトイ  ·  胶囊玩具", Vector3(0.0, 2.25, -0.254), 62, 0.0026)
	_caption(root, "Đồ chơi  ·  Jouets  ·  Juguetes", Vector3(0.0, 2.07, -0.254), 58, 0.0026)
	for i: int in 6:
		var x: float = (float(i) - 2.5) * 0.77
		var tint: Color = palette[(i + style) % palette.size()]
		var body: Material = Kit.paint(tint, 0.37)
		Kit.rbox(root, Vector3(0.64, 0.08, 0.64), Vector3(x, 0.47, 0.0), walnut, 0.035)
		Kit.rbox(root, Vector3(0.61, 0.61, 0.57), Vector3(x, 0.815, 0.0), body, 0.08)
		Kit.rbox(root, Vector3(0.52, 0.53, 0.025), Vector3(x, 0.815, 0.29), Kit.paint(Kit.CREAM, 0.48), 0.055)
		# Deep retrieval mouth with an inset brass-edged lifting flap and curved lip.
		Kit.rbox(root, Vector3(0.3, 0.135, 0.04), Vector3(x, 0.61, 0.311), steel, 0.04)
		Kit.rbox(root, Vector3(0.254, 0.087, 0.018), Vector3(x, 0.628, 0.339), body, 0.022)
		Kit.rbox(root, Vector3(0.275, 0.018, 0.067), Vector3(x, 0.557, 0.333), brass, 0.008)
		# Coin slot is recessed in a brass bezel, separate from the hand crank.
		Kit.rbox(root, Vector3(0.085, 0.14, 0.024), Vector3(x + 0.176, 0.909, 0.314), brass, 0.022)
		Kit.rbox(root, Vector3(0.013, 0.075, 0.012), Vector3(x + 0.176, 0.918, 0.331), steel, 0.005)
		Kit.add(root, _disc(), brass, Vector3(x - 0.06, 0.847, 0.328), Vector3(90.0, 0.0, 0.0))
		var crank: MeshInstance3D = Kit.rbox(root, Vector3(0.235, 0.043, 0.043), Vector3(x - 0.06, 0.847, 0.367), brass, 0.019)
		crank.rotation_degrees.z = -22.0 + float(style) * 14.0
		var angle: float = deg_to_rad(crank.rotation_degrees.z)
		Kit.add(root, _grip(), walnut, Vector3(x - 0.06 + cos(angle) * 0.095, 0.847 + sin(angle) * 0.095, 0.397), Vector3(90.0, 0.0, 0.0))
		# Turned collars and lid seal the transparent, gently bulging reservoir.
		Kit.add(root, _collar(), brass, Vector3(x, 1.107, 0.0))
		Kit.add(root, _dome(), _glass(), Vector3(x, 1.14, 0.0), Vector3.ZERO, false)
		Kit.add(root, _lid(), body, Vector3(x, 1.742, 0.0))
		Kit.add(root, _grip(), brass, Vector3(x, 1.794, 0.0))
		_caption(root, "%02d" % (i + 1), Vector3(x - 0.075, 1.011, 0.316), 58, 0.0025)
	_capsules(root, palette, style)
	return root


static func _caption(parent: Node3D, caption: String, at: Vector3, font_size: int, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.85, 0.96, 0.96, 0.16)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.12
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D


static func _capsule_material() -> StandardMaterial3D:
	if not _materials.has("capsule"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.27
		_materials["capsule"] = material
	return _materials["capsule"] as StandardMaterial3D


static func _profile(key: String, points: PackedVector2Array) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = Kit.lathe(points, 32)
	return _meshes[key] as Mesh


static func _dome() -> Mesh:
	return _profile("dome", PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.278, 0.025), Vector2(0.295, 0.09), Vector2(0.298, 0.39), Vector2(0.282, 0.49), Vector2(0.245, 0.555), Vector2(0.17, 0.597), Vector2(0.0, 0.61)]))


static func _collar() -> Mesh:
	return _profile("collar", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.272, 0.0), Vector2(0.288, 0.012), Vector2(0.288, 0.027), Vector2(0.271, 0.04), Vector2(0.0, 0.04)]))


static func _lid() -> Mesh:
	return _profile("lid", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.173, 0.0), Vector2(0.181, 0.012), Vector2(0.175, 0.031), Vector2(0.12, 0.043), Vector2(0.0, 0.043)]))


static func _disc() -> Mesh:
	return _profile("crank_disc", PackedVector2Array([Vector2(0.0, -0.014), Vector2(0.082, -0.014), Vector2(0.091, -0.004), Vector2(0.091, 0.006), Vector2(0.077, 0.018), Vector2(0.0, 0.018)]))


static func _grip() -> Mesh:
	return _profile("grip", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.025, 0.0), Vector2(0.035, 0.012), Vector2(0.035, 0.048), Vector2(0.025, 0.06), Vector2(0.0, 0.06)]))


static func _capsules(parent: Node3D, palette: Array[Color], style: int) -> void:
	# Three draws for 216 toys: coloured top shells, ivory bottom shells and dark equator seams.
	for part: int in 3:
		var points: PackedVector2Array = PackedVector2Array()
		if part == 2:
			points = PackedVector2Array([Vector2(0.054, -0.0015), Vector2(0.054, 0.0015)])
		else:
			for step: int in 9:
				var angle: float = float(step if part == 0 else 8 - step) / 8.0 * PI * 0.5
				points.append(Vector2(0.053 * cos(angle), 0.053 * sin(angle) * (1.0 if part == 0 else -1.0)))
		var instances: MultiMesh = MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = _profile("capsule_%d" % part, points)
		instances.instance_count = 216
		var index: int = 0
		for machine: int in 6:
			for layer: int in 4:
				for item: int in 9:
					var angle: float = float(item) / 8.0 * TAU + float(layer + style) * 0.39
					var radial: float = 0.192 if item < 8 else 0.0
					var position: Vector3 = Vector3((float(machine) - 2.5) * 0.77 + cos(angle) * radial, 1.207 + float(layer) * 0.105, sin(angle) * radial)
					var basis: Basis = Basis.from_euler(Vector3(0.22 * sin(angle), angle, 0.2 * cos(angle)))
					instances.set_instance_transform(index, Transform3D(basis, position))
					var tint: Color = palette[(machine + item + layer + style) % palette.size()]
					if part == 1:
						tint = Kit.CREAM.lerp(tint, 0.18)
					elif part == 2:
						tint = tint.darkened(0.3)
					instances.set_instance_color(index, tint)
					index += 1
		var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
		node.name = "CapsuleShells_%d" % part
		node.multimesh = instances
		node.material_override = _capsule_material()
		parent.add_child(node)
