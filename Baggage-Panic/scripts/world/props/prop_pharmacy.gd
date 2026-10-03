extends RefCounted
## A freestanding pharmacy: softly lit multilingual fascia over a stocked oak cabinet.


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PharmacyKiosk"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, Color(0.38, 0.53, 0.44), DesignKit.CLAY, DesignKit.INDIGO]
	var accent: Color = accents[choice]
	var timber: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut") if choice == 3 else DesignKit.wood()
	var white: StandardMaterial3D = DesignKit.stone(Color(0.96, 0.95, 0.90), 0.42, "pharmacy_white")
	var green: StandardMaterial3D = DesignKit.washi(Color(0.16, 0.55, 0.33), 1.15, "pharmacy_cross")
	var steel: StandardMaterial3D = DesignKit.metal()
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.55, "pharmacy_paper")
	var trim: StandardMaterial3D = DesignKit.paint(accent)

	# Raised cabinet on a recessed steel toe-kick; the origin remains exactly at floor level.
	DesignKit.rbox(root, Vector3(4.25, 0.12, 0.64), Vector3(0.0, 0.06, -0.81), steel, 0.04)
	DesignKit.rbox(root, Vector3(4.48, 2.20, 0.13), Vector3(0.0, 1.22, -1.08), timber, 0.06)
	DesignKit.rbox(root, Vector3(4.20, 1.30, 0.025), Vector3(0.0, 1.64, -1.002), DesignKit.fabric(DesignKit.LINEN, "pharmacy_linen"), 0.012, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.13, 2.27, 0.58), Vector3(side * 2.19, 1.255, -0.85), timber, 0.045)
		# Two lower storage doors and vertical brass pulls.
		DesignKit.rbox(root, Vector3(2.08, 0.76, 0.12), Vector3(side * 1.055, 0.53, -0.58), white, 0.035)
		DesignKit.rbox(root, Vector3(0.026, 0.24, 0.036), Vector3(side * 0.13, 0.63, -0.499), DesignKit.brass(), 0.012, false)
	DesignKit.rbox(root, Vector3(0.055, 1.37, 0.49), Vector3(0.0, 1.645, -0.80), timber, 0.02)
	for row: int in 3:
		var shelf_y: float = 0.98 + float(row) * 0.43
		DesignKit.rbox(root, Vector3(4.28, 0.065, 0.57), Vector3(0.0, shelf_y, -0.78), timber, 0.022)
		DesignKit.rbox(root, Vector3(4.14, 0.018, 0.022), Vector3(0.0, shelf_y + 0.07, -0.488), DesignKit.brass(), 0.008, false)
		DesignKit.rbox(root, Vector3(4.08, 0.015, 0.06), Vector3(0.0, shelf_y - 0.039, -0.62), paper, 0.006, false)
	_stock(root, choice, accent)

	# A white rounded service counter with a honed limestone cap and inset oak apron.
	DesignKit.rbox(root, Vector3(3.89, 0.10, 0.78), Vector3(0.0, 0.05, 0.63), steel, 0.035)
	DesignKit.rbox(root, Vector3(4.18, 0.94, 1.00), Vector3(0.0, 0.57, 0.63), white, 0.15)
	DesignKit.rbox(root, Vector3(4.35, 0.10, 1.13), Vector3(0.0, 1.09, 0.63), DesignKit.stone(), 0.048)
	DesignKit.rbox(root, Vector3(3.52, 0.46, 0.055), Vector3(0.0, 0.56, 1.122), timber, 0.026)
	for rib: int in 12:
		DesignKit.rbox(root, Vector3(0.023, 0.37, 0.014), Vector3(-1.57 + float(rib) * 0.285, 0.56, 1.155), DesignKit.wood(DesignKit.WALNUT, "walnut"), 0.006, false)
	DesignKit.rbox(root, Vector3(3.64, 0.022, 0.035), Vector3(0.0, 0.30, 1.12), DesignKit.brass(), 0.01, false)

	# Payment terminal: turned foot, tilted housing and an inset sage screen, without tiny text.
	var foot: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.12, 0.0), Vector2(0.12, 0.025),
		Vector2(0.07, 0.045), Vector2(0.045, 0.16), Vector2(0.0, 0.16)
	]))
	DesignKit.add(root, foot, steel, Vector3(1.38, 1.14, 0.52))
	var terminal: MeshInstance3D = DesignKit.rbox(root, Vector3(0.36, 0.26, 0.055), Vector3(1.38, 1.36, 0.55), steel, 0.022)
	terminal.rotation_degrees.x = -24.0
	DesignKit.rbox(terminal, Vector3(0.30, 0.17, 0.009), Vector3(0.0, 0.027, 0.032), DesignKit.washi(Color(0.61, 0.76, 0.67), 0.35, "pharmacy_screen"), 0.015, false)
	DesignKit.rbox(terminal, Vector3(0.10, 0.012, 0.008), Vector3(0.0, -0.092, 0.032), DesignKit.brass(), 0.004, false)
	# Shallow felt-lined dispensing tray; its lip is higher than the recessed liner.
	DesignKit.rbox(root, Vector3(0.64, 0.045, 0.38), Vector3(-1.28, 1.1625, 0.67), timber, 0.022)
	DesignKit.rbox(root, Vector3(0.56, 0.012, 0.30), Vector3(-1.28, 1.186, 0.67), DesignKit.fabric(accent, "pharmacy_tray_%d" % choice), 0.016, false)

	# Fascia supported by the cabinet, with a warm paper face and a green cross beacon.
	DesignKit.rbox(root, Vector3(4.60, 1.34, 0.24), Vector3(0.0, 2.98, -0.78), timber, 0.075)
	DesignKit.rbox(root, Vector3(4.44, 1.19, 0.034), Vector3(0.0, 2.98, -0.644), paper, 0.047, false)
	DesignKit.rbox(root, Vector3(4.28, 0.024, 0.025), Vector3(0.0, 2.437, -0.618), DesignKit.brass(), 0.009, false)
	DesignKit.rbox(root, Vector3(0.94, 0.94, 0.055), Vector3(-1.59, 2.98, -0.606), white, 0.14)
	_cross(root, Vector3(-1.59, 2.98, -0.56), 0.73, green)
	_text(root, "Pharmacy", Vector3(0.48, 3.31, -0.617), 0.0060, DesignKit.CHARCOAL)
	_text(root, "薬局  ·  药房", Vector3(0.48, 2.99, -0.617), 0.0040, DesignKit.CHARCOAL)
	_text(root, "Nhà thuốc", Vector3(0.48, 2.75, -0.617), 0.0037, DesignKit.CHARCOAL)
	_text(root, "Pharmacie  ·  Farmacia", Vector3(0.48, 2.52, -0.617), 0.0035, DesignKit.CHARCOAL)

	# Side blade cross makes the kiosk recognisable when approached along the terminal.
	var blade: Node3D = Node3D.new()
	blade.position = Vector3(2.31, 2.85, -0.28)
	blade.rotation_degrees.y = 90.0
	root.add_child(blade)
	DesignKit.rbox(blade, Vector3(0.77, 0.86, 0.09), Vector3.ZERO, trim, 0.09)
	for face: float in [-1.0, 1.0]:
		DesignKit.rbox(blade, Vector3(0.68, 0.77, 0.024), Vector3(0.0, 0.0, face * 0.052), paper, 0.075, false)
		_cross(blade, Vector3(0.0, 0.0, face * 0.079), 0.53, green)
	return root


static func _cross(parent: Node3D, at: Vector3, size: float, material: Material) -> void:
	DesignKit.rbox(parent, Vector3(size * 0.31, size, 0.035), at, material, 0.015, false)
	DesignKit.rbox(parent, Vector3(size, size * 0.31, 0.034), at + Vector3(0.0, 0.0, 0.001), material, 0.015, false)


static func _text(parent: Node3D, caption: String, at: Vector3, pixel_size: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 64
	label.pixel_size = pixel_size
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _stock(parent: Node3D, variant: int, accent: Color) -> void:
	# Three batches of cartons; bodies, broad colour bands and folded lid seams use nine nodes.
	var colors: Array[Color] = [DesignKit.CREAM, accent.lightened(0.35), Color(0.82, 0.87, 0.81)]
	for kind: int in 3:
		var height: float = 0.24 + float(kind) * 0.035
		var bodies: Array[Transform3D] = []
		var bands: Array[Transform3D] = []
		var seams: Array[Transform3D] = []
		for row: int in 3:
			for column: int in 8:
				if posmod(column + row + variant, 3) != kind:
					continue
				var center: Vector3 = Vector3(-1.85 + float(column) * 0.52, 1.0125 + float(row) * 0.43 + height * 0.5, -0.73)
				bodies.append(Transform3D(Basis.IDENTITY, center))
				bands.append(Transform3D(Basis.IDENTITY, center + Vector3(0.0, -height * 0.18, 0.101)))
				seams.append(Transform3D(Basis.IDENTITY, center + Vector3(0.0, height * 0.5 - 0.027, 0.102)))
		_batch(parent, DesignKit.rounded_box(Vector3(0.30, height, 0.20), 0.012), DesignKit.paint(colors[kind], 0.82), bodies)
		_batch(parent, DesignKit.rounded_box(Vector3(0.27, 0.07, 0.006), 0.002), DesignKit.paint(accent if kind != 1 else DesignKit.CREAM), bands)
		_batch(parent, DesignKit.rounded_box(Vector3(0.25, 0.006, 0.004), 0.001), DesignKit.paint(colors[kind].darkened(0.18)), seams)


static func _batch(parent: Node3D, mesh: Mesh, material: Material, placements: Array[Transform3D]) -> void:
	var instances: MultiMesh = MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = placements.size()
	for index: int in placements.size():
		instances.set_instance_transform(index, placements[index])
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = instances
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
