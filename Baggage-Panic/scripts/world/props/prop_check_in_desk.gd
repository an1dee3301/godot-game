extends RefCounted
## Two staffed check-in positions, with independent weighing conveyors and a lit canopy.

static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CheckInDeskPair"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var choice: int = posmod(variant, 4)
	var accent: Color = accents[choice]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var stone: StandardMaterial3D = DesignKit.stone()
	var brass: StandardMaterial3D = DesignKit.brass()
	var rubber: StandardMaterial3D = DesignKit.paint(Color(0.075, 0.085, 0.08), 0.95)
	var screen: StandardMaterial3D = DesignKit.washi(Color(0.13, 0.22, 0.23), 0.45, "check_in_screen")
	for station in 2:
		var center: float = -1.45 + float(station) * 2.9
		var desk_x: float = center - 0.43
		var belt_x: float = center + 0.82
		# Recessed dark toe kick, honed stone carcass and a radiused solid oak worktop.
		DesignKit.rbox(root, Vector3(1.48, 0.12, 0.79), Vector3(desk_x, 0.06, -0.08), steel, 0.035)
		DesignKit.rbox(root, Vector3(1.59, 0.86, 0.88), Vector3(desk_x, 0.55, -0.08), stone, 0.085)
		DesignKit.rbox(root, Vector3(1.74, 0.085, 1.07), Vector3(desk_x, 1.0225, -0.035), oak, 0.04)
		DesignKit.rbox(root, Vector3(1.57, 0.022, 0.035), Vector3(desk_x, 0.968, 0.389), brass, 0.008, false)
		# Fluted joinery: walnut shadow gaps behind broad, individually rounded oak battens.
		DesignKit.rbox(root, Vector3(1.43, 0.69, 0.045), Vector3(desk_x, 0.565, 0.368), walnut, 0.02)
		for rib in 9:
			var rib_x: float = desk_x - 0.64 + float(rib) * 0.16
			DesignKit.rbox(root, Vector3(0.135, 0.67, 0.062), Vector3(rib_x, 0.565, 0.402), oak, 0.025)
		# Large position marker inset in a textile-toned customer fascia.
		DesignKit.rbox(root, Vector3(0.47, 0.44, 0.04), Vector3(desk_x, 0.63, 0.449), DesignKit.fabric(accent, "check_in_%d" % choice), 0.055)
		_label(root, "%02d" % (choice * 2 + station + 1), Vector3(desk_x, 0.63, 0.474), 0.26, DesignKit.CREAM)
		# Agent-side cabinet seam and brass pull; the staff work surface remains usable.
		DesignKit.rbox(root, Vector3(1.36, 0.56, 0.025), Vector3(desk_x, 0.58, -0.531), oak, 0.018)
		DesignKit.rbox(root, Vector3(0.012, 0.51, 0.014), Vector3(desk_x, 0.58, -0.549), walnut, 0.004)
		DesignKit.rbox(root, Vector3(0.22, 0.025, 0.03), Vector3(desk_x + 0.29, 0.77, -0.56), brass, 0.01)
		# Passenger-facing monitor, pedestal, status lamp and an understated screen graphic.
		DesignKit.rbox(root, Vector3(0.29, 0.025, 0.2), Vector3(desk_x, 1.078, -0.19), steel, 0.012)
		DesignKit.rbox(root, Vector3(0.055, 0.23, 0.055), Vector3(desk_x, 1.19, -0.24), steel, 0.015)
		DesignKit.rbox(root, Vector3(0.61, 0.38, 0.055), Vector3(desk_x, 1.41, -0.225), steel, 0.032)
		DesignKit.rbox(root, Vector3(0.554, 0.322, 0.009), Vector3(desk_x, 1.413, -0.193), screen, 0.016, false)
		DesignKit.rbox(root, Vector3(0.39, 0.023, 0.005), Vector3(desk_x, 1.455, -0.186), DesignKit.paint(DesignKit.CREAM), 0.008, false)
		DesignKit.rbox(root, Vector3(0.23, 0.013, 0.005), Vector3(desk_x - 0.08, 1.398, -0.186), DesignKit.paint(accent.lightened(0.25)), 0.005, false)
		DesignKit.rbox(root, Vector3(0.15, 0.044, 0.006), Vector3(desk_x, 1.328, -0.186), DesignKit.washi(accent, 0.55, "check_in_button_%d" % choice), 0.014, false)
		# Low scale conveyor extends toward +Z for loading, with protected rounded side rails.
		DesignKit.rbox(root, Vector3(0.72, 0.12, 1.66), Vector3(belt_x, 0.06, 0.17), steel, 0.04)
		DesignKit.rbox(root, Vector3(0.84, 0.29, 1.9), Vector3(belt_x, 0.265, 0.17), stone, 0.065)
		DesignKit.rbox(root, Vector3(0.72, 0.09, 1.8), Vector3(belt_x, 0.44, 0.17), steel, 0.043)
		DesignKit.rbox(root, Vector3(0.61, 0.035, 1.72), Vector3(belt_x, 0.4925, 0.17), rubber, 0.016)
		for edge: float in [-1.0, 1.0]:
			DesignKit.rbox(root, Vector3(0.064, 0.08, 1.79), Vector3(belt_x + edge * 0.365, 0.48, 0.17), brass, 0.026)
		# Repeated belt tread is one instanced draw, rather than dozens of child nodes.
		var treads: MultiMesh = MultiMesh.new()
		treads.transform_format = MultiMesh.TRANSFORM_3D
		treads.mesh = DesignKit.rounded_box(Vector3(0.58, 0.009, 0.018), 0.003)
		treads.instance_count = 13
		for tread in 13:
			treads.set_instance_transform(tread, Transform3D(Basis.IDENTITY, Vector3(belt_x, 0.514, -0.59 + float(tread) * 0.125)))
		var tread_node: MultiMeshInstance3D = MultiMeshInstance3D.new()
		tread_node.multimesh = treads
		tread_node.material_override = DesignKit.paint(Color(0.16, 0.17, 0.15), 0.9)
		root.add_child(tread_node)
		# Scale readout is a physical angled-free housing; no illegibly small text.
		DesignKit.rbox(root, Vector3(0.28, 0.15, 0.07), Vector3(belt_x, 0.32, 1.153), steel, 0.022)
		DesignKit.rbox(root, Vector3(0.23, 0.1, 0.009), Vector3(belt_x, 0.32, 1.194), screen, 0.012, false)
		DesignKit.rbox(root, Vector3(0.12, 0.018, 0.005), Vector3(belt_x, 0.32, 1.202), DesignKit.washi(DesignKit.SAGE, 0.7, "check_in_scale"), 0.005, false)
	# A self-supported airline canopy: slender uprights sit behind the staff positions.
	for x: float in [-2.65, 2.65]:
		DesignKit.rbox(root, Vector3(0.27, 0.035, 0.3), Vector3(x, 0.0175, -0.61), steel, 0.016)
		DesignKit.rbox(root, Vector3(0.075, 2.71, 0.075), Vector3(x, 1.39, -0.61), steel, 0.022)
		DesignKit.rbox(root, Vector3(0.095, 0.16, 0.095), Vector3(x, 2.63, -0.61), brass, 0.02)
	DesignKit.rbox(root, Vector3(5.85, 1.65, 0.2), Vector3(0.0, 3.36, -0.61), walnut, 0.09)
	DesignKit.rbox(root, Vector3(5.68, 1.48, 0.022), Vector3(0.0, 3.36, -0.499), DesignKit.washi(DesignKit.CREAM, 0.8, "check_in_canopy"), 0.06, false)
	DesignKit.rbox(root, Vector3(5.44, 0.027, 0.016), Vector3(0.0, 3.94, -0.476), DesignKit.paint(accent), 0.009, false)
	_label(root, "Check-in", Vector3(0.0, 3.73, -0.475), 0.42, DesignKit.CHARCOAL)
	_label(root, "チェックイン　·　值机", Vector3(0.0, 3.34, -0.475), 0.245, DesignKit.CHARCOAL)
	var translated: Array = Signage.TEXT["self_check_in"]
	var vietnamese: String = str(translated[3])
	var french: String = str(translated[4])
	var spanish: String = str(translated[5])
	_label(root, vietnamese, Vector3(0.0, 3.06, -0.475), 0.21, DesignKit.CHARCOAL)
	_label(root, french + "  ·  " + spanish, Vector3(0.0, 2.8, -0.475), 0.21, DesignKit.CHARCOAL)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, ink: Color) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 100
	label.pixel_size = height / 100.0
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
	return label
