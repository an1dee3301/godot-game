extends RefCounted
## A floor-height, backlit Tokyo travel print in an oak and brass lightbox.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "TokyoPosterLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.78, "tokyo_poster_steel")
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "tokyo_poster_oak")
	var brass: StandardMaterial3D = DesignKit.brass()
	var diffuser: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 0.8, "tokyo_poster_diffuser")

	DesignKit.rbox(root, Vector3(2.0, 3.0, 0.15), Vector3(0.0, 1.5, 0.0), steel, 0.055)
	DesignKit.rbox(root, Vector3(1.90, 2.90, 0.025), Vector3(0.0, 1.5, 0.089), diffuser, 0.024, false)
	DesignKit.add(root, _poster_mesh(), _poster_material(variant), Vector3(0.0, 1.77, 0.107), Vector3.ZERO, false)

	# Four mitred-looking rails, with narrow brass reveals on the face.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.075, 2.91, 0.075), Vector3(side * 0.96, 1.5, 0.105), oak, 0.021)
		DesignKit.rbox(root, Vector3(1.90, 0.075, 0.075), Vector3(0.0, 1.5 + side * 1.46, 0.105), oak, 0.021)
		DesignKit.rbox(root, Vector3(0.009, 2.81, 0.012), Vector3(side * 0.915, 1.5, 0.146), brass, 0.003, false)
	DesignKit.rbox(root, Vector3(1.81, 0.009, 0.012), Vector3(0.0, 0.715, 0.146), brass, 0.003, false)

	var title := Label3D.new()
	title.name = "TokyoTitle"
	title.text = "TOKYO 東京"
	title.font = Signage.font()
	title.font_size = 104
	title.pixel_size = 0.0024
	var title_width: float = title.font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.font_size).x * title.pixel_size
	if title_width > 1.72:
		title.font_size = maxi(60, int(float(title.font_size) * 1.72 / title_width))
	title.modulate = DesignKit.INDIGO
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.0, 0.39, 0.122)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title)
	return root


static func _poster_mesh() -> QuadMesh:
	if not _meshes.has("poster"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.80, 2.10)
		_meshes["poster"] = mesh
	return _meshes["poster"] as QuadMesh


static func _poster_material(variant: int) -> StandardMaterial3D:
	var key := "art_%d" % posmod(variant, 2)
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var image := Image.create(600, 700, false, Image.FORMAT_RGB8)
	var paper := Color(0.96, 0.92, 0.84)
	var clay := Color(0.73, 0.46, 0.35)
	var sage := Color(0.54, 0.62, 0.55)
	var ink := Color(0.23, 0.32, 0.35)
	if posmod(variant, 2) == 1:
		clay = Color(0.76, 0.53, 0.37)
		sage = Color(0.55, 0.63, 0.60)
	image.fill(paper)

	# A single clay sun sits behind Fuji. The broken cream summit reads at a distance.
	_disc(image, Vector2(414.0, 216.0), 104.0, clay)
	_poly(image, PackedVector2Array([
		Vector2(16, 573), Vector2(94, 498), Vector2(190, 423), Vector2(296, 294),
		Vector2(360, 365), Vector2(481, 498), Vector2(598, 571), Vector2(598, 680), Vector2(16, 680)
	]), sage)
	_poly(image, PackedVector2Array([
		Vector2(211, 399), Vector2(296, 294), Vector2(351, 357), Vector2(327, 351),
		Vector2(312, 370), Vector2(292, 357), Vector2(272, 377), Vector2(250, 367)
	]), paper)
	_poly(image, PackedVector2Array([
		Vector2(16, 585), Vector2(98, 544), Vector2(156, 561), Vector2(212, 529),
		Vector2(280, 553), Vector2(343, 531), Vector2(417, 566), Vector2(503, 535),
		Vector2(598, 574), Vector2(598, 700), Vector2(16, 700)
	]), ink)

	# A four-storey pagoda is cut as bold timber silhouettes over the foothills.
	image.fill_rect(Rect2i(85, 414, 94, 244), ink)
	for level in 4:
		var roof_y: int = 405 + level * 62
		var reach: int = 57 + level * 5
		_poly(image, PackedVector2Array([
			Vector2(132, roof_y - 18), Vector2(132 + reach - 19, roof_y - 1),
			Vector2(132 + reach, roof_y + 4), Vector2(132 + reach - 16, roof_y + 13),
			Vector2(132 - reach + 16, roof_y + 13), Vector2(132 - reach, roof_y + 4),
			Vector2(132 - reach + 19, roof_y - 1)
		]), ink)
		image.fill_rect(Rect2i(101, roof_y + 16, 62, 21), paper)
		image.fill_rect(Rect2i(111, roof_y + 16, 8, 21), ink)
		image.fill_rect(Rect2i(145, roof_y + 16, 8, 21), ink)
	_poly(image, PackedVector2Array([
		Vector2(132, 367), Vector2(181, 401), Vector2(83, 401)
	]), ink)
	image.fill_rect(Rect2i(128, 346, 8, 25), ink)
	_disc(image, Vector2(132, 343), 6.0, ink)

	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	var texture := ImageTexture.create_from_image(image)
	material.albedo_texture = texture
	material.emission_enabled = true
	material.emission_texture = texture
	material.emission_energy_multiplier = 0.6
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.9
	_materials[key] = material
	return material


static func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var left := maxi(0, int(floor(center.x - radius)))
	var right := mini(image.get_width() - 1, int(ceil(center.x + radius)))
	var top := maxi(0, int(floor(center.y - radius)))
	var bottom := mini(image.get_height() - 1, int(ceil(center.y + radius)))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Vector2(float(x) + 0.5, float(y) + 0.5).distance_squared_to(center) <= radius * radius:
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
