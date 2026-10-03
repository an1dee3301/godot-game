extends RefCounted
## Apron team: marshaller, radio operator and turnaround supervisor.
## All poses are static; pooled, softened geometry keeps this a cheap fixture.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "GroundCrewGroup"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var scheme: int = posmod(variant, 4)
	var colours: Array[Color] = [Color(0.96, 0.74, 0.19), DesignKit.CREAM, DesignKit.SAGE, DesignKit.CHARCOAL]
	var accents: Array[Color] = [DesignKit.CHARCOAL, DesignKit.CLAY, DesignKit.OCHRE, Color(0.83, 0.66, 0.36)]
	var jacket: Material = DesignKit.fabric(colours[scheme], "crew_jacket_%d" % scheme)
	var trim: Material = DesignKit.fabric(accents[scheme], "crew_trim_%d" % scheme)
	var hi_vis: Material = DesignKit.fabric(Color(0.95, 0.78, 0.24), "crew_safety_yellow")
	var tape: Material = DesignKit.metal(DesignKit.CREAM, 0.3, 0.35, "crew_reflective_tape")
	_crew(root, Vector3(-1.05, 0.0, 0.25), -8.0, 0, jacket, trim, hi_vis, tape)
	_crew(root, Vector3(0.0, 0.0, -0.05), 12.0, 1, jacket, trim, hi_vis, tape)
	_crew(root, Vector3(1.05, 0.0, 0.15), -16.0, 2, jacket, trim, hi_vis, tape)
	_cones(root, Vector3(2.0, 0.0, 0.15), tape)
	_chock(root, Vector3(1.8, 0.0, 0.93))
	_apron_marker(root, accents[scheme])
	return root


static func _crew(parent: Node3D, at: Vector3, yaw: float, pose: int, jacket: Material, trim: Material, hi_vis: Material, tape: Material) -> void:
	var person: Node3D = Node3D.new()
	person.name = ["Marshaller", "RadioOperator", "Supervisor"][pose]
	person.position = at
	person.rotation_degrees.y = yaw
	parent.add_child(person)
	var trousers: Material = DesignKit.fabric(DesignKit.INDIGO.darkened(0.3), "crew_work_trousers")
	var rubber: Material = DesignKit.paint(DesignKit.CHARCOAL, 0.94)
	var skins: Array[Color] = [Color(0.64, 0.40, 0.27), Color(0.87, 0.65, 0.48), Color(0.42, 0.27, 0.19)]
	var skin: Material = DesignKit.paint(skins[pose], 0.85)
	var gloves: Material = DesignKit.fabric(DesignKit.LINEN, "crew_work_gloves")
	for side: float in [-1.0, 1.0]:
		var foot: Vector3 = Vector3(side * 0.14, 0.13, 0.035 if side < 0.0 else -0.045)
		DesignKit.rbox(person, Vector3(0.16, 0.16, 0.30), foot + Vector3(0.0, -0.05, 0.055), rubber, 0.055)
		_limb(person, Vector3(side * 0.12, 0.87, 0.0), Vector3(side * 0.14, 0.51, 0.01), 0.085, trousers)
		_limb(person, Vector3(side * 0.14, 0.51, 0.01), foot, 0.075, trousers)
		DesignKit.rbox(person, Vector3(0.15, 0.045, 0.014), Vector3(side * 0.14, 0.31, 0.081), tape, 0.005, false)
	DesignKit.rbox(person, Vector3(0.37, 0.16, 0.25), Vector3(0.0, 0.88, 0.0), trousers, 0.065)
	DesignKit.rbox(person, Vector3(0.40, 0.49, 0.25), Vector3(0.0, 1.18, 0.0), jacket, 0.10)
	# Split safety vest exposes the operator-coloured shirt and its centre closure.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(person, Vector3(0.17, 0.43, 0.035), Vector3(side * 0.107, 1.18, 0.126), hi_vis, 0.014)
		DesignKit.rbox(person, Vector3(0.042, 0.30, 0.014), Vector3(side * 0.115, 1.25, 0.149), tape, 0.006, false)
	DesignKit.rbox(person, Vector3(0.38, 0.057, 0.016), Vector3(0.0, 1.055, 0.15), tape, 0.006, false)
	DesignKit.rbox(person, Vector3(0.35, 0.08, 0.015), Vector3(0.0, 0.98, 0.132), trim, 0.008, false)
	DesignKit.rbox(person, Vector3(0.09, 0.11, 0.025), Vector3(0.12, 1.16, 0.16), trim, 0.01, false)
	_limb(person, Vector3(0.0, 1.4, 0.0), Vector3(0.0, 1.49, 0.0), 0.056, skin)
	var head: MeshInstance3D = DesignKit.add(person, _sphere(), skin, Vector3(0.0, 1.605, 0.015))
	head.scale = Vector3(0.19, 0.25, 0.20)
	# Turned safety helmet shell, front brim, ear cups: no miniature facial labels.
	var helmet: MeshInstance3D = DesignKit.add(person, _helmet(), DesignKit.paint(DesignKit.CREAM, 0.42), Vector3(0.0, 1.67, 0.0))
	helmet.scale.z = 1.13
	DesignKit.rbox(person, Vector3(0.27, 0.025, 0.27), Vector3(0.0, 1.689, 0.048), trim, 0.012)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(person, Vector3(0.056, 0.105, 0.085), Vector3(side * 0.114, 1.605, 0.0), rubber, 0.025)
	var left_elbow: Vector3 = Vector3(-0.29, 1.11, 0.02)
	var left_hand: Vector3 = Vector3(-0.29, 0.96, 0.14)
	var right_elbow: Vector3 = Vector3(0.29, 1.11, 0.02)
	var right_hand: Vector3 = Vector3(0.29, 0.96, 0.14)
	if pose == 0:
		left_elbow = Vector3(-0.43, 1.50, 0.03)
		left_hand = Vector3(-0.53, 1.77, 0.10)
		right_elbow = Vector3(0.43, 1.50, 0.03)
		right_hand = Vector3(0.53, 1.77, 0.10)
	elif pose == 1:
		right_elbow = Vector3(0.33, 1.25, 0.15)
		right_hand = Vector3(0.16, 1.53, 0.21)
	else:
		left_elbow = Vector3(-0.30, 1.09, 0.18)
		left_hand = Vector3(-0.18, 1.15, 0.34)
		right_elbow = Vector3(0.30, 1.09, 0.18)
		right_hand = Vector3(0.18, 1.15, 0.34)
	_limb(person, Vector3(-0.20, 1.35, 0.0), left_elbow, 0.064, jacket)
	_limb(person, left_elbow, left_hand, 0.053, jacket)
	_limb(person, Vector3(0.20, 1.35, 0.0), right_elbow, 0.064, jacket)
	_limb(person, right_elbow, right_hand, 0.053, jacket)
	for hand: Vector3 in [left_hand, right_hand]:
		var glove: MeshInstance3D = DesignKit.add(person, _sphere(), gloves, hand)
		glove.scale = Vector3(0.10, 0.135, 0.095)
	if pose == 0:
		for hand: Vector3 in [left_hand, right_hand]:
			_limb(person, hand, hand + Vector3(0.0, 0.13, 0.0), 0.023, rubber)
			_limb(person, hand + Vector3(0.0, 0.12, 0.0), hand + Vector3(0.0, 0.42, 0.0), 0.028, DesignKit.washi(Color(1.0, 0.40, 0.09), 1.8, "crew_marshalling_wands"))
	elif pose == 1:
		DesignKit.rbox(person, Vector3(0.058, 0.13, 0.04), right_hand + Vector3(0.0, 0.02, 0.025), rubber, 0.012)
		_limb(person, right_hand + Vector3(0.01, 0.08, 0.025), right_hand + Vector3(0.01, 0.18, 0.025), 0.008, DesignKit.metal())
	else:
		var clipboard: MeshInstance3D = DesignKit.rbox(person, Vector3(0.35, 0.24, 0.027), Vector3(0.0, 1.16, 0.35), DesignKit.metal(), 0.016)
		clipboard.rotation_degrees.x = -24.0
		DesignKit.rbox(person, Vector3(0.29, 0.19, 0.006), Vector3(0.0, 1.16, 0.37), DesignKit.paint(DesignKit.CREAM), 0.003, false)
		DesignKit.rbox(person, Vector3(0.09, 0.035, 0.016), Vector3(0.0, 1.25, 0.333), DesignKit.brass(), 0.006, false)


static func _limb(parent: Node3D, start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	var direction: Vector3 = finish - start
	var part: MeshInstance3D = DesignKit.add(parent, _capsule(), material, (start + finish) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, direction.normalized())
	part.scale = Vector3(radius, direction.length(), radius)


static func _capsule() -> Mesh:
	if not _meshes.has("limb"):
		_meshes["limb"] = DesignKit.lathe(PackedVector2Array([Vector2(0.0, -0.5), Vector2(0.7, -0.47), Vector2(1.0, -0.39), Vector2(1.0, 0.39), Vector2(0.7, 0.47), Vector2(0.0, 0.5)]), 12)
	return _meshes["limb"] as Mesh


static func _sphere() -> Mesh:
	if not _meshes.has("head"):
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 16
		mesh.rings = 8
		_meshes["head"] = mesh
	return _meshes["head"] as Mesh


static func _helmet() -> Mesh:
	if not _meshes.has("helmet"):
		_meshes["helmet"] = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.128, 0.0), Vector2(0.131, 0.025), Vector2(0.116, 0.080), Vector2(0.082, 0.117), Vector2(0.0, 0.135)]), 20)
	return _meshes["helmet"] as Mesh


static func _cones(parent: Node3D, at: Vector3, tape: Material) -> void:
	var orange: Material = DesignKit.paint(DesignKit.CLAY.lightened(0.12), 0.75)
	var rubber: Material = DesignKit.paint(DesignKit.CHARCOAL, 0.94)
	# Nested cones: only the exposed upper shell of each lower cone is visible.
	for i: int in 3:
		var offset: Vector3 = at + Vector3(0.0, float(i) * 0.095, 0.0)
		DesignKit.rbox(parent, Vector3(0.43, 0.055, 0.43), offset + Vector3(0.0, 0.0275, 0.0), rubber, 0.025)
		DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0.16, 0.055), Vector2(0.157, 0.082), Vector2(0.036, 0.62), Vector2(0.027, 0.63), Vector2(0.023, 0.615), Vector2(0.14, 0.055)]), 20), orange, offset)
		if i == 2:
			for band: Vector2 in [Vector2(0.25, 0.34), Vector2(0.45, 0.52)]:
				var bottom: float = 0.157 - (band.x - 0.082) * 0.225
				var top: float = 0.157 - (band.y - 0.082) * 0.225
				DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(bottom + 0.002, band.x), Vector2(top + 0.002, band.y)]), 20), tape, offset, Vector3.ZERO, false)
	# Portable amber beacon on the stack's tip, without a costly dynamic light.
	DesignKit.add(parent, _helmet(), DesignKit.washi(Color(1.0, 0.64, 0.16), 2.0, "crew_stack_beacon"), at + Vector3(0.0, 0.825, 0.0)).scale = Vector3(0.42, 0.6, 0.42)


static func _chock(parent: Node3D, at: Vector3) -> void:
	if not _meshes.has("chock"):
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var vertices: PackedVector3Array = PackedVector3Array([Vector3(-0.23, 0.0, -0.15), Vector3(0.23, 0.0, -0.15), Vector3(-0.23, 0.19, -0.10), Vector3(0.23, 0.19, -0.10), Vector3(-0.23, 0.0, 0.22), Vector3(0.23, 0.0, 0.22)])
		var indices: PackedInt32Array = PackedInt32Array([0, 2, 1, 1, 2, 3, 2, 4, 3, 3, 4, 5, 4, 0, 5, 5, 0, 1, 0, 4, 2, 1, 3, 5])
		for index: int in indices:
			st.add_vertex(vertices[index])
		st.generate_normals()
		_meshes["chock"] = st.commit()
	DesignKit.add(parent, _meshes["chock"] as Mesh, DesignKit.paint(DesignKit.CHARCOAL, 0.96), at)
	for x: float in [-0.14, 0.0, 0.14]:
		var rib: MeshInstance3D = DesignKit.rbox(parent, Vector3(0.025, 0.018, 0.30), at + Vector3(x, 0.097, 0.057), DesignKit.paint(DesignKit.OCHRE), 0.007, false)
		rib.rotation_degrees.x = 31.0
	# A stiff rope loop stays above the apron rather than clipping into it.
	_limb(parent, at + Vector3(0.23, 0.06, 0.0), at + Vector3(0.42, 0.065, 0.08), 0.012, DesignKit.fabric(DesignKit.LINEN, "crew_chock_rope"))
	_limb(parent, at + Vector3(0.42, 0.065, 0.08), at + Vector3(0.25, 0.06, 0.16), 0.012, DesignKit.fabric(DesignKit.LINEN, "crew_chock_rope"))


static func _apron_marker(parent: Node3D, accent: Color) -> void:
	# A large international apron marker above the team, with rounded steel feet.
	var steel: Material = DesignKit.metal()
	for x: float in [-1.75, 1.75]:
		DesignKit.rbox(parent, Vector3(0.07, 2.7, 0.07), Vector3(x, 1.35, -0.65), steel, 0.02)
		DesignKit.rbox(parent, Vector3(0.42, 0.055, 0.55), Vector3(x, 0.0275, -0.65), steel, 0.025)
	DesignKit.rbox(parent, Vector3(4.05, 1.24, 0.10), Vector3(0.0, 2.65, -0.65), steel, 0.045)
	DesignKit.rbox(parent, Vector3(3.91, 0.028, 0.012), Vector3(0.0, 3.18, -0.591), DesignKit.brass(), 0.005, false)
	var translations: Array = Signage.TEXT["apron"]
	var lines: Array[String] = [str(translations[0]), "%s · %s" % [translations[1], translations[2]], "%s · %s · %s" % [translations[3], translations[4], translations[5]]]
	for i: int in 3:
		var label: Label3D = Label3D.new()
		label.font = Signage.font()
		label.text = lines[i]
		label.font_size = 96 if i < 2 else 72
		label.pixel_size = 0.0032 if i < 2 else 0.0028
		label.modulate = DesignKit.CREAM if i != 1 else accent.lightened(0.3)
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(0.0, 2.98 - float(i) * 0.36, -0.59)
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(label)
