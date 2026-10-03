extends RefCounted
## Riviera Express / RX — Mediterranean sails, warm porcelain and coastal blue.
## Only the shared design helpers are used; no fonts or imported artwork are needed.

const SEA_BLUE: Color = Color(0.015, 0.36, 0.62)
const WORDMARK_INK: Color = Color(0.035, 0.18, 0.29)
const CLEAR: Color = Color(0.0, 0.0, 0.0, 0.0)
const TAIL_SIZE: int = 512
const TITLE_SIZE: Vector2i = Vector2i(2048, 256)
const SUPERSAMPLE: int = 2

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	var porcelain: Color = Color.WHITE.lerp(DesignKit.CREAM, 0.08)
	var cheatline: Array[Color] = [SEA_BLUE, DesignKit.LIMESTONE.lightened(0.3)]
	return {
		"name": "Riviera Express",
		"code": "RX",
		"body": porcelain,
		"belly": porcelain.lerp(DesignKit.LIMESTONE, 0.24),
		"cheatline": cheatline,
		"engine": SEA_BLUE,
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": WORDMARK_INK,
		"accent": DesignKit.OCHRE,
	}


static func _make_tail() -> ImageTexture:
	var image: Image = Image.create(TAIL_SIZE * SUPERSAMPLE, TAIL_SIZE * SUPERSAMPLE, false, Image.FORMAT_RGBA8)
	image.fill(SEA_BLUE)
	var sail_white: Color = Color.WHITE.lerp(DesignKit.CREAM, 0.04)
	# Broad sails and a generous blue mast gap retain the silhouette at apron distance.
	# Signage's shared pictogram painter uses square, normalized coordinates here.
	var shapes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(0.57, 0.08), Vector2(0.57, 0.65), Vector2(0.14, 0.65)]),
		PackedVector2Array([Vector2(0.63, 0.23), Vector2(0.89, 0.65), Vector2(0.63, 0.65)]),
		PackedVector2Array([Vector2(0.12, 0.70), Vector2(0.90, 0.70), Vector2(0.78, 0.81), Vector2(0.24, 0.81)]),
		PackedVector2Array([Vector2(0.25, 0.87), Vector2(0.78, 0.87), Vector2(0.73, 0.92), Vector2(0.20, 0.92)]),
	]
	for polygon: PackedVector2Array in shapes:
		Signage._draw_shape(image, ["poly", polygon, true], sail_white, SEA_BLUE)
	# Two wide blue cuts turn the lower sail into bold white maritime stripes.
	var size: int = image.get_width()
	for band_y: float in [0.40, 0.53]:
		image.fill_rect(Rect2i(0, roundi(band_y * float(size)), size, roundi(0.047 * float(size))), SEA_BLUE)
	image.resize(TAIL_SIZE, TAIL_SIZE, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _make_title() -> ImageTexture:
	var image: Image = Image.create(TITLE_SIZE.x * SUPERSAMPLE, TITLE_SIZE.y * SUPERSAMPLE, false, Image.FORMAT_RGBA8)
	image.fill(CLEAR)
	# Equally tall words: EXPRESS remains legible instead of becoming a tiny subtitle.
	var cursor: float = 97.0
	for word: String in ["RIVIERA", "EXPRESS"]:
		var ink: Color = WORDMARK_INK if word == "RIVIERA" else SEA_BLUE
		for index: int in range(word.length()):
			var letter: String = word.substr(index, 1)
			var width: float = 44.0 if letter == "I" else 124.0
			_draw_letter(image, letter, Vector2(cursor, 40.0), Vector2(width, 176.0), ink)
			cursor += width + 14.0
		cursor += 82.0
	image.resize(TITLE_SIZE.x, TITLE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _draw_letter(image: Image, letter: String, origin: Vector2, size: Vector2, ink: Color) -> void:
	var outline: PackedVector2Array = PackedVector2Array()
	var counter: PackedVector2Array = PackedVector2Array()
	# Hand-built block capitals: deep stems, clipped bowls, open counters, raked R legs.
	match letter:
		"R", "P":
			outline = PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.71, 0.0), Vector2(0.94, 0.14),
				Vector2(0.94, 0.45), Vector2(0.73, 0.59), Vector2(0.24, 0.59),
				Vector2(0.24, 1.0), Vector2(0.0, 1.0),
			])
			counter = PackedVector2Array([
				Vector2(0.24, 0.20), Vector2(0.63, 0.20), Vector2(0.70, 0.25),
				Vector2(0.70, 0.35), Vector2(0.63, 0.40), Vector2(0.24, 0.40),
			])
			if letter == "R":
				_letter_polygon(image, PackedVector2Array([
					Vector2(0.43, 0.52), Vector2(0.70, 0.52), Vector2(1.0, 1.0), Vector2(0.70, 1.0),
				]), origin, size, ink)
		"I":
			outline = PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)])
		"V":
			outline = PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.26, 0.0), Vector2(0.50, 0.71), Vector2(0.74, 0.0),
				Vector2(1.0, 0.0), Vector2(0.65, 1.0), Vector2(0.35, 1.0),
			])
		"E":
			outline = PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 0.20), Vector2(0.24, 0.20),
				Vector2(0.24, 0.39), Vector2(0.84, 0.39), Vector2(0.84, 0.59), Vector2(0.24, 0.59),
				Vector2(0.24, 0.80), Vector2(1.0, 0.80), Vector2(1.0, 1.0), Vector2(0.0, 1.0),
			])
		"A":
			outline = PackedVector2Array([
				Vector2(0.0, 1.0), Vector2(0.31, 0.0), Vector2(0.69, 0.0), Vector2(1.0, 1.0),
				Vector2(0.75, 1.0), Vector2(0.67, 0.73), Vector2(0.33, 0.73), Vector2(0.25, 1.0),
			])
			counter = PackedVector2Array([Vector2(0.39, 0.53), Vector2(0.50, 0.19), Vector2(0.61, 0.53)])
		"X":
			outline = PackedVector2Array([
				Vector2(0.0, 0.0), Vector2(0.29, 0.0), Vector2(0.50, 0.31), Vector2(0.71, 0.0),
				Vector2(1.0, 0.0), Vector2(0.65, 0.49), Vector2(1.0, 1.0), Vector2(0.71, 1.0),
				Vector2(0.50, 0.68), Vector2(0.29, 1.0), Vector2(0.0, 1.0), Vector2(0.35, 0.49),
			])
		"S":
			outline = PackedVector2Array([
				Vector2(0.18, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 0.20), Vector2(0.29, 0.20),
				Vector2(0.24, 0.24), Vector2(0.24, 0.36), Vector2(0.29, 0.40), Vector2(0.80, 0.40),
				Vector2(1.0, 0.55), Vector2(1.0, 0.85), Vector2(0.80, 1.0), Vector2(0.0, 1.0),
				Vector2(0.0, 0.80), Vector2(0.71, 0.80), Vector2(0.76, 0.76), Vector2(0.76, 0.65),
				Vector2(0.71, 0.61), Vector2(0.20, 0.61), Vector2(0.0, 0.46), Vector2(0.0, 0.15),
			])
	_letter_polygon(image, outline, origin, size, ink)
	if not counter.is_empty():
		_letter_polygon(image, counter, origin, size, CLEAR)


static func _letter_polygon(image: Image, polygon: PackedVector2Array, origin: Vector2, size: Vector2, ink: Color) -> void:
	var pixels: PackedVector2Array = PackedVector2Array()
	var minimum: Vector2 = Vector2(INF, INF)
	var maximum: Vector2 = Vector2(-INF, -INF)
	for point: Vector2 in polygon:
		# Slight forward inclination recalls a sail without compromising broad strokes.
		var pixel: Vector2 = (origin + point * size + Vector2((1.0 - point.y) * 14.0, 0.0)) * float(SUPERSAMPLE)
		pixels.append(pixel)
		minimum = minimum.min(pixel)
		maximum = maximum.max(pixel)
	# Bound the raster loop to the glyph rather than scanning the whole wide decal.
	for y: int in range(maxi(0, floori(minimum.y)), mini(image.get_height(), ceili(maximum.y))):
		for x: int in range(maxi(0, floori(minimum.x)), mini(image.get_width(), ceili(maximum.x))):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), pixels):
				image.set_pixel(x, y, ink)
