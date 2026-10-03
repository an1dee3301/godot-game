extends RefCounted
## Floor-standing, backlit Hà Nội travel print with a Ha Long Bay silhouette.

static var _textures: Dictionary = {}
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "HanoiTravelLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.43, 0.82, "hanoi_case")
	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "hanoi_frame")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "hanoi_reveal")
	var brass: StandardMaterial3D = DesignKit.brass()
	DesignKit.rbox(root, Vector3(2.0, 3.0, 0.14), Vector3(0.0, 1.5, -0.035), steel, 0.045)
	DesignKit.rbox(root, Vector3(1.89, 2.89, 0.025), Vector3(0.0, 1.5, 0.046), walnut, 0.012, false)
	DesignKit.rbox(root, Vector3(1.81, 2.81, 0.012), Vector3(0.0, 1.5, 0.065), DesignKit.washi(DesignKit.CREAM, 1.5, "hanoi_diffuser"), 0.006, false)
	DesignKit.add(root, _art_mesh(), _art_material(variant), Vector3(0.0, 1.5, 0.073), Vector3.ZERO, false)

	# Four softly rounded oak rails hide the print edges and the dark recessed case.
	DesignKit.rbox(root, Vector3(2.0, 0.085, 0.13), Vector3(0.0, 2.9575, 0.075), oak, 0.032)
	DesignKit.rbox(root, Vector3(2.0, 0.085, 0.13), Vector3(0.0, 0.0425, 0.075), oak, 0.032)
	DesignKit.rbox(root, Vector3(0.085, 2.83, 0.13), Vector3(-0.9575, 1.5, 0.075), oak, 0.032)
	DesignKit.rbox(root, Vector3(0.085, 2.83, 0.13), Vector3(0.9575, 1.5, 0.075), oak, 0.032)
	for x: float in [-0.78, 0.78]:
		DesignKit.rbox(root, Vector3(0.11, 0.035, 0.25), Vector3(x, 0.0175, -0.06), steel, 0.015)
		DesignKit.rbox(root, Vector3(0.022, 0.022, 0.022), Vector3(x, 0.052, 0.145), brass, 0.008, false)

	var title := Label3D.new()
	title.text = "HÀ NỘI"
	title.font = Signage.font()
	title.font_size = 142
	title.pixel_size = 0.0023
	title.modulate = Color(0.16, 0.24, 0.24)
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(0.0, 2.55, 0.081)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	title.visibility_range_end = 70.0
	title.visibility_range_end_margin = 10.0
	root.add_child(title)
	return root


static func _art_mesh() -> QuadMesh:
	if not _meshes.has("face"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.81, 2.81)
		_meshes["face"] = mesh
	return _meshes["face"] as QuadMesh


static func _art_material(variant: int) -> StandardMaterial3D:
	var key := str(posmod(variant, 3))
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = _art_texture(variant)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.55
	material.roughness = 1.0
	_materials[key] = material
	return material


static func _art_texture(variant: int) -> Texture2D:
	var key := str(posmod(variant, 3))
	if _textures.has(key):
		return _textures[key] as Texture2D
	var width := 512
	var height := 768
	var image := Image.create(width, height, false, Image.FORMAT_RGB8)
	var paper := Color(0.951, 0.923, 0.858)
	var clay := Color(0.756, 0.448, 0.337)
	var far := Color(0.681, 0.733, 0.673)
	var middle := Color(0.430, 0.565, 0.541)
	var deep := Color(0.177, 0.337, 0.350)
	var water := Color(0.533, 0.650, 0.616)
	var shift := float(posmod(variant, 3)) * 0.018
	for y: int in height:
		var v := (float(y) + 0.5) / float(height)
		for x: int in width:
			var u := (float(x) + 0.5) / float(width)
			var color := paper
			# The open upper field keeps the large title clear against warm paper.
			var sun_delta := Vector2((u - 0.69 - shift) * 1.0, (v - 0.365) * 1.5)
			if sun_delta.length() < 0.135:
				color = clay
			var distant_top := minf(_karst_top(u, 0.16 + shift, 0.15, 0.47, 0.71), _karst_top(u, 0.41, 0.18, 0.51, 0.71))
			distant_top = minf(distant_top, _karst_top(u, 0.80, 0.15, 0.49, 0.71))
			if v >= distant_top and v < 0.715:
				color = far
			var middle_top := minf(_karst_top(u, 0.30, 0.16, 0.40, 0.73), _karst_top(u, 0.64 + shift, 0.20, 0.455, 0.73))
			if v >= middle_top and v < 0.735:
				color = middle
			if v >= 0.735:
				color = water
				# A few broad, restrained reflections read as water from across the hall.
				if (v > 0.748 and v < 0.752 and u > 0.18 and u < 0.47) or (v > 0.805 and v < 0.809 and u > 0.58 and u < 0.88) or (v > 0.89 and v < 0.894 and u > 0.12 and u < 0.43):
					color = paper.darkened(0.08)
			# A traditional sail boat: tapered dark hull, slim mast, ochre triangular sail.
			if u > 0.43 and u < 0.67 and v > 0.82 and v < 0.85:
				var hull_edge := minf(u - 0.43, 0.67 - u) / 0.06
				if v < 0.82 + clampf(hull_edge, 0.0, 1.0) * 0.03:
					color = deep
			if absf(u - 0.548) < 0.003 and v > 0.70 and v < 0.825:
				color = deep
			if u > 0.558 and u < 0.642 and v > 0.71 and v < 0.812:
				var sail_edge := 0.558 + (v - 0.71) * 0.83
				if u < sail_edge:
					color = clay
			# Print tooth is subtle enough to preserve the flat graphic shapes.
			var grain := sin(float(x) * 1.31 + float(y) * 0.83) * sin(float(x) * 0.37 - float(y) * 1.71)
			color = color.lightened(maxf(grain, 0.0) * 0.012).darkened(maxf(-grain, 0.0) * 0.012)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture


static func _karst_top(u: float, centre: float, half_width: float, tip: float, base: float) -> float:
	var distance := absf(u - centre) / half_width
	if distance >= 1.0:
		return base
	var shoulder := pow(1.0 - distance, 0.72)
	return base - (base - tip) * shoulder
