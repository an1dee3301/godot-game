extends RefCounted
## Three hand-painted daruma on a stepped oak cultural display. Front is +Z.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DarumaDisplay"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var oak: StandardMaterial3D = Kit.wood()
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "daruma_walnut")
	var brass: StandardMaterial3D = Kit.brass()
	var accent: Color = Kit.SAGE if choice % 2 == 0 else Kit.CLAY
	# Continuous stone foot, recessed shadow reveal, and softly routed oak tiers.
	Kit.rbox(root, Vector3(5.35, 0.18, 1.8), Vector3(0.0, 0.09, 0.0), Kit.stone(), 0.07)
	Kit.rbox(root, Vector3(5.12, 0.08, 1.57), Vector3(0.0, 0.22, 0.0), walnut, 0.03)
	Kit.rbox(root, Vector3(5.5, 0.25, 1.9), Vector3(0.0, 0.385, 0.0), oak, 0.08)
	Kit.rbox(root, Vector3(5.26, 0.024, 0.025), Vector3(0.0, 0.31, 0.947), brass, 0.008)
	Kit.rbox(root, Vector3(1.61, 0.3, 1.55), Vector3(0.0, 0.66, -0.08), oak, 0.065)
	Kit.rbox(root, Vector3(1.58, 0.14, 1.5), Vector3(1.73, 0.58, -0.04), oak, 0.05)
	var colors: Array[Color] = [Color(0.65, 0.13, 0.095), Kit.CREAM, Color(0.79, 0.57, 0.23)]
	var places: Array[Vector3] = [Vector3(-1.73, 0.515, 0.03), Vector3(0.0, 0.815, -0.08), Vector3(1.73, 0.655, -0.04)]
	var scales: Array[float] = [1.04, 1.17, 0.94]
	for i: int in 3:
		var color_index: int = (i + choice) % 3
		_doll(root, places[i], scales[i], colors[color_index], color_index == 2, choice == 3 or i == choice % 3, accent)
	# Rear posts are grounded in the plinth; the sign clears the tallest doll.
	for x: float in [-2.38, 2.38]:
		Kit.rbox(root, Vector3(0.09, 3.42, 0.09), Vector3(x, 1.97, -0.73), Kit.metal(), 0.025)
		Kit.rbox(root, Vector3(0.18, 0.045, 0.18), Vector3(x, 0.529, -0.73), brass, 0.015)
	Kit.rbox(root, Vector3(5.5, 1.37, 0.18), Vector3(0.0, 3.6, -0.71), walnut, 0.08)
	Kit.rbox(root, Vector3(5.28, 1.15, 0.035), Vector3(0.0, 3.6, -0.606), Kit.washi(Kit.CREAM, 0.55, "daruma_sign"), 0.045, false)
	Kit.rbox(root, Vector3(5.05, 0.018, 0.022), Vector3(0.0, 3.54, -0.58), brass, 0.007, false)
	_caption(root, "DARUMA  /  達磨 · 达摩", Vector3(0.0, 3.96, -0.577), 104, 0.0034, Kit.CHARCOAL)
	var welcome: Array = Signs.TEXT["welcome"]
	_caption(root, "%s  ·  %s  ·  %s" % [welcome[0], welcome[1], welcome[2]], Vector3(0.0, 3.65, -0.577), 68, 0.0034, Kit.CHARCOAL)
	_caption(root, "%s  ·  %s  ·  %s" % [welcome[3], welcome[4], welcome[5]], Vector3(0.0, 3.28, -0.577), 64, 0.0034, Kit.CHARCOAL)
	return root


static func _doll(parent: Node3D, at: Vector3, size: float, color: Color, gold: bool, completed: bool, accent: Color) -> void:
	var doll: Node3D = Node3D.new()
	doll.name = "Daruma"
	doll.position = at
	doll.scale = Vector3.ONE * size
	parent.add_child(doll)
	var lacquer: StandardMaterial3D = Kit.paint(color, 0.29)
	if gold:
		lacquer = Kit.metal(color, 0.38, 0.65, "daruma_gold")
	var ink: StandardMaterial3D = Kit.paint(Kit.CHARCOAL, 0.7)
	var cream: StandardMaterial3D = Kit.paint(Kit.CREAM, 0.65)
	# Linen presentation cushion and turned walnut base conceal the weighted flat foot.
	Kit.rbox(doll, Vector3(1.23, 0.055, 1.14), Vector3(0.0, 0.0275, 0.0), Kit.fabric(accent, "daruma_cushion_%s" % accent.to_html()), 0.025)
	Kit.add(doll, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.055), Vector2(0.42, 0.055), Vector2(0.46, 0.075), Vector2(0.46, 0.11), Vector2(0.42, 0.13), Vector2(0.0, 0.13)]), 40), Kit.wood(Kit.WALNUT, "daruma_walnut"), Vector3.ZERO)
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.12), Vector2(0.38, 0.12), Vector2(0.49, 0.17), Vector2(0.59, 0.3), Vector2(0.66, 0.48), Vector2(0.68, 0.67), Vector2(0.66, 0.87), Vector2(0.61, 1.08), Vector2(0.54, 1.27), Vector2(0.43, 1.43), Vector2(0.28, 1.54), Vector2(0.12, 1.6), Vector2(0.0, 1.61)])
	Kit.add(doll, Kit.lathe(profile, 64), lacquer, Vector3.ZERO)
	_oval(doll, Vector3(0.0, 1.045, 0.55), Vector3(0.88, 0.8, 0.41), Kit.paint(Color(0.83, 0.66, 0.43), 0.65))
	_oval(doll, Vector3(0.0, 1.045, 0.563), Vector3(0.84, 0.78, 0.4), cream)
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = Vector2(side * 0.17, 0.05)
		var z: float = _face_point(eye).z
		_oval(doll, Vector3(eye.x, 1.045 + eye.y, z), Vector3(0.235, 0.22, 0.025), ink)
		_oval(doll, Vector3(eye.x, 1.045 + eye.y, z + 0.014), Vector3(0.195, 0.183, 0.022), cream)
		if side < 0.0 or completed:
			_oval(doll, Vector3(eye.x, 1.045 + eye.y, z + 0.029), Vector3(0.095, 0.106, 0.018), ink)
		# Broad gold robe strokes retain legibility beside the belly character.
		for j: int in 3:
			var stripe: MeshInstance3D = Kit.rbox(doll, Vector3(0.035, 0.23 - float(j) * 0.025, 0.023), Vector3(side * (0.28 + float(j) * 0.073), 0.43 + float(j) * 0.025, 0.625 - float(j) * 0.043), Kit.brass(), 0.01, false)
			stripe.rotation_degrees.z = side * (12.0 + float(j) * 9.0)
	Kit.add(doll, _brush_mesh(), ink, Vector3.ZERO, Vector3.ZERO, false)
	_caption(doll, "福", Vector3(0.0, 0.415, 0.673), 108, 0.0039, Kit.CHARCOAL if gold else Kit.CREAM)


static func _oval(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> void:
	if not _meshes.has("sphere"):
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 40
		sphere.rings = 24
		_meshes["sphere"] = sphere
	var mesh: Mesh = _meshes["sphere"]
	var instance: MeshInstance3D = Kit.add(parent, mesh, material, at)
	instance.scale = dimensions


static func _face_point(p: Vector2) -> Vector3:
	var depth: float = 0.2 * sqrt(maxf(0.0, 1.0 - pow(p.x / 0.42, 2.0) - pow(p.y / 0.39, 2.0)))
	return Vector3(p.x, 1.045 + p.y, 0.571 + depth)


static func _brush_mesh() -> ArrayMesh:
	if _meshes.has("brush"):
		return _meshes["brush"] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Mirror crane-like brows and flowing turtle-like beard strokes, all in one mesh.
	for side: float in [-1.0, 1.0]:
		_ribbon(st, PackedVector2Array([Vector2(0.055 * side, 0.155), Vector2(0.12 * side, 0.23), Vector2(0.21 * side, 0.255), Vector2(0.29 * side, 0.20)]), 0.057)
		_ribbon(st, PackedVector2Array([Vector2(0.08 * side, 0.185), Vector2(0.15 * side, 0.29), Vector2(0.22 * side, 0.3)]), 0.022)
		_ribbon(st, PackedVector2Array([Vector2(0.025 * side, -0.12), Vector2(0.1 * side, -0.10), Vector2(0.19 * side, -0.17), Vector2(0.27 * side, -0.15)]), 0.043)
		_ribbon(st, PackedVector2Array([Vector2(0.07 * side, -0.20), Vector2(0.13 * side, -0.26), Vector2(0.21 * side, -0.24), Vector2(0.26 * side, -0.21)]), 0.026)
		_ribbon(st, PackedVector2Array([Vector2(0.045 * side, -0.23), Vector2(0.075 * side, -0.31), Vector2(0.15 * side, -0.30)]), 0.024)
	_ribbon(st, PackedVector2Array([Vector2(-0.055, -0.065), Vector2(0.0, -0.085), Vector2(0.055, -0.065)]), 0.019)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["brush"] = mesh
	return mesh


static func _ribbon(st: SurfaceTool, points: PackedVector2Array, width: float) -> void:
	for i: int in points.size() - 1:
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		var tangent: Vector2 = (end - start).normalized()
		var offset: Vector2 = Vector2(-tangent.y, tangent.x) * width * 0.5
		# Short subdivisions follow the curved cheek; clockwise faces point toward +Z.
		for step: int in 6:
			var a: Vector2 = start.lerp(end, float(step) / 6.0)
			var b: Vector2 = start.lerp(end, float(step + 1) / 6.0)
			var vertices: Array[Vector2] = [a - offset, b + offset, b - offset, a - offset, a + offset, b + offset]
			for p: Vector2 in vertices:
				st.add_vertex(_face_point(p))


static func _caption(parent: Node3D, text: String, at: Vector3, font_size: int, pixel_size: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font = Signs.font()
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
