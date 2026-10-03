extends RefCounted
## Stillness: a hand-carved, slightly irregular stone ring on a layered gallery plinth.
## All dimensions are metres; the inscription faces +Z.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "StoneSculpture"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var tones: Array[Color] = [DesignKit.LIMESTONE, Color(0.57, 0.59, 0.53), Color(0.69, 0.58, 0.48), Color(0.32, 0.34, 0.32)]
	var ring_tone: Color = tones[choice]
	var stone: StandardMaterial3D = DesignKit.stone(ring_tone, 0.72, "sculpture_ring_%d" % choice)
	var base: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.65, "sculpture_plinth")
	var timber: StandardMaterial3D = DesignKit.wood(DesignKit.OAK if choice % 2 == 0 else DesignKit.WALNUT, "sculpture_cap_%d" % (choice % 2))
	var steel: StandardMaterial3D = DesignKit.metal()
	# Recessed toe creates a shadow reveal; the honed block has generous eased corners.
	DesignKit.rbox(root, Vector3(1.68, 0.04, 0.92), Vector3(0.0, 0.02, 0.0), steel, 0.015)
	DesignKit.rbox(root, Vector3(1.86, 0.32, 1.08), Vector3(0.0, 0.20, 0.0), base, 0.065)
	DesignKit.rbox(root, Vector3(1.79, 0.014, 1.01), Vector3(0.0, 0.367, 0.0), steel, 0.006, false)
	DesignKit.rbox(root, Vector3(1.84, 0.066, 1.06), Vector3(0.0, 0.407, 0.0), timber, 0.03)
	# Two brass bedding shoes are the visible ends of the concealed mounting pin.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.18, 0.026, 0.06), Vector3(0.0, 0.453, side * 0.14), DesignKit.brass(), 0.012, false)
	var ring: MeshInstance3D = DesignKit.add(root, _ring_mesh(choice), stone, Vector3(0.0, 1.225, 0.0))
	ring.rotation_degrees.y = -7.0 + float(choice) * 4.0
	ring.name = "CarvedStoneRing"
	# A broad, flush brass plaque uses the sculpture title in all six terminal languages.
	DesignKit.rbox(root, Vector3(1.69, 0.304, 0.018), Vector3(0.0, 0.20, 0.542), DesignKit.brass(), 0.014, false)
	_inscription(root, "STILL · 静 · 静", Vector3(0.0, 0.269, 0.553))
	_inscription(root, "Tĩnh · Calme · Calma", Vector3(0.0, 0.128, 0.553))
	# Countersunk fixing heads, with dark slots instead of unreadable miniature writing.
	for side: float in [-1.0, 1.0]:
		DesignKit.add(root, _fixing_mesh(), DesignKit.brass(), Vector3(side * 0.802, 0.20, 0.554), Vector3(90.0, 0.0, 0.0), false)
		DesignKit.rbox(root, Vector3(0.017, 0.003, 0.002), Vector3(side * 0.802, 0.20, 0.558), steel, 0.001, false)
	return root


static func _inscription(parent: Node3D, caption: String, at: Vector3) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 48
	label.pixel_size = 0.003
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _fixing_mesh() -> ArrayMesh:
	# The lathed bevel catches the light along each flush screw head.
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, -0.002), Vector2(0.011, -0.002),
		Vector2(0.013, 0.0), Vector2(0.010, 0.002), Vector2(0.0, 0.002)
	]), 12)


static func _ring_mesh(choice: int) -> ArrayMesh:
	var key: String = "carved_ring_%d" % choice
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const AROUND: int = 96
	const SECTION: int = 20
	for segment: int in AROUND:
		var u0: float = TAU * float(segment) / float(AROUND)
		var u1: float = TAU * float(segment + 1) / float(AROUND)
		for section: int in SECTION:
			var v0: float = TAU * float(section) / float(SECTION)
			var v1: float = TAU * float(section + 1) / float(SECTION)
			# Clockwise front faces, with continuous analytical surface normals.
			var corners: Array[Vector2] = [Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v0), Vector2(u1, v0), Vector2(u0, v1), Vector2(u1, v1)]
			for corner: Vector2 in corners:
				var u: float = corner.x
				var v: float = corner.y
				var tangent_u: Vector3 = _ring_point(u + 0.001, v, choice) - _ring_point(u - 0.001, v, choice)
				var tangent_v: Vector3 = _ring_point(u, v + 0.001, choice) - _ring_point(u, v - 0.001, choice)
				surface.set_normal(tangent_u.cross(tangent_v).normalized())
				surface.set_uv(Vector2(u / TAU, v / TAU))
				surface.add_vertex(_ring_point(u, v, choice))
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _ring_point(u: float, v: float, choice: int) -> Vector3:
	# Broad oval section and restrained lobing read as carved stone, rather than a perfect torus.
	var phase: float = float(choice) * 0.6
	var thickness: float = 0.16 * (1.0 + 0.06 * sin(3.0 * u + phase))
	var radius_x: float = 0.58 + 0.025 * sin(2.0 * u + phase)
	return Vector3(
		(radius_x + thickness * cos(v)) * cos(u),
		(0.63 + thickness * cos(v)) * sin(u),
		0.18 * sin(v) + 0.018 * cos(2.0 * u + phase)
	)
