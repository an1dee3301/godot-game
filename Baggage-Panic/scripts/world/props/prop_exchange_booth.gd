extends RefCounted
## A staffed exchange kiosk; the transaction counter and rate display face +Z.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ExchangeBooth"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var stone: StandardMaterial3D = DesignKit.stone()
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	var finish: StandardMaterial3D = DesignKit.paint(accent)
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.65, "exchange_header")

	# Recessed toe kick, solid lower cabinet and honed counter with softened nosing.
	DesignKit.rbox(root, Vector3(2.86, 0.12, 1.84), Vector3(0.0, 0.06, -0.04), steel, 0.045)
	DesignKit.rbox(root, Vector3(2.96, 0.91, 1.92), Vector3(0.0, 0.575, -0.04), oak, 0.09)
	DesignKit.rbox(root, Vector3(2.86, 0.76, 0.045), Vector3(0.0, 0.59, 0.934), walnut, 0.02)
	for i in 22:
		var x: float = -1.36 + float(i) * 0.1295
		DesignKit.rbox(root, Vector3(0.106, 0.78, 0.055), Vector3(x, 0.59, 0.967), oak, 0.018)
	DesignKit.rbox(root, Vector3(2.87, 0.025, 0.025), Vector3(0.0, 0.985, 1.006), brass, 0.008)
	DesignKit.rbox(root, Vector3(3.0, 0.1, 0.58), Vector3(0.0, 1.07, 0.71), stone, 0.048)

	# Warm interior, two solid cheeks, and a sheltered washi-lit canopy.
	DesignKit.rbox(root, Vector3(2.85, 1.42, 0.105), Vector3(0.0, 1.72, -0.94), finish, 0.04)
	for x: float in [-1.43, 1.43]:
		DesignKit.rbox(root, Vector3(0.14, 2.33, 1.92), Vector3(x, 1.285, -0.04), oak, 0.045)
		DesignKit.rbox(root, Vector3(0.032, 1.29, 0.045), Vector3(x, 1.755, 0.945), brass, 0.012)
	DesignKit.rbox(root, Vector3(3.0, 0.12, 2.0), Vector3(0.0, 3.29, 0.0), walnut, 0.055)
	DesignKit.rbox(root, Vector3(2.7, 0.035, 1.65), Vector3(0.0, 3.212, -0.04), paper, 0.016, false)

	# Header: four comfortably spaced lines, including all six airport languages.
	DesignKit.rbox(root, Vector3(2.96, 0.94, 0.16), Vector3(0.0, 2.79, 0.9), oak, 0.055)
	DesignKit.rbox(root, Vector3(2.83, 0.81, 0.025), Vector3(0.0, 2.79, 0.99), paper, 0.012, false)
	DesignKit.rbox(root, Vector3(2.74, 0.018, 0.018), Vector3(0.0, 3.17, 1.01), brass, 0.007, false)
	_text(root, "CURRENCY EXCHANGE", Vector3(0.0, 3.04, 1.013), 112, 2.66, DesignKit.CHARCOAL)
	_text(root, "両替  ·  货币兑换", Vector3(0.0, 2.8, 1.013), 88, 2.64, DesignKit.CHARCOAL)
	_text(root, "Đổi tiền", Vector3(0.0, 2.605, 1.013), 76, 2.64, DesignKit.CHARCOAL)
	_text(root, "Change de devises  ·  Cambio de divisas", Vector3(0.0, 2.435, 1.013), 76, 2.64, DesignKit.CHARCOAL)

	# Glazing ends above the counter to leave an actual pass-through for cash.
	var glass: StandardMaterial3D = _glass()
	DesignKit.rbox(root, Vector3(1.68, 1.04, 0.024), Vector3(-0.5, 1.81, 0.894), glass, 0.011, false)
	for x: float in [-1.36, 0.36]:
		DesignKit.rbox(root, Vector3(0.043, 1.2, 0.058), Vector3(x, 1.73, 0.901), brass, 0.014)
	DesignKit.rbox(root, Vector3(1.74, 0.04, 0.06), Vector3(-0.5, 1.285, 0.9), brass, 0.015)
	DesignKit.rbox(root, Vector3(1.74, 0.04, 0.06), Vector3(-0.5, 2.32, 0.9), brass, 0.015)
	# A shallow dark cash tray nested within a brass rim on the public counter.
	DesignKit.rbox(root, Vector3(0.48, 0.02, 0.3), Vector3(-0.5, 1.13, 0.75), brass, 0.009)
	DesignKit.rbox(root, Vector3(0.43, 0.012, 0.25), Vector3(-0.5, 1.147, 0.75), steel, 0.005)

	# Rate board is in front of the glass line, so digits stay clear of reflections.
	DesignKit.rbox(root, Vector3(1.01, 1.22, 0.12), Vector3(0.88, 1.72, 0.89), walnut, 0.045)
	DesignKit.rbox(root, Vector3(0.94, 1.15, 0.025), Vector3(0.88, 1.72, 0.962), brass, 0.012)
	DesignKit.rbox(root, Vector3(0.895, 1.1, 0.02), Vector3(0.88, 1.72, 0.985), steel, 0.009)
	_text(root, "JPY / 1", Vector3(0.88, 2.14, 1.003), 70, 0.8, DesignKit.CREAM)
	var currencies: Array[String] = ["USD", "EUR", "GBP"]
	var rates: Array[String] = ["147.20", "162.40", "192.80"]
	if choice == 1:
		rates = ["148.10", "163.20", "193.60"]
	elif choice == 2:
		currencies = ["USD", "EUR", "AUD"]
		rates = ["147.20", "162.40", "98.30"]
	elif choice == 3:
		currencies = ["USD", "EUR", "CAD"]
		rates = ["147.20", "162.40", "108.50"]
	for row in 3:
		var y: float = 1.905 - float(row) * 0.295
		_text(root, currencies[row], Vector3(0.595, y, 1.004), 65, 0.28, DesignKit.LINEN)
		_text(root, rates[row], Vector3(1.045, y, 1.004), 92, 0.51, DesignKit.CREAM)
		DesignKit.rbox(root, Vector3(0.79, 0.009, 0.009), Vector3(0.88, y - 0.125, 1.002), brass, 0.003, false)

	# Teller equipment visible behind the window, plus a linen seat.
	DesignKit.rbox(root, Vector3(1.58, 0.055, 0.5), Vector3(-0.49, 1.055, 0.04), walnut, 0.023)
	DesignKit.rbox(root, Vector3(0.23, 0.025, 0.17), Vector3(-0.69, 1.1, 0.08), steel, 0.01)
	DesignKit.rbox(root, Vector3(0.05, 0.18, 0.04), Vector3(-0.69, 1.19, 0.04), brass, 0.013)
	DesignKit.rbox(root, Vector3(0.4, 0.26, 0.045), Vector3(-0.69, 1.36, 0.04), steel, 0.023)
	DesignKit.rbox(root, Vector3(0.35, 0.21, 0.008), Vector3(-0.69, 1.36, 0.068), DesignKit.washi(accent.lightened(0.3), 0.35, "exchange_screen_%d" % choice), 0.003, false)
	var stool_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.24, 0.0), Vector2(0.26, 0.025), Vector2(0.24, 0.055), Vector2(0.045, 0.08), Vector2(0.035, 0.52), Vector2(0.0, 0.52)])
	DesignKit.add(root, DesignKit.lathe(stool_profile), steel, Vector3(-0.5, 1.01, -0.52))
	DesignKit.rbox(root, Vector3(0.46, 0.08, 0.42), Vector3(-0.5, 1.55, -0.52), DesignKit.fabric(accent, "exchange_seat_%d" % choice), 0.039)
	# Recessed rear service door, a real handle and three quiet ventilation slots.
	DesignKit.rbox(root, Vector3(0.78, 1.99, 0.03), Vector3(0.68, 1.145, -1.003), walnut, 0.014)
	DesignKit.rbox(root, Vector3(0.71, 1.91, 0.035), Vector3(0.68, 1.145, -1.025), oak, 0.015)
	DesignKit.rbox(root, Vector3(0.035, 0.21, 0.045), Vector3(0.94, 1.06, -1.062), brass, 0.016)
	for slot in 3:
		DesignKit.rbox(root, Vector3(0.47, 0.017, 0.008), Vector3(0.68, 0.38 + float(slot) * 0.06, -1.047), steel, 0.007, false)
	return root


static func _glass() -> StandardMaterial3D:
	if _materials.has("glass"):
		return _materials["glass"] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.76, 0.88, 0.84, 0.17)
	material.roughness = 0.12
	material.metallic = 0.08
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["glass"] = material
	return material


static func _text(parent: Node3D, caption: String, at: Vector3, size: int, width: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.font_size = size
	label.pixel_size = 0.0024
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	if measured > width:
		label.font_size = int(float(size) * width / measured)
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
