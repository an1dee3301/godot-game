extends RefCounted
## Four-metre kaiten counter. All belt and food details are deliberately static.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SushiCounter"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var v: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.LINEN]
	var accent: Color = accents[v]
	var oak: Material = DesignKit.wood()
	var walnut: Material = DesignKit.wood(DesignKit.WALNUT, "sushi_walnut")
	var stone: Material = DesignKit.stone()
	var steel: Material = DesignKit.metal()
	var brass: Material = DesignKit.brass()
	var ceramic: Material = DesignKit.paint(accent, 0.27)
	var cream: Material = DesignKit.paint(DesignKit.CREAM, 0.3)
	# Recessed toe-kick, eased oak cabinet, stone reveal and generous dining lip.
	DesignKit.rbox(root, Vector3(3.62, 0.12, 1.06), Vector3(0, 0.06, 0), steel, 0.045)
	DesignKit.rbox(root, Vector3(3.84, 0.91, 1.15), Vector3(0, 0.575, 0), oak, 0.11)
	DesignKit.rbox(root, Vector3(3.94, 0.06, 1.26), Vector3(0, 1.035, 0), stone, 0.025)
	DesignKit.rbox(root, Vector3(4.0, 0.09, 1.38), Vector3(0, 1.11, 0), oak, 0.045)
	DesignKit.rbox(root, Vector3(3.67, 0.022, 0.018), Vector3(0, 0.94, 0.579), brass, 0.008, false)
	DesignKit.rbox(root, Vector3(3.6, 0.018, 0.018), Vector3(0, 1.055, 0.63), DesignKit.washi(DesignKit.CREAM, 1.3, "sushi_edge"), 0.006, false)
	# Broad inset walnut panels with deliberate oak gaps, rather than dozens of fins.
	for i in 6:
		DesignKit.rbox(root, Vector3(0.52, 0.67, 0.024), Vector3(-1.5 + float(i) * 0.6, 0.57, 0.579), walnut, 0.012)
	# A genuine capsule-shaped closed loop: metal surround, dark segmented belt,
	# and raised central oak island leave the return path clearly visible.
	DesignKit.rbox(root, Vector3(3.84, 0.065, 0.92), Vector3(0, 1.185, -0.13), steel, 0.032)
	DesignKit.add(root, _belt_mesh(), DesignKit.paint(Color(0.23, 0.24, 0.22), 0.8), Vector3(0, 1.221, -0.13))
	DesignKit.rbox(root, Vector3(3.29, 0.048, 0.34), Vector3(0, 1.229, -0.13), oak, 0.023)
	_belt_seams(root, brass)
	# Front rail and readable directional chevrons are physical brass inlays.
	DesignKit.rbox(root, Vector3(3.0, 0.019, 0.018), Vector3(0, 1.224, 0.303), brass, 0.007, false)
	for i in 3:
		for sign_value: float in [-1.0, 1.0]:
			DesignKit.add(root, DesignKit.rounded_box(Vector3(0.09, 0.007, 0.014), 0.003), brass, Vector3(-0.8 + float(i) * 0.8, 1.255, -0.13 + sign_value * 0.026), Vector3(0, sign_value * 40.0, 0), false)
	var plate_profile: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0.075, 0), Vector2(0.085, 0.014), Vector2(0.143, 0.021), Vector2(0.155, 0.036), Vector2(0.15, 0.044), Vector2(0.126, 0.033), Vector2(0.07, 0.025), Vector2(0, 0.025)])
	var plate_mesh: Mesh = DesignKit.lathe(plate_profile, 24)
	for i in 8:
		var front_row: bool = i < 4
		var x: float = -1.14 + float(i % 4) * 0.76
		var p: Vector3 = Vector3(x, 1.225, 0.175 if front_row else -0.435)
		DesignKit.add(root, plate_mesh, ceramic if (i + v) % 2 == 0 else cream, p, Vector3.ZERO, false)
		_sushi(root, p + Vector3(0, 0.045, 0), (i + v) % 3)
	# Three compact, turned stools: solid oak pedestal, steel foot-ring, linen seat.
	for i in 3:
		var p: Vector3 = Vector3(-1.22 + float(i) * 1.22, 0, 1.15)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.235, 0), Vector2(0.25, 0.028), Vector2(0.23, 0.058), Vector2(0.075, 0.09), Vector2(0.055, 0.66), Vector2(0.15, 0.69)])), oak, p)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.174, 0.28), Vector2(0.187, 0.28), Vector2(0.192, 0.295), Vector2(0.187, 0.31), Vector2(0.174, 0.31), Vector2(0.174, 0.28)])), steel, p)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0.68), Vector2(0.245, 0.68), Vector2(0.26, 0.7), Vector2(0.255, 0.72), Vector2(0, 0.72)])), walnut, p)
		DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0.72), Vector2(0.238, 0.72), Vector2(0.25, 0.741), Vector2(0.245, 0.787), Vector2(0.22, 0.8), Vector2(0, 0.8)])), DesignKit.fabric(accent, "sushi_seat_%d" % v), p)
	# Rear chef station, separated by a usable 0.75 m working aisle.
	DesignKit.rbox(root, Vector3(2.96, 0.12, 0.54), Vector3(0, 0.06, -1.66), steel, 0.035)
	DesignKit.rbox(root, Vector3(3.12, 0.81, 0.64), Vector3(0, 0.525, -1.66), walnut, 0.065)
	DesignKit.rbox(root, Vector3(3.28, 0.09, 0.76), Vector3(0, 0.975, -1.66), stone, 0.04)
	for x: float in [-0.97, 0.0, 0.97]:
		DesignKit.rbox(root, Vector3(0.87, 0.67, 0.025), Vector3(x, 0.53, -1.325), oak, 0.018)
		DesignKit.rbox(root, Vector3(0.22, 0.028, 0.048), Vector3(x, 0.8, -1.298), brass, 0.012)
	DesignKit.rbox(root, Vector3(0.85, 0.035, 0.43), Vector3(-0.87, 1.0375, -1.59), oak, 0.025)
	# Broad knife blade on the board; handle safely oriented toward the chef aisle.
	DesignKit.rbox(root, Vector3(0.25, 0.007, 0.065), Vector3(-0.96, 1.059, -1.61), DesignKit.metal(Color(0.7, 0.72, 0.7), 0.25, 0.8, "sushi_blade"), 0.003, false)
	DesignKit.rbox(root, Vector3(0.12, 0.025, 0.035), Vector3(-0.775, 1.069, -1.61), walnut, 0.012, false)
	DesignKit.rbox(root, Vector3(0.75, 0.07, 0.4), Vector3(0.7, 1.055, -1.65), steel, 0.025)
	for i in 3:
		DesignKit.rbox(root, Vector3(0.2, 0.025, 0.3), Vector3(0.46 + float(i) * 0.24, 1.097, -1.65), cream if i == 0 else ceramic, 0.012, false)
	# Lidded rice vessel: a softly turned ceramic pot with walnut knob.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.14, 0), Vector2(0.17, 0.035), Vector2(0.18, 0.18), Vector2(0.16, 0.23), Vector2(0, 0.23)])), cream, Vector3(-0.1, 1.02, -1.7))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.035, 0), Vector2(0.028, 0.045), Vector2(0, 0.05)])), walnut, Vector3(-0.1, 1.25, -1.7))
	# Freestanding frame carries the six-language sign without a ceiling dependency.
	for x: float in [-1.78, 1.78]:
		DesignKit.rbox(root, Vector3(0.18, 0.035, 0.22), Vector3(x, 0.0175, -1.85), steel, 0.015)
		DesignKit.rbox(root, Vector3(0.055, 3.31, 0.055), Vector3(x, 1.69, -1.85), steel, 0.015)
	DesignKit.rbox(root, Vector3(3.65, 0.06, 0.07), Vector3(0, 3.35, -1.85), oak, 0.025)
	Signage.panel(root, Vector3(0, 2.61, -1.83), "sushi", {"width": 3.5, "scale": 1.12, "accent": accent})
	return root


static func _sushi(parent: Node3D, at: Vector3, kind: int) -> void:
	var rice: Material = DesignKit.stone(DesignKit.CREAM, 0.82, "sushi_rice")
	var nori: Material = DesignKit.paint(Color(0.075, 0.12, 0.085), 0.85)
	for side: float in [-1.0, 1.0]:
		var p: Vector3 = at + Vector3(0.058 * side, 0, 0)
		if kind == 2:
			DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.046, 0), Vector2(0.048, 0.067), Vector2(0, 0.067)]), 16), nori, p, Vector3.ZERO, false)
			DesignKit.add(parent, DesignKit.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.039, 0), Vector2(0.039, 0.006), Vector2(0, 0.006)]), 16), rice, p + Vector3(0, 0.067, 0), Vector3.ZERO, false)
			DesignKit.rbox(parent, Vector3(0.024, 0.009, 0.024), p + Vector3(0, 0.077, 0), DesignKit.paint(DesignKit.SAGE), 0.004, false)
		else:
			DesignKit.rbox(parent, Vector3(0.083, 0.046, 0.15), p + Vector3(0, 0.023, 0), rice, 0.022, false)
			var topping: Color = Color(0.93, 0.46, 0.29) if kind == 0 else DesignKit.OCHRE
			DesignKit.rbox(parent, Vector3(0.092, 0.025, 0.17), p + Vector3(0, 0.056, 0), DesignKit.paint(topping, 0.4), 0.012, false)
			if kind == 1:
				DesignKit.rbox(parent, Vector3(0.096, 0.029, 0.029), p + Vector3(0, 0.056, 0), nori, 0.008, false)


static func _outline(radius: float) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for end in 2:
		for i in 17:
			var angle: float = -PI * 0.5 + float(i) * PI / 16.0 + float(end) * PI
			points.append(Vector3((1.45 if end == 0 else -1.45) + cos(angle) * radius, 0, sin(angle) * radius))
	return points


static func _belt_mesh() -> ArrayMesh:
	if _meshes.has("belt"):
		return _meshes["belt"] as ArrayMesh
	var outside: PackedVector3Array = _outline(0.405)
	var inside: PackedVector3Array = _outline(0.19)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outside.size():
		var j: int = (i + 1) % outside.size()
		var vertices: Array[Vector3] = [outside[i], outside[j], inside[i], outside[j], inside[j], inside[i]]
		for point: Vector3 in vertices:
			st.set_normal(Vector3.UP)
			st.add_vertex(point)
	var mesh: ArrayMesh = st.commit()
	_meshes["belt"] = mesh
	return mesh


static func _belt_seams(parent: Node3D, material: Material) -> void:
	var transforms: Array[Transform3D] = []
	for z: float in [-0.4275, 0.1675]:
		for i in 25:
			transforms.append(Transform3D(Basis.IDENTITY, Vector3(-1.39 + float(i) * 2.78 / 24.0, 1.224, z)))
	for end in 2:
		for i in 13:
			var angle: float = -PI * 0.5 + float(i) * PI / 12.0 + float(end) * PI
			var p: Vector3 = Vector3((1.45 if end == 0 else -1.45) + cos(angle) * 0.2975, 1.224, -0.13 + sin(angle) * 0.2975)
			transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5 - angle), p))
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = DesignKit.rounded_box(Vector3(0.008, 0.005, 0.205), 0.0015)
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var seams: MultiMeshInstance3D = MultiMeshInstance3D.new()
	seams.name = "BeltLinks"
	seams.multimesh = multimesh
	seams.material_override = material
	seams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(seams)
