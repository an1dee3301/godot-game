extends RefCounted
## A compact, staffed airport koban. Front / service hatch faces +Z.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Koban"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[choice]
	var white: StandardMaterial3D = DesignKit.stone(Color(0.96, 0.95, 0.90), 0.76, "koban_white")
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var stone: StandardMaterial3D = DesignKit.stone()
	var trim: StandardMaterial3D = DesignKit.paint(accent)
	var glazing: StandardMaterial3D = DesignKit.metal(Color(0.23, 0.32, 0.33), 0.20, 0.25, "koban_glazing")
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.65, "koban_sign")

	# Recessed dark footing, honed stone threshold, and a genuinely hollow booth.
	DesignKit.rbox(root, Vector3(3.24, 0.08, 2.24), Vector3(0.0, 0.04, 0.0), steel, 0.035)
	DesignKit.rbox(root, Vector3(3.42, 0.12, 2.44), Vector3(0.0, 0.14, 0.0), stone, 0.055)
	DesignKit.rbox(root, Vector3(3.36, 2.70, 0.16), Vector3(0.0, 1.55, -1.12), white, 0.075)
	for x: float in [-1.60, 1.60]:
		DesignKit.rbox(root, Vector3(0.16, 2.70, 2.30), Vector3(x, 1.55, 0.0), white, 0.075)
		DesignKit.rbox(root, Vector3(0.055, 2.42, 0.12), Vector3(x, 1.43, 1.15), oak, 0.022)
	DesignKit.rbox(root, Vector3(3.26, 0.07, 2.20), Vector3(0.0, 0.235, 0.0), oak, 0.025)

	# Rounded eaves have a walnut shadow reveal and an oak soffit.
	DesignKit.rbox(root, Vector3(3.52, 0.075, 2.54), Vector3(0.0, 2.965, 0.0), walnut, 0.035)
	DesignKit.rbox(root, Vector3(3.64, 0.19, 2.66), Vector3(0.0, 3.095, 0.0), white, 0.085)
	DesignKit.rbox(root, Vector3(3.38, 0.04, 2.36), Vector3(0.0, 2.915, 0.0), oak, 0.018)

	# Left service hatch: rounded solid apron, deep counter, open view to the desk.
	DesignKit.rbox(root, Vector3(2.10, 0.94, 0.17), Vector3(-0.52, 0.70, 1.12), white, 0.06)
	DesignKit.rbox(root, Vector3(1.91, 0.61, 0.028), Vector3(-0.52, 0.72, 1.217), trim, 0.014)
	for x: float in [-1.53, 0.49]:
		DesignKit.rbox(root, Vector3(0.10, 1.42, 0.20), Vector3(x, 1.89, 1.11), oak, 0.035)
	DesignKit.rbox(root, Vector3(2.15, 0.10, 0.54), Vector3(-0.52, 1.22, 1.08), oak, 0.042)
	DesignKit.rbox(root, Vector3(1.93, 0.025, 0.25), Vector3(-0.52, 1.284, 1.15), stone, 0.012)
	DesignKit.rbox(root, Vector3(2.13, 0.10, 0.20), Vector3(-0.52, 2.55, 1.11), oak, 0.035)
	DesignKit.rbox(root, Vector3(1.87, 0.025, 0.08), Vector3(-0.52, 2.491, 1.11), glow, 0.011, false)

	# Right staff door: inset glass, crafted stiles, brass pull and visible hinges.
	DesignKit.rbox(root, Vector3(0.93, 2.36, 0.16), Vector3(1.05, 1.43, 1.12), walnut, 0.04)
	DesignKit.rbox(root, Vector3(0.81, 2.23, 0.08), Vector3(1.05, 1.43, 1.221), oak, 0.035)
	DesignKit.rbox(root, Vector3(0.64, 1.20, 0.035), Vector3(1.05, 1.88, 1.277), glazing, 0.016)
	DesignKit.rbox(root, Vector3(0.64, 0.75, 0.026), Vector3(1.05, 0.80, 1.274), white, 0.012)
	DesignKit.rbox(root, Vector3(0.64, 0.035, 0.04), Vector3(1.05, 1.81, 1.304), oak, 0.015)
	for y: float in [1.07, 1.34]:
		DesignKit.rbox(root, Vector3(0.035, 0.035, 0.07), Vector3(0.80, y, 1.32), brass, 0.014, false)
	DesignKit.rbox(root, Vector3(0.035, 0.31, 0.04), Vector3(0.80, 1.205, 1.364), brass, 0.016, false)
	for y: float in [0.63, 2.22]:
		DesignKit.rbox(root, Vector3(0.026, 0.12, 0.035), Vector3(1.45, y, 1.286), steel, 0.012, false)

	# Interior: linen noticeboard, writing desk and a small terminal with no microtext.
	DesignKit.rbox(root, Vector3(1.38, 0.84, 0.07), Vector3(-0.45, 1.91, -1.004), oak, 0.035)
	DesignKit.rbox(root, Vector3(1.25, 0.71, 0.024), Vector3(-0.45, 1.91, -0.955), DesignKit.fabric(accent, "koban_linen_%d" % choice), 0.011)
	DesignKit.rbox(root, Vector3(1.91, 0.075, 0.71), Vector3(-0.52, 1.06, 0.39), walnut, 0.03)
	for x: float in [-1.28, 0.24]:
		DesignKit.rbox(root, Vector3(0.06, 0.76, 0.55), Vector3(x, 0.64, 0.38), steel, 0.02)
	var monitor_x: float = -0.96 if choice % 2 == 0 else -0.18
	DesignKit.rbox(root, Vector3(0.27, 0.025, 0.20), Vector3(monitor_x, 1.11, 0.43), steel, 0.012)
	DesignKit.rbox(root, Vector3(0.05, 0.19, 0.045), Vector3(monitor_x, 1.21, 0.39), steel, 0.018)
	DesignKit.rbox(root, Vector3(0.44, 0.31, 0.055), Vector3(monitor_x, 1.41, 0.39), steel, 0.026)
	DesignKit.rbox(root, Vector3(0.38, 0.245, 0.012), Vector3(monitor_x, 1.41, 0.425), DesignKit.washi(Color(0.38, 0.56, 0.57), 0.35, "koban_screen"), 0.005, false)
	DesignKit.rbox(root, Vector3(0.30, 0.035, 0.22), Vector3(-1.25 if choice % 2 == 1 else 0.14, 1.30, 1.03), trim, 0.016, false)

	# The main text is around 0.35 m high; its warm luminous field faces +Z.
	DesignKit.rbox(root, Vector3(3.27, 0.51, 0.18), Vector3(0.0, 2.75, 1.16), oak, 0.055)
	DesignKit.rbox(root, Vector3(3.12, 0.39, 0.035), Vector3(0.0, 2.75, 1.271), glow, 0.016, false)
	_caption(root, "POLICE · 交番", Vector3(0.0, 2.75, 1.297), 116, 2.98)

	# A broad side directory supplies the remaining terminal languages at readable scale.
	var directory: Node3D = Node3D.new()
	directory.name = "InternationalPoliceSign"
	directory.position = Vector3(-1.70, 1.60, 0.0)
	directory.rotation_degrees.y = -90.0
	root.add_child(directory)
	DesignKit.rbox(directory, Vector3(2.05, 1.76, 0.07), Vector3.ZERO, oak, 0.032)
	DesignKit.rbox(directory, Vector3(1.93, 1.64, 0.022), Vector3(0.0, 0.0, 0.049), glow, 0.01, false)
	var captions: Array[String] = ["警察", "Cảnh sát", "Police", "Policía"]
	for index: int in captions.size():
		_caption(directory, captions[index], Vector3(0.0, 0.57 - float(index) * 0.38, 0.067), 92, 1.78)

	# Turned red beacon: steel foot, brass collar, soft domed lens, static light glow.
	var beacon_at: Vector3 = Vector3(0.0, 3.19, 0.18)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.18, 0.02), Vector2(0.18, 0.06), Vector2(0.15, 0.085), Vector2(0.0, 0.085)])), steel, beacon_at)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.15, 0.025), Vector2(0.0, 0.025)])), brass, beacon_at + Vector3(0.0, 0.085, 0.0))
	var red: StandardMaterial3D = DesignKit.washi(Color(0.87, 0.055, 0.035), 1.7, "koban_red_beacon")
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.135, 0.0), Vector2(0.135, 0.15), Vector2(0.125, 0.205), Vector2(0.09, 0.25), Vector2(0.045, 0.275), Vector2(0.0, 0.285)])), red, beacon_at + Vector3(0.0, 0.11, 0.0))
	return root


static func _caption(parent: Node3D, caption: String, at: Vector3, size: int, width: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.pixel_size = 0.003
	var measured: float = Signage.font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	label.font_size = mini(size, int(float(size) * width / maxf(measured, 0.001)))
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
