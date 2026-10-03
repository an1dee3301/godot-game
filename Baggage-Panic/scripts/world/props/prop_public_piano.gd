extends RefCounted
## A playable-scale walnut upright, open keyboard and upholstered companion stool.
## +Z is the pianist's side; all dimensions are metres.

static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "PublicPiano"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var style: int = posmod(variant, 4)
	var upholstery_colors: Array[Color] = [DesignKit.LINEN, DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO]
	var walnut_colors: Array[Color] = [DesignKit.WALNUT, DesignKit.WALNUT.lightened(0.06), DesignKit.WALNUT.darkened(0.06), DesignKit.WALNUT.lightened(0.025)]
	var walnut: StandardMaterial3D = DesignKit.wood(walnut_colors[style], "public_piano_walnut_%d" % style)
	var dark_wood: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT.darkened(0.23), "public_piano_recess")
	var steel: StandardMaterial3D = DesignKit.metal()
	var brass: StandardMaterial3D = DesignKit.brass()
	var ivory: StandardMaterial3D = DesignKit.paint(DesignKit.CREAM, 0.28)
	var ebony: StandardMaterial3D = DesignKit.paint(DesignKit.CHARCOAL.darkened(0.5), 0.25)
	var linen: StandardMaterial3D = DesignKit.fabric(upholstery_colors[style], "public_piano_seat_%d" % style)

	# Rounded cabinet joinery: a recessed lower soundboard and raised upper panel.
	DesignKit.rbox(root, Vector3(1.39, 1.10, 0.43), Vector3(0.0, 0.64, -0.075), dark_wood, 0.035)
	DesignKit.rbox(root, Vector3(1.30, 0.53, 0.055), Vector3(0.0, 0.40, 0.158), walnut, 0.024)
	DesignKit.rbox(root, Vector3(1.32, 0.365, 0.052), Vector3(0.0, 0.987, 0.161), walnut, 0.028)
	DesignKit.rbox(root, Vector3(1.51, 0.065, 0.50), Vector3(0.0, 1.215, -0.05), walnut, 0.025)
	DesignKit.rbox(root, Vector3(1.41, 0.075, 0.47), Vector3(0.0, 0.123, -0.055), walnut, 0.025)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.075, 1.12, 0.465), Vector3(side * 0.715, 0.65, -0.058), walnut, 0.025)
		# Swept-looking softened cheeks frame the open keyboard.
		DesignKit.rbox(root, Vector3(0.093, 0.10, 0.43), Vector3(side * 0.681, 0.746, 0.377), walnut, 0.038)
		DesignKit.rbox(root, Vector3(0.074, 0.61, 0.09), Vector3(side * 0.683, 0.405, 0.486), walnut, 0.025)
		DesignKit.rbox(root, Vector3(0.115, 0.09, 0.62), Vector3(side * 0.676, 0.085, 0.153), walnut, 0.034)
		for depth: float in [-0.105, 0.399]:
			DesignKit.add(root, _foot_mesh(), steel, Vector3(side * 0.676, 0.0, depth))
		# Flush lid hinges, deliberately without tiny lettering.
		DesignKit.rbox(root, Vector3(0.085, 0.014, 0.045), Vector3(side * 0.43, 1.249, -0.17), brass, 0.006, false)

	# Full 88-key layout, shared as two cached meshes rather than 88 nodes.
	DesignKit.rbox(root, Vector3(1.32, 0.053, 0.30), Vector3(0.0, 0.708, 0.441), walnut, 0.019)
	DesignKit.rbox(root, Vector3(1.245, 0.023, 0.252), Vector3(0.0, 0.741, 0.465), ebony, 0.008)
	DesignKit.add(root, _keyboard_mesh(false), ivory, Vector3.ZERO, Vector3.ZERO, false)
	DesignKit.add(root, _keyboard_mesh(true), ebony, Vector3.ZERO, Vector3.ZERO, false)
	# Raised fallboard behind the keys, with felt stop and a brass hinge rule.
	DesignKit.rbox(root, Vector3(1.30, 0.115, 0.034), Vector3(0.0, 0.809, 0.304), walnut, 0.013)
	DesignKit.rbox(root, Vector3(1.235, 0.012, 0.018), Vector3(0.0, 0.757, 0.327), DesignKit.fabric(DesignKit.CLAY.darkened(0.35), "public_piano_felt"), 0.004, false)
	DesignKit.rbox(root, Vector3(1.23, 0.009, 0.012), Vector3(0.0, 0.864, 0.329), brass, 0.003, false)
	# Open walnut music rest: a lip holds scores, raised battens support their backs.
	# The recessed cabinet remains visible between the crafted frame members.
	DesignKit.rbox(root, Vector3(0.67, 0.03, 0.078), Vector3(0.0, 0.891, 0.226), walnut, 0.01)
	DesignKit.rbox(root, Vector3(0.67, 0.028, 0.02), Vector3(0.0, 0.915, 0.258), walnut, 0.009)
	DesignKit.rbox(root, Vector3(0.65, 0.025, 0.026), Vector3(0.0, 1.103, 0.205), walnut, 0.008)
	for x: float in [-0.306, 0.0, 0.306]:
		DesignKit.rbox(root, Vector3(0.022, 0.19, 0.026), Vector3(x, 0.999, 0.205), walnut, 0.008)
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.013, 0.28, 0.014), Vector3(side * 0.605, 0.99, 0.193), brass, 0.004, false)

	# Three brass pedals emerge from a dark escutcheon, with rounded toe pads.
	DesignKit.rbox(root, Vector3(0.37, 0.055, 0.022), Vector3(0.0, 0.184, 0.191), steel, 0.014)
	for pedal: int in 3:
		var x: float = float(pedal - 1) * 0.115
		DesignKit.add(root, DesignKit.rounded_box(Vector3(0.029, 0.023, 0.17), 0.009), brass, Vector3(x, 0.152, 0.26), Vector3(-12.0, 0.0, 0.0), false)
		DesignKit.rbox(root, Vector3(0.066, 0.027, 0.098), Vector3(x, 0.13, 0.369), brass, 0.013, false)

	# Companion stool: turned walnut legs, stretchers, linen cushion and piping.
	var stool_z: float = 1.07 + (0.035 if style % 2 == 1 else 0.0)
	DesignKit.rbox(root, Vector3(0.57, 0.07, 0.36), Vector3(0.0, 0.428, stool_z), walnut, 0.029)
	DesignKit.rbox(root, Vector3(0.595, 0.025, 0.385), Vector3(0.0, 0.47, stool_z), DesignKit.fabric(upholstery_colors[style].darkened(0.22), "public_piano_piping_%d" % style), 0.011)
	DesignKit.rbox(root, Vector3(0.59, 0.072, 0.38), Vector3(0.0, 0.498, stool_z), linen, 0.035)
	for x: float in [-0.223, 0.223]:
		for z: float in [-0.115, 0.115]:
			DesignKit.add(root, _stool_leg_mesh(), walnut, Vector3(x, 0.025, stool_z + z))
			DesignKit.rbox(root, Vector3(0.048, 0.025, 0.048), Vector3(x, 0.0125, stool_z + z), steel, 0.008, false)
		DesignKit.rbox(root, Vector3(0.026, 0.034, 0.254), Vector3(x, 0.16, stool_z), walnut, 0.01)
	DesignKit.rbox(root, Vector3(0.466, 0.034, 0.027), Vector3(0.0, 0.16, stool_z), walnut, 0.01)

	# A small tabletop invitation with large high-contrast lettering.
	# Two lines keep the Japanese at a readable physical character height.
	for x: float in [-0.42, 0.42]:
		DesignKit.rbox(root, Vector3(0.032, 0.15, 0.032), Vector3(x, 1.313, -0.034), brass, 0.009)
	DesignKit.rbox(root, Vector3(1.36, 0.435, 0.064), Vector3(0.0, 1.524, -0.017), walnut, 0.036)
	DesignKit.rbox(root, Vector3(1.29, 0.37, 0.014), Vector3(0.0, 1.524, 0.019), DesignKit.washi(DesignKit.CREAM, 0.35, "public_piano_invitation"), 0.022, false)
	_caption(root, "Play me ·", Vector3(0.0, 1.615, 0.029), 72)
	_caption(root, "弾いてください", Vector3(0.0, 1.443, 0.029), 64)
	return root


static func _caption(parent: Node3D, caption: String, at: Vector3, size: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = 0.0023
	label.modulate = DesignKit.CHARCOAL
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _keyboard_mesh(black: bool) -> ArrayMesh:
	var key: String = "black_keys" if black else "white_keys"
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var size: Vector3 = Vector3(0.0135, 0.022, 0.137) if black else Vector3(0.0226, 0.017, 0.235)
	var source: ArrayMesh = DesignKit.rounded_box(size, 0.003, 2)
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white_index: int = 0
	var spacing: float = 0.0235
	for midi: int in range(21, 109):
		var pitch: int = midi % 12
		var is_black: bool = pitch in [1, 3, 6, 8, 10]
		if is_black == black:
			var x: float = -52.0 * spacing * 0.5 + (float(white_index) + (0.0 if black else 0.5)) * spacing
			var offset: Vector3 = Vector3(x, 0.779 if black else 0.757, 0.416 if black else 0.465)
			surface.append_from(source, 0, Transform3D(Basis.IDENTITY, offset))
		if not is_black:
			white_index += 1
	var mesh: ArrayMesh = surface.commit()
	_meshes[key] = mesh
	return mesh


static func _foot_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.04, 0.0), Vector2(0.045, 0.012),
		Vector2(0.041, 0.038), Vector2(0.029, 0.044), Vector2(0.0, 0.044)
	]), 16)


static func _stool_leg_mesh() -> ArrayMesh:
	return DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.023, 0.0), Vector2(0.025, 0.025),
		Vector2(0.022, 0.075), Vector2(0.027, 0.30), Vector2(0.034, 0.36),
		Vector2(0.034, 0.40), Vector2(0.0, 0.40)
	]), 16)
