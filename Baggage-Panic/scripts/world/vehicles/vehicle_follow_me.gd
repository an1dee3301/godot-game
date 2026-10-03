extends RefCounted
## Apron escort: 4.5 m electric utility car, nose +Z, tyre contact at y = 0.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "FollowMeCar"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var colors: Array[Color] = [Color(0.98, 0.73, 0.12), KIT.CREAM, KIT.SAGE, KIT.CHARCOAL]
	var accents: Array[Color] = [KIT.CHARCOAL, KIT.CLAY, KIT.CREAM, Color(0.78, 0.6, 0.34)]
	var scheme: int = posmod(variant, 4)
	var body: StandardMaterial3D = KIT.paint(colors[scheme], 0.32)
	var stripe: StandardMaterial3D = KIT.paint(accents[scheme], 0.45)
	var steel: StandardMaterial3D = KIT.metal(KIT.CHARCOAL, 0.42, 0.65, "follow_me_steel")
	var rubber: StandardMaterial3D = KIT.paint(Color(0.045, 0.043, 0.039), 0.95)
	var glass: StandardMaterial3D = _glazing()
	var silver: StandardMaterial3D = KIT.metal(Color(0.57, 0.59, 0.56), 0.29, 0.9, "follow_me_alloy")
	var amber: StandardMaterial3D = KIT.washi(Color(1.0, 0.46, 0.045), 3.2, "follow_me_amber")
	var headlight: StandardMaterial3D = KIT.washi(Color(1.0, 0.93, 0.75), 2.8, "follow_me_headlight")
	var red: StandardMaterial3D = KIT.washi(Color(0.8, 0.045, 0.02), 1.6, "follow_me_tail")
	KIT.rbox(root, Vector3(1.62, 0.19, 3.88), Vector3(0, 0.59, 0), steel, 0.08)
	# Eight-point bevel sections give a tapered bonnet and softened rear shoulders.
	var body_sections: Array[Vector4] = [Vector4(-2.14, 0.77, 0.69, 1.03), Vector4(-1.88, 0.89, 0.66, 1.15), Vector4(-1.25, 0.92, 0.66, 1.2), Vector4(0.86, 0.92, 0.66, 1.16), Vector4(1.73, 0.87, 0.68, 1.05), Vector4(2.13, 0.76, 0.74, 0.96)]
	KIT.add(root, _shell("body", body_sections, 0.1), body, Vector3.ZERO)
	var cabin_sections: Array[Vector4] = [Vector4(-1.42, 0.79, 1.1, 1.3), Vector4(-0.97, 0.75, 1.12, 1.78), Vector4(0.53, 0.74, 1.12, 1.78), Vector4(1.05, 0.8, 1.12, 1.23)]
	KIT.add(root, _shell("cabin", cabin_sections, 0.07), glass, Vector3.ZERO)
	KIT.rbox(root, Vector3(1.52, 0.1, 1.67), Vector3(0, 1.78, -0.22), body, 0.045)
	# Pillars follow the sloping glass, with a warm roof rail and lower window seals.
	for side: float in [-1.0, 1.0]:
		var x: float = side * 0.8
		_bar(root, Vector3(side * 0.75, 1.74, 0.52), Vector3(side * 0.83, 1.16, 1.04), 0.075, body)
		_bar(root, Vector3(side * 0.76, 1.74, -0.97), Vector3(side * 0.84, 1.17, -1.4), 0.09, body)
		_bar(root, Vector3(side * 0.78, 1.18, -0.3), Vector3(side * 0.73, 1.73, -0.3), 0.07, steel)
		KIT.rbox(root, Vector3(0.055, 0.055, 2.32), Vector3(x, 1.17, -0.16), steel, 0.018)
		KIT.rbox(root, Vector3(0.045, 0.035, 1.52), Vector3(side * 0.61, 1.85, -0.23), KIT.brass(), 0.012)
		# Door cuts, recessed pulls, protective sill and broad operator stripe.
		KIT.rbox(root, Vector3(0.03, 0.42, 0.014), Vector3(side * 0.924, 0.91, -0.3), steel, 0.005)
		KIT.rbox(root, Vector3(0.028, 0.16, 2.3), Vector3(side * 0.926, 0.82, -0.13), stripe, 0.012)
		KIT.rbox(root, Vector3(0.055, 0.075, 0.25), Vector3(side * 0.93, 1.075, -0.66), steel, 0.025)
		KIT.rbox(root, Vector3(0.055, 0.075, 0.25), Vector3(side * 0.93, 1.075, 0.34), steel, 0.025)
		KIT.rbox(root, Vector3(0.09, 0.08, 2.13), Vector3(side * 0.91, 0.64, -0.08), steel, 0.03)
		_bar(root, Vector3(side * 0.8, 1.25, 0.72), Vector3(side * 1.01, 1.3, 0.72), 0.045, steel)
		KIT.rbox(root, Vector3(0.17, 0.17, 0.26), Vector3(side * 1.055, 1.31, 0.72), body, 0.055)
		KIT.rbox(root, Vector3(0.13, 0.115, 0.015), Vector3(side * 1.055, 1.31, 0.58), silver, 0.025, false)
		for axle: float in [-1.35, 1.35]:
			KIT.add(root, _tyre(), rubber, Vector3(side * 0.91, 0.36, axle), Vector3(0, 0, 90))
			KIT.add(root, _hub(), silver, Vector3(side * 1.055, 0.36, axle), Vector3(0, 0, 90))
			KIT.add(root, _hub_cap(), steel, Vector3(side * 1.086, 0.36, axle), Vector3(0, 0, 90), false)
		# Side-mounted guidance boards, large enough to read at terminal-side distances.
		var board: Node3D = Node3D.new()
		board.position = Vector3(side * 0.96, 1.01, -0.06)
		board.rotation_degrees.y = side * 90.0
		root.add_child(board)
		KIT.rbox(board, Vector3(1.96, 0.61, 0.035), Vector3.ZERO, steel, 0.025)
		_caption(board, "FOLLOW ME", Vector3(0, 0.17, 0.024), 1.78, 0.003, 100, KIT.CREAM)
		_caption(board, "ついてきて · 跟随我", Vector3(0, -0.055, 0.024), 1.79, 0.0024, 76, KIT.CREAM)
		# Split the remaining languages between the two sides to keep lettering generous.
		var translation: String = "Theo tôi · Suivez-moi" if side > 0.0 else "Suivez-moi · Sígueme"
		_caption(board, translation, Vector3(0, -0.225, 0.024), 1.79, 0.0024, 70, KIT.CREAM)
	# Layered bumpers, inset grille, broad lamp lenses and amber corner markers.
	for end: float in [-1.0, 1.0]:
		KIT.rbox(root, Vector3(1.68, 0.17, 0.19), Vector3(0, 0.7, end * 2.15), steel, 0.065)
		KIT.rbox(root, Vector3(1.27, 0.035, 0.035), Vector3(0, 0.78, end * 2.245), silver, 0.012)
		for side: float in [-1.0, 1.0]:
			KIT.rbox(root, Vector3(0.35, 0.15, 0.07), Vector3(side * 0.57, 0.9, end * 2.12), steel, 0.04)
			KIT.rbox(root, Vector3(0.29, 0.095, 0.075), Vector3(side * 0.57, 0.91, end * 2.16), headlight if end > 0 else red, 0.03, false)
			KIT.rbox(root, Vector3(0.055, 0.07, 0.08), Vector3(side * 0.77, 0.9, end * 2.09), amber, 0.02, false)
	KIT.rbox(root, Vector3(0.66, 0.13, 0.045), Vector3(0, 0.9, 2.139), steel, 0.035)
	for row in 3:
		KIT.rbox(root, Vector3(0.55, 0.012, 0.016), Vector3(0, 0.86 + float(row) * 0.038, 2.17), silver, 0.004, false)
	_bar(root, Vector3(-0.5, 1.19, 0.99), Vector3(-0.13, 1.23, 0.94), 0.02, steel)
	_bar(root, Vector3(0.07, 1.19, 0.99), Vector3(0.44, 1.23, 0.94), 0.02, steel)
	# Roof sign: sturdy mount, black border, warm luminous face and checker courses.
	for x: float in [-0.57, 0.57]:
		KIT.rbox(root, Vector3(0.07, 0.18, 0.39), Vector3(x, 1.91, -0.3), steel, 0.02)
	KIT.rbox(root, Vector3(1.8, 0.69, 0.23), Vector3(0, 2.28, -0.3), steel, 0.06)
	var sign_face: StandardMaterial3D = KIT.washi(Color(1.0, 0.79, 0.24), 0.65, "follow_me_sign")
	for end: float in [-1.0, 1.0]:
		var face: Node3D = Node3D.new()
		face.position = Vector3(0, 2.28, -0.3 + end * 0.12)
		face.rotation_degrees.y = 0.0 if end > 0 else 180.0
		root.add_child(face)
		KIT.rbox(face, Vector3(1.7, 0.6, 0.015), Vector3.ZERO, sign_face, 0.025, false)
		_caption(face, "FOLLOW ME", Vector3(0, 0, 0.015), 1.58, 0.0037, 140, KIT.CHARCOAL)
		_checkers(face, steel)
	# Amber beacon behind the sign remains visible above it from distant sightlines.
	KIT.add(root, _beacon(false), steel, Vector3(0, 1.83, -0.91))
	KIT.add(root, _beacon(true), amber, Vector3(0, 2.35, -0.91), Vector3.ZERO, false)
	KIT.rbox(root, Vector3(0.21, 0.024, 0.21), Vector3(0, 2.64, -0.91), silver, 0.012, false)
	return root


static func _caption(parent: Node3D, text: String, at: Vector3, width: float, pixel: float, size: int, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = SIGNS.font()
	label.text = text
	label.pixel_size = pixel
	var measured: float = label.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * pixel
	label.font_size = mini(size, int(float(size) * width / maxf(measured, 0.001)))
	label.position = at
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _checkers(parent: Node3D, material: Material) -> void:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = KIT.rounded_box(Vector3(0.14, 0.085, 0.008), 0.003)
	batch.instance_count = 24
	var index: int = 0
	for course in 2:
		for row in 2:
			for col in 12:
				if (col + row) % 2 == 0:
					var y: float = (-0.255 if course == 0 else 0.17) + float(row) * 0.085
					batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(-0.77 + float(col) * 0.14, y, 0.014)))
					index += 1
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _bar(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, material: Material) -> void:
	var delta: Vector3 = finish - start
	var node: MeshInstance3D = KIT.rbox(parent, Vector3(thickness, delta.length(), thickness), (start + finish) * 0.5, material, thickness * 0.35)
	node.quaternion = Quaternion(Vector3.UP, delta.normalized())


static func _glazing() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.1, 0.19, 0.2)
		material.metallic = 0.45
		material.roughness = 0.16
		_materials["glass"] = material
	return _materials["glass"] as StandardMaterial3D


static func _tyre() -> ArrayMesh:
	return KIT.lathe(PackedVector2Array([Vector2(0, -0.13), Vector2(0.25, -0.13), Vector2(0.32, -0.115), Vector2(0.355, -0.07), Vector2(0.36, 0.07), Vector2(0.32, 0.115), Vector2(0.25, 0.13), Vector2(0, 0.13)]), 32)


static func _hub() -> ArrayMesh:
	return KIT.lathe(PackedVector2Array([Vector2(0, -0.02), Vector2(0.21, -0.02), Vector2(0.23, 0), Vector2(0.21, 0.025), Vector2(0.15, 0.035), Vector2(0, 0.035)]), 24)


static func _hub_cap() -> ArrayMesh:
	return KIT.lathe(PackedVector2Array([Vector2(0, -0.014), Vector2(0.095, -0.014), Vector2(0.1, 0), Vector2(0.08, 0.025), Vector2(0, 0.025)]), 16)


static func _beacon(lens: bool) -> ArrayMesh:
	if lens:
		return KIT.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.135, 0), Vector2(0.135, 0.18), Vector2(0.11, 0.27), Vector2(0.07, 0.29), Vector2(0, 0.29)]), 24)
	return KIT.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.16, 0), Vector2(0.16, 0.055), Vector2(0.055, 0.09), Vector2(0.055, 0.5), Vector2(0.15, 0.52), Vector2(0, 0.52)]), 20)


static func _shell(key: String, sections: Array[Vector4], bevel: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var rings: Array[PackedVector3Array] = []
	for section: Vector4 in sections:
		var z: float = section.x
		var w: float = section.y
		var bottom: float = section.z
		var top: float = section.w
		rings.append(PackedVector3Array([Vector3(-w + bevel, bottom, z), Vector3(w - bevel, bottom, z), Vector3(w, bottom + bevel, z), Vector3(w, top - bevel, z), Vector3(w - bevel, top, z), Vector3(-w + bevel, top, z), Vector3(-w, top - bevel, z), Vector3(-w, bottom + bevel, z)]))
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for station in rings.size() - 1:
		var a: PackedVector3Array = rings[station]
		var b: PackedVector3Array = rings[station + 1]
		for edge in 8:
			var next: int = (edge + 1) % 8
			_triangle(surface, a[edge], b[edge], b[next])
			_triangle(surface, a[edge], b[next], a[next])
	var rear: PackedVector3Array = rings[0]
	var front: PackedVector3Array = rings[rings.size() - 1]
	for i in range(1, 7):
		_triangle(surface, rear[0], rear[i], rear[i + 1])
		_triangle(surface, front[0], front[i + 1], front[i])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
