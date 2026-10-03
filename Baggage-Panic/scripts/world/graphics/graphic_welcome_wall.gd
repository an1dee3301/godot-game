extends RefCounted
## A full-height oak welcome wall with a limestone inset and raised brass lettering.

static var _textures: Dictionary = {}
static var _materials: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "WelcomeWall"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var oak: StandardMaterial3D = DesignKit.wood(DesignKit.OAK, "welcome_oak")
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "welcome_walnut")
	var limestone: StandardMaterial3D = DesignKit.stone(DesignKit.LIMESTONE, 0.78, "welcome_limestone")
	var steel: StandardMaterial3D = DesignKit.metal(DesignKit.CHARCOAL, 0.5, 0.75, "welcome_reveal")
	var brass: StandardMaterial3D = DesignKit.brass()

	DesignKit.rbox(root, Vector3(8.0, 4.0, 0.16), Vector3(0.0, 2.0, -0.08), limestone, 0.045)
	_add_slats(root, oak, walnut)
	# The two stepped reveals make the stone feel fitted into the timber rather than pasted on it.
	DesignKit.rbox(root, Vector3(7.48, 3.15, 0.09), Vector3(0.0, 2.02, 0.185), steel, 0.035)
	DesignKit.rbox(root, Vector3(7.40, 3.07, 0.095), Vector3(0.0, 2.02, 0.238), limestone, 0.035)
	DesignKit.rbox(root, Vector3(7.08, 0.018, 0.025), Vector3(0.0, 2.345, 0.298), brass, 0.008, false)
	DesignKit.rbox(root, Vector3(7.78, 0.11, 0.22), Vector3(0.0, 0.055, 0.12), walnut, 0.035)
	DesignKit.rbox(root, Vector3(7.62, 0.022, 0.035), Vector3(0.0, 0.13, 0.239), brass, 0.008, false)

	_add_title(root, brass)
	var art := MeshInstance3D.new()
	var art_mesh := QuadMesh.new()
	art_mesh.size = Vector2(1.66, 1.66)
	art.mesh = art_mesh
	art.material_override = _art_material(variant)
	art.position = Vector3(-2.54, 1.42, 0.292)
	art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(art)
	DesignKit.rbox(root, Vector3(1.78, 1.78, 0.025), Vector3(-2.54, 1.42, 0.259), brass, 0.012, false)
	# Re-add the print just ahead of its narrow brass mount.
	art.position.z = 0.278
	_add_line(root, "ようこそ  ·  欢迎", 1.98, DesignKit.CHARCOAL)
	_add_line(root, "Chào mừng  ·  Bienvenue", 1.43, DesignKit.CHARCOAL)
	_add_line(root, "Bienvenidos", 0.88, DesignKit.WALNUT)
	return root


static func _add_slats(root: Node3D, oak: Material, walnut: Material) -> void:
	var slat_mesh: Mesh = DesignKit.rounded_box(Vector3(0.16, 3.90, 0.10), 0.035)
	for tone: int in 2:
		var count := 0
		for i: int in 33:
			if i % 8 == 2 and tone == 1 or i % 8 != 2 and tone == 0:
				count += 1
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = slat_mesh
		multi.instance_count = count
		var index := 0
		for i: int in 33:
			if i % 8 == 2 and tone == 1 or i % 8 != 2 and tone == 0:
				var x := -3.84 + float(i) * 0.24
				multi.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x, 2.0, 0.095)))
				index += 1
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = walnut if tone == 1 else oak
		root.add_child(instance)


static func _add_title(root: Node3D, brass: Material) -> void:
	var letters := TextMesh.new()
	letters.text = "WELCOME"
	letters.font = Signage.font()
	letters.font_size = 128
	letters.pixel_size = 0.007
	letters.depth = 0.045
	var text_bounds: AABB = letters.get_aabb()
	var title := MeshInstance3D.new()
	title.mesh = letters
	title.material_override = brass
	title.position = Vector3(-text_bounds.position.x - text_bounds.size.x * 0.5, 2.96 - text_bounds.position.y - text_bounds.size.y * 0.5, 0.33)
	root.add_child(title)


static func _add_line(root: Node3D, caption: String, height: float, ink: Color) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 85
	label.pixel_size = 0.004
	label.modulate = ink
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(1.02, height, 0.31)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(label)


static func _art_material(variant: int) -> StandardMaterial3D:
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
	var image := Image.create(512, 512, false, Image.FORMAT_RGB8)
	var paper := DesignKit.CREAM
	var sun := DesignKit.CLAY
	var earth := DesignKit.SAGE
	var offset := float(posmod(variant, 3)) * 0.025
	for y: int in 512:
		for x: int in 512:
			var u := (float(x) + 0.5) / 512.0
			var v := (float(y) + 0.5) / 512.0
			var color := paper
			var d := Vector2(u - 0.5 - offset, v - 0.39).length()
			if d < 0.275:
				color = sun
			if v > 0.63 and v < 0.67:
				color = earth
			if v > 0.715 and v < 0.755:
				color = earth
			if v > 0.80 and v < 0.84:
				color = earth
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_textures[key] = texture
	return texture
