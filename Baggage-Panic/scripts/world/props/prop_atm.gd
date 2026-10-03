extends RefCounted
## Freestanding exchange ATM; all geometry is in metres and faces +Z.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ATM_CurrencyExchange"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "oak")
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.65, "atm_charcoal")
	var dark: StandardMaterial3D = DesignKit.paint(Color(0.035, 0.042, 0.039), 0.38)
	var brass: StandardMaterial3D = DesignKit.brass()
	var stone: StandardMaterial3D = DesignKit.stone()
	var glow: StandardMaterial3D = DesignKit.washi(Color(0.72, 0.87, 0.72), 1.3, "atm_status")
	var screen: StandardMaterial3D = DesignKit.washi(Color(0.055, 0.13, 0.12).lerp(accent.darkened(0.65), 0.25), 0.85, "atm_screen_%d" % choice)

	# Honed stone footing and an inset kick reveal keep the wood off the floor.
	DesignKit.rbox(root, Vector3(1.76, 0.12, 0.88), Vector3(0.0, 0.06, 0.0), stone, 0.05)
	DesignKit.rbox(root, Vector3(1.48, 0.10, 0.66), Vector3(0.0, 0.17, 0.0), dark, 0.025)
	DesignKit.rbox(root, Vector3(1.52, 2.06, 0.72), Vector3(0.0, 1.25, 0.0), steel, 0.10)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.105, 2.04, 0.76), Vector3(side * 0.80, 1.25, -0.015), oak, 0.047)
		DesignKit.rbox(root, Vector3(0.018, 1.88, 0.018), Vector3(side * 0.733, 1.25, 0.368), brass, 0.006)
		# A darker inset on the rear edge reads as a joinery / service seam.
		DesignKit.rbox(root, Vector3(0.012, 1.84, 0.018), Vector3(side * 0.854, 1.25, -0.26), dark, 0.005)

	# Large, sheltered portrait display: brass rim, black bezel, luminous glass.
	DesignKit.rbox(root, Vector3(1.42, 1.14, 0.075), Vector3(0.0, 1.63, 0.371), brass, 0.048)
	DesignKit.rbox(root, Vector3(1.39, 1.11, 0.064), Vector3(0.0, 1.63, 0.400), dark, 0.043)
	DesignKit.rbox(root, Vector3(1.29, 1.01, 0.018), Vector3(0.0, 1.63, 0.438), screen, 0.033, false)
	_text(root, "EXCHANGE", Vector3(0.0, 2.024, 0.451), 0.125, DesignKit.CREAM)
	DesignKit.rbox(root, Vector3(1.10, 0.012, 0.008), Vector3(0.0, 1.917, 0.452), brass, 0.003, false)
	# Illustrative display values, expressed per USD; intentionally not live rates.
	var rates: Array[String] = ["USD   1.00", "JPY   150.0", "VND   25 000", "EUR   0.92", "CNY   7.20"]
	if choice == 1:
		rates[1] = "JPY   149.5"
	elif choice == 2:
		rates[3] = "EUR   0.93"
	elif choice == 3:
		rates[4] = "CNY   7.18"
	for row: int in range(rates.size()):
		var caption: String = rates[row]
		_text(root, caption, Vector3(0.0, 1.804 - float(row) * 0.147, 0.453), 0.141, DesignKit.CREAM)

	# The console slopes toward the user, with a protective metal keypad surround.
	var console: MeshInstance3D = DesignKit.rbox(root, Vector3(1.39, 0.11, 0.36), Vector3(0.0, 1.028, 0.48), steel, 0.045)
	console.rotation_degrees.x = -12.0
	var keypad: Node3D = Node3D.new()
	keypad.name = "RecessedKeypad"
	keypad.position = Vector3(-0.26, 1.094, 0.48)
	keypad.rotation_degrees.x = -12.0
	root.add_child(keypad)
	DesignKit.rbox(keypad, Vector3(0.32, 0.02, 0.26), Vector3.ZERO, dark, 0.025)
	for row: int in range(4):
		for column: int in range(3):
			var key_mat: StandardMaterial3D = DesignKit.metal(DesignKit.LINEN, 0.45, 0.6, "atm_key_caps")
			if row == 3 and column == 2:
				key_mat = DesignKit.paint(accent)
			DesignKit.rbox(keypad, Vector3(0.072, 0.014, 0.043), Vector3(float(column - 1) * 0.091, 0.017, float(row) * 0.055 - 0.0825), key_mat, 0.008, false)
	DesignKit.rbox(root, Vector3(0.34, 0.13, 0.055), Vector3(0.39, 1.075, 0.661), brass, 0.025)
	DesignKit.rbox(root, Vector3(0.26, 0.023, 0.012), Vector3(0.39, 1.072, 0.695), dark, 0.009, false)
	DesignKit.rbox(root, Vector3(0.20, 0.009, 0.008), Vector3(0.39, 1.105, 0.696), glow, 0.003, false)

	# Cash shutter with an overhanging lip; lower service door has a real reveal.
	DesignKit.rbox(root, Vector3(1.23, 0.58, 0.025), Vector3(0.0, 0.60, 0.368), dark, 0.035)
	DesignKit.rbox(root, Vector3(1.19, 0.54, 0.027), Vector3(0.0, 0.60, 0.384), steel, 0.032)
	DesignKit.rbox(root, Vector3(0.65, 0.16, 0.055), Vector3(0.0, 0.756, 0.415), brass, 0.024)
	DesignKit.rbox(root, Vector3(0.55, 0.085, 0.015), Vector3(0.0, 0.753, 0.447), dark, 0.018)
	DesignKit.rbox(root, Vector3(0.57, 0.018, 0.062), Vector3(0.0, 0.802, 0.471), steel, 0.008)
	DesignKit.rbox(root, Vector3(0.26, 0.021, 0.012), Vector3(0.0, 0.455, 0.407), brass, 0.007)
	var lock_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.019, 0.0), Vector2(0.019, 0.009), Vector2(0.015, 0.014), Vector2(0.0, 0.014)])
	DesignKit.add(root, DesignKit.lathe(lock_profile, 16), brass, Vector3(0.48, 0.49, 0.403), Vector3(90.0, 0.0, 0.0), false)

	# Broad oak-edged header is integral to the kiosk, with all six languages.
	DesignKit.rbox(root, Vector3(2.14, 0.77, 0.23), Vector3(0.0, 2.56, -0.02), oak, 0.075)
	DesignKit.rbox(root, Vector3(2.04, 0.67, 0.036), Vector3(0.0, 2.56, 0.107), steel, 0.045)
	DesignKit.rbox(root, Vector3(1.84, 0.018, 0.016), Vector3(0.0, 2.845, 0.132), DesignKit.washi(DesignKit.CREAM, 1.5, "atm_header_light"), 0.006, false)
	_text(root, "ATM / EXCHANGE", Vector3(0.0, 2.738, 0.132), 0.181, DesignKit.CREAM)
	_text(root, "両替 · 货币兑换", Vector3(0.0, 2.572, 0.132), 0.132, DesignKit.CREAM)
	_text(root, "Đổi tiền", Vector3(0.0, 2.439, 0.132), 0.121, accent.lightened(0.38))
	_text(root, "Change · Cambio", Vector3(0.0, 2.313, 0.132), 0.121, DesignKit.CREAM)
	return root


static func _text(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 64
	label.pixel_size = height / 64.0
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
