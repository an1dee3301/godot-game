extends RefCounted
## An open-front tea pavilion; all dimensions are metres, entrance faces +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TeaHouse"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var steel: StandardMaterial3D = DesignKit.metal()
	var textile: StandardMaterial3D = DesignKit.fabric(accent, "tea_cushion_%d" % style)
	var border: StandardMaterial3D = DesignKit.fabric(accent.darkened(0.32), "tea_heri_%d" % style)
	var tatami: StandardMaterial3D = DesignKit.fabric(Color(0.71, 0.70, 0.49), "tea_rush")
	var paper: StandardMaterial3D = DesignKit.washi(Color(1.0, 0.89 - float(style) * 0.02, 0.72), 1.15, "tea_paper_%d" % style)
	var tile: StandardMaterial3D = DesignKit.stone(DesignKit.CHARCOAL.lightened(float(style) * 0.035), 0.78, "tea_tile_%d" % style)
	# Limestone footing, floating timber deck, and a broad welcoming step.
	DesignKit.rbox(root, Vector3(2.98, 0.12, 2.98), Vector3(0.0, 0.06, 0.0), DesignKit.stone(), 0.055)
	DesignKit.rbox(root, Vector3(2.92, 0.12, 2.92), Vector3(0.0, 0.17, 0.0), walnut, 0.035)
	DesignKit.rbox(root, Vector3(2.98, 0.035, 2.98), Vector3(0.0, 0.245, 0.0), oak, 0.015)
	DesignKit.rbox(root, Vector3(1.68, 0.10, 0.34), Vector3(0.0, 0.05, 1.57), DesignKit.stone(), 0.045)
	for column in 3:
		for row in 2:
			var center: Vector3 = Vector3(-0.88 + float(column) * 0.88, 0.285, -0.66 + float(row) * 1.32)
			DesignKit.rbox(root, Vector3(0.868, 0.05, 1.308), center, tatami, 0.012)
			for side: float in [-1.0, 1.0]:
				DesignKit.rbox(root, Vector3(0.045, 0.012, 1.30), center + Vector3(side * 0.405, 0.031, 0.0), border, 0.004, false)
	# Four oak posts with durable metal shoes and exposed brass joinery pins.
	for x: float in [-1.38, 1.38]:
		for z: float in [-1.38, 1.38]:
			DesignKit.rbox(root, Vector3(0.15, 2.34, 0.15), Vector3(x, 1.43, z), oak, 0.024)
			DesignKit.rbox(root, Vector3(0.166, 0.12, 0.166), Vector3(x, 0.32, z), steel, 0.014)
			DesignKit.rbox(root, Vector3(0.05, 0.026, 0.014), Vector3(x, 2.49, z + 0.081), DesignKit.brass(), 0.006, false)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.15, 0.16, 2.94), Vector3(side * 1.38, 2.56, 0.0), oak, 0.025)
		DesignKit.rbox(root, Vector3(2.94, 0.16, 0.15), Vector3(0.0, 2.56, side * 1.38), oak, 0.025)
	# Three luminous shoji walls. Lattice pieces share one cached mesh per wall.
	_screen(root, Vector3(0.0, 1.35, -1.38), 0.0, oak, walnut, paper)
	_screen(root, Vector3(-1.38, 1.35, 0.0), 90.0, oak, walnut, paper)
	_screen(root, Vector3(1.38, 1.35, 0.0), -90.0, oak, walnut, paper)
	# Low hipped roof, timber soffit and individually rounded ceramic edge tiles.
	DesignKit.rbox(root, Vector3(3.30, 0.10, 3.30), Vector3(0.0, 2.65, 0.0), walnut, 0.045)
	DesignKit.add(root, _roof(), tile, Vector3(0.0, 2.69, 0.0))
	for edge in 4:
		var rim: Node3D = Node3D.new()
		rim.rotation_degrees.y = float(edge) * 90.0
		root.add_child(rim)
		DesignKit.add(rim, _tile_edge(), tile, Vector3(0.0, 2.70, 1.63))
	DesignKit.rbox(root, Vector3(0.64, 0.055, 0.64), Vector3(0.0, 2.995, 0.0), tile, 0.025)
	# A generous entrance fascia carries six languages in two readable lines.
	DesignKit.rbox(root, Vector3(2.56, 0.64, 0.095), Vector3(0.0, 2.23, 1.43), walnut, 0.035)
	DesignKit.rbox(root, Vector3(2.38, 0.022, 0.018), Vector3(0.0, 2.49, 1.484), DesignKit.brass(), 0.006, false)
	_caption(root, "Tea · お茶 · 茶", Vector3(0.0, 2.34, 1.485), 100)
	_caption(root, "Trà · Thé · Té", Vector3(0.0, 2.09, 1.485), 88)
	# Floor seating and a low, rounded walnut tea table.
	for side: float in [-1.0, 1.0]:
		var cushion_z: float = 0.22 + float(style % 2) * 0.10
		DesignKit.rbox(root, Vector3(0.63, 0.035, 0.63), Vector3(side * 0.77, 0.33, cushion_z), border, 0.015)
		DesignKit.rbox(root, Vector3(0.60, 0.11, 0.60), Vector3(side * 0.77, 0.39, cushion_z), textile, 0.052)
		DesignKit.rbox(root, Vector3(0.032, 0.008, 0.032), Vector3(side * 0.77, 0.447, cushion_z), border, 0.003, false)
	for x: float in [-0.39, 0.39]:
		DesignKit.rbox(root, Vector3(0.07, 0.29, 0.46), Vector3(x, 0.455, -0.36), walnut, 0.023)
	DesignKit.rbox(root, Vector3(1.05, 0.07, 0.67), Vector3(0.0, 0.635, -0.36), walnut, 0.05)
	DesignKit.rbox(root, Vector3(0.67, 0.024, 0.38), Vector3(0.0, 0.682, -0.36), oak, 0.022)
	var ceramic: StandardMaterial3D = DesignKit.paint(accent.lightened(0.20), 0.30)
	var cup: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.035, 0.0), Vector2(0.041, 0.018), Vector2(0.052, 0.083), Vector2(0.044, 0.083), Vector2(0.033, 0.022), Vector2(0.0, 0.022)]))
	for x: float in [-0.23, 0.23]:
		DesignKit.add(root, cup, ceramic, Vector3(x, 0.695, -0.29))
	var pot: ArrayMesh = DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.055, 0.0), Vector2(0.085, 0.04), Vector2(0.095, 0.09), Vector2(0.065, 0.145), Vector2(0.0, 0.145)]))
	DesignKit.add(root, pot, ceramic, Vector3(0.0, 0.695, -0.42))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.067, 0.0), Vector2(0.07, 0.014), Vector2(0.025, 0.025), Vector2(0.014, 0.045), Vector2(0.0, 0.045)])), ceramic, Vector3(0.0, 0.84, -0.42))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.034, 0.0), Vector2(0.028, 0.07), Vector2(0.018, 0.11)])), ceramic, Vector3(0.06, 0.76, -0.42), Vector3(0.0, 0.0, -55.0))
	DesignKit.rbox(root, Vector3(0.025, 0.025, 0.14), Vector3(-0.13, 0.80, -0.42), walnut, 0.01, false)
	return root


static func _screen(parent: Node3D, at: Vector3, angle: float, oak: Material, walnut: Material, paper: Material) -> void:
	var wall: Node3D = Node3D.new()
	wall.position = at
	wall.rotation_degrees.y = angle
	parent.add_child(wall)
	DesignKit.rbox(wall, Vector3(2.60, 1.80, 0.035), Vector3(0.0, 0.19, 0.0), paper, 0.012, false)
	DesignKit.rbox(wall, Vector3(2.60, 0.35, 0.075), Vector3(0.0, -0.89, 0.0), walnut, 0.018)
	DesignKit.add(wall, _lattice(), oak, Vector3.ZERO)
	for x: float in [-0.10, 0.10]:
		DesignKit.rbox(wall, Vector3(0.027, 0.12, 0.025), Vector3(x, -0.49, 0.056), DesignKit.brass(), 0.009, false)


static func _lattice() -> ArrayMesh:
	if _meshes.has("lattice"):
		return _meshes["lattice"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 9:
		var size: Vector3 = Vector3(0.045 if i == 4 else 0.026, 1.84, 0.065)
		st.append_from(DesignKit.rounded_box(size, 0.009), 0, Transform3D(Basis.IDENTITY, Vector3(-1.28 + float(i) * 0.32, 0.19, 0.0)))
	for i in 5:
		st.append_from(DesignKit.rounded_box(Vector3(2.60, 0.027, 0.065), 0.009), 0, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.71 + float(i) * 0.45, 0.0)))
	var mesh: ArrayMesh = st.commit()
	_meshes["lattice"] = mesh
	return mesh


static func _tile_edge() -> ArrayMesh:
	if _meshes.has("tile_edge"):
		return _meshes["tile_edge"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 22:
		st.append_from(DesignKit.rounded_box(Vector3(0.147, 0.085, 0.19), 0.031), 0, Transform3D(Basis.IDENTITY, Vector3(-1.575 + float(i) * 0.15, 0.0, 0.0)))
	var mesh: ArrayMesh = st.commit()
	_meshes["tile_edge"] = mesh
	return mesh


static func _roof() -> ArrayMesh:
	if _meshes.has("roof"):
		return _meshes["roof"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var turn: Basis = Basis(Vector3.UP, float(i) * PI * 0.5)
		var vertices: PackedVector3Array = PackedVector3Array([Vector3(-1.68, 0.0, 1.68), Vector3(1.68, 0.0, 1.68), Vector3(0.31, 0.29, 0.31), Vector3(-0.31, 0.29, 0.31)])
		for index: int in [0, 2, 1, 0, 3, 2]:
			st.add_vertex(turn * vertices[index])
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["roof"] = mesh
	return mesh


static func _caption(parent: Node3D, text: String, at: Vector3, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.0030
	label.position = at
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
