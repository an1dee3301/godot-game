extends RefCounted
## Standing, backlit Shanghai travel poster. Artwork is painted into one reusable texture.

static var _art_materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "ShanghaiTravelLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var walnut := DesignKit.wood(DesignKit.WALNUT, "poster_shanghai_walnut")
	var steel := DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.7, "poster_shanghai_steel")
	var brass := DesignKit.brass()
	var glow := DesignKit.washi(DesignKit.CREAM, 1.7, "poster_shanghai_paper")

	# A shallow illuminated cabinet with a walnut rim and a recessed paper diffuser.
	DesignKit.rbox(root, Vector3(2.0, 3.0, 0.16), Vector3(0.0, 1.6, -0.07), walnut, 0.065)
	DesignKit.rbox(root, Vector3(1.90, 2.90, 0.045), Vector3(0.0, 1.6, 0.025), steel, 0.042)
	DesignKit.rbox(root, Vector3(1.82, 2.82, 0.025), Vector3(0.0, 1.6, 0.057), glow, 0.025, false)

	var art := MeshInstance3D.new()
	var sheet := QuadMesh.new()
	sheet.size = Vector2(1.78, 2.78)
	art.mesh = sheet
	art.material_override = _art_material(variant % 2)
	art.position = Vector3(0.0, 1.6, 0.073)
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(art)

	# The slim brass reveal and inset fasteners give the cabinet a crafted edge.
	DesignKit.rbox(root, Vector3(1.85, 0.012, 0.012), Vector3(0.0, 3.026, 0.059), brass, 0.005, false)
	DesignKit.rbox(root, Vector3(1.85, 0.012, 0.012), Vector3(0.0, 0.174, 0.059), brass, 0.005, false)
	for side in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.012, 2.84, 0.012), Vector3(side * 0.923, 1.6, 0.059), brass, 0.005, false)
		DesignKit.rbox(root, Vector3(0.25, 0.08, 0.36), Vector3(side * 0.65, 0.04, -0.09), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.085, 0.12, 0.11), Vector3(side * 0.65, 0.13, -0.08), brass, 0.02)

	var title := Label3D.new()
	title.name = "ShanghaiTitle"
	title.text = "SHANGHAI 上海"
	title.font = Signage.font()
	title.font_size = 91
	title.pixel_size = 0.0024
	title.modulate = DesignKit.CHARCOAL
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.0, 2.735, 0.077)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title)
	return root


static func _art_material(variant: int) -> StandardMaterial3D:
	if _art_materials.has(variant):
		return _art_materials[variant] as StandardMaterial3D
	var image := Image.create(512, 768, false, Image.FORMAT_RGBA8)
	var paper := Color("f3ead8")
	var skyline := Color("34434a")
	var deep := Color("253842")
	var water := Color("9eada2") if variant == 0 else Color("a8aaa0")
	var clay := Color("bd755b") if variant == 0 else Color("bd8965")
	image.fill(paper)

	# One ochre sun anchors the composition; the layered Pudong profile sits on the river.
	_circle(image, Vector2i(376, 294), 93, clay)
	_poly(image, PackedVector2Array([Vector2(0, 527), Vector2(0, 441), Vector2(32, 441), Vector2(32, 401), Vector2(60, 401), Vector2(60, 425), Vector2(87, 425), Vector2(87, 378), Vector2(115, 378), Vector2(115, 431), Vector2(144, 431), Vector2(144, 408), Vector2(168, 408), Vector2(168, 527)]), water)
	_poly(image, PackedVector2Array([Vector2(322, 527), Vector2(322, 451), Vector2(352, 451), Vector2(352, 415), Vector2(388, 415), Vector2(388, 436), Vector2(419, 436), Vector2(419, 388), Vector2(449, 388), Vector2(449, 425), Vector2(479, 425), Vector2(479, 400), Vector2(512, 400), Vector2(512, 527)]), water)

	# Shanghai Tower's taper, the World Financial Center's cutout, and the Pearl Tower.
	_poly(image, PackedVector2Array([Vector2(287, 527), Vector2(287, 295), Vector2(300, 281), Vector2(310, 246), Vector2(316, 233), Vector2(322, 287), Vector2(331, 314), Vector2(331, 527)]), skyline)
	_poly(image, PackedVector2Array([Vector2(340, 527), Vector2(340, 344), Vector2(346, 339), Vector2(380, 339), Vector2(386, 344), Vector2(386, 527)]), deep)
	_poly(image, PackedVector2Array([Vector2(350, 350), Vector2(376, 350), Vector2(375, 369), Vector2(351, 369)]), paper)
	_rect(image, Rect2i(222, 282, 8, 245), deep)
	_rect(image, Rect2i(225, 253, 2, 35), deep)
	_poly(image, PackedVector2Array([Vector2(193, 527), Vector2(203, 400), Vector2(210, 400), Vector2(219, 527)]), deep)
	_poly(image, PackedVector2Array([Vector2(231, 527), Vector2(242, 400), Vector2(249, 400), Vector2(259, 527)]), deep)
	_circle(image, Vector2i(226, 387), 30, deep)
	_circle(image, Vector2i(226, 300), 17, deep)
	_rect(image, Rect2i(171, 483, 26, 44), skyline)
	_rect(image, Rect2i(263, 446, 23, 81), skyline)
	_rect(image, Rect2i(389, 469, 43, 58), skyline)
	_rect(image, Rect2i(445, 455, 18, 72), skyline)

	# Broad river ribbons and one quiet ferry carry the eye across the base.
	_rect(image, Rect2i(0, 527, 512, 168), water)
	_poly(image, PackedVector2Array([Vector2(0, 554), Vector2(142, 544), Vector2(332, 559), Vector2(512, 545), Vector2(512, 577), Vector2(320, 592), Vector2(130, 571), Vector2(0, 583)]), paper)
	_poly(image, PackedVector2Array([Vector2(0, 626), Vector2(157, 603), Vector2(311, 616), Vector2(512, 597), Vector2(512, 632), Vector2(318, 652), Vector2(145, 638), Vector2(0, 660)]), deep)
	_poly(image, PackedVector2Array([Vector2(347, 581), Vector2(410, 581), Vector2(399, 590), Vector2(358, 590)]), skyline)
	_rect(image, Rect2i(375, 569, 16, 12), skyline)
	_rect(image, Rect2i(0, 695, 512, 73), paper)
	image.generate_mipmaps()

	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.75
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.9
	_art_materials[variant] = material
	return material


static func _rect(image: Image, area: Rect2i, color: Color) -> void:
	image.fill_rect(area, color)


static func _circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(maxi(0, center.y - radius), mini(image.get_height(), center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(image.get_width(), center.x + radius + 1)):
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= radius * radius:
				image.set_pixel(x, y, color)


static func _poly(image: Image, points: PackedVector2Array, color: Color) -> void:
	var first: Vector2 = points[0]
	var left := int(first.x)
	var right := left
	var top := int(first.y)
	var bottom := top
	for point in points:
		left = mini(left, int(point.x))
		right = maxi(right, int(point.x))
		top = mini(top, int(point.y))
		bottom = maxi(bottom, int(point.y))
	for y in range(maxi(0, top), mini(image.get_height(), bottom + 1)):
		for x in range(maxi(0, left), mini(image.get_width(), right + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, color)
