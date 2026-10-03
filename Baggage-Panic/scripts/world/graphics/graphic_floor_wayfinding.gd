extends RefCounted
## Three low-profile painted routes, read from the +Z approach to the concourse.

static var _painted_materials: Dictionary = {}
static var _quad_mesh: QuadMesh


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "FloorWayfinding"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var names: Array[String] = ["GATES", "CLAIM", "EXIT"]
	var colors: Array[Color] = [DesignKit.SAGE.darkened(0.13), DesignKit.CLAY.darkened(0.08), DesignKit.INDIGO]
	var translations: Array[String] = ["搭乗口 · 登机口", "手荷物 · 行李", "出口 · Lối ra"]
	var directions: Array[int] = [0, -1, 1]
	var order: Array[int] = [0, 1, 2]
	if variant % 2 != 0:
		order.reverse()
	for lane in 3:
		var index: int = order[lane]
		var x: float = (float(lane) - 1.0) * 1.13
		# A beveled limestone-coloured perimeter suggests an inset paint bed without a tall curb.
		DesignKit.rbox(root, Vector3(1.045, 0.012, 3.92), Vector3(x, 0.006, 0.0), DesignKit.stone(DesignKit.LIMESTONE, 0.85, "wayfinding_edge"), 0.005, false)
		var art := MeshInstance3D.new()
		art.name = names[index] + "_paint"
		art.mesh = _quad()
		art.material_override = _paint_material(index, colors[index], directions[index])
		art.position = Vector3(x, 0.0125, 0.0)
		art.rotation_degrees.x = -90.0
		art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(art)

		_add_floor_text(root, names[index], Vector3(x, 0.019, 0.58), 132, DesignKit.CREAM)
		_add_floor_text(root, translations[index], Vector3(x, 0.020, 1.04), 46, DesignKit.CREAM)
	return root


static func _quad() -> QuadMesh:
	if _quad_mesh == null:
		_quad_mesh = QuadMesh.new()
		_quad_mesh.size = Vector2(1.01, 3.88)
	return _quad_mesh


static func _paint_material(index: int, tint: Color, direction: int) -> StandardMaterial3D:
	if _painted_materials.has(index):
		return _painted_materials[index] as StandardMaterial3D
	var width := 256
	var height := 1024
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var edge := tint.darkened(0.19)
	var field := tint
	for py in height:
		for px in width:
			var dx := minf(float(px), float(width - 1 - px))
			var dy := minf(float(py), float(height - 1 - py))
			var cx := maxf(0.0, 14.0 - dx)
			var cy := maxf(0.0, 14.0 - dy)
			if Vector2(cx, cy).length() <= 14.0:
				var rim := dx < 5.0 or dy < 5.0
				image.set_pixel(px, py, edge if rim else field)
	# Two fine route rules, an oversized direction arrow, and a quiet terminal marker.
	image.fill_rect(Rect2i(20, 45, 3, 930), DesignKit.CREAM.darkened(0.16))
	image.fill_rect(Rect2i(233, 45, 3, 930), DesignKit.CREAM.darkened(0.16))
	var arrow := PackedVector2Array()
	match direction:
		-1:
			arrow = PackedVector2Array([Vector2(40, 250), Vector2(109, 155), Vector2(109, 205), Vector2(211, 205), Vector2(211, 295), Vector2(109, 295), Vector2(109, 345)])
		1:
			arrow = PackedVector2Array([Vector2(216, 250), Vector2(147, 155), Vector2(147, 205), Vector2(45, 205), Vector2(45, 295), Vector2(147, 295), Vector2(147, 345)])
		_:
			arrow = PackedVector2Array([Vector2(128, 94), Vector2(38, 205), Vector2(83, 205), Vector2(83, 345), Vector2(173, 345), Vector2(173, 205), Vector2(218, 205)])
	_fill_polygon(image, arrow, DesignKit.CREAM)
	image.fill_rect(Rect2i(44, 397, 168, 5), DesignKit.CREAM.darkened(0.05))
	image.fill_rect(Rect2i(89, 912, 78, 7), DesignKit.CREAM.darkened(0.05))
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_painted_materials[index] = material
	return material


static func _fill_polygon(image: Image, vertices: PackedVector2Array, color: Color) -> void:
	for py in range(85, 350):
		for px in range(32, 224):
			if Geometry2D.is_point_in_polygon(Vector2(float(px) + 0.5, float(py) + 0.5), vertices):
				image.set_pixel(px, py, color)


static func _add_floor_text(parent: Node3D, caption: String, at: Vector3, size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = 0.0022
	label.modulate = color
	label.outline_size = 0
	label.double_sided = true
	label.no_depth_test = false
	label.position = at
	label.rotation_degrees.x = -90.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
