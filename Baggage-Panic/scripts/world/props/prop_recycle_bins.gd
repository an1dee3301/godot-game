extends RefCounted
## Four removable liners behind softly folded metal doors; all dimensions are metres.

const KIT = preload("res://scripts/world/design_kit.gd")
const SIGNS = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}

static var _captions: Array[PackedStringArray] = [
	PackedStringArray(["Burnable", "もえるごみ", "可燃垃圾", "Rác cháy", "À brûler", "Quemables"]),
	PackedStringArray(["PET", "ペットボトル", "塑料瓶", "Chai PET", "Bouteilles", "Botellas"]),
	PackedStringArray(["Cans", "缶", "易拉罐", "Lon", "Canettes", "Latas"]),
	PackedStringArray(["Paper", "紙", "纸类", "Giấy", "Papier", "Papel"]),
]


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "RecycleStation"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: StandardMaterial3D = KIT.wood(KIT.OAK, "oak")
	var dark: StandardMaterial3D = KIT.metal(KIT.CHARCOAL, 0.48, 0.7, "recycle_recess")
	var shell_tint: Color = KIT.PLASTER if style < 2 else KIT.LINEN
	var shell: StandardMaterial3D = KIT.paint(shell_tint, 0.74)
	var base: StandardMaterial3D = KIT.stone(KIT.LIMESTONE, 0.72, "recycle_honed_base")
	var trim: StandardMaterial3D = KIT.brass() if style % 2 == 0 else dark
	var colours: Array[Color] = [KIT.CLAY, KIT.SAGE, KIT.INDIGO, KIT.OCHRE]
	var slots: Array[Vector2] = [Vector2(0.60, 0.19), Vector2(0.32, 0.19), Vector2(0.38, 0.17), Vector2(0.65, 0.075)]
	# Recessed stone toe-kick touches the floor; oak wraps the ends and caps the carcass.
	KIT.rbox(root, Vector3(3.94, 0.11, 0.70), Vector3(0.0, 0.055, -0.015), base, 0.035)
	KIT.rbox(root, Vector3(4.10, 1.02, 0.76), Vector3(0.0, 0.65, -0.045), shell, 0.07)
	KIT.rbox(root, Vector3(4.22, 0.09, 0.88), Vector3(0.0, 1.205, 0.0), oak, 0.035)
	KIT.rbox(root, Vector3(4.03, 0.018, 0.016), Vector3(0.0, 1.15, 0.394), trim, 0.006, false)
	for side: float in [-1.0, 1.0]:
		KIT.rbox(root, Vector3(0.08, 1.01, 0.78), Vector3(side * 2.04, 0.65, -0.045), oak, 0.028)
	# Raised multilingual fascia is supported by the rear wall, rather than floating above it.
	KIT.rbox(root, Vector3(4.10, 2.04, 0.075), Vector3(0.0, 1.26, -0.37), oak, 0.03)
	for index: int in 4:
		var x: float = (float(index) - 1.5) * 1.015
		var accent: Color = colours[index]
		if style == 1:
			accent = accent.lightened(0.08)
		elif style == 3:
			accent = accent.darkened(0.08)
		var enamel: StandardMaterial3D = KIT.paint(accent, 0.58)
		# Deep, shadowed seam around each separate service door.
		KIT.rbox(root, Vector3(0.984, 0.74, 0.025), Vector3(x, 0.52, 0.345), dark, 0.035)
		KIT.rbox(root, Vector3(0.958, 0.71, 0.038), Vector3(x, 0.52, 0.362), shell, 0.03)
		KIT.rbox(root, Vector3(0.60, 0.51, 0.017), Vector3(x, 0.55, 0.391), enamel, 0.055, false)
		KIT.add(root, _pictogram(index), KIT.paint(KIT.CREAM), Vector3(x, 0.56, 0.403), Vector3.ZERO, false)
		# Finger pull with a real gap, and an inset brass maintenance latch.
		KIT.rbox(root, Vector3(0.19, 0.033, 0.025), Vector3(x, 0.212, 0.39), dark, 0.012, false)
		KIT.rbox(root, Vector3(0.22, 0.023, 0.032), Vector3(x, 0.23, 0.406), trim, 0.009, false)
		KIT.add(root, KIT.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.016, 0.0), Vector2(0.016, 0.007), Vector2(0.0, 0.007)]), 12), trim, Vector3(x + 0.39, 0.28, 0.384), Vector3(-90.0, 0.0, 0.0), false)
		# A bevelled open frame surrounds a recessed black liner: no painted-on slot.
		var opening: Vector2 = slots[index]
		KIT.add(root, _intake_mesh(opening), enamel, Vector3(x, 1.005, 0.445))
		KIT.rbox(root, Vector3(0.89, 0.26, 0.012), Vector3(x, 1.005, 0.347), dark, 0.025, false)
		# Porcelain-like sign faces: six substantial lines, no small service labels.
		KIT.rbox(root, Vector3(0.954, 0.985, 0.023), Vector3(x, 1.755, -0.316), KIT.paint(KIT.CREAM), 0.025, false)
		KIT.rbox(root, Vector3(0.89, 0.022, 0.012), Vector3(x, 2.223, -0.3), enamel, 0.008, false)
		var captions: PackedStringArray = _captions[index]
		for line: int in 6:
			_label(root, captions[line], Vector3(x, 2.12 - float(line) * 0.153, -0.298), 80 if line == 0 else 60, 0.89)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, font_size: int, width: float) -> void:
	var label: Label3D = Label3D.new()
	label.font = SIGNS.font()
	label.text = caption
	label.pixel_size = 0.0022
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x * label.pixel_size
	label.font_size = mini(font_size, int(float(font_size) * width / maxf(measured, 0.001)))
	label.modulate = KIT.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


## Rounded-rectangle loops in the XY plane, counterclockwise when viewed from +Z.
static func _loop(size: Vector2, radius: float, depth: float) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	var half: Vector2 = size * 0.5
	var r: float = minf(radius, minf(half.x, half.y) - 0.001)
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var centre: Vector2 = Vector2(half.x - r, half.y - r)
		if corner == 1 or corner == 2:
			centre.x *= -1.0
		if corner >= 2:
			centre.y *= -1.0
		for step: int in 6:
			var theta: float = angle + float(step) / 5.0 * PI * 0.5
			var point: Vector2 = centre + Vector2(cos(theta), sin(theta)) * r
			points.append(Vector3(point.x, point.y, depth))
	return points


static func _intake_mesh(opening: Vector2) -> ArrayMesh:
	var key: String = "intake:%s" % opening
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Outer wall, softened front edge, face, inner bevel, and the deep throat wall.
	var rings: Array[PackedVector3Array] = [
		_loop(Vector2(0.94, 0.30), 0.045, -0.095),
		_loop(Vector2(0.94, 0.30), 0.045, -0.012),
		_loop(Vector2(0.922, 0.282), 0.038, 0.0),
		_loop(opening + Vector2(0.02, 0.02), 0.037, 0.0),
		_loop(opening, 0.027, -0.012),
		_loop(opening, 0.027, -0.095),
	]
	for band: int in rings.size() - 1:
		var a: PackedVector3Array = rings[band]
		var b: PackedVector3Array = rings[band + 1]
		for point: int in a.size():
			var next: int = (point + 1) % a.size()
			# Godot front faces use clockwise winding.
			for vertex: Vector3 in [a[point], b[point], a[next], a[next], b[point], b[next]]:
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


## Large vector silhouettes; the paper and can use negative space for their detail.
static func _pictogram(kind: int) -> ArrayMesh:
	var key: String = "pictogram:%d" % kind
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var shapes: Array[PackedVector2Array] = []
	match kind:
		0:
			shapes.append(PackedVector2Array([Vector2(-0.08, -0.17), Vector2(-0.15, -0.09), Vector2(-0.14, 0.01), Vector2(-0.08, 0.11), Vector2(-0.075, 0.005), Vector2(-0.015, 0.07), Vector2(0.025, 0.20), Vector2(0.105, 0.09), Vector2(0.15, -0.035), Vector2(0.13, -0.12), Vector2(0.07, -0.17)]))
		1:
			shapes.append(PackedVector2Array([Vector2(-0.075, -0.18), Vector2(0.075, -0.18), Vector2(0.092, -0.155), Vector2(0.092, 0.065), Vector2(0.038, 0.13), Vector2(0.038, 0.18), Vector2(-0.038, 0.18), Vector2(-0.038, 0.13), Vector2(-0.092, 0.065), Vector2(-0.092, -0.155)]))
			shapes.append(_rect(-0.045, 0.191, 0.09, 0.022))
		2:
			shapes.append(PackedVector2Array([Vector2(-0.105, -0.14), Vector2(-0.082, -0.175), Vector2(0.082, -0.175), Vector2(0.105, -0.14), Vector2(0.105, 0.14), Vector2(0.075, 0.14), Vector2(0.075, -0.135), Vector2(-0.075, -0.135), Vector2(-0.075, 0.14), Vector2(-0.105, 0.14)]))
			shapes.append(PackedVector2Array([Vector2(-0.105, 0.155), Vector2(-0.075, 0.18), Vector2(0.075, 0.18), Vector2(0.105, 0.155), Vector2(0.075, 0.135), Vector2(-0.075, 0.135)]))
			shapes.append(_rect(-0.055, -0.09, 0.025, 0.18))
			shapes.append(_rect(0.03, -0.09, 0.025, 0.18))
		3:
			shapes.append(PackedVector2Array([Vector2(-0.13, -0.175), Vector2(0.13, -0.175), Vector2(0.13, 0.085), Vector2(0.035, 0.18), Vector2(-0.13, 0.18), Vector2(-0.13, 0.15), Vector2(0.02, 0.15), Vector2(0.10, 0.07), Vector2(0.10, -0.145), Vector2(-0.10, -0.145), Vector2(-0.10, 0.15), Vector2(-0.13, 0.15)]))
			shapes.append(PackedVector2Array([Vector2(0.02, 0.145), Vector2(0.02, 0.06), Vector2(0.10, 0.06)]))
			shapes.append(_rect(-0.065, -0.012, 0.13, 0.025))
			shapes.append(_rect(-0.065, -0.078, 0.13, 0.025))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for polygon: PackedVector2Array in shapes:
		var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
		for triangle: int in range(0, triangles.size(), 3):
			var a: Vector2 = polygon[triangles[triangle]]
			var b: Vector2 = polygon[triangles[triangle + 1]]
			var c: Vector2 = polygon[triangles[triangle + 2]]
			if (b - a).cross(c - a) > 0.0:
				var swap: Vector2 = b
				b = c
				c = swap
			for point: Vector2 in [a, b, c]:
				st.set_normal(Vector3.FORWARD * -1.0)
				st.add_vertex(Vector3(point.x, point.y, 0.0))
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _rect(x: float, y: float, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + width, y), Vector2(x + width, y + height), Vector2(x, y + height)])
