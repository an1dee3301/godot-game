extends RefCounted
## INTENDED_SCALE = 5.5
## Shell: 40 x 12 metres after integration scaling. Apron faces +Z; root stays at scale 1.
## All dimensions below are authored compactly, including joinery and lettering.

static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CargoTerminal"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colors: Array[Color] = [Color(0.94, 0.72, 0.22), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var operator_color: Color = colors[scheme]
	var stripe_color: Color = DesignKit.CLAY if scheme == 1 else DesignKit.OCHRE
	var shell: StandardMaterial3D = DesignKit.stone(DesignKit.PLASTER, 0.75, "cargo_plaster")
	var stone: StandardMaterial3D = DesignKit.stone()
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var paint: StandardMaterial3D = DesignKit.paint(operator_color)
	var accent: StandardMaterial3D = DesignKit.paint(stripe_color)
	var glow: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.4, "cargo_canopy_glow")
	var amber: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.49, 0.12), 2.4, "cargo_beacon")
	# Ground-contact plinth, inset plaster shell, oak eaves and a gently stepped roof.
	DesignKit.rbox(root, Vector3(7.2727, 0.16, 2.1818), Vector3(0.0, 0.08, 0.0), stone, 0.055)
	DesignKit.rbox(root, Vector3(7.20, 2.00, 2.10), Vector3(0.0, 1.14, 0.0), shell, 0.065)
	DesignKit.rbox(root, Vector3(7.56, 0.12, 2.42), Vector3(0.0, 2.17, 0.02), walnut, 0.045)
	DesignKit.rbox(root, Vector3(7.46, 0.10, 2.33), Vector3(0.0, 2.27, 0.0), steel, 0.035)
	DesignKit.rbox(root, Vector3(6.98, 0.09, 1.95), Vector3(0.0, 2.35, -0.06), stone, 0.035)
	# Continuous clerestory, framed in wood; repeated fins are one draw call.
	DesignKit.rbox(root, Vector3(6.95, 0.28, 0.055), Vector3(0.0, 1.94, 1.067), DesignKit.paint(DesignKit.INDIGO.darkened(0.35), 0.23), 0.012)
	var fins: Array[Transform3D] = []
	for i in 49:
		fins.append(Transform3D(Basis.IDENTITY, Vector3(-3.36 + float(i) * 0.14, 1.94, 1.11)))
	_repeat(root, Vector3(0.025, 0.30, 0.09), oak, fins, 0.009)
	DesignKit.rbox(root, Vector3(7.04, 0.035, 0.07), Vector3(0.0, 1.775, 1.09), brass, 0.009)
	# Front canopy has a warm luminous underside and four tapered-look columns.
	DesignKit.rbox(root, Vector3(5.78, 0.10, 0.92), Vector3(0.0, 1.58, 1.47), walnut, 0.035)
	DesignKit.rbox(root, Vector3(5.52, 0.027, 0.68), Vector3(0.0, 1.515, 1.47), glow, 0.011, false)
	for x: float in [-2.67, -0.89, 0.89, 2.67]:
		DesignKit.rbox(root, Vector3(0.065, 1.45, 0.08), Vector3(x, 0.77, 1.80), steel, 0.018)
		DesignKit.rbox(root, Vector3(0.12, 0.10, 0.13), Vector3(x, 0.05, 1.80), stone, 0.02)
	# Three loading bays; centre door is raised to reveal freight in a shadowed opening.
	for bay in 3:
		var x: float = -1.78 + float(bay) * 1.78
		_dock(root, x, bay, paint, steel, stone, brass, amber)
	# Four stacked intermodal containers sit on either side of the clear approach lanes.
	for side: float in [-1.0, 1.0]:
		for level in 2:
			var container_material: StandardMaterial3D = paint if level == 0 else DesignKit.paint(DesignKit.CLAY if scheme != 1 else DesignKit.SAGE)
			_container(root, Vector3(side * 3.10, 0.04 + float(level) * 0.47, 2.32), container_material, accent, steel, brass)
	# Large multilingual cargo lettering: six languages, three generously spaced lines.
	DesignKit.rbox(root, Vector3(4.80, 0.70, 0.08), Vector3(0.0, 2.77, 0.58), steel, 0.035)
	DesignKit.rbox(root, Vector3(4.61, 0.02, 0.015), Vector3(0.0, 3.06, 0.628), brass, 0.006, false)
	_label(root, "CARGO TERMINAL", Vector3(0.0, 2.94, 0.632), 0.0035, 80, DesignKit.CREAM)
	_label(root, "貨物ターミナル  ·  货运站", Vector3(0.0, 2.72, 0.632), 0.0030, 60, DesignKit.CREAM)
	_label(root, "Ga hàng hóa  ·  Fret  ·  Carga", Vector3(0.0, 2.51, 0.632), 0.0030, 60, DesignKit.CREAM)
	for x: float in [-1.9, 1.9]:
		DesignKit.rbox(root, Vector3(0.045, 0.35, 0.045), Vector3(x, 2.44, 0.58), steel, 0.011)
	# Shared international apron sign and a linen-textured staff entrance at the left end.
	Signage.panel(root, Vector3(-3.12, 1.24, 1.13), "apron", {"width": 3.1, "scale": 0.27, "accent": operator_color})
	DesignKit.rbox(root, Vector3(0.54, 0.68, 0.07), Vector3(3.12, 0.62, 1.09), walnut, 0.025)
	DesignKit.rbox(root, Vector3(0.44, 0.58, 0.035), Vector3(3.12, 0.62, 1.135), DesignKit.fabric(), 0.016)
	DesignKit.rbox(root, Vector3(0.02, 0.16, 0.025), Vector3(3.28, 0.63, 1.16), brass, 0.008)
	# Warm warning beacons on roof corners; lathed domes with black bases.
	var dome: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.045, 0.07), Vector2(0.032, 0.095), Vector2(0.0, 0.105)]), 12)
	for x: float in [-3.43, 3.43]:
		DesignKit.rbox(root, Vector3(0.13, 0.045, 0.13), Vector3(x, 2.425, 0.72), steel, 0.015)
		DesignKit.add(root, dome, amber, Vector3(x, 2.448, 0.72), Vector3.ZERO, false)
	return root


static func _dock(parent: Node3D, x: float, bay: int, paint: Material, steel: Material, stone: Material, brass: Material, amber: Material) -> void:
	DesignKit.rbox(parent, Vector3(1.42, 1.04, 0.12), Vector3(x, 0.86, 1.10), steel, 0.035)
	var door_height: float = 0.21 if bay == 1 else 0.80
	var door_y: float = 1.24 if bay == 1 else 0.88
	DesignKit.rbox(parent, Vector3(1.19, door_height, 0.055), Vector3(x, door_y, 1.175), paint, 0.016)
	var slats: Array[Transform3D] = []
	var slat_count: int = 3 if bay == 1 else 10
	for i in slat_count:
		slats.append(Transform3D(Basis.IDENTITY, Vector3(x, door_y - door_height * 0.5 + 0.045 + float(i) * 0.075, 1.21)))
	_repeat(parent, Vector3(1.14, 0.013, 0.012), brass, slats, 0.004)
	DesignKit.rbox(parent, Vector3(1.40, 0.21, 0.60), Vector3(x, 0.255, 1.38), stone, 0.027)
	DesignKit.rbox(parent, Vector3(1.18, 0.035, 0.45), Vector3(x, 0.38, 1.43), steel, 0.012)
	for offset: float in [-0.56, 0.56]:
		DesignKit.rbox(parent, Vector3(0.105, 0.22, 0.105), Vector3(x + offset, 0.26, 1.715), DesignKit.fabric(DesignKit.CHARCOAL, "cargo_dock_rubber"), 0.024)
	DesignKit.rbox(parent, Vector3(0.09, 0.05, 0.04), Vector3(x + 0.72, 1.15, 1.17), amber, 0.014, false)
	_label(parent, "%02d" % (bay + 1), Vector3(x, 1.39, 1.178), 0.003, 58, DesignKit.CREAM)
	if bay == 1:
		DesignKit.rbox(parent, Vector3(0.68, 0.40, 0.12), Vector3(x + 0.16, 0.65, 1.175), DesignKit.paint(DesignKit.CLAY), 0.032)
		DesignKit.rbox(parent, Vector3(0.04, 0.38, 0.018), Vector3(x + 0.16, 0.65, 1.245), DesignKit.fabric(), 0.008)


static func _container(parent: Node3D, at: Vector3, paint: Material, accent: Material, steel: Material, brass: Material) -> void:
	# 5 x 8 x 2.5 m compact freight boxes at intended scale, with cast corner fittings.
	DesignKit.rbox(parent, Vector3(0.89, 0.43, 1.48), at + Vector3(0.0, 0.245, 0.0), paint, 0.026)
	DesignKit.rbox(parent, Vector3(0.90, 0.05, 1.49), at + Vector3(0.0, 0.045, 0.0), steel, 0.012)
	DesignKit.rbox(parent, Vector3(0.90, 0.035, 1.49), at + Vector3(0.0, 0.449, 0.0), accent, 0.011)
	var ribs: Array[Transform3D] = []
	for i in 13:
		var z: float = at.z - 0.65 + float(i) * 0.108
		for side: float in [-1.0, 1.0]:
			ribs.append(Transform3D(Basis.IDENTITY, Vector3(at.x + side * 0.449, at.y + 0.25, z)))
	_repeat(parent, Vector3(0.025, 0.35, 0.035), paint, ribs, 0.009)
	DesignKit.rbox(parent, Vector3(0.025, 0.38, 0.025), at + Vector3(0.0, 0.245, 0.748), steel, 0.007)
	for x: float in [-0.22, 0.22]:
		DesignKit.rbox(parent, Vector3(0.016, 0.34, 0.018), at + Vector3(x, 0.245, 0.752), brass, 0.006)
		DesignKit.rbox(parent, Vector3(0.105, 0.022, 0.028), at + Vector3(x + 0.035, 0.18, 0.768), steel, 0.007)
	var corners: Array[Transform3D] = []
	for x: float in [-0.42, 0.42]:
		for z: float in [-0.71, 0.71]:
			for y: float in [0.04, 0.44]:
				corners.append(Transform3D(Basis.IDENTITY, at + Vector3(x, y, z)))
	_repeat(parent, Vector3(0.085, 0.075, 0.085), steel, corners, 0.013)


static func _repeat(parent: Node3D, size: Vector3, material: Material, placements: Array[Transform3D], radius: float) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = DesignKit.rounded_box(size, radius, 2)
	instances.instance_count = placements.size()
	for i in placements.size():
		instances.set_instance_transform(i, placements[i])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = instances
	node.material_override = material
	parent.add_child(node)


static func _label(parent: Node3D, caption: String, at: Vector3, pixel_size: float, font_size: int, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.position = at
	label.pixel_size = pixel_size
	label.font_size = font_size
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
