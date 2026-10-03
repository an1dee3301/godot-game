extends RefCounted
## Red Crane China: a porcelain white aircraft with a vermilion and gold crane fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const VERMILION := Color("b93629")
const DEEP_RED := Color("84291f")
const GOLD := Color("f4ce80")
const WHITE := Color("faf9f4")


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Red Crane China",
		"code": "RC",
		"body": WHITE,
		"belly": DesignKit.CREAM,
		"cheatline": [VERMILION, GOLD],
		"engine": WHITE,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.INDIGO.darkened(0.3),
		"accent": GOLD,
		"gate_translations": Signage.translations("gate"),
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(VERMILION)
	# Broad, asymmetric wings and trailing legs read as a flying crane at a distance.
	_poly(image, PackedVector2Array([
		Vector2(259, 267), Vector2(214, 232), Vector2(177, 192), Vector2(123, 112),
		Vector2(66, 40), Vector2(88, 128), Vector2(111, 181), Vector2(58, 137),
		Vector2(80, 202), Vector2(145, 260), Vector2(221, 301)
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(254, 267), Vector2(297, 218), Vector2(333, 164), Vector2(371, 88),
		Vector2(420, 31), Vector2(407, 118), Vector2(380, 191), Vector2(458, 130),
		Vector2(428, 215), Vector2(359, 277), Vector2(294, 310)
	]), GOLD)
	# The body, long curved neck, pointed beak, and legs complete the silhouette.
	_poly(image, PackedVector2Array([
		Vector2(216, 274), Vector2(265, 250), Vector2(315, 263), Vector2(331, 292),
		Vector2(301, 321), Vector2(259, 335), Vector2(218, 315), Vector2(198, 291)
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(296, 273), Vector2(326, 257), Vector2(346, 227), Vector2(354, 195),
		Vector2(365, 173), Vector2(386, 168), Vector2(402, 177), Vector2(399, 195),
		Vector2(383, 199), Vector2(373, 188), Vector2(367, 221), Vector2(352, 263),
		Vector2(324, 294)
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(398, 179), Vector2(439, 187), Vector2(400, 197)
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(247, 318), Vector2(234, 390), Vector2(180, 467), Vector2(198, 467),
		Vector2(261, 404), Vector2(275, 331)
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(280, 324), Vector2(300, 397), Vector2(340, 465), Vector2(359, 465),
		Vector2(317, 385), Vector2(302, 307)
	]), GOLD)
	# A restrained dark eye and feather cuts add definition without fragmenting the mark.
	_circle(image, Vector2(389, 182), 4.0, DEEP_RED)
	_poly(image, PackedVector2Array([
		Vector2(89, 78), Vector2(165, 212), Vector2(129, 178)
	]), VERMILION)
	_poly(image, PackedVector2Array([
		Vector2(415, 70), Vector2(347, 210), Vector2(386, 173)
	]), VERMILION)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var glyphs: Dictionary = {
		"A": PackedStringArray(["01110", "10001", "10001", "11111", "10001", "10001", "10001"]),
		"C": PackedStringArray(["01111", "10000", "10000", "10000", "10000", "10000", "01111"]),
		"D": PackedStringArray(["11110", "10001", "10001", "10001", "10001", "10001", "11110"]),
		"E": PackedStringArray(["11111", "10000", "10000", "11110", "10000", "10000", "11111"]),
		"H": PackedStringArray(["10001", "10001", "10001", "11111", "10001", "10001", "10001"]),
		"I": PackedStringArray(["11111", "00100", "00100", "00100", "00100", "00100", "11111"]),
		"N": PackedStringArray(["10001", "11001", "11001", "10101", "10011", "10011", "10001"]),
		"R": PackedStringArray(["11110", "10001", "10001", "11110", "10100", "10010", "10001"]),
	}
	_draw_word(image, "RED CRANE", glyphs, 15, 107, 20, DEEP_RED)
	_draw_word(image, "CHINA", glyphs, 10, 362, 162, DEEP_RED)
	image.fill_rect(Rect2i(107, 239, 810, 7), GOLD)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_word(image: Image, word: String, glyphs: Dictionary, cell: int, left: int, top: int, ink: Color) -> void:
	var x := left
	for index in word.length():
		var letter := word.substr(index, 1)
		if letter == " ":
			x += cell * 3
			continue
		var glyph: PackedStringArray = glyphs[letter]
		for row in 7:
			for column in 5:
				if glyph[row].substr(column, 1) == "1":
					image.fill_rect(Rect2i(x + column * cell, top + row * cell, cell, cell), ink)
		x += cell * 6


static func _poly(image: Image, vertices: PackedVector2Array, ink: Color) -> void:
	var low := Vector2(float(image.get_width()), float(image.get_height()))
	var high := Vector2.ZERO
	for vertex: Vector2 in vertices:
		low = low.min(vertex)
		high = high.max(vertex)
	var min_x := maxi(0, int(floorf(low.x)))
	var max_x := mini(image.get_width() - 1, int(ceilf(high.x)))
	var min_y := maxi(0, int(floorf(low.y)))
	var max_y := mini(image.get_height() - 1, int(ceilf(high.y)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), vertices):
				image.set_pixel(x, y, ink)


static func _circle(image: Image, centre: Vector2, radius: float, ink: Color) -> void:
	var r := int(ceilf(radius))
	for y in range(maxi(0, int(centre.y) - r), mini(image.get_height(), int(centre.y) + r + 1)):
		for x in range(maxi(0, int(centre.x) - r), mini(image.get_width(), int(centre.x) + r + 1)):
			if Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(centre) <= radius:
				image.set_pixel(x, y, ink)
