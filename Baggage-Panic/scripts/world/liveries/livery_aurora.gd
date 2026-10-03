extends RefCounted
## Aurora Nordic Cargo: a quiet pearl-grey aircraft with a vivid polar-light fin.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const _GLYPHS := {
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
	"D": ["11110", "11011", "11011", "11011", "11011", "11011", "11110"],
	"G": ["01111", "11000", "11000", "11011", "11011", "11011", "01111"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"N": ["11011", "11111", "11111", "11111", "11111", "11011", "11011"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
	"U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Aurora Nordic Cargo",
		"code": "AU",
		"body": Color(0.88, 0.91, 0.91),
		"belly": Color(0.64, 0.70, 0.71),
		"cheatline": [Color(0.30, 0.66, 0.57), Color(0.48, 0.37, 0.67)],
		"engine": DesignKit.INDIGO.darkened(0.26),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.CHARCOAL,
		"accent": Color(0.38, 0.78, 0.63),
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var midnight := DesignKit.INDIGO.darkened(0.56)
	var violet := Color(0.28, 0.20, 0.44)
	var jade := Color(0.16, 0.47, 0.42)
	for y in 512:
		for x in 512:
			var u := float(x) / 511.0
			var v := float(y) / 511.0
			var base := midnight.lerp(violet, 0.42 * (1.0 - v) + 0.15 * u)
			base = base.lerp(jade, 0.18 * u * v)
			# Broad undulating curtains stay visible when the fin is seen at a distance.
			var sweep := float(y) - (385.0 - 285.0 * u + 45.0 * sin(u * 7.0))
			var green_light := exp(-pow(sweep / 77.0, 2.0)) * 0.82
			var violet_light := exp(-pow((sweep - 96.0) / 62.0, 2.0)) * 0.68
			base = base.lerp(Color(0.22, 0.84, 0.61), green_light)
			base = base.lerp(Color(0.58, 0.40, 0.86), violet_light)
			image.set_pixel(x, y, base)
	# A luminous, split A reads as both the initial and a northern mountain.
	var pearl := DesignKit.CREAM.lightened(0.09)
	_fill_poly(image, PackedVector2Array([Vector2(69, 448), Vector2(220, 66), Vector2(267, 66), Vector2(236, 152), Vector2(145, 448)]), pearl)
	_fill_poly(image, PackedVector2Array([Vector2(267, 66), Vector2(443, 448), Vector2(361, 448), Vector2(231, 168)]), pearl)
	_fill_poly(image, PackedVector2Array([Vector2(167, 324), Vector2(354, 324), Vector2(382, 382), Vector2(144, 382)]), pearl)
	# A thin brass horizon line adds a crafted detail without competing with the mark.
	_fill_rect(image, Rect2i(72, 468, 365, 7), Color(0.83, 0.69, 0.45))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var ink := DesignKit.INDIGO.darkened(0.34)
	_draw_word(image, "AURORA", Vector2i(42, 24), 17, ink)
	_fill_rect(image, Rect2i(46, 157, 617, 8), Color(0.28, 0.67, 0.56))
	_draw_word(image, "NORDIC CARGO", Vector2i(47, 181), 8, ink)
	# The small brand stamp repeats the large fin symbol without using a font.
	var stamp := Color(0.28, 0.67, 0.56)
	_fill_poly(image, PackedVector2Array([Vector2(803, 164), Vector2(873, 25), Vector2(902, 25), Vector2(836, 164)]), stamp)
	_fill_poly(image, PackedVector2Array([Vector2(902, 25), Vector2(974, 164), Vector2(940, 164), Vector2(886, 68)]), stamp)
	_fill_rect(image, Rect2i(843, 119, 111, 19), stamp)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_word(image: Image, word: String, at: Vector2i, cell: int, ink: Color) -> void:
	var cursor := at.x
	for i in word.length():
		var letter := word.substr(i, 1)
		if letter == " ":
			cursor += cell * 4
			continue
		var rows: Array = _GLYPHS[letter]
		for row in rows.size():
			var bits: String = rows[row]
			for column in 5:
				if bits[column] == "1":
					_fill_rect(image, Rect2i(cursor + column * cell, at.y + row * cell, cell, cell), ink)
		cursor += cell * 6


static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var left := maxi(0, rect.position.x)
	var top := maxi(0, rect.position.y)
	var right := mini(image.get_width(), rect.end.x)
	var bottom := mini(image.get_height(), rect.end.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color)


static func _fill_poly(image: Image, points: PackedVector2Array, color: Color) -> void:
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
