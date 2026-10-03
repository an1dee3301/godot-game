extends RefCounted

## A standing, softly lit travel print in a crafted two-by-three-metre frame.

static var _textures: Dictionary = {}
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "ParisTravelLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "paris_walnut")
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "paris_oak")
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.48, 0.65, "paris_steel")
	var brass: StandardMaterial3D = DesignKit.brass()
	DesignKit.rbox(root, Vector3(1.98, 2.98, 0.16), Vector3(0.0, 1.50, -0.075), walnut, 0.055)
	DesignKit.rbox(root, Vector3(1.88, 2.88, 0.025), Vector3(0.0, 1.50, 0.018), steel, 0.018, false)
	DesignKit.rbox(root, Vector3(1.82, 2.82, 0.015), Vector3(0.0, 1.50, 0.037), DesignKit.washi(Color(0.97, 0.88, 0.72), 1.3, "paris_diffuser"), 0.008, false)
	DesignKit.add(root, _print_mesh(), _print_material(variant), Vector3(0.0, 1.50, 0.049), Vector3.ZERO, false)

	# Rounded oak battens sit forward of the print; a narrow brass reveal catches the light.
	for x: float in [-0.955, 0.955]:
		DesignKit.rbox(root, Vector3(0.07, 2.98, 0.13), Vector3(x, 1.50, 0.083), oak, 0.025)
		DesignKit.rbox(root, Vector3(0.012, 2.83, 0.013), Vector3(x * 0.945, 1.50, 0.154), brass, 0.005, false)
	for y: float in [0.035, 2.965]:
		DesignKit.rbox(root, Vector3(1.98, 0.07, 0.13), Vector3(0.0, y, 0.083), oak, 0.025)
		DesignKit.rbox(root, Vector3(1.82, 0.012, 0.013), Vector3(0.0, 1.50 + (y - 1.50) * 0.963, 0.154), brass, 0.005, false)

	var title := Label3D.new()
	title.text = "PARIS"
	title.font = Signage.font()
	title.font_size = 140
	title.pixel_size = 0.0036
	title.modulate = DesignKit.INDIGO
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.0, 2.64, 0.064)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title)

	var caption := Label3D.new()
	caption.text = "FRANCE"
	caption.font = Signage.font()
	caption.font_size = 54
	caption.pixel_size = 0.0028
	caption.modulate = DesignKit.INDIGO
	caption.outline_size = 0
	caption.double_sided = false
	caption.position = Vector3(0.0, 0.25, 0.064)
	caption.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(caption)

	# The small feet keep the case visibly standing on the terminal floor.
	for x: float in [-0.70, 0.70]:
		DesignKit.rbox(root, Vector3(0.23, 0.045, 0.26), Vector3(x, 0.023, -0.09), steel, 0.018)
	return root


static func _print_mesh() -> QuadMesh:
	if not _meshes.has("print"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.82, 2.82)
		_meshes["print"] = mesh
	return _meshes["print"] as QuadMesh


static func _print_material(variant: int) -> StandardMaterial3D:
	var key := str(posmod(variant, 3))
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = _art_texture(variant)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.65
	material.roughness = 1.0
	_materials[key] = material
	return material


static func _art_texture(variant: int) -> Texture2D:
	var key := str(posmod(variant, 3))
	if _textures.has(key):
		return _textures[key] as Texture2D
	var image := Image.create(768, 1152, false, Image.FORMAT_RGB8)
	var paper := Color(0.94, 0.90, 0.82)
	var sun := Color(0.74, 0.43, 0.32)
	var ink := Color(0.23, 0.31, 0.39)
	var gold := Color(0.72, 0.55, 0.30)
	image.fill(paper)
	var offset := (posmod(variant, 3) - 1) * 22
	_circle(image, Vector2i(384 + offset, 559), 188, sun)
	# Fine stepped border and horizon echo the geometry of 1930s railway posters.
	for inset: int in [68, 77]:
		_hline(image, inset, 714 - inset, 305, 2, gold)
		_hline(image, inset, 714 - inset, 1008, 2, gold)
	for y: int in [892, 907, 922]:
		_hline(image, 110, 658, y, 2, gold)

	# Each side of the tower is a tapered iron leg; the open centre forms its arch.
	var left := PackedVector2Array([
		Vector2(378, 294), Vector2(369, 418), Vector2(339, 569),
		Vector2(288, 742), Vector2(200, 923), Vector2(161, 980),
		Vector2(214, 980), Vector2(258, 917), Vector2(322, 755),
		Vector2(357, 587), Vector2(382, 426), Vector2(387, 294)
	])
	var right := PackedVector2Array()
	for point: Vector2 in left:
		right.append(Vector2(768.0 - point.x, point.y))
	_polygon(image, left, ink)
	_polygon(image, right, ink)
	# Tiered viewing decks and short cross braces give the silhouette Eiffel's rhythm.
	for deck: Array in [[572, 322, 446, 10], [739, 267, 501, 13], [826, 225, 543, 10]]:
		var deck_y: int = deck[0]
		var deck_left: int = deck[1]
		var deck_right: int = deck[2]
		var deck_height: int = deck[3]
		image.fill_rect(Rect2i(deck_left - 17, deck_y, deck_right - deck_left + 34, deck_height), ink)
		image.fill_rect(Rect2i(deck_left - 7, deck_y - 7, deck_right - deck_left + 14, 4), gold)
	for y: int in [425, 476, 528, 610, 657, 700, 777]:
		var span := int(13.0 + float(y - 290) * 0.17)
		_line(image, Vector2i(384 - span, y), Vector2i(384 + span, y - 25), 3, gold)
		_line(image, Vector2i(384 + span, y), Vector2i(384 - span, y - 25), 3, gold)
	# Crown, antenna, and the little illuminated beacon finish the vertical axis.
	image.fill_rect(Rect2i(372, 277, 24, 23), ink)
	image.fill_rect(Rect2i(381, 226, 6, 52), ink)
	_circle(image, Vector2i(384, 221), 8, gold)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture


static func _circle(image: Image, centre: Vector2i, radius: int, color: Color) -> void:
	for y: int in range(centre.y - radius, centre.y + radius + 1):
		for x: int in range(centre.x - radius, centre.x + radius + 1):
			var dx := x - centre.x
			var dy := y - centre.y
			if dx * dx + dy * dy <= radius * radius:
				image.set_pixel(x, y, color)


static func _hline(image: Image, x1: int, x2: int, y: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x1, y, x2 - x1, height), color)


static func _polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	for y: int in range(maxi(0, int(bounds.position.y)), mini(image.get_height(), int(bounds.end.y) + 1)):
		for x: int in range(maxi(0, int(bounds.position.x)), mini(image.get_width(), int(bounds.end.x) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, color)


static func _line(image: Image, start: Vector2i, finish: Vector2i, width: int, color: Color) -> void:
	var a := Vector2(start)
	var b := Vector2(finish)
	var direction := b - a
	var length_squared := direction.length_squared()
	for y: int in range(maxi(0, mini(start.y, finish.y) - width), mini(image.get_height(), maxi(start.y, finish.y) + width + 1)):
		for x: int in range(maxi(0, mini(start.x, finish.x) - width), mini(image.get_width(), maxi(start.x, finish.x) + width + 1)):
			var pixel := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t := clampf((pixel - a).dot(direction) / length_squared, 0.0, 1.0)
			if pixel.distance_squared_to(a + direction * t) <= float(width * width):
				image.set_pixel(x, y, color)
