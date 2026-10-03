extends RefCounted
## A freestanding walnut café counter; all service faces point toward +Z.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "EspressoBar"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[style]
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "espresso_walnut")
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.48, "espresso_worktop")
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var ceramic: StandardMaterial3D = DesignKit.paint(DesignKit.CREAM, 0.24)
	var trim: StandardMaterial3D = DesignKit.paint(accent)
	# Recessed kick, continuous walnut carcass, framed door leaves and rounded stone lip.
	DesignKit.rbox(root, Vector3(4.12, 0.12, 1.0), Vector3(0, 0.06, -0.04), steel, 0.035)
	DesignKit.rbox(root, Vector3(4.3, 0.84, 1.12), Vector3(0, 0.53, 0), walnut, 0.09)
	for i in 4:
		var x: float = -1.56 + float(i) * 1.04
		DesignKit.rbox(root, Vector3(0.99, 0.68, 0.045), Vector3(x, 0.53, 0.57), walnut, 0.045)
		DesignKit.rbox(root, Vector3(0.28, 0.022, 0.038), Vector3(x, 0.8, 0.61), brass, 0.01)
	DesignKit.rbox(root, Vector3(4.26, 0.025, 1.12), Vector3(0, 0.95, 0), brass, 0.008)
	DesignKit.rbox(root, Vector3(4.48, 0.105, 1.32), Vector3(0, 1.015, 0.035), stone, 0.048)
	DesignKit.rbox(root, Vector3(3.98, 0.018, 0.018), Vector3(0, 0.16, 0.594), DesignKit.washi(DesignKit.CREAM, 0.6, "espresso_kick_glow"), 0.006, false)
	# The menu and six-language café masthead share slender rear uprights.
	for x: float in [-1.99, 1.99]:
		DesignKit.rbox(root, Vector3(0.065, 3.43, 0.065), Vector3(x, 1.715, -0.5), steel, 0.02)
		DesignKit.rbox(root, Vector3(0.15, 0.04, 0.15), Vector3(x, 0.02, -0.5), brass, 0.018)
	DesignKit.rbox(root, Vector3(4.3, 1.1, 0.13), Vector3(0, 3.12, -0.5), walnut, 0.085)
	DesignKit.rbox(root, Vector3(4.14, 0.94, 0.03), Vector3(0, 3.12, -0.421), DesignKit.washi(DesignKit.CREAM, 0.45, "espresso_header"), 0.055, false)
	_label(root, "ESPRESSO BAR", Vector3(0, 3.39, -0.395), 0.28, DesignKit.CHARCOAL)
	var cafe: Array = Signage.TEXT["cafe"]
	_label(root, "%s  ·  %s  ·  %s" % [cafe[0], cafe[1], cafe[2]], Vector3(0, 3.1, -0.394), 0.18, DesignKit.CHARCOAL)
	_label(root, "%s  ·  %s  ·  %s" % [cafe[3], cafe[4], cafe[5]], Vector3(0, 2.83, -0.394), 0.155, DesignKit.CHARCOAL)
	DesignKit.rbox(root, Vector3(3.86, 0.8, 0.1), Vector3(0, 2.13, -0.48), brass, 0.035)
	DesignKit.rbox(root, Vector3(3.77, 0.71, 0.026), Vector3(0, 2.13, -0.418), steel, 0.022)
	_label(root, "ESPRESSO    3   /   LATTE    4", Vector3(0, 2.31, -0.399), 0.19, DesignKit.CREAM)
	_label(root, "MATCHA    4   /   CROISSANT    3", Vector3(0, 2.06, -0.399), 0.18, DesignKit.CREAM)
	_label(root, "COFFEE & A QUIET MOMENT", Vector3(0, 1.85, -0.399), 0.14, accent.lightened(0.35))
	# Two-group brass machine: side cheeks, inset face, gauge, group bells, tray and wand.
	var mx: float = -0.5
	DesignKit.rbox(root, Vector3(1.25, 0.055, 0.59), Vector3(mx, 1.095, 0.02), steel, 0.02)
	DesignKit.rbox(root, Vector3(1.2, 0.47, 0.33), Vector3(mx, 1.38, -0.14), brass, 0.085)
	DesignKit.rbox(root, Vector3(1.04, 0.26, 0.025), Vector3(mx, 1.36, 0.035), trim, 0.035)
	DesignKit.rbox(root, Vector3(1.24, 0.045, 0.4), Vector3(mx, 1.63, -0.12), brass, 0.02)
	DesignKit.rbox(root, Vector3(1.04, 0.024, 0.31), Vector3(mx, 1.65, -0.12), steel, 0.012)
	DesignKit.rbox(root, Vector3(1.08, 0.03, 0.25), Vector3(mx, 1.139, 0.195), brass, 0.013)
	for i in 7:
		DesignKit.rbox(root, Vector3(0.009, 0.008, 0.2), Vector3(mx - 0.42 + float(i) * 0.14, 1.16, 0.195), steel, 0.003, false)
	for x: float in [-0.79, -0.24]:
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.073, 0), Vector2(0.08, 0.035), Vector2(0.057, 0.095), Vector2(0, 0.095)])), brass, Vector3(x, 1.28, 0.16))
		DesignKit.rbox(root, Vector3(0.042, 0.036, 0.22), Vector3(x, 1.292, 0.315), walnut, 0.016)
		DesignKit.rbox(root, Vector3(0.045, 0.035, 0.018), Vector3(x, 1.46, 0.057), DesignKit.washi(accent.lightened(0.45), 0.5, "espresso_button_%d" % style), 0.01, false)
		_cup(root, Vector3(x, 1.164, 0.16), ceramic)
	var gauge: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.063, 0), Vector2(0.063, 0.015), Vector2(0, 0.015)]))
	DesignKit.add(root, gauge, brass, Vector3(mx, 1.47, 0.065), Vector3(90, 0, 0))
	DesignKit.add(root, gauge, ceramic, Vector3(mx, 1.47, 0.082), Vector3(90, 0, 0)).scale = Vector3(0.8, 0.8, 0.8)
	var needle: MeshInstance3D = DesignKit.rbox(root, Vector3(0.008, 0.04, 0.008), Vector3(mx - 0.012, 1.482, 0.099), steel, 0.003, false)
	needle.rotation_degrees.z = 35
	DesignKit.rbox(root, Vector3(0.022, 0.24, 0.022), Vector3(0.14, 1.34, 0.19), brass, 0.008)
	DesignKit.rbox(root, Vector3(0.022, 0.022, 0.14), Vector3(0.14, 1.23, 0.25), brass, 0.008)
	# Service cups on a folded linen mat, with proper open ceramic profiles and handles.
	DesignKit.rbox(root, Vector3(0.61, 0.018, 0.34), Vector3(-1.62, 1.075, 0.13), DesignKit.fabric(accent, "espresso_linen_%d" % style), 0.008)
	for i in 3:
		_cup(root, Vector3(-1.82 + float(i) * 0.2, 1.087, 0.1), ceramic if i != style % 3 else trim)
	_cup(root, Vector3(-0.87, 1.666, -0.12), ceramic)
	_cup(root, Vector3(-0.15, 1.666, -0.12), ceramic)
	# A low glass cloche with walnut foot, brass rim and sculpted pastry rolls.
	var dome_at: Vector3 = Vector3(1.43, 1.067, 0.1)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.41, 0), Vector2(0.43, 0.025), Vector2(0.41, 0.065), Vector2(0, 0.065)])), walnut, dome_at)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.385, 0), Vector2(0.407, 0), Vector2(0.407, 0.025), Vector2(0.385, 0.025)])), brass, dome_at + Vector3(0, 0.06, 0))
	for i in 3:
		var pastry: MeshInstance3D = DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.05, 0.005), Vector2(0.085, 0.025), Vector2(0.075, 0.06), Vector2(0.045, 0.095), Vector2(0, 0.105)])), DesignKit.stone(DesignKit.OCHRE, 0.83, "espresso_pastry"), dome_at + Vector3(-0.22 + float(i) * 0.22, 0.065, 0))
		pastry.scale = Vector3(1, 1, 1.7)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.396, 0), Vector2(0.39, 0.13), Vector2(0.35, 0.24), Vector2(0.27, 0.32), Vector2(0.15, 0.37), Vector2(0, 0.39)]), 32), _glass(), dome_at + Vector3(0, 0.085, 0), Vector3.ZERO, false)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.025, 0), Vector2(0.045, 0.035), Vector2(0.035, 0.07), Vector2(0, 0.075)])), brass, dome_at + Vector3(0, 0.475, 0))
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _cup(parent: Node3D, at: Vector3, ceramic: Material) -> void:
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.085, 0), Vector2(0.09, 0.009), Vector2(0, 0.015)])), ceramic, at)
	DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0, 0.012), Vector2(0.038, 0.012), Vector2(0.051, 0.098), Vector2(0.044, 0.101), Vector2(0.032, 0.025), Vector2(0, 0.025)])), ceramic, at)
	var ring: PackedVector2Array = PackedVector2Array()
	for i in 13:
		var angle: float = TAU * float(i) / 12.0
		ring.append(Vector2(0.025 + cos(angle) * 0.007, sin(angle) * 0.007))
	DesignKit.add(parent, DesignKit.lathe(ring, 16), ceramic, at + Vector3(0.061, 0.062, 0), Vector3(90, 0, 0))


static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"):
		return _materials["glass"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.96, 0.93, 0.18)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.12
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["glass"] = material
	return material
