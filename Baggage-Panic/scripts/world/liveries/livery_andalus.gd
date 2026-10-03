extends RefCounted
## Andalus: a quiet white aircraft with a bold cobalt azulejo fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const COBALT := Color("143d8c")
const DEEP_COBALT := Color("102d68")
const PORCELAIN := Color("faf7ed")


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Andalus",
		"code": "AN",
		"body": PORCELAIN,
		"belly": DesignKit.CREAM,
		"cheatline": [COBALT, DesignKit.OCHRE],
		"engine": PORCELAIN,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DEEP_COBALT,
		"accent": DesignKit.OCHRE,
		"gate_translations": Signage.translations("gate"),
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(COBALT)
	var brass_ink: Color = DesignKit.OCHRE.lightened(0.1)
	# A double tile border keeps the art legible when the fin is seen at an angle.
	_frame(image, 19, 9, brass_ink)
	_frame(image, 35, 5, PORCELAIN)
	_fill_polygon(image, _star(Vector2(256.0, 256.0), 212.0, 113.0, 8), brass_ink)
	_fill_polygon(image, _star(Vector2(256.0, 256.0), 195.0, 102.0, 8), PORCELAIN)
	_fill_polygon(image, _star(Vector2(256.0, 256.0), 86.0, 75.0, 8), COBALT)
	_fill_polygon(image, _star(Vector2(256.0, 256.0), 57.0, 30.0, 8), brass_ink)
	_fill_polygon(image, _star(Vector2(256.0, 256.0), 24.0, 24.0, 8), PORCELAIN)
	for centre: Vector2 in [Vector2(73.0, 73.0), Vector2(439.0, 73.0), Vector2(73.0, 439.0), Vector2(439.0, 439.0)]:
		_fill_polygon(image, _star(centre, 18.0, 8.0, 4), PORCELAIN)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# Five by seven custom block glyphs; each occupied cell is a solid rectangle.
	var glyphs: Dictionary = {
		"A": PackedStringArray(["01110", "10001", "10001", "11111", "10001", "10001", "10001"]),
		"N": PackedStringArray(["10001", "11001", "11001", "10101", "10011", "10011", "10001"]),
		"D": PackedStringArray(["11110", "10001", "10001", "10001", "10001", "10001", "11110"]),
		"L": PackedStringArray(["10000", "10000", "10000", "10000", "10000", "10000", "11111"]),
		"U": PackedStringArray(["10001", "10001", "10001", "10001", "10001", "10001", "01110"]),
		"S": PackedStringArray(["01111", "10000", "10000", "01110", "00001", "00001", "11110"]),
	}
	var word := "ANDALUS"
	var cell := 20
	var gap := 21
	var left := 102
	var top := 23
	for letter_index in word.length():
		var glyph: PackedStringArray = glyphs[word.substr(letter_index, 1)]
		var letter_x := left + letter_index * (cell * 5 + gap)
		for row in 7:
			for column in 5:
				if glyph[row].substr(column, 1) == "1":
					image.fill_rect(Rect2i(letter_x + column * cell, top + row * cell, cell, cell), DEEP_COBALT)
	# A thin ochre underline recalls the tile border without reducing letter contrast.
	image.fill_rect(Rect2i(left, 174, 7 * cell * 5 + 6 * gap, 6), DesignKit.OCHRE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _frame(image: Image, inset: int, width: int, ink: Color) -> void:
	var extent := image.get_width() - inset * 2
	image.fill_rect(Rect2i(inset, inset, extent, width), ink)
	image.fill_rect(Rect2i(inset, image.get_height() - inset - width, extent, width), ink)
	image.fill_rect(Rect2i(inset, inset, width, extent), ink)
	image.fill_rect(Rect2i(image.get_width() - inset - width, inset, width, extent), ink)


static func _star(centre: Vector2, outer_radius: float, inner_radius: float, points: int) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	for index in points * 2:
		var angle := -PI * 0.5 + float(index) * PI / float(points)
		var radius := outer_radius if index % 2 == 0 else inner_radius
		vertices.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return vertices


static func _fill_polygon(image: Image, polygon: PackedVector2Array, ink: Color) -> void:
	var low := Vector2(512.0, 512.0)
	var high := Vector2.ZERO
	for vertex: Vector2 in polygon:
		low = low.min(vertex)
		high = high.max(vertex)
	var min_x := maxi(0, int(floorf(low.x)))
	var max_x := mini(image.get_width() - 1, int(ceilf(high.x)))
	var min_y := maxi(0, int(floorf(low.y)))
	var max_y := mini(image.get_height() - 1, int(ceilf(high.y)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), polygon):
				image.set_pixel(x, y, ink)
