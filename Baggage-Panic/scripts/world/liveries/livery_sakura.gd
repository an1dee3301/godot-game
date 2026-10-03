extends RefCounted
## Sakura Air / SK. A notched blossom crest and bespoke, chamfered block capitals.
## This data-only module adds no nodes, meshes, font dependencies, or external artwork.

const Kit: GDScript = preload("res://scripts/world/design_kit.gd")
const Signs: GDScript = preload("res://scripts/world/signage.gd")

const PLUM: Color = Color(0.205, 0.115, 0.185)
const BLUSH: Color = Color(0.94, 0.76, 0.80)
const WHITE: Color = Color(0.99, 0.985, 0.975)
const CLEAR: Color = Color(0.0, 0.0, 0.0, 0.0)
const TAIL_SIZE: int = 512
const TITLE_SIZE: Vector2i = Vector2i(1280, 256)

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	var stripes: Array[Color] = [BLUSH, Kit.CHARCOAL]
	return {
		"name": "Sakura Air",
		"code": "SK",
		"body": WHITE,
		"belly": Color(0.87, 0.83, 0.84),
		"cheatline": stripes,
		"engine": BLUSH.lightened(0.28),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Kit.CHARCOAL,
		"accent": PLUM,
	}


static func _make_tail() -> ImageTexture:
	# Supersampling rounds the petal edges; mipmaps preserve the crest at apron distances.
	var canvas: Image = Image.create(TAIL_SIZE * 2, TAIL_SIZE * 2, false, Image.FORMAT_RGBA8)
	canvas.fill(PLUM)
	var center: Vector2 = Vector2(0.5, 0.51)
	var petal: PackedVector2Array = _petal_outline()
	for index: int in range(5):
		var angle: float = float(index) * TAU / 5.0
		var outline: PackedVector2Array = PackedVector2Array()
		for point: Vector2 in petal:
			outline.append(center + point.rotated(angle))
		# Reuse the same normalized polygon painter as the international wayfinding icons.
		Signs._draw_shape(canvas, ["poly", outline, true], BLUSH, PLUM)
	# A single warm ivory heart; the gaps between the five petals stay broad and dark.
	Signs._draw_shape(canvas, ["circle", center, 0.092, true], BLUSH, PLUM)
	Signs._draw_shape(canvas, ["circle", center, 0.038, true], Kit.CREAM, PLUM)
	canvas.resize(TAIL_SIZE, TAIL_SIZE, Image.INTERPOLATE_LANCZOS)
	canvas.generate_mipmaps()
	return ImageTexture.create_from_image(canvas)


static func _petal_outline() -> PackedVector2Array:
	# One upright petal: curved shoulders and a deep V cleft distinguish sakura from a star.
	var outline: PackedVector2Array = PackedVector2Array([Vector2(0.0, -0.060)])
	_append_curve(outline, Vector2(0.0, -0.060), Vector2(-0.105, -0.120),
		Vector2(-0.175, -0.243), Vector2(-0.130, -0.344))
	_append_curve(outline, Vector2(-0.130, -0.344), Vector2(-0.110, -0.390),
		Vector2(-0.073, -0.416), Vector2(-0.039, -0.422))
	outline.append(Vector2(0.0, -0.365))
	outline.append(Vector2(0.039, -0.422))
	_append_curve(outline, Vector2(0.039, -0.422), Vector2(0.073, -0.416),
		Vector2(0.110, -0.390), Vector2(0.130, -0.344))
	_append_curve(outline, Vector2(0.130, -0.344), Vector2(0.175, -0.243),
		Vector2(0.105, -0.120), Vector2(0.0, -0.060))
	return outline


static func _append_curve(points: PackedVector2Array, start: Vector2, control_a: Vector2,
		control_b: Vector2, finish: Vector2) -> void:
	for step: int in range(1, 13):
		var t: float = float(step) / 12.0
		var u: float = 1.0 - t
		points.append(u * u * u * start + 3.0 * u * u * t * control_a
			+ 3.0 * u * t * t * control_b + t * t * t * finish)


static func _make_title() -> ImageTexture:
	var canvas: Image = Image.create(TITLE_SIZE.x, TITLE_SIZE.y, false, Image.FORMAT_RGBA8)
	canvas.fill(CLEAR)
	var caption: String = "SAKURA AIR"
	var pen_x: int = 68
	var ink: Color = Kit.CHARCOAL
	for index: int in range(caption.length()):
		var letter: String = caption.substr(index, 1)
		if letter == " ":
			pen_x += 40
			ink = PLUM
			continue
		var width: int = 32 if letter == "I" else 116
		var tile: Image = Image.create(384, 384, false, Image.FORMAT_RGBA8)
		tile.fill(CLEAR)
		var outline: PackedVector2Array = _letter_outline(letter)
		Signs._draw_shape(tile, ["poly", outline, true], ink, CLEAR)
		var counter: PackedVector2Array = _letter_counter(letter)
		if not counter.is_empty():
			Signs._draw_shape(tile, ["poly", counter, false], ink, CLEAR)
		# The final cap height is 184 px; even the thinnest stem is about 30 px wide.
		tile.resize(width, 184, Image.INTERPOLATE_LANCZOS)
		canvas.blit_rect(tile, Rect2i(0, 0, width, 184), Vector2i(pen_x, 36))
		pen_x += width + 18
	canvas.generate_mipmaps()
	return ImageTexture.create_from_image(canvas)


static func _letter_outline(letter: String) -> PackedVector2Array:
	# Original letter outlines, constructed only from straight-edged polygons.
	# Chamfered bowls echo the softened terminal fittings without sacrificing heavy strokes.
	match letter:
		"S":
			return PackedVector2Array([
				Vector2(0.14, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 0.20),
				Vector2(0.26, 0.20), Vector2(0.26, 0.40), Vector2(0.84, 0.40),
				Vector2(1.0, 0.52), Vector2(1.0, 0.86), Vector2(0.86, 1.0),
				Vector2(0.0, 1.0), Vector2(0.0, 0.80), Vector2(0.74, 0.80),
				Vector2(0.74, 0.60), Vector2(0.16, 0.60), Vector2(0.0, 0.48),
				Vector2(0.0, 0.14),
			])
		"A":
			return PackedVector2Array([
				Vector2(0.28, 0.0), Vector2(0.72, 0.0), Vector2(1.0, 1.0),
				Vector2(0.72, 1.0), Vector2(0.65, 0.76), Vector2(0.35, 0.76),
				Vector2(0.28, 1.0), Vector2(0.0, 1.0),
			])
		"K":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.27, 0.0), Vector2(0.27, 0.39),
				Vector2(0.70, 0.0), Vector2(1.0, 0.0), Vector2(0.52, 0.48),
				Vector2(1.0, 1.0), Vector2(0.68, 1.0), Vector2(0.27, 0.58),
				Vector2(0.27, 1.0), Vector2(0.0, 1.0),
			])
		"U":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.27, 0.0), Vector2(0.27, 0.74),
				Vector2(0.34, 0.81), Vector2(0.66, 0.81), Vector2(0.73, 0.74),
				Vector2(0.73, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 0.83),
				Vector2(0.83, 1.0), Vector2(0.17, 1.0), Vector2(0.0, 0.83),
			])
		"R":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.82, 0.0), Vector2(1.0, 0.16),
				Vector2(1.0, 0.45), Vector2(0.80, 0.63), Vector2(1.0, 1.0),
				Vector2(0.69, 1.0), Vector2(0.48, 0.65), Vector2(0.27, 0.65),
				Vector2(0.27, 1.0), Vector2(0.0, 1.0),
			])
		"I":
			return PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0),
			])
	return PackedVector2Array()


static func _letter_counter(letter: String) -> PackedVector2Array:
	match letter:
		"A":
			return PackedVector2Array([
				Vector2(0.41, 0.56), Vector2(0.5, 0.22), Vector2(0.59, 0.56),
			])
		"R":
			return PackedVector2Array([
				Vector2(0.27, 0.20), Vector2(0.68, 0.20), Vector2(0.74, 0.26),
				Vector2(0.74, 0.40), Vector2(0.68, 0.46), Vector2(0.27, 0.46),
			])
	return PackedVector2Array()
