extends RefCounted
## Fuji Skyways: a snow-white aircraft with a bold indigo, red-sun fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _INDIGO := Color(0.105, 0.165, 0.32)
const _SUN := Color(0.82, 0.19, 0.17)
const _SNOW := Color(0.98, 0.97, 0.92)

const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"J": ["00111", "00011", "00011", "00011", "11011", "11011", "01110"],
	"K": ["11011", "11011", "11110", "11100", "11110", "11011", "11011"],
	"S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
	"U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
	"W": ["11011", "11011", "11011", "11111", "11111", "11111", "11011"],
	"Y": ["11011", "11011", "01110", "00100", "00100", "00100", "00100"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Fuji Skyways",
		"code": "FJ",
		"body": Color(0.97, 0.975, 0.96),
		"belly": DesignKit.LIMESTONE.lightened(0.16),
		"cheatline": [_INDIGO, _SUN],
		"engine": _INDIGO,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.CHARCOAL,
		"accent": _SUN,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in 512:
		var shade := _INDIGO.lerp(DesignKit.INDIGO.darkened(0.34), float(y) / 511.0 * 0.44)
		image.fill_rect(Rect2i(0, y, 512, 1), shade)

	# The rising sun sits behind the mountain, with enough exposed area to read on a distant fin.
	_disc(image, Vector2(371.0, 168.0), 99.0, _SUN)
	var mountain := Color(0.48, 0.57, 0.68)
	_polygon(image, PackedVector2Array([
		Vector2(0, 458), Vector2(137, 323), Vector2(211, 164), Vector2(266, 164),
		Vector2(341, 319), Vector2(512, 458), Vector2(512, 512), Vector2(0, 512),
	]), mountain)
	# The irregular lower edge evokes snow gullies; the broad cap survives mipmapping.
	_polygon(image, PackedVector2Array([
		Vector2(151, 296), Vector2(211, 164), Vector2(266, 164), Vector2(335, 307),
		Vector2(310, 286), Vector2(293, 315), Vector2(273, 280), Vector2(250, 310),
		Vector2(224, 280), Vector2(202, 312), Vector2(181, 285),
	]), _SNOW)
	# A restrained horizon rule gives the mountain a clean, crafted base.
	image.fill_rect(Rect2i(0, 466, 512, 8), _SNOW)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1536, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var ink := _INDIGO
	var cursor := 52
	for letter in "FUJI":
		_draw_glyph(image, letter, Vector2i(cursor, 36), 20, ink)
		cursor += 120
	# A small hinomaru separates the two strong word groups.
	_disc(image, Vector2(float(cursor + 43), 106.0), 31.0, _SUN)
	cursor += 92
	for letter in "SKYWAYS":
		_draw_glyph(image, letter, Vector2i(cursor, 36), 20, ink)
		cursor += 120
	image.fill_rect(Rect2i(52, 208, 1390, 8), _SUN)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_glyph(image: Image, letter: String, origin: Vector2i, cell: int, ink: Color) -> void:
	var rows: Array = _GLYPHS[letter]
	for row_index in rows.size():
		var row: String = rows[row_index]
		for column in 5:
			if row[column] == "1":
				image.fill_rect(Rect2i(origin.x + column * cell, origin.y + row_index * cell, cell, cell), ink)


static func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var left := maxi(0, floori(center.x - radius))
	var top := maxi(0, floori(center.y - radius))
	var right := mini(image.get_width() - 1, ceili(center.x + radius))
	var bottom := mini(image.get_height() - 1, ceili(center.y + radius))
	var radius_squared := radius * radius
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Vector2(float(x) + 0.5, float(y) + 0.5).distance_squared_to(center) <= radius_squared:
				image.set_pixel(x, y, color)


static func _polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var left := maxi(0, floori(bounds.position.x))
	var top := maxi(0, floori(bounds.position.y))
	var right := mini(image.get_width() - 1, ceili(bounds.end.x))
	var bottom := mini(image.get_height() - 1, ceili(bounds.end.y))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, color)
