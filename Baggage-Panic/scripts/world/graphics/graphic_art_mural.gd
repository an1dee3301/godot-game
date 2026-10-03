extends RefCounted
## Eight-metre washi landscape set into a shallow, crafted oak frame.

static var _textures: Dictionary = {}
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "WashiMountainMural"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "mural_oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "mural_walnut")
	var backing: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.85, "mural_limestone")
	DesignKit.rbox(root, Vector3(8.0, 3.0, 0.12), Vector3(0.0, 1.5, -0.065), backing, 0.035)
	# The dark reveal leaves a crisp shadow line between the print and timber.
	DesignKit.rbox(root, Vector3(7.82, 2.82, 0.025), Vector3(0.0, 1.5, 0.008), walnut, 0.012, false)
	DesignKit.rbox(root, Vector3(8.0, 0.115, 0.17), Vector3(0.0, 2.9425, 0.055), oak, 0.035)
	DesignKit.rbox(root, Vector3(8.0, 0.115, 0.17), Vector3(0.0, 0.0575, 0.055), oak, 0.035)
	DesignKit.rbox(root, Vector3(0.115, 2.8, 0.17), Vector3(-3.9425, 1.5, 0.055), oak, 0.035)
	DesignKit.rbox(root, Vector3(0.115, 2.8, 0.17), Vector3(3.9425, 1.5, 0.055), oak, 0.035)

	var print_mesh: QuadMesh = _print_mesh()
	DesignKit.add(root, print_mesh, _paper_material(variant), Vector3(0.0, 1.5, 0.032), Vector3.ZERO, false)
	var title := Label3D.new()
	title.text = "山"
	title.font = Signage.font()
	title.font_size = 180
	title.pixel_size = 0.003
	title.modulate = Color(0.302, 0.402, 0.398)
	title.outline_size = 0
	title.double_sided = false
	title.position = Vector3(-2.77, 2.32, 0.039)
	title.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(title)
	var pin_mesh: Mesh = _pin_mesh()
	var brass: StandardMaterial3D = DesignKit.brass()
	for x: float in [-3.9, 3.9]:
		for y: float in [0.10, 2.90]:
			DesignKit.add(root, pin_mesh, brass, Vector3(x, y, 0.151), Vector3(90.0, 0.0, 0.0), false)
	return root


static func _print_mesh() -> QuadMesh:
	if not _meshes.has("print"):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(7.70, 2.70)
		_meshes["print"] = mesh
	return _meshes["print"] as QuadMesh


static func _pin_mesh() -> Mesh:
	if not _meshes.has("pin"):
		_meshes["pin"] = DesignKit.lathe(PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.023, 0.0),
			Vector2(0.022, 0.007), Vector2(0.012, 0.011), Vector2(0.0, 0.011)
		]), 12)
	return _meshes["pin"] as Mesh


static func _paper_material(variant: int) -> StandardMaterial3D:
	var key := str(posmod(variant, 3))
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = _art_texture(variant)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 1.0
	_materials[key] = material
	return material


static func _art_texture(variant: int) -> Texture2D:
	var key := str(posmod(variant, 3))
	if _textures.has(key):
		return _textures[key] as Texture2D
	var image := Image.create(1024, 384, false, Image.FORMAT_RGB8)
	var paper := Color(0.941, 0.901, 0.819)
	var sky := Color(0.901, 0.851, 0.746)
	var sun := Color(0.735, 0.419, 0.300)
	var far := Color(0.680, 0.708, 0.635)
	var middle := Color(0.487, 0.575, 0.526)
	var near := Color(0.302, 0.402, 0.398)
	var shift := float(posmod(variant, 3)) * 0.07
	for y: int in 384:
		var v := (float(y) + 0.5) / 384.0
		for x: int in 1024:
			var u := (float(x) + 0.5) / 1024.0
			var color := paper
			if u > 0.038 and u < 0.962 and v > 0.073 and v < 0.927:
				color = sky.lerp(paper, clampf(v * 0.75, 0.0, 1.0))
				var sun_offset := Vector2((u - (0.715 - shift)) * 7.70, (v - 0.38) * 2.70)
				if sun_offset.length() < 0.48:
					color = sun
				var rear_ridge := 0.62 - 0.23 * exp(-pow((u - 0.25 - shift) / 0.23, 2.0)) - 0.11 * exp(-pow((u - 0.76) / 0.16, 2.0))
				var middle_ridge := 0.75 - 0.18 * exp(-pow((u - 0.59 + shift) / 0.25, 2.0)) - 0.045 * sin(u * 16.0)
				var near_ridge := 0.87 - 0.075 * exp(-pow((u - 0.18) / 0.23, 2.0)) - 0.055 * exp(-pow((u - 0.88) / 0.13, 2.0))
				if v > rear_ridge:
					color = far
				if v > middle_ridge:
					color = middle
				if v > near_ridge:
					color = near
			# Fine, deterministic paper fibre variation without more geometry.
			var grain := sin(float(x) * 1.73 + float(y) * 2.39) * sin(float(x) * 0.37 - float(y) * 1.19)
			color = color.lightened(maxf(grain, 0.0) * 0.017).darkened(maxf(-grain, 0.0) * 0.017)
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture
