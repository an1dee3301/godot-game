extends RefCounted
## Raised main-deck K-loader. Aircraft docking end and driving direction are +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "CargoLoader"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colours: Array[Color] = [Color(0.92, 0.69, 0.22), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var operator: int = posmod(variant, 4)
	var body := DesignKit.paint(colours[operator], 0.48)
	var accent := DesignKit.paint(DesignKit.CLAY if operator == 1 else DesignKit.OCHRE)
	var steel := DesignKit.metal()
	var alloy := DesignKit.metal(Color(0.64, 0.65, 0.61), 0.43, 0.85, "cargo_loader_alloy")
	var rubber := DesignKit.paint(Color(0.055, 0.052, 0.046), 0.94)
	var brass := DesignKit.brass()
	var amber := DesignKit.washi(Color(1.0, 0.49, 0.08), 3.0, "cargo_loader_amber")
	var lamps := DesignKit.washi(DesignKit.CREAM, 2.8, "cargo_loader_headlight")
	# Low, heavy chassis: long sills surrounding the recessed hydraulic machinery.
	DesignKit.rbox(root, Vector3(3.5, 0.45, 10.6), Vector3(0, 0.95, 0), steel, 0.15)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.38, 0.62, 10.4), Vector3(side * 1.69, 1.08, 0), body, 0.12)
		DesignKit.rbox(root, Vector3(0.025, 0.15, 9.8), Vector3(side * 1.895, 1.15, 0), accent, 0.012, false)
		# Wheel axes are X; the lathed tyre profile includes rounded shoulders.
		for z: float in [-3.75, 3.65]:
			DesignKit.add(root, _tyre(), rubber, Vector3(side * 1.86, 0.58, z), Vector3(0, 0, 90))
			DesignKit.add(root, _cylinder(0.31, 0.07), alloy, Vector3(side * 2.13, 0.58, z), Vector3(0, 0, 90))
			DesignKit.add(root, _cylinder(0.13, 0.09), steel, Vector3(side * 2.18, 0.58, z), Vector3(0, 0, 90))
			DesignKit.rbox(root, Vector3(0.61, 0.18, 1.5), Vector3(side * 1.85, 1.28, z), body, 0.08)
		# Stabilizer feet actually touch the ground.
		for z: float in [-4.65, 4.65]:
			DesignKit.rbox(root, Vector3(0.72, 0.15, 0.68), Vector3(side * 2.0, 0.075, z), rubber, 0.06)
			DesignKit.add(root, _cylinder(0.1, 0.82), alloy, Vector3(side * 2.0, 0.56, z))
			DesignKit.rbox(root, Vector3(0.49, 0.26, 0.5), Vector3(side * 1.94, 0.99, z), body, 0.06)
	DesignKit.rbox(root, Vector3(2.65, 0.7, 1.8), Vector3(0, 1.44, -3.75), body, 0.18)
	DesignKit.rbox(root, Vector3(2.3, 0.06, 1.5), Vector3(0, 1.82, -3.75), alloy, 0.025)
	# Recessed cooling grille, grouped into one MultiMesh.
	var vents: Array[Transform3D] = []
	for i in 10:
		vents.append(Transform3D(Basis.IDENTITY, Vector3(-0.95 + float(i) * 0.21, 1.45, -4.665)))
	_repeat(root, DesignKit.rounded_box(Vector3(0.085, 0.34, 0.025), 0.012), steel, vents)
	# Two distinct lift structures make the characteristic K-loader outline.
	_lift(root, -4.25, 1.05, 1.28, 3.83, body, steel, alloy)
	_lift(root, 2.05, 4.65, 1.28, 3.83, body, steel, alloy)
	_deck(root, -1.6, 6.7, 3.82, 3.9, body, alloy, rubber)
	_deck(root, 3.45, 3.3, 3.82, 3.9, body, alloy, rubber)
	DesignKit.rbox(root, Vector3(3.8, 0.23, 0.22), Vector3(0, 4.0, 5.19), rubber, 0.09)
	# Narrow edge rails leave the front docking lip open for unit-load devices.
	for side: float in [-1.0, 1.0]:
		var posts: Array[Transform3D] = []
		for z: float in [-4.8, -3.15, -1.5, 0.15, 1.5]:
			posts.append(Transform3D(Basis.IDENTITY, Vector3(side * 1.88, 4.49, z)))
		_repeat(root, DesignKit.rounded_box(Vector3(0.075, 0.93, 0.075), 0.025), steel, posts)
		DesignKit.rbox(root, Vector3(0.09, 0.09, 6.5), Vector3(side * 1.88, 4.99, -1.65), body, 0.035)
		DesignKit.rbox(root, Vector3(0.06, 0.06, 6.5), Vector3(side * 1.88, 4.53, -1.65), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.1, 0.22, 6.5), Vector3(side * 1.88, 4.12, -1.65), accent, 0.03)
		# Broad multilingual sideboards, readable from terminal windows.
		var sign := Node3D.new()
		sign.position = Vector3(side * 1.96, 3.48, -1.65)
		sign.rotation_degrees.y = side * 90.0
		root.add_child(sign)
		DesignKit.rbox(sign, Vector3(5.9, 1.02, 0.075), Vector3.ZERO, steel, 0.05)
		DesignKit.rbox(sign, Vector3(5.64, 0.035, 0.018), Vector3(0, 0.42, 0.045), brass, 0.009, false)
		_caption(sign, "CARGO  •  MAIN DECK", Vector3(0, 0.19, 0.05), 78, 0.0045)
		_caption(sign, "貨物  ·  货物  ·  Hàng hóa", Vector3(0, -0.10, 0.05), 60, 0.0045)
		_caption(sign, "Fret  ·  Carga", Vector3(0, -0.35, 0.05), 60, 0.0045)
	# Offset standing operator station beside the front transfer bridge.
	DesignKit.rbox(root, Vector3(0.94, 0.18, 2.55), Vector3(2.32, 3.91, 3.42), alloy, 0.07)
	DesignKit.rbox(root, Vector3(0.82, 0.83, 0.64), Vector3(2.32, 4.40, 4.33), body, 0.10)
	var console := DesignKit.rbox(root, Vector3(0.72, 0.13, 0.47), Vector3(2.32, 4.84, 4.28), steel, 0.05)
	console.rotation_degrees.x = -18.0
	DesignKit.rbox(root, Vector3(0.31, 0.018, 0.23), Vector3(2.22, 4.92, 4.24), DesignKit.washi(DesignKit.SAGE, 0.7, "cargo_loader_display"), 0.03, false)
	_beam(root, Vector3(2.58, 4.88, 4.21), Vector3(2.58, 5.12, 4.17), 0.045, steel)
	DesignKit.add(root, _cylinder(0.065, 0.09), rubber, Vector3(2.58, 5.12, 4.17))
	# Walnut grip is protected beneath the weather hood.
	DesignKit.rbox(root, Vector3(0.58, 0.045, 0.055), Vector3(2.32, 4.68, 3.95), DesignKit.wood(DesignKit.WALNUT, "cargo_loader_grip"), 0.02)
	for z: float in [2.22, 4.58]:
		_beam(root, Vector3(2.73, 4.0, z), Vector3(2.73, 5.55, z), 0.075, steel)
	_beam(root, Vector3(2.73, 4.97, 2.22), Vector3(2.73, 4.97, 4.58), 0.07, body)
	DesignKit.rbox(root, Vector3(1.10, 0.15, 2.8), Vector3(2.31, 5.60, 3.40), body, 0.07)
	# Open access ladder from ground to the operator catwalk.
	for x: float in [2.0, 2.64]:
		_beam(root, Vector3(x, 0.45, 1.26), Vector3(x, 3.94, 2.23), 0.085, steel)
	var steps: Array[Transform3D] = []
	for i in 9:
		var h: float = 0.59 + float(i) * 0.39
		steps.append(Transform3D(Basis.IDENTITY, Vector3(2.32, h, 1.3 + (h - 0.45) / 3.49 * 0.97)))
	_repeat(root, DesignKit.rounded_box(Vector3(0.68, 0.065, 0.23), 0.022), alloy, steps)
	for x: float in [-1.4, 1.4]:
		DesignKit.rbox(root, Vector3(0.5, 0.3, 0.15), Vector3(x, 1.07, 5.34), steel, 0.07)
		DesignKit.rbox(root, Vector3(0.35, 0.17, 0.025), Vector3(x, 1.08, 5.425), lamps, 0.05, false)
		DesignKit.rbox(root, Vector3(0.25, 0.12, 0.04), Vector3(x, 1.05, -5.33), DesignKit.washi(DesignKit.CLAY, 1.8, "cargo_loader_tail"), 0.03, false)
	for at_beacon: Vector3 in [Vector3(-1.72, 5.12, -4.7), Vector3(2.31, 5.79, 4.2)]:
		DesignKit.add(root, _cylinder(0.13, 0.07), steel, at_beacon)
		DesignKit.add(root, _cylinder(0.10, 0.18), amber, at_beacon + Vector3(0, 0.12, 0), Vector3.ZERO, false)
	return root


static func _lift(parent: Node3D, rear: float, front: float, low: float, high: float, body: Material, steel: Material, alloy: Material) -> void:
	for x: float in [-1.35, 1.35]:
		_beam(parent, Vector3(x, low, rear), Vector3(x, high, front), 0.24, body)
		_beam(parent, Vector3(x + 0.15, low, front), Vector3(x + 0.15, high, rear), 0.24, steel)
		DesignKit.add(parent, _cylinder(0.20, 0.14), alloy, Vector3(x + 0.24, (low + high) * 0.5, (rear + front) * 0.5), Vector3(0, 0, 90))
		var a := Vector3(x, low + 0.1, rear + 0.55)
		var b := Vector3(x, high - 0.3, (rear + front) * 0.5)
		_beam(parent, a, a.lerp(b, 0.60), 0.18, steel)
		_beam(parent, a.lerp(b, 0.57), b, 0.09, alloy)
	_beam(parent, Vector3(-1.5, low, rear), Vector3(1.5, low, rear), 0.16, steel)


static func _deck(parent: Node3D, z: float, length_m: float, width_m: float, y: float, body: Material, alloy: Material, rubber: Material) -> void:
	DesignKit.rbox(parent, Vector3(width_m, 0.25, length_m), Vector3(0, y, z), body, 0.07)
	DesignKit.rbox(parent, Vector3(width_m - 0.20, 0.07, length_m - 0.12), Vector3(0, y + 0.15, z), rubber, 0.025)
	var rollers: Array[Transform3D] = []
	var count: int = int(length_m / 0.32)
	for i in count:
		rollers.append(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0, y + 0.20, z - length_m * 0.5 + 0.21 + float(i) * 0.32)))
	_repeat(parent, _cylinder(0.075, width_m - 0.37), alloy, rollers)
	for x: float in [-1.78, 1.78]:
		DesignKit.rbox(parent, Vector3(0.14, 0.08, length_m - 0.12), Vector3(x, y + 0.22, z), alloy, 0.025)


static func _beam(parent: Node3D, a: Vector3, b: Vector3, thickness: float, mat: Material) -> void:
	var beam := DesignKit.rbox(parent, Vector3(thickness, a.distance_to(b), thickness), (a + b) * 0.5, mat, thickness * 0.25)
	beam.quaternion = Quaternion(Vector3.UP, (b - a).normalized())


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var key: String = "cylinder:%0.3f:%0.3f" % [radius, height]
	if not _meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 16
		_meshes[key] = mesh
	return _meshes[key] as CylinderMesh


static func _tyre() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0, -0.25), Vector2(0.36, -0.25), Vector2(0.51, -0.23),
		Vector2(0.57, -0.16), Vector2(0.58, -0.08), Vector2(0.58, 0.08),
		Vector2(0.57, 0.16), Vector2(0.51, 0.23), Vector2(0.36, 0.25), Vector2(0, 0.25)
	]), 24)


static func _repeat(parent: Node3D, mesh: Mesh, material: Material, transforms: Array[Transform3D]) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.material_override = material
	parent.add_child(node)


static func _caption(parent: Node3D, caption: String, at: Vector3, size: int, pixel_m: float) -> void:
	var label := Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.font_size = size
	label.pixel_size = pixel_m
	label.position = at
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
