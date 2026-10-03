extends RefCounted
## Mekong Airlines: a quiet white fuselage with a bold rising river on the tail.

const RIVER_DEEP := Color(0.055, 0.23, 0.34)
const RIVER_BLUE := Color(0.08, 0.43, 0.59)
const RIVER_LIGHT := Color(0.36, 0.69, 0.72)
const BAMBOO := Color(0.34, 0.51, 0.36)
const PAPER := Color(0.975, 0.97, 0.94)

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Mekong Airlines",
		"code": "MK",
		"body": Color(0.96, 0.97, 0.96),
		"belly": Color(0.84, 0.89, 0.87),
		"cheatline": [RIVER_DEEP, RIVER_BLUE, BAMBOO],
		"engine": RIVER_DEEP,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Color(0.075, 0.16, 0.22),
		"accent": BAMBOO,
	}


static func _make_tail() -> ImageTexture:
	var size := 512
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(PAPER)
	for y in size:
		for x in size:
			var fx := float(x)
			var fy := float(y)
			# One rising channel and three separated branches read as a river at apron scale.
			var bank := 414.0 - fx * 0.66 + 15.0 * sin(fx * 0.014)
			var offset := fy - bank
			var ink := PAPER
			if offset >= 0.0:
				ink = RIVER_DEEP
			elif offset >= -108.0 and offset <= -25.0:
				ink = RIVER_BLUE
			elif offset >= -182.0 and offset <= -137.0:
				ink = RIVER_LIGHT
			elif offset >= -218.0 and offset <= -205.0:
				ink = BAMBOO
			image.set_pixel(x, y, ink)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var x := 62
	var y := 28
	var w := 126
	var h := 132
	var stroke := 21
	var gap := 31
	# M: broad verticals and a deep central chevron.
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_rect(image, x + w - stroke, y, stroke, h, RIVER_DEEP)
	_quad(image, Vector2(x + 12, y), Vector2(x + 35, y), Vector2(x + 64, y + 55), Vector2(x + 52, y + 83), RIVER_DEEP)
	_quad(image, Vector2(x + w - 35, y), Vector2(x + w - 12, y), Vector2(x + 74, y + 83), Vector2(x + 62, y + 55), RIVER_DEEP)
	x += w + gap
	# E.
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_rect(image, x, y, w, stroke, RIVER_DEEP)
	_rect(image, x, y + 55, w - 17, stroke, RIVER_DEEP)
	_rect(image, x, y + h - stroke, w, stroke, RIVER_DEEP)
	x += w + gap
	# K.
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_quad(image, Vector2(x + 20, y + 58), Vector2(x + 95, y), Vector2(x + w, y), Vector2(x + 46, y + 77), RIVER_DEEP)
	_quad(image, Vector2(x + 43, y + 59), Vector2(x + 63, y + 72), Vector2(x + w, y + h), Vector2(x + 97, y + h), RIVER_DEEP)
	x += w + gap
	# O.
	_rect(image, x, y, w, stroke, RIVER_DEEP)
	_rect(image, x, y + h - stroke, w, stroke, RIVER_DEEP)
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_rect(image, x + w - stroke, y, stroke, h, RIVER_DEEP)
	x += w + gap
	# N.
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_rect(image, x + w - stroke, y, stroke, h, RIVER_DEEP)
	_quad(image, Vector2(x + 14, y), Vector2(x + 34, y), Vector2(x + w - 13, y + h), Vector2(x + w - 34, y + h), RIVER_DEEP)
	x += w + gap
	# G: an open counter and an assertive right-facing crossbar.
	_rect(image, x, y, w, stroke, RIVER_DEEP)
	_rect(image, x, y + h - stroke, w, stroke, RIVER_DEEP)
	_rect(image, x, y, stroke, h, RIVER_DEEP)
	_rect(image, x + w - stroke, y + 68, stroke, h - 68, RIVER_DEEP)
	_rect(image, x + 67, y + 68, w - 67, stroke, RIVER_DEEP)
	# A bamboo-green river rule gives the name its own visual signature.
	_rect(image, 62, 174, 898, 7, BAMBOO)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)


static func _quad(image: Image, a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	var points := PackedVector2Array([a, b, c, d])
	var left := maxi(0, int(floor(minf(minf(a.x, b.x), minf(c.x, d.x)))))
	var right := mini(image.get_width() - 1, int(ceil(maxf(maxf(a.x, b.x), maxf(c.x, d.x)))))
	var top := maxi(0, int(floor(minf(minf(a.y, b.y), minf(c.y, d.y)))))
	var bottom := mini(image.get_height() - 1, int(ceil(maxf(maxf(a.y, b.y), maxf(c.y, d.y)))))
	for py in range(top, bottom + 1):
		for px in range(left, right + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(px) + 0.5, float(py) + 0.5), points):
				image.set_pixel(px, py, color)
