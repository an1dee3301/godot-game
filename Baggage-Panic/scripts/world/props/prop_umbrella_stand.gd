extends RefCounted
## Open oak sharing rack; folded rain umbrellas sit tip-down in a removable drip tray.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "UmbrellaSharingStand"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var oak: Material = Kit.wood()
	var walnut: Material = Kit.wood(Kit.WALNUT, "umbrella_walnut")
	var steel: Material = Kit.metal()
	var brass: Material = Kit.brass()
	var colors: Array[Color] = [Kit.SAGE, Kit.CLAY, Kit.INDIGO, Kit.OCHRE, Color(0.37, 0.57, 0.61), Color(0.65, 0.37, 0.43)]
	var accent: Color = colors[style]
	# Four oak legs with black ferrules: the bottom of each ferrule touches y = 0.
	for x: float in [-0.84, 0.84]:
		for z: float in [-0.27, 0.27]:
			Kit.rbox(root, Vector3(0.075, 0.10, 0.075), Vector3(x, 0.05, z), steel, 0.018)
			Kit.rbox(root, Vector3(0.07, 0.92, 0.07), Vector3(x, 0.54, z), oak, 0.021)
		# Tall rear uprights support the sign without enclosing the umbrellas.
		Kit.rbox(root, Vector3(0.065, 1.61, 0.065), Vector3(x, 1.74, -0.27), oak, 0.02)
		Kit.rbox(root, Vector3(0.07, 0.08, 0.07), Vector3(x, 1.30, -0.27), brass, 0.012, false)
		Kit.rbox(root, Vector3(0.07, 0.07, 0.61), Vector3(x, 0.93, 0.0), oak, 0.022)
	for y: float in [0.19, 0.93]:
		for z: float in [-0.27, 0.27]:
			Kit.rbox(root, Vector3(1.69, 0.07, 0.065), Vector3(0.0, y, z), oak, 0.022)
	# Honed limestone bed, recessed steel insert and raised lip contain wet umbrella tips.
	Kit.rbox(root, Vector3(1.67, 0.075, 0.55), Vector3(0.0, 0.16, 0.0), Kit.stone(), 0.035)
	Kit.rbox(root, Vector3(1.51, 0.022, 0.42), Vector3(0.0, 0.207, 0.0), steel, 0.01)
	for z: float in [-0.22, 0.22]:
		Kit.rbox(root, Vector3(1.55, 0.04, 0.025), Vector3(0.0, 0.224, z), steel, 0.01)
	for x: float in [-0.77, 0.77]:
		Kit.rbox(root, Vector3(0.025, 0.04, 0.44), Vector3(x, 0.224, 0.0), steel, 0.01)
	# Slotted upper rack: crossbars divide eight open wells rather than a solid shelf.
	Kit.rbox(root, Vector3(1.65, 0.035, 0.032), Vector3(0.0, 0.925, 0.0), brass, 0.012)
	for x: float in [-0.60, -0.20, 0.20, 0.60]:
		Kit.rbox(root, Vector3(0.028, 0.035, 0.49), Vector3(x, 0.925, 0.0), brass, 0.011)
	for i: int in 8:
		# One empty well on alternating variants suggests an active sharing service.
		if style % 2 == 1 and i == 6:
			continue
		var x: float = -0.64 + float(i % 4) * 0.40
		var z: float = -0.135 if i < 4 else 0.135
		var tint: Color = colors[(i + style) % colors.size()]
		var umbrella: Node3D = Node3D.new()
		umbrella.name = "FoldedUmbrella_%d" % i
		umbrella.position = Vector3(x, 0.22, z)
		umbrella.rotation_degrees.y = float((i * 37 + style * 24) % 100) - 50.0
		root.add_child(umbrella)
		var cloth: Material = Kit.fabric(tint, "umbrella_" + tint.to_html())
		Kit.add(umbrella, _folded_mesh(), cloth, Vector3(0.0, 0.045, 0.0))
		Kit.add(umbrella, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.009, 0.0), Vector2(0.009, 0.82), Vector2(0.0, 0.82)]), 12), steel, Vector3.ZERO)
		Kit.add(umbrella, Kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.014, 0.0), Vector2(0.018, 0.015), Vector2(0.018, 0.048), Vector2(0.0, 0.048)]), 12), brass, Vector3.ZERO)
		Kit.add(umbrella, _handle_mesh(), walnut, Vector3(0.0, 0.80, 0.0))
		# Woven closure band and visible brass snap on the front of each folded canopy.
		Kit.add(umbrella, Kit.lathe(PackedVector2Array([Vector2(0.048, 0.0), Vector2(0.057, 0.0), Vector2(0.057, 0.025), Vector2(0.048, 0.025)]), 24), Kit.fabric(tint.darkened(0.22), "umbrella_band_" + tint.to_html()), Vector3(0.0, 0.48, 0.0))
		Kit.rbox(umbrella, Vector3(0.015, 0.016, 0.006), Vector3(0.0, 0.492, 0.058), brass, 0.003, false)
	# Broad, softly lit multilingual header: no miniature instructions or labels.
	Kit.rbox(root, Vector3(2.30, 1.36, 0.10), Vector3(0.0, 1.99, -0.27), oak, 0.075)
	Kit.rbox(root, Vector3(2.18, 1.24, 0.018), Vector3(0.0, 1.99, -0.211), Kit.washi(Kit.CREAM, 0.35, "umbrella_sign"), 0.055)
	Kit.rbox(root, Vector3(1.97, 0.014, 0.012), Vector3(0.0, 2.525, -0.195), Kit.paint(accent), 0.006, false)
	_label(root, "Share an umbrella", Vector3(0.0, 2.385, -0.193), 76, 0.0031)
	_label(root, "傘のシェア  ·  共享雨伞", Vector3(0.0, 2.145, -0.193), 62, 0.0031)
	_label(root, "Ô dùng chung", Vector3(0.0, 1.915, -0.193), 56, 0.0031)
	_label(root, "Parapluies partagés", Vector3(0.0, 1.705, -0.193), 56, 0.0031)
	_label(root, "Paraguas compartidos", Vector3(0.0, 1.495, -0.193), 56, 0.0031)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signs.font()
	label.font_size = size
	label.pixel_size = pixel
	label.position = at
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _folded_mesh() -> ArrayMesh:
	if _meshes.has("folded"):
		return _meshes["folded"] as ArrayMesh
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.009, 0.0), Vector2(0.028, 0.07), Vector2(0.059, 0.32), Vector2(0.055, 0.47), Vector2(0.033, 0.65), Vector2(0.009, 0.68)])
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in profile.size() - 1:
		for side: int in 32:
			var a: Vector3 = _pleat_vertex(profile[ring], side)
			var b: Vector3 = _pleat_vertex(profile[ring], side + 1)
			var c: Vector3 = _pleat_vertex(profile[ring + 1], side)
			var d: Vector3 = _pleat_vertex(profile[ring + 1], side + 1)
			for point: Vector3 in [a, c, b, b, c, d]:
				st.set_uv(Vector2(atan2(point.z, point.x) / TAU, point.y))
				st.add_vertex(point)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["folded"] = mesh
	return mesh


static func _pleat_vertex(profile: Vector2, side: int) -> Vector3:
	var angle: float = TAU * float(side) / 32.0
	var radius: float = profile.x * (1.0 if side % 4 == 0 else 0.76)
	return Vector3(cos(angle) * radius, profile.y, sin(angle) * radius)


static func _handle_mesh() -> ArrayMesh:
	if _meshes.has("handle"):
		return _meshes["handle"] as ArrayMesh
	var path: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, 0.10)])
	for i: int in range(1, 17):
		var angle: float = PI - PI * float(i) / 16.0
		path.append(Vector2(0.065 + cos(angle) * 0.065, 0.10 + sin(angle) * 0.065))
	path.append(Vector2(0.13, 0.045))
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in path.size() - 1:
		for side: int in 12:
			var a: Vector3 = _handle_vertex(path, i, side)
			var b: Vector3 = _handle_vertex(path, i, side + 1)
			var c: Vector3 = _handle_vertex(path, i + 1, side)
			var d: Vector3 = _handle_vertex(path, i + 1, side + 1)
			for point: Vector3 in [a, c, b, b, c, d]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["handle"] = mesh
	return mesh


static func _handle_vertex(path: PackedVector2Array, i: int, side: int) -> Vector3:
	var tangent: Vector2 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
	var normal: Vector3 = Vector3(tangent.y, -tangent.x, 0.0)
	var angle: float = TAU * float(side) / 12.0
	return Vector3(path[i].x, path[i].y, 0.0) + (normal * cos(angle) + Vector3.BACK * sin(angle)) * 0.018
