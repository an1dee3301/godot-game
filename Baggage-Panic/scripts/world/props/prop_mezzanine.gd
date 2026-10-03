extends RefCounted
## Eight-metre bridge; finished floor at +5 m, with both X ends open for continuation.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MezzanineWalkway"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var handrail: StandardMaterial3D = oak if style % 2 == 0 else walnut
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var stone: StandardMaterial3D = DesignKit.stone()
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.5, "mezzanine_diffuser")
	var glass: StandardMaterial3D = _glass(style)

	# Shallow structural deck, then honed stone tiles: the finished top is exactly y=5.
	DesignKit.rbox(root, Vector3(8.0, 0.26, 3.0), Vector3(0.0, 4.79, 0.0), steel, 0.07)
	for tile in 8:
		DesignKit.rbox(root, Vector3(0.993, 0.08, 2.98), Vector3(-3.5 + float(tile), 4.96, 0.0), stone, 0.012)
	for side: float in [-1.0, 1.0]:
		var z: float = side * 1.23
		DesignKit.rbox(root, Vector3(7.9, 0.28, 0.16), Vector3(0.0, 4.54, z), steel, 0.035)
		DesignKit.rbox(root, Vector3(8.0, 0.24, 0.10), Vector3(0.0, 4.77, side * 1.45), oak, 0.035)
		DesignKit.rbox(root, Vector3(7.88, 0.016, 0.018), Vector3(0.0, 4.90, side * 1.499), brass, 0.006, false)

	# Oak ceiling battens in one draw call. Narrow shadow gaps reveal the dark backing.
	var soffit_mesh: ArrayMesh = DesignKit.rounded_box(Vector3(7.84, 0.085, 0.135), 0.018)
	var soffit: MultiMesh = MultiMesh.new()
	soffit.transform_format = MultiMesh.TRANSFORM_3D
	soffit.mesh = soffit_mesh
	soffit.instance_count = 18
	for slat in 18:
		soffit.set_instance_transform(slat, Transform3D(Basis.IDENTITY, Vector3(0.0, 4.61, -1.36 + float(slat) * 0.16)))
	var ribs: MultiMeshInstance3D = MultiMeshInstance3D.new()
	ribs.name = "OakSoffitBattens"
	ribs.multimesh = soffit
	ribs.material_override = oak
	root.add_child(ribs)
	for z: float in [-0.72, 0.72]:
		DesignKit.rbox(root, Vector3(7.5, 0.028, 0.054), Vector3(0.0, 4.559, z), brass, 0.009, false)
		DesignKit.rbox(root, Vector3(7.4, 0.014, 0.033), Vector3(0.0, 4.538, z), glow, 0.006, false)

	# Slim turned steel supports, with stone shoes, brass collars and rounded capitals.
	var column_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.08), Vector2(0.115, 0.08), Vector2(0.115, 0.18),
		Vector2(0.09, 0.24), Vector2(0.085, 4.28), Vector2(0.12, 4.38),
		Vector2(0.12, 4.43), Vector2(0.0, 4.43)
	]), 20)
	var collar_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.09, 0.0), Vector2(0.12, 0.0), Vector2(0.12, 0.035),
		Vector2(0.09, 0.035), Vector2(0.09, 0.0)
	]), 20)
	for x: float in [-3.15, 3.15]:
		for z: float in [-1.23, 1.23]:
			DesignKit.rbox(root, Vector3(0.38, 0.10, 0.38), Vector3(x, 0.05, z), stone, 0.04)
			DesignKit.add(root, column_mesh, steel, Vector3(x, 0.0, z))
			DesignKit.add(root, collar_mesh, brass, Vector3(x, 0.20, z), Vector3.ZERO, false)
			DesignKit.rbox(root, Vector3(0.36, 0.09, 0.30), Vector3(x, 4.425, z), steel, 0.025)

	# Laminated glass in five bays per side, set into metal shoes; rail height 1.12 m.
	for side: float in [-1.0, 1.0]:
		var z: float = side * 1.39
		DesignKit.rbox(root, Vector3(7.94, 0.11, 0.085), Vector3(0.0, 5.055, z), steel, 0.018)
		DesignKit.rbox(root, Vector3(7.96, 0.075, 0.095), Vector3(0.0, 6.0825, z), handrail, 0.035)
		DesignKit.rbox(root, Vector3(7.88, 0.018, 0.027), Vector3(0.0, 6.036, z), brass, 0.007, false)
		for bay in 5:
			var x: float = -3.18 + float(bay) * 1.59
			DesignKit.rbox(root, Vector3(1.56, 0.95, 0.022), Vector3(x, 5.575, z), glass, 0.009, false)
			# A restrained safety stripe makes the transparent barrier readable at distance.
			DesignKit.rbox(root, Vector3(1.51, 0.024, 0.025), Vector3(x, 5.81, z), DesignKit.paint(DesignKit.CREAM), 0.008, false)
		for post in 6:
			var x: float = -3.975 + float(post) * 1.59
			DesignKit.rbox(root, Vector3(0.038, 1.04, 0.045), Vector3(x, 5.56, z), steel, 0.013, false)

	# Front-facing wayfinding, hung below the bridge on substantial concealed brackets.
	for x: float in [-2.15, 2.15]:
		DesignKit.rbox(root, Vector3(0.06, 0.37, 0.08), Vector3(x, 4.43, 1.38), steel, 0.015)
	DesignKit.rbox(root, Vector3(5.94, 1.74, 0.16), Vector3(0.0, 3.58, 1.42), walnut, 0.065)
	DesignKit.rbox(root, Vector3(5.79, 1.59, 0.027), Vector3(0.0, 3.58, 1.512), DesignKit.paint(DesignKit.CHARCOAL), 0.035)
	DesignKit.rbox(root, Vector3(0.085, 1.42, 0.034), Vector3(-2.73, 3.58, 1.53), DesignKit.paint(accent), 0.018, false)
	DesignKit.rbox(root, Vector3(5.4, 0.018, 0.018), Vector3(0.0, 4.305, 1.536), brass, 0.006, false)
	var words: Array = Signage.TEXT["gates"]
	var ranges: Array[String] = ["A01–A12", "B01–B12", "C01–C12", "D01–D12"]
	_label(root, "%s  %s  →" % [words[0], ranges[style]], Vector3(0.0, 4.08, 1.543), 120, DesignKit.CREAM)
	_label(root, "%s  ·  %s" % [words[1], words[2]], Vector3(0.0, 3.69, 1.543), 92, DesignKit.CREAM)
	_label(root, str(words[3]), Vector3(0.0, 3.34, 1.543), 88, DesignKit.CREAM)
	_label(root, "%s  ·  %s" % [words[4], words[5]], Vector3(0.0, 3.00, 1.543), 88, DesignKit.CREAM)
	return root


static func _glass(style: int) -> StandardMaterial3D:
	var key: String = "glass_%d" % style
	if _materials.has(key):
		var cached: StandardMaterial3D = _materials[key]
		return cached
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.74, 0.86, 0.83, 0.19) if style % 2 == 0 else Color(0.87, 0.84, 0.74, 0.19)
	material.roughness = 0.12
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
