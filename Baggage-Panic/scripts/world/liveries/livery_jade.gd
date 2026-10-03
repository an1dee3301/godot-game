extends RefCounted
## Jade Dragon: porcelain white fuselage, deep jade fin, and a single coiled white dragon.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const JADE := Color("12695a")
const DEEP_JADE := Color("104c43")
const PALE_JADE := Color("8fc4ac")
const PORCELAIN := Color("f7f6f0")
const DRAGON_WHITE := Color("fffdf2")

const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"D": ["11110", "11011", "11011", "11011", "11011", "11011", "11110"],
	"E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
	"G": ["01111", "11000", "11000", "11011", "11011", "11011", "01111"],
	"J": ["00111", "00011", "00011", "00011", "11011", "11011", "01110"],
	"N": ["11011", "11111", "11111", "11111", "11111", "11111", "11011"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Jade Dragon",
		"code": "JD",
		"body": PORCELAIN,
		"belly": Color("e1e7df"),
		"cheatline": [JADE, PALE_JADE],
		"engine": PORCELAIN,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DEEP_JADE,
		"accent": JADE,
		"gate_translations": Signage.translations("gate"),
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(JADE)
	# The large continuous coil keeps its silhouette when the aircraft is far away.
	var spine := PackedVector2Array([
		Vector2(89, 388), Vector2(140, 422), Vector2(199, 413),
		Vector2(237, 377), Vector2(232, 338), Vector2(194, 311),
		Vector2(148, 305), Vector2(113, 273), Vector2(111, 224),
		Vector2(147, 183), Vector2(202, 171), Vector2(253, 194),
		Vector2(277, 233), Vector2(267, 269), Vector2(236, 283),
		Vector2(205, 265), Vector2(204, 232), Vector2(233, 204),
		Vector2(285, 192), Vector2(334, 166),
	])
	for index in spine.size() - 1:
		var width_a := 22.0 + 6.0 * sin(float(index) / float(spine.size() - 1) * PI)
		var width_b := 22.0 + 6.0 * sin(float(index + 1) / float(spine.size() - 1) * PI)
		_stroke(image, spine[index], spine[index + 1], width_a, width_b, DRAGON_WHITE)
	# Tapered tail, whiskers, antler horns, and the angular snout distinguish a dragon from a snake.
	_poly(image, PackedVector2Array([
		Vector2(98, 373), Vector2(59, 348), Vector2(82, 407), Vector2(118, 410)
	]), DRAGON_WHITE)
	_poly(image, PackedVector2Array([
		Vector2(319, 169), Vector2(353, 129), Vector2(394, 117),
		Vector2(423, 131), Vector2(450, 147), Vector2(470, 149),
		Vector2(451, 167), Vector2(462, 182), Vector2(421, 183),
		Vector2(394, 173), Vector2(361, 186), Vector2(336, 190)
	]), DRAGON_WHITE)
	_poly(image, PackedVector2Array([
		Vector2(360, 137), Vector2(349, 74), Vector2(369, 97),
		Vector2(377, 127)
	]), DRAGON_WHITE)
	_poly(image, PackedVector2Array([
		Vector2(388, 121), Vector2(403, 63), Vector2(411, 111),
		Vector2(402, 130)
	]), DRAGON_WHITE)
	_poly(image, PackedVector2Array([
		Vector2(399, 174), Vector2(420, 210), Vector2(460, 228),
		Vector2(423, 224), Vector2(383, 184)
	]), DRAGON_WHITE)
	_poly(image, PackedVector2Array([
		Vector2(416, 177), Vector2(444, 200), Vector2(475, 207),
		Vector2(452, 212), Vector2(411, 190)
	]), DRAGON_WHITE)
	# A cut under the muzzle and a dark eye make the head readable against the fin.
	_poly(image, PackedVector2Array([
		Vector2(417, 166), Vector2(452, 166), Vector2(438, 175)
	]), JADE)
	_circle(image, Vector2(399, 142), 6.0, DEEP_JADE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var x := 70
	var cell := 14
	for index in "JADE DRAGON".length():
		var letter := "JADE DRAGON".substr(index, 1)
		if letter == " ":
			x += cell * 3
			continue
		var glyph: Array = _GLYPHS[letter]
		for row in 7:
			for column in 5:
				if glyph[row].substr(column, 1) == "1":
					image.fill_rect(Rect2i(x + column * cell, 67 + row * cell, cell, cell), DEEP_JADE)
		x += cell * 6
	# A calm double rule carries the jade hue across the aircraft's white fuselage.
	image.fill_rect(Rect2i(70, 187, 882, 8), JADE)
	image.fill_rect(Rect2i(70, 204, 882, 3), PALE_JADE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _stroke(image: Image, a: Vector2, b: Vector2, radius_a: float, radius_b: float, ink: Color) -> void:
	var low := a.min(b) - Vector2.ONE * maxf(radius_a, radius_b)
	var high := a.max(b) + Vector2.ONE * maxf(radius_a, radius_b)
	var segment := b - a
	var length_squared := segment.length_squared()
	for y in range(maxi(0, floori(low.y)), mini(image.get_height(), ceili(high.y) + 1)):
		for x in range(maxi(0, floori(low.x)), mini(image.get_width(), ceili(high.x) + 1)):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			var t := clampf((point - a).dot(segment) / length_squared, 0.0, 1.0)
			if point.distance_to(a.lerp(b, t)) <= lerpf(radius_a, radius_b, t):
				image.set_pixel(x, y, ink)


static func _poly(image: Image, vertices: PackedVector2Array, ink: Color) -> void:
	var low := Vector2(float(image.get_width()), float(image.get_height()))
	var high := Vector2.ZERO
	for vertex: Vector2 in vertices:
		low = low.min(vertex)
		high = high.max(vertex)
	for y in range(maxi(0, floori(low.y)), mini(image.get_height(), ceili(high.y) + 1)):
		for x in range(maxi(0, floori(low.x)), mini(image.get_width(), ceili(high.x) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), vertices):
				image.set_pixel(x, y, ink)


static func _circle(image: Image, centre: Vector2, radius: float, ink: Color) -> void:
	for y in range(maxi(0, floori(centre.y - radius)), mini(image.get_height(), ceili(centre.y + radius) + 1)):
		for x in range(maxi(0, floori(centre.x - radius)), mini(image.get_width(), ceili(centre.x + radius) + 1)):
			if Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(centre) <= radius:
				image.set_pixel(x, y, ink)
