extends RefCounted
## Peony Star: a layered peony bloom on pale stone-grey, paired with a strong plum wordmark.

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture

const WHITE := Color("f9f7f3")
const SOFT_GREY := Color("d9d8d5")
const PLUM := Color("702349")
const MAGENTA := Color("ba346f")
const PETAL := Color("e45b91")
const PALE_PETAL := Color("f6a3bd")
const GOLD := Color("c09b62")

const LETTERS := {
	"P": ["11110", "11011", "11011", "11110", "11000", "11000", "11000"],
	"E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
	"O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
	"N": ["11011", "11111", "11111", "11111", "11111", "11111", "11011"],
	"Y": ["11011", "11011", "11011", "01110", "00100", "00100", "00100"],
	"S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
	"T": ["11111", "01110", "00100", "00100", "00100", "00100", "00100"],
	"A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
	"R": ["11110", "11011", "11011", "11110", "11100", "11010", "11011"],
}


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Peony Star",
		"code": "PS",
		"body": WHITE,
		"belly": SOFT_GREY,
		"cheatline": [MAGENTA, GOLD],
		"engine": PLUM,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": DesignKit.CHARCOAL,
		"accent": MAGENTA,
	}


static func _make_tail() -> ImageTexture:
	var image := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	image.fill(SOFT_GREY)
	# A fine metallic-looking root line gives the fin a crafted edge.
	image.fill_rect(Rect2i(0, 472, 512, 12), GOLD)
	var center := Vector2(256.0, 247.0)
	# Broad scalloped petals form one unmistakable silhouette at long range.
	for petal_index in 8:
		var angle := TAU * float(petal_index) / 8.0
		_petal(image, center, angle, 1.0, PLUM)
	for petal_index in 8:
		var angle := TAU * float(petal_index) / 8.0
		_petal(image, center, angle, 0.91, MAGENTA)
	# A second ring turns the emblem into a full peony rather than a flat rosette.
	for petal_index in 7:
		var angle := TAU * (float(petal_index) + 0.5) / 7.0
		_petal(image, center, angle, 0.59, PETAL)
	for petal_index in 7:
		var angle := TAU * (float(petal_index) + 0.5) / 7.0
		var tip := center + Vector2(0.0, -116.0).rotated(angle)
		_circle(image, tip, 9.0, PALE_PETAL)
	_circle(image, center, 43.0, PLUM)
	_circle(image, center, 31.0, DesignKit.CREAM)
	for stamen in 9:
		var angle := TAU * float(stamen) / 9.0
		_circle(image, center + Vector2(0.0, -18.0).rotated(angle), 5.5, GOLD)
	_circle(image, center, 7.0, GOLD)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _petal(image: Image, center: Vector2, angle: float, scale: float, color: Color) -> void:
	var outline := PackedVector2Array([
		Vector2(0.0, -8.0), Vector2(-52.0, -66.0), Vector2(-76.0, -117.0),
		Vector2(-73.0, -157.0), Vector2(-50.0, -173.0), Vector2(-24.0, -164.0),
		Vector2(0.0, -187.0), Vector2(24.0, -164.0), Vector2(50.0, -173.0),
		Vector2(73.0, -157.0), Vector2(76.0, -117.0), Vector2(52.0, -66.0),
	])
	var points := PackedVector2Array()
	for point in outline:
		points.append(center + (point * scale).rotated(angle))
	_poly(image, points, color)


static func _make_title() -> ImageTexture:
	var image := Image.create(1536, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var x := 172
	for index in "PEONY STAR".length():
		var letter := "PEONY STAR".substr(index, 1)
		if letter == " ":
			x += 58
			continue
		var rows: Array = LETTERS[letter]
		for row_index in rows.size():
			var row: String = rows[row_index]
			for column_index in row.length():
				if row[column_index] == "1":
					image.fill_rect(Rect2i(x + column_index * 20, 34 + row_index * 25, 20, 25), PLUM)
		x += 124
	# A restrained magenta rule makes the two-word name read as a single mark.
	image.fill_rect(Rect2i(172, 224, x - 196, 9), MAGENTA)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	for y in range(maxi(0, floori(center.y - radius)), mini(image.get_height(), ceili(center.y + radius))):
		var distance_y := float(y) + 0.5 - center.y
		var half_width := sqrt(maxf(0.0, radius * radius - distance_y * distance_y))
		var left := maxi(0, ceili(center.x - half_width - 0.5))
		var right := mini(image.get_width(), ceili(center.x + half_width - 0.5))
		if right > left:
			image.fill_rect(Rect2i(left, y, right - left, 1), color)


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
