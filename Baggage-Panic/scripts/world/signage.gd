class_name Signage
extends RefCounted
## International wayfinding: charcoal sign bodies with a backlit pictogram tile, English headline and
## Japanese, Chinese, Vietnamese, French and Spanish lines underneath.

## key -> [English, 日本語, 中文, Tiếng Việt, Français, Español, pictogram]
const TEXT := {
	"gate": ["Gate", "搭乗口", "登机口", "Cửa", "Porte", "Puerta", "plane"],
	"gates": ["Gates", "搭乗口", "登机口", "Cửa ra máy bay", "Portes", "Puertas", "plane"],
	"baggage_claim": ["Baggage Claim", "手荷物受取所", "行李提取", "Nhận hành lý", "Retrait des bagages", "Recogida de equipajes", "suitcase"],
	"departures": ["Departures", "出発", "出发", "Khởi hành", "Départs", "Salidas", "plane"],
	"arrivals": ["Arrivals", "到着", "到达", "Đến", "Arrivées", "Llegadas", "plane"],
	"toilets": ["Toilets", "お手洗い", "洗手间", "Nhà vệ sinh", "Toilettes", "Aseos", "wc"],
	"exit": ["Way Out", "出口", "出口", "Lối ra", "Sortie", "Salida", "exit"],
	"passports": ["Passport Control", "出入国審査", "边防检查", "Kiểm soát hộ chiếu", "Contrôle des passeports", "Control de pasaportes", "passport"],
	"security": ["Security", "保安検査場", "安全检查", "Kiểm tra an ninh", "Contrôle de sûreté", "Control de seguridad", "shield"],
	"baggage_check": ["Baggage Checkpoint", "手荷物検査", "行李检查", "Kiểm tra hành lý", "Contrôle des bagages", "Control de equipaje", "suitcase"],
	"welcome": ["Welcome", "ようこそ", "欢迎", "Chào mừng", "Bienvenue", "Bienvenidos", "plane"],
	"duty_free": ["Duty Free", "免税店", "免税店", "Cửa hàng miễn thuế", "Hors taxes", "Libre de impuestos", "bag"],
	"cafe": ["Café", "カフェ", "咖啡厅", "Quán cà phê", "Café", "Cafetería", "cup"],
	"news": ["News & Books", "書店", "书报亭", "Sách báo", "Presse", "Prensa", "bag"],
	"sushi": ["Sushi Bar", "寿司", "寿司", "Quầy sushi", "Bar à sushi", "Bar de sushi", "cup"],
	"lounge": ["Lounge", "ラウンジ", "休息室", "Phòng chờ", "Salon", "Sala de espera", "cup"],
	"lost_found": ["Lost & Found", "遺失物取扱所", "失物招领", "Đồ thất lạc", "Objets trouvés", "Objetos perdidos", "suitcase"],
	"self_check_in": ["Self Check-in", "自動チェックイン", "自助值机", "Tự làm thủ tục", "Enregistrement", "Facturación", "suitcase"],
	"bag_drop": ["Bag Drop", "手荷物預け", "行李托运", "Gửi hành lý", "Dépose bagages", "Entrega de equipaje", "suitcase"],
	"staff_only": ["Staff Only", "関係者以外立入禁止", "员工通道", "Chỉ dành cho nhân viên", "Réservé au personnel", "Solo personal", "shield"],
	"trays": ["Trays", "トレイ", "托盘", "Khay", "Bacs", "Bandejas", "suitcase"],
	"apron": ["Apron", "エプロン", "停机坪", "Sân đỗ", "Aire de trafic", "Plataforma", "plane"],
	"claim": ["Claim", "受取", "提取", "Băng chuyền", "Tapis", "Cinta", "suitcase"],
}

static var _font: SystemFont
static var _icons: Dictionary = {}


## A CJK + Vietnamese capable font from the OS (Hiragino on macOS, Yu Gothic/YaHei on Windows).
static func font() -> SystemFont:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray(["Hiragino Sans", "Hiragino Kaku Gothic ProN", "Yu Gothic UI", "Microsoft YaHei", "Noto Sans CJK JP", "Noto Sans"])
		_font.font_weight = 500
		_font.allow_system_fallback = true
		_font.multichannel_signed_distance_field = true
		# Simplified Chinese glyphs missing from the Japanese faces (e.g. 间, 边).
		var chinese := SystemFont.new()
		chinese.font_names = PackedStringArray(["Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC"])
		chinese.multichannel_signed_distance_field = true
		_font.fallbacks = [chinese]
	return _font


static func translations(key: String) -> Array:
	return TEXT.get(key, [key.capitalize(), "", "", "", "", "", "plane"])


## Builds a sign panel facing +Z in its own space. opts: width (m), arrow ("left"/"right"/"up"/""),
## accent (Color for the pictogram tile), suffix (appended to the English line, e.g. "A1-A12"),
## double_sided (bool), compact (bool: English + Japanese + Chinese only), scale (float: grows the
## whole sign uniformly — width is given before scaling).
static func panel(parent: Node3D, at: Vector3, key: String, opts: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Sign_" + key
	root.position = at
	root.scale = Vector3.ONE * float(opts.get("scale", 1.0))
	parent.add_child(root)
	var t := translations(key)
	var compact: bool = opts.get("compact", false)
	var width: float = opts.get("width", 3.4)
	var height := 0.86 if compact else 1.42
	var accent: Color = opts.get("accent", DesignKit.OCHRE)
	var body := DesignKit.metal(DesignKit.CHARCOAL, 0.5, 0.4, "sign_body")
	DesignKit.rbox(root, Vector3(width, height, 0.14), Vector3.ZERO, body, 0.05)
	# Brass rule along the top edge.
	DesignKit.rbox(root, Vector3(width - 0.12, 0.025, 0.02), Vector3(0.0, height * 0.5 - 0.06, 0.075), DesignKit.brass(), 0.008, false)
	var sides: Array[float] = [1.0]
	if opts.get("double_sided", false):
		sides.append(-1.0)
	for face in sides:
		var holder := Node3D.new()
		holder.rotation_degrees.y = 0.0 if face > 0.0 else 180.0
		root.add_child(holder)
		var tile := height - 0.24
		var tile_x := -width * 0.5 + 0.12 + tile * 0.5
		var pict := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(tile, tile)
		pict.mesh = quad
		pict.material_override = _icon_material(str(t[6]), accent)
		pict.position = Vector3(tile_x, -0.02, 0.072)
		pict.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(pict)
		var text_x := tile_x + tile * 0.5 + 0.14
		var arrow: String = opts.get("arrow", "")
		var text_width := width * 0.5 - text_x - (0.6 if arrow != "" else 0.12)
		var english := str(t[0]) + ("  " + str(opts["suffix"]) if opts.has("suffix") else "")
		var top := height * 0.5 - 0.17
		_text(holder, english, Vector3(text_x, top, 0.073), 96, DesignKit.CREAM, text_width)
		_text(holder, "%s　%s" % [t[1], t[2]], Vector3(text_x, top - 0.3, 0.073), 58, Color(0.93, 0.84, 0.68), text_width)
		if not compact:
			_text(holder, str(t[3]), Vector3(text_x, top - 0.53, 0.073), 50, Color(0.86, 0.82, 0.76), text_width)
			_text(holder, "%s · %s" % [t[4], t[5]], Vector3(text_x, top - 0.74, 0.073), 50, Color(0.86, 0.82, 0.76), text_width)
		if arrow != "":
			var arrow_mi := MeshInstance3D.new()
			var arrow_quad := QuadMesh.new()
			arrow_quad.size = Vector2(0.46, 0.46)
			arrow_mi.mesh = arrow_quad
			arrow_mi.material_override = _icon_material("arrow_" + arrow, Color(0, 0, 0, 0))
			arrow_mi.position = Vector3(width * 0.5 - 0.36, 0.0, 0.073)
			arrow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(arrow_mi)
	return root


## Hangs a sign from the ceiling on two thin steel rods.
static func hanging(parent: Node3D, at: Vector3, key: String, opts: Dictionary = {}, rod_length := 3.0) -> Node3D:
	var node := panel(parent, at, key, opts)
	var width: float = opts.get("width", 3.4)
	var rod := DesignKit.metal(DesignKit.CHARCOAL, 0.4, 0.9, "rod")
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.012
	mesh.height = rod_length
	mesh.radial_segments = 6
	for x in [-width * 0.38, width * 0.38]:
		DesignKit.add(node, mesh, rod, Vector3(x, rod_length * 0.5 + 0.4, 0.0), Vector3.ZERO, false)
	return node


## Left-aligned text that shrinks its font until it fits `width_m`.
static func _text(parent: Node3D, caption: String, at: Vector3, size: int, color: Color, width_m: float) -> Label3D:
	var label := Label3D.new()
	label.text = caption
	label.font = font()
	label.pixel_size = 0.0022
	var text_width := font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	if text_width > width_m:
		size = maxi(12, int(float(size) * width_m / text_width))
		text_width = font().get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	label.font_size = size
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = at + Vector3(text_width * 0.5, 0.0, 0.0)
	label.visibility_range_end = 70.0
	label.visibility_range_end_margin = 10.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
	return label


# --- Pictograms (ISO-style, drawn once into small textures) ----------------------------------

static func _icon_material(kind: String, tile: Color) -> StandardMaterial3D:
	var key := "%s:%s" % [kind, tile.to_html()]
	if _icons.has(key):
		return _icons[key]
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(tile)
	var ink := DesignKit.CREAM if tile.a > 0.0 else Color(0.97, 0.88, 0.62)
	if tile.a > 0.0:
		# Rounded tile corners.
		for y in size:
			for x in size:
				var cx := clampf(float(x), 14.0, size - 15.0)
				var cy := clampf(float(y), 14.0, size - 15.0)
				if Vector2(x - cx, y - cy).length() > 14.0:
					image.set_pixel(x, y, Color(0, 0, 0, 0))
	for shape: Array in _icon_shapes(kind):
		_draw_shape(image, shape, ink, tile if tile.a > 0.0 else Color(0, 0, 0, 0))
	# Smooth the rasterised edges, then mipmap for distance.
	image.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.albedo_texture = ImageTexture.create_from_image(image)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.emission_enabled = true
	m.emission_texture = m.albedo_texture
	m.emission_energy_multiplier = 0.9
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_icons[key] = m
	return m


## Shapes in 0..1 space: ["poly", PackedVector2Array, fill?] / ["circle", centre, radius, fill?] /
## ["rect", Rect2, fill?]. fill = false cuts back to the tile colour.
static func _icon_shapes(kind: String) -> Array:
	match kind:
		"plane":
			return [["poly", PackedVector2Array([Vector2(0.47, 0.1), Vector2(0.53, 0.1), Vector2(0.56, 0.4), Vector2(0.9, 0.6), Vector2(0.9, 0.67), Vector2(0.56, 0.57), Vector2(0.55, 0.8), Vector2(0.66, 0.88), Vector2(0.66, 0.93), Vector2(0.5, 0.89), Vector2(0.34, 0.93), Vector2(0.34, 0.88), Vector2(0.45, 0.8), Vector2(0.44, 0.57), Vector2(0.1, 0.67), Vector2(0.1, 0.6), Vector2(0.44, 0.4)]), true]]
		"suitcase":
			return [["rect", Rect2(0.36, 0.16, 0.28, 0.2), true], ["rect", Rect2(0.42, 0.22, 0.16, 0.14), false],
				["rect", Rect2(0.18, 0.33, 0.64, 0.5), true], ["rect", Rect2(0.32, 0.33, 0.04, 0.5), false], ["rect", Rect2(0.64, 0.33, 0.04, 0.5), false]]
		"wc":
			return [["circle", Vector2(0.3, 0.2), 0.085, true], ["rect", Rect2(0.21, 0.32, 0.18, 0.56), true],
				["circle", Vector2(0.7, 0.2), 0.085, true], ["poly", PackedVector2Array([Vector2(0.7, 0.31), Vector2(0.86, 0.68), Vector2(0.54, 0.68)]), true],
				["rect", Rect2(0.63, 0.66, 0.14, 0.22), true], ["rect", Rect2(0.49, 0.1, 0.02, 0.8), true]]
		"exit":
			return [["rect", Rect2(0.12, 0.12, 0.42, 0.76), true], ["rect", Rect2(0.2, 0.2, 0.26, 0.68), false],
				["poly", PackedVector2Array([Vector2(0.48, 0.44), Vector2(0.7, 0.44), Vector2(0.7, 0.32), Vector2(0.9, 0.5), Vector2(0.7, 0.68), Vector2(0.7, 0.56), Vector2(0.48, 0.56)]), true]]
		"passport":
			return [["rect", Rect2(0.24, 0.12, 0.52, 0.76), true], ["circle", Vector2(0.5, 0.43), 0.15, false],
				["circle", Vector2(0.5, 0.43), 0.1, true], ["rect", Rect2(0.34, 0.7, 0.32, 0.04), false]]
		"shield":
			return [["poly", PackedVector2Array([Vector2(0.5, 0.1), Vector2(0.84, 0.22), Vector2(0.8, 0.58), Vector2(0.5, 0.9), Vector2(0.2, 0.58), Vector2(0.16, 0.22)]), true],
				["poly", PackedVector2Array([Vector2(0.34, 0.5), Vector2(0.44, 0.6), Vector2(0.67, 0.36), Vector2(0.72, 0.42), Vector2(0.44, 0.7), Vector2(0.29, 0.55)]), false]]
		"cup":
			return [["circle", Vector2(0.68, 0.52), 0.14, true], ["circle", Vector2(0.68, 0.52), 0.075, false],
				["rect", Rect2(0.22, 0.34, 0.44, 0.44), true], ["rect", Rect2(0.14, 0.8, 0.66, 0.06), true]]
		"bag":
			return [["circle", Vector2(0.5, 0.36), 0.17, true], ["circle", Vector2(0.5, 0.36), 0.11, false],
				["rect", Rect2(0.2, 0.36, 0.6, 0.52), true]]
		"arrow_right":
			return [["poly", PackedVector2Array([Vector2(0.1, 0.4), Vector2(0.52, 0.4), Vector2(0.52, 0.18), Vector2(0.92, 0.5), Vector2(0.52, 0.82), Vector2(0.52, 0.6), Vector2(0.1, 0.6)]), true]]
		"arrow_left":
			return [["poly", PackedVector2Array([Vector2(0.9, 0.4), Vector2(0.48, 0.4), Vector2(0.48, 0.18), Vector2(0.08, 0.5), Vector2(0.48, 0.82), Vector2(0.48, 0.6), Vector2(0.9, 0.6)]), true]]
		"arrow_up":
			return [["poly", PackedVector2Array([Vector2(0.4, 0.9), Vector2(0.4, 0.48), Vector2(0.18, 0.48), Vector2(0.5, 0.08), Vector2(0.82, 0.48), Vector2(0.6, 0.48), Vector2(0.6, 0.9)]), true]]
	return []


static func _draw_shape(image: Image, shape: Array, ink: Color, cut: Color) -> void:
	var size := float(image.get_width())
	var fill: bool = shape[shape.size() - 1]
	var color := ink if fill else cut
	for y in image.get_height():
		for x in image.get_width():
			var p := Vector2((float(x) + 0.5) / size, (float(y) + 0.5) / size)
			var inside := false
			match str(shape[0]):
				"poly":
					inside = Geometry2D.is_point_in_polygon(p, shape[1])
				"circle":
					inside = p.distance_to(shape[1]) <= float(shape[2])
				"rect":
					inside = (shape[1] as Rect2).has_point(p)
			if inside:
				image.set_pixel(x, y, color)
