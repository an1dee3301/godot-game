extends RefCounted
## Sol Iberia: a ceramic sunburst and chamfered capitals, drawn without font assets.

const Design = preload("res://scripts/world/design_kit.gd")
const Wayfinding = preload("res://scripts/world/signage.gd")
const TERRACOTTA: Color = Color(0.70, 0.30, 0.19)
const SAFFRON: Color = Color(0.94, 0.64, 0.20)
const LETTER_INK: Color = Color(0.27, 0.18, 0.14)

static var _tail_texture: ImageTexture
static var _title_texture: ImageTexture


static func spec() -> Dictionary:
	if _tail_texture == null:
		_tail_texture = _make_tail()
	if _title_texture == null:
		_title_texture = _make_title()
	return {
		"name": "Sol Iberia",
		"code": "SI",
		"body": Design.CREAM,
		"belly": Design.LIMESTONE.lerp(Design.CREAM, 0.35),
		"cheatline": [TERRACOTTA, SAFFRON],
		"engine": Design.CREAM.lerp(TERRACOTTA, 0.12),
		"tail_texture": _tail_texture,
		"title_texture": _title_texture,
		"window_color": Design.CHARCOAL,
		"accent": TERRACOTTA,
	}


static func _make_tail() -> ImageTexture:
	# The emblem occupies 92% of the fin artwork; broad rays survive distant mip levels.
	var canvas: Image = Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	canvas.fill(Design.CREAM)
	var center: Vector2 = Vector2(0.5, 0.5)
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0 - PI * 0.5
		var ray: PackedVector2Array = PackedVector2Array()
		# Clipped shoulders give the sun rays the finish of an inlaid ceramic tile.
		for corner: Vector2 in [
			Vector2(-0.165, 0.215), Vector2(-0.205, 0.423),
			Vector2(-0.157, 0.462), Vector2(0.157, 0.462),
			Vector2(0.205, 0.423), Vector2(0.165, 0.215),
		]:
			var direction: float = angle + corner.x
			ray.append(center + Vector2(cos(direction), sin(direction)) * corner.y)
		var ink: Color = TERRACOTTA if index % 2 == 0 else SAFFRON
		Wayfinding._draw_shape(canvas, ["poly", ray, true], ink, Design.CREAM)
	# A substantial central disc and a cream breathing ring keep the silhouette clear.
	Wayfinding._draw_shape(canvas, ["circle", center, 0.177, true], TERRACOTTA, Design.CREAM)
	Wayfinding._draw_shape(canvas, ["circle", center + Vector2(-0.014, -0.018), 0.126, true], SAFFRON, Design.CREAM)
	canvas.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	canvas.generate_mipmaps()
	return ImageTexture.create_from_image(canvas)


static func _make_title() -> ImageTexture:
	# Supersampling softens the polygon edges without thinning the heavy letter strokes.
	var canvas: Image = Image.create(3072, 512, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(LETTER_INK.r, LETTER_INK.g, LETTER_INK.b, 0.0))
	var widths: Dictionary = {"S": 74.0, "O": 74.0, "L": 66.0, "I": 44.0, "B": 74.0, "E": 66.0, "R": 78.0, "A": 84.0}
	var caption: String = "SOL IBERIA"
	var width: float = -14.0
	for index: int in range(caption.length()):
		var letter: String = caption.substr(index, 1)
		width += 28.0 if letter == " " else float(widths[letter]) + 14.0
	var scale: float = minf(2944.0 / width, 448.0 / 110.0)
	var pen: Vector2 = Vector2((3072.0 - width * scale) * 0.5, (512.0 - 110.0 * scale) * 0.5)
	for index: int in range(caption.length()):
		var letter: String = caption.substr(index, 1)
		if letter == " ":
			pen.x += 28.0 * scale
			continue
		var ink: Color = TERRACOTTA.darkened(0.18) if index < 3 else LETTER_INK
		var shapes: Array[PackedVector2Array] = _letter_shapes(letter)
		for shape_index: int in range(shapes.size()):
			var color: Color = ink if shape_index == 0 else Color(ink.r, ink.g, ink.b, 0.0)
			_paint_polygon(canvas, shapes[shape_index], pen, scale, color)
		pen.x += (float(widths[letter]) + 14.0) * scale
	canvas.resize(1536, 256, Image.INTERPOLATE_LANCZOS)
	canvas.generate_mipmaps()
	return ImageTexture.create_from_image(canvas)


## Each first polygon is a letter silhouette; subsequent polygons cut open counters.
## The shared 21–23 unit stems and generous apertures are legible across the apron.
static func _letter_shapes(letter: String) -> Array[PackedVector2Array]:
	match letter:
		"S":
			return [PackedVector2Array([
				Vector2(16, 0), Vector2(74, 0), Vector2(74, 22), Vector2(28, 22),
				Vector2(22, 28), Vector2(22, 38), Vector2(28, 44), Vector2(58, 44),
				Vector2(74, 60), Vector2(74, 94), Vector2(58, 110), Vector2(0, 110),
				Vector2(0, 88), Vector2(46, 88), Vector2(52, 82), Vector2(52, 72),
				Vector2(46, 66), Vector2(16, 66), Vector2(0, 50), Vector2(0, 16),
			])]
		"O":
			return [
				PackedVector2Array([Vector2(16, 0), Vector2(58, 0), Vector2(74, 16), Vector2(74, 94), Vector2(58, 110), Vector2(16, 110), Vector2(0, 94), Vector2(0, 16)]),
				PackedVector2Array([Vector2(28, 22), Vector2(46, 22), Vector2(52, 28), Vector2(52, 82), Vector2(46, 88), Vector2(28, 88), Vector2(22, 82), Vector2(22, 28)]),
			]
		"L":
			return [PackedVector2Array([Vector2(0, 0), Vector2(22, 0), Vector2(22, 88), Vector2(66, 88), Vector2(66, 102), Vector2(58, 110), Vector2(0, 110)])]
		"I":
			return [PackedVector2Array([
				Vector2(0, 0), Vector2(44, 0), Vector2(44, 20), Vector2(33, 20),
				Vector2(33, 90), Vector2(44, 90), Vector2(44, 110), Vector2(0, 110),
				Vector2(0, 90), Vector2(11, 90), Vector2(11, 20), Vector2(0, 20),
			])]
		"B":
			return [
				PackedVector2Array([Vector2(0, 0), Vector2(56, 0), Vector2(74, 18), Vector2(74, 43), Vector2(63, 54), Vector2(74, 65), Vector2(74, 92), Vector2(56, 110), Vector2(0, 110)]),
				PackedVector2Array([Vector2(22, 21), Vector2(46, 21), Vector2(52, 27), Vector2(52, 38), Vector2(46, 44), Vector2(22, 44)]),
				PackedVector2Array([Vector2(22, 66), Vector2(46, 66), Vector2(52, 72), Vector2(52, 83), Vector2(46, 89), Vector2(22, 89)]),
			]
		"E":
			return [PackedVector2Array([
				Vector2(0, 0), Vector2(66, 0), Vector2(66, 22), Vector2(22, 22),
				Vector2(22, 44), Vector2(57, 44), Vector2(57, 66), Vector2(22, 66),
				Vector2(22, 88), Vector2(66, 88), Vector2(66, 110), Vector2(0, 110),
			])]
		"R":
			return [
				PackedVector2Array([Vector2(0, 0), Vector2(54, 0), Vector2(74, 18), Vector2(74, 50), Vector2(58, 66), Vector2(78, 110), Vector2(52, 110), Vector2(33, 68), Vector2(22, 68), Vector2(22, 110), Vector2(0, 110)]),
				PackedVector2Array([Vector2(22, 22), Vector2(46, 22), Vector2(52, 28), Vector2(52, 40), Vector2(46, 46), Vector2(22, 46)]),
			]
		"A":
			return [
				PackedVector2Array([Vector2(0, 110), Vector2(28, 0), Vector2(56, 0), Vector2(84, 110), Vector2(61, 110), Vector2(55, 86), Vector2(29, 86), Vector2(23, 110)]),
				PackedVector2Array([Vector2(34, 64), Vector2(50, 64), Vector2(42, 30)]),
			]
	return []


static func _paint_polygon(canvas: Image, outline: PackedVector2Array, origin: Vector2, scale: float, ink: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var bounds: Rect2 = Rect2(origin + outline[0] * scale, Vector2.ZERO)
	for point: Vector2 in outline:
		var mapped: Vector2 = origin + point * scale
		points.append(mapped)
		bounds = bounds.expand(mapped)
	var left: int = maxi(0, floori(bounds.position.x))
	var right: int = mini(canvas.get_width(), ceili(bounds.end.x))
	var top: int = maxi(0, floori(bounds.position.y))
	var bottom: int = mini(canvas.get_height(), ceili(bounds.end.y))
	for y: int in range(top, bottom):
		for x: int in range(left, right):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				canvas.set_pixel(x, y, ink)
