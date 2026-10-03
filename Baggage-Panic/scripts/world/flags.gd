class_name Flags
extends RefCounted
## Procedural national flags. Geometry is expressed in multiples of flag height.

const CODES: PackedStringArray = ["VN", "JP", "KR", "US", "GB", "FR", "DE", "IT", "IN", "AE", "SG", "AU", "TH", "NL", "SE", "CH", "CN"]
const _NAMES := {"VN": "Vietnam", "JP": "Japan", "KR": "South Korea", "US": "United States", "GB": "United Kingdom", "FR": "France", "DE": "Germany", "IT": "Italy", "IN": "India", "AE": "United Arab Emirates", "SG": "Singapore", "AU": "Australia", "TH": "Thailand", "NL": "Netherlands", "SE": "Sweden", "CH": "Switzerland", "CN": "China"}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}


static func aspect(code: String) -> float:
	match code.to_upper():
		"US": return 1.9
		"GB", "AE", "AU": return 2.0
		"DE": return 5.0 / 3.0
		"SE": return 8.0 / 5.0
		"CH": return 1.0
		_: return 1.5 if CODES.has(code.to_upper()) else 0.0


static func country_name(code: String) -> String:
	return _NAMES.get(code.to_upper(), "") as String


static func image(code: String, height: int = 120) -> Image:
	code = code.to_upper()
	if not CODES.has(code) or height < 1:
		return null
	var key := "%s:%d" % [code, height]
	if _images.has(key):
		return _images[key] as Image
	var s := 4.0 * float(height)
	var w := roundi(aspect(code) * s)
	var img := Image.create_empty(w, roundi(s), false, Image.FORMAT_RGBA8)
	_draw(img, code, s)
	img.resize(roundi(aspect(code) * float(height)), height, Image.INTERPOLATE_LANCZOS)
	_images[key] = img
	return img


static func texture(code: String, height: int = 120) -> ImageTexture:
	var key := "%s:%d" % [code.to_upper(), height]
	if _textures.has(key):
		return _textures[key] as ImageTexture
	var img := image(code, height)
	if img == null:
		return null
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


static func _rect(img: Image, x: float, y: float, w: float, h: float, c: Color) -> void:
	var x0 := maxi(0, ceili(x))
	var y0 := maxi(0, ceili(y))
	var x1 := mini(img.get_width(), ceili(x + w))
	var y1 := mini(img.get_height(), ceili(y + h))
	if x1 > x0 and y1 > y0:
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), c)


static func _disk(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(maxi(0, floori(cy - r)), mini(img.get_height(), ceili(cy + r))):
		for x in range(maxi(0, floori(cx - r)), mini(img.get_width(), ceili(cx + r))):
			var dx := float(x) + 0.5 - cx
			var dy := float(y) + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(x, y, c)


static func _polygon(img: Image, pts: PackedVector2Array, c: Color) -> void:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := 0
	var max_y := 0
	for p in pts:
		min_x = mini(min_x, floori(p.x))
		min_y = mini(min_y, floori(p.y))
		max_x = maxi(max_x, ceili(p.x))
		max_y = maxi(max_y, ceili(p.y))
	for y in range(maxi(0, min_y), mini(img.get_height(), max_y)):
		for x in range(maxi(0, min_x), mini(img.get_width(), max_x)):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), pts):
				img.set_pixel(x, y, c)


static func _star(img: Image, cx: float, cy: float, outer: float, inner: float, points: int, angle: float, c: Color) -> void:
	var poly := PackedVector2Array()
	for i in points * 2:
		var a := angle + PI * float(i) / float(points)
		var r := outer if i % 2 == 0 else inner
		poly.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	_polygon(img, poly, c)


static func _bar(img: Image, center: Vector2, along: Vector2, length: float, thick: float, c: Color) -> void:
	var a := along.normalized() * length * 0.5
	var b := Vector2(-along.y, along.x).normalized() * thick * 0.5
	_polygon(img, PackedVector2Array([center - a - b, center + a - b, center + a + b, center - a + b]), c)


static func _uk(img: Image, ox: float, oy: float, h: float) -> void:
	# Union Flag construction on a 60 by 30 grid. Red saltires are counterchanged.
	var blue := Color("012169")
	var red := Color("c8102e")
	var white := Color.WHITE
	var scale := h / 30.0
	for py in range(maxi(0, floori(oy)), mini(img.get_height(), ceili(oy + h))):
		for px in range(maxi(0, floori(ox)), mini(img.get_width(), ceili(ox + h * 2.0))):
			var x := (float(px) + 0.5 - ox) / scale
			var y := (float(py) + 0.5 - oy) / scale
			var d1 := y - x * 0.5
			var d2 := y - (30.0 - x * 0.5)
			var c := blue
			if absf(d1) < 3.0 or absf(d2) < 3.0:
				c = white
			# Offsetting the red stripe to opposite sides at the centre
			# produces the characteristic unequal white borders.
			if (d1 > 0.0 and d1 < 2.0 and x < 30.0) or (d1 < 0.0 and d1 > -2.0 and x >= 30.0):
				c = red
			if (d2 < 0.0 and d2 > -2.0 and x < 30.0) or (d2 > 0.0 and d2 < 2.0 and x >= 30.0):
				c = red
			if absf(x - 30.0) < 5.0 or absf(y - 15.0) < 5.0:
				c = white
			if absf(x - 30.0) < 3.0 or absf(y - 15.0) < 3.0:
				c = red
			img.set_pixel(px, py, c)


static func _trigram(img: Image, center: Vector2, angle: float, kind: String, s: float) -> void:
	var along := Vector2(cos(angle), sin(angle))
	var across := Vector2(-along.y, along.x)
	var bar_length := s / 4.0
	var thick := s / 48.0
	var gap := s / 24.0
	for row in 3:
		var p := center + across * (float(row - 1) * gap)
		var broken := kind == "gon" or (kind == "gam" and row != 1) or (kind == "ri" and row == 1)
		if broken:
			_bar(img, p - along * (bar_length * 0.275), along, bar_length * 0.45, thick, Color.BLACK)
			_bar(img, p + along * (bar_length * 0.275), along, bar_length * 0.45, thick, Color.BLACK)
		else:
			_bar(img, p, along, bar_length, thick, Color.BLACK)


static func _draw(img: Image, code: String, s: float) -> void:
	var w := float(img.get_width())
	var white := Color.WHITE
	match code:
		"VN":
			img.fill(Color("da251d"))
			_star(img, w * 0.5, s * 0.5, s * 0.3, s * 0.3 * 0.38196601125, 5, -PI / 2.0, Color.YELLOW)
		"JP":
			img.fill(white)
			_disk(img, w * 0.5, s * 0.5, s * 0.3, Color("bc002d"))
		"KR":
			img.fill(white)
			var r := s * 0.25
			for y in range(floori(s * 0.25), ceili(s * 0.75)):
				for x in range(floori(w * 0.5 - r), ceili(w * 0.5 + r)):
					var dx := float(x) + 0.5 - w * 0.5
					var dy := float(y) + 0.5 - s * 0.5
					if dx * dx + dy * dy > r * r:
						continue
					var u := (dx - dy) * 0.70710678118
					var v := (dx + dy) * 0.70710678118
					var is_red := v < 0.0
					if (u - r * 0.5) ** 2 + v * v < (r * 0.5) ** 2:
						is_red = true
					if (u + r * 0.5) ** 2 + v * v < (r * 0.5) ** 2:
						is_red = false
					img.set_pixel(x, y, Color("cd2e3a") if is_red else Color("0047a0"))
			_trigram(img, Vector2(w * 0.25, s * 0.25), PI / 6.0, "geon", s)
			_trigram(img, Vector2(w * 0.75, s * 0.25), -PI / 6.0, "gam", s)
			_trigram(img, Vector2(w * 0.25, s * 0.75), -PI / 6.0, "ri", s)
			_trigram(img, Vector2(w * 0.75, s * 0.75), PI / 6.0, "gon", s)
		"US":
			img.fill(white)
			for i in 13:
				if i % 2 == 0:
					_rect(img, 0.0, s * float(i) / 13.0, w, s / 13.0, Color("b31942"))
			_rect(img, 0.0, 0.0, s * 0.76, s * 7.0 / 13.0, Color("0a3161"))
			for row in 9:
				var count := 6 if row % 2 == 0 else 5
				for col in count:
					var cx := s * (0.063 + float(col) * 0.126 + (0.063 if count == 5 else 0.0))
					var cy := s * (0.05385 + float(row) * 0.05385)
					_star(img, cx, cy, s * 0.0308, s * 0.01176, 5, -PI / 2.0, white)
		"GB":
			_uk(img, 0.0, 0.0, s)
		"FR":
			img.fill(white)
			_rect(img, 0.0, 0.0, w / 3.0, s, Color("002654"))
			_rect(img, w * 2.0 / 3.0, 0.0, w / 3.0, s, Color("ce1126"))
		"DE":
			img.fill(Color("ffce00"))
			_rect(img, 0.0, 0.0, w, s / 3.0, Color.BLACK)
			_rect(img, 0.0, s / 3.0, w, s / 3.0, Color("dd0000"))
		"IT":
			img.fill(white)
			_rect(img, 0.0, 0.0, w / 3.0, s, Color("009246"))
			_rect(img, w * 2.0 / 3.0, 0.0, w / 3.0, s, Color("ce2b37"))
		"IN":
			img.fill(white)
			_rect(img, 0.0, 0.0, w, s / 3.0, Color("ff9933"))
			_rect(img, 0.0, s * 2.0 / 3.0, w, s / 3.0, Color("138808"))
			var navy := Color("000080")
			var radius := s / 8.0
			for y in range(floori(s * 0.5 - radius), ceili(s * 0.5 + radius)):
				for x in range(floori(w * 0.5 - radius), ceili(w * 0.5 + radius)):
					var d := Vector2(float(x) + 0.5 - w * 0.5, float(y) + 0.5 - s * 0.5)
					var dist := d.length()
					if absf(dist - radius) <= s / 320.0 or dist <= s / 90.0:
						img.set_pixel(x, y, navy)
					elif dist < radius:
						var theta := fposmod(atan2(d.y, d.x), TAU / 24.0)
						if minf(theta, TAU / 24.0 - theta) * dist < s / 400.0:
							img.set_pixel(x, y, navy)
		"AE":
			img.fill(white)
			_rect(img, 0.0, 0.0, w, s / 3.0, Color("00732f"))
			_rect(img, 0.0, s * 2.0 / 3.0, w, s / 3.0, Color.BLACK)
			_rect(img, 0.0, 0.0, w / 4.0, s, Color.RED)
		"SG":
			img.fill(white)
			_rect(img, 0.0, 0.0, w, s * 0.5, Color("ef3340"))
			_disk(img, w * 0.185, s * 0.25, s * 0.165, white)
			_disk(img, w * 0.235, s * 0.215, s * 0.145, Color("ef3340"))
			for i in 5:
				var a := -PI / 2.0 + float(i) * TAU / 5.0
				_star(img, w * 0.365 + cos(a) * s * 0.103, s * 0.25 + sin(a) * s * 0.103, s * 0.036, s * 0.014, 5, -PI / 2.0, white)
		"AU":
			img.fill(Color("012169"))
			_uk(img, 0.0, 0.0, s * 0.5)
			var star_inner := 4.0 / 9.0
			_star(img, s * 0.5, s * 0.75, s * 0.15, s * 0.15 * star_inner, 7, -PI / 2.0, white)
			_star(img, s * 1.5, s * 0.75, s / 14.0, s / 14.0 * star_inner, 7, -PI / 2.0, white)
			_star(img, s * 1.25, s * 5.0 / 12.0, s / 14.0, s / 14.0 * star_inner, 7, -PI / 2.0, white)
			_star(img, s * 1.5, s / 6.0, s / 14.0, s / 14.0 * star_inner, 7, -PI / 2.0, white)
			_star(img, s * 1.75, s * 5.0 / 12.0, s / 14.0, s / 14.0 * star_inner, 7, -PI / 2.0, white)
			_star(img, s * 1.625, s * 7.0 / 12.0, s / 24.0, s / 24.0 * star_inner, 5, -PI / 2.0, white)
		"TH":
			img.fill(Color("a51931"))
			_rect(img, 0.0, s / 6.0, w, s / 6.0, white)
			_rect(img, 0.0, s / 3.0, w, s / 3.0, Color("2d2a4a"))
			_rect(img, 0.0, s * 2.0 / 3.0, w, s / 6.0, white)
		"NL":
			img.fill(white)
			_rect(img, 0.0, 0.0, w, s / 3.0, Color("ae1c28"))
			_rect(img, 0.0, s * 2.0 / 3.0, w, s / 3.0, Color("21468b"))
		"SE":
			img.fill(Color("006aa7"))
			_rect(img, s * 0.5, 0.0, s * 0.2, s, Color("fecc02"))
			_rect(img, 0.0, s * 0.4, w, s * 0.2, Color("fecc02"))
		"CH":
			img.fill(Color("da291c"))
			_rect(img, s * 13.0 / 32.0, s * 6.0 / 32.0, s * 6.0 / 32.0, s * 20.0 / 32.0, white)
			_rect(img, s * 6.0 / 32.0, s * 13.0 / 32.0, s * 20.0 / 32.0, s * 6.0 / 32.0, white)
		"CN":
			img.fill(Color("ee1c25"))
			var yellow := Color.YELLOW
			var large := Vector2(s * 0.25, s * 0.25)
			_star(img, large.x, large.y, s * 0.15, s * 0.15 * 0.38196601125, 5, -PI / 2.0, yellow)
			var small_centers: Array[Vector2] = [Vector2(0.50, 0.10), Vector2(0.60, 0.20), Vector2(0.60, 0.35), Vector2(0.50, 0.45)]
			for p: Vector2 in small_centers:
				var center: Vector2 = p * s
				var angle: float = (large - center).angle()
				_star(img, center.x, center.y, s * 0.05, s * 0.05 * 0.38196601125, 5, angle, yellow)
