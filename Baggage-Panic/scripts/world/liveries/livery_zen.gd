extends RefCounted
## Zen Air / ZN — white porcelain paint, raw linen and one uninterrupted sumi gesture.
## No scene nodes or fonts: the wordmark is built entirely from bespoke polygons.

const _KIT: GDScript = preload("res://scripts/world/design_kit.gd")
const _SIGNAGE: GDScript = preload("res://scripts/world/signage.gd")
const _TAIL_SIZE: int = 512
const _TITLE_SIZE: Vector2i = Vector2i(1280, 256)

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	var stripes: Array[Color] = []
	return {
		"name": "Zen Air",
		"code": "ZN",
		"body": Color.WHITE,
		"belly": Color.WHITE,
		"cheatline": stripes,
		"engine": Color.WHITE,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": _KIT.CHARCOAL.darkened(0.25),
		"accent": _KIT.LINEN,
	}


static func _make_tail() -> ImageTexture:
	# Work at twice the final resolution, then filter the brush silhouette once.
	var size: int = _TAIL_SIZE * 2
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var linen: Color = _KIT.LINEN.lightened(0.09)
	var ink: Color = _KIT.CHARCOAL.darkened(0.60)
	image.fill(linen)
	var outline: PackedVector2Array = _enso_outline()
	# Reuse the shared signage polygon rasterizer; square UVs preserve the circle.
	_SIGNAGE._draw_shape(image, ["poly", outline, true], ink, linen)
	for y: int in size:
		for x: int in size:
			var u: float = (float(x) + 0.5) / float(size)
			var v: float = (float(y) + 0.5) / float(size)
			var warp: float = sin(float(x) * PI * 0.25 + sin(v * 39.0) * 0.18)
			var weft: float = sin(float(y) * PI * 0.25 + sin(u * 27.0) * 0.22)
			var tooth: float = sin(float(x * 47 + y * 71))
			var slub: float = sin(u * 79.0 + sin(v * 11.0)) * sin(v * 57.0)
			var weave: float = warp * 0.009 + weft * 0.007 + tooth * 0.003 + slub * 0.004
			var cloth: Color = Color(linen.r + weave, linen.g + weave, linen.b + weave)
			var current: Color = image.get_pixel(x, y)
			if current.r < 0.2:
				var offset: Vector2 = Vector2(u, v) - Vector2(0.495, 0.5)
				var angle: float = fposmod(offset.angle() - deg_to_rad(24.0), TAU)
				var progress: float = clampf(angle / deg_to_rad(324.0), 0.0, 1.0)
				var radial: float = offset.length()
				# Long bristle tracks follow the gesture; the last quarter runs dry.
				var bristle: float = sin(radial * 1950.0 + sin(angle * 9.0) * 1.8)
				var dry: float = smoothstep(0.66, 1.0, progress)
				var track: float = smoothstep(0.50, 0.98, bristle) * dry * 0.56
				var pigment: Color = ink.lerp(cloth, 0.035 + track + (tooth + 1.0) * 0.015)
				image.set_pixel(x, y, pigment)
			else:
				image.set_pixel(x, y, cloth)
	image.resize(_TAIL_SIZE, _TAIL_SIZE, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _enso_outline() -> PackedVector2Array:
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var steps: int = 180
	for step: int in steps + 1:
		var t: float = float(step) / float(steps)
		var angle: float = deg_to_rad(24.0 + 324.0 * t)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var radius: float = 0.333 + 0.008 * sin(angle * 3.0) + 0.005 * sin(angle * 7.0)
		var pressure: float = 0.057 + 0.023 * sin(angle - 0.35) + 0.006 * sin(angle * 3.0)
		pressure *= lerpf(0.72, 1.0, smoothstep(0.0, 0.055, t))
		pressure *= lerpf(1.0, 0.37, smoothstep(0.88, 1.0, t))
		var fringe: float = 0.0018 * sin(angle * 83.0) + 0.0012 * sin(angle * 137.0)
		var center: Vector2 = Vector2(0.495, 0.5)
		outer.append(center + direction * (radius + pressure + fringe))
		inner.append(center + direction * (radius - pressure + fringe * 0.6))
	# A single open-ring polygon leaves a generous, deliberate gap on the right.
	inner.reverse()
	outer.append_array(inner)
	return outer


static func _make_title() -> ImageTexture:
	var image: Image = Image.create(_TITLE_SIZE.x * 2, _TITLE_SIZE.y * 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var ink: Color = _KIT.CHARCOAL.darkened(0.25)
	# Coordinates are in a 100-unit cap height. Thick strokes and open counters
	# survive distance filtering; the chamfered shoulders soften the block forms.
	_glyph(image, "Z", Rect2(66, 32, 160, 192), ink)
	_glyph(image, "E", Rect2(266, 32, 148, 192), ink)
	_glyph(image, "N", Rect2(454, 32, 164, 192), ink)
	_glyph(image, "A", Rect2(726, 32, 172, 192), ink)
	_glyph(image, "I", Rect2(950, 32, 40, 192), ink)
	_glyph(image, "R", Rect2(1030, 32, 184, 192), ink)
	image.resize(_TITLE_SIZE.x, _TITLE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _glyph(image: Image, letter: String, box: Rect2, ink: Color) -> void:
	var outline: PackedVector2Array = PackedVector2Array()
	var counter: PackedVector2Array = PackedVector2Array()
	match letter:
		"Z":
			outline = PackedVector2Array([Vector2(3, 0), Vector2(97, 0), Vector2(100, 3), Vector2(100, 19), Vector2(32, 79), Vector2(100, 79), Vector2(100, 100), Vector2(0, 100), Vector2(0, 81), Vector2(68, 21), Vector2(0, 21), Vector2(0, 3)])
		"E":
			outline = PackedVector2Array([Vector2(3, 0), Vector2(100, 0), Vector2(100, 21), Vector2(25, 21), Vector2(25, 39), Vector2(87, 39), Vector2(87, 60), Vector2(25, 60), Vector2(25, 79), Vector2(100, 79), Vector2(100, 100), Vector2(3, 100), Vector2(0, 97), Vector2(0, 3)])
		"N":
			outline = PackedVector2Array([Vector2(0, 100), Vector2(0, 0), Vector2(25, 0), Vector2(76, 62), Vector2(76, 0), Vector2(100, 0), Vector2(100, 100), Vector2(75, 100), Vector2(24, 38), Vector2(24, 100)])
		"A":
			outline = PackedVector2Array([Vector2(0, 100), Vector2(35, 3), Vector2(39, 0), Vector2(61, 0), Vector2(65, 3), Vector2(100, 100), Vector2(74, 100), Vector2(65, 75), Vector2(35, 75), Vector2(26, 100)])
			counter = PackedVector2Array([Vector2(40, 55), Vector2(50, 26), Vector2(60, 55)])
		"I":
			outline = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
		"R":
			outline = PackedVector2Array([Vector2(0, 100), Vector2(0, 0), Vector2(69, 0), Vector2(87, 7), Vector2(96, 19), Vector2(96, 43), Vector2(88, 55), Vector2(72, 62), Vector2(100, 100), Vector2(71, 100), Vector2(45, 65), Vector2(23, 65), Vector2(23, 100)])
			counter = PackedVector2Array([Vector2(23, 21), Vector2(62, 21), Vector2(72, 26), Vector2(72, 39), Vector2(62, 44), Vector2(23, 44)])
		_:
			return
	_polygon(image, outline, box, ink)
	if not counter.is_empty():
		_polygon(image, counter, box, Color.TRANSPARENT)


static func _polygon(image: Image, points: PackedVector2Array, box: Rect2, color: Color) -> void:
	# Unlike square signage icons, a wordmark needs independent width/height scales.
	var pixels: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		pixels.append((box.position + point * box.size / 100.0) * 2.0)
	var left: int = maxi(0, floori(box.position.x * 2.0))
	var top: int = maxi(0, floori(box.position.y * 2.0))
	var right: int = mini(image.get_width(), ceili(box.end.x * 2.0))
	var bottom: int = mini(image.get_height(), ceili(box.end.y * 2.0))
	for y: int in range(top, bottom):
		for x: int in range(left, right):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), pixels):
				image.set_pixel(x, y, color)
