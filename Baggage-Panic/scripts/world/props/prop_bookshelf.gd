extends RefCounted
## Freestanding, two-sided walnut book island. All dimensions are metres.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BookstoreIsland"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var edition: int = posmod(variant, 4)
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT.lightened(float(edition) * 0.025), "bookshelf_walnut_%d" % edition)
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "bookshelf_oak")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[edition]
	# Recessed feet touch the floor; a honed stone skirt protects the timber.
	for x: float in [-1.40, 1.40]:
		for z: float in [-0.38, 0.38]:
			DesignKit.rbox(root, Vector3(0.16, 0.10, 0.16), Vector3(x, 0.05, z), steel, 0.025)
	DesignKit.rbox(root, Vector3(3.46, 0.16, 1.16), Vector3(0.0, 0.17, 0.0), DesignKit.stone(), 0.055)
	DesignKit.rbox(root, Vector3(3.38, 0.025, 1.08), Vector3(0.0, 0.2625, 0.0), brass, 0.009)
	# A thin central back and divider make two bays on each side of the island.
	DesignKit.rbox(root, Vector3(3.18, 1.27, 0.07), Vector3(0.0, 0.90, 0.0), oak, 0.025)
	for x: float in [-1.63, 0.0, 1.63]:
		DesignKit.rbox(root, Vector3(0.075, 1.32, 1.04), Vector3(x, 0.93, 0.0), walnut, 0.025)
	for row: int in 4:
		var y: float = 0.30 + float(row) * 0.43
		DesignKit.rbox(root, Vector3(3.40, 0.05, 1.10), Vector3(0.0, y, 0.0), walnut, 0.022)
		if row < 3:
			for side: float in [-1.0, 1.0]:
				# A slender brass lip keeps books and face-out displays on the shelf.
				DesignKit.rbox(root, Vector3(3.19, 0.032, 0.018), Vector3(0.0, y + 0.041, side * 0.527), brass, 0.007)
		else:
			for side: float in [-1.0, 1.0]:
				DesignKit.rbox(root, Vector3(3.12, 0.016, 0.025), Vector3(0.0, y - 0.032, side * 0.43), DesignKit.washi(DesignKit.CREAM, 0.65, "bookshelf_shelf_glow"), 0.006, false)
	_books(root, edition)
	for side: float in [-1.0, 1.0]:
		for display: int in 2:
			_face_out(root, Vector3(-0.91 + float(display) * 1.82, 1.175, side * 0.435), side, accents[(edition + display) % 4], edition + display)
	# The header is built into the furniture, with a warm paper inset on both faces.
	DesignKit.rbox(root, Vector3(3.42, 0.97, 0.13), Vector3(0.0, 2.075, 0.0), walnut, 0.045)
	for side: float in [-1.0, 1.0]:
		var face: Node3D = Node3D.new()
		face.position = Vector3(0.0, 2.075, side * 0.071)
		face.rotation_degrees.y = 0.0 if side > 0.0 else 180.0
		root.add_child(face)
		DesignKit.rbox(face, Vector3(3.24, 0.82, 0.018), Vector3.ZERO, DesignKit.washi(DesignKit.CREAM, 0.3, "bookshelf_header"), 0.026, false)
		DesignKit.rbox(face, Vector3(0.022, 0.67, 0.014), Vector3(-1.50, 0.0, 0.017), DesignKit.paint(accent), 0.006, false)
		var text: Array = Signage.TEXT["news"]
		_caption(face, str(text[0]), Vector3(0.0, 0.24, 0.023), 90)
		_caption(face, "%s　·　%s" % [text[1], text[2]], Vector3(0.0, 0.025, 0.023), 62)
		_caption(face, str(text[3]), Vector3(0.0, -0.15, 0.023), 58)
		_caption(face, "%s　·　%s" % [text[4], text[5]], Vector3(0.0, -0.31, 0.023), 58)
	return root


static func _book_material() -> StandardMaterial3D:
	if not _materials.has("cloth_covers"):
		var material: StandardMaterial3D = DesignKit.fabric(Color.WHITE, "bookshelf_cover_cloth").duplicate() as StandardMaterial3D
		material.vertex_color_use_as_albedo = true
		_materials["cloth_covers"] = material
	return _materials["cloth_covers"] as StandardMaterial3D


static func _batch(parent: Node3D, name_value: String, size: Vector3, count: int, material: Material, colors: bool = false) -> MultiMesh:
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = colors
	batch.mesh = DesignKit.rounded_box(size, 0.002, 2)
	batch.instance_count = count
	var node: MultiMeshInstance3D = MultiMeshInstance3D.new()
	node.name = name_value
	node.multimesh = batch
	node.material_override = material
	parent.add_child(node)
	return batch


static func _books(parent: Node3D, edition: int) -> void:
	const COUNT: int = 288
	var covers: MultiMesh = _batch(parent, "ClothCoverBoards", Vector3(0.003, 0.30, 0.23), COUNT * 2, _book_material(), true)
	var spines: MultiMesh = _batch(parent, "RoundedBookSpines", Vector3(0.06, 0.30, 0.015), COUNT, _book_material(), true)
	var pages: MultiMesh = _batch(parent, "IvoryPageBlocks", Vector3(0.054, 0.286, 0.213), COUNT, DesignKit.paint(DesignKit.CREAM, 0.93))
	var bands: MultiMesh = _batch(parent, "SpineFoilRules", Vector3(0.044, 0.004, 0.0025), COUNT * 2, DesignKit.brass())
	var palette: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE, DesignKit.LINEN, DesignKit.CHARCOAL, Color(0.45, 0.25, 0.25), DesignKit.CREAM]
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7319 + edition * 107
	var index: int = 0
	for side: float in [-1.0, 1.0]:
		var facing: Basis = Basis(Vector3.UP, 0.0 if side > 0.0 else PI)
		for row: int in 3:
			for bay: int in 2:
				var cursor: float = -1.55 + float(bay) * 1.66
				for book: int in 24:
					var width: float = random.randf_range(0.043, 0.063)
					var height: float = random.randf_range(0.235, 0.355)
					var depth: float = random.randf_range(0.205, 0.26)
					var scale_value: Vector3 = Vector3(width / 0.06, height / 0.30, depth / 0.23)
					var center: Vector3 = Vector3(cursor + width * 0.5, 0.325 + float(row) * 0.43 + height * 0.5, side * (0.09 + depth * 0.5))
					var color_value: Color = palette[(book + row * 3 + edition + random.randi_range(0, 3)) % palette.size()]
					var transform: Transform3D = Transform3D(facing.scaled(scale_value), center)
					pages.set_instance_transform(index, transform)
					spines.set_instance_transform(index, Transform3D(transform.basis, center + facing * Vector3(0.0, 0.0, depth * 0.5 - 0.0075)))
					spines.set_instance_color(index, color_value.darkened(0.04))
					for edge: int in 2:
						var sign_value: float = -1.0 if edge == 0 else 1.0
						covers.set_instance_transform(index * 2 + edge, Transform3D(transform.basis, center + facing * Vector3(sign_value * (width * 0.5 - 0.0015), 0.0, 0.0)))
						covers.set_instance_color(index * 2 + edge, color_value)
						bands.set_instance_transform(index * 2 + edge, Transform3D(transform.basis, center + facing * Vector3(0.0, sign_value * height * 0.34, depth * 0.5 + 0.001)))
					cursor += width + 0.006
					index += 1


static func _face_out(parent: Node3D, at: Vector3, side: float, color_value: Color, motif: int) -> void:
	var book: Node3D = Node3D.new()
	book.name = "FaceOutCover"
	book.position = at
	book.rotation_degrees = Vector3(-9.0, 0.0 if side > 0.0 else 180.0, 0.0)
	parent.add_child(book)
	# Large-format art books, with visible page edges, cloth boards and abstract cover art.
	DesignKit.rbox(book, Vector3(0.255, 0.35, 0.029), Vector3(0.0, 0.175, 0.0), DesignKit.paint(DesignKit.CREAM, 0.95), 0.006)
	for z: float in [-0.020, 0.020]:
		DesignKit.rbox(book, Vector3(0.27, 0.365, 0.007), Vector3(0.0, 0.18, z), DesignKit.fabric(color_value, "bookshelf_face_%d" % posmod(motif, 4)), 0.003)
	DesignKit.rbox(book, Vector3(0.017, 0.36, 0.044), Vector3(-0.128, 0.18, 0.0), DesignKit.paint(color_value.darkened(0.12)), 0.007)
	# Abstract sun, horizon and a narrow foil rule; no unreadable miniature lettering.
	var sun_profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, -0.002), Vector2(0.038, -0.002), Vector2(0.042, 0.0), Vector2(0.038, 0.002), Vector2(0.0, 0.002)])
	DesignKit.add(book, DesignKit.lathe(sun_profile, 20), DesignKit.paint(DesignKit.OCHRE), Vector3(0.045, 0.25, 0.027), Vector3(90.0, 0.0, 0.0), false)
	DesignKit.rbox(book, Vector3(0.20, 0.065, 0.004), Vector3(0.0, 0.125, 0.027), DesignKit.paint(DesignKit.CREAM), 0.015, false)
	DesignKit.rbox(book, Vector3(0.15, 0.005, 0.004), Vector3(0.0, 0.075, 0.027), DesignKit.brass(), 0.001, false)
	DesignKit.rbox(parent, Vector3(0.28, 0.019, 0.13), Vector3(at.x, at.y - 0.04, at.z - side * 0.02), DesignKit.metal(), 0.008)


static func _caption(parent: Node3D, value: String, at: Vector3, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = value
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = 0.0028
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
