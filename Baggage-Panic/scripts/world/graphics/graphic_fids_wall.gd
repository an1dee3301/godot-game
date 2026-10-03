extends RefCounted
## A floor-standing flight information display in a crafted timber surround.

static var _art: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "DeparturesWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var walnut := DesignKit.wood(DesignKit.WALNUT, "fids_walnut")
	var steel := DesignKit.metal(DesignKit.CHARCOAL, 0.43, 0.65, "fids_steel")
	var screen := DesignKit.paint(Color(0.025, 0.042, 0.045), 0.22)
	var brass := DesignKit.brass()
	var sage := DesignKit.paint(DesignKit.SAGE.darkened(0.27), 0.5)

	# The timber case reaches the floor; narrow stone and steel feet give it a stable stance.
	DesignKit.rbox(root, Vector3(6.0, 2.5, 0.2), Vector3(0.0, 1.25, 0.0), walnut, 0.075)
	DesignKit.rbox(root, Vector3(5.79, 2.29, 0.218), Vector3(0.0, 1.26, 0.014), steel, 0.055)
	DesignKit.rbox(root, Vector3(5.67, 2.17, 0.226), Vector3(0.0, 1.26, 0.022), screen, 0.035, false)
	DesignKit.rbox(root, Vector3(5.76, 0.025, 0.025), Vector3(0.0, 2.425, 0.129), brass, 0.008, false)
	DesignKit.rbox(root, Vector3(5.74, 0.018, 0.027), Vector3(0.0, 0.115, 0.131), brass, 0.006, false)
	DesignKit.rbox(root, Vector3(5.94, 0.09, 0.31), Vector3(0.0, 0.045, -0.015), DesignKit.stone(DesignKit.LIMESTONE, 0.6, "fids_limestone"), 0.035)
	for x: float in [-2.55, 2.55]:
		DesignKit.rbox(root, Vector3(0.42, 0.045, 0.39), Vector3(x, 0.0225, 0.01), steel, 0.02)
		DesignKit.rbox(root, Vector3(0.05, 0.05, 0.02), Vector3(x, 0.065, 0.152), brass, 0.012, false)

	# A single strong rising-sun/runway mark is painted into a luminous image.
	var mark := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.38, 0.38)
	mark.mesh = quad
	mark.material_override = _motif_material()
	mark.position = Vector3(-2.53, 2.14, 0.139)
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mark)

	var title_words: Array = Signage.TEXT["departures"]
	_label(root, str(title_words[0]).to_upper(), -2.24, 2.155, 3.35, 91, Color(0.97, 0.93, 0.83))
	_label(root, "%s  /  %s" % [title_words[1], title_words[2]], 1.11, 2.155, 1.59, 54, Color(0.69, 0.8, 0.69))
	DesignKit.rbox(root, Vector3(5.39, 0.018, 0.016), Vector3(0.0, 1.965, 0.143), sage, 0.006, false)

	# The six destinations use English, Japanese, Chinese, Vietnamese, French and Spanish.
	var destinations: Array[String] = ["SINGAPORE", "東京", "上海", "Hà Nội", "PARIS", "MADRID"]
	var times: Array[String] = ["08:45", "09:10", "09:35", "10:05", "10:40", "11:20"]
	var gates: Array[String] = ["A12", "B04", "C08", "A06", "D02", "B11"]
	var first_row: int = posmod(variant, 6)
	for row in 6:
		var index: int = (first_row + row) % 6
		var y: float = 1.78 - float(row) * 0.292
		if row % 2 == 0:
			DesignKit.rbox(root, Vector3(5.43, 0.282, 0.006), Vector3(0.0, y, 0.141), DesignKit.paint(Color(0.055, 0.077, 0.076), 0.4), 0.002, false)
		_label(root, destinations[index], -2.6, y, 3.10, 79, Color(0.93, 0.95, 0.88))
		_label(root, times[index], 0.76, y, 1.10, 79, Color(0.89, 0.82, 0.64))
		DesignKit.rbox(root, Vector3(0.69, 0.235, 0.012), Vector3(2.21, y, 0.149), sage, 0.025, false)
		_label(root, gates[index], 1.98, y, 0.52, 69, Color(0.96, 0.95, 0.83), 0.157)
		if row < 5:
			DesignKit.rbox(root, Vector3(5.37, 0.007, 0.01), Vector3(0.0, y - 0.147, 0.149), DesignKit.paint(Color(0.19, 0.25, 0.23), 0.5), 0.002, false)
	return root


static func _label(parent: Node3D, words: String, left: float, y: float, max_width: float, size: int, color: Color, z: float = 0.157) -> void:
	var label := Label3D.new()
	label.text = words
	label.font = Signage.font()
	label.pixel_size = 0.00255
	var measured: float = Signage.font().get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	if measured > max_width:
		size = maxi(32, int(float(size) * max_width / measured))
		measured = Signage.font().get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * label.pixel_size
	label.font_size = size
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(left + measured * 0.5, y, z)
	label.visibility_range_end = 80.0
	label.visibility_range_end_margin = 10.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _motif_material() -> StandardMaterial3D:
	if _art.has("motif"):
		return _art["motif"] as StandardMaterial3D
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for py in 256:
		for px in 256:
			var p := Vector2(float(px) - 128.0, float(py) - 128.0)
			var d: float = p.length()
			if d < 107.0:
				image.set_pixel(px, py, Color(0.70, 0.76, 0.61))
			if d < 90.0 and p.y > 8.0:
				image.set_pixel(px, py, Color(0.78, 0.49, 0.34))
			if d < 90.0 and p.y <= 8.0:
				image.set_pixel(px, py, Color(0.96, 0.88, 0.68))
			if absf(p.x) < 8.0 and p.y > -54.0 and p.y < 94.0:
				image.set_pixel(px, py, Color(0.18, 0.28, 0.27))
			if absf(p.x) > 31.0 and absf(p.x) < 39.0 and p.y > 43.0 and p.y < 82.0:
				image.set_pixel(px, py, Color(0.18, 0.28, 0.27))
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 1.25
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art["motif"] = material
	return material
