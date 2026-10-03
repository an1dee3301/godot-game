extends RefCounted
## A small contemporary torii sculpture; dimensions are metres, frontage is +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ToriiArtInstallation"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var reds: Array[Color] = [Color(0.72, 0.19, 0.10), Color(0.65, 0.16, 0.09), Color(0.79, 0.25, 0.13), Color(0.69, 0.23, 0.16)]
	var vermilion: StandardMaterial3D = DesignKit.paint(reds[style], 0.43)
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE if style % 2 == 0 else DesignKit.PLASTER, 0.65, "torii_stone_%d" % style)
	var timber: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT if style % 2 == 0 else DesignKit.OAK, "torii_placard_%d" % style)
	var steel: StandardMaterial3D = DesignKit.metal()
	var trim: StandardMaterial3D = DesignKit.brass() if style < 2 else steel
	# Low, chamfer-softened exhibition plinth with two independently dressed sockets.
	DesignKit.rbox(root, Vector3(3.22, 0.12, 1.02), Vector3(0.0, 0.06, 0.0), stone, 0.055)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 1.22
		DesignKit.rbox(root, Vector3(0.66, 0.12, 0.68), Vector3(x, 0.18, 0.0), stone, 0.045)
		DesignKit.add(root, _socket_mesh(), stone, Vector3(x, 0.24, 0.0))
		var post: MeshInstance3D = DesignKit.add(root, _post_mesh(), vermilion, Vector3(x, 0.34, 0.0), Vector3(0.0, 0.0, side * 2.3))
		post.name = "TaperedLacquerPost"
		DesignKit.add(root, _collar_mesh(), steel, Vector3(x, 0.33, 0.0))
		DesignKit.add(root, _ring_mesh(), trim, Vector3(x, 0.48, 0.0))
		# Visible pinned joinery at the lower crossbeam, with recessed dark washers.
		DesignKit.rbox(root, Vector3(0.23, 0.075, 0.025), Vector3(side * 1.12, 2.65, 0.205), steel, 0.025, false)
		DesignKit.rbox(root, Vector3(0.08, 0.035, 0.035), Vector3(side * 1.12, 2.65, 0.228), trim, 0.012, false)
	# Kasagi and shimaki share a smooth upswept silhouette, rather than stepped blocks.
	DesignKit.add(root, _swept_beam(Vector3(3.70, 0.15, 0.35), 0.17), vermilion, Vector3(0.0, 3.03, 0.0))
	DesignKit.add(root, _swept_beam(Vector3(3.90, 0.22, 0.46), 0.23), vermilion, Vector3(0.0, 3.16, 0.0))
	DesignKit.add(root, _swept_beam(Vector3(3.96, 0.055, 0.49), 0.23), steel, Vector3(0.0, 3.30, 0.0))
	DesignKit.rbox(root, Vector3(2.96, 0.17, 0.28), Vector3(0.0, 2.65, 0.0), vermilion, 0.04)
	DesignKit.rbox(root, Vector3(0.17, 0.39, 0.23), Vector3(0.0, 2.89, 0.0), vermilion, 0.035)
	# Broad timber placard, held by two brass straps, with raised perimeter moulding.
	for x: float in [-0.67, 0.67]:
		DesignKit.rbox(root, Vector3(0.038, 0.25, 0.035), Vector3(x, 2.57, 0.24), trim, 0.012)
	DesignKit.rbox(root, Vector3(2.16, 0.97, 0.095), Vector3(0.0, 2.13, 0.25), timber, 0.055)
	DesignKit.rbox(root, Vector3(2.04, 0.85, 0.025), Vector3(0.0, 2.13, 0.307), timber, 0.035)
	DesignKit.rbox(root, Vector3(1.90, 0.015, 0.018), Vector3(0.0, 2.51, 0.33), trim, 0.005, false)
	for x: float in [-0.98, 0.98]:
		DesignKit.rbox(root, Vector3(0.024, 0.024, 0.018), Vector3(x, 2.49, 0.325), trim, 0.01, false)
	var words: Array = Signage.TEXT["welcome"]
	_caption(root, str(words[0]), 2.39, 100, 1.86)
	_caption(root, "%s  ·  %s" % [words[1], words[2]], 2.17, 78, 1.86)
	_caption(root, str(words[3]), 1.98, 70, 1.86)
	_caption(root, "%s · %s" % [words[4], words[5]], 1.79, 66, 1.92)
	return root


static func _caption(parent: Node3D, caption: String, y: float, size: int, width: float) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.pixel_size = 0.003
	var extent: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x * label.pixel_size
	label.font_size = mini(size, int(float(size) * width / maxf(extent, 0.001)))
	label.position = Vector3(0.0, y, 0.334)
	label.modulate = DesignKit.CREAM
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _post_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.17, 0.0), Vector2(0.18, 0.035),
		Vector2(0.174, 0.14), Vector2(0.143, 2.70), Vector2(0.138, 2.78), Vector2(0.0, 2.78)
	]), 32)


static func _socket_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.28, 0.0), Vector2(0.29, 0.025),
		Vector2(0.26, 0.17), Vector2(0.235, 0.20), Vector2(0.0, 0.20)
	]), 32)


static func _collar_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.19, 0.0), Vector2(0.196, 0.025),
		Vector2(0.191, 0.14), Vector2(0.18, 0.155), Vector2(0.0, 0.155)
	]), 32)


static func _ring_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.176, 0.0), Vector2(0.192, 0.0), Vector2(0.192, 0.018),
		Vector2(0.176, 0.018), Vector2(0.176, 0.0)
	]), 32)


static func _swept_beam(size: Vector3, rise: float) -> ArrayMesh:
	var key: String = "beam:%s:%s" % [size, rise]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	# Subdivide a rounded cross-section along X, then sweep it through a quartic arc.
	var profile: PackedVector2Array = PackedVector2Array()
	var radius: float = minf(0.045, size.y * 0.35)
	for corner: int in 4:
		var angle: float = float(corner) * PI * 0.5
		var center: Vector2 = Vector2(1.0 if corner == 0 or corner == 3 else -1.0, 1.0 if corner < 2 else -1.0)
		center *= Vector2(size.y * 0.5 - radius, size.z * 0.5 - radius)
		for step: int in 5:
			var theta: float = angle + float(step) * PI / 8.0
			profile.append(center + Vector2(cos(theta), sin(theta)) * radius)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: int = 40
	for section: int in sections:
		for edge: int in profile.size():
			var next: int = (edge + 1) % profile.size()
			var a: Vector3 = _beam_vertex(section, sections, profile[edge], size.x, rise)
			var b: Vector3 = _beam_vertex(section + 1, sections, profile[edge], size.x, rise)
			var c: Vector3 = _beam_vertex(section + 1, sections, profile[next], size.x, rise)
			var d: Vector3 = _beam_vertex(section, sections, profile[next], size.x, rise)
			for vertex: Vector3 in [a, c, b, a, d, c]:
				st.add_vertex(vertex)
	for end: int in [0, sections]:
		var center: Vector3 = _beam_vertex(end, sections, Vector2.ZERO, size.x, rise)
		for edge: int in profile.size():
			var a: Vector3 = _beam_vertex(end, sections, profile[edge], size.x, rise)
			var b: Vector3 = _beam_vertex(end, sections, profile[(edge + 1) % profile.size()], size.x, rise)
			for vertex: Vector3 in ([center, b, a] if end == 0 else [center, a, b]):
				st.add_vertex(vertex)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes[key] = mesh
	return mesh


static func _beam_vertex(section: int, sections: int, profile: Vector2, width: float, rise: float) -> Vector3:
	var u: float = 2.0 * float(section) / float(sections) - 1.0
	return Vector3(u * width * 0.5, profile.x + rise * pow(u, 4.0), profile.y)
