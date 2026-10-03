extends RefCounted
## Refrigerated retail case. Front is +Z; repeated food pieces share batched meshes.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "BentoDisplay"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var oak: Material = DesignKit.wood(DesignKit.WALNUT if choice == 2 else DesignKit.OAK, "bento_walnut" if choice == 2 else "bento_oak")
	var accent: Material = DesignKit.paint(accents[choice])
	var steel: Material = DesignKit.metal()
	var brass: Material = DesignKit.brass()
	var stone: Material = DesignKit.stone()
	var cream: Material = DesignKit.paint(DesignKit.CREAM)
	var glow: Material = DesignKit.washi(Color(1.0, 0.84, 0.59), 1.8, "bento_shelf_light")
	var glass: Material = _glass()
	# Four adjustable feet meet the floor; recessed plinth leaves a shadow reveal.
	for x: float in [-1.18, 1.18]:
		for z: float in [-0.36, 0.36]:
			DesignKit.add(root, DesignKit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.065, 0.0), Vector2(0.065, 0.025), Vector2(0.045, 0.04), Vector2(0.045, 0.13), Vector2(0.0, 0.13)]), 12), steel, Vector3(x, 0.0, z))
	DesignKit.rbox(root, Vector3(2.66, 0.12, 0.86), Vector3(0.0, 0.13, 0.0), steel, 0.045)
	DesignKit.rbox(root, Vector3(2.88, 0.47, 0.99), Vector3(0.0, 0.405, 0.0), stone, 0.07)
	DesignKit.rbox(root, Vector3(2.76, 0.035, 1.0), Vector3(0.0, 0.645, 0.0), brass, 0.012)
	DesignKit.rbox(root, Vector3(2.62, 0.405, 0.024), Vector3(0.0, 0.408, 0.503), accent, 0.011)
	_caption(root, "Cơm hộp", Vector3(0.0, 0.54, 0.524), 65, 2.45, DesignKit.CREAM)
	_caption(root, "Repas bento", Vector3(0.0, 0.397, 0.524), 65, 2.45, DesignKit.CREAM)
	_caption(root, "Comida bento", Vector3(0.0, 0.254, 0.524), 65, 2.45, DesignKit.CREAM)
	# Insulated rear, oak stiles and transparent end panels.
	DesignKit.rbox(root, Vector3(2.78, 1.06, 0.08), Vector3(0.0, 1.18, -0.46), oak, 0.035)
	DesignKit.rbox(root, Vector3(2.53, 0.97, 0.022), Vector3(0.0, 1.18, -0.408), cream, 0.01)
	for x: float in [-1.36, 1.36]:
		for z: float in [-0.43, 0.47]:
			DesignKit.rbox(root, Vector3(0.09, 1.08, 0.085), Vector3(x, 1.2, z), oak, 0.025)
		DesignKit.rbox(root, Vector3(0.012, 0.94, 0.81), Vector3(x, 1.2, 0.02), glass, 0.005, false)
	DesignKit.rbox(root, Vector3(2.91, 0.09, 1.04), Vector3(0.0, 1.755, 0.0), oak, 0.035)
	DesignKit.rbox(root, Vector3(2.82, 0.46, 0.16), Vector3(0.0, 2.025, 0.43), oak, 0.05)
	DesignKit.rbox(root, Vector3(2.68, 0.36, 0.025), Vector3(0.0, 2.025, 0.522), glow, 0.012, false)
	_caption(root, "BENTO", Vector3(0.0, 2.105, 0.542), 112, 2.5, DesignKit.CHARCOAL)
	_caption(root, "お弁当 · 便当", Vector3(0.0, 1.933, 0.542), 65, 2.5, DesignKit.CHARCOAL)
	# Two glazed sliding doors, brass edge seals and offset grip rails.
	for side: float in [-1.0, 1.0]:
		var door_z: float = 0.516 + (0.012 if side > 0.0 else 0.0)
		DesignKit.rbox(root, Vector3(1.3, 0.995, 0.012), Vector3(side * 0.649, 1.2, door_z), glass, 0.005, false)
		DesignKit.rbox(root, Vector3(0.016, 0.995, 0.025), Vector3(side * 0.025, 1.2, door_z + 0.008), brass, 0.006)
		DesignKit.rbox(root, Vector3(0.025, 0.28, 0.048), Vector3(side * 0.15, 1.14, door_z + 0.035), brass, 0.01)
	for y: float in [0.691, 1.702]:
		DesignKit.rbox(root, Vector3(2.68, 0.025, 0.055), Vector3(0.0, y, 0.516), steel, 0.009)
	# Rear service grille and its wooden surround are visible from the terminal aisle.
	DesignKit.rbox(root, Vector3(1.18, 0.24, 0.023), Vector3(0.0, 0.39, -0.506), steel, 0.018)
	for slot in 6:
		DesignKit.rbox(root, Vector3(1.08, 0.011, 0.01), Vector3(0.0, 0.302 + float(slot) * 0.035, -0.523), brass, 0.004, false)
	var batches: Dictionary = {}
	var tilt: Basis = Basis(Vector3.RIGHT, deg_to_rad(12.0))
	for row in 3:
		var shelf_y: float = 0.775 + float(row) * 0.31
		DesignKit.add(root, DesignKit.rounded_box(Vector3(2.57, 0.028, 0.72), 0.012), cream, Vector3(0.0, shelf_y, 0.04), Vector3(12.0, 0.0, 0.0))
		DesignKit.rbox(root, Vector3(2.58, 0.046, 0.026), Vector3(0.0, shelf_y - 0.061, 0.392), brass, 0.01)
		DesignKit.rbox(root, Vector3(2.48, 0.018, 0.022), Vector3(0.0, shelf_y + 0.215, -0.22), glow, 0.007, false)
		for column in 4:
			var tray_at: Vector3 = Vector3(-0.945 + float(column) * 0.63, shelf_y, 0.09)
			_bento(batches, Transform3D(tilt, tray_at), posmod(column + row + choice, 4), steel, brass)
	_flush(root, batches)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "WarmDisplayLight"
	light.position = Vector3(0.0, 1.36, 0.04)
	light.light_color = Color(1.0, 0.84, 0.62)
	light.light_energy = 0.65
	light.omni_range = 1.65
	light.shadow_enabled = false
	root.add_child(light)
	return root


static func _bento(batches: Dictionary, pose: Transform3D, recipe: int, tray: Material, rim: Material) -> void:
	# Raised rim, recessed lacquer liner, rice bay and three smaller food wells.
	_piece(batches, Vector3(0.55, 0.055, 0.39), pose, Vector3(0.0, 0.043, 0.0), rim, 0.023)
	_piece(batches, Vector3(0.523, 0.045, 0.362), pose, Vector3(0.0, 0.064, 0.0), tray, 0.018)
	_piece(batches, Vector3(0.231, 0.041, 0.314), pose, Vector3(-0.126, 0.087, 0.0), DesignKit.paint(DesignKit.CREAM, 0.9), 0.018)
	_piece(batches, Vector3(0.012, 0.035, 0.326), pose, Vector3(0.008, 0.085, 0.0), rim, 0.005)
	_piece(batches, Vector3(0.215, 0.026, 0.012), pose, Vector3(0.13, 0.085, 0.015), rim, 0.005)
	var proteins: Array[Color] = [Color(0.89, 0.43, 0.27), Color(0.69, 0.43, 0.19), Color(0.88, 0.72, 0.28), Color(0.78, 0.51, 0.37)]
	var protein: Material = DesignKit.paint(proteins[recipe], 0.42)
	for slice in 3:
		_piece(batches, Vector3(0.175, 0.044, 0.043), pose, Vector3(0.137, 0.105, -0.117 + float(slice) * 0.05), protein, 0.017)
		_piece(batches, Vector3(0.15, 0.004, 0.006), pose, Vector3(0.137, 0.128, -0.117 + float(slice) * 0.05), DesignKit.paint(Color(0.95, 0.79, 0.53)), 0.0015)
	for vegetable in 3:
		_piece(batches, Vector3(0.055, 0.054, 0.071), pose, Vector3(0.075 + float(vegetable) * 0.06, 0.112, 0.085), DesignKit.paint(Color(0.29, 0.46, 0.22)), 0.024)
	_piece(batches, Vector3(0.18, 0.03, 0.038), pose, Vector3(0.135, 0.099, 0.147), DesignKit.paint(Color(0.88, 0.43, 0.12)), 0.013)
	_piece(batches, Vector3(0.043, 0.016, 0.043), pose, Vector3(-0.126, 0.114, 0.0), DesignKit.paint(Color(0.6, 0.17, 0.13), 0.35), 0.007)
	# A pair of nori strips breaks up the rice surface without illegible packaging labels.
	for stripe in 2:
		_piece(batches, Vector3(0.013, 0.005, 0.13), pose, Vector3(-0.18 + float(stripe) * 0.11, 0.11, -0.035), DesignKit.paint(Color(0.19, 0.24, 0.16)), 0.002)


static func _piece(batches: Dictionary, size: Vector3, pose: Transform3D, offset: Vector3, material: Material, radius: float) -> void:
	var key: String = "%s:%s:%s" % [size, radius, material.get_instance_id()]
	if not batches.has(key):
		batches[key] = {"mesh": DesignKit.rounded_box(size, radius), "material": material, "poses": []}
	var batch: Dictionary = batches[key]
	var poses: Array = batch["poses"]
	poses.append(Transform3D(pose.basis, pose * offset))


static func _flush(root: Node3D, batches: Dictionary) -> void:
	for key: String in batches:
		var batch: Dictionary = batches[key]
		var poses: Array = batch["poses"]
		var mesh: Mesh = batch["mesh"]
		var material: Material = batch["material"]
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = poses.size()
		for index in poses.size():
			var pose: Transform3D = poses[index]
			multi.set_instance_transform(index, pose)
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = material
		root.add_child(instance)


static func _glass() -> StandardMaterial3D:
	if not _materials.has("glass"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.82, 0.94, 0.91, 0.13)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.roughness = 0.09
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["glass"] = material
	return _materials["glass"]


static func _caption(parent: Node3D, text: String, at: Vector3, font_size: int, width: float, ink: Color) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = text
	label.pixel_size = 0.0025
	var measured: float = label.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * label.pixel_size
	label.font_size = mini(font_size, int(float(font_size) * width / maxf(measured, 0.001)))
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
