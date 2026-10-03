extends RefCounted
## Lumière Airways: pearl paint, champagne metal, and a monumental Art Deco fan.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _INK := Color(0.19, 0.20, 0.23)
const _GOLD := Color(0.77, 0.59, 0.32)
const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
	"M": ["11011", "11111", "11111", "11011", "11011", "11011", "11011"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
	"S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
	"U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
	"W": ["11011", "11011", "11011", "11011", "11111", "11111", "11011"],
	"Y": ["11011", "11011", "01110", "00100", "00100", "00100", "00100"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Lumière Airways",
		"code": "LA",
		"body": DesignKit.CREAM.lightened(0.08),
		"belly": DesignKit.LIMESTONE.lightened(0.10),
		"cheatline": [_GOLD, _INK],
		"engine": _INK,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": _INK,
		"accent": _GOLD,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var champagne := DesignKit.OCHRE.lightened(0.34)
	var pale := DesignKit.CREAM
	var hub := Vector2(256.0, 414.0)
	var start := deg_to_rad(-170.0)
	var sweep := deg_to_rad(160.0)
	for y in 512:
		for x in 512:
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - hub
			var radius := p.length()
			var angle := atan2(p.y, p.x)
			var finish := clampf(float(y) / 511.0, 0.0, 1.0)
			var color := pale.lerp(champagne, 0.54 + 0.28 * finish)
			if angle >= start and angle <= start + sweep:
				if radius >= 356.0 and radius <= 370.0:
					color = _INK
				elif radius >= 56.0 and radius < 356.0:
					var sector := (angle - start) / sweep * 11.0
					if fposmod(sector, 1.0) < 0.73:
						color = _INK
			if radius < 55.0:
				color = _INK
			elif radius >= 55.0 and radius < 64.0:
				color = _GOLD.darkened(0.22)
			image.set_pixel(x, y, color)
	# The two fine base rules echo machined brass detailing on the aircraft.
	image.fill_rect(Rect2i(32, 471, 448, 7), _INK)
	image.fill_rect(Rect2i(54, 488, 404, 4), _GOLD.darkened(0.22))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_draw_word(image, "LUMIERE", Vector2i(39, 35), 18, _INK)
	# A broad grave accent makes the French name clear without relying on fonts.
	image.fill_rect(Rect2i(486, 10, 17, 10), _INK)
	image.fill_rect(Rect2i(502, 20, 17, 10), _INK)
	image.fill_rect(Rect2i(42, 177, 749, 7), _GOLD)
	_draw_word(image, "AIRWAYS", Vector2i(43, 194), 8, _INK)
	# Compact fan seal balances the long wordmark on the right.
	var center := Vector2(916.0, 207.0)
	for y in range(30, 245):
		for x in range(816, 1015):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - center
			var radius := p.length()
			var angle := atan2(p.y, p.x)
			if angle < deg_to_rad(-165.0) or angle > deg_to_rad(-15.0):
				continue
			if radius < 14.0 or (radius > 88.0 and radius < 93.0):
				image.set_pixel(x, y, _GOLD)
			elif radius > 16.0 and radius < 87.0:
				var sector := (angle + deg_to_rad(165.0)) / deg_to_rad(150.0) * 9.0
				if fposmod(sector, 1.0) < 0.7:
					image.set_pixel(x, y, _GOLD)
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
					image.fill_rect(Rect2i(cursor + column * cell, at.y + row * cell, cell, cell), ink)
		cursor += cell * 6
