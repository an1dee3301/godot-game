extends RefCounted
## Lotus Vietnam: a broad gold lotus on deep teal, with a quiet ivory fuselage.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const DEEP_TEAL := Color("123f40")
const JADE := Color("23746d")
const GOLD := Color("e1ad54")
const PALE_GOLD := Color("f7d788")
const IVORY := Color("f6f2e8")
const LETTERS := {
	"L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"T": ["11111", "01110", "00100", "00100", "00100", "00100", "00100"],
	"U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
	"S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
	"V": ["11011", "11011", "11011", "11011", "11011", "01110", "00100"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
	"N": ["11001", "11101", "11101", "11111", "10111", "10111", "10011"],
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"M": ["11011", "11111", "11111", "10101", "10001", "10001", "10001"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Lotus Vietnam",
		"code": "LV",
		"body": IVORY,
		"belly": JADE,
		"cheatline": [GOLD, DEEP_TEAL],
		"engine": DEEP_TEAL,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.CHARCOAL,
		"accent": GOLD,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(DEEP_TEAL)
	# A low jade sweep follows the fin root without competing with the flower.
	_poly(image, PackedVector2Array([
		Vector2(0, 470), Vector2(98, 452), Vector2(211, 460),
		Vector2(338, 445), Vector2(512, 460), Vector2(512, 512), Vector2(0, 512),
	]), JADE)
	# Five large, overlapping petals make one readable silhouette at a distance.
	_poly(image, PackedVector2Array([
		Vector2(256, 111), Vector2(292, 171), Vector2(312, 244),
		Vector2(300, 319), Vector2(256, 378), Vector2(212, 319),
		Vector2(200, 244), Vector2(220, 171),
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(119, 211), Vector2(185, 231), Vector2(228, 275),
		Vector2(256, 365), Vector2(190, 350), Vector2(143, 310),
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(393, 211), Vector2(369, 310), Vector2(322, 350),
		Vector2(256, 365), Vector2(284, 275), Vector2(327, 231),
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(62, 305), Vector2(151, 329), Vector2(222, 370),
		Vector2(256, 394), Vector2(182, 402), Vector2(111, 374),
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(450, 305), Vector2(401, 374), Vector2(330, 402),
		Vector2(256, 394), Vector2(290, 370), Vector2(361, 329),
	]), GOLD)
	# Fine inner facets give the petals a folded, crafted quality.
	_poly(image, PackedVector2Array([
		Vector2(256, 145), Vector2(276, 206), Vector2(282, 278),
		Vector2(256, 346), Vector2(230, 278), Vector2(236, 206),
	]), PALE_GOLD)
	_poly(image, PackedVector2Array([
		Vector2(140, 238), Vector2(198, 264), Vector2(233, 328),
		Vector2(183, 307),
	]), PALE_GOLD)
	_poly(image, PackedVector2Array([
		Vector2(372, 238), Vector2(329, 307), Vector2(279, 328),
		Vector2(314, 264),
	]), PALE_GOLD)
	# The broad lower bowl binds the flower into a single emblem.
	_poly(image, PackedVector2Array([
		Vector2(115, 391), Vector2(179, 410), Vector2(256, 416),
		Vector2(333, 410), Vector2(397, 391), Vector2(354, 445),
		Vector2(297, 463), Vector2(215, 463), Vector2(158, 445),
	]), GOLD)
	_poly(image, PackedVector2Array([
		Vector2(179, 423), Vector2(256, 432), Vector2(333, 423),
		Vector2(296, 447), Vector2(216, 447),
	]), PALE_GOLD)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1536, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var x := 66
	const CELL_X := 17
	const CELL_Y := 23
	const TOP := 30
	for index in "LOTUS VIETNAM".length():
		var letter := "LOTUS VIETNAM".substr(index, 1)
		if letter == " ":
			x += 52
			continue
		var rows: Array = LETTERS[letter]
		for row_index in rows.size():
			var row: String = rows[row_index]
			for column_index in row.length():
				if row[column_index] == "1":
					image.fill_rect(Rect2i(x + column_index * CELL_X, TOP + row_index * CELL_Y, CELL_X, CELL_Y), DEEP_TEAL)
		x += 112
	# A clean golden rule repeats the tail's warm detail beneath the wordmark.
	image.fill_rect(Rect2i(66, 218, 1383, 10), GOLD)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _poly(image: Image, points: PackedVector2Array, color: Color) -> void:
	var min_y := image.get_height()
	var max_y := 0
	for point in points:
		min_y = mini(min_y, floori(point.y))
		max_y = maxi(max_y, ceili(point.y))
	for y in range(maxi(0, min_y), mini(image.get_height(), max_y)):
		var scan_y := float(y) + 0.5
		var crossings: Array[float] = []
		for edge in points.size():
			var a: Vector2 = points[edge]
			var b: Vector2 = points[(edge + 1) % points.size()]
			if (a.y <= scan_y and b.y > scan_y) or (b.y <= scan_y and a.y > scan_y):
				crossings.append(a.x + (scan_y - a.y) * (b.x - a.x) / (b.y - a.y))
		crossings.sort()
		for pair in crossings.size() / 2:
			var left := maxi(0, ceili(crossings[pair * 2] - 0.5))
			var right := mini(image.get_width(), ceili(crossings[pair * 2 + 1] - 0.5))
			if right > left:
				image.fill_rect(Rect2i(left, y, right - left, 1), color)
