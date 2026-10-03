extends RefCounted

const CRIMSON := Color(0.64, 0.055, 0.12)
const INK := Color(0.075, 0.065, 0.065)
const GOLD := Color(0.87, 0.68, 0.39)

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Flamenco",
		"code": "FL",
		"body": Color(0.97, 0.955, 0.925),
		"belly": Color(0.86, 0.83, 0.78),
		"cheatline": [CRIMSON, GOLD],
		"engine": Color(0.55, 0.055, 0.105),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Color(0.12, 0.16, 0.18),
		"accent": CRIMSON,
	}


static func _make_tail() -> ImageTexture:
	var size: int = 512
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var hub: Vector2 = Vector2(0.47, 0.60)
	for y in size:
		for x in size:
			var p: Vector2 = Vector2((float(x) + 0.5) / float(size), (float(y) + 0.5) / float(size))
			var base: Color = CRIMSON.lerp(Color(0.47, 0.035, 0.075), 0.24 * p.y + 0.13 * p.x)
			var v: Vector2 = p - hub
			var radius: float = v.length()
			var angle: float = atan2(v.y, v.x)
			var fan: bool = false
			if angle > -2.91 and angle < -0.23:
				var outer: float = 0.485 - 0.014 * cos((angle + 2.91) * 11.0)
				fan = radius < outer
			var dress: bool = false
			if p.y >= 0.59:
				var t: float = clampf((p.y - 0.59) / 0.41, 0.0, 1.0)
				var left: float = 0.45 - 0.43 * pow(t, 1.45)
				var right: float = 0.50 + 0.48 * pow(t, 1.25)
				dress = p.x >= left and p.x <= right
			var color: Color = INK if fan or dress else base
			if fan and radius > 0.105:
				var rib_phase: float = fposmod((angle + 2.91) / 2.68 * 11.0, 1.0)
				if rib_phase < 0.018:
					color = Color(0.29, 0.12, 0.13)
			if dress and p.y > 0.67:
				var sweep_x: float = 0.47 + 0.19 * sin((p.y - 0.64) * 5.7)
				var sweep_width: float = 0.008 + 0.023 * (p.y - 0.67)
				if absf(p.x - sweep_x) < sweep_width:
					color = base
			image.set_pixel(x, y, color)
	# The small gold pivot anchors the radial fan without weakening its silhouette.
	_disc(image, Vector2(0.47, 0.60), 0.020, GOLD)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image: Image = Image.create(1024, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var word: String = "FLAMENCO"
	for index in word.length():
		var glyph: String = word.substr(index, 1)
		var origin: Vector2 = Vector2(62.0 + float(index) * 113.0, 51.0)
		for path: PackedVector2Array in _letter(glyph):
			for segment in path.size() - 1:
				var a: Vector2 = origin + Vector2(path[segment].x * 82.0, path[segment].y * 154.0)
				var b: Vector2 = origin + Vector2(path[segment + 1].x * 82.0, path[segment + 1].y * 154.0)
				_stroke(image, a, b, 18.0, CRIMSON)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _letter(glyph: String) -> Array[PackedVector2Array]:
	match glyph:
		"F":
			return [PackedVector2Array([Vector2(0.08, 1.0), Vector2(0.08, 0.0), Vector2(0.95, 0.0)]), PackedVector2Array([Vector2(0.08, 0.48), Vector2(0.78, 0.48)])]
		"L":
			return [PackedVector2Array([Vector2(0.08, 0.0), Vector2(0.08, 1.0), Vector2(0.95, 1.0)])]
		"A":
			return [PackedVector2Array([Vector2(0.04, 1.0), Vector2(0.50, 0.0), Vector2(0.96, 1.0)]), PackedVector2Array([Vector2(0.20, 0.65), Vector2(0.80, 0.65)])]
		"M":
			return [PackedVector2Array([Vector2(0.03, 1.0), Vector2(0.03, 0.0), Vector2(0.50, 0.56), Vector2(0.97, 0.0), Vector2(0.97, 1.0)])]
		"E":
			return [PackedVector2Array([Vector2(0.94, 0.0), Vector2(0.08, 0.0), Vector2(0.08, 1.0), Vector2(0.94, 1.0)]), PackedVector2Array([Vector2(0.08, 0.50), Vector2(0.78, 0.50)])]
		"N":
			return [PackedVector2Array([Vector2(0.06, 1.0), Vector2(0.06, 0.0), Vector2(0.94, 1.0), Vector2(0.94, 0.0)])]
		"C":
			return [PackedVector2Array([Vector2(0.93, 0.12), Vector2(0.77, 0.0), Vector2(0.22, 0.0), Vector2(0.07, 0.18), Vector2(0.07, 0.82), Vector2(0.22, 1.0), Vector2(0.77, 1.0), Vector2(0.93, 0.88)])]
		"O":
			return [PackedVector2Array([Vector2(0.22, 0.0), Vector2(0.78, 0.0), Vector2(0.95, 0.18), Vector2(0.95, 0.82), Vector2(0.78, 1.0), Vector2(0.22, 1.0), Vector2(0.05, 0.82), Vector2(0.05, 0.18), Vector2(0.22, 0.0)])]
	return []


static func _stroke(image: Image, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var half_width: float = width * 0.5
	var min_x: int = maxi(0, int(floor(minf(a.x, b.x) - half_width)))
	var max_x: int = mini(image.get_width() - 1, int(ceil(maxf(a.x, b.x) + half_width)))
	var min_y: int = maxi(0, int(floor(minf(a.y, b.y) - half_width)))
	var max_y: int = mini(image.get_height() - 1, int(ceil(maxf(a.y, b.y) + half_width)))
	var ab: Vector2 = b - a
	var length_sq: float = ab.length_squared()
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5)
			var t: float = clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
			if p.distance_squared_to(a + ab * t) <= half_width * half_width:
				image.set_pixel(x, y, color)


static func _disc(image: Image, centre: Vector2, radius: float, color: Color) -> void:
	var size: int = image.get_width()
	var cx: int = int(centre.x * float(size))
	var cy: int = int(centre.y * float(size))
	var r: int = int(ceil(radius * float(size)))
	for y in range(maxi(0, cy - r), mini(size, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(size, cx + r + 1)):
			var p: Vector2 = Vector2((float(x) + 0.5) / float(size), (float(y) + 0.5) / float(size))
			if p.distance_squared_to(centre) <= radius * radius:
				image.set_pixel(x, y, color)
