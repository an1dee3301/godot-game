extends RefCounted

## Baobab Air: warm sand paint, a sunset fin, and a broad tree silhouette.
static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _INK := Color(0.18, 0.13, 0.11)
const _SUN := Color(1.0, 0.79, 0.47)
const _SUNSET := Color(0.88, 0.35, 0.17)

const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"B": ["11110", "11011", "11011", "11110", "11011", "11011", "11110"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Baobab Air",
		"code": "BB",
		"body": Color(0.89, 0.82, 0.68),
		"belly": DesignKit.LIMESTONE.darkened(0.14),
		"cheatline": [DesignKit.CLAY, DesignKit.OCHRE],
		"engine": DesignKit.WALNUT.darkened(0.22),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Color(0.15, 0.23, 0.26),
		"accent": _SUNSET,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in 512:
		var t := float(y) / 511.0
		var tone := _SUNSET.lerp(DesignKit.CLAY.darkened(0.12), t * 0.54)
		for x in 512:
			image.set_pixel(x, y, tone)

	# The low sun remains visible around the canopy and makes the silhouette read at a distance.
	_ellipse(image, Vector2(335.0, 220.0), Vector2(105.0, 105.0), _SUN)
	_ellipse(image, Vector2(335.0, 220.0), Vector2(91.0, 91.0), DesignKit.CREAM.lightened(0.02))

	# A broad, irregular crown gives the tree its characteristic baobab profile.
	_ellipse(image, Vector2(150.0, 237.0), Vector2(81.0, 49.0), _INK)
	_ellipse(image, Vector2(213.0, 210.0), Vector2(85.0, 65.0), _INK)
	_ellipse(image, Vector2(291.0, 215.0), Vector2(91.0, 59.0), _INK)
	_ellipse(image, Vector2(362.0, 239.0), Vector2(79.0, 45.0), _INK)
	_ellipse(image, Vector2(252.0, 187.0), Vector2(72.0, 52.0), _INK)
	_ellipse(image, Vector2(109.0, 252.0), Vector2(38.0, 29.0), _INK)
	_ellipse(image, Vector2(405.0, 257.0), Vector2(36.0, 27.0), _INK)

	# Substantial forks and a bottle-shaped trunk remain clear when the fin is small.
	_polygon(image, PackedVector2Array([
		Vector2(221, 307), Vector2(170, 247), Vector2(121, 241), Vector2(175, 274),
		Vector2(216, 352), Vector2(281, 352), Vector2(342, 269), Vector2(391, 249),
		Vector2(339, 248), Vector2(282, 313), Vector2(271, 224), Vector2(244, 216),
	]), _INK)
	_polygon(image, PackedVector2Array([
		Vector2(234, 280), Vector2(278, 280), Vector2(292, 359), Vector2(323, 466),
		Vector2(357, 512), Vector2(143, 512), Vector2(176, 466), Vector2(214, 359),
	]), _INK)
	_polygon(image, PackedVector2Array([
		Vector2(0, 477), Vector2(74, 458), Vector2(156, 467), Vector2(240, 460),
		Vector2(323, 466), Vector2(410, 453), Vector2(512, 469), Vector2(512, 512),
		Vector2(0, 512),
	]), _INK)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var x := 33
	for letter in "BAOBAB":
		_draw_glyph(image, letter, Vector2i(x, 23), _INK)
		x += 98
	x += 30
	for letter in "AIR":
		_draw_glyph(image, letter, Vector2i(x, 23), _SUNSET)
		x += 98
	# A single ochre rule carries the warmth of the fin onto the fuselage.
	image.fill_rect(Rect2i(33, 164, 560, 9), DesignKit.OCHRE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_glyph(image: Image, letter: String, origin: Vector2i, color: Color) -> void:
	var rows: Array = _GLYPHS[letter]
	for row_index in rows.size():
		var row: String = rows[row_index]
		for column in 5:
			if row[column] == "1":
				image.fill_rect(Rect2i(origin.x + column * 18, origin.y + row_index * 18, 18, 18), color)


static func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color) -> void:
	var x0 := maxi(0, int(floorf(center.x - radius.x)))
	var x1 := mini(image.get_width() - 1, int(ceilf(center.x + radius.x)))
	var y0 := maxi(0, int(floorf(center.y - radius.y)))
	var y1 := mini(image.get_height() - 1, int(ceilf(center.y + radius.y)))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (float(x) + 0.5 - center.x) / radius.x
			var dy := (float(y) + 0.5 - center.y) / radius.y
			if dx * dx + dy * dy <= 1.0:
				image.set_pixel(x, y, color)


static func _polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var x0 := maxi(0, int(floorf(bounds.position.x)))
	var x1 := mini(image.get_width() - 1, int(ceilf(bounds.end.x)))
	var y0 := maxi(0, int(floorf(bounds.position.y)))
	var y1 := mini(image.get_height() - 1, int(ceilf(bounds.end.y)))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, color)
