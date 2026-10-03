extends RefCounted
## Saigon Wings: lacquer red, warm white enamel, and a brass-gold nón lá.
## Texture-only livery; no scene nodes, external artwork, or system-font wordmark.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

const RED: Color = Color("a12c32")
const INK: Color = Color("81242b")
const CLEAR: Color = Color(0.0, 0.0, 0.0, 0.0)
const TAIL_SIZE: int = 512
const TITLE_SIZE: Vector2i = Vector2i(1536, 256)
const SUPERSAMPLE: int = 2

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	var stripes: Array[Color] = [RED, _gold()]
	return {
		"name": "Saigon Wings",
		"code": "SW",
		"body": Kit.CREAM.lerp(Color.WHITE, 0.93),
		"belly": Kit.LIMESTONE.lerp(Color.WHITE, 0.70),
		"cheatline": stripes,
		"engine": RED,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Kit.CHARCOAL.lerp(Kit.INDIGO, 0.25),
		"accent": _gold(),
	}


static func _gold() -> Color:
	# Match the terminal's brass, warmed toward its washi/cream palette.
	return Kit.brass().albedo_color.lerp(Kit.CREAM, 0.27)


static func _make_tail() -> ImageTexture:
	var canvas: Image = Image.create(TAIL_SIZE * SUPERSAMPLE, TAIL_SIZE * SUPERSAMPLE, false, Image.FORMAT_RGBA8)
	canvas.fill(RED)
	var gold: Color = _gold()
	var light_gold: Color = gold.lerp(Kit.CREAM, 0.42)
	var dark_gold: Color = gold.darkened(0.19)
	# A broad, open chin ribbon makes the silhouette a hat, even at small mip levels.
	var ribbon: PackedVector2Array = PackedVector2Array()
	for step: int in range(25):
		var t: float = float(step) / 24.0
		ribbon.append(_quadratic(Vector2(191, 356), Vector2(231, 507), Vector2(371, 405), t))
	for step: int in range(24, -1, -1):
		var t: float = float(step) / 24.0
		ribbon.append(_quadratic(Vector2(211, 353), Vector2(243, 470), Vector2(362, 394), t))
	_polygon(canvas, ribbon, gold)
	# Elliptical underside, followed by the sloped crown and its curved front rim.
	_polygon(canvas, _ellipse(Vector2(256, 338), Vector2(207, 46)), dark_gold)
	var crown: PackedVector2Array = PackedVector2Array([
		Vector2(49, 336), Vector2(247, 109), Vector2(253, 105),
		Vector2(259, 105), Vector2(265, 109), Vector2(463, 336),
	])
	for step: int in range(1, 33):
		var angle: float = PI * float(step) / 32.0
		crown.append(Vector2(256 + 207 * cos(angle), 336 + 34 * sin(angle)))
	_polygon(canvas, crown, gold)
	# Two quiet facets recall woven palm leaves without fragmenting the main mark.
	_polygon(canvas, PackedVector2Array([
		Vector2(253, 108), Vector2(78, 326), Vector2(177, 348), Vector2(250, 128),
	]), light_gold)
	_polygon(canvas, PackedVector2Array([
		Vector2(262, 112), Vector2(443, 327), Vector2(344, 350), Vector2(263, 130),
	]), gold.darkened(0.07))
	# Wide bamboo binding: a continuous bright curved edge, readable from the apron.
	var rim: PackedVector2Array = PackedVector2Array()
	for step: int in range(33):
		var angle: float = PI * float(step) / 32.0
		rim.append(Vector2(256 + 207 * cos(angle), 335 + 36 * sin(angle)))
	for step: int in range(32, -1, -1):
		var angle: float = PI * float(step) / 32.0
		rim.append(Vector2(256 + 201 * cos(angle), 335 + 23 * sin(angle)))
	_polygon(canvas, rim, light_gold)
	return _finish(canvas, Vector2i(TAIL_SIZE, TAIL_SIZE))


static func _make_title() -> ImageTexture:
	var canvas: Image = Image.create(TITLE_SIZE.x * SUPERSAMPLE, TITLE_SIZE.y * SUPERSAMPLE, false, Image.FORMAT_RGBA8)
	canvas.fill(CLEAR)
	# Bespoke chamfered block capitals; large counters remain open after mipmapping.
	var caption: String = "SAIGON WINGS"
	var total_width: float = 0.0
	for index: int in range(caption.length()):
		var letter: String = caption.substr(index, 1)
		total_width += _advance(letter)
	total_width -= 18.0
	var x: float = (float(TITLE_SIZE.x) - total_width) * 0.5
	for index: int in range(caption.length()):
		var letter: String = caption.substr(index, 1)
		if letter != " ":
			_draw_letter(canvas, letter, Vector2(x, 30), Vector2(_advance(letter) - 18.0, 196), INK)
		x += _advance(letter)
	return _finish(canvas, TITLE_SIZE)


static func _advance(letter: String) -> float:
	match letter:
		" ":
			return 58.0
		"I":
			return 74.0
		"W":
			return 168.0
	return 132.0


static func _draw_letter(canvas: Image, letter: String, origin: Vector2, size: Vector2, ink: Color) -> void:
	# All outlines are authored here, in a unit em; no font rasterization or text API.
	var outlines: Array[PackedVector2Array] = []
	var cuts: Array[PackedVector2Array] = []
	match letter:
		"S":
			outlines.append(PackedVector2Array([
				Vector2(0.17, 0), Vector2(1, 0), Vector2(1, 0.21), Vector2(0.27, 0.21),
				Vector2(0.27, 0.39), Vector2(0.83, 0.39), Vector2(1, 0.53), Vector2(1, 0.86),
				Vector2(0.83, 1), Vector2(0, 1), Vector2(0, 0.79), Vector2(0.73, 0.79),
				Vector2(0.73, 0.60), Vector2(0.17, 0.60), Vector2(0, 0.46), Vector2(0, 0.14),
			]))
		"A":
			outlines.append(PackedVector2Array([Vector2(0, 1), Vector2(0.30, 0), Vector2(0.70, 0), Vector2(1, 1)]))
			cuts.append(PackedVector2Array([Vector2(0.40, 0.48), Vector2(0.47, 0.23), Vector2(0.53, 0.23), Vector2(0.60, 0.48)]))
			cuts.append(PackedVector2Array([Vector2(0.25, 1), Vector2(0.34, 0.70), Vector2(0.66, 0.70), Vector2(0.75, 1)]))
		"I":
			outlines.append(_rect(0, 0, 1, 0.20))
			outlines.append(_rect(0.22, 0, 0.56, 1))
			outlines.append(_rect(0, 0.80, 1, 0.20))
		"G":
			outlines.append(PackedVector2Array([
				Vector2(0.18, 0), Vector2(0.84, 0), Vector2(1, 0.14), Vector2(1, 0.28),
				Vector2(0.74, 0.28), Vector2(0.74, 0.21), Vector2(0.27, 0.21),
				Vector2(0.27, 0.79), Vector2(0.74, 0.79), Vector2(0.74, 0.62),
				Vector2(0.51, 0.62), Vector2(0.51, 0.43), Vector2(1, 0.43),
				Vector2(1, 0.86), Vector2(0.83, 1), Vector2(0.18, 1), Vector2(0, 0.85), Vector2(0, 0.15),
			]))
		"O":
			outlines.append(PackedVector2Array([
				Vector2(0.18, 0), Vector2(0.82, 0), Vector2(1, 0.15), Vector2(1, 0.85),
				Vector2(0.82, 1), Vector2(0.18, 1), Vector2(0, 0.85), Vector2(0, 0.15),
			]))
			cuts.append(PackedVector2Array([
				Vector2(0.31, 0.21), Vector2(0.69, 0.21), Vector2(0.73, 0.25), Vector2(0.73, 0.75),
				Vector2(0.69, 0.79), Vector2(0.31, 0.79), Vector2(0.27, 0.75), Vector2(0.27, 0.25),
			]))
		"N":
			outlines.append(_rect(0, 0, 0.26, 1))
			outlines.append(_rect(0.74, 0, 0.26, 1))
			outlines.append(PackedVector2Array([Vector2(0.11, 0), Vector2(0.38, 0), Vector2(0.89, 1), Vector2(0.62, 1)]))
		"W":
			outlines.append(PackedVector2Array([
				Vector2(0, 0), Vector2(0.23, 0), Vector2(0.32, 0.68), Vector2(0.41, 0.28),
				Vector2(0.59, 0.28), Vector2(0.68, 0.68), Vector2(0.77, 0), Vector2(1, 0),
				Vector2(0.84, 1), Vector2(0.61, 1), Vector2(0.50, 0.61), Vector2(0.39, 1), Vector2(0.16, 1),
			]))
	# Render each glyph separately so its transparent counters replace its own ink.
	var glyph: Image = Image.create(ceili(size.x * SUPERSAMPLE), ceili(size.y * SUPERSAMPLE), false, Image.FORMAT_RGBA8)
	glyph.fill(CLEAR)
	for outline: PackedVector2Array in outlines:
		_polygon(glyph, _transform(outline, size), ink)
	for cut: PackedVector2Array in cuts:
		_polygon(glyph, _transform(cut, size), CLEAR, true)
	canvas.blend_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), Vector2i(origin * SUPERSAMPLE))


static func _rect(x: float, y: float, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + width, y), Vector2(x + width, y + height), Vector2(x, y + height)])


static func _transform(points: PackedVector2Array, size: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(point * size)
	return result


static func _quadratic(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	return start.lerp(control, t).lerp(control.lerp(end, t), t)


static func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(64):
		var angle: float = TAU * float(step) / 64.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func _polygon(canvas: Image, points: PackedVector2Array, ink: Color, erase: bool = false) -> void:
	# Reuse Signage's shape rasterizer on a cropped patch, avoiding full-canvas scans.
	# Its coordinates use image WIDTH for both axes, including rectangular patches.
	var bounds: Rect2 = Rect2(points[0] * SUPERSAMPLE, Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point * SUPERSAMPLE)
	var top_left: Vector2i = Vector2i(floori(bounds.position.x), floori(bounds.position.y))
	var bottom_right: Vector2i = Vector2i(ceili(bounds.end.x), ceili(bounds.end.y))
	var area: Rect2i = Rect2i(top_left, bottom_right - top_left).intersection(Rect2i(Vector2i.ZERO, canvas.get_size()))
	if not area.has_area():
		return
	var patch: Image = canvas.get_region(area) if erase else Image.create(area.size.x, area.size.y, false, Image.FORMAT_RGBA8)
	if not erase:
		patch.fill(CLEAR)
	var normalized: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		normalized.append((point * SUPERSAMPLE - Vector2(area.position)) / float(area.size.x))
	Signs._draw_shape(patch, ["poly", normalized, true], ink, CLEAR)
	if erase:
		canvas.blit_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), area.position)
	else:
		canvas.blend_rect(patch, Rect2i(Vector2i.ZERO, patch.get_size()), area.position)


static func _finish(canvas: Image, size: Vector2i) -> ImageTexture:
	canvas.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	canvas.generate_mipmaps()
	return ImageTexture.create_from_image(canvas)
