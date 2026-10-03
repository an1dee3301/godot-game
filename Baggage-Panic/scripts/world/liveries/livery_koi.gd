extends RefCounted
## Koi Pacific: a white aircraft with a vermilion koi on a midnight-blue fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _BLUE := Color(0.055, 0.13, 0.25)
const _VERMILION := Color(0.9, 0.27, 0.13)
const _CORAL := Color(1.0, 0.39, 0.19)
const _IVORY := Color(0.99, 0.94, 0.82)
const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
	"F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"K": ["11011", "11011", "11110", "11100", "11110", "11011", "11011"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"P": ["11110", "11011", "11011", "11110", "11000", "11000", "11000"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Koi Pacific",
		"code": "KP",
		"body": Color(0.985, 0.98, 0.955),
		"belly": DesignKit.LIMESTONE.lightened(0.13),
		"cheatline": [_VERMILION, _BLUE],
		"engine": _BLUE,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.CHARCOAL,
		"accent": _VERMILION,
		"brand_font": Signage.font(),
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(_BLUE)
	# Broad blue-on-blue current gives the fish movement without competing with its outline.
	_polygon(image, PackedVector2Array([
		Vector2(0, 460), Vector2(105, 444), Vector2(198, 459), Vector2(304, 472),
		Vector2(404, 448), Vector2(512, 407), Vector2(512, 512), Vector2(0, 512),
	]), Color(0.09, 0.2, 0.33))
	# Paired fork of the tail, followed by the far-side fins.
	_polygon(image, PackedVector2Array([
		Vector2(185, 331), Vector2(45, 263), Vector2(81, 352), Vector2(34, 449),
		Vector2(204, 382),
	]), _VERMILION)
	_polygon(image, PackedVector2Array([
		Vector2(165, 344), Vector2(74, 290), Vector2(105, 354), Vector2(66, 418),
		Vector2(190, 371),
	]), _CORAL)
	_polygon(image, PackedVector2Array([
		Vector2(258, 186), Vector2(254, 90), Vector2(342, 151), Vector2(355, 183),
	]), _VERMILION)
	_polygon(image, PackedVector2Array([
		Vector2(268, 275), Vector2(250, 396), Vector2(346, 299),
	]), _CORAL)
	# The sweeping silhouette fills the fin and stays recognizable after mipmapping.
	_polygon(image, PackedVector2Array([
		Vector2(133, 330), Vector2(165, 286), Vector2(208, 234), Vector2(260, 188),
		Vector2(317, 153), Vector2(372, 138), Vector2(421, 147), Vector2(455, 166),
		Vector2(477, 183), Vector2(456, 201), Vector2(438, 220), Vector2(401, 241),
		Vector2(351, 259), Vector2(303, 282), Vector2(254, 316), Vector2(208, 355),
		Vector2(168, 379), Vector2(137, 371),
	]), _CORAL)
	# Two ivory patches make this a koi rather than a generic fish silhouette.
	_polygon(image, PackedVector2Array([
		Vector2(187, 301), Vector2(215, 255), Vector2(248, 213), Vector2(279, 195),
		Vector2(288, 227), Vector2(268, 259), Vector2(230, 298), Vector2(197, 329),
	]), _IVORY)
	_polygon(image, PackedVector2Array([
		Vector2(322, 165), Vector2(359, 142), Vector2(397, 143), Vector2(409, 158),
		Vector2(389, 180), Vector2(355, 193), Vector2(321, 192),
	]), _IVORY)
	_polygon(image, PackedVector2Array([
		Vector2(267, 304), Vector2(321, 274), Vector2(369, 250), Vector2(422, 225),
		Vector2(385, 255), Vector2(335, 280), Vector2(291, 315), Vector2(245, 350),
	]), _IVORY)
	# Face: a high-contrast eye, gill line and small mouth notch.
	_disc(image, Vector2(430, 173), 14.0, _IVORY)
	_disc(image, Vector2(434, 173), 6.0, _BLUE)
	_polygon(image, PackedVector2Array([
		Vector2(403, 194), Vector2(410, 199), Vector2(405, 221), Vector2(394, 225),
		Vector2(399, 206),
	]), _BLUE)
	_polygon(image, PackedVector2Array([
		Vector2(453, 192), Vector2(477, 183), Vector2(457, 204),
	]), _IVORY)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1536, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cursor := 54
	for letter in "KOI":
		_draw_glyph(image, letter, Vector2i(cursor, 35), 21, _VERMILION)
		cursor += 126
	cursor += 82
	for letter in "PACIFIC":
		_draw_glyph(image, letter, Vector2i(cursor, 35), 21, _BLUE)
		cursor += 126
	image.fill_rect(Rect2i(54, 207, 1267, 8), _VERMILION)
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
