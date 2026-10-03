extends RefCounted
## Mistral France: a quiet white airframe and a silver wind mark across a navy fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _NAVY := Color(0.035, 0.085, 0.18)
const _RED := Color(0.72, 0.115, 0.16)
const _SILVER := Color(0.79, 0.84, 0.87)

const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
	"E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
	"F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
	"M": ["11011", "11111", "11111", "11011", "11011", "11011", "11011"],
	"N": ["11011", "11111", "11111", "11111", "11111", "11111", "11011"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
	"S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Mistral France",
		"code": "MF",
		"body": Color(0.97, 0.965, 0.945),
		"belly": Color(0.80, 0.82, 0.83),
		"cheatline": [_RED],
		"engine": Color(0.91, 0.92, 0.91),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": _NAVY,
		"accent": _RED,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in 512:
		for x in 512:
			var u := float(x) / 511.0
			var v := float(y) / 511.0
			var background := _NAVY.lerp(Color(0.08, 0.15, 0.27), 0.35 * u + 0.2 * (1.0 - v))
			# Three tapering ribbons make the mark read as wind across the entire fin.
			var sweep := 361.0 - 210.0 * u - 31.0 * sin(PI * u)
			var main_width := 44.0 + 34.0 * sin(PI * u)
			var distance := float(y) - sweep
			if absf(distance) < main_width:
				var silver := _SILVER.lerp(Color(0.96, 0.97, 0.96), clampf(0.45 - distance / (main_width * 2.0), 0.0, 1.0))
				background = silver
			var upper := sweep - 94.0 - 15.0 * sin(PI * u)
			var upper_width := 10.0 + 13.0 * sin(PI * u)
			if absf(float(y) - upper) < upper_width:
				background = Color(0.69, 0.76, 0.81)
			var lower := sweep + 102.0 + 11.0 * sin(PI * u)
			var lower_width := 5.0 + 8.0 * sin(PI * u)
			if absf(float(y) - lower) < lower_width:
				background = Color(0.91, 0.93, 0.93)
			image.set_pixel(x, y, background)
	# A short red wake ties the fin to the thin fuselage cheatline.
	_fill_polygon(image, PackedVector2Array([
		Vector2(34, 465), Vector2(170, 435), Vector2(287, 401),
		Vector2(225, 447), Vector2(104, 481), Vector2(34, 489),
	]), _RED)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_draw_word(image, "MISTRAL", Vector2i(44, 19), 21, _NAVY)
	_fill_rect(image, Rect2i(44, 181, 885, 7), _RED)
	_draw_word(image, "FRANCE", Vector2i(47, 200), 7, _NAVY)
	# A compact wind signature balances the second line at the far right.
	_fill_polygon(image, PackedVector2Array([
		Vector2(782, 231), Vector2(841, 210), Vector2(928, 206),
		Vector2(893, 220), Vector2(826, 236),
	]), _SILVER)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_word(image: Image, word: String, at: Vector2i, cell: int, ink: Color) -> void:
	var cursor := at.x
	for i in word.length():
		var letter := word.substr(i, 1)
		var rows: Array = _GLYPHS[letter]
		for row in rows.size():
			var bits: String = rows[row]
			for column in 5:
				if bits[column] == "1":
					_fill_rect(image, Rect2i(cursor + column * cell, at.y + row * cell, cell, cell), ink)
		cursor += cell * 6


static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(image.get_height(), rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(image.get_width(), rect.end.x)):
			image.set_pixel(x, y, color)


static func _fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var left := image.get_width()
	var top := image.get_height()
	var right := 0
	var bottom := 0
	for point in points:
		left = mini(left, floori(point.x))
		top = mini(top, floori(point.y))
		right = maxi(right, ceili(point.x))
		bottom = maxi(bottom, ceili(point.y))
	for y in range(maxi(0, top), mini(image.get_height(), bottom)):
		for x in range(maxi(0, left), mini(image.get_width(), right)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				image.set_pixel(x, y, color)
