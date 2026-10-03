extends RefCounted
## Static, ceiling-mounted welcome mobile. Origin remains at the floor below the rosette.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "HangingLeafMobile"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[style]
	var brass: StandardMaterial3D = DesignKit.brass()
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "mobile_walnut")
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.35, "mobile_cream")
	var tinted_paper: StandardMaterial3D = DesignKit.washi(accent.lightened(0.45), 0.18, "mobile_paper_%d" % style)
	# Turned ceiling escutcheon, stepped brass collar and a blackened safety cable.
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.07, 0.0), Vector2(0.09, 0.03),
		Vector2(0.17, 0.05), Vector2(0.20, 0.08), Vector2(0.20, 0.11), Vector2(0.0, 0.11)
	]), 32), oak, Vector3(0.0, 5.97, 0.0))
	DesignKit.add(root, DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.045, 0.0), Vector2(0.055, 0.025),
		Vector2(0.055, 0.065), Vector2(0.035, 0.08), Vector2(0.0, 0.08)
	]), 20), brass, Vector3(0.0, 5.89, 0.0))
	_rod(root, Vector3(0.0, 5.9, 0.0), Vector3(0.0, 5.64, 0.0), 0.009, DesignKit.metal())
	var words: Array = Signage.TEXT["welcome"]
	# Each lower arm is suspended from the preceding arm's pivot, with paired leaf weights.
	for tier in 3:
		var arm_y: float = 5.64 - float(tier) * 0.24
		var angle: float = deg_to_rad(-18.0 + float(tier) * 26.0 + float(style) * 5.0)
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var half_span: float = 1.85 - float(tier) * 0.36
		var pivot: Vector3 = Vector3(0.0, arm_y, 0.0)
		_rod(root, pivot - direction * half_span, pivot + direction * half_span, 0.018, brass)
		DesignKit.rbox(root, Vector3(0.10, 0.09, 0.08), pivot, walnut, 0.035)
		if tier < 2:
			_rod(root, pivot, pivot - Vector3(0.0, 0.24, 0.0), 0.008, brass)
		for side in 2:
			var sign_value: float = -1.0 if side == 0 else 1.0
			var tip: Vector3 = pivot + direction * half_span * sign_value
			var leaf_y: float = 4.82 - float(tier) * 0.14 + float(side) * 0.035
			var leaf: Node3D = Node3D.new()
			leaf.name = "Leaf_%d_%d" % [tier, side]
			leaf.position = Vector3(tip.x, leaf_y, tip.z)
			leaf.rotation_degrees = Vector3(0.0, -12.0 + float(tier) * 12.0 + float(style) * 3.0, sign_value * 7.0)
			root.add_child(leaf)
			_rod(root, tip, leaf.transform * Vector3(0.0, 0.49, 0.0), 0.007, brass)
			var edge_material: StandardMaterial3D = walnut if (tier + style) % 3 == 0 else oak
			DesignKit.add(leaf, _leaf_mesh(), edge_material, Vector3.ZERO)
			var face_material: StandardMaterial3D = paper if (tier + side + style) % 2 == 0 else tinted_paper
			var front: MeshInstance3D = DesignKit.add(leaf, _leaf_mesh(), face_material, Vector3(0.0, 0.0, 0.027))
			front.scale = Vector3(0.92, 0.89, 0.50)
			var back: MeshInstance3D = DesignKit.add(leaf, _leaf_mesh(), face_material, Vector3(0.0, 0.0, -0.027))
			back.scale = Vector3(0.92, 0.89, 0.50)
			# A brass petiole and two short ribs read as crafted botanical detail.
			_rod(leaf, Vector3(0.0, 0.39, 0.038), Vector3(0.0, 0.49, 0.0), 0.014, brass)
			_rod(leaf, Vector3(-0.48, -0.18, 0.041), Vector3(-0.12, -0.29, 0.052), 0.004, brass)
			_rod(leaf, Vector3(0.12, -0.29, 0.052), Vector3(0.48, -0.18, 0.041), 0.004, brass)
			var caption: Label3D = Label3D.new()
			caption.text = str(words[tier * 2 + side])
			caption.font = Signage.font()
			caption.font_size = 96
			var text_width: float = caption.font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 96).x
			caption.pixel_size = minf(0.0027, 1.36 / maxf(text_width, 1.0))
			caption.modulate = DesignKit.CHARCOAL
			caption.outline_size = 0
			caption.position = Vector3(0.0, 0.025, 0.069)
			caption.double_sided = false
			caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			leaf.add_child(caption)
	return root


static func _rod(parent: Node3D, start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	# A shared unit cylinder scales to the requested length; no resource per cable.
	var key: String = "rod"
	var mesh: CylinderMesh
	if _meshes.has(key):
		mesh = _meshes[key] as CylinderMesh
	else:
		mesh = CylinderMesh.new()
		mesh.top_radius = 1.0
		mesh.bottom_radius = 1.0
		mesh.height = 1.0
		mesh.radial_segments = 12
		_meshes[key] = mesh
	var delta: Vector3 = finish - start
	var node: MeshInstance3D = DesignKit.add(parent, mesh, material, (start + finish) * 0.5, Vector3.ZERO, false)
	node.quaternion = Quaternion(Vector3.UP, delta.normalized())
	node.scale = Vector3(radius, delta.length(), radius)


static func _leaf_mesh() -> ArrayMesh:
	if _meshes.has("leaf"):
		return _meshes["leaf"] as ArrayMesh
	# A closed lenticular shell: rounded silhouette, subtly crowned faces and a fine edge.
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS: int = 48
	for face in 2:
		var face_sign: float = 1.0 if face == 0 else -1.0
		var center: Vector3 = Vector3(0.0, 0.0, face_sign * 0.035)
		for i in SEGMENTS:
			var a: float = TAU * float(i) / float(SEGMENTS)
			var b: float = TAU * float(i + 1) / float(SEGMENTS)
			var p: Vector3 = _outline(a, face_sign * 0.009)
			var q: Vector3 = _outline(b, face_sign * 0.009)
			_triangle(st, center, q, p) if face == 0 else _triangle(st, center, p, q)
	for i in SEGMENTS:
		var a: float = TAU * float(i) / float(SEGMENTS)
		var b: float = TAU * float(i + 1) / float(SEGMENTS)
		var p: Vector3 = _outline(a, 0.009)
		var q: Vector3 = _outline(b, 0.009)
		var r: Vector3 = _outline(a, -0.009)
		var s: Vector3 = _outline(b, -0.009)
		_triangle(st, p, q, r)
		_triangle(st, q, s, r)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_meshes["leaf"] = mesh
	return mesh


static func _outline(angle: float, depth: float) -> Vector3:
	# Broad ginkgo-like leaves, tapered at the petiole rather than rectangular panels.
	var y: float = sin(angle) * 0.46
	var taper: float = 0.78 - sin(angle) * 0.20
	return Vector3(cos(angle) * taper, y, depth)


static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex: Vector3 in [a, b, c]:
		st.set_uv(Vector2(vertex.x / 1.7 + 0.5, vertex.y + 0.5))
		st.add_vertex(vertex)
