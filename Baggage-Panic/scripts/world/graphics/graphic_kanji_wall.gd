extends RefCounted
## Floor-rooted 6 x 3 m feature wall; all artwork is generated and cached in memory.

const Kit = preload("res://scripts/world/design_kit.gd")
const Signs = preload("res://scripts/world/signage.gd")

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "KanjiJourneyWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var oak: StandardMaterial3D = Kit.wood()
	var walnut: StandardMaterial3D = Kit.wood(Kit.WALNUT, "kanji_wall_walnut")
	# A recessed, gently lit paper field, floating inside a thick oak gallery frame.
	Kit.rbox(root, Vector3(5.92, 2.92, 0.16), Vector3(0.0, 1.5, -0.055), walnut, 0.045)
	Kit.rbox(root, Vector3(5.74, 2.74, 0.055), Vector3(0.0, 1.5, 0.041),
		Kit.washi(Kit.CREAM, 0.16, "kanji_wall_paper"), 0.018)
	Kit.add(root, _paper_mesh(), _art_material(variant), Vector3(0.0, 1.5, 0.071), Vector3.ZERO, false)
	for x: float in [-2.93, 2.93]:
		Kit.rbox(root, Vector3(0.14, 3.0, 0.24), Vector3(x, 1.5, 0.0), oak, 0.026)
	for y: float in [0.07, 2.93]:
		Kit.rbox(root, Vector3(5.72, 0.14, 0.24), Vector3(0.0, y, 0.0), oak, 0.026)
	# Narrow brass inlays and walnut splines express the frame's joinery.
	for y: float in [0.147, 2.853]:
		Kit.rbox(root, Vector3(5.68, 0.012, 0.018), Vector3(0.0, y, 0.097), Kit.brass(), 0.004, false)
	for x: float in [-2.93, 2.93]:
		for y: float in [0.21, 2.79]:
			Kit.rbox(root, Vector3(0.083, 0.018, 0.012), Vector3(x, y, 0.119), walnut, 0.004, false)
	# Readable editorial column: one motif, six languages, no small explanatory labels.
	_caption(root, "Journey", Vector3(1.32, 2.26, 0.078), 0.39)
	_caption(root, "旅 · 旅程", Vector3(1.32, 1.84, 0.078), 0.30)
	_caption(root, "Hành trình", Vector3(1.32, 1.48, 0.078), 0.30)
	_caption(root, "Voyage", Vector3(1.32, 1.12, 0.078), 0.30)
	_caption(root, "Viaje", Vector3(1.32, 0.76, 0.078), 0.30)
	return root


static func _caption(parent: Node3D, words: String, at: Vector3, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = words
	label.font = Signs.font()
	label.font_size = 128
	label.pixel_size = height / 128.0
	label.position = at
	label.modulate = Kit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _paper_mesh() -> QuadMesh:
	if _meshes.has("paper"):
		return _meshes["paper"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(5.68, 2.68)
	_meshes["paper"] = mesh
	return mesh


static func _art_material(variant: int) -> StandardMaterial3D:
	var key: String = "ink_%d" % posmod(variant, 2)
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var image: Image = Image.create(1536, 768, false, Image.FORMAT_RGBA8)
	# Warm paper tooth and long scattered fibres, baked into one opaque texture.
	for y: int in image.get_height():
		for x: int in image.get_width():
			var tooth: float = _grain(x, y) * 0.022
			var fibre: float = 0.014 if posmod(x * 7 + y * 193, 701) < 4 else 0.0
			image.set_pixel(x, y, Color(0.963 - tooth - fibre, 0.928 - tooth - fibre, 0.852 - tooth - fibre))
	# Hand-authored ten-stroke skeleton of 旅, in a square calligraphic coordinate field.
	# Width rises with brush pressure, then trails away; uneven edges and dry bristles
	# retain the gesture without sacrificing the character's silhouette at distance.
	var strokes: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(29, 8), Vector2(32, 13), Vector2(33, 20)]),
		PackedVector2Array([Vector2(10, 29), Vector2(27, 27), Vector2(47, 25)]),
		PackedVector2Array([Vector2(27, 43), Vector2(43, 42), Vector2(42, 58), Vector2(37, 80), Vector2(33, 87), Vector2(25, 82)]),
		PackedVector2Array([Vector2(28, 29), Vector2(27, 47), Vector2(22, 65), Vector2(13, 82), Vector2(7, 89)]),
		PackedVector2Array([Vector2(63, 8), Vector2(60, 19), Vector2(54, 31), Vector2(48, 38)]),
		PackedVector2Array([Vector2(60, 25), Vector2(74, 24), Vector2(94, 21)]),
		PackedVector2Array([Vector2(79, 33), Vector2(69, 43), Vector2(56, 52), Vector2(48, 56)]),
		PackedVector2Array([Vector2(62, 48), Vector2(62, 66), Vector2(62, 87), Vector2(64, 91), Vector2(77, 80)]),
		PackedVector2Array([Vector2(91, 43), Vector2(84, 52), Vector2(74, 61)]),
		PackedVector2Array([Vector2(72, 53), Vector2(77, 68), Vector2(87, 83), Vector2(98, 90)])
	]
	for index: int in strokes.size():
		_brush(image, strokes[index], 18.0 if index == 0 else 24.0, index)
	# A single clay-coloured seal-like square, deliberately without invented writing.
	var seal: Color = Kit.CLAY.darkened(0.12) if posmod(variant, 2) == 0 else Kit.SAGE.darkened(0.15)
	for y: int in range(631, 675):
		for x: int in range(691, 735):
			if x < 697 or x > 728 or y < 637 or y > 668:
				if _grain(x, y) > 0.09:
					image.set_pixel(x, y, seal)
	image.generate_mipmaps()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = 0.94
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 0.12
	_materials[key] = material
	return material


static func _brush(image: Image, path: PackedVector2Array, width: float, stroke: int) -> void:
	var ink: Color = Color(0.085, 0.079, 0.068)
	for segment: int in range(path.size() - 1):
		var a: Vector2 = Vector2(92, 67) + path[segment] * 6.3
		var b: Vector2 = Vector2(92, 67) + path[segment + 1] * 6.3
		var delta: Vector2 = b - a
		var length_squared: float = delta.length_squared()
		var min_x: int = maxi(0, int(minf(a.x, b.x) - width * 1.5))
		var max_x: int = mini(image.get_width() - 1, int(maxf(a.x, b.x) + width * 1.5))
		var min_y: int = maxi(0, int(minf(a.y, b.y) - width * 1.5))
		var max_y: int = mini(image.get_height() - 1, int(maxf(a.y, b.y) + width * 1.5))
		for y: int in range(min_y, max_y + 1):
			for x: int in range(min_x, max_x + 1):
				var p: Vector2 = Vector2(x, y)
				var t: float = clampf((p - a).dot(delta) / length_squared, 0.0, 1.0)
				var progress: float = (float(segment) + t) / float(path.size() - 1)
				var pressure: float = 0.66 + 0.37 * sin(progress * PI)
				if segment == path.size() - 2:
					pressure *= lerpf(1.0, 0.34, t * t)
				var radius: float = width * pressure
				var distance: float = p.distance_to(a + delta * t)
				var edge: float = radius + (_grain(x, y + stroke * 59) - 0.5) * 3.2
				if distance > edge:
					continue
				var across: float = (p - a).cross(delta.normalized())
				var bristle: float = sin(across * 1.7 + float(stroke))
				var dry: float = 0.20 if bristle > 0.84 and progress > 0.45 else 0.0
				var coverage: float = clampf(edge - distance, 0.0, 1.0) * (0.91 - dry - _grain(x, y) * 0.10)
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(ink, coverage))


static func _grain(x: int, y: int) -> float:
	var value: int = posmod(x * 374761 + y * 668265, 104729)
	value = posmod(value * 127 + 13, 104729)
	return float(value) / 104729.0
