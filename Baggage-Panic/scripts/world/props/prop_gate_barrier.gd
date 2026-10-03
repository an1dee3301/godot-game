extends RefCounted
## Three boarding lanes; the right-hand lane has a wider accessible opening.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AutomaticBoardingGates"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var timber: StandardMaterial3D = DesignKit.wood(DesignKit.OAK if style % 2 == 0 else DesignKit.WALNUT, "gate_oak" if style % 2 == 0 else "gate_walnut")
	var accent_colors: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.LINEN, DesignKit.INDIGO]
	var accent: StandardMaterial3D = DesignKit.paint(accent_colors[style])
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.75, "gate_charcoal")
	var dark: StandardMaterial3D = DesignKit.paint(Color(0.035, 0.045, 0.045), 0.24)
	var stone: StandardMaterial3D = DesignKit.stone()
	var glass: StandardMaterial3D = _glass(style)
	var green: StandardMaterial3D = DesignKit.washi(Color(0.16, 0.9, 0.5), 1.8, "gate_ready")
	var red: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.22, 0.15), 1.8, "gate_closed")
	var xs: Array[float] = [-1.95, -0.72, 0.51, 1.99]
	for index in xs.size():
		var x: float = xs[index]
		# Honed stone shoes, recessed metal plinths and rounded equipment housings.
		DesignKit.rbox(root, Vector3(0.34, 0.065, 1.48), Vector3(x, 0.0325, 0.0), stone, 0.027)
		DesignKit.rbox(root, Vector3(0.25, 0.08, 1.33), Vector3(x, 0.105, 0.0), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.30, 0.91, 1.39), Vector3(x, 0.59, 0.0), steel, 0.10)
		DesignKit.rbox(root, Vector3(0.307, 0.022, 1.35), Vector3(x, 1.048, 0.0), DesignKit.brass(), 0.01, false)
		DesignKit.rbox(root, Vector3(0.32, 0.065, 1.41), Vector3(x, 1.0915, 0.0), timber, 0.031)
		# Removable service face with a reveal around the softly inset panel.
		DesignKit.rbox(root, Vector3(0.205, 0.67, 0.018), Vector3(x, 0.60, 0.697), dark, 0.025, false)
		DesignKit.rbox(root, Vector3(0.185, 0.645, 0.018), Vector3(x, 0.60, 0.708), accent, 0.025, false)
		DesignKit.rbox(root, Vector3(0.055, 0.014, 0.014), Vector3(x, 0.82, 0.724), DesignKit.brass(), 0.005, false)
		# Sensor windows along the lane-facing surfaces.
		for side: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.013, 0.10, 0.29), Vector3(x + side * 0.15, 0.73, 0.37), dark, 0.006, false)
		if index < 3:
			var stopped: bool = posmod(index + style, 3) == 2
			var light: StandardMaterial3D = red if stopped else green
			# Sloped scanner: black optical glass sits inside a brass bezel.
			var bezel: MeshInstance3D = DesignKit.rbox(root, Vector3(0.235, 0.045, 0.29), Vector3(x, 1.142, 0.39), DesignKit.brass(), 0.021)
			bezel.rotation_degrees.x = 18.0
			var reader: MeshInstance3D = DesignKit.rbox(root, Vector3(0.209, 0.013, 0.264), Vector3(x, 1.167, 0.398), dark, 0.006, false)
			reader.rotation_degrees.x = 18.0
			DesignKit.rbox(root, Vector3(0.16, 0.016, 0.033), Vector3(x, 1.17, 0.55), light, 0.007, false)
			DesignKit.rbox(root, Vector3(0.23, 0.25, 0.019), Vector3(x, 0.95, 0.696), dark, 0.025, false)
			_status(root, Vector3(x, 0.95, 0.709), stopped, light)
	for lane in 3:
		var left: float = xs[lane] + 0.15
		var right: float = xs[lane + 1] - 0.15
		var leaf_width: float = (right - left) * 0.5 - 0.012
		var opened: bool = posmod(lane + style, 4) == 1
		for side: float in [-1.0, 1.0]:
			var hinge_x: float = left if side > 0.0 else right
			var hinge: Node3D = Node3D.new()
			hinge.name = "Lane%dGlassFlap" % (lane + 1)
			hinge.position = Vector3(hinge_x, 0.0, -0.12)
			hinge.rotation_degrees.y = side * 68.0 if opened else 0.0
			root.add_child(hinge)
			DesignKit.rbox(hinge, Vector3(0.045, 0.70, 0.075), Vector3.ZERO + Vector3(0.0, 0.67, 0.0), steel, 0.021)
			DesignKit.rbox(hinge, Vector3(leaf_width, 0.77, 0.018), Vector3(side * leaf_width * 0.5, 0.715, 0.0), glass, 0.008, false)
			# A pale ceramic frit band makes the transparent barrier perceptible.
			DesignKit.rbox(hinge, Vector3(leaf_width - 0.025, 0.033, 0.020), Vector3(side * leaf_width * 0.5, 0.88, 0.0), DesignKit.paint(DesignKit.CREAM), 0.009, false)
			DesignKit.rbox(hinge, Vector3(0.012, 0.72, 0.022), Vector3(side * (leaf_width - 0.007), 0.715, 0.0), DesignKit.metal(Color(0.39, 0.58, 0.54), 0.25, 0.25, "gate_glass_edge"), 0.005, false)
	# A self-supported lintel leaves generous head clearance above every lane.
	for x: float in [xs[0], xs[3]]:
		DesignKit.rbox(root, Vector3(0.075, 1.43, 0.075), Vector3(x, 1.825, -0.52), steel, 0.025)
	DesignKit.rbox(root, Vector3(4.30, 1.23, 0.13), Vector3(0.02, 3.16, -0.52), timber, 0.06)
	DesignKit.rbox(root, Vector3(4.17, 1.10, 0.024), Vector3(0.02, 3.16, -0.442), DesignKit.washi(DesignKit.CREAM, 0.65, "gate_sign_washi"), 0.011, false)
	var gate_words: Array = Signage.TEXT["gate"]
	_label(root, "%s A%d" % [str(gate_words[0]), 12 + style], Vector3(0.02, 3.48, -0.421), 128)
	_label(root, "%s  ·  %s" % [str(gate_words[1]), str(gate_words[2])], Vector3(0.02, 3.15, -0.421), 88)
	_label(root, "%s  ·  %s  ·  %s" % [str(gate_words[3]), str(gate_words[4]), str(gate_words[5])], Vector3(0.02, 2.83, -0.421), 80)
	return root


static func _glass(style: int) -> StandardMaterial3D:
	var key: String = "glass%d" % (style % 2)
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.63, 0.82, 0.78, 0.32) if style % 2 == 0 else Color(0.76, 0.83, 0.81, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.14
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _status(parent: Node3D, at: Vector3, stopped: bool, material: StandardMaterial3D) -> void:
	if stopped:
		for angle: float in [-45.0, 45.0]:
			var stroke: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.025, 0.17, 0.012), at, material, 0.005, false)
			stroke.rotation_degrees.z = angle
	else:
		DesignKit.rbox(parent, Vector3(0.027, 0.135, 0.012), at + Vector3(0.0, -0.015, 0.0), material, 0.005, false)
		for side: float in [-1.0, 1.0]:
			var stroke: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.025, 0.092, 0.012), at + Vector3(side * 0.031, 0.031, 0.0), material, 0.005, false)
			stroke.rotation_degrees.z = side * 45.0


static func _label(parent: Node3D, caption: String, at: Vector3, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
