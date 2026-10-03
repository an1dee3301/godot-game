extends RefCounted
## A furniture-scale reading display: tilted oak pockets, brass retainers and art editions.

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


static func build(parent: Node3D, at: Vector3, rot_y_deg: float = 0.0, variant: int = 0) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MagazineRack"
	root.position = at
	root.rotation_degrees.y = rot_y_deg
	parent.add_child(root)
	var edition: int = posmod(variant, 4)
	var oak: StandardMaterial3D = DesignKit.wood()
	var walnut: StandardMaterial3D = DesignKit.wood(DesignKit.WALNUT, "walnut")
	var brass: StandardMaterial3D = DesignKit.brass()
	var ink: StandardMaterial3D = DesignKit.metal()
	var accents: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var accent: Color = accents[edition]
	# Wide, softly bevelled shoe with a recessed toe and four turned ferrules.
	DesignKit.rbox(root, Vector3(1.56, 0.10, 0.66), Vector3(0.0, 0.15, 0.0), oak, 0.045)
	DesignKit.rbox(root, Vector3(1.38, 0.055, 0.50), Vector3(0.0, 0.0825, 0.0), walnut, 0.023)
	var foot: ArrayMesh = DesignKit.lathe(PackedVector2Array([
		Vector2(0.0, 0.012), Vector2(0.035, 0.012), Vector2(0.041, 0.025),
		Vector2(0.041, 0.10), Vector2(0.035, 0.115), Vector2(0.0, 0.115)]), 16)
	for x: float in [-0.63, 0.63]:
		for z: float in [-0.23, 0.23]:
			DesignKit.add(root, foot, brass, Vector3(x, 0.0, z))
			DesignKit.rbox(root, Vector3(0.074, 0.014, 0.074), Vector3(x, 0.007, z), ink, 0.006, false)
	# The back and stiles follow the magazine lean, leaving an open carrying slot above.
	DesignKit.add(root, DesignKit.rounded_box(Vector3(1.40, 1.35, 0.05), 0.018),
		walnut, Vector3(0.0, 0.93, -0.12), Vector3(-14.0, 0.0, 0.0))
	for x: float in [-0.735, 0.735]:
		DesignKit.add(root, DesignKit.rounded_box(Vector3(0.075, 1.66, 0.10), 0.031),
			oak, Vector3(x, 1.01, -0.13), Vector3(-14.0, 0.0, 0.0))
		DesignKit.rbox(root, Vector3(0.084, 0.10, 0.108), Vector3(x, 0.25, 0.06), brass, 0.02)
	DesignKit.rbox(root, Vector3(1.43, 0.06, 0.065), Vector3(0.0, 1.86, -0.335), oak, 0.025)
	# Compact masthead, with titles on the magazines carrying the six languages.
	DesignKit.rbox(root, Vector3(1.41, 0.21, 0.065), Vector3(0.0, 1.695, -0.285), oak, 0.024)
	DesignKit.rbox(root, Vector3(1.32, 0.155, 0.014), Vector3(0.0, 1.695, -0.245),
		DesignKit.paint(accent), 0.006, false)
	_label(root, "READ / 旅", Vector3(0.0, 1.695, -0.231), 0.135, DesignKit.CREAM)
	var titles: Array[String] = ["ROAM", "旅", "远方", "ĐI", "VIE", "SOL"]
	for tier: int in 2:
		var pocket: Node3D = Node3D.new()
		pocket.name = "SlantedPocket_%d" % tier
		pocket.position = Vector3(0.0, 0.615 + float(tier) * 0.59, 0.065 - float(tier) * 0.15)
		pocket.rotation_degrees.x = -14.0
		root.add_child(pocket)
		DesignKit.rbox(pocket, Vector3(1.43, 0.055, 0.22), Vector3(0.0, -0.282, 0.04), oak, 0.022)
		# A low brass lip holds the stock without hiding the illustrated covers.
		DesignKit.rbox(pocket, Vector3(1.39, 0.037, 0.032), Vector3(0.0, -0.235, 0.145), brass, 0.014)
		for x: float in [-0.69, 0.69]:
			DesignKit.rbox(pocket, Vector3(0.03, 0.13, 0.19), Vector3(x, -0.245, 0.05), oak, 0.012)
		for column: int in 3:
			var index: int = tier * 3 + column
			var x: float = float(column - 1) * 0.455
			# Layered paper block, bound spine and a slightly proud cover edge.
			DesignKit.rbox(pocket, Vector3(0.417, 0.515, 0.027), Vector3(x, 0.0, 0.058),
				DesignKit.paint(DesignKit.CREAM, 0.93), 0.009)
			DesignKit.rbox(pocket, Vector3(0.428, 0.529, 0.009), Vector3(x, 0.0, 0.079),
				DesignKit.paint(accent), 0.003, false)
			DesignKit.rbox(pocket, Vector3(0.014, 0.513, 0.033), Vector3(x - 0.205, 0.0, 0.061),
				DesignKit.paint(DesignKit.CHARCOAL), 0.005, false)
			DesignKit.add(pocket, _cover_mesh(), _cover_material(index, edition), Vector3(x, 0.0, 0.085), Vector3.ZERO, false)
			_label(pocket, titles[index], Vector3(x, 0.166, 0.088), 0.115, DesignKit.CHARCOAL)
	return root


static func _label(parent: Node3D, caption: String, at: Vector3, height: float, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = caption
	label.font = Signage.font()
	label.font_size = 96
	label.pixel_size = height / 96.0
	label.position = at
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	label.no_depth_test = false
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label)


static func _cover_mesh() -> QuadMesh:
	if _meshes.has("cover"):
		return _meshes["cover"] as QuadMesh
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.411, 0.512)
	_meshes["cover"] = mesh
	return mesh


static func _cover_material(index: int, edition: int) -> StandardMaterial3D:
	var key: String = "%d:%d" % [index, edition]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var colors: Array[Color] = [DesignKit.SAGE, DesignKit.CLAY, DesignKit.INDIGO, DesignKit.OCHRE]
	var tone: Color = colors[(index + edition) % colors.size()]
	var image: Image = Image.create(256, 320, false, Image.FORMAT_RGB8)
	# Editorial artwork: oversized sun, layered hills, a winding river, or architectural arches.
	# A clear cream masthead gives every language the same strong silhouette.
	for y: int in 320:
		for x: int in 256:
			var u: float = float(x) / 255.0
			var v: float = float(y) / 319.0
			var color: Color = DesignKit.CREAM
			if v > 0.28:
				color = DesignKit.LINEN.lightened(0.16)
				var sun: Vector2 = Vector2(0.66 if index % 2 == 0 else 0.34, 0.46)
				if Vector2(u, v).distance_to(sun) < 0.15:
					color = DesignKit.OCHRE if edition % 2 == 0 else DesignKit.CLAY
				if index % 3 == 0:
					if v > 0.70 - 0.13 * sin(u * 5.0 + float(edition)):
						color = tone.lightened(0.16)
					if v > 0.84 - 0.10 * sin(u * 7.0 + 1.0):
						color = tone.darkened(0.13)
				elif index % 3 == 1:
					var arch: Vector2 = Vector2((u - 0.5) * 1.1, minf(v - 0.62, 0.0))
					if arch.length() < 0.32 and arch.length() > 0.21:
						color = tone
					if v > 0.89:
						color = tone.darkened(0.15)
				else:
					if v > 0.61:
						color = tone
						if absf(u - (0.5 + 0.16 * sin(v * 13.0))) < 0.085:
							color = DesignKit.CREAM
				# A thin printing border is texture detail rather than extra geometry.
				if u < 0.028 or u > 0.972 or v > 0.975:
					color = DesignKit.CREAM
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.roughness = 0.88
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_materials[key] = material
	return material
