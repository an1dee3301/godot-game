extends RefCounted
## A four-metre cabinet: turned bottles, walnut joinery and recessed warm light.

const DK = preload("res://scripts/world/design_kit.gd")
const SIG = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WhiskySakeWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var edition: int = posmod(variant, 4)
	var accents: Array[Color] = [DK.SAGE, DK.CLAY, DK.INDIGO, DK.LINEN]
	var accent: Color = accents[edition]
	var walnut: StandardMaterial3D = DK.wood(DK.WALNUT, "whisky_wall_walnut")
	var dark_wood: StandardMaterial3D = DK.wood(DK.WALNUT.darkened(0.2), "whisky_wall_endgrain")
	var steel: StandardMaterial3D = DK.metal()
	var brass: StandardMaterial3D = DK.brass()
	var limestone: StandardMaterial3D = DK.stone()
	var glow: StandardMaterial3D = DK.washi(Color(1.0, 0.79, 0.49), 2.0, "whisky_2700k")
	# Recessed plinth touches the floor; carcass floats above its shadow line.
	DK.rbox(root, Vector3(3.8, 0.12, 0.48), Vector3(0.0, 0.06, -0.015), steel, 0.025)
	DK.rbox(root, Vector3(3.94, 0.57, 0.56), Vector3(0.0, 0.405, 0.0), dark_wood, 0.045)
	for door in 4:
		var x: float = -1.47 + float(door) * 0.98
		DK.rbox(root, Vector3(0.95, 0.49, 0.035), Vector3(x, 0.415, 0.296), walnut, 0.018)
		# Routed finger pull with a discreet brass lower lip.
		DK.rbox(root, Vector3(0.25, 0.026, 0.014), Vector3(x, 0.60, 0.319), steel, 0.009, false)
		DK.rbox(root, Vector3(0.25, 0.009, 0.019), Vector3(x, 0.586, 0.323), brass, 0.003, false)
	DK.rbox(root, Vector3(4.0, 0.085, 0.62), Vector3(0.0, 0.7325, 0.0), limestone, 0.03)
	# Tactile inset back and full-height softened walnut end cheeks.
	DK.rbox(root, Vector3(3.82, 2.78, 0.055), Vector3(0.0, 2.165, -0.257), DK.fabric(accent, "whisky_back_%d" % edition), 0.018)
	for x: float in [-1.94, 1.94]:
		DK.rbox(root, Vector3(0.12, 2.91, 0.55), Vector3(x, 2.23, -0.015), walnut, 0.035)
		DK.rbox(root, Vector3(0.012, 2.78, 0.017), Vector3(x, 2.20, 0.268), brass, 0.004, false)
	# Narrow oak splines express the cabinet's crafted backing, behind the bottles.
	for index in 9:
		DK.rbox(root, Vector3(0.025, 1.98, 0.021), Vector3(-1.72 + float(index) * 0.43, 1.76, -0.215), dark_wood, 0.006, false)
	var levels: Array[float] = [0.86, 1.47, 2.08, 2.69]
	for shelf in 4:
		var y: float = levels[shelf]
		DK.rbox(root, Vector3(3.77, 0.075, 0.51), Vector3(0.0, y, 0.025), walnut, 0.018)
		DK.rbox(root, Vector3(3.61, 0.012, 0.018), Vector3(0.0, y - 0.022, 0.284), brass, 0.004, false)
		if shelf > 0:
			DK.rbox(root, Vector3(3.57, 0.018, 0.055), Vector3(0.0, y - 0.049, 0.16), steel, 0.006, false)
			DK.rbox(root, Vector3(3.51, 0.008, 0.041), Vector3(0.0, y - 0.059, 0.16), glow, 0.003, false)
			# Two shadowless pools per tier provide actual light on the bottle shoulders.
			for x: float in [-0.95, 0.95]:
				var light: OmniLight3D = OmniLight3D.new()
				light.position = Vector3(x, y - 0.115, 0.10)
				light.light_color = Color(1.0, 0.77, 0.48)
				light.light_energy = 0.42
				light.omni_range = 1.15
				light.shadow_enabled = false
				light.distance_fade_enabled = true
				light.distance_fade_begin = 18.0
				light.distance_fade_length = 8.0
				root.add_child(light)
	_bottles(root, levels, edition)
	# A generous four-line fascia keeps all six languages together, above the stock.
	DK.rbox(root, Vector3(3.76, 0.87, 0.10), Vector3(0.0, 3.195, 0.17), dark_wood, 0.035)
	DK.rbox(root, Vector3(3.57, 0.012, 0.012), Vector3(0.0, 3.582, 0.228), brass, 0.004, false)
	_caption(root, "WHISKY & SAKE", Vector3(0.0, 3.44, 0.227), 94, 0.0027, DK.CREAM)
	_caption(root, "ウイスキー・日本酒  /  威士忌・清酒", Vector3(0.0, 3.20, 0.227), 64, 0.0027, DK.CREAM)
	_caption(root, "Whisky & rượu sake", Vector3(0.0, 2.99, 0.227), 65, 0.0027, DK.CREAM)
	_caption(root, "Whisky et saké  /  Whisky y sake", Vector3(0.0, 2.80, 0.227), 60, 0.0027, DK.CREAM)
	DK.rbox(root, Vector3(4.0, 0.075, 0.58), Vector3(0.0, 3.6675, -0.005), walnut, 0.025)
	return root


static func _bottles(root: Node3D, levels: Array[float], edition: int) -> void:
	var colors: Array[Color] = [Color(0.46, 0.22, 0.065), Color(0.22, 0.31, 0.14), Color(0.11, 0.22, 0.19), Color(0.68, 0.43, 0.13), Color(0.17, 0.25, 0.34), DK.CREAM]
	for shape in 3:
		var bodies: Array[Transform3D] = []
		var caps: Array[Transform3D] = []
		var labels: Array[Transform3D] = []
		var body_colors: Array[Color] = []
		var cap_colors: Array[Color] = []
		var label_colors: Array[Color] = []
		var radius: float = 0.072 if shape == 0 else 0.058
		var height: float = 0.335 if shape == 0 else (0.43 if shape == 1 else 0.39)
		for tier in 3:
			for row in 2:
				for column in 16:
					if posmod(column + tier + row + edition, 3) != shape:
						continue
					var seed_value: int = column + tier * 7 + row * 3 + edition * 5
					var size_factor: float = 0.91 + float(posmod(seed_value, 4)) * 0.035
					var pos: Vector3 = Vector3(-1.65 + float(column) * 0.22 + float(row) * 0.018, levels[tier] + 0.0375, 0.14 if row == 0 else -0.075)
					bodies.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size_factor), pos))
					var tint: Color = colors[posmod(seed_value, colors.size())]
					body_colors.append(tint)
					caps.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.027, 0.038, 0.027) * size_factor), pos + Vector3(0.0, (height - 0.006) * size_factor, 0.0)))
					cap_colors.append(DK.OCHRE if seed_value % 2 == 0 else DK.CHARCOAL)
					labels.append(Transform3D(Basis.IDENTITY.scaled(Vector3(radius + 0.0015, 0.108, radius + 0.0015) * size_factor), pos + Vector3(0.0, 0.085 * size_factor, 0.0)))
					label_colors.append(DK.LINEN if seed_value % 3 != 0 else DK.CLAY)
		_batch(root, "BottleBodies%d" % shape, _bottle_mesh(shape), _bottle_material(), bodies, body_colors)
		_batch(root, "BottleCaps%d" % shape, _sleeve_mesh(), _instance_material("caps", 0.38), caps, cap_colors)
		_batch(root, "PaperWraps%d" % shape, _sleeve_mesh(), _instance_material("paper", 0.90), labels, label_colors)


static func _bottle_mesh(shape: int) -> ArrayMesh:
	var key: String = "bottle_%d" % shape
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var profile: PackedVector2Array
	match shape:
		0: # Low, broad whisky decanter with rounded heel and shoulder.
			profile = PackedVector2Array([Vector2(0, 0), Vector2(0.058, 0), Vector2(0.072, 0.015), Vector2(0.072, 0.21), Vector2(0.067, 0.23), Vector2(0.029, 0.266), Vector2(0.025, 0.28), Vector2(0.025, 0.335), Vector2(0, 0.335)])
		1: # Long-neck sake bottle.
			profile = PackedVector2Array([Vector2(0, 0), Vector2(0.045, 0), Vector2(0.058, 0.013), Vector2(0.058, 0.26), Vector2(0.051, 0.29), Vector2(0.026, 0.33), Vector2(0.024, 0.34), Vector2(0.024, 0.43), Vector2(0, 0.43)])
		_: # Tapered spirit bottle, soft sloping shoulders.
			profile = PackedVector2Array([Vector2(0, 0), Vector2(0.05, 0), Vector2(0.058, 0.014), Vector2(0.056, 0.20), Vector2(0.048, 0.265), Vector2(0.024, 0.31), Vector2(0.023, 0.39), Vector2(0, 0.39)])
	var mesh: ArrayMesh = DK.lathe(profile, 20)
	_meshes[key] = mesh
	return mesh


static func _sleeve_mesh() -> ArrayMesh:
	if not _meshes.has("sleeve"):
		_meshes["sleeve"] = DK.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.96, 0), Vector2(1, 0.05), Vector2(1, 0.95), Vector2(0.96, 1), Vector2(0, 1)]), 20)
	return _meshes["sleeve"] as ArrayMesh


static func _bottle_material() -> StandardMaterial3D:
	if not _materials.has("bottle"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.20
		material.metallic = 0.0
		material.clearcoat_enabled = true
		material.clearcoat = 0.85
		material.clearcoat_roughness = 0.12
		_materials["bottle"] = material
	return _materials["bottle"] as StandardMaterial3D


static func _instance_material(key: String, roughness: float) -> StandardMaterial3D:
	if not _materials.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		material.vertex_color_use_as_albedo = true
		material.roughness = roughness
		_materials[key] = material
	return _materials[key] as StandardMaterial3D


static func _batch(root: Node3D, title: String, mesh: Mesh, material: Material, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in transforms.size():
		multi.set_instance_transform(index, transforms[index])
		multi.set_instance_color(index, colors[index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = title
	instance.multimesh = multi
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)


static func _caption(root: Node3D, text: String, at: Vector3, size: int, pixel: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = SIG.font()
	label.font_size = size
	label.pixel_size = pixel
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)
