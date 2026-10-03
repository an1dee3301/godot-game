extends RefCounted
## Ha Long Air: limestone karsts rising from layered green water.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const DEEP_SEA := Color("174e4b")
const SEA := Color("28746b")
const JADE := Color("559888")
const MIST := Color("a7c7ad")
const FOAM := Color("e2e8d7")
const INK := Color("234f49")

const LETTERS := {
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"A": ["01110", "11011", "10001", "11111", "10001", "10001", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"O": ["01110", "11011", "10001", "10001", "10001", "11011", "01110"],
	"N": ["10001", "11001", "11001", "10101", "10011", "10011", "10001"],
	"G": ["01111", "11000", "10000", "10111", "10001", "11001", "01111"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"R": ["11110", "10011", "10001", "11110", "10100", "10010", "10001"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Ha Long Air",
		"code": "HL",
		"body": Color("f7f6f0"),
		"belly": Color("dbe6df"),
		"cheatline": [JADE, DEEP_SEA],
		"engine": DEEP_SEA,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Color("243b3b"),
		"accent": DesignKit.SAGE,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(DEEP_SEA)
	# A pale sky opening keeps the peaks readable against the deep green fin.
	_poly(image, PackedVector2Array([
		Vector2(0, 0), Vector2(512, 0), Vector2(512, 325),
		Vector2(453, 306), Vector2(408, 318), Vector2(347, 293),
		Vector2(275, 319), Vector2(214, 301), Vector2(151, 319),
		Vector2(89, 298), Vector2(0, 320),
	]), FOAM)
	# Distant island and three broad, steep karst towers, in distinct depths.
	_poly(image, PackedVector2Array([
		Vector2(0, 318), Vector2(46, 308), Vector2(72, 247),
		Vector2(93, 239), Vector2(111, 258), Vector2(135, 293),
		Vector2(177, 311), Vector2(234, 294), Vector2(260, 310),
		Vector2(303, 292), Vector2(349, 311), Vector2(401, 290),
		Vector2(453, 314), Vector2(512, 295), Vector2(512, 430), Vector2(0, 430),
	]), MIST)
	_poly(image, PackedVector2Array([
		Vector2(0, 361), Vector2(26, 354), Vector2(48, 311),
		Vector2(68, 274), Vector2(83, 265), Vector2(96, 280),
		Vector2(112, 318), Vector2(134, 352), Vector2(168, 368),
		Vector2(199, 363), Vector2(227, 326), Vector2(244, 282),
		Vector2(258, 219), Vector2(272, 186), Vector2(287, 174),
		Vector2(301, 192), Vector2(315, 248), Vector2(331, 295),
		Vector2(349, 342), Vector2(376, 364), Vector2(401, 345),
		Vector2(416, 309), Vector2(436, 284), Vector2(451, 290),
		Vector2(467, 332), Vector2(489, 355), Vector2(512, 360),
		Vector2(512, 454), Vector2(0, 454),
	]), JADE)
	# Near island has a high, flat-topped crag and a softer shoulder.
	_poly(image, PackedVector2Array([
		Vector2(0, 391), Vector2(35, 383), Vector2(69, 374),
		Vector2(97, 346), Vector2(115, 304), Vector2(129, 259),
		Vector2(142, 229), Vector2(155, 219), Vector2(171, 222),
		Vector2(183, 250), Vector2(193, 295), Vector2(210, 336),
		Vector2(231, 367), Vector2(263, 385), Vector2(307, 376),
		Vector2(339, 354), Vector2(355, 314), Vector2(370, 281),
		Vector2(383, 275), Vector2(396, 290), Vector2(410, 327),
		Vector2(432, 363), Vector2(462, 383), Vector2(512, 390),
		Vector2(512, 512), Vector2(0, 512),
	]), SEA)
	# Quiet water bands bind the silhouettes into a single emblem.
	_poly(image, PackedVector2Array([
		Vector2(0, 415), Vector2(75, 407), Vector2(141, 416),
		Vector2(225, 407), Vector2(305, 416), Vector2(391, 406),
		Vector2(461, 413), Vector2(512, 408), Vector2(512, 444),
		Vector2(437, 452), Vector2(352, 444), Vector2(269, 453),
		Vector2(180, 443), Vector2(90, 453), Vector2(0, 444),
	]), MIST)
	_poly(image, PackedVector2Array([
		Vector2(0, 462), Vector2(89, 453), Vector2(171, 462),
		Vector2(256, 454), Vector2(340, 462), Vector2(430, 453),
		Vector2(512, 461), Vector2(512, 484), Vector2(427, 477),
		Vector2(338, 486), Vector2(255, 477), Vector2(171, 485),
		Vector2(84, 477), Vector2(0, 485),
	]), JADE)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var caption := "HA LONG AIR"
	var cell_x := 15
	var cell_y := 23
	var advance := 6 * cell_x
	var x := 58
	var top := 38
	for letter_index in caption.length():
		var letter := caption.substr(letter_index, 1)
		if letter == " ":
			x += 3 * cell_x
			continue
		var rows: Array = LETTERS[letter]
		for row_index in rows.size():
			var row: String = rows[row_index]
			for column_index in row.length():
				if row[column_index] == "1":
					image.fill_rect(Rect2i(x + column_index * cell_x, top + row_index * cell_y, cell_x, cell_y), INK)
		x += advance
	# A simple sea line below the name echoes the fin and anchors the wordmark.
	image.fill_rect(Rect2i(58, 220, 900, 10), JADE)
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
