extends RefCounted
## Four-metre lounge buffet: oak joinery, honed stone and removable glass cloches.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BuffetCounter"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[style]
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var stone_tint: Color = DesignKit.LIMESTONE if style % 2 == 0 else DesignKit.PLASTER
	var stone: StandardMaterial3D = DesignKit.stone(stone_tint, 0.48, "buffet_stone_%d" % (style % 2))
	var ceramic: StandardMaterial3D = DesignKit.paint(DesignKit.CREAM, 0.25)
	var glazed_accent: StandardMaterial3D = DesignKit.paint(accent, 0.3)
	var brass: StandardMaterial3D = DesignKit.brass()
	var steel: StandardMaterial3D = DesignKit.metal()
	# Recessed plinth meets the floor; the cabinet appears lightly lifted above it.
	DesignKit.rbox(root, Vector3(3.66, 0.14, 0.78), Vector3(0.0, 0.07, 0.0), steel, 0.035)
	DesignKit.rbox(root, Vector3(3.86, 0.75, 0.92), Vector3(0.0, 0.515, 0.0), walnut, 0.07)
	DesignKit.rbox(root, Vector3(4.0, 0.09, 1.06), Vector3(0.0, 0.955, 0.0), stone, 0.04)
	DesignKit.rbox(root, Vector3(3.8, 0.018, 0.025), Vector3(0.0, 0.893, 0.464), brass, 0.007, false)
	DesignKit.rbox(root, Vector3(3.7, 0.018, 0.028), Vector3(0.0, 0.87, 0.465), DesignKit.washi(DesignKit.CREAM, 1.1, "buffet_reveal"), 0.007, false)
	for door in 4:
		var x: float = -1.44 + float(door) * 0.96
		DesignKit.rbox(root, Vector3(0.942, 0.65, 0.055), Vector3(x, 0.505, 0.458), oak, 0.024)
		# Routed finger-pull recess with a fine brass lip.
		DesignKit.rbox(root, Vector3(0.29, 0.025, 0.013), Vector3(x, 0.735, 0.49), walnut, 0.008, false)
		DesignKit.rbox(root, Vector3(0.3, 0.012, 0.019), Vector3(x, 0.716, 0.494), brass, 0.005, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.055, 0.71, 0.84), Vector3(side * 1.926, 0.51, 0.0), oak, 0.022)
		# Slim end pilasters reveal the cabinet's framed construction.
		for z: float in [-0.35, 0.35]:
			DesignKit.rbox(root, Vector3(0.015, 0.65, 0.045), Vector3(side * 1.958, 0.51, z), walnut, 0.007, false)
	# Three removable domes on footed porcelain dishes. Front ledge stays clear for service.
	for station in 3:
		var x: float = -1.35 + float(station) * 0.82
		_dish(root, Vector3(x, 1.0, -0.06), ceramic, brass, style, station)
	_fruit_bowl(root, Vector3(1.25, 1.0, -0.07), glazed_accent, style)
	# A linen mat, a small plate stack and resting serving tongs.
	DesignKit.rbox(root, Vector3(0.48, 0.012, 0.25), Vector3(1.25, 1.007, 0.34), DesignKit.fabric(DesignKit.LINEN, "linen"), 0.015, false)
	var plate: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.11, 0.0), Vector2(0.155, 0.015),
		Vector2(0.16, 0.025), Vector2(0.145, 0.03), Vector2(0.1, 0.013), Vector2(0.0, 0.013)
	]), 32)
	for level in 4:
		DesignKit.add(root, plate, ceramic, Vector3(1.23, 1.015 + float(level) * 0.022, 0.34), Vector3.ZERO, false)
	for side: float in [-1.0, 1.0]:
		var tong: MeshInstance3D = DesignKit.rbox(root, Vector3(0.024, 0.016, 0.29), Vector3(0.57 + side * 0.025, 1.023, 0.3), brass, 0.006, false)
		tong.rotation_degrees.y = side * 8.0
	# Freestanding rear sign, with all six lounge translations supplied by Signage.
	for x: float in [-1.78, 1.78]:
		DesignKit.rbox(root, Vector3(0.065, 1.95, 0.065), Vector3(x, 1.935, -0.415), steel, 0.02)
		DesignKit.rbox(root, Vector3(0.14, 0.025, 0.14), Vector3(x, 1.013, -0.415), brass, 0.012, false)
	Signage.panel(root, Vector3(0.0, 2.36, -0.415), "lounge", {"width": 3.8, "accent": accent})
	return root


static func _dish(parent: Node3D, at: Vector3, ceramic: Material, brass: Material, style: int, station: int) -> void:
	var platter: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.19, 0.025),
		Vector2(0.31, 0.035), Vector2(0.335, 0.055), Vector2(0.335, 0.07),
		Vector2(0.31, 0.072), Vector2(0.26, 0.052), Vector2(0.0, 0.052)
	]), 40)
	DesignKit.add(parent, platter, ceramic, at, Vector3.ZERO, false)
	var bread: Material = DesignKit.paint(Color(0.77, 0.48, 0.22), 0.78)
	var filling: Material = DesignKit.paint(DesignKit.CLAY if style % 2 == 0 else DesignKit.SAGE, 0.64)
	for piece in 4:
		var angle: float = TAU * float(piece) / 4.0 + float(station) * 0.25
		var centre: Vector3 = at + Vector3(cos(angle) * 0.13, 0.086, sin(angle) * 0.13)
		var morsel: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.14, 0.064, 0.105), centre, bread, 0.029, false)
		morsel.rotation_degrees.y = rad_to_deg(angle)
		var topping: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.12, 0.019, 0.085), centre + Vector3(0.0, 0.041, 0.0), filling, 0.008, false)
		topping.rotation_degrees.y = rad_to_deg(angle)
	# Thick rolled lower lip and curved cloche profile; transparent, with no shadow over food.
	var dome: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.322, 0.072), Vector2(0.324, 0.09), Vector2(0.315, 0.19),
		Vector2(0.283, 0.275), Vector2(0.228, 0.343), Vector2(0.15, 0.393),
		Vector2(0.065, 0.423), Vector2(0.0, 0.428)
	]), 48)
	DesignKit.add(parent, dome, _glass(), at, Vector3.ZERO, false)
	var rim: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.314, 0.072), Vector2(0.326, 0.072), Vector2(0.326, 0.082),
		Vector2(0.314, 0.082), Vector2(0.314, 0.072)
	]), 40)
	DesignKit.add(parent, rim, brass, at, Vector3.ZERO, false)
	var knob: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.426), Vector2(0.015, 0.426), Vector2(0.015, 0.447),
		Vector2(0.032, 0.456), Vector2(0.034, 0.47), Vector2(0.023, 0.484), Vector2(0.0, 0.489)
	]), 24)
	DesignKit.add(parent, knob, brass, at, Vector3.ZERO, false)


static func _fruit_bowl(parent: Node3D, at: Vector3, ceramic: Material, style: int) -> void:
	var bowl: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.115, 0.0), Vector2(0.125, 0.025),
		Vector2(0.21, 0.06), Vector2(0.29, 0.145), Vector2(0.325, 0.215),
		Vector2(0.325, 0.23), Vector2(0.308, 0.23), Vector2(0.28, 0.15),
		Vector2(0.2, 0.078), Vector2(0.1, 0.047), Vector2(0.0, 0.047)
	]), 40)
	DesignKit.add(parent, bowl, ceramic, at, Vector3.ZERO, false)
	var fruit_colors: Array[Color] = [Color(0.83, 0.39, 0.09), Color(0.65, 0.18, 0.12), Color(0.61, 0.68, 0.27), DesignKit.OCHRE]
	var stem: Material = DesignKit.wood(DesignKit.WALNUT, "walnut")
	for fruit in 8:
		var angle: float = float(fruit) * 2.39996
		var radius: float = 0.16 if fruit < 5 else 0.08
		var height: float = 0.205 if fruit < 5 else 0.31
		var centre: Vector3 = at + Vector3(cos(angle) * radius, height, sin(angle) * radius)
		var color: Color = fruit_colors[posmod(fruit + style, 4)]
		var orb: MeshInstance3D = DesignKit.add(parent, _fruit_mesh(), DesignKit.paint(color, 0.43), centre, Vector3.ZERO, false)
		orb.scale = Vector3(1.0, 1.1 if fruit % 3 == 0 else 0.94, 1.0)
		DesignKit.rbox(parent, Vector3(0.009, 0.027, 0.009), centre + Vector3(0.0, 0.086, 0.0), stem, 0.003, false)


static func _fruit_mesh() -> SphereMesh:
	if not _meshes.has("fruit"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.078
		sphere.height = 0.156
		sphere.radial_segments = 20
		sphere.rings = 12
		_meshes["fruit"] = sphere
	return _meshes["fruit"] as SphereMesh


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.88, 0.96, 0.94, 0.16)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.09
		material.metallic = 0.06
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D
