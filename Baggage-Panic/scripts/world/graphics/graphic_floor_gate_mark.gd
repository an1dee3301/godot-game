extends RefCounted
## A flush, painted gate roundel with an inlaid directional arrow.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "FloorGateMark"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var roundel := MeshInstance3D.new()
	roundel.mesh = _roundel_mesh()
	roundel.material_override = _roundel_material(variant)
	roundel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(roundel)

	# The end of the charcoal ribbon is chamfered like a painted stencil.
	var band := PackedVector2Array([
		Vector2(-0.37, 0.99), Vector2(0.37, 0.99),
		Vector2(0.48, 1.11), Vector2(0.48, 1.88),
		Vector2(0.37, 2.00), Vector2(-0.37, 2.00),
		Vector2(-0.48, 1.88), Vector2(-0.48, 1.11),
	])
	DesignKit.add(root, _polygon_mesh("band", band, 0.006), DesignKit.paint(DesignKit.CHARCOAL), Vector3.ZERO, Vector3.ZERO, false)

	# The arrow points from the approach end into the gate roundel, toward -Z.
	var arrow := PackedVector2Array([
		Vector2(0.0, 1.13), Vector2(0.34, 1.53),
		Vector2(0.16, 1.53), Vector2(0.16, 1.85),
		Vector2(-0.16, 1.85), Vector2(-0.16, 1.53),
		Vector2(-0.34, 1.53),
	])
	DesignKit.add(root, _polygon_mesh("arrow", arrow, 0.008), DesignKit.brass(), Vector3.ZERO, Vector3.ZERO, false)

	var gate_words: Array = Signage.translations("gate")
	var caption := Label3D.new()
	caption.name = "GateCaption"
	caption.text = "%s  %s" % [str(gate_words[0]).to_upper(), str(gate_words[1])]
	caption.font = Signage.font()
	caption.font_size = 64
	caption.pixel_size = 0.0045
	caption.modulate = DesignKit.CHARCOAL
	caption.outline_size = 0
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.rotation_degrees.x = -90.0
	caption.position = Vector3(0.0, 0.011, -1.40)
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(caption)
	return root


static func _roundel_mesh() -> ArrayMesh:
	if _meshes.has("roundel"):
		return _meshes["roundel"] as ArrayMesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [
		[Vector3(-1.50, 0.004, -1.95), Vector2(0.0, 0.0)],
		[Vector3(1.50, 0.004, -1.95), Vector2(1.0, 0.0)],
		[Vector3(1.50, 0.004, 1.05), Vector2(1.0, 1.0)],
		[Vector3(-1.50, 0.004, 1.05), Vector2(0.0, 1.0)],
	]
	for index in [0, 2, 1, 0, 3, 2]:
		var point: Array = points[index]
		st.set_normal(Vector3.UP)
		st.set_uv(point[1] as Vector2)
		st.add_vertex(point[0] as Vector3)
	var mesh := st.commit()
	_meshes["roundel"] = mesh
	return mesh


static func _polygon_mesh(key: String, outline: PackedVector2Array, height: float) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(outline)
	for index in triangles:
		var p: Vector2 = outline[index]
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(p.x, height, p.y))
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


static func _roundel_material(variant: int) -> StandardMaterial3D:
	var key := "roundel:%d" % posmod(variant, 3)
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var size := 768
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var accent := DesignKit.SAGE if posmod(variant, 3) == 1 else DesignKit.OCHRE if posmod(variant, 3) == 2 else DesignKit.CLAY
	var clear := Color.TRANSPARENT
	for y in size:
		for x in size:
			var p := Vector2((float(x) + 0.5) / float(size) * 2.0 - 1.0, (float(y) + 0.5) / float(size) * 2.0 - 1.0)
			var radius := p.length()
			var color := clear
			if radius < 0.925:
				color = DesignKit.LIMESTONE
			if radius > 0.835 and radius < 0.925:
				color = DesignKit.CHARCOAL
			elif radius > 0.795 and radius < 0.813:
				color = accent
			elif radius < 0.795:
				# A broad, hand-stencilled A, cut from three simple painted strokes.
				var left := _segment_distance(p, Vector2(-0.43, 0.55), Vector2(0.0, -0.38))
				var right := _segment_distance(p, Vector2(0.43, 0.55), Vector2(0.0, -0.38))
				var crossbar := _segment_distance(p, Vector2(-0.25, 0.17), Vector2(0.25, 0.17))
				if minf(left, minf(right, crossbar)) < 0.083:
					color = DesignKit.CHARCOAL
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)
