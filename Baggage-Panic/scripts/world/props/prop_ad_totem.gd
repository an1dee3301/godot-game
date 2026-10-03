extends RefCounted
## A two-sided, softly illuminated travel campaign in a crafted 2.2 metre enclosure.

static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AdTotem"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var choice: int = posmod(variant, 4)
	var charcoal: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.7, "ad_totem_frame")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT if choice % 2 == 0 else DesignKit.OAK, "ad_totem_walnut" if choice % 2 == 0 else "ad_totem_oak")
	var gasket: StandardMaterial3D = DesignKit.paint(Color(0.035, 0.033, 0.03), 0.85)
	# The broad honed foot provides ballast; a recessed timber neck keeps it light visually.
	DesignKit.rbox(root, Vector3(1.28, 0.09, 0.54), Vector3(0.0, 0.045, 0.0), DesignKit.stone(), 0.043)
	DesignKit.rbox(root, Vector3(1.10, 0.025, 0.35), Vector3(0.0, 0.1025, 0.0), DesignKit.brass(), 0.012)
	DesignKit.rbox(root, Vector3(0.94, 0.16, 0.25), Vector3(0.0, 0.195, 0.0), walnut, 0.035)
	DesignKit.rbox(root, Vector3(1.20, 1.94, 0.18), Vector3(0.0, 1.23, 0.0), charcoal, 0.065)
	# Timber splines set into the two narrow edges, ending short of the rounded corners.
	for side: float in [-1.0, 1.0]:
		DesignKit.rbox(root, Vector3(0.012, 1.72, 0.085), Vector3(side * 0.599, 1.23, 0.0), walnut, 0.005)
	# Both faces are assembled in identical local coordinates, so the rear reads correctly.
	for side_index: int in 2:
		var face: Node3D = Node3D.new()
		face.name = "Front" if side_index == 0 else "Rear"
		face.rotation_degrees.y = float(side_index) * 180.0
		root.add_child(face)
		DesignKit.rbox(face, Vector3(1.115, 1.83, 0.018), Vector3(0.0, 1.235, 0.093), gasket, 0.008)
		DesignKit.rbox(face, Vector3(1.075, 1.79, 0.012), Vector3(0.0, 1.235, 0.105), _screen_material(choice), 0.005, false)
		# Generous lettering, high contrast, and a single campaign message in all six languages.
		_caption(face, "EXPLORE", 1.235, 96, 0.96)
		_caption(face, "旅へ  ·  探索", 1.025, 72, 0.96)
		_caption(face, "Khám phá", 0.835, 72, 0.96)
		_caption(face, "Explorez", 0.645, 72, 0.96)
		_caption(face, "Explora", 0.455, 72, 0.96)
		# A flush brass service strip and a quiet status light below the glass.
		DesignKit.rbox(face, Vector3(0.24, 0.012, 0.006), Vector3(0.0, 0.291, 0.092), DesignKit.brass(), 0.002, false)
		DesignKit.rbox(face, Vector3(0.025, 0.008, 0.006), Vector3(0.40, 0.291, 0.092), DesignKit.washi(DesignKit.SAGE, 0.8, "ad_totem_status"), 0.003, false)
	return root


static func _caption(parent: Node3D, caption: String, height: float, font_size: int, width: float) -> void:
	var label: Label3D = Label3D.new()
	label.font = Signage.font()
	label.text = caption
	label.pixel_size = 0.0022
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x * label.pixel_size
	label.font_size = mini(font_size, int(float(font_size) * width / maxf(measured, width)))
	label.position = Vector3(0.0, height, 0.114)
	label.modulate = Color(0.12, 0.16, 0.15)
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label.visibility_range_end = 65.0
	label.visibility_range_end_margin = 8.0
	parent.add_child(label)


static func _screen_material(choice: int) -> StandardMaterial3D:
	var key: String = "screen_%d" % choice
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var ridge_colors: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var ridge: Color = ridge_colors[choice]
	var sun_colors: Array[Color] = [DesignKit.CLAY, DesignKit.OCHRE, DesignKit.CLAY, DesignKit.SAGE]
	var sun: Color = sun_colors[choice]
	var image: Image = Image.create(540, 900, false, Image.FORMAT_RGBA8)
	var peak: float = 0.40 + float(choice) * 0.045
	var sun_center: Vector2 = Vector2(0.73 if choice % 2 == 0 else 0.26, 0.145)
	# Raster art is shared by both faces and cached across copies; no stacks of polygon nodes.
	for y: int in image.get_height():
		for x: int in image.get_width():
			var uv: Vector2 = Vector2(float(x) / 539.0, float(y) / 899.0)
			var color: Color = DesignKit.CREAM
			if uv.y < 0.405:
				color = DesignKit.CREAM.lerp(Color(0.82, 0.86, 0.81), (0.405 - uv.y) * 0.85)
				# Correct for portrait aspect so the sun is a circle in world space.
				var sun_delta: Vector2 = (uv - sun_center) * Vector2(1.075, 1.79)
				var sun_coverage: float = clampf((0.124 - sun_delta.length()) / 0.003, 0.0, 1.0)
				color = color.lerp(sun, sun_coverage)
				var far_edge: float = 0.21 + absf(uv.x - (1.0 - peak)) * 0.34
				var near_edge: float = 0.175 + absf(uv.x - peak) * 0.49
				color = color.lerp(ridge.lightened(0.30), clampf((uv.y - far_edge) / 0.003, 0.0, 1.0))
				color = color.lerp(ridge, clampf((uv.y - near_edge) / 0.003, 0.0, 1.0))
				# A pale snow cap and a darker descending shoulder give the mountain depth.
				if uv.y > near_edge and uv.y < 0.227 and absf(uv.x - peak) < 0.10:
					color = DesignKit.CREAM
				if uv.x > peak and uv.y > near_edge + 0.033:
					color = ridge.darkened(0.12)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 0.65
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 0.24
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = material
	return material
