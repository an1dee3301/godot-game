extends RefCounted
## Southern Cross: a quiet white aircraft with a bold night-sky tail.

const NAVY := Color(0.075, 0.14, 0.25)
const WHITE := Color(0.97, 0.97, 0.94)
const WARM_WHITE := Color(0.91, 0.9, 0.85)
const BRASS := Color(0.7, 0.55, 0.33)

const LETTERS := {
	"S": ["11111", "10000", "10000", "11111", "00001", "00001", "11111"],
	"O": ["11111", "10001", "10001", "10001", "10001", "10001", "11111"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "11111"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"N": ["10001", "11001", "10101", "10101", "10011", "10001", "10001"],
	"C": ["11111", "10000", "10000", "10000", "10000", "10000", "11111"],
}

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Southern Cross",
		"code": "SX",
		"body": WHITE,
		"belly": WARM_WHITE,
		"cheatline": [NAVY, BRASS],
		"engine": NAVY,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Color(0.1, 0.18, 0.25),
		"accent": BRASS,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(NAVY)
	# Four oversized stars form a clear cross even when the fin is seen from afar.
	_draw_star(image, Vector2(256.0, 83.0), 61.0)
	_draw_star(image, Vector2(111.0, 251.0), 55.0)
	_draw_star(image, Vector2(390.0, 251.0), 55.0)
	_draw_star(image, Vector2(256.0, 410.0), 70.0)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_star(image: Image, centre: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in 8:
		var angle := -PI * 0.5 + float(i) * PI / 4.0
		var distance := radius if i % 2 == 0 else radius * 0.24
		points.append(centre + Vector2(cos(angle), sin(angle)) * distance)
	var left := maxi(0, int(floor(centre.x - radius)))
	var right := mini(image.get_width() - 1, int(ceil(centre.x + radius)))
	var top := maxi(0, int(floor(centre.y - radius)))
	var bottom := mini(image.get_height() - 1, int(ceil(centre.y + radius)))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				image.set_pixel(x, y, WHITE)


static func _make_title() -> ImageTexture:
	var image := Image.create(1024, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cursor := 54
	for letter in "SOUTHERN CROSS":
		if letter == " ":
			cursor += 28
			continue
		var rows: Array = LETTERS[letter]
		for row_index in rows.size():
			var row: String = rows[row_index]
			for column in 5:
				if row[column] == "1":
					image.fill_rect(Rect2i(cursor + column * 11, 40 + row_index * 16, 11, 16), NAVY)
		cursor += 67
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
