extends RefCounted
## Electric apron tug and three open, coupled baggage carts. Metres; travel is +Z.
## Repeated railwork, wheel profiles and luggage details share instanced draw calls.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BaggageTrain"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var schemes: Array[Color] = [Color(0.92, 0.69, 0.18), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var scheme: int = posmod(variant, 4)
	var body: Material = DesignKit.paint(schemes[scheme], 0.42)
	var accent: Material = DesignKit.brass() if scheme == 3 else DesignKit.paint(DesignKit.CLAY, 0.45)
	var steel: Material = DesignKit.metal(DesignKit.CHARCOAL, 0.5, 0.72, "baggage_train_frame")
	var groups: Dictionary = {}
	_tug(groups, body, accent, steel)
	for index: int in range(3):
		_cart(groups, Vector3(0.0, 0.0, -3.9 - float(index) * 3.2), index, body, accent, steel)
	_flush(root, groups)
	# The six large cart-side captions cover the airport's languages without tiny labels.
	var captions: Array[String] = ["BAGGAGE", "手荷物", "行李", "Hành lý", "Bagages", "Equipaje"]
	for index: int in range(3):
		for side: int in range(2):
			var direction: float = -1.0 if side == 0 else 1.0
			var label: Label3D = Label3D.new()
			label.text = captions[index * 2 + side]
			label.font = Signage.font()
			label.font_size = 128
			label.pixel_size = 0.0021
			label.modulate = DesignKit.CREAM
			label.outline_size = 0
			label.double_sided = false
			label.position = Vector3(direction * 0.973, 0.92, -3.9 - float(index) * 3.2)
			label.rotation_degrees.y = direction * 90.0
			label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(label)
	return root


static func _tug(groups: Dictionary, body: Material, accent: Material, steel: Material) -> void:
	var rubber: Material = DesignKit.paint(Color(0.065, 0.06, 0.055), 0.96)
	var upholstery: Material = DesignKit.fabric(DesignKit.WALNUT, "baggage_train_seat")
	var headlight: Material = DesignKit.washi(DesignKit.CREAM, 3.0, "baggage_train_headlight")
	var amber: Material = DesignKit.washi(Color(1.0, 0.49, 0.08), 2.8, "baggage_train_beacon")
	_box(groups, Vector3(1.7, 0.22, 3.05), Vector3(0.0, 0.49, 0.0), steel, 0.09)
	_box(groups, Vector3(1.64, 0.43, 2.9), Vector3(0.0, 0.77, 0.0), body, 0.14)
	# Rounded battery bonnet and low rear counterweight leave a visibly open driving bay.
	_box(groups, Vector3(1.57, 0.43, 1.13), Vector3(0.0, 1.13, 0.9), body, 0.18)
	_box(groups, Vector3(1.6, 0.42, 0.5), Vector3(0.0, 1.13, -1.24), body, 0.13)
	_box(groups, Vector3(1.81, 0.18, 0.19), Vector3(0.0, 0.57, 1.57), rubber, 0.07)
	_box(groups, Vector3(1.81, 0.18, 0.19), Vector3(0.0, 0.57, -1.57), rubber, 0.07)
	_box(groups, Vector3(0.2, 0.12, 0.4), Vector3(0.0, 0.42, -1.77), steel, 0.045)
	_box(groups, Vector3(0.07, 0.19, 0.07), Vector3(0.0, 0.47, -1.9), DesignKit.brass(), 0.025)
	_box(groups, Vector3(1.5, 0.1, 0.035), Vector3(0.0, 0.92, 1.459), accent, 0.016)
	for side: float in [-1.0, 1.0]:
		_box(groups, Vector3(0.035, 0.12, 2.65), Vector3(side * 0.826, 0.77, 0.0), accent, 0.013)
		_box(groups, Vector3(0.25, 0.1, 0.88), Vector3(side * 0.9, 0.53, -0.47), steel, 0.035)
		for axle: float in [-1.02, 1.02]:
			_wheel(groups, Vector3(side * 0.86, 0.39, axle), 0.39, 0.24, rubber, steel)
			_box(groups, Vector3(0.31, 0.13, 0.95), Vector3(side * 0.77, 0.85, axle), body, 0.06)
		_box(groups, Vector3(0.35, 0.23, 0.07), Vector3(side * 0.52, 1.11, 1.464), steel, 0.06)
		_box(groups, Vector3(0.26, 0.14, 0.035), Vector3(side * 0.52, 1.11, 1.509), headlight, 0.045)
		_box(groups, Vector3(0.11, 0.08, 0.045), Vector3(side * 0.72, 0.92, 1.475), amber, 0.025)
		# Four roll-cage uprights, with an unobstructed entry on each side.
		for z: float in [-1.15, 0.24]:
			_box(groups, Vector3(0.07, 1.27, 0.07), Vector3(side * 0.72, 1.68, z), steel, 0.025)
		_box(groups, Vector3(0.15, 0.23, 0.075), Vector3(side * 0.88, 1.93, 0.24), steel, 0.045)
		_box(groups, Vector3(0.13, 0.19, 0.026), Vector3(side * 0.88, 1.93, 0.285), _mirror(), 0.035)
	_box(groups, Vector3(1.8, 0.14, 1.79), Vector3(0.0, 2.34, -0.48), body, 0.067)
	_box(groups, Vector3(1.72, 0.035, 1.7), Vector3(0.0, 2.249, -0.48), DesignKit.paint(DesignKit.LINEN), 0.016)
	_box(groups, Vector3(1.44, 0.065, 0.065), Vector3(0.0, 1.47, 0.24), steel, 0.022)
	_box(groups, Vector3(1.37, 0.71, 0.015), Vector3(0.0, 1.88, 0.244), _glass(), 0.006)
	_box(groups, Vector3(0.025, 0.45, 0.035), Vector3(0.15, 1.76, 0.269), steel, 0.01, Vector3(0.0, 0.0, -22.0))
	_box(groups, Vector3(0.61, 0.15, 0.58), Vector3(0.0, 1.09, -0.57), upholstery, 0.07)
	_box(groups, Vector3(0.59, 0.56, 0.13), Vector3(0.0, 1.4, -0.86), upholstery, 0.065, Vector3(-9.0, 0.0, 0.0))
	_box(groups, Vector3(0.31, 0.27, 0.21), Vector3(0.0, 1.26, -0.02), steel, 0.065)
	var steering: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.19, -0.018), Vector2(0.22, -0.018), Vector2(0.235, 0.0), Vector2(0.22, 0.018), Vector2(0.19, 0.018), Vector2(0.19, -0.018)]), 24)
	_part(groups, steering, rubber, Vector3(0.0, 1.47, -0.04), Vector3(24.0, 0.0, 0.0))
	_box(groups, Vector3(0.4, 0.027, 0.04), Vector3(0.0, 1.47, -0.04), steel, 0.012, Vector3(24.0, 0.0, 0.0))
	_box(groups, Vector3(0.18, 0.065, 0.22), Vector3(0.49, 2.445, -0.8), steel, 0.027)
	var beacon: Mesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.11, 0.025), Vector2(0.095, 0.19), Vector2(0.065, 0.23), Vector2(0.0, 0.23)]), 20)
	_part(groups, beacon, amber, Vector3(0.49, 2.47, -0.8))
	# Broad grille slots: visible functional detail, without a small text plaque.
	for slot: int in range(5):
		_box(groups, Vector3(0.44, 0.024, 0.027), Vector3(0.0, 1.05 + float(slot) * 0.045, 1.472), steel, 0.01)


static func _cart(groups: Dictionary, center: Vector3, index: int, body: Material, accent: Material, steel: Material) -> void:
	var rubber: Material = DesignKit.paint(Color(0.065, 0.06, 0.055), 0.96)
	var deck: Material = DesignKit.wood(DesignKit.OAK.darkened(0.1), "baggage_train_deck")
	_box(groups, Vector3(1.82, 0.16, 2.55), center + Vector3(0.0, 0.55, 0.0), steel, 0.055)
	# Replaceable oak wear strips within the blackened steel chassis.
	for slat: int in range(5):
		_box(groups, Vector3(0.325, 0.07, 2.4), center + Vector3(-0.68 + float(slat) * 0.34, 0.665, 0.0), deck, 0.023)
	for side: float in [-1.0, 1.0]:
		_box(groups, Vector3(0.055, 0.34, 2.47), center + Vector3(side * 0.935, 0.92, 0.0), steel, 0.025)
		_box(groups, Vector3(0.07, 0.07, 2.55), center + Vector3(side * 0.94, 1.36, 0.0), body, 0.033)
		_box(groups, Vector3(0.025, 0.04, 2.36), center + Vector3(side * 0.972, 0.735, 0.0), accent, 0.012)
		for end: float in [-1.23, 1.23]:
			_box(groups, Vector3(0.075, 0.74, 0.075), center + Vector3(side * 0.94, 1.025, end), steel, 0.025)
		for axle: float in [-0.87, 0.87]:
			_wheel(groups, center + Vector3(side * 0.97, 0.29, axle), 0.29, 0.16, rubber, steel)
			_box(groups, Vector3(0.27, 0.085, 0.67), center + Vector3(side * 0.9, 0.68, axle), body, 0.04)
	for end: float in [-1.23, 1.23]:
		_box(groups, Vector3(1.87, 0.065, 0.065), center + Vector3(0.0, 1.36, end), steel, 0.027)
		_box(groups, Vector3(1.87, 0.065, 0.065), center + Vector3(0.0, 0.97, end), steel, 0.027)
	for axle: float in [-0.87, 0.87]:
		_box(groups, Vector3(1.93, 0.08, 0.08), center + Vector3(0.0, 0.3, axle), steel, 0.025)
	# A triangular drawbar connects each cart to the previous vehicle, at axle height.
	_bar(groups, center + Vector3(-0.42, 0.42, 1.23), center + Vector3(0.0, 0.42, 1.83), steel)
	_bar(groups, center + Vector3(0.42, 0.42, 1.23), center + Vector3(0.0, 0.42, 1.83), steel)
	_box(groups, Vector3(0.16, 0.12, 0.23), center + Vector3(0.0, 0.42, 1.91), steel, 0.05)
	_box(groups, Vector3(0.16, 0.12, 0.26), center + Vector3(0.0, 0.42, -1.36), steel, 0.05)
	for side: float in [-1.0, 1.0]:
		_box(groups, Vector3(0.14, 0.08, 0.025), center + Vector3(side * 0.78, 0.58, -1.29), DesignKit.washi(DesignKit.CLAY, 1.4, "baggage_train_tail"), 0.02)
	var colours: Array[Color] = [DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE, DesignKit.SAGE, DesignKit.CREAM, Color(0.28, 0.5, 0.49), Color(0.52, 0.24, 0.27), DesignKit.WALNUT]
	for row: int in range(3):
		for column: int in range(2):
			var bag_index: int = (index * 3 + row * 2 + column) % colours.size()
			_suitcase(groups, center + Vector3(-0.39 + float(column) * 0.78, 1.1, -0.77 + float(row) * 0.77), Vector3(0.64, 0.78, 0.58), colours[bag_index], Vector3.ZERO, steel)
	# Two crosswise cabin bags give the pile a staggered skyline rather than a solid block.
	for upper: int in range(2):
		var bag_index: int = (index * 2 + upper + 5) % colours.size()
		_suitcase(groups, center + Vector3(0.08, 1.69, -0.51 + float(upper) * 1.02), Vector3(0.78, 0.36, 0.59), colours[bag_index], Vector3(0.0, -9.0 + float(upper) * 18.0, 0.0), steel)


static func _suitcase(groups: Dictionary, at: Vector3, size: Vector3, tint: Color, rotation_deg: Vector3, steel: Material) -> void:
	var shell: Material = DesignKit.paint(tint, 0.48)
	var ribs: Material = DesignKit.paint(tint.lightened(0.11), 0.48)
	var frame: Basis = Basis.from_euler(rotation_deg * PI / 180.0)
	_box(groups, size * Vector3(0.99, 0.99, 1.0), at, steel, 0.08, rotation_deg)
	for face: float in [-1.0, 1.0]:
		var half_size: Vector3 = Vector3(size.x, size.y, size.z * 0.48)
		_box(groups, half_size, at + frame * Vector3(0.0, 0.0, face * size.z * 0.255), shell, 0.085, rotation_deg)
		for rib: int in range(3):
			_box(groups, Vector3(0.024, size.y * 0.7, 0.024), at + frame * Vector3((float(rib) - 1.0) * size.x * 0.22, 0.0, face * (size.z * 0.5 + 0.009)), ribs, 0.011, rotation_deg)
	# A raised leather grab handle, anchored at both ends; black seam reads as a zipper.
	for end: float in [-1.0, 1.0]:
		_box(groups, Vector3(0.045, 0.064, 0.055), at + frame * Vector3(end * 0.1, size.y * 0.5 + 0.028, 0.0), steel, 0.016, rotation_deg)
	_box(groups, Vector3(0.24, 0.038, 0.055), at + frame * Vector3(0.0, size.y * 0.5 + 0.061, 0.0), DesignKit.fabric(DesignKit.WALNUT, "baggage_train_handles"), 0.018, rotation_deg)
	for side: float in [-1.0, 1.0]:
		_box(groups, Vector3(0.085, 0.06, 0.095), at + frame * Vector3(side * (size.x * 0.5 - 0.07), -size.y * 0.5, 0.0), steel, 0.028, rotation_deg)


static func _wheel(groups: Dictionary, at: Vector3, radius: float, width: float, rubber: Material, steel: Material) -> void:
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, -width * 0.5), Vector2(radius * 0.76, -width * 0.5), Vector2(radius * 0.95, -width * 0.36), Vector2(radius, -width * 0.2), Vector2(radius, width * 0.2), Vector2(radius * 0.95, width * 0.36), Vector2(radius * 0.76, width * 0.5), Vector2(0.0, width * 0.5)])
	_part(groups, DesignKit.lathe(profile, 24), rubber, at, Vector3(0.0, 0.0, 90.0))
	var hub: PackedVector2Array = PackedVector2Array([Vector2(0.0, -width * 0.55), Vector2(radius * 0.47, -width * 0.55), Vector2(radius * 0.55, -width * 0.44), Vector2(radius * 0.55, width * 0.44), Vector2(radius * 0.47, width * 0.55), Vector2(0.0, width * 0.55)])
	_part(groups, DesignKit.lathe(hub, 20), steel, at, Vector3(0.0, 0.0, 90.0))
	var cap: PackedVector2Array = PackedVector2Array([Vector2(0.0, -width * 0.57), Vector2(radius * 0.19, -width * 0.57), Vector2(radius * 0.19, width * 0.57), Vector2(0.0, width * 0.57)])
	_part(groups, DesignKit.lathe(cap, 16), DesignKit.brass(), at, Vector3(0.0, 0.0, 90.0))


static func _bar(groups: Dictionary, from: Vector3, to: Vector3, material: Material) -> void:
	var basis: Basis = Basis.looking_at((to - from).normalized(), Vector3.UP)
	_part(groups, DesignKit.rounded_box(Vector3(0.075, 0.075, from.distance_to(to)), 0.028), material, (from + to) * 0.5, basis.get_euler() * 180.0 / PI)


static func _box(groups: Dictionary, size: Vector3, at: Vector3, material: Material, radius: float, rotation_deg: Vector3 = Vector3.ZERO) -> void:
	_part(groups, DesignKit.rounded_box(size, radius), material, at, rotation_deg)


static func _part(groups: Dictionary, mesh: Mesh, material: Material, at: Vector3, rotation_deg: Vector3 = Vector3.ZERO) -> void:
	var key: String = "%s:%s" % [mesh.get_instance_id(), material.get_instance_id()]
	if not groups.has(key):
		groups[key] = {"mesh": mesh, "material": material, "transforms": []}
	var group: Dictionary = groups[key]
	var transforms: Array = group["transforms"]
	transforms.append(Transform3D(Basis.from_euler(rotation_deg * PI / 180.0), at))


static func _flush(root: Node3D, groups: Dictionary) -> void:
	for value: Variant in groups.values():
		var group: Dictionary = value
		var mesh: Mesh = group["mesh"]
		var material: Material = group["material"]
		var transforms: Array = group["transforms"]
		if transforms.size() == 1:
			var transform: Transform3D = transforms[0]
			var part: MeshInstance3D = DesignKit.add(root, mesh, material, transform.origin)
			part.basis = transform.basis
		else:
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			multimesh.instance_count = transforms.size()
			for index: int in range(transforms.size()):
				var transform: Transform3D = transforms[index]
				multimesh.set_instance_transform(index, transform)
			var part: MultiMeshInstance3D = MultiMeshInstance3D.new()
			part.multimesh = multimesh
			part.material_override = material
			root.add_child(part)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.35, 0.48, 0.46, 0.18)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.16
		_materials["glass"] = material
	return _materials["glass"]


static func _mirror() -> StandardMaterial3D:
	return DesignKit.metal(Color(0.62, 0.67, 0.64), 0.12, 0.95, "baggage_train_mirror")
