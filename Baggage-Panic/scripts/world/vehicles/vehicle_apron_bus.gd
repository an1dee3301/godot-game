extends RefCounted
## Wide low-floor airport shuttle; +Z is the cab end. Dimensions are metres.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ApronPassengerBus"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colours: Array[Color] = [Color(0.94, 0.70, 0.18), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var accents: Array[Color] = [DesignKit.CHARCOAL, DesignKit.CLAY, DesignKit.CREAM, Color(0.78, 0.60, 0.34)]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = DesignKit.paint(colours[scheme], 0.36)
	var accent: StandardMaterial3D = DesignKit.paint(accents[scheme], 0.44)
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.65, "apron_bus_steel")
	var rubber: StandardMaterial3D = DesignKit.paint(Color(0.045, 0.042, 0.038), 0.96)
	var alloy: StandardMaterial3D = DesignKit.metal(Color(0.64, 0.62, 0.56), 0.34, 0.85, "apron_bus_alloy")
	var glass: StandardMaterial3D = _glass()
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "apron_bus_oak")
	var seat: StandardMaterial3D = DesignKit.fabric(DesignKit.CLAY, "apron_bus_linen")
	var warm_light: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 2.6, "apron_bus_headlight")
	var amber: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.48, 0.06), 3.0, "apron_bus_amber")
	var red: StandardMaterial3D = DesignKit.washi(Color(0.9, 0.09, 0.035), 2.0, "apron_bus_tail")
	# Low boarding deck, gently rolled roof and distinct front/rear caps.
	DesignKit.rbox(root, Vector3(2.84, 0.18, 13.2), Vector3(0.0, 0.39, 0.0), steel, 0.07)
	DesignKit.rbox(root, Vector3(2.72, 0.045, 12.9), Vector3(0.0, 0.5, 0.0), DesignKit.paint(DesignKit.LINEN), 0.018)
	DesignKit.add(root, _skirt_mesh(), body, Vector3.ZERO)
	DesignKit.rbox(root, Vector3(3.0, 0.29, 13.6), Vector3(0.0, 2.94, 0.0), body, 0.14)
	DesignKit.rbox(root, Vector3(2.2, 0.21, 3.4), Vector3(0.0, 3.16, -2.1), DesignKit.paint(DesignKit.CREAM), 0.1)
	for end: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(2.96, 0.89, 0.38), Vector3(0.0, 0.91, end * 6.57), body, 0.17)
		DesignKit.rbox(root, Vector3(2.86, 0.19, 0.19), Vector3(0.0, 0.49, end * 6.77), steel, 0.08)
		DesignKit.rbox(root, Vector3(2.76, 1.45, 0.12), Vector3(0.0, 2.04, end * 6.63), steel, 0.06)
		DesignKit.rbox(root, Vector3(2.55, 1.23, 0.08), Vector3(0.0, 2.02, end * 6.705), glass, 0.04, false)
		DesignKit.rbox(root, Vector3(2.78, 0.12, 0.055), Vector3(0.0, 1.22, end * 6.78), accent, 0.025)
	# Glazing is an uninterrupted dark ribbon, with structural mullions and black seals.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.11, 1.48, 12.8), Vector3(side * 1.435, 2.04, 0.0), glass, 0.045, false)
		DesignKit.rbox(root, Vector3(0.12, 0.10, 12.9), Vector3(side * 1.46, 2.77, 0.0), steel, 0.035)
		DesignKit.rbox(root, Vector3(0.09, 0.12, 12.85), Vector3(side * 1.5, 1.27, 0.0), accent, 0.03)
		for z: float in [-6.39, -5.0, -2.69, -1.01, 1.01, 2.69, 4.95, 6.39]:
			DesignKit.rbox(root, Vector3(0.125, 1.47, 0.075), Vector3(side * 1.46, 2.04, z), steel, 0.025)
		# Two double-leaf doors on each side, down to the 0.48 m boarding floor.
		for door_z: float in [-1.85, 1.85]:
			DesignKit.rbox(root, Vector3(0.12, 2.26, 1.65), Vector3(side * 1.485, 1.61, door_z), steel, 0.045)
			for leaf: float in [-1.0, 1.0]:
				DesignKit.rbox(root, Vector3(0.065, 2.09, 0.71), Vector3(side * 1.565, 1.61, door_z + leaf * 0.39), glass, 0.03, false)
			DesignKit.rbox(root, Vector3(0.025, 2.12, 0.045), Vector3(side * 1.604, 1.61, door_z), steel, 0.015)
			DesignKit.rbox(root, Vector3(0.045, 0.07, 1.49), Vector3(side * 1.605, 0.55, door_z), alloy, 0.02)
			DesignKit.rbox(root, Vector3(0.04, 0.35, 0.065), Vector3(side * 1.61, 1.25, door_z + 0.085), DesignKit.brass(), 0.02)
		# Oak window ledges and visible upholstered perimeter benches.
		DesignKit.rbox(root, Vector3(0.14, 0.07, 3.5), Vector3(side * 1.29, 1.3, -4.65), oak, 0.025)
		for bench_z: float in [-4.65, 0.0, 4.25]:
			var length: float = 1.65 if bench_z == 0.0 else 2.55
			DesignKit.rbox(root, Vector3(0.46, 0.13, length), Vector3(side * 1.01, 0.96, bench_z), seat, 0.055)
			DesignKit.rbox(root, Vector3(0.12, 0.55, length), Vector3(side * 1.26, 1.26, bench_z), seat, 0.055)
		# Large international route display, facing outward along each side.
		var sign_root: Node3D = Node3D.new()
		sign_root.position = Vector3(side * 1.53, 2.04, -4.65)
		sign_root.rotation_degrees.y = side * 90.0
		root.add_child(sign_root)
		DesignKit.rbox(sign_root, Vector3(3.0, 1.12, 0.055), Vector3.ZERO, steel, 0.035)
		var words: Array = Signage.TEXT["gates"]
		_text(sign_root, "%s  A01–A12" % str(words[0]), Vector3(0.0, 0.37, 0.034), 0.24)
		_text(sign_root, "%s   %s" % [str(words[1]), str(words[2])], Vector3(0.0, 0.10, 0.034), 0.23)
		_text(sign_root, str(words[3]), Vector3(0.0, -0.15, 0.034), 0.21)
		_text(sign_root, "%s · %s" % [str(words[4]), str(words[5])], Vector3(0.0, -0.39, 0.034), 0.21)
	# Wheels: broad rounded rubber shoulders, inset steel rims and hub caps.
	var tyre_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.19), Vector2(0.43, -0.19), Vector2(0.53, -0.15),
		Vector2(0.56, -0.09), Vector2(0.56, 0.09), Vector2(0.53, 0.15),
		Vector2(0.43, 0.19), Vector2(0.0, 0.19)]), 32)
	var rim_mesh: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.355, 0.035),
		Vector2(0.32, 0.065), Vector2(0.16, 0.065), Vector2(0.13, 0.11), Vector2(0.0, 0.11)]), 24)
	for axle_z: float in [-4.25, 3.95]:
		for side: float in [-1.0, 1.0]:
			DesignKit.add(root, tyre_mesh, rubber, Vector3(side * 1.31, 0.56, axle_z), Vector3(0.0, 0.0, side * -90.0))
			DesignKit.add(root, rim_mesh, alloy, Vector3(side * 1.5, 0.56, axle_z), Vector3(0.0, 0.0, side * -90.0))
	# Cab details, headlamps and corner mirrors make the front unambiguous.
	DesignKit.rbox(root, Vector3(2.4, 0.22, 0.62), Vector3(0.0, 1.32, 6.13), steel, 0.07)
	DesignKit.rbox(root, Vector3(2.26, 0.35, 0.06), Vector3(0.0, 2.5, 6.76), steel, 0.035)
	_text(root, "GATES  A01–A12", Vector3(0.0, 2.5, 6.802), 0.21)
	for x: float in [-1.07, 1.07]:
		DesignKit.rbox(root, Vector3(0.49, 0.23, 0.075), Vector3(x, 0.93, 6.785), steel, 0.065)
		DesignKit.rbox(root, Vector3(0.36, 0.12, 0.055), Vector3(x, 0.94, 6.831), warm_light, 0.045, false)
		DesignKit.rbox(root, Vector3(0.13, 0.12, 0.045), Vector3(x, 0.7, 6.803), amber, 0.035, false)
		DesignKit.rbox(root, Vector3(0.16, 0.49, 0.055), Vector3(x, 0.99, -6.79), red, 0.055, false)
		DesignKit.rbox(root, Vector3(0.43, 0.065, 0.085), Vector3(signf(x) * 1.61, 2.38, 6.12), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.17, 0.46, 0.28), Vector3(signf(x) * 1.81, 2.18, 6.12), steel, 0.065)
		DesignKit.rbox(root, Vector3(0.09, 0.08, 10.8), Vector3(signf(x) * 0.95, 2.76, 0.0), warm_light, 0.025, false)
		DesignKit.rbox(root, Vector3(0.61, 0.035, 0.035), Vector3(x * 0.45, 1.47, 6.77), steel, 0.015)
	for x: float in [-0.91, 0.91]:
		DesignKit.rbox(root, Vector3(0.28, 0.07, 0.28), Vector3(x, 3.11, 5.45), steel, 0.03)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.105, 0.0), Vector2(0.11, 0.12), Vector2(0.08, 0.17), Vector2(0.0, 0.17)]), 16), amber, Vector3(x, 3.145, 5.45), Vector3.ZERO, false)
	# Rear cooling grilles, with individual softened horizontal louvers.
	for row: int in 4:
		DesignKit.rbox(root, Vector3(1.48, 0.04, 0.035), Vector3(0.0, 0.77 + float(row) * 0.1, -6.782), steel, 0.012)
	return root


static func _text(parent: Node3D, caption: String, at: Vector3, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.11, 0.20, 0.21, 0.69)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.16
		material.metallic = 0.22
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D


static func _skirt_mesh() -> ArrayMesh:
	if _meshes.has("skirt"):
		return _meshes["skirt"] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spans: Array[Vector2] = [Vector2(-6.55, -2.68), Vector2(-1.02, 1.02), Vector2(2.68, 6.55)]
	for span: Vector2 in spans:
		var steps: int = ceili((span.y - span.x) / 0.075)
		for step: int in steps:
			var z0: float = lerpf(span.x, span.y, float(step) / float(steps))
			var z1: float = lerpf(span.x, span.y, float(step + 1) / float(steps))
			var low0: float = _arch_height(z0)
			var low1: float = _arch_height(z1)
			for side: float in [-1.0, 1.0]:
				var outer: float = side * 1.49
				var inner: float = side * 1.39
				var a: Vector3 = Vector3(outer, low0, z0)
				var b: Vector3 = Vector3(outer, 1.35, z0)
				var c: Vector3 = Vector3(outer, 1.35, z1)
				var d: Vector3 = Vector3(outer, low1, z1)
				_quad(surface, a, b, c, d, side < 0.0)
				_quad(surface, d, a, Vector3(inner, low0, z0), Vector3(inner, low1, z1), side < 0.0)
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes["skirt"] = mesh
	return mesh


static func _arch_height(z: float) -> float:
	var lower: float = 0.43
	for axle: float in [-4.25, 3.95]:
		var distance: float = absf(z - axle)
		if distance < 0.68:
			lower = maxf(lower, 0.56 + sqrt(maxf(0.0, 0.68 * 0.68 - distance * distance)))
	return lower


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool) -> void:
	var vertices: Array = [a, c, b, a, d, c] if flip else [a, b, c, a, c, d]
	for vertex: Vector3 in vertices:
		surface.add_vertex(vertex)
