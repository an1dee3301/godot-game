extends RefCounted
## Freestanding, backlit tea advertisement in a shallow walnut and brass case.

static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "MidoriTeaLightbox"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "midori_walnut")
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.45, 0.8, "midori_stand")
	var brass: StandardMaterial3D = DesignKit.brass()
	var paper: StandardMaterial3D = DesignKit.washi(Color(0.98, 0.94, 0.84), 1.3, "midori_diffuser")

	# Two narrow steel standards and broad, low feet make the wall-sized face credible on the floor.
	for x: float in [-1.48, 1.48]:
		DesignKit.rbox(root, Vector3(0.10, 0.48, 0.11), Vector3(x, 0.24, -0.05), steel, 0.025)
		DesignKit.rbox(root, Vector3(0.32, 0.055, 0.49), Vector3(x, 0.0275, -0.045), steel, 0.022)
		DesignKit.rbox(root, Vector3(0.12, 0.025, 0.27), Vector3(x, 0.062, -0.045), brass, 0.009)

	# Layered case: dark rear shell, glowing diffuser, and four individually rounded timber rails.
	DesignKit.rbox(root, Vector3(4.04, 1.54, 0.17), Vector3(0.0, 1.17, -0.065), steel, 0.065)
	DesignKit.rbox(root, Vector3(3.91, 1.41, 0.025), Vector3(0.0, 1.17, 0.037), paper, 0.018, false)
	DesignKit.add(root, _poster_mesh(), _poster_material(variant), Vector3(0.0, 1.17, 0.054), Vector3.ZERO, false)
	for y: float in [0.43, 1.91]:
		DesignKit.rbox(root, Vector3(4.08, 0.10, 0.18), Vector3(0.0, y, 0.047), walnut, 0.035)
	for x: float in [-1.99, 1.99]:
		DesignKit.rbox(root, Vector3(0.10, 1.40, 0.18), Vector3(x, 1.17, 0.047), walnut, 0.034)
	DesignKit.rbox(root, Vector3(3.82, 0.012, 0.015), Vector3(0.0, 1.853, 0.108), brass, 0.004, false)
	DesignKit.rbox(root, Vector3(3.82, 0.012, 0.015), Vector3(0.0, 0.487, 0.108), brass, 0.004, false)

	# All lettering stays separate from the procedural artwork so the type is crisp at distance.
	_add_label(root, "MIDORI TEA", Vector3(-0.85, 1.39, 0.079), 128, 0.0025, Color(0.17, 0.23, 0.19), 2.12)
	_add_label(root, "緑茶", Vector3(-1.40, 0.89, 0.079), 155, 0.0025, Color(0.28, 0.39, 0.31), 0.82)

	# Small screw heads belong to the frame, away from the large copy.
	var screw: Mesh = _screw_mesh()
	for x: float in [-1.99, 1.99]:
		for y: float in [0.46, 1.88]:
			DesignKit.add(root, screw, brass, Vector3(x, y, 0.144), Vector3(90.0, 0.0, 0.0), false)
	return root


static func _poster_mesh() -> QuadMesh:
	if not _meshes.has("poster"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(3.88, 1.38)
		_meshes["poster"] = mesh
	return _meshes["poster"] as QuadMesh


static func _screw_mesh() -> Mesh:
	if not _meshes.has("screw"):
		_meshes["screw"] = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.018, 0.0),
			Vector2(0.018, 0.004), Vector2(0.012, 0.008), Vector2(0.0, 0.008)
		]), 12)
	return _meshes["screw"] as Mesh


static func _poster_material(variant: int) -> StandardMaterial3D:
	var key := "poster_%d" % posmod(variant, 3)
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = _make_poster(variant)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission_texture = material.albedo_texture
	material.emission_energy_multiplier = 0.55
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 1.0
	_materials[key] = material
	return material


static func _make_poster(variant: int) -> ImageTexture:
	var image := Image.create(1024, 384, false, Image.FORMAT_RGB8)
	var paper := Color(0.96, 0.93, 0.85)
	var sage := Color(0.70, 0.76, 0.64)
	var dark_sage := Color(0.30, 0.43, 0.33)
	var matcha := Color(0.46, 0.58, 0.31)
	var clay := Color(0.68, 0.42, 0.32)
	var ceramic := Color(0.83, 0.67, 0.52)
	var walnut := Color(0.33, 0.27, 0.22)
	var shift := float(posmod(variant, 3) - 1) * 0.035
	for y: int in 384:
		var fy := float(y)
		for x: int in 1024:
			var fx := float(x)
			var p := Vector2(fx, fy)
			var grain := sin(fx * 0.71 + fy * 0.41) * sin(fx * 0.19 - fy * 0.83) * 0.008
			var color := paper.lightened(maxf(grain, 0.0)).darkened(maxf(-grain, 0.0))
			# A single soft disc gives the illustrated cup generous negative space.
			if p.distance_to(Vector2(772.0, 191.0)) < 165.0:
				color = sage.lightened(0.05 + shift)
			# Offset leaf stems, broad enough to read as shapes rather than texture.
			if _ellipse(p, Vector2(722.0, 93.0), Vector2(16.0, 35.0)):
				color = dark_sage
			if _ellipse(p, Vector2(760.0, 79.0), Vector2(17.0, 31.0)):
				color = matcha
			# Handle sits behind the bowl and has a distinct open centre.
			if _ellipse(p, Vector2(886.0, 215.0), Vector2(43.0, 50.0)):
				color = ceramic
			if _ellipse(p, Vector2(886.0, 215.0), Vector2(24.0, 31.0)):
				color = sage.lightened(0.05 + shift)
			# Low saucer, rounded bowl silhouette, dark rim, then a matcha surface.
			if _ellipse(p, Vector2(772.0, 307.0), Vector2(135.0, 16.0)):
				color = walnut
			if fy >= 169.0 and fy <= 302.0:
				var width := 120.0 - 0.30 * (fy - 169.0)
				if absf(fx - 772.0) < width and _ellipse(p, Vector2(772.0, 169.0), Vector2(120.0, 150.0)):
					color = clay.lerp(ceramic, (fx - 650.0) / 260.0 * 0.35)
			if _ellipse(p, Vector2(772.0, 170.0), Vector2(122.0, 39.0)):
				color = walnut
			if _ellipse(p, Vector2(772.0, 164.0), Vector2(108.0, 25.0)):
				color = matcha
			if _ellipse(p, Vector2(740.0, 157.0), Vector2(37.0, 6.0)):
				color = matcha.lightened(0.23)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _ellipse(point: Vector2, centre: Vector2, radii: Vector2) -> bool:
	var delta := (point - centre) / radii
	return delta.length_squared() <= 1.0


static func _add_label(parent: Node3D, caption: String, at: Vector3, size: int, pixel_size: float, ink: Color, width_m: float) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel_size
	var measured: float = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * pixel_size
	if measured > width_m:
		label.font_size = maxi(12, int(float(size) * width_m / measured))
		measured = label.font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x * pixel_size
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = at + Vector3(measured * 0.5, 0.0, 0.0)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)
