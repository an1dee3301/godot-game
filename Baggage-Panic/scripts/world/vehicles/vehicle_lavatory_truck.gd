extends RefCounted
## Compact apron lavatory tanker: cab at +Z, hose equipment at the rear.
## Shared DesignKit resources supply every solid surface; only the hose is custom.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "LavatoryServiceTruck"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.94, 0.69, 0.16), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var accents: Array[Color] = [DesignKit.CHARCOAL, DesignKit.CLAY, DesignKit.CREAM, DesignKit.OCHRE]
	var body: StandardMaterial3D = DesignKit.paint(colours[scheme], 0.42)
	var stripe: StandardMaterial3D = DesignKit.paint(accents[scheme], 0.48)
	var steel: StandardMaterial3D = DesignKit.metal()
	var stainless: StandardMaterial3D = DesignKit.metal(Color(0.73, 0.75, 0.71), 0.34, 0.8, "lavatory_stainless")
	var rubber: StandardMaterial3D = DesignKit.paint(Color(0.045, 0.049, 0.043), 0.94)
	var glass: StandardMaterial3D = DesignKit.metal(Color(0.13, 0.23, 0.25), 0.18, 0.3, "lavatory_glazing")
	var amber: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.48, 0.08), 3.0, "lavatory_beacon")
	var lamp: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 2.6, "lavatory_headlamp")
	var red: StandardMaterial3D = DesignKit.washi(Color(0.85, 0.12, 0.065), 1.7, "lavatory_tail")
	# Low ladder chassis and short-wheelbase cab-over layout, 6.5 m overall.
	DesignKit.rbox(root, Vector3(1.8, 0.23, 5.7), Vector3(0.0, 0.64, -0.05), steel, 0.07)
	DesignKit.rbox(root, Vector3(2.12, 0.15, 3.9), Vector3(0.0, 0.93, -1.12), stainless, 0.055)
	for axle_z: float in [-1.85, 1.91]:
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, -0.99), Vector2(0.095, -0.99), Vector2(0.095, 0.99), Vector2(0, 0.99)]), 12), steel, Vector3(0, 0.48, axle_z), Vector3(0, 0, 90))
		for side: float in [-1.0, 1.0]:
			var wheel_at: Vector3 = Vector3(side * 1.0, 0.48, axle_z)
			var tire: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.25, -0.18), Vector2(0.41, -0.18), Vector2(0.48, -0.12), Vector2(0.48, 0.12), Vector2(0.41, 0.18), Vector2(0.25, 0.18), Vector2(0.25, -0.18)]), 32)
			DesignKit.add(root, tire, rubber, wheel_at, Vector3(0, 0, 90))
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, -0.035), Vector2(0.25, -0.035), Vector2(0.28, 0), Vector2(0.25, 0.035), Vector2(0, 0.035)]), 24), stainless, wheel_at + Vector3(side * 0.185, 0, 0), Vector3(0, 0, 90))
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.105, 0), Vector2(0.105, 0.07), Vector2(0, 0.07)]), 16), steel, wheel_at + Vector3(side * 0.21, 0, 0), Vector3(0, 0, -side * 90))
			DesignKit.rbox(root, Vector3(0.38, 0.14, 1.2), Vector3(side * 1.0, 1.03, axle_z), body, 0.065)
	# Rounded cab, layered doors and broad opaque blue-green glazing.
	DesignKit.rbox(root, Vector3(2.08, 1.5, 1.75), Vector3(0, 1.68, 2.02), body, 0.16)
	DesignKit.rbox(root, Vector3(2.17, 0.13, 1.88), Vector3(0, 2.47, 2.01), body, 0.065)
	DesignKit.rbox(root, Vector3(1.86, 0.72, 0.07), Vector3(0, 2.02, 2.91), steel, 0.09)
	DesignKit.rbox(root, Vector3(1.74, 0.6, 0.055), Vector3(0, 2.04, 2.955), glass, 0.065)
	DesignKit.rbox(root, Vector3(0.035, 0.65, 0.04), Vector3(0, 2.03, 2.99), steel, 0.012)
	DesignKit.rbox(root, Vector3(2.19, 0.24, 0.21), Vector3(0, 0.9, 2.95), steel, 0.07)
	DesignKit.rbox(root, Vector3(1.82, 0.24, 0.065), Vector3(0, 1.45, 2.91), stripe, 0.05)
	DesignKit.rbox(root, Vector3(0.76, 0.23, 0.075), Vector3(0, 1.14, 2.936), steel, 0.045)
	for line in 3:
		DesignKit.rbox(root, Vector3(0.66, 0.022, 0.025), Vector3(0, 1.075 + float(line) * 0.057, 2.985), stainless, 0.009, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.035, 1.22, 1.38), Vector3(side * 1.045, 1.71, 2.02), steel, 0.014)
		DesignKit.rbox(root, Vector3(0.045, 1.16, 1.31), Vector3(side * 1.066, 1.71, 2.02), body, 0.02)
		DesignKit.rbox(root, Vector3(0.05, 0.58, 1.12), Vector3(side * 1.098, 2.06, 2.06), glass, 0.024)
		DesignKit.rbox(root, Vector3(0.055, 0.15, 1.31), Vector3(side * 1.103, 1.46, 2.02), stripe, 0.02)
		DesignKit.rbox(root, Vector3(0.055, 0.045, 0.25), Vector3(side * 1.114, 1.65, 1.59), stainless, 0.018, false)
		DesignKit.rbox(root, Vector3(0.36, 0.11, 0.64), Vector3(side * 1.12, 0.76, 1.21), steel, 0.04)
		DesignKit.rbox(root, Vector3(0.22, 0.08, 0.48), Vector3(side * 1.12, 0.826, 1.21), stainless, 0.025)
		DesignKit.rbox(root, Vector3(0.25, 0.055, 0.055), Vector3(side * 1.18, 2.0, 2.62), steel, 0.025, false)
		DesignKit.rbox(root, Vector3(0.13, 0.36, 0.23), Vector3(side * 1.32, 2.07, 2.61), steel, 0.05)
		DesignKit.rbox(root, Vector3(0.02, 0.27, 0.16), Vector3(side * 1.394, 2.07, 2.61), glass, 0.009, false)
		DesignKit.rbox(root, Vector3(0.43, 0.22, 0.09), Vector3(side * 0.73, 1.15, 2.97), lamp, 0.045, false)
		DesignKit.rbox(root, Vector3(0.15, 0.07, 0.06), Vector3(side * 0.73, 1.34, 2.96), amber, 0.025, false)
		var wiper: MeshInstance3D = DesignKit.rbox(root, Vector3(0.035, 0.33, 0.025), Vector3(side * 0.46, 1.91, 2.994), steel, 0.012, false)
		wiper.rotation_degrees.z = side * -25.0
	# Elliptical-ended waste tank; the turned profile runs lengthwise along Z.
	var tank_profile: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0.38, 0.045), Vector2(0.65, 0.17), Vector2(0.82, 0.36), Vector2(0.86, 0.55), Vector2(0.86, 2.82), Vector2(0.82, 3.01), Vector2(0.65, 3.2), Vector2(0.38, 3.325), Vector2(0, 3.37)])
	DesignKit.add(root, DesignKit.lathe(tank_profile, 40), stainless, Vector3(0, 1.83, -2.7), Vector3(90, 0, 0))
	for band_z: float in [-2.04, -0.14]:
		var band: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.858, -0.055), Vector2(0.883, -0.055), Vector2(0.883, 0.055), Vector2(0.858, 0.055), Vector2(0.858, -0.055)]), 40)
		DesignKit.add(root, band, stripe, Vector3(0, 1.83, band_z), Vector3(90, 0, 0))
		DesignKit.rbox(root, Vector3(1.46, 0.21, 0.27), Vector3(0, 1.04, band_z), steel, 0.045)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.29, 0), Vector2(0.29, 0.08), Vector2(0.24, 0.13), Vector2(0, 0.13)]), 24), steel, Vector3(0, 2.68, -1.15))
	DesignKit.rbox(root, Vector3(0.27, 0.05, 0.055), Vector3(0, 2.83, -1.15), DesignKit.brass(), 0.018)
	# International service legends on shielded, gently rounded side placards.
	var words: Array = Signage.translations("toilets")
	var international: String = "%s  ·  %s\n%s\n%s  ·  %s" % [words[1], words[2], words[3], words[4], words[5]]
	for side: float in [-1.0, 1.0]:
		var placard: Node3D = Node3D.new()
		placard.position = Vector3(side * 0.89, 1.88, -1.05)
		placard.rotation_degrees.y = side * 90.0
		root.add_child(placard)
		DesignKit.rbox(placard, Vector3(3.0, 1.07, 0.055), Vector3.ZERO, body, 0.026)
		DesignKit.rbox(placard, Vector3(2.87, 0.035, 0.02), Vector3(0, 0.46, 0.035), stripe, 0.009, false)
		var ink: Color = DesignKit.CREAM if scheme == 3 else DesignKit.CHARCOAL
		_label(placard, "LAVATORY SERVICE", Vector3(0, 0.26, 0.037), 80, 0.003, ink)
		_label(placard, international, Vector3(0, -0.16, 0.037), 58, 0.003, ink)
	# Separate rinse-water locker, rear pump and visible thick hose reel.
	DesignKit.rbox(root, Vector3(1.78, 0.5, 0.57), Vector3(0, 1.24, -2.78), body, 0.08)
	DesignKit.rbox(root, Vector3(1.31, 0.32, 0.065), Vector3(0, 1.25, -3.08), stripe, 0.025)
	DesignKit.rbox(root, Vector3(0.31, 0.065, 0.07), Vector3(0.38, 1.35, -3.125), stainless, 0.024)
	DesignKit.rbox(root, Vector3(2.16, 0.17, 0.4), Vector3(0, 0.84, -3.04), steel, 0.055)
	DesignKit.rbox(root, Vector3(0.62, 0.42, 0.54), Vector3(-0.54, 1.75, -2.96), steel, 0.085)
	DesignKit.add(root, _hose_mesh(), rubber, Vector3(0.38, 1.82, -2.96))
	for reel_x: float in [0.1, 0.68]:
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.08, -0.025), Vector2(0.43, -0.025), Vector2(0.43, 0.025), Vector2(0.08, 0.025), Vector2(0.08, -0.025)]), 28), stripe, Vector3(reel_x, 1.82, -2.96), Vector3(0, 0, 90))
	DesignKit.rbox(root, Vector3(0.76, 0.075, 0.08), Vector3(0.38, 1.82, -2.96), stainless, 0.025)
	DesignKit.rbox(root, Vector3(0.09, 0.63, 0.095), Vector3(-0.89, 1.93, -2.94), rubber, 0.04)
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.095, 0), Vector2(0.095, 0.1), Vector2(0.06, 0.13), Vector2(0, 0.13)]), 16), DesignKit.brass(), Vector3(-0.89, 2.25, -2.94))
	# Roof beacons and rear lamps are emissive geometry, without extra light nodes.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.23, 0.055, 0.23), Vector3(side * 0.73, 2.56, 2.05), steel, 0.025)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.092, 0), Vector2(0.092, 0.16), Vector2(0.065, 0.21), Vector2(0, 0.22)]), 16), amber, Vector3(side * 0.73, 2.59, 2.05), Vector3.ZERO, false)
		DesignKit.rbox(root, Vector3(0.25, 0.12, 0.07), Vector3(side * 0.84, 1.02, -3.21), red, 0.027, false)
		DesignKit.rbox(root, Vector3(0.25, 0.07, 0.07), Vector3(side * 0.84, 1.16, -3.21), amber, 0.025, false)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = ink
	label.outline_size = 0
	label.position = at
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _hose_mesh() -> ArrayMesh:
	if _meshes.has("hose"):
		return _meshes["hose"] as ArrayMesh
	# Five coils of a 70 mm hose around the reel's horizontal spindle.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 150
	var ring_segments: int = 8
	for i in steps:
		for j in ring_segments:
			var a: Vector3 = _hose_vertex(i, j, steps, ring_segments)
			var b: Vector3 = _hose_vertex(i + 1, j, steps, ring_segments)
			var c: Vector3 = _hose_vertex(i + 1, j + 1, steps, ring_segments)
			var d: Vector3 = _hose_vertex(i, j + 1, steps, ring_segments)
			for vertex: Vector3 in [a, c, b, a, d, c]:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["hose"] = mesh
	return mesh


static func _hose_vertex(step: int, ring: int, steps: int, segments: int) -> Vector3:
	var t: float = float(step) / float(steps)
	var angle: float = t * TAU * 5.0
	var radial: Vector3 = Vector3(0, cos(angle), sin(angle))
	var center: Vector3 = Vector3(-0.2 + 0.4 * t, 0, 0) + radial * 0.335
	var cross_angle: float = float(ring) / float(segments) * TAU
	return center + (Vector3.RIGHT * cos(cross_angle) + radial * sin(cross_angle)) * 0.035
