extends RefCounted
## Three woven wayfinding banners, suspended from a shared blackened steel rod.

static var _materials: Dictionary = {}
static var _cloth_mesh: ArrayMesh


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root := Node3D.new()
	root.name = "JourneySkyHarbourBanners"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)

	var steel := DesignKit.metal(DesignKit.CHARCOAL, 0.42, 0.75, "banner_steel")
	var brass := DesignKit.brass()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.022
	rod.bottom_radius = 0.022
	rod.height = 4.04
	rod.radial_segments = 12
	DesignKit.add(root, rod, steel, Vector3(0.0, 9.08, -0.015), Vector3(0.0, 0.0, 90.0))
	for end_x: float in [-2.035, 2.035]:
		DesignKit.rbox(root, Vector3(0.055, 0.065, 0.065), Vector3(end_x, 9.08, -0.015), brass, 0.025)

	var suspender := CylinderMesh.new()
	suspender.top_radius = 0.009
	suspender.bottom_radius = 0.009
	suspender.height = 0.78
	suspender.radial_segments = 8
	for anchor_x: float in [-1.82, 1.82]:
		DesignKit.add(root, suspender, steel, Vector3(anchor_x, 9.49, -0.015))

	var cloth := _banner_mesh()
	for i in 3:
		var x := (float(i) - 1.0) * 1.34
		var scheme := posmod(i + variant, 3)
		var panel := MeshInstance3D.new()
		panel.name = "FabricBanner_%d" % i
		panel.mesh = cloth
		panel.material_override = _banner_material(scheme)
		panel.position.x = x
		root.add_child(panel)

		var loop_fabric := DesignKit.fabric(_canvas_color(scheme), "banner_loop_%d" % scheme)
		for side: float in [-0.36, 0.36]:
			DesignKit.rbox(root, Vector3(0.12, 0.27, 0.045), Vector3(x + side, 9.025, -0.005), loop_fabric, 0.02)
			DesignKit.rbox(root, Vector3(0.13, 0.019, 0.055), Vector3(x + side, 9.07, 0.027), brass, 0.008, false)

		# A weighted hem keeps the fabric visually taut without a rigid frame.
		DesignKit.rbox(root, Vector3(0.98, 0.045, 0.052), Vector3(x, 4.025, 0.014), DesignKit.wood(DesignKit.WALNUT, "banner_walnut"), 0.02)
		var ink := DesignKit.CHARCOAL if scheme != 2 else DesignKit.INDIGO
		var glyph: String = ["旅", "空", "港"][i]
		var word: String = ["JOURNEY", "SKY", "HARBOUR"][i]
		_add_text(root, glyph, Vector3(x, 6.27, 0.075), 510, 0.0020, ink)
		_add_text(root, word, Vector3(x, 4.95, 0.075), 118, 0.00175, ink)
	return root


static func _add_text(parent: Node3D, caption: String, at: Vector3, size: int, pixel: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.position = at
	label.visibility_range_end = 80.0
	label.visibility_range_end_margin = 10.0
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _banner_mesh() -> ArrayMesh:
	if _cloth_mesh != null:
		return _cloth_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in 20:
		for col in 12:
			var a := _cloth_vertex(col, row)
			var b := _cloth_vertex(col + 1, row)
			var c := _cloth_vertex(col + 1, row + 1)
			var d := _cloth_vertex(col, row + 1)
			for vertex: Vector3 in [a, b, c, a, c, d]:
				st.set_uv(Vector2(vertex.x + 0.5, (9.0 - vertex.y) / 5.0))
				st.add_vertex(vertex)
	st.generate_normals()
	_cloth_mesh = st.commit()
	return _cloth_mesh


static func _cloth_vertex(col: int, row: int) -> Vector3:
	var u := float(col) / 12.0
	var v := float(row) / 20.0
	var x := u - 0.5
	var y := 4.0 + v * 5.0
	var ripple := 0.014 * sin(u * TAU * 3.0) * sin(v * PI)
	var bow := 0.012 * (1.0 - absf(x) * 2.0)
	return Vector3(x, y, ripple + bow)


static func _canvas_color(scheme: int) -> Color:
	match scheme:
		0:
			return Color(0.91, 0.86, 0.76)
		1:
			return Color(0.84, 0.87, 0.79)
		_:
			return Color(0.87, 0.83, 0.74)


static func _banner_material(scheme: int) -> StandardMaterial3D:
	if _materials.has(scheme):
		return _materials[scheme] as StandardMaterial3D
	var image := Image.create(256, 1024, false, Image.FORMAT_RGB8)
	var ground := _canvas_color(scheme)
	var motif := DesignKit.CLAY if scheme == 0 else (DesignKit.INDIGO if scheme == 1 else DesignKit.SAGE)
	var line := motif.darkened(0.16)
	for py in 1024:
		var v := (float(py) + 0.5) / 1024.0
		for px in 256:
			var u := (float(px) + 0.5) / 256.0
			var c := ground
			# A barely visible woven warp gives the printed cloth a tactile finish.
			if px % 3 == 0 or py % 7 == 0:
				c = c.darkened(0.018)
			var distance := Vector2((u - 0.5) * 1.06, v - 0.29).length()
			if distance < 0.257:
				c = motif
			if scheme == 0 and distance < 0.257 and absf((u - 0.5) - (v - 0.29) * 0.42) < 0.025:
				c = ground
			elif scheme == 1 and distance < 0.257 and absf(v - 0.32 + 0.045 * sin(u * TAU)) < 0.028:
				c = ground
			elif scheme == 2 and distance < 0.257 and v > 0.31 and int((v - 0.31) * 55.0) % 3 == 0:
				c = ground
			if (absf(u - 0.06) < 0.003 or absf(u - 0.94) < 0.003) and v > 0.055 and v < 0.95:
				c = line.lightened(0.35)
			if v > 0.91 and v < 0.915 and u > 0.13 and u < 0.87:
				c = line
			image.set_pixel(px, py, c)
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.94
	_materials[scheme] = material
	return material
