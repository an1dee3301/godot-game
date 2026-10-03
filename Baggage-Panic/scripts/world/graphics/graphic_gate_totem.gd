extends RefCounted
## Floor-standing gate marker: a warm oak monolith with a luminous number and inset flight display.

static var _screen_materials: Dictionary = {}
static var _screen_mesh: QuadMesh


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "GateTotem"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "gate_totem_oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "gate_totem_walnut")
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.43, 0.68, "gate_totem_steel")
	var brass: StandardMaterial3D = DesignKit.brass()
	var paper: StandardMaterial3D = DesignKit.washi(DesignKit.CREAM, 1.8, "gate_totem_washi")
	var stone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.7, "gate_totem_stone")

	# Limestone foot, separated from the timber by a thin dark reveal.
	DesignKit.rbox(root, Vector3(1.36, 0.11, 0.46), Vector3(0.0, 0.055, 0.0), stone, 0.04)
	DesignKit.rbox(root, Vector3(1.22, 0.035, 0.34), Vector3(0.0, 0.128, 0.0), steel, 0.014)
	DesignKit.rbox(root, Vector3(1.28, 3.04, 0.34), Vector3(0.0, 1.68, 0.0), oak, 0.065)
	DesignKit.rbox(root, Vector3(1.22, 0.035, 0.36), Vector3(0.0, 3.17, 0.0), walnut, 0.014)

	# A shallow walnut channel frames the tall washi lightbox.
	DesignKit.rbox(root, Vector3(1.14, 1.10, 0.035), Vector3(0.0, 2.51, 0.177), walnut, 0.03)
	DesignKit.rbox(root, Vector3(1.09, 1.05, 0.019), Vector3(0.0, 2.51, 0.199), paper, 0.025, false)
	DesignKit.rbox(root, Vector3(0.96, 0.012, 0.012), Vector3(0.0, 2.045, 0.213), brass, 0.005, false)

	var gate_index: int = posmod(variant, 32)
	var gate_letter: String = ["A", "B", "C", "D"][gate_index / 8]
	var gate_number: int = 7 + gate_index % 8
	_add_label(root, "%s %02d" % [gate_letter, gate_number], Vector3(0.0, 2.52, 0.219), 218, 0.00255, DesignKit.CHARCOAL)
	_add_label(root, "GATE  ·  搭乗口  ·  登机口", Vector3(0.0, 2.88, 0.219), 55, 0.0018, DesignKit.WALNUT)

	# The display is set behind a blackened steel bezel, with a printed route motif.
	DesignKit.rbox(root, Vector3(1.14, 0.86, 0.055), Vector3(0.0, 1.28, 0.187), steel, 0.036)
	DesignKit.rbox(root, Vector3(1.09, 0.81, 0.018), Vector3(0.0, 1.28, 0.222), DesignKit.paint(DesignKit.INDIGO), 0.021, false)
	DesignKit.add(root, _get_screen_mesh(), _screen_material(), Vector3(0.0, 1.28, 0.233), Vector3.ZERO, false)
	_add_label(root, "BOARDING", Vector3(-0.26, 1.55, 0.24), 72, 0.0019, DesignKit.CREAM)
	_add_label(root, "08:40", Vector3(-0.24, 1.29, 0.24), 125, 0.0019, DesignKit.CREAM)
	_add_label(root, "TOKYO  /  東京", Vector3(-0.13, 1.02, 0.24), 68, 0.0018, DesignKit.CREAM)

	# Brass inlay marks the display boundary; the lower panel is kept quiet.
	DesignKit.rbox(root, Vector3(1.06, 0.015, 0.017), Vector3(0.0, 0.79, 0.185), brass, 0.006, false)
	DesignKit.rbox(root, Vector3(0.64, 0.028, 0.012), Vector3(0.0, 0.50, 0.176), walnut, 0.009, false)
	_add_label(root, "PORTE · CỬA · PUERTA", Vector3(0.0, 0.36, 0.181), 49, 0.0018, DesignKit.WALNUT)
	return root


static func _add_label(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.visibility_range_end = 75.0
	label.visibility_range_end_margin = 10.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _get_screen_mesh() -> QuadMesh:
	if _screen_mesh == null:
		_screen_mesh = QuadMesh.new()
		_screen_mesh.size = Vector2(1.055, 0.775)
	return _screen_mesh


static func _screen_material() -> StandardMaterial3D:
	if _screen_materials.has("route"):
		return _screen_materials["route"] as StandardMaterial3D
	var image := Image.create(512, 384, false, Image.FORMAT_RGB8)
	var ground := Color(0.145, 0.205, 0.245)
	var horizon := Color(0.25, 0.36, 0.36)
	var sage := Color(0.53, 0.62, 0.54)
	var glow := Color(0.86, 0.73, 0.50)
	for py: int in 384:
		var v := (float(py) + 0.5) / 384.0
		for px: int in 512:
			var u := (float(px) + 0.5) / 512.0
			var color := ground.lerp(horizon, v * 0.42)
			var sun_distance := Vector2((u - 0.78) * 1.35, v - 0.30).length()
			if sun_distance < 0.15:
				color = glow
			var route_y := 0.77 - 0.31 * sin(u * PI * 0.78)
			if absf(v - route_y) < 0.009 and u > 0.46:
				color = sage
			if v > 0.91:
				color = sage.darkened(0.52)
			if px % 64 == 0 and v > 0.92:
				color = glow
			image.set_pixel(px, py, color)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.75
	_screen_materials["route"] = material
	return material
