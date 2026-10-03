extends RefCounted
## A standing, backlit Barcelona travel print: terracotta basilica above a quiet sea.

static var _art_materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "BarcelonaPosterLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var steel := DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.75, "poster_steel")
	var oak := DesignKit.wood(DesignKit.OAK, "poster_oak")
	var brass := DesignKit.brass()
	DesignKit.rbox(root, Vector3(2.0, 3.0, 0.13), Vector3(0.0, 1.5, 0.0), steel, 0.055)
	DesignKit.rbox(root, Vector3(1.90, 2.90, 0.025), Vector3(0.0, 1.5, 0.079), DesignKit.washi(DesignKit.CREAM, 0.75, "poster_washi"), 0.025, false)
	# Four individual oak rails make the picture read as a crafted lightbox.
	for side in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.058, 2.88, 0.055), Vector3(side * 0.956, 1.5, 0.107), oak, 0.019)
		DesignKit.rbox(root, Vector3(1.85, 0.058, 0.055), Vector3(0.0, 1.5 + side * 1.456, 0.107), oak, 0.019)
	DesignKit.rbox(root, Vector3(1.83, 0.012, 0.018), Vector3(0.0, 0.705, 0.117), brass, 0.005, false)
	DesignKit.rbox(root, Vector3(1.83, 0.012, 0.018), Vector3(0.0, 2.833, 0.117), brass, 0.005, false)

	var art := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.78, 2.12)
	art.mesh = quad
	art.material_override = _art_material(variant)
	art.position = Vector3(0.0, 1.77, 0.112)
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(art)

	var title := Label3D.new()
	title.name = "BarcelonaTitle"
	title.text = "BARCELONA"
	title.font = Signage.font()
	title.font_size = 102
	title.pixel_size = 0.00245
	title.modulate = DesignKit.CHARCOAL
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.0, 0.397, 0.119)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title)
	return root


static func _art_material(variant: int) -> StandardMaterial3D:
	var key := variant % 2
	if _art_materials.has(key):
		return _art_materials[key] as StandardMaterial3D
	var image := Image.create(512, 610, false, Image.FORMAT_RGBA8)
	var paper := Color(0.96, 0.92, 0.83)
	var clay := DesignKit.CLAY
	var dark_clay := Color(0.49, 0.29, 0.24)
	var sea := DesignKit.SAGE if key == 0 else DesignKit.INDIGO.lightened(0.28)
	var foam := Color(0.83, 0.84, 0.74)
	image.fill(paper)

	# A cropped ochre sun and still water form the two large fields of colour.
	_ellipse(image, Vector2(389.0, 165.0), Vector2(104.0, 104.0), DesignKit.OCHRE.lightened(0.20))
	image.fill_rect(Rect2i(0, 448, 512, 162), sea)
	_poly(image, PackedVector2Array([Vector2(0, 448), Vector2(512, 448), Vector2(512, 468), Vector2(0, 457)]), foam)
	for n in 5:
		var y := 480 + n * 28
		var inset := 23 + (n % 2) * 62
		_poly(image, PackedVector2Array([Vector2(inset, y), Vector2(433 - inset / 3, y - 4), Vector2(397 - inset / 3, y + 3), Vector2(inset + 18, y + 5)]), foam)

	# Five unequal, perforated spires evoke the Sagrada Família without fine linework.
	var bases: Array[int] = [118, 183, 255, 327, 392]
	var tips: Array[int] = [218, 149, 105, 163, 232]
	for i in bases.size():
		var x: int = bases[i]
		var tip: int = tips[i]
		var half_width := 20 if i == 2 else 16
		_poly(image, PackedVector2Array([
			Vector2(x - half_width, 421), Vector2(x - half_width + 3, tip + 38),
			Vector2(x - 8, tip + 20), Vector2(x - 5, tip + 7), Vector2(x, tip),
			Vector2(x + 5, tip + 7), Vector2(x + 8, tip + 20),
			Vector2(x + half_width - 3, tip + 38), Vector2(x + half_width, 421)
		]), clay)
		_ellipse(image, Vector2(x, tip + 49), Vector2(4, 8), paper)
		_ellipse(image, Vector2(x, tip + 78), Vector2(4, 8), paper)
		_ellipse(image, Vector2(x, tip + 108), Vector2(4, 8), paper)
		_poly(image, PackedVector2Array([Vector2(x - 4, tip - 2), Vector2(x, tip - 17), Vector2(x + 4, tip - 2)]), dark_clay)
	# The wide, stepped nave and three arched doors ground the silhouette.
	_poly(image, PackedVector2Array([
		Vector2(80, 448), Vector2(85, 379), Vector2(129, 365),
		Vector2(151, 387), Vector2(175, 376), Vector2(209, 389),
		Vector2(255, 352), Vector2(301, 389), Vector2(339, 376),
		Vector2(361, 387), Vector2(383, 365), Vector2(427, 379), Vector2(432, 448)
	]), clay)
	for x in [191, 255, 319]:
		_ellipse(image, Vector2(x, 421), Vector2(17, 26), dark_clay)
		image.fill_rect(Rect2i(x - 17, 421, 34, 27), dark_clay)
	# A few oversized stone openings retain the print's clarity at a distance.
	for x in [157, 353]:
		_ellipse(image, Vector2(x, 405), Vector2(6, 11), paper)
	return _finish_material(image, key)


static func _finish_material(image: Image, key: int) -> StandardMaterial3D:
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.emission_enabled = true
	material.emission_texture = texture
	material.emission_energy_multiplier = 0.55
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.9
	_art_materials[key] = material
	return material


static func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	var left := maxi(0, int(floor(center.x - radius.x)))
	var right := mini(image.get_width() - 1, int(ceil(center.x + radius.x)))
	var top := maxi(0, int(floor(center.y - radius.y)))
	var bottom := mini(image.get_height() - 1, int(ceil(center.y + radius.y)))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var dx := (float(x) + 0.5 - center.x) / radius.x
			var dy := (float(y) + 0.5 - center.y) / radius.y
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, color)


static func _poly(image: Image, points: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var left := maxi(0, int(floor(bounds.position.x)))
	var right := mini(image.get_width() - 1, int(ceil(bounds.end.x)))
	var top := maxi(0, int(floor(bounds.position.y)))
	var bottom := mini(image.get_height() - 1, int(ceil(bounds.end.y)))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, color)
