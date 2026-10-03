extends RefCounted
## Honed limestone island, turned brass display pedestals and a luminous oak screen.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PerfumeCounter"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "perfume_walnut")
	var stone: StandardMaterial3D = DesignKit.stone()
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.2, "perfume_screen")
	# Recessed kick gives the heavy island a floating edge while touching the floor.
	DesignKit.rbox(root, Vector3(3.42, 0.12, 1.30), Vector3(0.0, 0.06, 0.0), steel, 0.055)
	DesignKit.rbox(root, Vector3(3.68, 0.86, 1.48), Vector3(0.0, 0.55, 0.0), stone, 0.14)
	DesignKit.rbox(root, Vector3(3.70, 0.025, 1.50), Vector3(0.0, 0.99, 0.0), brass, 0.011)
	DesignKit.rbox(root, Vector3(3.84, 0.13, 1.64), Vector3(0.0, 1.0675, 0.0), stone, 0.06)
	# A recessed walnut fascia and wide brass drawer pulls add cabinet craft.
	DesignKit.rbox(root, Vector3(2.92, 0.55, 0.035), Vector3(0.0, 0.58, 0.746), walnut, 0.016)
	for x: float in [-0.99, 0.0, 0.99]:
		DesignKit.rbox(root, Vector3(0.94, 0.49, 0.025), Vector3(x, 0.58, 0.773), oak, 0.012)
		DesignKit.rbox(root, Vector3(0.36, 0.025, 0.035), Vector3(x, 0.78, 0.803), brass, 0.01, false)
	# Back screen: thick oak perimeter, warm paper inset, walnut reveal and fluted wings.
	DesignKit.rbox(root, Vector3(3.76, 2.22, 0.16), Vector3(0.0, 2.19, -0.67), oak, 0.08)
	DesignKit.rbox(root, Vector3(3.39, 1.77, 0.04), Vector3(0.0, 2.35, -0.571), walnut, 0.04)
	DesignKit.rbox(root, Vector3(3.29, 1.67, 0.032), Vector3(0.0, 2.35, -0.543), glow, 0.04, false)
	for side: float in [-1.0, 1.0]:
		for flute: int in 3:
			DesignKit.rbox(root, Vector3(0.026, 1.91, 0.024), Vector3(side * (1.72 + float(flute) * 0.046), 2.19, -0.579), walnut, 0.011, false)
	# Large multilingual typography sits above the bottles, facing the passenger aisle.
	_label(root, "PERFUME", Vector3(0.0, 2.96, -0.519), 100, 0.004, 3.06)
	_label(root, "香水  ·  香水", Vector3(0.0, 2.60, -0.519), 84, 0.0035, 3.06)
	_label(root, "Nước hoa", Vector3(0.0, 2.25, -0.519), 80, 0.0035, 3.06)
	_label(root, "Parfums  ·  Perfumes", Vector3(0.0, 1.91, -0.519), 76, 0.0035, 3.06)
	var duty: Array = Signage.TEXT["duty_free"]
	_label(root, str(duty[0]) + "  ·  " + str(duty[1]) + "  ·  " + str(duty[2]), Vector3(0.0, 0.53, 0.802), 76, 0.0031, 2.78, DesignKit.CREAM)
	# Three stepped brass risers: a turned stem and foot support a softly lipped tray.
	for station: int in 3:
		var x: float = float(station - 1) * 1.04
		var lift: float = 0.13 + float(posmod(station + style, 3)) * 0.07
		var pedestal: ArrayMesh = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.25, 0.025),
			Vector2(0.21, 0.045), Vector2(0.065, 0.055), Vector2(0.055, lift - 0.025),
			Vector2(0.20, lift - 0.014), Vector2(0.22, lift), Vector2(0.0, lift)
		]), 24)
		DesignKit.add(root, pedestal, brass, Vector3(x, 1.133, 0.04))
		var tray_y: float = 1.133 + lift
		DesignKit.rbox(root, Vector3(0.86, 0.042, 0.55), Vector3(x, tray_y + 0.021, 0.04), brass, 0.02)
		DesignKit.rbox(root, Vector3(0.78, 0.014, 0.47), Vector3(x, tray_y + 0.05, 0.04), DesignKit.fabric(accent, "perfume_tray_%d" % style), 0.006, false)
		for bottle: int in 3:
			var bx: float = x + float(bottle - 1) * 0.245
			var round_shape: bool = posmod(bottle + station + style, 2) == 0
			_bottle(root, Vector3(bx, tray_y + 0.057, 0.04), accent, round_shape, posmod(bottle + style, 3))
	# Test-strip dish at the front edge: turned limestone with a visible recessed basin.
	var dish: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.20, 0.016),
		Vector2(0.21, 0.055), Vector2(0.19, 0.06), Vector2(0.16, 0.025), Vector2(0.0, 0.025)
	]), 32)
	DesignKit.add(root, dish, stone, Vector3(1.42, 1.133, 0.52))
	for strip: int in 3:
		var paper: MeshInstance3D = DesignKit.rbox(root, Vector3(0.027, 0.006, 0.23), Vector3(1.40 + float(strip) * 0.035, 1.165 + float(strip) * 0.005, 0.51), DesignKit.paint(DesignKit.CREAM), 0.002, false)
		paper.rotation_degrees.y = float(strip - 1) * 13.0
	return root


static func _bottle(parent: Node3D, at: Vector3, tint: Color, round_shape: bool, kind: int) -> void:
	var height: float = 0.20 + float(kind) * 0.035
	var glass: StandardMaterial3D = _glass(tint)
	var liquid: StandardMaterial3D = DesignKit.paint(tint.lightened(0.35), 0.22)
	if round_shape:
		var shell: ArrayMesh = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.062, 0.0), Vector2(0.075, 0.018),
			Vector2(0.075, height - 0.04), Vector2(0.042, height - 0.013),
			Vector2(0.03, height), Vector2(0.0, height)
		]), 20)
		DesignKit.add(parent, shell, glass, at, Vector3.ZERO, false)
	else:
		DesignKit.rbox(parent, Vector3(0.15, height, 0.095), at + Vector3(0.0, height * 0.5, 0.0), glass, 0.024, false)
	# Inset liquid leaves a clear shoulder and thick glass heel.
	DesignKit.rbox(parent, Vector3(0.10, height * 0.62, 0.055), at + Vector3(0.0, height * 0.37, 0.0), liquid, 0.016, false)
	var collar: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.031, 0.0), Vector2(0.031, 0.025), Vector2(0.0, 0.025)
	]), 16)
	DesignKit.add(parent, collar, DesignKit.brass(), at + Vector3(0.0, height, 0.0), Vector3.ZERO, false)
	var cap_material: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "perfume_walnut") if kind == 1 else DesignKit.brass()
	DesignKit.rbox(parent, Vector3(0.087, 0.055, 0.078), at + Vector3(0.0, height + 0.0475, 0.0), cap_material, 0.017, false)


static func _glass(tint: Color) -> StandardMaterial3D:
	var key: String = "glass_" + tint.to_html()
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(tint.lightened(0.65), 0.30)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.12
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, width: float, ink: Color = DesignKit.CHARCOAL) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x * pixel
	label.pixel_size = pixel * minf(1.0, width / maxf(measured, 0.001))
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
